// =============================================================================
// multiTenantAudit — Sprint 5, R9 sentinel.
//
// Scheduled weekly on Sunday at 03:00 IST. For each shop, scans known
// subcollections and verifies:
//
//   1. shopId field in subcollection documents matches the parent path segment
//   2. shop_0 synthetic docs exist and are unmutated
//
// Violations are logged to /system/audit_results/{YYYY-MM-DD}.
// =============================================================================

import * as admin from 'firebase-admin';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions/v2';

/// Constants.
const SYSTEM_UID = 'system_multi_tenant_audit';

/// Known subcollections to audit for shopId consistency.
const AUDITABLE_SUBCOLLECTIONS = [
  'projects',
  'udhaarLedger',
  'inventory',
  'customers',
  'chatThreads',
  'operators',
  'voiceNotes',
  'curatedShortlists',
  'feedback',
];

/// Expected shape of the shop_0 synthetic sentinel document.
const SHOP_0_EXPECTED_FIELDS: Record<string, unknown> = {
  shopId: 'shop_0',
  synthetic: true,
};

interface Violation {
  shopId: string;
  type: 'shopId_mismatch' | 'shop_0_missing' | 'shop_0_mutated';
  subcollection?: string;
  documentId?: string;
  details?: string;
}

export const multiTenantAudit = onSchedule(
  {
    schedule: '0 3 * * 0',       // Sunday 03:00.
    timeZone: 'Asia/Kolkata',
    region: 'asia-south1',
    memory: '256MiB',
    timeoutSeconds: 60,
    retryCount: 0,
  },
  async () => {
    const db = admin.firestore();

    logger.info('multiTenantAudit: audit started');

    const violations: Violation[] = [];

    // Fetch all shops.
    const shopsSnap = await db.collection('shops').get();

    if (shopsSnap.empty) {
      logger.info('multiTenantAudit: no shops to audit');
      return;
    }

    for (const shopDoc of shopsSnap.docs) {
      const shopId = shopDoc.id;

      // ── Check 1: Verify shopId field in subcollection documents ──
      for (const subcol of AUDITABLE_SUBCOLLECTIONS) {
        try {
          // Sample up to 100 docs per subcollection to stay within timeout.
          const subSnap = await db
            .collection('shops')
            .doc(shopId)
            .collection(subcol)
            .limit(100)
            .get();

          for (const subDoc of subSnap.docs) {
            const data = subDoc.data();
            if (data.shopId !== undefined && data.shopId !== shopId) {
              violations.push({
                shopId,
                type: 'shopId_mismatch',
                subcollection: subcol,
                documentId: subDoc.id,
                details: `Expected shopId '${shopId}', found '${data.shopId}'`,
              });
            }
          }
        } catch (err) {
          logger.warn('Error auditing subcollection', {
            shopId,
            subcollection: subcol,
            error: err instanceof Error ? err.message : String(err),
          });
        }
      }

      // ── Check 2: Verify shop_0 synthetic sentinel ──
      try {
        const shop0Ref = db.collection('shops').doc('shop_0');
        const shop0Snap = await shop0Ref.get();

        if (!shop0Snap.exists) {
          // Only log this once (when processing the first shop).
          if (shopDoc === shopsSnap.docs[0]) {
            violations.push({
              shopId: 'shop_0',
              type: 'shop_0_missing',
              details: 'shop_0 synthetic document does not exist',
            });
          }
        } else if (shopDoc === shopsSnap.docs[0]) {
          // Verify expected fields on first pass only.
          const data = shop0Snap.data() ?? {};
          for (const [key, expectedVal] of Object.entries(
            SHOP_0_EXPECTED_FIELDS,
          )) {
            if (data[key] !== expectedVal) {
              violations.push({
                shopId: 'shop_0',
                type: 'shop_0_mutated',
                details: `Field '${key}': expected '${expectedVal}', found '${data[key]}'`,
              });
            }
          }
        }
      } catch (err) {
        logger.warn('Error checking shop_0 sentinel', {
          error: err instanceof Error ? err.message : String(err),
        });
      }
    }

    // ── Write audit results ──
    const today = new Date();
    const dateKey = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}`;

    try {
      await db
        .collection('system')
        .doc('audit_results')
        .collection(dateKey)
        .doc('summary')
        .set({
          auditedAt: admin.firestore.FieldValue.serverTimestamp(),
          shopsAudited: shopsSnap.size,
          violationCount: violations.length,
          violations: violations.slice(0, 100), // Cap stored violations.
          executedByUid: SYSTEM_UID,
        });
    } catch (err) {
      logger.error('Failed to write multi-tenant audit results', {
        error: err instanceof Error ? err.message : String(err),
      });
    }

    if (violations.length > 0) {
      logger.error('multiTenantAudit: violations found', {
        violationCount: violations.length,
        violations: violations.slice(0, 10),
      });
    } else {
      logger.info('multiTenantAudit: clean — no violations');
    }

    logger.info('multiTenantAudit: audit complete', {
      shopsAudited: shopsSnap.size,
      violationCount: violations.length,
    });
  },
);
