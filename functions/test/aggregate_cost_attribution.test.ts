// =============================================================================
// aggregateCostAttribution tests — WS6.3 per-shop cost dashboard source.
//
// Coverage:
//   1. No shops → skips, logs warning
//   2. Shop with media + SMS data → correct summary written to cost_attribution
//   3. Shop with no media/SMS data → zeroes in summary, no crash
//   4. Multi-shop: 3 shops all get summaries
//   5. Batch-write failure propagates (rare path — no catch in outer function)
// =============================================================================

/* eslint-disable @typescript-eslint/no-explicit-any */

// ---- Mocks (must come before import) ----

const mockBatchSet = jest.fn();
const mockBatchCommit = jest.fn().mockResolvedValue(undefined);
const mockBatch = jest.fn(() => ({
  set: mockBatchSet,
  commit: mockBatchCommit,
}));

let shopDocs: Array<{ id: string }> = [];
let mediaDocsByShopId: Map<string, Record<string, unknown>> = new Map();
let smsDocsByShopId: Map<string, Record<string, unknown>> = new Map();

const mockFirestore = jest.fn(() => ({
  collection: jest.fn((name: string) => {
    if (name === 'shops') {
      return {
        get: jest.fn(async () => ({
          empty: shopDocs.length === 0,
          docs: shopDocs.map((s) => ({
            id: s.id,
            ref: {
              collection: (sub: string) => ({
                doc: (docId: string) => ({
                  _path: `shops/${s.id}/${sub}/${docId}`,
                }),
              }),
            },
          })),
        })),
        // Support db.collection('shops').doc(shopId).collection(...).doc(...)
        // used by the batch-write path in aggregateCostAttribution.
        doc: (shopId: string) => ({
          collection: (sub: string) => ({
            doc: (docId: string) => ({
              _path: `shops/${shopId}/${sub}/${docId}`,
            }),
          }),
        }),
      };
    }
    if (name === 'system') {
      return {
        doc: (docId: string) => {
          if (docId === 'media_usage_counter') {
            return {
              collection: (_sub: string) => ({
                get: jest.fn(async () => ({
                  docs: [...mediaDocsByShopId.entries()].map(([id, d]) => ({
                    id,
                    data: () => d,
                  })),
                })),
              }),
            };
          }
          if (docId === 'phone_auth_quota') {
            return {
              collection: (_sub: string) => ({
                get: jest.fn(async () => ({
                  docs: [...smsDocsByShopId.entries()].map(([id, d]) => ({
                    id,
                    data: () => d,
                  })),
                })),
              }),
            };
          }
          return {};
        },
      };
    }
    return {};
  }),
  batch: mockBatch,
}));

(mockFirestore as any).FieldValue = {
  serverTimestamp: () => '__server_timestamp__',
};

jest.mock('firebase-admin', () => ({
  apps: [{ name: '[DEFAULT]' }],
  initializeApp: jest.fn(),
  firestore: mockFirestore,
}));

const mockLoggerError = jest.fn();
const mockLoggerWarn = jest.fn();
const mockLoggerInfo = jest.fn();

jest.mock('firebase-functions/v2', () => ({
  logger: {
    error: mockLoggerError,
    warn: mockLoggerWarn,
    info: mockLoggerInfo,
  },
}));

let capturedHandler: (() => Promise<void>) | null = null;

jest.mock('firebase-functions/v2/scheduler', () => ({
  onSchedule: jest.fn((_config: unknown, handler: any) => {
    capturedHandler = handler;
    return handler;
  }),
}));

import './../src/aggregate_cost_attribution';

const now = new Date();
const MONTH_KEY = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
const SMS_FIELD = `smsCount_${MONTH_KEY}`;

beforeEach(() => {
  jest.clearAllMocks();
  shopDocs = [];
  mediaDocsByShopId = new Map();
  smsDocsByShopId = new Map();
});

describe('aggregateCostAttribution (WS6.3)', () => {
  // ---------------------------------------------------------------------------
  // 1. No shops
  // ---------------------------------------------------------------------------

  test('no shops → warns and skips batch writes', async () => {
    shopDocs = [];

    await capturedHandler!();

    expect(mockLoggerWarn).toHaveBeenCalledWith(
      'aggregateCostAttribution: no shops found, skipping',
    );
    expect(mockBatch).not.toHaveBeenCalled();
  });

  // ---------------------------------------------------------------------------
  // 2. Shop with media + SMS data → correct summary
  // ---------------------------------------------------------------------------

  test('single shop with full data writes correct summary', async () => {
    shopDocs = [{ id: 'sunil-trading-company' }];
    mediaDocsByShopId.set('sunil-trading-company', {
      cloudinaryCreditsUsed: 12,
      storageGb: 2.5,
    });
    smsDocsByShopId.set('sunil-trading-company', { [SMS_FIELD]: 4_200 });

    await capturedHandler!();

    expect(mockBatch).toHaveBeenCalledTimes(1);
    expect(mockBatchSet).toHaveBeenCalledTimes(1);
    expect(mockBatchSet).toHaveBeenCalledWith(
      expect.objectContaining({
        _path: `shops/sunil-trading-company/cost_attribution/${MONTH_KEY}`,
      }),
      expect.objectContaining({
        shopId: 'sunil-trading-company',
        month: MONTH_KEY,
        cloudinaryCreditsUsed: 12,
        cloudinaryCapPercent: (12 / 25) * 100,
        storageGb: 2.5,
        storageCapPercent: (2.5 / 5) * 100,
        smsCount: 4_200,
        smsCapPercent: (4_200 / 10_000) * 100,
        estimatedCostUsd: 0.0,
        generatedByUid: 'system_aggregate_cost_attribution',
      }),
      expect.objectContaining({ merge: true }),
    );
    expect(mockBatchCommit).toHaveBeenCalledTimes(1);
  });

  // ---------------------------------------------------------------------------
  // 3. Shop with no media / SMS data → zeroes
  // ---------------------------------------------------------------------------

  test('shop with no usage data → zeroes, no crash', async () => {
    shopDocs = [{ id: 'empty-shop' }];
    // No entries in mediaDocsByShopId or smsDocsByShopId

    await capturedHandler!();

    expect(mockBatchSet).toHaveBeenCalledWith(
      expect.any(Object),
      expect.objectContaining({
        cloudinaryCreditsUsed: 0,
        storageGb: 0,
        smsCount: 0,
        estimatedCostUsd: 0.0,
      }),
      expect.any(Object),
    );
    expect(mockBatchCommit).toHaveBeenCalledTimes(1);
  });

  // ---------------------------------------------------------------------------
  // 4. Multi-shop: all get summaries
  // ---------------------------------------------------------------------------

  test('3-shop set: all get cost_attribution summaries', async () => {
    shopDocs = [
      { id: 'sunil-trading-company' },
      { id: 'shop-2' },
      { id: 'shop-3' },
    ];

    await capturedHandler!();

    expect(mockBatch).toHaveBeenCalledTimes(1);
    expect(mockBatchSet).toHaveBeenCalledTimes(3);
    expect(mockBatchCommit).toHaveBeenCalledTimes(1);
    expect(mockLoggerInfo).toHaveBeenCalledWith(
      'aggregateCostAttribution: complete',
      expect.objectContaining({ shopsProcessed: 3 }),
    );
  });
});
