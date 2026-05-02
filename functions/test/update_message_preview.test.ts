// =============================================================================
// updateMessagePreview tests — Phase 7 chat preview CF migration.
//
// Coverage (9 tests, no idempotency claim — see CF doc comment):
//   1. text + customer    → preview written; unreadCountForShopkeeper += 1
//   2. text + bhaiya      → preview written; unreadCountForCustomer += 1
//   3. text + munshi      → same as bhaiya
//   4. text + beta        → same as bhaiya
//   5. voice_note         → preview is '🎤 आवाज़ नोट'
//   6. system             → preview is first 80 chars of textBody
//   7. price_proposal     → preview is 'मूल्य प्रस्ताव: ₹{price}'
//   8. cross-tenant       → writes target shops/{eventShopId}, not other shops
//   9. unknown authorRole → preview written; unread NOT incremented (warn)
//
// NOTE: at-least-once delivery is NOT tested as idempotent. The CF
// explicitly accepts best-effort behavior for unread counters; real
// idempotency is queued for Phase 9+. See update_message_preview.ts
// doc comment.
// =============================================================================

/* eslint-disable @typescript-eslint/no-explicit-any */

// ---- Mocks (must come before importing the CF) ----

const mockBatchSet = jest.fn();
const mockBatchUpdate = jest.fn();
const mockBatchCommit = jest.fn().mockResolvedValue(undefined);
const mockBatch = jest.fn(() => ({
  set: mockBatchSet,
  update: mockBatchUpdate,
  commit: mockBatchCommit,
}));

interface DocRef {
  _path: string;
  get: () => Promise<{
    exists: boolean;
    data: () => Record<string, unknown> | undefined;
  }>;
}

// Test-controlled chatThread doc shape. Each test sets this before invoking
// handleMessageCreate to control whether the parent thread exists and what
// customerUid is stored on it (for trusted unread routing — Codex r2 #1).
let mockThreadDoc: {
  exists: boolean;
  data?: Record<string, unknown>;
} = {
  exists: true,
  data: { customerUid: 'cust-default' },
};

function makeDocRef(path: string): DocRef {
  return {
    _path: path,
    get: async () => {
      if (path.includes('/chatThreads/')) {
        return {
          exists: mockThreadDoc.exists,
          data: () => mockThreadDoc.data,
        };
      }
      // Project / other doc reads are not exercised by the current CF, but
      // return a benign default so any future read-path additions don't
      // silently throw.
      return { exists: true, data: () => ({}) };
    },
  };
}

function makeShopRef(shopId: string): {
  collection: (sub: string) => { doc: (id: string) => DocRef };
} {
  return {
    collection: (sub: string) => ({
      doc: (id: string) => makeDocRef(`shops/${shopId}/${sub}/${id}`),
    }),
  };
}

const mockFirestore = jest.fn(() => ({
  collection: (name: string) => {
    if (name !== 'shops') {
      throw new Error(`Unexpected top-level collection: ${name}`);
    }
    return {
      doc: (shopId: string) => makeShopRef(shopId),
    };
  },
  batch: mockBatch,
}));

const SERVER_TS_SENTINEL = Symbol('server-ts');
const incrementSpy = jest.fn((n: number) => ({ _increment: n }));

jest.mock('firebase-admin', () => ({
  firestore: Object.assign(
    () => mockFirestore(),
    {
      FieldValue: {
        serverTimestamp: () => SERVER_TS_SENTINEL,
        increment: (n: number) => incrementSpy(n),
      },
    },
  ),
  initializeApp: jest.fn(),
}));

jest.mock('firebase-functions/v2', () => ({
  logger: {
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
  },
}));

// onDocumentCreated is invoked at module load to wrap the handler. Stub it
// so we can extract the handler that update_message_preview.ts passes in,
// without actually subscribing to Firestore events.
jest.mock('firebase-functions/v2/firestore', () => ({
  onDocumentCreated: (_options: unknown, handler: unknown) => handler,
}));

// ---- Imports (after mocks are wired) ----

import {
  derivePreview,
  handleMessageCreate,
} from '../src/update_message_preview';

// Helper: build a fake event with the shape the handler reads.
function makeEvent(opts: {
  shopId?: string;
  threadId?: string;
  messageId?: string;
  data: Record<string, unknown>;
}): any {
  return {
    data: { data: () => opts.data },
    params: {
      shopId: opts.shopId ?? 'shop_1',
      threadId: opts.threadId ?? 't-1',
      messageId: opts.messageId ?? 'm-1',
    },
  };
}

// Helper: scan mockBatchUpdate (and mockBatchSet for legacy) calls for a
// write to a specific path. Returns the update map argument, or undefined
// if no such write happened. Phase 7a r1 (Codex r1 #1) switched the CF
// from batch.set+merge to batch.update; this helper looks at both so the
// helper survives any future tweaks.
function findWrite(path: string): Record<string, unknown> | undefined {
  for (const call of mockBatchUpdate.mock.calls) {
    const ref = call[0] as DocRef;
    if (ref._path === path) {
      return call[1] as Record<string, unknown>;
    }
  }
  for (const call of mockBatchSet.mock.calls) {
    const ref = call[0] as DocRef;
    if (ref._path === path) {
      return call[1] as Record<string, unknown>;
    }
  }
  return undefined;
}

beforeEach(() => {
  mockBatchSet.mockClear();
  mockBatchUpdate.mockClear();
  mockBatchCommit.mockClear();
  mockBatchCommit.mockResolvedValue(undefined);
  mockBatch.mockClear();
  mockFirestore.mockClear();
  incrementSpy.mockClear();
  // Default: thread exists, customer is 'cust-default'. Tests override.
  mockThreadDoc = {
    exists: true,
    data: { customerUid: 'cust-default' },
  };
});

describe('updateMessagePreview — derivePreview pure helper', () => {
  test('text type returns first 80 chars; longer text gets ellipsis', () => {
    expect(derivePreview({ type: 'text', textBody: 'hello' })).toBe('hello');
    const long = 'a'.repeat(120);
    const out = derivePreview({ type: 'text', textBody: long });
    expect(out.length).toBe(81); // 80 + ellipsis
    expect(out.endsWith('…')).toBe(true);
  });

  test('voice_note returns the canonical Hindi label', () => {
    expect(derivePreview({ type: 'voice_note' })).toBe('🎤 आवाज़ नोट');
  });

  test('price_proposal formats price with INR locale', () => {
    expect(
      derivePreview({ type: 'price_proposal', proposedPrice: 25000 }),
    ).toBe('मूल्य प्रस्ताव: ₹25,000');
  });

  test('price_proposal without proposedPrice returns the bare label', () => {
    expect(derivePreview({ type: 'price_proposal' })).toBe('मूल्य प्रस्ताव');
  });

  test('system type uses textBody like text type', () => {
    expect(derivePreview({ type: 'system', textBody: 'Order confirmed' }))
      .toBe('Order confirmed');
  });

  test('empty text falls back to default Hindi placeholder', () => {
    expect(derivePreview({ type: 'text', textBody: '' })).toBe('नया संदेश');
    expect(derivePreview({ type: 'text' })).toBe('नया संदेश');
  });
});

describe('updateMessagePreview — handleMessageCreate', () => {
  test('customer message (authorUid == thread.customerUid) → unreadCountForShopkeeper += 1', async () => {
    mockThreadDoc = { exists: true, data: { customerUid: 'alice' } };
    await handleMessageCreate(
      makeEvent({
        data: {
          type: 'text',
          textBody: 'kab tak ready ho jayega?',
          authorUid: 'alice', // matches thread.customerUid
          authorRole: 'customer',
        },
      }),
    );

    expect(mockBatchCommit).toHaveBeenCalledTimes(1);

    const projectWrite = findWrite('shops/shop_1/projects/t-1');
    expect(projectWrite).toBeDefined();
    expect(projectWrite!.lastMessagePreview).toBe('kab tak ready ho jayega?');

    const threadWrite = findWrite('shops/shop_1/chatThreads/t-1');
    expect(threadWrite).toBeDefined();
    expect(threadWrite!.lastMessagePreview).toBe('kab tak ready ho jayega?');
    expect(threadWrite!.unreadCountForShopkeeper).toEqual({ _increment: 1 });
    expect(threadWrite!.unreadCountForCustomer).toBeUndefined();
    expect(incrementSpy).toHaveBeenCalledTimes(1);
  });

  test('operator message (authorUid != thread.customerUid) → unreadCountForCustomer += 1', async () => {
    mockThreadDoc = { exists: true, data: { customerUid: 'alice' } };
    await handleMessageCreate(
      makeEvent({
        data: {
          type: 'text',
          textBody: 'aap kal aa jaaiye',
          authorUid: 'op-shop_1-owner', // operator, not the thread's customer
          authorRole: 'bhaiya',
        },
      }),
    );
    const threadWrite = findWrite('shops/shop_1/chatThreads/t-1');
    expect(threadWrite!.unreadCountForCustomer).toEqual({ _increment: 1 });
    expect(threadWrite!.unreadCountForShopkeeper).toBeUndefined();
  });

  test('r2 (Codex r2 #1) — price-acceptance flow with authorRole="system" but customer authorUid → routed to shopkeeper unread', async () => {
    // The price-acceptance flow legitimately writes authorRole='system'
    // with the customer's authorUid. The pre-r2 form (authorRole-based
    // routing) would have skipped the unread increment because 'system'
    // is not in {customer,bhaiya,beta,munshi}. After r2 the trust-bound
    // authorUid+customerUid comparison correctly routes to shopkeeper.
    mockThreadDoc = { exists: true, data: { customerUid: 'alice' } };
    await handleMessageCreate(
      makeEvent({
        data: {
          type: 'price_proposal',
          proposedPrice: 22000,
          authorUid: 'alice', // customer
          authorRole: 'system', // legitimately written by price-acceptance flow
        },
      }),
    );
    const threadWrite = findWrite('shops/shop_1/chatThreads/t-1');
    expect(threadWrite!.unreadCountForShopkeeper).toEqual({ _increment: 1 });
    expect(threadWrite!.unreadCountForCustomer).toBeUndefined();
  });

  test('voice_note preview is the canonical Hindi label', async () => {
    mockThreadDoc = { exists: true, data: { customerUid: 'alice' } };
    await handleMessageCreate(
      makeEvent({
        data: {
          type: 'voice_note',
          authorUid: 'op-shop_1-owner',
          voiceUrl: 'gs://...',
        },
      }),
    );
    const projectWrite = findWrite('shops/shop_1/projects/t-1');
    expect(projectWrite!.lastMessagePreview).toBe('🎤 आवाज़ नोट');
  });

  test('system message preview falls back to textBody', async () => {
    mockThreadDoc = { exists: true, data: { customerUid: 'alice' } };
    await handleMessageCreate(
      makeEvent({
        data: {
          type: 'system',
          textBody: 'Order locked',
          authorUid: 'op-shop_1-owner',
        },
      }),
    );
    const projectWrite = findWrite('shops/shop_1/projects/t-1');
    expect(projectWrite!.lastMessagePreview).toBe('Order locked');
  });

  test('price_proposal preview formats with INR locale', async () => {
    mockThreadDoc = { exists: true, data: { customerUid: 'alice' } };
    await handleMessageCreate(
      makeEvent({
        data: {
          type: 'price_proposal',
          proposedPrice: 18500,
          authorUid: 'op-shop_1-owner',
        },
      }),
    );
    const projectWrite = findWrite('shops/shop_1/projects/t-1');
    expect(projectWrite!.lastMessagePreview).toBe('मूल्य प्रस्ताव: ₹18,500');
  });

  test('cross-tenant safety: writes target the event shopId, not other shops', async () => {
    mockThreadDoc = { exists: true, data: { customerUid: 'alice' } };
    await handleMessageCreate(
      makeEvent({
        shopId: 'shop_0',
        threadId: 't-99',
        data: { type: 'text', textBody: 'hi', authorUid: 'alice' },
      }),
    );
    expect(findWrite('shops/shop_0/projects/t-99')).toBeDefined();
    expect(findWrite('shops/shop_0/chatThreads/t-99')).toBeDefined();
    expect(findWrite('shops/shop_1/projects/t-99')).toBeUndefined();
    expect(findWrite('shops/shop_1/chatThreads/t-99')).toBeUndefined();
  });

  test('r3 (Codex r3 #1) — chatThread parent missing → project preview still updated, thread write skipped, warn logged', async () => {
    // Pre-r3 the CF returned early when the thread was missing, dropping
    // the project preview update too. The result was that the first
    // operator message would not appear in the project list until the
    // customer opened the chat (which creates the thread). r3 keeps the
    // project update flowing and only skips the thread write.
    mockThreadDoc = { exists: false };
    await handleMessageCreate(
      makeEvent({
        data: { type: 'text', textBody: 'first message', authorUid: 'op-1' },
      }),
    );
    // Project preview is written.
    const projectWrite = findWrite('shops/shop_1/projects/t-1');
    expect(projectWrite).toBeDefined();
    expect(projectWrite!.lastMessagePreview).toBe('first message');
    // Thread write is skipped entirely.
    expect(findWrite('shops/shop_1/chatThreads/t-1')).toBeUndefined();
    // Batch.commit still runs (with just the project write).
    expect(mockBatchCommit).toHaveBeenCalledTimes(1);
  });

  test('r1 — project doc missing (thread exists) → batch.commit rejects, function swallows NOT_FOUND', async () => {
    // Even with the chatThread present, the project doc could be absent
    // (rare but possible if a race deletes it). The batch.update on
    // projectRef rejects with NOT_FOUND; the CF catches and logs warn.
    mockThreadDoc = { exists: true, data: { customerUid: 'alice' } };
    const notFoundErr = Object.assign(
      new Error('5 NOT_FOUND: No document to update'),
      { code: 5 },
    );
    mockBatchCommit.mockRejectedValueOnce(notFoundErr);

    await expect(
      handleMessageCreate(
        makeEvent({
          data: { type: 'text', textBody: 'orphan', authorUid: 'alice' },
        }),
      ),
    ).resolves.toBeUndefined();
    expect(mockBatchCommit).toHaveBeenCalledTimes(1);
  });

  test('missing authorUid → preview written, no unread increment, warn logged', async () => {
    mockThreadDoc = { exists: true, data: { customerUid: 'alice' } };
    await handleMessageCreate(
      makeEvent({
        data: { type: 'text', textBody: 'mystery' /* no authorUid */ },
      }),
    );
    // Preview still written on both docs.
    const projectWrite = findWrite('shops/shop_1/projects/t-1');
    expect(projectWrite!.lastMessagePreview).toBe('mystery');
    const threadWrite = findWrite('shops/shop_1/chatThreads/t-1');
    expect(threadWrite!.lastMessagePreview).toBe('mystery');
    // Neither unread counter incremented.
    expect(threadWrite!.unreadCountForShopkeeper).toBeUndefined();
    expect(threadWrite!.unreadCountForCustomer).toBeUndefined();
    expect(incrementSpy).not.toHaveBeenCalled();
  });

  test('thread missing customerUid → preview written, no unread increment, warn logged', async () => {
    // The thread doc exists but lacks customerUid (a malformed thread doc
    // — defensive default). Preview still flows; unread routing skipped.
    mockThreadDoc = { exists: true, data: {} };
    await handleMessageCreate(
      makeEvent({
        data: { type: 'text', textBody: 'data', authorUid: 'alice' },
      }),
    );
    const threadWrite = findWrite('shops/shop_1/chatThreads/t-1');
    expect(threadWrite!.lastMessagePreview).toBe('data');
    expect(threadWrite!.unreadCountForShopkeeper).toBeUndefined();
    expect(threadWrite!.unreadCountForCustomer).toBeUndefined();
  });
});
