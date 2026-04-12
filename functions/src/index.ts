// =============================================================================
// functions/src/index.ts — Cloud Functions deploy barrel.
//
// Every Cloud Function in the SAD v1.0.4 §7 inventory gets re-exported here
// so `firebase deploy --only functions` picks them up. The deployed function
// name matches the exported identifier — do NOT rename exports without
// updating the Pub/Sub topic subscribers + Cloud Scheduler jobs that
// reference them.
//
// Initial exports (Phase 2.x I6.8):
//   - killSwitchOnBudgetAlert (PRD I6.8 + SAD §7 Function 1)
//
// Future exports (SAD §7 inventory — implemented as stories land):
//   - triggerMarketingRebuild (M5.5, marketing site rebuild on theme update)
//   - generateWaMeLink (I6.5 companion)
//   - sendUdhaarReminder (Sprint 5, RBI guardrails)
//   - multiTenantAuditJob (Sprint 5, R9 sentinel)
//   - firebasePhoneAuthQuotaMonitor (Sprint 5, R8)
//   - joinDecisionCircle (Sprint 4, multi-device)
//   - mediaCostMonitor (Sprint 5, S4.16)
//   - shopDeactivationSweep (Sprint 6, ADR-013 DPDP)
// =============================================================================

import * as admin from 'firebase-admin';

// Initialize admin SDK exactly once per function instance. Cloud Functions
// reuse the same Node process across invocations, so repeated
// `admin.initializeApp()` calls would throw `already exists`. The
// `!admin.apps.length` guard is the idiomatic Firebase fix.
if (!admin.apps.length) {
  admin.initializeApp();
}

export { killSwitchOnBudgetAlert } from './kill_switch';
export { triggerMarketingRebuild } from './trigger_marketing_rebuild';
