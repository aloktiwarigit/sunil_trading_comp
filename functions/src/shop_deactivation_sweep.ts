// =============================================================================
// shopDeactivationSweep — Sprint 6, ADR-013 DPDP compliance.
//
// Scheduled daily at 02:00 IST. Manages shop lifecycle transitions:
//
//   1. deactivating → purgeScheduled (after 24h grace period)
//      - Cancels active projects (draft/negotiating/committed → cancelled)
//      - Freezes open udhaar ledgers
//      - Sets dpdpRetentionUntil = now + 180 days
//
//   2. purgeScheduled → purged (after dpdpRetentionUntil expires)
//      - Anonymizes PII fields
//      - Sets shopLifecycle to 'purged'
//
// Audit trail at /system/deactivation_sweeps/history/{auto-id}.
// Batch writes in 500-doc chunks per kill_switch.ts pattern.
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

/// 24 hours in milliseconds.
const GRACE_PERIOD_MS = 24 * 60 * 60 * 1000;

/// 180 days in milliseconds (DPDP retention).
const DPDP_RETENTION_MS = 180 * 24 * 60 * 60 * 1000;

/// Project statuses that should be cancelled on deactivation.
const CANCELLABLE_STATUSES = ['draft', 'negotiating', 'committed'];

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
      errorCount: errors.length,
    });
  },
);
