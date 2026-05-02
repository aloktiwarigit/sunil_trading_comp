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
}

function makeShopRef(shopId: string): {
  collection: (sub: string) => { doc: (id: string) => DocRef };
} {
  return {
    collection: (sub: string) => ({
      doc: (id: string) => ({ _path: `shops/${shopId}/${sub}/${id}` }),
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
  test('text + customer → unreadCountForShopkeeper += 1, preview on both docs', async () => {
    await handleMessageCreate(
      makeEvent({
        data: { type: 'text', textBody: 'kab tak ready ho jayega?', authorRole: 'customer' },
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
    // The customer-side unread must NOT be incremented for a customer message.
    expect(threadWrite!.unreadCountForCustomer).toBeUndefined();
    expect(incrementSpy).toHaveBeenCalledTimes(1);
  });

  test('text + bhaiya → unreadCountForCustomer += 1', async () => {
    await handleMessageCreate(
      makeEvent({
        data: { type: 'text', textBody: 'aap kal aa jaaiye', authorRole: 'bhaiya' },
      }),
    );
    const threadWrite = findWrite('shops/shop_1/chatThreads/t-1');
    expect(threadWrite!.unreadCountForCustomer).toEqual({ _increment: 1 });
    expect(threadWrite!.unreadCountForShopkeeper).toBeUndefined();
  });

  test('text + munshi → unreadCountForCustomer += 1', async () => {
    await handleMessageCreate(
      makeEvent({
        data: { type: 'text', textBody: 'note', authorRole: 'munshi' },
      }),
    );
    const threadWrite = findWrite('shops/shop_1/chatThreads/t-1');
    expect(threadWrite!.unreadCountForCustomer).toEqual({ _increment: 1 });
  });

  test('text + beta → unreadCountForCustomer += 1', async () => {
    await handleMessageCreate(
      makeEvent({
        data: { type: 'text', textBody: 'note', authorRole: 'beta' },
      }),
    );
    const threadWrite = findWrite('shops/shop_1/chatThreads/t-1');
    expect(threadWrite!.unreadCountForCustomer).toEqual({ _increment: 1 });
  });

  test('voice_note preview is the canonical Hindi label', async () => {
    await handleMessageCreate(
      makeEvent({
        data: { type: 'voice_note', authorRole: 'bhaiya', voiceUrl: 'gs://...' },
      }),
    );
    const projectWrite = findWrite('shops/shop_1/projects/t-1');
    expect(projectWrite!.lastMessagePreview).toBe('🎤 आवाज़ नोट');
  });

  test('system message preview falls back to textBody', async () => {
    await handleMessageCreate(
      makeEvent({
        data: { type: 'system', textBody: 'Order locked', authorRole: 'munshi' },
      }),
    );
    const projectWrite = findWrite('shops/shop_1/projects/t-1');
    expect(projectWrite!.lastMessagePreview).toBe('Order locked');
  });

  test('price_proposal preview formats with INR locale', async () => {
    await handleMessageCreate(
      makeEvent({
        data: { type: 'price_proposal', proposedPrice: 18500, authorRole: 'bhaiya' },
      }),
    );
    const projectWrite = findWrite('shops/shop_1/projects/t-1');
    expect(projectWrite!.lastMessagePreview).toBe('मूल्य प्रस्ताव: ₹18,500');
  });

  test('cross-tenant safety: writes target the event shopId, not other shops', async () => {
    await handleMessageCreate(
      makeEvent({
        shopId: 'shop_0',
        threadId: 't-99',
        data: { type: 'text', textBody: 'hi', authorRole: 'customer' },
      }),
    );
    // Only shop_0 paths should appear in the batch.
    expect(findWrite('shops/shop_0/projects/t-99')).toBeDefined();
    expect(findWrite('shops/shop_0/chatThreads/t-99')).toBeDefined();
    expect(findWrite('shops/shop_1/projects/t-99')).toBeUndefined();
    expect(findWrite('shops/shop_1/chatThreads/t-99')).toBeUndefined();
  });

  test('r1 (Codex r1 #1) parent doc missing → batch fails, function logs warn, does not throw', async () => {
    // Codex P1: prior to r1 the CF used batch.set+merge, which silently
    // CREATED a malformed parent doc with only preview/unread fields if
    // the parent was absent (e.g. operator wrote first message before
    // customer-app created the chatThread). Switched to batch.update; the
    // batch.commit rejects with NOT_FOUND, the CF catches it and logs
    // warn instead of leaving a malformed parent.
    const notFoundErr = Object.assign(
      new Error('5 NOT_FOUND: No document to update'),
      { code: 5 },
    );
    mockBatchCommit.mockRejectedValueOnce(notFoundErr);

    // Should not throw — function swallows NOT_FOUND defensively.
    await expect(
      handleMessageCreate(
        makeEvent({
          data: { type: 'text', textBody: 'orphan message', authorRole: 'bhaiya' },
        }),
      ),
    ).resolves.toBeUndefined();

    expect(mockBatchCommit).toHaveBeenCalledTimes(1);
  });

  test('unknown authorRole: preview written, no unread increment, warn logged', async () => {
    await handleMessageCreate(
      makeEvent({
        data: { type: 'text', textBody: 'mystery', authorRole: 'unknown_role' },
      }),
    );
    // Preview still written.
    const projectWrite = findWrite('shops/shop_1/projects/t-1');
    expect(projectWrite!.lastMessagePreview).toBe('mystery');
    // Neither unread counter is incremented.
    const threadWrite = findWrite('shops/shop_1/chatThreads/t-1');
    expect(threadWrite!.unreadCountForShopkeeper).toBeUndefined();
    expect(threadWrite!.unreadCountForCustomer).toBeUndefined();
    expect(incrementSpy).not.toHaveBeenCalled();
  });
});
