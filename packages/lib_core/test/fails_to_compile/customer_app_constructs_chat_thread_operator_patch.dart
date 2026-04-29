// =============================================================================
// Negative compilation test — PRD I6.12 AC #5(a) extended to ChatThread.
//
// Phase 1.9 code review cleanup (my pre-review finding): the original
// `customer_app_constructs_operator_patch.dart` only covered Project. The
// PRD I6.12 AC #4 extended Standing Rule 11 to ChatThread and UdhaarLedger,
// but this partition discipline was never enforced by a matching negative
// compilation test. This file closes the gap for ChatThread.
//
// See the original Project variant (`customer_app_constructs_operator_patch.dart`)
// for the full documentation of the pattern — this file mirrors it.
// =============================================================================

// ignore_for_file: unused_import, unused_local_variable
// ignore_for_file: undefined_class, undefined_identifier, uri_does_not_exist

// Deliberate: import ONLY the participant (customer) patch class, mirroring
// the customer_app repository layer's import discipline. The Operator and
// System patches should NOT be in scope.
import 'package:lib_core/src/models/chat_thread_patch.dart'
    show ChatThreadParticipantPatch;

void expectThisFileFailsToCompile() {
  // Compiles cleanly — customer can construct its own participant patch.
  const okParticipantPatch =
      ChatThreadParticipantPatch(unreadCountForCustomer: 0);

  // The following lines are DELIBERATELY broken to trigger compile errors.
  //
  // ---- Uncomment to verify the enforcement works:
  //
  // const illegalOperatorPatch = ChatThreadOperatorPatch(
  //   unreadCountForShopkeeper: 5,
  //   participantUids: <String>['uid_a', 'uid_b'],
  // );
  //
  // const illegalSystemPatch = ChatThreadSystemPatch(
  //   lastMessagePreview: 'oops',
  // );
  //
  // ---- End uncomment block
  //
  // In normal CI runs these lines stay commented. The `show` restriction on
  // the import IS the enforcement — `tools/audit_project_patch_imports.sh`
  // fails the build if a future engineer un-restricts the import.
}
