// =============================================================================
// phoneAuthQuotaMonitor — Sprint 5 R8 + WS6.2 per-shop observability.
//
// Scheduled daily at 10:00 IST. Reads per-shop SMS counters from
//   system/phone_auth_quota/shops/{shopId}
// field `smsCount_{YYYY-MM}` (written by AuthProviderFirebase on each
// successful confirmPhoneVerification call).
//
// Graduated response is applied PER-SHOP only — a high-usage shop is
// throttled without affecting shops still within quota:
//
//   80% of 10k/mo: flip authProviderStrategy → 'msg91' for that shop only.
//   95% of 10k/mo: also flip otpAtCommitEnabled → false for that shop only.
//
// Audit summary written to system/phone_auth_quota/{YYYY-MM}/checks/{auto-id}.
// Batch writes in 500-doc chunks per kill_switch.ts pattern.
// =============================================================================

import * as admin from 'firebase-admin';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions/v2';

const SYSTEM_UID = 'system_phone_auth_quota_monitor';
const BATCH_SIZE = 500;

/// Firebase Phone Auth free tier cap per account per month.
const SMS_CAP = 10_000;
const WARNING_THRESHOLD = 0.80;
const CRITICAL_THRESHOLD = 0.95;

const RUNTIME_FLAGS_SUBCOLLECTION = 'featureFlags';
const RUNTIME_FLAGS_DOC_ID = 'runtime';

interface ShopQuotaStatus {
  shopId: string;
  smsCount: number;
  usagePercent: number;
  action: 'none' | 'msg91_fallback' | 'otp_disabled';
}

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

    const now = new Date();
    const monthKey = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
    const smsCountField = `smsCount_${monthKey}`;

    // Read all per-shop quota documents.
    const shopsSnap = await db
      .collection('system')
      .doc('phone_auth_quota')
      .collection('shops')
      .get();

    const results: ShopQuotaStatus[] = [];
    const warningShops: string[] = [];   // need msg91 fallback
    const criticalShops: string[] = [];  // need OTP disabled

    for (const doc of shopsSnap.docs) {
      const shopId = doc.id;
      const data = doc.data();
      const smsCount: number = data[smsCountField] ?? 0;
      const usageRatio = SMS_CAP > 0 ? smsCount / SMS_CAP : 0;
      const usagePercent = usageRatio * 100;

      let action: ShopQuotaStatus['action'] = 'none';

      if (usageRatio >= CRITICAL_THRESHOLD) {
        action = 'otp_disabled';
        criticalShops.push(shopId);
        logger.error('SMS quota CRITICAL for shop', {
          shopId,
          smsCount,
          usagePercent: usagePercent.toFixed(1),
          threshold: CRITICAL_THRESHOLD * SMS_CAP,
        });
      } else if (usageRatio >= WARNING_THRESHOLD) {
        action = 'msg91_fallback';
        warningShops.push(shopId);
        logger.warn('SMS quota WARNING for shop', {
          shopId,
          smsCount,
          usagePercent: usagePercent.toFixed(1),
          threshold: WARNING_THRESHOLD * SMS_CAP,
        });
      }

      results.push({ shopId, smsCount, usagePercent, action });
    }

    // Apply graduated responses — per-shop, not global.
    if (criticalShops.length > 0) {
      await updateShopFlags(db, criticalShops, {
        authProviderStrategy: 'msg91',
        otpAtCommitEnabled: false,
      });
    }
    if (warningShops.length > 0) {
      await updateShopFlags(db, warningShops, {
        authProviderStrategy: 'msg91',
      });
    }

    // Write audit summary for the run.
    try {
      await db
        .collection('system')
        .doc('phone_auth_quota')
        .collection(monthKey)
        .doc('checks')
        .collection('history')
        .add({
          checkedAt: admin.firestore.FieldValue.serverTimestamp(),
          monthKey,
          smsCap: SMS_CAP,
          shopsChecked: results.length,
          shopsWarning: warningShops.length,
          shopsCritical: criticalShops.length,
          results: results.slice(0, 50),
          executedByUid: SYSTEM_UID,
        });
    } catch (err) {
      logger.error('Failed to write phone auth quota audit entry', {
        error: err instanceof Error ? err.message : String(err),
      });
    }

    logger.info('phoneAuthQuotaMonitor: check complete', {
      shopsChecked: results.length,
      shopsWarning: warningShops.length,
      shopsCritical: criticalShops.length,
    });
  },
);

/// Update featureFlags/runtime for a specific list of shops.
async function updateShopFlags(
  db: admin.firestore.Firestore,
  shopIds: string[],
  flags: Record<string, unknown>,
): Promise<void> {
  const chunks: string[][] = [];
  for (let i = 0; i < shopIds.length; i += BATCH_SIZE) {
    chunks.push(shopIds.slice(i, i + BATCH_SIZE));
  }

  let totalUpdated = 0;
  for (const chunk of chunks) {
    const batch = db.batch();
    for (const shopId of chunk) {
      const flagsRef = db
        .collection('shops')
        .doc(shopId)
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
