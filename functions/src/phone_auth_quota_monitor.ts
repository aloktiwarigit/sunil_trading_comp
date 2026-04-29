// =============================================================================
// phoneAuthQuotaMonitor — Sprint 5, R8 phone auth quota safety rail.
//
// Scheduled daily at 10:00 IST. Reads the SMS usage counter from
// /system/phone_auth_quota/{YYYY-MM} and applies graduated responses:
//
//   - At 80% of 10k cap: switch authProviderStrategy to 'msg91' in all
//     shops' featureFlags/runtime (cheaper SMS provider fallback).
//   - At 95% of 10k cap: disable OTP at commit (otpAtCommitEnabled = false).
//
// Audit to /system/phone_auth_quota/{YYYY-MM}/checks/{auto-id}.
// Batch writes in 500-doc chunks per kill_switch.ts pattern.
// =============================================================================

import * as admin from 'firebase-admin';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions/v2';

/// Constants.
const SYSTEM_UID = 'system_phone_auth_quota_monitor';
const BATCH_SIZE = 500;

/// Firebase Phone Auth free tier cap.
const SMS_CAP = 10_000;
const WARNING_THRESHOLD = 0.80;
const CRITICAL_THRESHOLD = 0.95;

/// Runtime flags subcollection per Phase 1.3 contract.
const RUNTIME_FLAGS_SUBCOLLECTION = 'featureFlags';
const RUNTIME_FLAGS_DOC_ID = 'runtime';

export const phoneAuthQuotaMonitor = onSchedule(
  {
    schedule: '0 10 * * *',
    timeZone: 'Asia/Kolkata',
    region: 'asia-south1',
    memory: '256MiB',
    timeoutSeconds: 60,
    retryCount: 0,
  },
  async () => {
    const db = admin.firestore();

    logger.info('phoneAuthQuotaMonitor: check started');

    // Determine current month key (YYYY-MM).
    const now = new Date();
    const monthKey = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;

    // Read SMS count for current month.
    // Try the primary counter document first: /system/phone_auth_quota
    let smsCount = 0;
    const primaryRef = db.doc('system/phone_auth_quota');
    const primarySnap = await primaryRef.get();

    if (primarySnap.exists) {
      const data = primarySnap.data();
      smsCount = data?.[`smsCount_${monthKey}`] ?? data?.smsCount ?? 0;
    }

    // Also check the month-specific document.
    const monthSpecificRef = db
      .collection('system')
      .doc('phone_auth_quota')
      .collection(monthKey)
      .doc('counter');
    const monthSpecificSnap = await monthSpecificRef.get();

    if (monthSpecificSnap.exists) {
      const data = monthSpecificSnap.data();
      smsCount = Math.max(smsCount, data?.smsCount ?? 0);
    }

    const usageRatio = SMS_CAP > 0 ? smsCount / SMS_CAP : 0;

    logger.info('phoneAuthQuotaMonitor: usage check', {
      monthKey,
      smsCount,
      smsCap: SMS_CAP,
      usagePercent: (usageRatio * 100).toFixed(1),
    });

    let action: 'none' | 'msg91_fallback' | 'otp_disabled' = 'none';

    // Apply graduated responses.
    if (usageRatio >= CRITICAL_THRESHOLD) {
      action = 'otp_disabled';
      logger.error('SMS quota at CRITICAL level — disabling OTP at commit', {
        smsCount,
        threshold: CRITICAL_THRESHOLD * SMS_CAP,
      });
      await updateAllShopFlags(db, {
        authProviderStrategy: 'msg91',
        otpAtCommitEnabled: false,
      });
    } else if (usageRatio >= WARNING_THRESHOLD) {
      action = 'msg91_fallback';
      logger.warn('SMS quota at WARNING level — switching to MSG91', {
        smsCount,
        threshold: WARNING_THRESHOLD * SMS_CAP,
      });
      await updateAllShopFlags(db, {
        authProviderStrategy: 'msg91',
      });
    }

    // Write audit check entry.
    try {
      await db
        .collection('system')
        .doc('phone_auth_quota')
        .collection(monthKey)
        .doc('checks')
        .collection('history')
        .add({
          checkedAt: admin.firestore.FieldValue.serverTimestamp(),
          smsCount,
          smsCap: SMS_CAP,
          usagePercent: usageRatio * 100,
          action,
          executedByUid: SYSTEM_UID,
        });
    } catch (err) {
      logger.error('Failed to write phone auth quota audit entry', {
        error: err instanceof Error ? err.message : String(err),
      });
    }

    logger.info('phoneAuthQuotaMonitor: check complete', { action });
  },
);

/// Update featureFlags/runtime for all shops with the given flags.
async function updateAllShopFlags(
  db: admin.firestore.Firestore,
  flags: Record<string, unknown>,
): Promise<void> {
  const shopsSnap = await db.collection('shops').get();

  if (shopsSnap.empty) {
    logger.warn('No shops to update feature flags');
    return;
  }

  const chunks: admin.firestore.QueryDocumentSnapshot[][] = [];
  for (let i = 0; i < shopsSnap.docs.length; i += BATCH_SIZE) {
    chunks.push(shopsSnap.docs.slice(i, i + BATCH_SIZE));
  }

  let totalUpdated = 0;
  for (const chunk of chunks) {
    const batch = db.batch();
    for (const shopDoc of chunk) {
      const flagsRef = shopDoc.ref
        .collection(RUNTIME_FLAGS_SUBCOLLECTION)
        .doc(RUNTIME_FLAGS_DOC_ID);
      batch.set(
        flagsRef,
        {
          ...flags,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedByUid: SYSTEM_UID,
        },
        { merge: true },
      );
    }
    await batch.commit();
    totalUpdated += chunk.length;
  }

  logger.info(`Updated feature flags for ${totalUpdated} shop(s)`, { flags });
}
