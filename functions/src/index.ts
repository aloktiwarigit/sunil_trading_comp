// =============================================================================
// functions/src/index.ts — Cloud Functions deploy barrel.
//
// Every Cloud Function in the SAD v1.0.4 §7 inventory gets re-exported here
// so `firebase deploy --only functions` picks them up. The deployed function
// name matches the exported identifier — do NOT rename exports without
// updating the Pub/Sub topic subscribers + Cloud Scheduler jobs that
// reference them.
//
// Exports (SAD §7 inventory — all 9 functions implemented + 2 WS additions):
//   - killSwitchOnBudgetAlert (PRD I6.8 + SAD §7 Function 1)
//   - triggerMarketingRebuild (M5.5, marketing site rebuild on theme update)
//   - sendUdhaarReminder (Sprint 5, RBI guardrails — scheduled daily 09:00 IST)
//   - shopDeactivationSweep (Sprint 6, ADR-013 DPDP — scheduled daily 02:00 IST)
//   - phoneAuthQuotaMonitor (Sprint 5 R8 + WS6.2 per-shop — scheduled daily 10:00 IST)
//   - multiTenantAudit (Sprint 5, R9 sentinel — scheduled weekly Sun 03:00 IST)
//   - joinDecisionCircle (Sprint 4, multi-device — HTTPS Callable)
//   - mediaCostMonitor (Sprint 5, S4.16 — scheduled daily 11:00 IST)
//   - generateWaMeLink (I6.5 companion — HTTPS Callable)
//   - provisionNewShop (WS4 — admin-only HTTPS Callable, yugmaAdmin claim required)
//   - aggregateCostAttribution (WS6.3 — scheduled daily 12:00 IST)
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
export { sendUdhaarReminder } from './send_udhaar_reminder';
export { shopDeactivationSweep } from './shop_deactivation_sweep';
export { phoneAuthQuotaMonitor } from './phone_auth_quota_monitor';
export { multiTenantAudit } from './multi_tenant_audit';
export { joinDecisionCircle } from './join_decision_circle';
export { mediaCostMonitor } from './media_cost_monitor';
export { generateWaMeLink } from './generate_wa_me_link';
export { provisionNewShop } from './provision_new_shop';
export { aggregateCostAttribution } from './aggregate_cost_attribution';
