// =============================================================================
// phoneAuthQuotaMonitor tests — WS6.2 per-shop graduated response.
//
// Follows the kill_switch.test.ts mock pattern: mock firebase-admin and
// firebase-functions before importing the module, capture the scheduler
// handler, invoke it with seeded shop data, assert per-shop flag updates.
//
// Coverage:
//   1. No shops → skips batch writes, logs info
//   2. Single shop below both thresholds → action 'none', no flag flip
//   3. Single shop at WARNING (80%) → msg91 fallback for that shop only
//   4. Single shop at CRITICAL (95%) → msg91 + OTP disabled for that shop only
//   5. Two shops: one warning, one critical → correct flags per shop
//   6. Audit write failure does not block flag updates
//   7. Shops with no smsCount field treated as 0 (below threshold)
// =============================================================================

/* eslint-disable @typescript-eslint/no-explicit-any */

// ---- Mock firebase-admin BEFORE importing the function module ----

const mockBatchSet = jest.fn();
const mockBatchCommit = jest.fn().mockResolvedValue(undefined);
const mockBatch = jest.fn(() => ({
  set: mockBatchSet,
  commit: mockBatchCommit,
}));

const mockAuditAdd = jest.fn().mockResolvedValue({ id: 'audit-1' });

let shopQuotaDocs: Array<{ id: string; data: () => Record<string, unknown> }> = [];

const mockQuotaShopsGet = jest.fn(async () => ({
  empty: shopQuotaDocs.length === 0,
  docs: shopQuotaDocs,
}));

const mockShopDocRef = (shopId: string) => ({
  collection: (_sub: string) => ({
    doc: (_id: string) => ({ _path: `shops/${shopId}/featureFlags/runtime` }),
  }),
});

const mockFirestore = jest.fn(() => ({
  collection: jest.fn((name: string) => {
    if (name === 'shops') {
      return {
        get: jest.fn(async () => ({
          empty: false,
          docs: shopQuotaDocs.map((d) => ({
            id: d.id,
            ref: mockShopDocRef(d.id),
          })),
        })),
        doc: (shopId: string) => mockShopDocRef(shopId),
      };
    }
    if (name === 'system') {
      return {
        doc: (docId: string) => {
          if (docId === 'phone_auth_quota') {
            return {
              collection: (sub: string) => {
                if (sub === 'shops') {
                  return { get: mockQuotaShopsGet };
                }
                // sub is a month key like '2026-04' — for audit writes
                return {
                  doc: (_id: string) => ({
                    collection: (_h: string) => ({
                      add: mockAuditAdd,
                    }),
                  }),
                };
              },
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

import './../src/phone_auth_quota_monitor';

// Current month key matching what the function computes at runtime.
const now = new Date();
const MONTH_KEY = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
const SMS_FIELD = `smsCount_${MONTH_KEY}`;

function seedShops(shops: Array<{ id: string; smsCount?: number }>) {
  shopQuotaDocs = shops.map((s) => ({
    id: s.id,
    data: () => ({ [SMS_FIELD]: s.smsCount ?? 0 }),
  }));
}

beforeEach(() => {
  jest.clearAllMocks();
  shopQuotaDocs = [];
});

describe('phoneAuthQuotaMonitor (per-shop WS6.2)', () => {
  // ---------------------------------------------------------------------------
  // 1. No shops in quota collection
  // ---------------------------------------------------------------------------

  test('no shops → no batch writes, logs info', async () => {
    seedShops([]);

    await capturedHandler!();

    expect(mockBatch).not.toHaveBeenCalled();
    expect(mockBatchCommit).not.toHaveBeenCalled();
    expect(mockLoggerInfo).toHaveBeenCalledWith(
      'phoneAuthQuotaMonitor: check complete',
      expect.objectContaining({ shopsChecked: 0 }),
    );
  });

  // ---------------------------------------------------------------------------
  // 2. Single shop below both thresholds
  // ---------------------------------------------------------------------------

  test('shop at 50% → action none, no flag flip', async () => {
    seedShops([{ id: 'sunil-trading-company', smsCount: 5_000 }]);

    await capturedHandler!();

    expect(mockBatchCommit).not.toHaveBeenCalled();
    expect(mockBatchSet).not.toHaveBeenCalled();
    expect(mockLoggerWarn).not.toHaveBeenCalled();
    expect(mockLoggerError).not.toHaveBeenCalled();
    expect(mockAuditAdd).toHaveBeenCalledWith(
      expect.objectContaining({ shopsWarning: 0, shopsCritical: 0 }),
    );
  });

  // ---------------------------------------------------------------------------
  // 3. Single shop at WARNING (80%)
  // ---------------------------------------------------------------------------

  test('shop at 80% → msg91 fallback for that shop only', async () => {
    seedShops([{ id: 'sunil-trading-company', smsCount: 8_000 }]);

    await capturedHandler!();

    expect(mockBatch).toHaveBeenCalledTimes(1);
    expect(mockBatchSet).toHaveBeenCalledTimes(1);
    expect(mockBatchSet).toHaveBeenCalledWith(
      expect.objectContaining({
        _path: 'shops/sunil-trading-company/featureFlags/runtime',
      }),
      expect.objectContaining({
        authProviderStrategy: 'msg91',
        updatedByUid: 'system_phone_auth_quota_monitor',
      }),
      expect.objectContaining({ merge: true }),
    );
    expect(mockBatchCommit).toHaveBeenCalledTimes(1);
    expect(mockLoggerWarn).toHaveBeenCalledWith(
      'SMS quota WARNING for shop',
      expect.objectContaining({ shopId: 'sunil-trading-company' }),
    );
    expect(mockAuditAdd).toHaveBeenCalledWith(
      expect.objectContaining({ shopsWarning: 1, shopsCritical: 0 }),
    );
  });

  // ---------------------------------------------------------------------------
  // 4. Single shop at CRITICAL (95%)
  // ---------------------------------------------------------------------------

  test('shop at 95% → msg91 + OTP disabled for that shop', async () => {
    seedShops([{ id: 'sunil-trading-company', smsCount: 9_500 }]);

    await capturedHandler!();

    // Only one batch (critical shops batch — warning shops list is empty
    // because critical shops are NOT added to the warning list).
    expect(mockBatch).toHaveBeenCalledTimes(1);
    expect(mockBatchSet).toHaveBeenCalledTimes(1);
    expect(mockBatchSet).toHaveBeenCalledWith(
      expect.objectContaining({
        _path: 'shops/sunil-trading-company/featureFlags/runtime',
      }),
      expect.objectContaining({
        authProviderStrategy: 'msg91',
        otpAtCommitEnabled: false,
      }),
      expect.objectContaining({ merge: true }),
    );
    expect(mockLoggerError).toHaveBeenCalledWith(
      'SMS quota CRITICAL for shop',
      expect.objectContaining({ shopId: 'sunil-trading-company' }),
    );
    expect(mockAuditAdd).toHaveBeenCalledWith(
      expect.objectContaining({ shopsWarning: 0, shopsCritical: 1 }),
    );
  });

  // ---------------------------------------------------------------------------
  // 5. Two shops: one warning, one critical
  // ---------------------------------------------------------------------------

  test('two shops at different tiers → correct per-shop flags', async () => {
    seedShops([
      { id: 'shop-a', smsCount: 8_200 }, // WARNING
      { id: 'shop-b', smsCount: 9_600 }, // CRITICAL
    ]);

    await capturedHandler!();

    // Two separate batch runs: one for critical, one for warning.
    expect(mockBatch).toHaveBeenCalledTimes(2);
    expect(mockBatchSet).toHaveBeenCalledTimes(2);
    // shop-b gets OTP disabled
    expect(mockBatchSet).toHaveBeenCalledWith(
      expect.objectContaining({ _path: 'shops/shop-b/featureFlags/runtime' }),
      expect.objectContaining({ otpAtCommitEnabled: false }),
      expect.objectContaining({ merge: true }),
    );
    // shop-a gets only msg91 (no otpAtCommitEnabled key)
    expect(mockBatchSet).toHaveBeenCalledWith(
      expect.objectContaining({ _path: 'shops/shop-a/featureFlags/runtime' }),
      expect.not.objectContaining({ otpAtCommitEnabled: false }),
      expect.objectContaining({ merge: true }),
    );
    expect(mockBatchCommit).toHaveBeenCalledTimes(2);
  });

  // ---------------------------------------------------------------------------
  // 6. Audit write failure does not block flag updates
  // ---------------------------------------------------------------------------

  test('audit write failure does not block flag flips', async () => {
    seedShops([{ id: 'sunil-trading-company', smsCount: 9_500 }]);
    mockAuditAdd.mockRejectedValueOnce(new Error('Firestore unavailable'));

    await capturedHandler!();

    expect(mockBatchCommit).toHaveBeenCalledTimes(1);
    expect(mockLoggerError).toHaveBeenCalledWith(
      'Failed to write phone auth quota audit entry',
      expect.any(Object),
    );
  });

  // ---------------------------------------------------------------------------
  // 7. Shop with no smsCount field → treated as 0, no flag flip
  // ---------------------------------------------------------------------------

  test('shop with no smsCount field → treated as 0, no flag flip', async () => {
    shopQuotaDocs = [
      { id: 'empty-shop', data: () => ({}) }, // no smsCount field
    ];

    await capturedHandler!();

    expect(mockBatchCommit).not.toHaveBeenCalled();
    expect(mockBatchSet).not.toHaveBeenCalled();
  });
});
