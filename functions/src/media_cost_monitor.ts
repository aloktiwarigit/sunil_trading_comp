// =============================================================================
// mediaCostMonitor — Sprint 5, S4.16 media cost safety rail.
//
// Scheduled daily at 11:00 IST. Reads per-shop media usage counters from
// /system/media_usage_counter/{shopId} and applies graduated responses:
//
//   - Cloudinary credits: 25 free tier cap
//     - At 80%: warning log + Crashlytics custom key
//     - At 100%: flip cloudinaryUploadsBlocked = true in featureFlags/runtime
//
//   - Storage GB: 5GB cap
//     - At 80%: warning log + Crashlytics custom key
//     - At 100%: flip cloudinaryUploadsBlocked = true in featureFlags/runtime
//
// Audit trail at /system/media_cost_checks/history/{auto-id}.
// Batch writes in 500-doc chunks per kill_switch.ts pattern.
// =============================================================================

import * as admin from 'firebase-admin';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions/v2';

/// Constants.
const AUDIT_COLLECTION = 'system';
const AUDIT_DOC_ID = 'media_cost_checks';
const AUDIT_HISTORY_SUBCOLLECTION = 'history';
const SYSTEM_UID = 'system_media_cost_monitor';

/// Free tier caps.
const CLOUDINARY_CREDITS_CAP = 25;
const STORAGE_GB_CAP = 5;

/// Thresholds.
const WARNING_THRESHOLD = 0.80;
const BLOCK_THRESHOLD = 1.00;

/// Runtime flags subcollection per Phase 1.3 contract.
const RUNTIME_FLAGS_SUBCOLLECTION = 'featureFlags';
const RUNTIME_FLAGS_DOC_ID = 'runtime';

interface ShopMediaStatus {
  shopId: string;
  cloudinaryCreditsUsed: number;
  storageGb: number;
  cloudinaryRatio: number;
  storageRatio: number;
  action: 'none' | 'warning' | 'blocked';
}

export const mediaCostMonitor = onSchedule(
  {
    schedule: '0 11 * * *',
    timeZone: 'Asia/Kolkata',
    region: 'asia-south1',
    memory: '256MiB',
    timeoutSeconds: 60,
    retryCount: 0,
  },
  async () => {
    const db = admin.firestore();

    logger.info('mediaCostMonitor: check started');

    // Read all per-shop media usage counter documents.
    const usageSnap = await db
      .collection('system')
      .doc('media_usage_counter')
      .collection('shops')
      .get();

    // Fallback: try flat collection /system/media_usage_counter/{shopId}
    let usageDocs = usageSnap.docs;
    if (usageDocs.length === 0) {
      const flatSnap = await db.collection('system/media_usage_counter').get();
      // Filter out the parent doc if it shows up.
      usageDocs = flatSnap.docs.filter((d) => d.id !== 'media_usage_counter');
    }

    const results: ShopMediaStatus[] = [];
    const shopsToBlock: string[] = [];

    for (const doc of usageDocs) {
      const shopId = doc.id;
      const data = doc.data();

      const cloudinaryCreditsUsed = data.cloudinaryCreditsUsed ?? 0;
      const storageGb = data.storageGb ?? 0;

      const cloudinaryRatio =
        CLOUDINARY_CREDITS_CAP > 0
          ? cloudinaryCreditsUsed / CLOUDINARY_CREDITS_CAP
          : 0;
      const storageRatio =
        STORAGE_GB_CAP > 0 ? storageGb / STORAGE_GB_CAP : 0;

      let action: 'none' | 'warning' | 'blocked' = 'none';

      // Check if either metric hits block threshold.
      if (
        cloudinaryRatio >= BLOCK_THRESHOLD ||
        storageRatio >= BLOCK_THRESHOLD
      ) {
        action = 'blocked';
        shopsToBlock.push(shopId);
        logger.error('Media usage BLOCKED for shop', {
          shopId,
          cloudinaryCreditsUsed,
          cloudinaryRatio: (cloudinaryRatio * 100).toFixed(1),
          storageGb,
          storageRatio: (storageRatio * 100).toFixed(1),
        });
      } else if (
        cloudinaryRatio >= WARNING_THRESHOLD ||
        storageRatio >= WARNING_THRESHOLD
      ) {
        action = 'warning';
        logger.warn('Media usage WARNING for shop', {
          shopId,
          cloudinaryCreditsUsed,
          cloudinaryRatio: (cloudinaryRatio * 100).toFixed(1),
          storageGb,
          storageRatio: (storageRatio * 100).toFixed(1),
          // Crashlytics custom key equivalent — logged for GCP Error Reporting
          // to act as the free-tier substitute for Crashlytics custom keys.
          crashlyticsKey: `media_warning_${shopId}`,
        });
      }

      results.push({
        shopId,
        cloudinaryCreditsUsed,
        storageGb,
        cloudinaryRatio,
        storageRatio,
        action,
      });
    }

    // Flip cloudinaryUploadsBlocked for shops at 100%.
    if (shopsToBlock.length > 0) {
      const CHUNK_SIZE = 500;
      const chunks: string[][] = [];
      for (let i = 0; i < shopsToBlock.length; i += CHUNK_SIZE) {
        chunks.push(shopsToBlock.slice(i, i + CHUNK_SIZE));
      }

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
              cloudinaryUploadsBlocked: true,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
              updatedByUid: SYSTEM_UID,
            },
            { merge: true },
          );
        }
        await batch.commit();
      }

      logger.info(`Blocked media uploads for ${shopsToBlock.length} shop(s)`);
    }

    // ── Audit trail ──
    try {
      await db
        .collection(AUDIT_COLLECTION)
        .doc(AUDIT_DOC_ID)
        .collection(AUDIT_HISTORY_SUBCOLLECTION)
        .add({
          checkedAt: admin.firestore.FieldValue.serverTimestamp(),
          shopsChecked: results.length,
          shopsWarning: results.filter((r) => r.action === 'warning').length,
          shopsBlocked: shopsToBlock.length,
          results: results.slice(0, 50), // Cap stored results.
          executedByUid: SYSTEM_UID,
        });
    } catch (err) {
      logger.error('Failed to write media cost monitor audit entry', {
        error: err instanceof Error ? err.message : String(err),
      });
    }

    logger.info('mediaCostMonitor: check complete', {
      shopsChecked: results.length,
      shopsWarning: results.filter((r) => r.action === 'warning').length,
      shopsBlocked: shopsToBlock.length,
    });
  },
);
