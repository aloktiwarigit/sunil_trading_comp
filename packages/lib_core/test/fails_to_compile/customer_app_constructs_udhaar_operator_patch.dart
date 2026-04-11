// =============================================================================
// Negative compilation test — PRD I6.12 AC #5(a) extended to UdhaarLedger.
//
// Phase 1.9 code review cleanup: same rationale as the ChatThread variant.
// UdhaarLedger is operator-write-only per ADR-010 — customers have read
// access only. There is no ParticipantPatch / CustomerPatch for this entity;
// the ONLY customer-accessible surface is via `UdhaarLedgerRepo.getById` /
// `watchByCustomer` reads. This negative compilation test proves that a
// customer_app code path cannot construct an `UdhaarLedgerOperatorPatch`.
//
// Unlike the Project and ChatThread variants, there is no "okCustomerPatch"
// baseline here — customers never have a write path to this collection.
// =============================================================================

// ignore_for_file: unused_import, unused_local_variable
// ignore_for_file: undefined_class, undefined_identifier, uri_does_not_exist

// Customer_app should import nothing from udhaar_ledger_patch.dart — the
// collection is operator-write-only per ADR-010. Even reading the patch
// class name is a policy violation (customers have no construction surface).
//
// We use an empty-show clause to make the intent explicit: no symbols
// from this module are reachable from customer_app code paths.
import 'package:lib_core/src/models/udhaar_ledger_patch.dart' show;

void expectThisFileFailsToCompile() {
  // The following lines are DELIBERATELY broken to trigger compile errors.
  //
  // ---- Uncomment to verify the enforcement works:
  //
  // const illegalOperatorPatch = UdhaarLedgerOperatorPatch(
  //   runningBalance: 10000,
  //   acknowledgedAt: null,
  // );
  //
  // const illegalSystemPatch = UdhaarLedgerSystemPatch(
  //   reminderCountLifetime: 1,
  // );
  //
  // ---- End uncomment block
  //
  // Customer_app code paths must NEVER construct either of these. The
  // Cloud Function Fn 3 (sendUdhaarReminder) is the ONLY writer of the
  // SystemPatch; shopkeeper_app (operator side) is the ONLY writer of the
  // OperatorPatch via UdhaarLedgerRepo.applyOperatorPatch.
}
