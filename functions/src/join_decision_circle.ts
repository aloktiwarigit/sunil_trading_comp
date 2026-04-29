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

import { verifyJoinToken, JoinTokenPayload } from './lib/hmac_join_token';

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
   * Optional (§15.1.A / ADR-009 v1.0.3 + Codex P1-1 backwards-compat).
   * HMAC-SHA256 token minted by `generateWaMeLink`. When present and valid,
   * the token-verified path runs (existing behavior). When absent, falls back
   * to legacy SEC001 caller-uid-or-role check with a structured warning.
   * Will be required once `joinDecisionCircle_enabled` ships in Sprint 5-6.
   */
  joinToken?: string;
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
    const { sourceUid, destUid, shopId } = data;
    const callerUid = request.auth.uid;

    // Normalise joinToken — empty string counts as absent (Codex P1-1).
    const joinToken: string | undefined =
      typeof data.joinToken === 'string' && data.joinToken
        ? data.joinToken
        : undefined;

    // Hoisted so Phases 2 + 3 can scope queries to the token's projectId (Codex P1-2).
    let tokenPayload: JoinTokenPayload | undefined;

    if (joinToken) {
      // §15.1.A — Token-verified path. HMAC token verification + payload
      // binding check proves the token is unforged + unexpired, and that
      // it was minted FOR this specific request (matching shopId +
      // originalCustomerUid).
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
      tokenPayload = verifyResult.payload!;
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
    } else {
      // Legacy fallback (Codex P1-1 backwards-compat) — joinToken absent.
      // HttpsCallableStateMigrationCaller calls without a token; this path
      // keeps mergers working until Sprint 5-6 when the flag flips on and
      // the client starts minting tokens. SEC001 + SEC002 guards still apply.
      logger.warn(
        'joinDecisionCircle: joinToken absent — falling back to legacy auth. ' +
          'Will require token when join_decision_circle_enabled flag ships in Sprint 5-6.',
        { callerUid, shopId, sourceUid, destUid },
      );
    }

    // SEC002: caller's shop claim must match the request shopId. Applies in
    // both token and legacy paths — ensures the caller's session is bound to
    // this shop even when the HMAC token isn't present to enforce it.
    const callerShopId = request.auth.token?.shopId;
    if (callerShopId !== shopId) {
      throw new HttpsError(
        'permission-denied',
        'Shop mismatch: caller does not belong to this shop.',
      );
    }

    const callerRole = request.auth.token?.role;
    const isOperator =
      callerRole === 'bhaiya' ||
      callerRole === 'beta' ||
      callerRole === 'munshi';

    if (joinToken) {
      // Token path: caller must be destUid (the joiner) or an operator.
      // The verified token is the primary authorization; this is defense in depth.
      if (callerUid !== destUid && !isOperator) {
        throw new HttpsError(
          'permission-denied',
          'Caller must be destUid (the joiner) or an operator.',
        );
      }
    } else {
      // Legacy path (SEC001): caller must be sourceUid or an operator.
      if (callerUid !== sourceUid && !isOperator) {
        throw new HttpsError(
          'permission-denied',
          'Caller must be sourceUid or an operator (legacy auth — joinToken absent).',
        );
      }
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
        // Token path (wa.me DC join): this is a PARTICIPANT ADD, not a full
        // account merger. sourceUid is NOT being deprecated — they are still a
        // valid customer with their own DC memberships and projects. Deleting
        // sourceMemberRef unconditionally would orphan other projects in the
        // same shop that weren't part of the shared link. Skip DC migration
        // entirely; the project + chatThread participant updates in Phases 2
        // and 3 are sufficient for the wa.me join use case.
        //
        // Legacy path (phone collision, no token): full account merge —
        // sourceUid is being deprecated. Move DC membership to destUid.
        if (!tokenPayload) {
          const sourceMemberRef = shopRef
            .collection('decisionCircle')
            .doc(sourceUid);
          const destMemberRef = shopRef
            .collection('decisionCircle')
            .doc(destUid);

          const sourceMemberSnap = await txn.get(sourceMemberRef);
          if (sourceMemberSnap.exists) {
            const memberData = sourceMemberSnap.data() ?? {};
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
        }
      });

      // ── 2. Reassign Project.customerUid ──
      // Token path (wa.me DC join): SKIP. The token path is a participant
      // add — sourceUid remains the customer of record for their project.
      // Reassigning customerUid to destUid would break the `firestore.rules`
      // gate `resource.data.customerUid == request.auth.uid` for sourceUid,
      // locking the original customer out of their own order.
      //
      // Legacy path (phone collision, no token): full reassignment.
      // SEC003 fix: sequential batches, merged arrayRemove+arrayUnion.
      let projectsSnap: admin.firestore.QuerySnapshot | null = null;
      if (!tokenPayload) {
        const projectsQuery = shopRef
          .collection('projects')
          .where('customerUid', '==', sourceUid);
        projectsSnap = await projectsQuery.get();
      }

      if (projectsSnap && !projectsSnap.empty) {
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
      // Codex P1-2: when a token is present, the thread to update is the one
      // whose threadId == tokenPayload.projectId. Since threadId == projectId
      // (architecture §6.1 — chatThread document ID == project document ID),
      // we fetch it directly by doc ID — no compound query, no index needed.
      // Legacy path (no token) still queries by participantUids array-contains.
      // updateThread helper — `replaceSource` controls whether sourceUid is
      // removed before destUid is added.
      //   Token path (participant add): replaceSource=false → sourceUid stays,
      //     destUid is added. The original customer keeps chat access.
      //   Legacy path (account merge): replaceSource=true → sourceUid removed,
      //     destUid takes over (existing behaviour).
      const updateThread = async (
        threadRef: admin.firestore.DocumentReference,
        threadData: admin.firestore.DocumentData,
        replaceSource: boolean,
      ): Promise<void> => {
        const currentParticipants: string[] = threadData.participantUids ?? [];
        const filtered = replaceSource
          ? currentParticipants.filter((uid: string) => uid !== sourceUid)
          : currentParticipants;
        const uniqueParticipants = [...new Set([...filtered, destUid])];
        const batch = db.batch();
        batch.update(threadRef, {
          participantUids: uniqueParticipants,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedByUid: SYSTEM_UID,
        });
        await batch.commit();
      };

      let threadsUpdated = 0;
      if (tokenPayload) {
        // Token path: direct fetch by projectId (no index required).
        const threadSnap = await shopRef
          .collection('chatThreads')
          .doc(tokenPayload.projectId)
          .get();
        if (!threadSnap.exists) {
          // A valid token whose projectId has no matching chatThread means the
          // project was deleted or the thread was never created. Surface an
          // explicit error rather than silently returning { success: true }.
          throw new HttpsError(
            'not-found',
            `chatThread for project '${tokenPayload.projectId}' not found.`,
          );
        }
        const threadData = threadSnap.data()!;
        const participants: string[] = threadData.participantUids ?? [];
        // Verify sourceUid is already a participant in this thread.
        // Prevents a malicious customer from adding themselves to
        // another customer's thread by guessing a projectId.
        if (!participants.includes(sourceUid)) {
          throw new HttpsError(
            'permission-denied',
            'sourceUid is not a participant in the target chatThread.',
          );
        }
        // Token path: ADD destUid, keep sourceUid (participant add, not merge).
        await updateThread(threadSnap.ref, threadData, /* replaceSource= */ false);
        threadsUpdated = 1;
      } else {
        // Legacy path: query by participantUids.
        const threadsSnap = await shopRef
          .collection('chatThreads')
          .where('participantUids', 'array-contains', sourceUid)
          .get();
        if (!threadsSnap.empty) {
          threadsUpdated = threadsSnap.size;
          const chunks: admin.firestore.QueryDocumentSnapshot[][] = [];
          for (let i = 0; i < threadsSnap.docs.length; i += BATCH_SIZE) {
            chunks.push(threadsSnap.docs.slice(i, i + BATCH_SIZE));
          }
          for (const chunk of chunks) {
            for (const threadDoc of chunk) {
              // Legacy path: REPLACE sourceUid with destUid (full account merge).
              await updateThread(threadDoc.ref, threadDoc.data(), /* replaceSource= */ true);
            }
          }
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
            projectsReassigned: projectsSnap?.size ?? 0,
            threadsUpdated: threadsUpdated,
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
        projectsReassigned: projectsSnap?.size ?? 0,
        threadsUpdated: threadsUpdated,
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
