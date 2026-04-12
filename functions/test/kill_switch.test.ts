// =============================================================================
// killSwitchOnBudgetAlert tests — PRD I6.8 + SAD §7 Function 1.
//
// Unit tests for the kill-switch function logic. We DO NOT spin up the
// Firebase emulator for these tests — we mock `firebase-admin` and
// `firebase-functions` to isolate the function body.
//
// Coverage:
//   1. Malformed Pub/Sub payload → logs error, no flag flip, no throw
//   2. Missing numeric costAmount/budgetAmount → logs error, no flag flip
//   3. Sub-50% threshold → informational log only, audit entry written
//   4. 50-99% threshold → warning log, audit entry written, NO flag flip
//   5. 100% threshold → ERROR log, audit entry, batch-write kill flags
//      to every active shop
//   6. Multi-shop batch flipping (seeds 3 shops, asserts all 3 get flags)
//   7. Empty shops collection → logs warning, no crash
//   8. Audit write failure does not block kill-switch flip
// =============================================================================

/* eslint-disable @typescript-eslint/no-explicit-any */

// ---- Mock firebase-admin BEFORE importing the function module ----

const mockBatchSet = jest.fn();
const mockBatchCommit = jest.fn().mockResolvedValue(undefined);
const mockBatch = jest.fn(() => ({
  set: mockBatchSet,
  commit: mockBatchCommit,
}));

const mockAuditAdd = jest.fn().mockResolvedValue({ id: 'audit-doc-1' });

// Track documents seeded into the shops collection per test.
let shopDocs: Array<{ id: string; ref: any }> = [];

const mockShopsGet = jest.fn(async () => ({
  empty: shopDocs.length === 0,
  docs: shopDocs,
}));

const mockDocRef = (path: string) => ({
  collection: (_sub: string) => ({
    doc: (_id: string) => ({ _path: `${path}/featureFlags/runtime` }),
  }),
});

const mockFirestore = jest.fn(() => ({
  collection: jest.fn((name: string) => {
    if (name === 'shops') {
      return { get: mockShopsGet };
    }
    if (name === 'system') {
      return {
        doc: (_id: string) => ({
          collection: (_sub: string) => ({ add: mockAuditAdd }),
        }),
      };
    }
    return { get: jest.fn() };
  }),
  batch: mockBatch,
}));

// Attach FieldValue static to mockFirestore so the function can call
// `admin.firestore.FieldValue.serverTimestamp()`.
(mockFirestore as any).FieldValue = {
  serverTimestamp: () => '__server_timestamp__',
};

jest.mock('firebase-admin', () => {
  return {
    apps: [{ name: '[DEFAULT]' }],
    initializeApp: jest.fn(),
    firestore: mockFirestore,
  };
});

// ---- Mock firebase-functions logger ----

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

// ---- Mock the Pub/Sub trigger decorator ----
//
// `onMessagePublished` is the trigger builder. In production it registers
// the handler with Firebase. In tests we capture the handler so we can
// invoke it directly with synthetic events.

let capturedHandler: ((event: any) => Promise<void>) | null = null;

jest.mock('firebase-functions/v2/pubsub', () => ({
  onMessagePublished: jest.fn((_config: unknown, handler: any) => {
    capturedHandler = handler;
    return handler;
  }),
}));

// ---- Import the function under test AFTER mocks are registered ----

import './../src/kill_switch';

// Helper — build a synthetic Pub/Sub event with a base64 JSON payload.
function makeEvent(payload: unknown) {
  const json = JSON.stringify(payload);
  const base64 = Buffer.from(json, 'utf-8').toString('base64');
  return { data: { message: { data: base64 } } };
}

// Helper — seed the mock shops collection.
function seedShops(ids: string[]) {
  shopDocs = ids.map((id) => ({
    id,
    ref: mockDocRef(`shops/${id}`),
  }));
}

beforeEach(() => {
  jest.clearAllMocks();
  shopDocs = [];
});

describe('killSwitchOnBudgetAlert', () => {
  // ---------------------------------------------------------------------------
  // 1. Malformed payload
  // ---------------------------------------------------------------------------

  test('malformed JSON payload logs error and does not flip flags', async () => {
    expect(capturedHandler).not.toBeNull();
    // Base64-encode invalid JSON
    const invalidEvent = {
      data: {
        message: {
          data: Buffer.from('not valid json {{{', 'utf-8').toString('base64'),
        },
      },
    };

    await capturedHandler!(invalidEvent);

    expect(mockLoggerError).toHaveBeenCalledWith(
      'Failed to parse budget alert payload',
      expect.objectContaining({ error: expect.any(String) }),
    );
    expect(mockBatchCommit).not.toHaveBeenCalled();
    expect(mockBatchSet).not.toHaveBeenCalled();
  });

  // ---------------------------------------------------------------------------
  // 2. Missing numeric fields
  // ---------------------------------------------------------------------------

  test('missing costAmount/budgetAmount logs error and does not flip', async () => {
    const event = makeEvent({
      budgetDisplayName: 'yugma-dukaan-dev $1 cap',
      // costAmount missing
      // budgetAmount missing
      currencyCode: 'USD',
    });

    await capturedHandler!(event);

    expect(mockLoggerError).toHaveBeenCalledWith(
      'Budget alert missing numeric costAmount or budgetAmount',
      expect.any(Object),
    );
    expect(mockBatchCommit).not.toHaveBeenCalled();
  });

  // ---------------------------------------------------------------------------
  // 3. Sub-50% threshold — informational only
  // ---------------------------------------------------------------------------

  test('30% threshold writes audit entry and logs info, no flag flip', async () => {
    seedShops(['sunil-trading-company']);
    const event = makeEvent({
      budgetDisplayName: 'yugma-dukaan-dev $1 cap',
      costAmount: 0.3,
      budgetAmount: 1.0,
      currencyCode: 'USD',
    });

    await capturedHandler!(event);

    expect(mockAuditAdd).toHaveBeenCalledTimes(1);
    expect(mockAuditAdd).toHaveBeenCalledWith(
      expect.objectContaining({
        budgetDisplayName: 'yugma-dukaan-dev $1 cap',
        costAmount: 0.3,
        budgetAmount: 1.0,
        thresholdPercent: 30,
      }),
    );
    expect(mockLoggerInfo).toHaveBeenCalledWith(
      expect.stringContaining('30.0% — informational'),
      expect.any(Object),
    );
    expect(mockBatchCommit).not.toHaveBeenCalled();
    expect(mockBatchSet).not.toHaveBeenCalled();
  });

  // ---------------------------------------------------------------------------
  // 4. Warning zone — 50-99% threshold
  // ---------------------------------------------------------------------------

  test('75% threshold logs warning, writes audit, does NOT flip flags', async () => {
    seedShops(['sunil-trading-company']);
    const event = makeEvent({
      budgetDisplayName: 'yugma-dukaan-dev $1 cap',
      costAmount: 0.75,
      budgetAmount: 1.0,
      currencyCode: 'USD',
    });

    await capturedHandler!(event);

    expect(mockAuditAdd).toHaveBeenCalledTimes(1);
    expect(mockLoggerWarn).toHaveBeenCalledWith(
      expect.stringContaining('75.0% — approaching cap'),
      expect.any(Object),
    );
    expect(mockBatchCommit).not.toHaveBeenCalled();
    expect(mockBatchSet).not.toHaveBeenCalled();
  });

  test('50% exact threshold is warning not informational', async () => {
    seedShops(['sunil-trading-company']);
    const event = makeEvent({
      budgetDisplayName: 'yugma-dukaan-dev $1 cap',
      costAmount: 0.5,
      budgetAmount: 1.0,
      currencyCode: 'USD',
    });

    await capturedHandler!(event);

    expect(mockLoggerWarn).toHaveBeenCalledWith(
      expect.stringContaining('50.0% — approaching cap'),
      expect.any(Object),
    );
    expect(mockBatchCommit).not.toHaveBeenCalled();
  });

  // ---------------------------------------------------------------------------
  // 5. 100% threshold — kill-switch fires
  // ---------------------------------------------------------------------------

  test('100% threshold flips kill-switch flags for every shop', async () => {
    seedShops(['sunil-trading-company']);
    const event = makeEvent({
      budgetDisplayName: 'yugma-dukaan-dev $1 cap',
      costAmount: 1.0,
      budgetAmount: 1.0,
      currencyCode: 'USD',
    });

    await capturedHandler!(event);

    expect(mockAuditAdd).toHaveBeenCalledTimes(1);
    expect(mockBatch).toHaveBeenCalledTimes(1);
    expect(mockBatchSet).toHaveBeenCalledTimes(1);
    expect(mockBatchSet).toHaveBeenCalledWith(
      expect.objectContaining({ _path: expect.stringContaining('featureFlags/runtime') }),
      expect.objectContaining({
        killSwitchActive: true,
        cloudinaryUploadsBlocked: true,
        firestoreWritesBlocked: true,
        otpAtCommitEnabled: false,
        authProviderStrategy: 'upi_only',
        updatedAt: '__server_timestamp__',
        updatedByUid: 'system_kill_switch',
      }),
      expect.objectContaining({ merge: true }),
    );
    expect(mockBatchCommit).toHaveBeenCalledTimes(1);
    expect(mockLoggerError).toHaveBeenCalledWith(
      'BUDGET CAP REACHED — flipping kill-switch flags',
      expect.any(Object),
    );
    expect(mockLoggerError).toHaveBeenCalledWith(
      'Kill-switch activated across all shops',
    );
  });

  test('110% over-threshold also flips flags (no ceiling check)', async () => {
    seedShops(['sunil-trading-company']);
    const event = makeEvent({
      budgetDisplayName: 'yugma-dukaan-dev $1 cap',
      costAmount: 1.1, // over budget
      budgetAmount: 1.0,
      currencyCode: 'USD',
    });

    await capturedHandler!(event);

    expect(mockBatchCommit).toHaveBeenCalledTimes(1);
  });

  // ---------------------------------------------------------------------------
  // 6. Multi-shop batching
  // ---------------------------------------------------------------------------

  test('3-shop tenant set gets all 3 flag flips in one batch', async () => {
    seedShops(['sunil-trading-company', 'shop_2', 'shop_3']);
    const event = makeEvent({
      budgetDisplayName: 'yugma-dukaan-dev $1 cap',
      costAmount: 1.0,
      budgetAmount: 1.0,
      currencyCode: 'USD',
    });

    await capturedHandler!(event);

    // 1 batch, 3 set() calls
    expect(mockBatch).toHaveBeenCalledTimes(1);
    expect(mockBatchSet).toHaveBeenCalledTimes(3);
    expect(mockBatchCommit).toHaveBeenCalledTimes(1);
    expect(mockLoggerError).toHaveBeenCalledWith(
      'Kill-switch flipped for 3 shop(s)',
    );
  });

  // ---------------------------------------------------------------------------
  // 7. Empty shops collection
  // ---------------------------------------------------------------------------

  test('empty shops collection logs warning, no batch writes', async () => {
    seedShops([]);
    const event = makeEvent({
      budgetDisplayName: 'yugma-dukaan-dev $1 cap',
      costAmount: 1.0,
      budgetAmount: 1.0,
      currencyCode: 'USD',
    });

    await capturedHandler!(event);

    expect(mockLoggerWarn).toHaveBeenCalledWith(
      'No shops to flip — kill-switch fired on empty tenant set',
    );
    expect(mockBatch).not.toHaveBeenCalled();
  });

  // ---------------------------------------------------------------------------
  // 8. Audit write failure
  // ---------------------------------------------------------------------------

  test('audit write failure does not block kill-switch flip', async () => {
    seedShops(['sunil-trading-company']);
    mockAuditAdd.mockRejectedValueOnce(new Error('Firestore temporarily unavailable'));

    const event = makeEvent({
      budgetDisplayName: 'yugma-dukaan-dev $1 cap',
      costAmount: 1.0,
      budgetAmount: 1.0,
      currencyCode: 'USD',
    });

    await capturedHandler!(event);

    // Audit write was attempted and failed
    expect(mockAuditAdd).toHaveBeenCalledTimes(1);
    expect(mockLoggerError).toHaveBeenCalledWith(
      'Failed to write budget audit entry',
      expect.any(Object),
    );
    // But the kill-switch STILL flipped
    expect(mockBatchCommit).toHaveBeenCalledTimes(1);
    expect(mockBatchSet).toHaveBeenCalledTimes(1);
  });
});
