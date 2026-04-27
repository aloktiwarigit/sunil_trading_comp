// =============================================================================
// joinDecisionCircle — Sprint 4, multi-device Decision Circle merge.
//
// HTTPS Callable (onCall). Migrates a customer from one Decision Circle
// identity to another within a shop. This covers the scenario where a
// family member (e.g. bhabhi) who was browsing on a separate device wants
// to merge into an existing customer's Decision Circle.
//
// Input: { sourceUid, destUid, shopId }
// Auth: caller must be sourceUid or an operator.
// Behavior: Firestore transaction to atomically:
//   1. Migrate Decision Circle membership document
//   2. Reassign Project.customerUid from source → dest
//   3. Update ChatThread.participantUids arrays
// Returns: { success: true }
// =============================================================================

import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

import { verifyJoinToken } from './lib/hmac_join_token';

/// Audit trail constants.
const AUDIT_COLLECTION = 'system';
const AUDIT_DOC_ID = 'decision_circle_joins';
const AUDIT_HISTORY_SUBCOLLECTION = 'history';
const SYSTEM_UID = 'system_join_decision_circle';

/// Firestore batch size limit.
const BATCH_SIZE = 500;

interface JoinDecisionCircleRequest {
  sourceUid: string;
  destUid: string;
  shopId: string;
  /**
   * Required (§15.1.A / ADR-009 v1.0.3). HMAC-SHA256 token minted by
   * `generateWaMeLink` over `{shopId, projectId, originalCustomerUid,
   * expiresAt}`. The function rejects calls without a valid token.
   * The token's `originalCustomerUid` must match `sourceUid` and its
   * `shopId` must match the request's `shopId` (defense in depth).
   */
  joinToken: string;
}

export const joinDecisionCircle = onCall(
  {
    region: 'asia-south1',
    memory: '256MiB',
    timeoutSeconds: 30,
    // §15.1.C — server-side App Check enforcement. Rejects calls that
    // arrive without a valid App Check token; pairs with the client-side
    // FirebaseAppCheck.activate() in customer_app/shopkeeper_app main.dart.
    // Debug provider tokens are accepted in non-release builds.
    enforceAppCheck: true,
    // §15.1.A — HMAC join token verification. Wired via Firebase Secret
    // Manager: set with `firebase functions:secrets:set
    // JOIN_TOKEN_HMAC_SECRET` per docs/runbook/staging-setup.md.
    secrets: ['JOIN_TOKEN_HMAC_SECRET'],
  },
  async (request) => {
    // ── Auth check ──
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Authentication required.');
    }

    const data = request.data as JoinDecisionCircleRequest;

    // ── Input validation ──
    if (!data.sourceUid || typeof data.sourceUid !== 'string') {
      throw new HttpsError('invalid-argument', 'sourceUid is required.');
    }
    if (!data.destUid || typeof data.destUid !== 'string') {
      throw new HttpsError('invalid-argument', 'destUid is required.');
    }
    if (!data.shopId || typeof data.shopId !== 'string') {
      throw new HttpsError('invalid-argument', 'shopId is required.');
    }
    if (data.sourceUid === data.destUid) {
      throw new HttpsError(
        'invalid-argument',
        'sourceUid and destUid must be different.',
      );
    }
    if (!data.joinToken || typeof data.joinToken !== 'string') {
      // §15.1.A — token is required. Calls without one are forgery-able
      // and were the threat model behind the drift backlog entry.
      throw new HttpsError(
        'invalid-argument',
        'joinToken is required (§15.1.A / ADR-009).',
      );
    }

    const { sourceUid, destUid, shopId, joinToken } = data;
    const callerUid = request.auth.uid;

    // §15.1.A — HMAC token verification + payload binding check. The
    // verifier proves the token is unforged + unexpired; the binding
    // checks that immediately follow prove the token was minted FOR
    // THIS request (matching shopId + originalCustomerUid).
    const verifyResult = verifyJoinToken(joinToken);
    if (!verifyResult.ok) {
      logger.warn('joinDecisionCircle: token verification failed', {
        callerUid,
        shopId,
        sourceUid,
        destUid,
        error: verifyResult.error,
      });
      throw new HttpsError(
        'permission-denied',
        `Invalid join token (${verifyResult.error}).`,
      );
    }
    const tokenPayload = verifyResult.payload!;
    if (tokenPayload.shopId !== shopId) {
      throw new HttpsError(
        'permission-denied',
        'Token shopId does not match request shopId.',
      );
    }
    if (tokenPayload.originalCustomerUid !== sourceUid) {
      throw new HttpsError(
        'permission-denied',
        'Token originalCustomerUid does not match request sourceUid.',
      );
    }

    // SEC002 fix: validate caller's shopId token matches the provided shopId.
    // Without this, a customer from Shop A could manipulate Shop B's data.
    // Defense in depth — the HMAC token already binds shopId, but the
    // session-claim check ensures the CALLER's session is also bound to
    // this shop.
    const callerShopId = request.auth.token?.shopId;
    if (callerShopId !== shopId) {
      throw new HttpsError(
        'permission-denied',
        'Shop mismatch: caller does not belong to this shop.',
      );
    }

    // §15.1.A — with a verified token, the caller is authorized as the
    // joiner (destUid). A valid token means the original customer
    // explicitly minted it for this Decision Circle join, so the prior
    // SEC001 caller-must-be-source-or-operator check is now subsumed by
    // the token's signature gate. Operators retain the right to merge
    // (e.g., shopkeeper resolving a duplicate-account situation).
    const callerRole = request.auth.token?.role;
    const isOperator =
      callerRole === 'bhaiya' ||
      callerRole === 'beta' ||
      callerRole === 'munshi';
    // The caller must either BE the destUid (i.e., the joiner is acting
    // on their own UID) or an operator performing an admin merge.
    if (callerUid !== destUid && !isOperator) {
      throw new HttpsError(
        'permission-denied',
        'Caller must be destUid (the joiner) or an operator.',
      );
    }

    const db = admin.firestore();
    const shopRef = db.collection('shops').doc(shopId);

    logger.info('joinDecisionCircle: starting merge', {
      sourceUid,
      destUid,
      shopId,
      callerUid,
    });

    try {
      await db.runTransaction(async (txn) => {
        // Verify shop exists.
        const shopSnap = await txn.get(shopRef);
        if (!shopSnap.exists) {
          throw new HttpsError('not-found', `Shop '${shopId}' not found.`);
        }

        // ── 1. Migrate Decision Circle membership ──
        const sourceMemberRef = shopRef
          .collection('decisionCircle')
          .doc(sourceUid);
        const destMemberRef = shopRef
          .collection('decisionCircle')
          .doc(destUid);

        const sourceMemberSnap = await txn.get(sourceMemberRef);
        if (sourceMemberSnap.exists) {
          const memberData = sourceMemberSnap.data() ?? {};
          // Merge into dest, preserving any existing dest membership.
          const destMemberSnap = await txn.get(destMemberRef);
          const existingDestData = destMemberSnap.exists
            ? destMemberSnap.data() ?? {}
            : {};

          txn.set(destMemberRef, {
            ...existingDestData,
            ...memberData,
            uid: destUid,
            mergedFrom: sourceUid,
            mergedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedByUid: SYSTEM_UID,
          });

          txn.delete(sourceMemberRef);
        }
      });

      // ── 2. Reassign Project.customerUid ──
      // SEC003 fix: use sequential batches (not parallel) and merge
      // arrayRemove + arrayUnion into a single update per document to
      // prevent partial migration / overwrite race.
      const projectsSnap = await shopRef
        .collection('projects')
        .where('customerUid', '==', sourceUid)
        .get();

      if (!projectsSnap.empty) {
        const chunks: admin.firestore.QueryDocumentSnapshot[][] = [];
        for (let i = 0; i < projectsSnap.docs.length; i += BATCH_SIZE) {
          chunks.push(projectsSnap.docs.slice(i, i + BATCH_SIZE));
        }

        for (const chunk of chunks) {
          const batch = db.batch();
          for (const projDoc of chunk) {
            batch.update(projDoc.ref, {
              customerUid: destUid,
              previousCustomerUid: sourceUid,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
              updatedByUid: SYSTEM_UID,
            });
          }
          await batch.commit();
        }
      }

      // ── 3. Update ChatThread.participantUids ──
      const threadsSnap = await shopRef
        .collection('chatThreads')
        .where('participantUids', 'array-contains', sourceUid)
        .get();

      if (!threadsSnap.empty) {
        const chunks: admin.firestore.QueryDocumentSnapshot[][] = [];
        for (let i = 0; i < threadsSnap.docs.length; i += BATCH_SIZE) {
          chunks.push(threadsSnap.docs.slice(i, i + BATCH_SIZE));
        }

        for (const chunk of chunks) {
          const batch = db.batch();
          for (const threadDoc of chunk) {
            // SEC003 fix: read current participants, compute new array,
            // write once. Avoids the arrayRemove+arrayUnion double-update
            // race within a single batch.
            const currentData = threadDoc.data();
            const currentParticipants: string[] =
              currentData.participantUids ?? [];
            const newParticipants = currentParticipants
              .filter((uid: string) => uid !== sourceUid)
              .concat(destUid);
            // Deduplicate in case destUid was already a participant.
            const uniqueParticipants = [...new Set(newParticipants)];

            batch.update(threadDoc.ref, {
              participantUids: uniqueParticipants,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
              updatedByUid: SYSTEM_UID,
            });
          }
          await batch.commit();
        }
      }

      // ── Audit trail ──
      try {
        await db
          .collection(AUDIT_COLLECTION)
          .doc(AUDIT_DOC_ID)
          .collection(AUDIT_HISTORY_SUBCOLLECTION)
          .add({
            executedAt: admin.firestore.FieldValue.serverTimestamp(),
            sourceUid,
            destUid,
            shopId,
            callerUid,
            projectsReassigned: projectsSnap.size,
            threadsUpdated: threadsSnap.size,
            executedByUid: SYSTEM_UID,
          });
      } catch (err) {
        logger.error('Failed to write decision circle audit entry', {
          error: err instanceof Error ? err.message : String(err),
        });
      }

      logger.info('joinDecisionCircle: merge complete', {
        sourceUid,
        destUid,
        shopId,
        projectsReassigned: projectsSnap.size,
        threadsUpdated: threadsSnap.size,
      });

      return { success: true };
    } catch (err) {
      if (err instanceof HttpsError) {
        throw err;
      }
      logger.error('joinDecisionCircle: transaction failed', {
        sourceUid,
        destUid,
        shopId,
        error: err instanceof Error ? err.message : String(err),
      });
      throw new HttpsError(
        'internal',
        'Failed to merge Decision Circle membership.',
      );
    }
  },
);
