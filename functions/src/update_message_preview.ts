// =============================================================================
// updateMessagePreview — Phase 7 chat preview Cloud Function migration.
//
// Firestore-trigger CF on
//   shops/{shopId}/chatThreads/{threadId}/messages/{messageId}
// that:
//   1. Derives a message preview by message type (text / voice_note /
//      system / price_proposal).
//   2. Writes lastMessagePreview + lastMessageAt to BOTH the project doc
//      and the chatThread doc in one batch.
//   3. Increments the recipient-side unread counter on the chatThread doc:
//        - authorRole == 'customer' → unreadCountForShopkeeper += 1
//        - authorRole in {bhaiya, beta, munshi} → unreadCountForCustomer += 1
//        - unknown / missing authorRole → log warning, do not increment.
//
// **Delivery semantics:** Cloud Functions Gen 2 onDocumentCreated is
// at-least-once. The preview field writes are last-write-wins — safe to
// retry. The unread-count increment is NOT idempotent — a retry will
// double-increment. Phase 7 explicitly accepts this best-effort behavior
// because either side opening the chat thread resets the count via the
// existing ChatThreadParticipantPatch flow. Real idempotency (a
// processed-events marker doc + transactional create) is queued for
// Phase 9+.
//
// **Schema:** writes the chatThread.unreadCountForShopkeeper field (per
// packages/lib_core/lib/src/models/chat_thread.dart:25). Earlier drafts
// of the rules included a phantom `unreadCountForOperator` field with no
// model attribute; cleanup of that residue is queued separately.
//
// Phase 7 deploy ordering (CRITICAL):
//   PR 7a: this CF + tests + index export (deploy + verify on staging)
//   PR 7b: remove the existing client-side write in
//          apps/shopkeeper_app/lib/features/chat/shopkeeper_chat_screen.dart
//   PR 7c: remove lastMessagePreview / lastMessageAt from the operator
//          allowlist in firestore.rules
// 7a → 7b → 7c. Each as its own PR with its own Codex review.
// =============================================================================

import * as admin from 'firebase-admin';
import {
  FirestoreEvent,
  onDocumentCreated,
  QueryDocumentSnapshot,
} from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';

const PREVIEW_MAX_CHARS = 80;

/// Canonical authorRole values per
/// packages/lib_core/lib/src/models/* MessageAuthorRole enum.
/// Operator-side roles (any non-customer message increments the
/// customer-side unread counter on the chatThread).
const NON_CUSTOMER_ROLES = new Set(['bhaiya', 'beta', 'munshi']);

type MessageEvent = FirestoreEvent<
  QueryDocumentSnapshot | undefined,
  { shopId: string; threadId: string; messageId: string }
>;

/// Pure helper — exposed for unit testing.
export function derivePreview(message: Record<string, unknown>): string {
  const type = message.type as string | undefined;
  switch (type) {
    case 'voice_note':
      return '🎤 आवाज़ नोट';
    case 'price_proposal': {
      const price = message.proposedPrice as number | undefined;
      return price != null
        ? `मूल्य प्रस्ताव: ₹${price.toLocaleString('en-IN')}`
        : 'मूल्य प्रस्ताव';
    }
    case 'text':
    case 'system':
    default: {
      const text = (message.textBody as string | undefined) ?? '';
      if (text.length > PREVIEW_MAX_CHARS) {
        return `${text.substring(0, PREVIEW_MAX_CHARS)}…`;
      }
      return text || 'नया संदेश';
    }
  }
}

/// Exported for unit testing — allows the test suite to invoke the handler
/// directly with a mocked admin.firestore() and a constructed event.
export async function handleMessageCreate(event: MessageEvent): Promise<void> {
  const snap = event.data;
  if (!snap) {
    logger.warn('updateMessagePreview: no snapshot in event');
    return;
  }
  const message = snap.data();
  const { shopId, threadId, messageId } = event.params;

  const preview = derivePreview(message);
  const authorRole = message.authorRole as string | undefined;

  const db = admin.firestore();
  const shopRef = db.collection('shops').doc(shopId);
  // threadId == projectId (1:1 chat per project per PRD P2.4).
  const projectRef = shopRef.collection('projects').doc(threadId);
  const threadRef = shopRef.collection('chatThreads').doc(threadId);

  const batch = db.batch();
  const now = admin.firestore.FieldValue.serverTimestamp();

  batch.set(
    projectRef,
    {
      lastMessagePreview: preview,
      lastMessageAt: now,
      updatedAt: now,
    },
    { merge: true },
  );

  // Recipient-side unread field by authorRole:
  //   'customer'                → shopkeeper-side unread increments
  //   bhaiya / beta / munshi    → customer-side unread increments
  //   anything else / missing   → log warn, do NOT increment.
  let unreadField:
    | 'unreadCountForShopkeeper'
    | 'unreadCountForCustomer'
    | null = null;
  if (authorRole === 'customer') {
    unreadField = 'unreadCountForShopkeeper';
  } else if (authorRole && NON_CUSTOMER_ROLES.has(authorRole)) {
    unreadField = 'unreadCountForCustomer';
  } else {
    logger.warn(
      'updateMessagePreview: unknown authorRole, skipping unread increment',
      { shopId, threadId, messageId, authorRole },
    );
  }

  const threadUpdate: Record<string, unknown> = {
    lastMessagePreview: preview,
    lastMessageAt: now,
    updatedAt: now,
  };
  if (unreadField !== null) {
    // NOT idempotent under at-least-once retry. See doc-comment.
    threadUpdate[unreadField] = admin.firestore.FieldValue.increment(1);
  }
  batch.set(threadRef, threadUpdate, { merge: true });

  await batch.commit();
  logger.info('updateMessagePreview: applied', {
    shopId,
    threadId,
    messageId,
    unreadField,
  });
}

export const updateMessagePreview = onDocumentCreated(
  {
    region: 'asia-south1',
    document: 'shops/{shopId}/chatThreads/{threadId}/messages/{messageId}',
    memory: '256MiB',
    timeoutSeconds: 30,
  },
  handleMessageCreate,
);
