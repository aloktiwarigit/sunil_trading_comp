// =============================================================================
// killSwitchOnBudgetAlert — PRD I6.8 + SAD v1.0.4 §7 Function 1.
//
// The Triple Zero safety rail (ADR-007). Subscribes to the Google Cloud
// Billing budget-alerts Pub/Sub topic and automatically disables billable
// operations when the $1/month Blaze budget cap is approached or breached.
//
// Per Brief §8 Constraint 3 + ADR-007: the $1 cap is a SAFETY RAIL against
// SMS pumping, runaway queries, or config errors — NOT an expected spend.
// Real operation at one-shop scale should cost $0.00 across an entire
// month. Any trigger of this function is an incident.
//
// Wiring (one-time setup per environment, not automated):
//
// 1. Cloud Billing console → create budget at $1 USD on the Firebase
//    project's billing account.
// 2. Budget → "Manage notifications" → add Pub/Sub topic named
//    `budget-alerts` in the same GCP project.
// 3. Alert thresholds at 10% / 50% / 100% of budget.
// 4. Deploy this function: `firebase deploy --only functions --project
//    yugma-dukaan-dev`.
// 5. Verify the function is subscribed by inspecting the topic's
//    subscribers in Pub/Sub console.
//
// Documented in `docs/runbook/staging-setup.md` §6 + `docs/runbook/
// kill-switch-response.md` (Phase 2.x follow-up runbook).
//
// Test coverage: see `functions/test/kill_switch.test.ts`. The critical
// invariant is that 100% threshold writes the kill-switch flags to every
// active shop's `featureFlags/runtime` document within the function's
// 60-second timeout, honoring the PRD I6.7 AC #7 <5s client-propagation
// contract transitively via the onSnapshot listeners already shipped in
// Phase 1.3.
// =============================================================================

import * as admin from 'firebase-admin';
import { onMessagePublished } from 'firebase-functions/v2/pubsub';
import { logger } from 'firebase-functions/v2';

/// Shape of the Cloud Billing budget alert payload (abbreviated — we only
/// consume the fields we need for threshold math).
///
/// Reference:
/// https://cloud.google.com/billing/docs/how-to/budgets-programmatic-notifications
interface BudgetAlertMessage {
  /// Budget display name (e.g., "yugma-dukaan-dev $1 cap").
  budgetDisplayName: string;
  /// Actual cost accrued in the current billing period, in USD.
  costAmount: number;
  /// Budgeted cost for the period, in USD.
  budgetAmount: number;
  /// Currency code (always 'USD' for our setup).
  currencyCode: string;
  /// Type of the alert — 'FORECASTED_SPEND' or 'ACTUAL_SPEND'.
  alertThresholdExceeded?: number;
}

/// Canonical runtime-flags document path per Phase 1.3
/// `KillSwitchListener` contract. Matches the deployed
/// `firestore.rules:featureFlags` sub-collection scope.
const RUNTIME_FLAGS_SUBCOLLECTION = 'featureFlags';
const RUNTIME_FLAGS_DOC_ID = 'runtime';

/// Audit log path for budget alert history.
const AUDIT_COLLECTION = 'system';
const AUDIT_DOC_ID = 'budget_alerts';
const AUDIT_HISTORY_SUBCOLLECTION = 'history';

/// Audit trail UID — identifies kill-switch writes in the
/// `updatedByUid` field so operators can distinguish automatic flips
/// from manual Settings changes.
const KILL_SWITCH_AUDIT_UID = 'system_kill_switch';

/// Subscribes to the Cloud Billing budget-alerts Pub/Sub topic and
/// responds to threshold crossings.
///
/// Behavior:
///   - Always logs the alert to `/system/budget_alerts/history/{auto-id}`
///   - At ≥50% threshold: logs warning + (future) FCM notification to operators
///   - At ≥100% threshold: flips the kill-switch flags in every active
///     shop's `featureFlags/runtime` document:
///       - killSwitchActive → true
///       - cloudinaryUploadsBlocked → true
///       - firestoreWritesBlocked → true
///       - otpAtCommitEnabled → false
///       - authProviderStrategy → 'upi_only'
///       - updatedAt → serverTimestamp
///       - updatedByUid → 'system_kill_switch'
///
/// The Phase 1.3 `KillSwitchListener` in lib_core reads these flags via
/// Firestore `onSnapshot` with <5s propagation, so adapter short-circuits
/// activate on customer devices within seconds of this function firing.
export const killSwitchOnBudgetAlert = onMessagePublished(
  {
    topic: 'budget-alerts',
    region: 'asia-south1',
    memory: '256MiB',
    timeoutSeconds: 60,
    retry: false,
  },
  async (event) => {
    // Parse the Pub/Sub message. Cloud Billing publishes a base64-encoded
    // JSON payload; the Functions SDK exposes both the raw bytes and a
    // convenience `.json` accessor (v2 only).
    let payload: BudgetAlertMessage;
    try {
      const messageData = event.data.message.data;
      const decoded = Buffer.from(messageData, 'base64').toString('utf-8');
      payload = JSON.parse(decoded) as BudgetAlertMessage;
    } catch (err) {
      logger.error('Failed to parse budget alert payload', {
        error: err instanceof Error ? err.message : String(err),
        rawMessage: event.data.message.data,
      });
      // Do not re-throw — a malformed budget alert should not retry. The
      // error is logged and the function exits cleanly.
      return;
    }

    const { costAmount, budgetAmount, budgetDisplayName } = payload;

    if (typeof costAmount !== 'number' || typeof budgetAmount !== 'number') {
      logger.error('Budget alert missing numeric costAmount or budgetAmount', {
        payload,
      });
      return;
    }

    const thresholdPercent =
      budgetAmount > 0 ? (costAmount / budgetAmount) * 100 : 0;

    logger.warn('Budget alert received', {
      budgetDisplayName,
      costAmount,
      budgetAmount,
      thresholdPercent,
    });

    // Always record to audit history. Even sub-50% alerts are logged so the
    // ops team can spot cost trends.
    await writeAuditEntry(payload, thresholdPercent);

    if (thresholdPercent >= 50 && thresholdPercent < 100) {
      // Warning zone — log + notify, but do NOT flip flags yet. The
      // operator gets an early heads-up and can investigate before the
      // automatic kill fires.
      logger.warn(
        `Budget alert at ${thresholdPercent.toFixed(1)}% — approaching cap`,
        {
          budgetDisplayName,
          costAmount,
          budgetAmount,
        },
      );
      // Future: send FCM notification to operator devices via
      // admin.messaging().sendMulticast(...). For now, the Cloud Billing
      // email alerts handle the human notification side.
      return;
    }

    if (thresholdPercent >= 100) {
      logger.error('BUDGET CAP REACHED — flipping kill-switch flags', {
        budgetDisplayName,
        costAmount,
        budgetAmount,
      });
      await flipKillSwitchFlags();
      logger.error('Kill-switch activated across all shops');
      return;
    }

    // Sub-50% alerts are informational only — logged in audit above.
    logger.info(
      `Budget alert at ${thresholdPercent.toFixed(1)}% — informational`,
      {
        budgetDisplayName,
      },
    );
  },
);

/// Append an entry to the budget alerts audit trail. Idempotent at the
/// row level via `add()` (each invocation creates a new doc with an
/// auto-generated ID).
async function writeAuditEntry(
  payload: BudgetAlertMessage,
  thresholdPercent: number,
): Promise<void> {
  try {
    await admin
      .firestore()
      .collection(AUDIT_COLLECTION)
      .doc(AUDIT_DOC_ID)
      .collection(AUDIT_HISTORY_SUBCOLLECTION)
      .add({
        receivedAt: admin.firestore.FieldValue.serverTimestamp(),
        budgetDisplayName: payload.budgetDisplayName,
        costAmount: payload.costAmount,
        budgetAmount: payload.budgetAmount,
        thresholdPercent,
        currencyCode: payload.currencyCode,
      });
  } catch (err) {
    logger.error('Failed to write budget audit entry', {
      error: err instanceof Error ? err.message : String(err),
    });
    // Audit failure must not block the actual kill-switch flip. Swallow.
  }
}

/// Iterate every active shop and flip its `featureFlags/runtime` flags to
/// the kill-switch state. Uses a write batch per 500-shop chunk to respect
/// Firestore's batch size limit.
///
/// Chunk math: at shop #1 through shop #500 this completes in one batch.
/// Beyond shop #500 we chunk — but per Brief §11 vision we are still
/// ~50-200 shops at year 3, so chunking is future-proofing not immediate.
async function flipKillSwitchFlags(): Promise<void> {
  const db = admin.firestore();
  const shopsSnap = await db.collection('shops').get();

  if (shopsSnap.empty) {
    logger.warn('No shops to flip — kill-switch fired on empty tenant set');
    return;
  }

  const BATCH_SIZE = 500;
  const chunks: admin.firestore.QueryDocumentSnapshot[][] = [];
  for (let i = 0; i < shopsSnap.docs.length; i += BATCH_SIZE) {
    chunks.push(shopsSnap.docs.slice(i, i + BATCH_SIZE));
  }

  let totalFlipped = 0;
  for (const chunk of chunks) {
    const batch = db.batch();
    for (const shopDoc of chunk) {
      const flagsRef = shopDoc.ref
        .collection(RUNTIME_FLAGS_SUBCOLLECTION)
        .doc(RUNTIME_FLAGS_DOC_ID);
      batch.set(
        flagsRef,
        {
          killSwitchActive: true,
          cloudinaryUploadsBlocked: true,
          firestoreWritesBlocked: true,
          otpAtCommitEnabled: false,
          authProviderStrategy: 'upi_only',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedByUid: KILL_SWITCH_AUDIT_UID,
        },
        { merge: true },
      );
    }
    await batch.commit();
    totalFlipped += chunk.length;
  }

  logger.error(`Kill-switch flipped for ${totalFlipped} shop(s)`);
}
