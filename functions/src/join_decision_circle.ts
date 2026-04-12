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
}

export const joinDecisionCircle = onCall(
  {
    region: 'asia-south1',
    memory: '256MiB',
    timeoutSeconds: 30,
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

    const { sourceUid, destUid, shopId } = data;
    const callerUid = request.auth.uid;

    // Caller must be the sourceUid or an operator (custom claim).
    const isOperator = request.auth.token?.operator === true;
    if (callerUid !== sourceUid && !isOperator) {
      throw new HttpsError(
        'permission-denied',
        'Caller must be sourceUid or an operator.',
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

      // ── 2. Reassign Project.customerUid (outside transaction for batch) ──
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
            batch.update(threadDoc.ref, {
              participantUids: admin.firestore.FieldValue.arrayRemove(
                sourceUid,
              ),
            });
            batch.update(threadDoc.ref, {
              participantUids: admin.firestore.FieldValue.arrayUnion(destUid),
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
