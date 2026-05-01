// =============================================================================
// join_decision_circle.test.ts — joinToken backwards-compat (Codex P1-1).
//
// Validates that joinDecisionCircle accepts calls without a joinToken via the
// legacy SEC001 caller-uid-or-role fallback path, while still enforcing the
// token-verified path when a token IS provided.
//
// Coverage:
//   1. Fallback path: sourceUid caller, no joinToken → succeeds + warn logged
//   2. Fallback path: operator caller, no joinToken → succeeds + warn logged
//   3. Fallback path: unauthorized caller (not sourceUid/operator), no joinToken
//      → permission-denied
//   4. Token path: valid token + destUid caller → succeeds, verify called, no warn
//   5. Token path: invalid token → permission-denied
// =============================================================================

/* eslint-disable @typescript-eslint/no-explicit-any */

// ── Capture the onCall handler ──────────────────────────────────────────────
// Must be declared before jest.mock() so the factory closure can reference it.
let capturedHandler: ((request: any) => Promise<any>) | null = null;

jest.mock('firebase-functions/v2/https', () => ({
  onCall: jest.fn((_config: unknown, handler: any) => {
    capturedHandler = handler;
    return handler;
  }),
  // Minimal HttpsError that carries .code so tests can match on it.
  HttpsError: class extends Error {
    code: string;
    constructor(code: string, message: string) {
      super(message);
      this.code = code;
    }
  },
}));

// ── Mock verifyJoinToken ────────────────────────────────────────────────────
// Variables starting with 'mock' are hoisted alongside jest.mock() so the
// factory can reference them safely (Jest treats them specially).
const mockVerifyJoinToken = jest.fn();
jest.mock('../src/lib/hmac_join_token', () => ({
  verifyJoinToken: (...args: any[]) => mockVerifyJoinToken(...args),
}));

// ── Mock logger ─────────────────────────────────────────────────────────────
const mockLoggerWarn = jest.fn();
const mockLoggerInfo = jest.fn();
const mockLoggerError = jest.fn();

jest.mock('firebase-functions/v2', () => ({
  logger: {
    warn: mockLoggerWarn,
    info: mockLoggerInfo,
    error: mockLoggerError,
  },
}));

// ── Mock firebase-admin ─────────────────────────────────────────────────────
// mockTxnGet uses a sentinel property (_isShopRef) to distinguish the shop
// doc (which must exist) from member docs (which need not exist).
const mockTxnGet = jest.fn(async (ref: any) => {
  if (ref && ref._isShopRef) return { exists: true };
  return { exists: false };
});
const mockTxnSet = jest.fn();
const mockTxnDelete = jest.fn();
const mockTxn = { get: mockTxnGet, set: mockTxnSet, delete: mockTxnDelete };

const mockAuditAdd = jest.fn(async () => ({}));

const mockShopRef: any = {
  _isShopRef: true,
  collection: (sub: string) => {
    if (sub === 'decisionCircle') {
      return { doc: (_uid: string) => ({ _memberRef: true }) };
    }
    if (sub === 'projects' || sub === 'chatThreads') {
      // Support both the legacy where().get() path and the token path
      // doc(id).get() (Codex P1-2 — direct fetch avoids composite index).
      const emptySnap = { empty: true, docs: [], size: 0 };
      const q: any = { where: () => q, get: async () => emptySnap };
      return {
        where: () => q,
        // Return an existing thread that contains SOURCE_UID as a participant
        // so the token path can verify ownership + add DEST_UID.
        doc: (_id: string) => ({
          get: async () => ({
            exists: true,
            ref: { update: jest.fn() },
            data: () => ({ participantUids: ['uid_alice'] }),
          }),
          ref: {},
        }),
      };
    }
    return {};
  },
};

const mockBatchUpdate = jest.fn();
const mockBatchCommit = jest.fn(async () => ({}));
const mockBatch = { update: mockBatchUpdate, commit: mockBatchCommit };

const mockFirestore = jest.fn(() => ({
  collection: (name: string) => {
    if (name === 'shops') return { doc: () => mockShopRef };
    if (name === 'system') {
      return {
        doc: () => ({ collection: () => ({ add: mockAuditAdd }) }),
      };
    }
    return {};
  },
  runTransaction: async (fn: any) => fn(mockTxn),
  batch: () => mockBatch,
}));
(mockFirestore as any).FieldValue = {
  serverTimestamp: () => '__server_timestamp__',
};

jest.mock('firebase-admin', () => ({
  apps: [{ name: '[DEFAULT]' }],
  initializeApp: jest.fn(),
  firestore: mockFirestore,
}));

// ── Import the function under test AFTER mocks are registered ───────────────
import '../src/join_decision_circle';

// ── Helpers ─────────────────────────────────────────────────────────────────

interface AuthOpts {
  uid: string;
  shopId: string;
  role?: string;
}

function makeRequest(auth: AuthOpts, data: Record<string, unknown>): any {
  return {
    auth: {
      uid: auth.uid,
      token: {
        shopId: auth.shopId,
        ...(auth.role ? { role: auth.role } : {}),
      },
    },
    data,
  };
}

const SHOP_ID = 'sunil-trading-company';
const SOURCE_UID = 'uid_alice';
const DEST_UID = 'uid_bob';

// ── Tests ────────────────────────────────────────────────────────────────────

beforeEach(() => {
  jest.clearAllMocks();
});

describe('joinDecisionCircle — joinToken backwards-compat (Codex P1-1)', () => {
  describe('fallback path (no joinToken)', () => {
    test('sourceUid caller without joinToken succeeds and logs a warning', async () => {
      expect(capturedHandler).not.toBeNull();

      const result = await capturedHandler!(
        makeRequest(
          { uid: SOURCE_UID, shopId: SHOP_ID },
          { sourceUid: SOURCE_UID, destUid: DEST_UID, shopId: SHOP_ID },
        ),
      );

      expect(result).toEqual({ success: true });
      expect(mockLoggerWarn).toHaveBeenCalledWith(
        expect.stringContaining('joinToken absent'),
        expect.objectContaining({ callerUid: SOURCE_UID, shopId: SHOP_ID }),
      );
      expect(mockVerifyJoinToken).not.toHaveBeenCalled();
    });

    test('operator caller without joinToken succeeds', async () => {
      const result = await capturedHandler!(
        makeRequest(
          { uid: 'uid_bhaiya', shopId: SHOP_ID, role: 'bhaiya' },
          { sourceUid: SOURCE_UID, destUid: DEST_UID, shopId: SHOP_ID },
        ),
      );

      expect(result).toEqual({ success: true });
      expect(mockLoggerWarn).toHaveBeenCalledWith(
        expect.stringContaining('joinToken absent'),
        expect.any(Object),
      );
    });

    test('unauthorized caller without joinToken is rejected with permission-denied', async () => {
      await expect(
        capturedHandler!(
          makeRequest(
            { uid: 'uid_attacker', shopId: SHOP_ID },
            { sourceUid: SOURCE_UID, destUid: DEST_UID, shopId: SHOP_ID },
          ),
        ),
      ).rejects.toMatchObject({ code: 'permission-denied' });
    });
  });

  describe('token path (joinToken provided)', () => {
    test('valid token with destUid caller succeeds without a fallback warning', async () => {
      mockVerifyJoinToken.mockReturnValue({
        ok: true,
        payload: {
          shopId: SHOP_ID,
          projectId: 'p_001',
          originalCustomerUid: SOURCE_UID,
          expiresAt: Date.now() + 999_999,
        },
      });

      const result = await capturedHandler!(
        makeRequest(
          { uid: DEST_UID, shopId: SHOP_ID },
          {
            sourceUid: SOURCE_UID,
            destUid: DEST_UID,
            shopId: SHOP_ID,
            joinToken: 'valid.token',
          },
        ),
      );

      expect(result).toEqual({ success: true });
      expect(mockVerifyJoinToken).toHaveBeenCalledWith('valid.token');
      expect(mockLoggerWarn).not.toHaveBeenCalled();
    });

    test('invalid token is rejected with permission-denied', async () => {
      mockVerifyJoinToken.mockReturnValue({ ok: false, error: 'bad_signature' });

      await expect(
        capturedHandler!(
          makeRequest(
            { uid: DEST_UID, shopId: SHOP_ID },
            {
              sourceUid: SOURCE_UID,
              destUid: DEST_UID,
              shopId: SHOP_ID,
              joinToken: 'forged.token',
            },
          ),
        ),
      ).rejects.toMatchObject({ code: 'permission-denied' });
    });
  });
});
