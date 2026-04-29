// =============================================================================
// provision_new_shop.test.ts
//
// Coverage:
//   1. Idempotency — existing shop returns { exists: true, shopId }
//   2. Slug validation rejects invalid formats (uppercase, underscore, leading dash)
//   3. Non-yugmaAdmin caller rejected with permission-denied
//   4. Success path writes all 3 collections and sets custom claims
// =============================================================================

/* eslint-disable @typescript-eslint/no-explicit-any */

// ── Capture the onCall handler ──────────────────────────────────────────────
let capturedHandler: ((request: any) => Promise<any>) | null = null;

jest.mock('firebase-functions/v2/https', () => ({
  onCall: jest.fn((_config: unknown, handler: any) => {
    capturedHandler = handler;
    return handler;
  }),
  HttpsError: class extends Error {
    code: string;
    constructor(code: string, message: string) {
      super(message);
      this.code = code;
    }
  },
}));

// ── Mock logger ─────────────────────────────────────────────────────────────
jest.mock('firebase-functions/v2', () => ({
  logger: {
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
  },
}));

// ── Mock firebase-admin ─────────────────────────────────────────────────────
const mockBatchSet = jest.fn();
const mockBatchCommit = jest.fn(async () => ({}));
const mockBatch = { set: mockBatchSet, commit: mockBatchCommit };

const mockAuditAdd = jest.fn(async () => ({}));
const mockSetCustomUserClaims = jest.fn(async () => ({}));

// Controls whether the shop doc already exists (for idempotency test).
let shopAlreadyExists = false;

// Minimal DocumentReference factory — just needs collection() for chaining.
const makeRef = (path: string): any => ({
  _path: path,
  collection: (sub: string) => ({
    doc: (id: string) => makeRef(`${path}/${sub}/${id}`),
    add: mockAuditAdd,
  }),
  get: jest.fn(async () => ({ exists: shopAlreadyExists })),
});

const mockShopRef = makeRef('shops/test-slug');

const mockFirestore = jest.fn(() => ({
  collection: (name: string) => {
    if (name === 'shops') {
      return { doc: (_slug: string) => mockShopRef };
    }
    if (name === 'system') {
      return {
        doc: () => ({
          collection: () => ({ add: mockAuditAdd }),
        }),
      };
    }
    return {};
  },
  batch: () => mockBatch,
}));
(mockFirestore as any).FieldValue = {
  serverTimestamp: () => '__server_timestamp__',
};

jest.mock('firebase-admin', () => ({
  apps: [{ name: '[DEFAULT]' }],
  initializeApp: jest.fn(),
  firestore: mockFirestore,
  auth: jest.fn(() => ({ setCustomUserClaims: mockSetCustomUserClaims })),
}));

// ── Import AFTER mocks ────────────────────────────────────────────────────────
import '../src/provision_new_shop';

// ── Helpers ──────────────────────────────────────────────────────────────────

function makeRequest(auth: {
  uid: string;
  yugmaAdmin?: boolean;
}, data: Record<string, unknown>): any {
  return {
    auth: {
      uid: auth.uid,
      token: {
        ...(auth.yugmaAdmin ? { yugmaAdmin: true } : {}),
      },
    },
    data,
  };
}

const ADMIN_UID = 'yugma-admin-uid';
const OWNER_UID = 'owner-uid-123';
const VALID_SLUG = 'new-test-shop';
const VALID_INPUT = {
  slug: VALID_SLUG,
  brandName: 'Test Shop',
  brandNameDevanagari: 'टेस्ट दुकान',
  ownerUid: OWNER_UID,
  ownerEmail: 'owner@test.local',
};

// ── Tests ─────────────────────────────────────────────────────────────────────

beforeEach(() => {
  jest.clearAllMocks();
  shopAlreadyExists = false;
});

describe('provisionNewShop', () => {
  test('idempotency: existing shop returns { exists: true } without writing', async () => {
    expect(capturedHandler).not.toBeNull();
    shopAlreadyExists = true;

    const result = await capturedHandler!(
      makeRequest({ uid: ADMIN_UID, yugmaAdmin: true }, VALID_INPUT),
    );

    expect(result).toEqual({ exists: true, shopId: VALID_SLUG });
    expect(mockBatchCommit).not.toHaveBeenCalled();
    expect(mockSetCustomUserClaims).not.toHaveBeenCalled();
  });

  describe('slug validation', () => {
    const invalidSlugs = [
      'UPPER-CASE',
      'has_underscore',
      '-leading-dash',
      'trailing-dash-',
      '',
      'a'.repeat(64),
    ];

    test.each(invalidSlugs)('rejects slug "%s" with invalid-argument', async (badSlug) => {
      await expect(
        capturedHandler!(
          makeRequest(
            { uid: ADMIN_UID, yugmaAdmin: true },
            { ...VALID_INPUT, slug: badSlug },
          ),
        ),
      ).rejects.toMatchObject({ code: 'invalid-argument' });
    });
  });

  test('non-yugmaAdmin caller is rejected with permission-denied', async () => {
    await expect(
      capturedHandler!(
        makeRequest({ uid: 'regular-bhaiya-uid' }, VALID_INPUT),
      ),
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  test('success path writes all 3 collections and sets custom claims', async () => {
    const result = await capturedHandler!(
      makeRequest({ uid: ADMIN_UID, yugmaAdmin: true }, VALID_INPUT),
    );

    expect(result).toEqual({ success: true, shopId: VALID_SLUG });

    // 3 batch.set calls: shop doc, theme doc, operators doc.
    expect(mockBatchSet).toHaveBeenCalledTimes(3);
    expect(mockBatchCommit).toHaveBeenCalledTimes(1);

    // Verify shop doc shape (first call).
    const [, shopData] = mockBatchSet.mock.calls[0];
    expect(shopData).toMatchObject({
      shopId: VALID_SLUG,
      brandName: 'Test Shop',
      brandNameDevanagari: 'टेस्ट दुकान',
      ownerUid: OWNER_UID,
      ownerEmail: 'owner@test.local',
      shopLifecycle: 'active',
    });

    // Verify theme doc shape (second call).
    const [, themeData] = mockBatchSet.mock.calls[1];
    expect(themeData).toMatchObject({
      primaryColor: '#6B3410',
      accentColor: '#A0522D',
      brandName: 'Test Shop',
      version: 1,
    });

    // Verify operators doc shape (third call).
    const [, operatorData] = mockBatchSet.mock.calls[2];
    expect(operatorData).toMatchObject({
      uid: OWNER_UID,
      shopId: VALID_SLUG,
      role: 'bhaiya',
      email: 'owner@test.local',
    });

    // Custom claims set with correct payload.
    expect(mockSetCustomUserClaims).toHaveBeenCalledWith(OWNER_UID, {
      shopId: VALID_SLUG,
      role: 'bhaiya',
    });
  });
});
