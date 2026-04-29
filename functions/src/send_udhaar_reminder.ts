// =============================================================================
// sendUdhaarReminder — PRD Sprint 5, RBI guardrails.
//
// Scheduled daily at 09:00 IST. Scans all shops' udhaarLedger subcollections
// for open ledgers where the bhaiya has opted into reminders, and sends FCM
// notifications to customers who are due for a reminder (respecting cadence
// and lifetime caps).
//
// Guardrails:
//   - reminderCountLifetime < 3 (hard cap per ledger)
//   - Time since lastReminderAt >= reminderCadenceDays
//   - closedAt == null (only open ledgers)
//   - reminderOptInByBhaiya == true (bhaiya consent gate)
//
// Audit trail at /system/udhaar_reminders/history/{auto-id}.
// Batch writes in 500-doc chunks per kill_switch.ts pattern.
// =============================================================================

import * as admin from 'firebase-admin';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions/v2';

/// Audit trail constants.
const AUDIT_COLLECTION = 'system';
const AUDIT_DOC_ID = 'udhaar_reminders';
const AUDIT_HISTORY_SUBCOLLECTION = 'history';

/// System UID for audit trail.
const SYSTEM_UID = 'system_udhaar_reminder';

/// Maximum reminders per ledger lifetime.
const MAX_REMINDERS_LIFETIME = 3;

/// Firestore batch size limit.
const BATCH_SIZE = 500;

export const sendUdhaarReminder = onSchedule(
  {
    schedule: '0 9 * * *',       // 09:00 UTC+5:30 — cron is in UTC, so 03:30 UTC
    timeZone: 'Asia/Kolkata',
    region: 'asia-south1',
    memory: '256MiB',
    timeoutSeconds: 60,
    retryCount: 0,
  },
  async () => {
    const db = admin.firestore();
    const now = Date.now();

    logger.info('sendUdhaarReminder: sweep started');

    // Fetch all shops.
    const shopsSnap = await db.collection('shops').get();

    if (shopsSnap.empty) {
      logger.info('sendUdhaarReminder: no shops found');
      return;
    }

    let totalSent = 0;
    let totalSkipped = 0;
    const errors: string[] = [];

    // Process each shop's udhaarLedger subcollection.
    for (const shopDoc of shopsSnap.docs) {
      const shopId = shopDoc.id;

      try {
        // Query open ledgers where bhaiya opted in to reminders.
        const ledgersSnap = await db
          .collection('shops')
          .doc(shopId)
          .collection('udhaarLedger')
          .where('reminderOptInByBhaiya', '==', true)
          .where('closedAt', '==', null)
          .get();

        if (ledgersSnap.empty) {
          continue;
        }

        // Collect eligible ledgers.
        const eligibleDocs: admin.firestore.QueryDocumentSnapshot[] = [];

        for (const ledgerDoc of ledgersSnap.docs) {
          const data = ledgerDoc.data();

          // Check lifetime cap.
          const reminderCount = data.reminderCountLifetime ?? 0;
          if (reminderCount >= MAX_REMINDERS_LIFETIME) {
            totalSkipped++;
            continue;
          }

          // Check cadence.
          const cadenceDays = data.reminderCadenceDays ?? 7;
          const lastReminderAt = data.lastReminderAt;
          if (lastReminderAt) {
            const lastMs =
              lastReminderAt instanceof admin.firestore.Timestamp
                ? lastReminderAt.toMillis()
                : typeof lastReminderAt === 'number'
                  ? lastReminderAt
                  : 0;
            const elapsedDays = (now - lastMs) / (1000 * 60 * 60 * 24);
            if (elapsedDays < cadenceDays) {
              totalSkipped++;
              continue;
            }
          }

          eligibleDocs.push(ledgerDoc);
        }

        // Send FCM + batch-update ledgers in 500-doc chunks.
        const chunks: admin.firestore.QueryDocumentSnapshot[][] = [];
        for (let i = 0; i < eligibleDocs.length; i += BATCH_SIZE) {
          chunks.push(eligibleDocs.slice(i, i + BATCH_SIZE));
        }

        for (const chunk of chunks) {
          const batch = db.batch();
          // COM001 fix: track which ledgers had successful FCM sends.
          // Only increment reminderCountLifetime for those — prevents
          // consuming the 3x lifetime cap on failed deliveries.
          const successfulLedgerRefs: admin.firestore.DocumentReference[] = [];

          for (const ledgerDoc of chunk) {
            const data = ledgerDoc.data();
            const customerFcmToken = data.customerFcmToken;

            // Send FCM notification if token is available.
            if (customerFcmToken && typeof customerFcmToken === 'string') {
              try {
                await admin.messaging().send({
                  token: customerFcmToken,
                  notification: {
                    title: 'Udhaar Reminder',
                    body: `${data.shopName ?? 'Dukaan'} se aapka udhaar baaki hai. Kripya jaldi bhugtaan karein.`,
                  },
                  data: {
                    type: 'udhaar_reminder',
                    shopId,
                    ledgerId: ledgerDoc.id,
                  },
                  android: {
                    priority: 'normal',
                  },
                });
                totalSent++;
                successfulLedgerRefs.push(ledgerDoc.ref);
              } catch (fcmErr) {
                logger.warn('FCM send failed for ledger', {
                  shopId,
                  ledgerId: ledgerDoc.id,
                  error:
                    fcmErr instanceof Error
                      ? fcmErr.message
                      : String(fcmErr),
                });
                totalSkipped++;
              }
            } else {
              totalSkipped++;
            }
          }

          // Only increment counter for ledgers where FCM actually succeeded.
          for (const ref of successfulLedgerRefs) {
            batch.update(ref, {
              reminderCountLifetime: admin.firestore.FieldValue.increment(1),
              lastReminderAt: admin.firestore.FieldValue.serverTimestamp(),
              lastReminderByUid: SYSTEM_UID,
            });
          }

          await batch.commit();
        }
      } catch (err) {
        const msg = err instanceof Error ? err.message : String(err);
        logger.error('Error processing shop udhaar ledgers', {
          shopId,
          error: msg,
        });
        errors.push(`${shopId}: ${msg}`);
      }
    }

    // Write audit trail.
    try {
      await db
        .collection(AUDIT_COLLECTION)
        .doc(AUDIT_DOC_ID)
        .collection(AUDIT_HISTORY_SUBCOLLECTION)
        .add({
          executedAt: admin.firestore.FieldValue.serverTimestamp(),
          totalSent,
          totalSkipped,
          errorCount: errors.length,
          errors: errors.slice(0, 20), // Cap stored errors.
          executedByUid: SYSTEM_UID,
        });
    } catch (err) {
      logger.error('Failed to write udhaar reminder audit entry', {
        error: err instanceof Error ? err.message : String(err),
      });
    }

    logger.info('sendUdhaarReminder: sweep complete', {
      totalSent,
      totalSkipped,
      errorCount: errors.length,
    });
  },
);
