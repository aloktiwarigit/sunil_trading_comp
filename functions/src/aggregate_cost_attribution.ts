// =============================================================================
// aggregateCostAttribution — WS6.3 per-shop cost dashboard data source.
//
// Scheduled daily at 12:00 IST. For each active shop, aggregates:
//   - Media usage: reads system/media_usage_counter/shops/{shopId}
//     (written by mediaCostMonitor / Cloudinary + Storage SDKs)
//   - SMS usage: reads system/phone_auth_quota/shops/{shopId}
//     field `smsCount_{YYYY-MM}` (written by AuthProviderFirebase, WS6.2)
//
// Writes the per-shop monthly summary to:
//   shops/{shopId}/cost_attribution/{YYYY-MM}
// This document is the data source for the shopkeeper_app MediaSpendTile.
//
// All items are on Firebase/Cloudinary free tier so estimatedCostUsd is
// always 0.00 until a shop exits the free tier; the document still provides
// a usage-vs-cap view for the shopkeeper dashboard.
// =============================================================================

import * as admin from 'firebase-admin';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions/v2';

const SYSTEM_UID = 'system_aggregate_cost_attribution';
const BATCH_SIZE = 500;

/// Free-tier caps (mirrors media_cost_monitor.ts constants).
const CLOUDINARY_CREDITS_CAP = 25;
const STORAGE_GB_CAP = 5;
const SMS_CAP = 10_000;

interface ShopCostSummary {
  shopId: string;
  month: string;
  cloudinaryCreditsUsed: number;
  cloudinaryCapPercent: number;
  storageGb: number;
  storageCapPercent: number;
  smsCount: number;
  smsCapPercent: number;
  estimatedCostUsd: number;
  generatedAt: admin.firestore.FieldValue;
  generatedByUid: string;
}

export const aggregateCostAttribution = onSchedule(
  {
    schedule: '0 12 * * *',
    timeZone: 'Asia/Kolkata',
    region: 'asia-south1',
    memory: '256MiB',
    timeoutSeconds: 120,
    retryCount: 0,
  },
  async () => {
    const db = admin.firestore();

    logger.info('aggregateCostAttribution: run started');

    const now = new Date();
    const monthKey = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
    const smsCountField = `smsCount_${monthKey}`;

    // Enumerate all shops.
    const shopsSnap = await db.collection('shops').get();
    if (shopsSnap.empty) {
      logger.warn('aggregateCostAttribution: no shops found, skipping');
      return;
    }

    // Read media usage for all shops in one pass.
    const mediaSnap = await db
      .collection('system')
      .doc('media_usage_counter')
      .collection('shops')
      .get();
    const mediaByShop = new Map<string, { cloudinaryCreditsUsed: number; storageGb: number }>();
    for (const doc of mediaSnap.docs) {
      const d = doc.data();
      mediaByShop.set(doc.id, {
        cloudinaryCreditsUsed: d.cloudinaryCreditsUsed ?? 0,
        storageGb: d.storageGb ?? 0,
      });
    }

    // Read SMS quota counters for all shops in one pass.
    const smsSnap = await db
      .collection('system')
      .doc('phone_auth_quota')
      .collection('shops')
      .get();
    const smsByShop = new Map<string, number>();
    for (const doc of smsSnap.docs) {
      smsByShop.set(doc.id, doc.data()[smsCountField] ?? 0);
    }

    // Build per-shop summaries and batch-write to shops/{shopId}/cost_attribution/{YYYY-MM}.
    const summaries: ShopCostSummary[] = [];
    for (const shopDoc of shopsSnap.docs) {
      const shopId = shopDoc.id;
      const media = mediaByShop.get(shopId) ?? { cloudinaryCreditsUsed: 0, storageGb: 0 };
      const smsCount = smsByShop.get(shopId) ?? 0;

      summaries.push({
        shopId,
        month: monthKey,
        cloudinaryCreditsUsed: media.cloudinaryCreditsUsed,
        cloudinaryCapPercent:
          CLOUDINARY_CREDITS_CAP > 0
            ? (media.cloudinaryCreditsUsed / CLOUDINARY_CREDITS_CAP) * 100
            : 0,
        storageGb: media.storageGb,
        storageCapPercent:
          STORAGE_GB_CAP > 0 ? (media.storageGb / STORAGE_GB_CAP) * 100 : 0,
        smsCount,
        smsCapPercent: SMS_CAP > 0 ? (smsCount / SMS_CAP) * 100 : 0,
        estimatedCostUsd: 0.0,
        generatedAt: admin.firestore.FieldValue.serverTimestamp(),
        generatedByUid: SYSTEM_UID,
      });
    }

    // Batch-write summaries.
    const chunks: ShopCostSummary[][] = [];
    for (let i = 0; i < summaries.length; i += BATCH_SIZE) {
      chunks.push(summaries.slice(i, i + BATCH_SIZE));
    }

    let totalWritten = 0;
    for (const chunk of chunks) {
      const batch = db.batch();
      for (const summary of chunk) {
        const ref = db
          .collection('shops')
          .doc(summary.shopId)
          .collection('cost_attribution')
          .doc(monthKey);
        batch.set(ref, summary, { merge: true });
      }
      await batch.commit();
      totalWritten += chunk.length;
    }

    logger.info('aggregateCostAttribution: complete', {
      monthKey,
      shopsProcessed: totalWritten,
    });
  },
);
