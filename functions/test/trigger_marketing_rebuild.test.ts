// =============================================================================
// triggerMarketingRebuild tests — PRD M5.5 + SAD §7 Function 6.
//
// Unit tests for the marketing rebuild trigger. We mock firebase-admin,
// firebase-functions, and global fetch to isolate the function body.
//
// Coverage:
//   1. Theme update triggers GitHub Actions workflow_dispatch
//   2. Debounce — recent rebuild skips dispatch
//   3. Debounce — stale timestamp allows dispatch
//   4. Empty GITHUB_PAT logs error and returns
//   5. GitHub API non-204 response logs error
//   6. Network error on fetch logs error
//   7. Debounce timestamp update failure is non-blocking
//   8. First-ever trigger (no status doc) dispatches successfully
// =============================================================================

/* eslint-disable @typescript-eslint/no-explicit-any */

// ---- Mock firebase-admin ----

const mockStatusGet = jest.fn();
const mockStatusSet = jest.fn().mockResolvedValue(undefined);

const mockFirestore = jest.fn(() => ({
  collection: jest.fn((name: string) => {
    if (name === 'system') {
      return {
        doc: (_id: string) => ({
          get: mockStatusGet,
          set: mockStatusSet,
        }),
      };
    }
    return {};
  }),
}));

(mockFirestore as any).FieldValue = {
  serverTimestamp: () => '__server_timestamp__',
};
(mockFirestore as any).Timestamp = {
  // Simulate Timestamp instances with toMillis
};

// Helper class to simulate Firestore Timestamp
class MockTimestamp {
  constructor(private _millis: number) {}
  toMillis() {
    return this._millis;
  }
}

jest.mock('firebase-admin', () => {
  const ts = MockTimestamp;
  const fs = mockFirestore;
  (fs as any).Timestamp = ts;
  return {
    apps: [{ name: '[DEFAULT]' }],
    initializeApp: jest.fn(),
    firestore: fs,
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

// ---- Mock defineSecret ----

let mockSecretValue = 'ghp_test_pat_1234567890';

jest.mock('firebase-functions/params', () => ({
  defineSecret: jest.fn((_name: string) => ({
    value: () => mockSecretValue,
  })),
}));

// ---- Mock the Firestore trigger decorator ----

let capturedHandler: ((event: any) => Promise<void>) | null = null;

jest.mock('firebase-functions/v2/firestore', () => ({
  onDocumentWritten: jest.fn((_config: unknown, handler: any) => {
    capturedHandler = handler;
    return handler;
  }),
}));

// ---- Mock global fetch ----

const mockFetch = jest.fn();
(global as any).fetch = mockFetch;

// ---- Import the function under test AFTER mocks are registered ----

import './../src/trigger_marketing_rebuild';

// ---- Test helpers ----

function makeEvent(shopId: string) {
  return {
    params: { shopId },
  };
}

function mockStatusDocWith(data: Record<string, any> | null) {
  mockStatusGet.mockResolvedValue({
    data: () => data,
  });
}

beforeEach(() => {
  jest.clearAllMocks();
  mockSecretValue = 'ghp_test_pat_1234567890';
  mockStatusDocWith(null); // Default: no previous status doc
  mockFetch.mockResolvedValue({ status: 204 });
});

describe('triggerMarketingRebuild', () => {
  // ---------------------------------------------------------------------------
  // 1. Successful dispatch
  // ---------------------------------------------------------------------------

  test('theme update triggers workflow_dispatch with correct payload', async () => {
    expect(capturedHandler).not.toBeNull();

    await capturedHandler!(makeEvent('sunil-trading-company'));

    expect(mockFetch).toHaveBeenCalledTimes(1);
    const [url, opts] = mockFetch.mock.calls[0];
    expect(url).toContain('actions/workflows/ci-marketing.yml/dispatches');
    expect(opts.method).toBe('POST');
    expect(opts.headers.Authorization).toBe('Bearer ghp_test_pat_1234567890');

    const body = JSON.parse(opts.body);
    expect(body.ref).toBe('main');
    expect(body.inputs.shop_id).toBe('sunil-trading-company');

    // Debounce timestamp updated
    expect(mockStatusSet).toHaveBeenCalledWith(
      expect.objectContaining({
        'lastTriggeredAt_sunil-trading-company': '__server_timestamp__',
        lastShopId: 'sunil-trading-company',
      }),
      { merge: true },
    );

    expect(mockLoggerInfo).toHaveBeenCalledWith(
      'Marketing rebuild triggered successfully',
      { shopId: 'sunil-trading-company' },
    );
  });

  // ---------------------------------------------------------------------------
  // 2. Debounce — recent rebuild skips dispatch
  // ---------------------------------------------------------------------------

  test('debounces if rebuild was triggered <60s ago', async () => {
    // Last triggered 30 seconds ago
    const thirtySecondsAgo = Date.now() - 30_000;
    mockStatusDocWith({
      'lastTriggeredAt_sunil-trading-company': new MockTimestamp(thirtySecondsAgo),
    });

    await capturedHandler!(makeEvent('sunil-trading-company'));

    expect(mockFetch).not.toHaveBeenCalled();
    expect(mockLoggerInfo).toHaveBeenCalledWith(
      'Debounced — rebuild already triggered recently',
      expect.objectContaining({
        shopId: 'sunil-trading-company',
      }),
    );
  });

  // ---------------------------------------------------------------------------
  // 3. Debounce — stale timestamp allows dispatch
  // ---------------------------------------------------------------------------

  test('dispatches if last rebuild was >60s ago', async () => {
    // Last triggered 120 seconds ago
    const twoMinutesAgo = Date.now() - 120_000;
    mockStatusDocWith({
      'lastTriggeredAt_sunil-trading-company': new MockTimestamp(twoMinutesAgo),
    });

    await capturedHandler!(makeEvent('sunil-trading-company'));

    expect(mockFetch).toHaveBeenCalledTimes(1);
  });

  // ---------------------------------------------------------------------------
  // 4. Empty GITHUB_PAT
  // ---------------------------------------------------------------------------

  test('empty PAT logs error and does not dispatch', async () => {
    mockSecretValue = '';

    await capturedHandler!(makeEvent('sunil-trading-company'));

    expect(mockFetch).not.toHaveBeenCalled();
    expect(mockLoggerError).toHaveBeenCalledWith(
      expect.stringContaining('GITHUB_PAT secret is empty'),
    );
  });

  // ---------------------------------------------------------------------------
  // 5. GitHub API non-204 response
  // ---------------------------------------------------------------------------

  test('non-204 response logs error and does not update debounce', async () => {
    mockFetch.mockResolvedValue({
      status: 403,
      text: async () => '{"message":"Bad credentials"}',
    });

    await capturedHandler!(makeEvent('sunil-trading-company'));

    expect(mockLoggerError).toHaveBeenCalledWith(
      'GitHub Actions workflow_dispatch failed',
      expect.objectContaining({
        shopId: 'sunil-trading-company',
        status: 403,
      }),
    );
    // Debounce timestamp NOT updated on failure
    expect(mockStatusSet).not.toHaveBeenCalled();
  });

  // ---------------------------------------------------------------------------
  // 6. Network error on fetch
  // ---------------------------------------------------------------------------

  test('network error logs error and does not update debounce', async () => {
    mockFetch.mockRejectedValue(new Error('ECONNREFUSED'));

    await capturedHandler!(makeEvent('sunil-trading-company'));

    expect(mockLoggerError).toHaveBeenCalledWith(
      'Network error calling GitHub Actions',
      expect.objectContaining({
        shopId: 'sunil-trading-company',
        error: 'ECONNREFUSED',
      }),
    );
    expect(mockStatusSet).not.toHaveBeenCalled();
  });

  // ---------------------------------------------------------------------------
  // 7. Debounce timestamp update failure is non-blocking
  // ---------------------------------------------------------------------------

  test('debounce write failure logs warning but function succeeds', async () => {
    mockStatusSet.mockRejectedValueOnce(new Error('Firestore write failed'));

    await capturedHandler!(makeEvent('sunil-trading-company'));

    expect(mockFetch).toHaveBeenCalledTimes(1);
    expect(mockLoggerWarn).toHaveBeenCalledWith(
      'Failed to update rebuild debounce timestamp',
      expect.objectContaining({
        shopId: 'sunil-trading-company',
      }),
    );
    // Function still logs success
    expect(mockLoggerInfo).toHaveBeenCalledWith(
      'Marketing rebuild triggered successfully',
      expect.any(Object),
    );
  });

  // ---------------------------------------------------------------------------
  // 8. First-ever trigger (no status doc exists)
  // ---------------------------------------------------------------------------

  test('first-ever trigger with no status doc dispatches successfully', async () => {
    mockStatusDocWith(null);

    await capturedHandler!(makeEvent('sunil-trading-company'));

    expect(mockFetch).toHaveBeenCalledTimes(1);
    expect(mockStatusSet).toHaveBeenCalledTimes(1);
  });

  // ---------------------------------------------------------------------------
  // 9. Different shop IDs use separate debounce keys
  // ---------------------------------------------------------------------------

  test('different shops have independent debounce timestamps', async () => {
    // Shop A triggered 30s ago, Shop B never triggered
    mockStatusDocWith({
      'lastTriggeredAt_shop-a': new MockTimestamp(Date.now() - 30_000),
    });

    // Shop B should NOT be debounced
    await capturedHandler!(makeEvent('shop-b'));

    expect(mockFetch).toHaveBeenCalledTimes(1);
  });
});
