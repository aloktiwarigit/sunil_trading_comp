// =============================================================================
// shopDeactivationSweep — Sprint 6, ADR-013 DPDP compliance.
//
// Scheduled daily at 02:00 IST. Manages shop lifecycle transitions:
//
//   1. deactivating → purgeScheduled (after 30-day grace period)
//      - Cancels active projects (draft/negotiating/committed → cancelled)
//      - Freezes open udhaar ledgers
//      - Sets dpdpRetentionUntil = now + 180 days
//      - Sends bilingual (Devanagari + English) FCM to customers with
//        open udhaar + the operator (best-effort — see MT-2 caveat).
//
//   2. purgeScheduled → purged (after dpdpRetentionUntil expires)
//      - Anonymizes PII fields
//      - Sets shopLifecycle to 'purged'
//      - Sends final bilingual FCM "data has been removed".
//
// Audit trail at /system/deactivation_sweeps/history/{auto-id}.
// Batch writes in 500-doc chunks per kill_switch.ts pattern.
//
// Drifts addressed:
//   §15.1.D — GRACE_PERIOD_MS bumped from 24h to 30 days to match the
//     SAD/Five-Truths posture. A shopkeeper who clicks deactivate by
//     mistake at 11 PM gets 30 days (not 24h) to undo before the
//     irreversible purge is scheduled. Recommended default; founder
//     can ratify or override (see docs/architecture-source-of-truth.md
//     §15.1.D).
//   §15.1.E — bilingual FCM dispatch added on both lifecycle transitions.
//     Best-effort: customer FCM tokens come from open udhaar ledgers
//     (the only place customer tokens currently land in Firestore today —
//     see drift MT-2 / §15.2.L tracking the missing customer-app
//     getToken() registration path). Operator FCM token comes from the
//     operators doc if present.
// =============================================================================

import * as admin from 'firebase-admin';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions/v2';

/// Constants.
const AUDIT_COLLECTION = 'system';
const AUDIT_DOC_ID = 'deactivation_sweeps';
const AUDIT_HISTORY_SUBCOLLECTION = 'history';
const SYSTEM_UID = 'system_deactivation_sweep';
const BATCH_SIZE = 500;

/// 30 days in milliseconds — DPDP grace per §15.1.D resolution.
const GRACE_PERIOD_MS = 30 * 24 * 60 * 60 * 1000;

/// 180 days in milliseconds (DPDP retention).
const DPDP_RETENTION_MS = 180 * 24 * 60 * 60 * 1000;

/// Project statuses that should be cancelled on deactivation.
const CANCELLABLE_STATUSES = ['draft', 'negotiating', 'committed'];

// ─────────────────────────────────────────────────────────────────────────────
// Bilingual notification templates (drift §15.1.E).
// Devanagari source (per ADR-008 — Hindi is canonical) + concatenated
// English fallback. Single FCM payload per recipient — cheaper than
// language-specific deliveries; both lines render in the notification body.
// ─────────────────────────────────────────────────────────────────────────────

interface BilingualMessage {
  title: string;
  body: string;
}

function deactivatingToPurgeScheduledMessage(brandName: string): BilingualMessage {
  return {
    title: `${brandName} — दुकान बंद हो रही है`,
    // "180 दिन में आपकी जानकारी हटा दी जाएगी। बकाया हो तो पूरा कर लीजिए।"
    // English: "Your data will be removed in 180 days. Settle any open
    //           transactions soon."
    body:
      '180 दिन में आपकी ' +
      'जानकारी हटा ' +
      'दी जाएगी। बका' +
      'या हो तो पूरा ' +
      'कर लीजिए।' +
      '\n\n' +
      'Your data will be removed in 180 days. Settle any open transactions soon.',
  };
}

function purgeScheduledToPurgedMessage(brandName: string): BilingualMessage {
  return {
    title: `${brandName} — जानकारी हटा दी गई`,
    // "DPDP कानून के अनुसार आपकी जानकारी अब हमारे पास नहीं है।"
    // English: "Per the DPDP Act, your data has been permanently removed."
    body:
      'DPDP कानून के अनु' +
      'सार आपकी जानक' +
      'ारी अब हमारे ' +
      'पास नहीं है।' +
      '\n\n' +
      'Per the DPDP Act, your data has been permanently removed.',
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Best-effort FCM token discovery + bilingual send.
// ─────────────────────────────────────────────────────────────────────────────

/// Returns the de-duplicated set of customer FCM tokens for a shop, sourced
/// from `customerFcmToken` fields on the shop's udhaar ledgers (the only
/// location customer tokens currently land — see drift §15.2.L / MT-2).
async function collectCustomerFcmTokens(
  db: admin.firestore.Firestore,
  shopId: string,
  openOnly = false,
): Promise<string[]> {
  const ledgersSnap = await db
    .collection('shops')
    .doc(shopId)
    .collection('udhaarLedger')
    .get();
  const tokens = new Set<string>();
  for (const ledgerDoc of ledgersSnap.docs) {
    const data = ledgerDoc.data();
    // When openOnly=true, skip ledgers that are closed. An open ledger
    // either has closedAt == null OR has no closedAt field at all (docs
    // created before explicit null was set on creation). Both are "open".
    // Firestore .where('closedAt', '==', null) would miss documents
    // where the field is absent entirely, so we filter in-code instead.
    if (openOnly && data.closedAt != null) {
      continue;
    }
    const t = data.customerFcmToken;
    if (typeof t === 'string' && t.length > 0) {
      tokens.add(t);
    }
  }
  return Array.from(tokens);
}

/// Best-effort lookup of operator FCM tokens. Operator doc may carry
/// `fcmToken` once shopkeeper_app starts registering it (MT-2 tracks the
/// gap). Today this typically returns [].
async function collectOperatorFcmTokens(
  db: admin.firestore.Firestore,
  shopId: string,
): Promise<string[]> {
  const opsSnap = await db
    .collection('shops')
    .doc(shopId)
    .collection('operators')
    .get();
  const tokens = new Set<string>();
  for (const opDoc of opsSnap.docs) {
    const t = opDoc.data().fcmToken;
    if (typeof t === 'string' && t.length > 0) {
      tokens.add(t);
    }
  }
  return Array.from(tokens);
}

/// Sends a bilingual FCM payload to a list of tokens. Returns the number of
/// successful sends. Errors per-token are logged but do not abort the batch.
async function sendBilingualFcm(
  tokens: string[],
  message: BilingualMessage,
  context: { shopId: string; transition: string },
): Promise<number> {
  if (tokens.length === 0) {
    return 0;
  }
  let sent = 0;
  for (const token of tokens) {
    try {
      await admin.messaging().send({
        token,
        notification: { title: message.title, body: message.body },
        data: {
          shopId: context.shopId,
          transition: context.transition,
        },
      });
      sent++;
    } catch (err) {
      // Stale tokens (registration-token-not-registered) are common when
      // a customer reinstalls the app. Don't escalate; just count and
      // continue.
      logger.warn('Deactivation FCM send failed', {
        shopId: context.shopId,
        transition: context.transition,
        error: err instanceof Error ? err.message : String(err),
      });
    }
  }
  return sent;
}

export const shopDeactivationSweep = onSchedule(
  {
    schedule: '0 2 * * *',
    timeZone: 'Asia/Kolkata',
    region: 'asia-south1',
    memory: '256MiB',
    timeoutSeconds: 60,
    retryCount: 0,
  },
  async () => {
    const db = admin.firestore();
    const now = Date.now();

    logger.info('shopDeactivationSweep: sweep started');

    let transitioned = 0;
    let purged = 0;
    let projectsCancelled = 0;
    let ledgersFrozen = 0;
    let notificationsSent = 0;
    const errors: string[] = [];

    // ── Phase 1: deactivating → purgeScheduled ──
    try {
      const deactivatingSnap = await db
        .collection('shops')
        .where('shopLifecycle', '==', 'deactivating')
        .get();

      for (const shopDoc of deactivatingSnap.docs) {
        const shopId = shopDoc.id;
        const data = shopDoc.data();

        try {
          // Check 24h grace period.
          const changedAt = data.shopLifecycleChangedAt;
          if (!changedAt) {
            logger.warn('Shop missing shopLifecycleChangedAt', { shopId });
            continue;
          }

          const changedMs =
            changedAt instanceof admin.firestore.Timestamp
              ? changedAt.toMillis()
              : typeof changedAt === 'number'
                ? changedAt
                : 0;

          if (changedMs + GRACE_PERIOD_MS >= now) {
            // Grace period not yet elapsed.
            continue;
          }

          // Cancel active projects.
          const projectsSnap = await db
            .collection('shops')
            .doc(shopId)
            .collection('projects')
            .where('state', 'in', CANCELLABLE_STATUSES)
            .get();

          const projectChunks: admin.firestore.QueryDocumentSnapshot[][] = [];
          for (let i = 0; i < projectsSnap.docs.length; i += BATCH_SIZE) {
            projectChunks.push(projectsSnap.docs.slice(i, i + BATCH_SIZE));
          }

          for (const chunk of projectChunks) {
            const batch = db.batch();
            for (const projDoc of chunk) {
              batch.update(projDoc.ref, {
                state: 'cancelled',
                systemCancelReason: 'shop_deactivation',
                cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedByUid: SYSTEM_UID,
              });
              projectsCancelled++;
            }
            await batch.commit();
          }

          // §15.1.E — collect FCM tokens BEFORE freezing ledgers.
          // collectCustomerFcmTokens(openOnly=true) filters closedAt==null.
          // If tokens were collected after the freeze, all just-closed
          // ledgers would be excluded and customers would receive nothing
          // (Codex P2 finding). Capture tokens while they're still open.
          const brandName = (data.brandName as string | undefined) ?? 'Yugma Dukaan';
          const preFreezeCustomerTokens = await collectCustomerFcmTokens(db, shopId, true);
          const preFreezeOperatorTokens = await collectOperatorFcmTokens(db, shopId);

          // Freeze open udhaar ledgers.
          const ledgersSnap = await db
            .collection('shops')
            .doc(shopId)
            .collection('udhaarLedger')
            .where('closedAt', '==', null)
            .get();

          const ledgerChunks: admin.firestore.QueryDocumentSnapshot[][] = [];
          for (let i = 0; i < ledgersSnap.docs.length; i += BATCH_SIZE) {
            ledgerChunks.push(ledgersSnap.docs.slice(i, i + BATCH_SIZE));
          }

          for (const chunk of ledgerChunks) {
            const batch = db.batch();
            for (const ledgerDoc of chunk) {
              batch.update(ledgerDoc.ref, {
                closedAt: admin.firestore.FieldValue.serverTimestamp(),
                closedReason: 'shop_deactivation',
                updatedByUid: SYSTEM_UID,
              });
              ledgersFrozen++;
            }
            await batch.commit();
          }

          // Transition shop to purgeScheduled.
          await shopDoc.ref.update({
            shopLifecycle: 'purgeScheduled',
            shopLifecycleChangedAt:
              admin.firestore.FieldValue.serverTimestamp(),
            dpdpRetentionUntil: admin.firestore.Timestamp.fromMillis(
              now + DPDP_RETENTION_MS,
            ),
            updatedByUid: SYSTEM_UID,
          });

          transitioned++;

          // §15.1.E — bilingual FCM after the transition is committed.
          // Tokens were collected BEFORE the ledger freeze (above) so
          // open-ledger customers are included. Best-effort: tokens only
          // land on udhaar ledger docs today (drift MT-2 / §15.2.L).
          const message = deactivatingToPurgeScheduledMessage(brandName);
          const sent = await sendBilingualFcm(
            [...preFreezeCustomerTokens, ...preFreezeOperatorTokens],
            message,
            { shopId, transition: 'deactivating_to_purge_scheduled' },
          );
          notificationsSent += sent;
          if (sent === 0 && preFreezeCustomerTokens.length + preFreezeOperatorTokens.length === 0) {
            logger.info(
              'No FCM tokens available for shop deactivation notification — ' +
                'skipped silently (drift MT-2 customer-side registration pending)',
              { shopId, transition: 'deactivating_to_purge_scheduled' },
            );
          }
        } catch (err) {
          const msg = err instanceof Error ? err.message : String(err);
          logger.error('Error transitioning shop to purgeScheduled', {
            shopId,
            error: msg,
          });
          errors.push(`deactivating/${shopId}: ${msg}`);
        }
      }
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      logger.error('Error querying deactivating shops', { error: msg });
      errors.push(`deactivating_query: ${msg}`);
    }

    // ── Phase 2: purgeScheduled → purged (DPDP retention expired) ──
    try {
      const purgeSnap = await db
        .collection('shops')
        .where('shopLifecycle', '==', 'purgeScheduled')
        .get();

      for (const shopDoc of purgeSnap.docs) {
        const shopId = shopDoc.id;
        const data = shopDoc.data();

        try {
          const retentionUntil = data.dpdpRetentionUntil;
          if (!retentionUntil) {
            logger.warn('Shop missing dpdpRetentionUntil', { shopId });
            continue;
          }

          const retentionMs =
            retentionUntil instanceof admin.firestore.Timestamp
              ? retentionUntil.toMillis()
              : typeof retentionUntil === 'number'
                ? retentionUntil
                : 0;

          if (retentionMs >= now) {
            // Retention period not yet expired.
            continue;
          }

          // §15.1.E — capture brandName + collect FCM tokens BEFORE the
          // anonymization update destroys them.
          const brandName = (data.brandName as string | undefined) ?? 'Yugma Dukaan';
          const customerTokens = await collectCustomerFcmTokens(db, shopId);
          const operatorTokens = await collectOperatorFcmTokens(db, shopId);

          // Anonymize PII.
          await shopDoc.ref.update({
            shopLifecycle: 'purged',
            shopLifecycleChangedAt:
              admin.firestore.FieldValue.serverTimestamp(),
            shopName: '[purged]',
            ownerName: '[purged]',
            ownerPhone: '[purged]',
            ownerEmail: '[purged]',
            address: '[purged]',
            gstNumber: '[purged]',
            whatsappNumberE164: '[purged]',
            updatedByUid: SYSTEM_UID,
          });

          purged++;

          // Send the final bilingual "data has been removed" notification
          // after PII anonymization is committed. Same best-effort caveat
          // as Phase 1 applies.
          const message = purgeScheduledToPurgedMessage(brandName);
          const sent = await sendBilingualFcm(
            [...customerTokens, ...operatorTokens],
            message,
            { shopId, transition: 'purge_scheduled_to_purged' },
          );
          notificationsSent += sent;
        } catch (err) {
          const msg = err instanceof Error ? err.message : String(err);
          logger.error('Error purging shop', { shopId, error: msg });
          errors.push(`purge/${shopId}: ${msg}`);
        }
      }
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      logger.error('Error querying purgeScheduled shops', { error: msg });
      errors.push(`purge_query: ${msg}`);
    }

    // ── Audit trail ──
    try {
      await db
        .collection(AUDIT_COLLECTION)
        .doc(AUDIT_DOC_ID)
        .collection(AUDIT_HISTORY_SUBCOLLECTION)
        .add({
          executedAt: admin.firestore.FieldValue.serverTimestamp(),
          transitioned,
          purged,
          projectsCancelled,
          ledgersFrozen,
          notificationsSent,
          errorCount: errors.length,
          errors: errors.slice(0, 20),
          executedByUid: SYSTEM_UID,
        });
    } catch (err) {
      logger.error('Failed to write deactivation sweep audit entry', {
        error: err instanceof Error ? err.message : String(err),
      });
    }

    logger.info('shopDeactivationSweep: sweep complete', {
      transitioned,
      purged,
      projectsCancelled,
      ledgersFrozen,
      notificationsSent,
      errorCount: errors.length,
    });
  },
);
