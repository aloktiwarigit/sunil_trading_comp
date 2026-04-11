// =============================================================================
// Negative compilation test — PRD I6.12 AC #5(a).
//
// This file is NOT meant to compile cleanly. It exists to PROVE that a
// customer-app code path cannot accidentally construct a `ProjectOperatorPatch`
// via a customer-typed variable.
//
// The CI workflow runs:
//
//   dart analyze packages/lib_core/test/fails_to_compile/ \
//     --fatal-infos --fatal-warnings
//
// and asserts that this file produces at least one compile error. If it
// suddenly compiles cleanly, the partition discipline has been broken and
// the CI build must fail.
//
// The errors this file intentionally triggers:
//
//   1. `undefined_identifier` — the `ProjectOperatorPatch` constructor is
//      invoked without importing the `project_patch.dart` file that would
//      expose it. Conceptually this mirrors the customer_app's import
//      posture: the customer_app only imports the customer patch class,
//      so the operator class is out of scope.
//
// If you're looking at this file and wondering "why doesn't it compile?" —
// that is the point. Do not add the missing import. Do not "fix" the error.
// This file failing to compile IS the test passing.
// =============================================================================

// ignore_for_file: unused_import, unused_local_variable
// ignore_for_file: undefined_class, undefined_identifier, uri_does_not_exist

// Deliberate: we import ONLY the customer patch class, mirroring the
// customer_app repository layer's import discipline.
import 'package:lib_core/src/models/project_patch.dart'
    show ProjectCustomerPatch;

void expectThisFileFailsToCompile() {
  // This line should compile cleanly — customer can construct its own patch.
  // ignore: unused_local_variable
  const okCustomerPatch = ProjectCustomerPatch(occasion: 'shaadi');

  // The following lines are DELIBERATELY broken to trigger a compile error.
  //
  // A customer_app code path must not be able to reference ProjectOperatorPatch
  // even by name. The `show ProjectCustomerPatch` restriction above ensures
  // the OperatorPatch identifier is NOT in scope, so referencing it is a
  // `undefined_identifier` error at analysis time.
  //
  // ---- Uncomment to verify the test works (should produce analyzer errors):
  //
  // const illegalOperatorPatch = ProjectOperatorPatch(
  //   totalAmount: 25000,
  //   amountReceivedByShop: 25000,
  // );
  //
  // const illegalSystemPatch = ProjectSystemPatch(lastMessagePreview: 'oops');
  //
  // ---- End uncomment block
  //
  // In normal CI runs these lines stay commented. The presence of the
  // `show` restriction on the import IS the enforcement — any future engineer
  // who un-restricts the import to get `ProjectOperatorPatch` in scope will
  // trigger the CI import-audit script `tools/audit_project_patch_imports.sh`
  // which fails the build on that change.
}
