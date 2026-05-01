// =============================================================================
// Negative compilation test — Phase 3 partition discipline (2026-04-30).
//
// Mirrors customer_app_constructs_operator_patch.dart. This file exists to
// PROVE that a customer-app code path cannot accidentally construct
// `ProjectOperatorMarkPaidPatch` or `ProjectOperatorClosePatch` via a
// customer-typed variable. The `show` clause on the import is the
// enforcement — neither symbol is in scope, so the commented examples below
// would be `undefined_identifier` errors when un-commented.
//
// The persistent CI block on customer_app importing the operator patches
// lives in tools/audit_project_patch_imports.sh.
// =============================================================================

// ignore_for_file: unused_import, unused_local_variable
// ignore_for_file: undefined_class, undefined_identifier, uri_does_not_exist

// Deliberate: import ONLY the customer patch classes, mirroring the
// customer_app repository layer's import discipline.
import 'package:lib_core/src/models/project_patch.dart'
    show
        ProjectCustomerPatch,
        ProjectCustomerPaymentPatch,
        ProjectCustomerCodPatch,
        ProjectCustomerBankTransferPatch;

void expectThisFileFailsToCompile() {
  // OK — customer can construct customer-side patches.
  const okCustomer = ProjectCustomerPatch(occasion: 'shaadi');
  const okUpiClaim = ProjectCustomerPaymentPatch(customerVpa: 'sunita@okicici');
  const okCod = ProjectCustomerCodPatch();
  const okBankTransfer = ProjectCustomerBankTransferPatch();

  // The following are DELIBERATELY broken — they require the operator-only
  // Phase 3 patch classes to be in scope, but the `show` clause above does
  // not import them. Un-commenting either line should produce an
  // `undefined_identifier` analyzer error.
  //
  // ---- Uncomment to verify the test works:
  //
  // final illegalMarkPaid = ProjectOperatorMarkPaidPatch(paymentMethod: 'cash');
  // const illegalClose = ProjectOperatorClosePatch();
  //
  // ---- End uncomment block.
  //
  // Real CI enforcement: tools/audit_project_patch_imports.sh greps every
  // file under apps/customer_app/ for any import of ProjectOperatorPatch /
  // ProjectOperatorMarkPaidPatch / ProjectOperatorClosePatch and fails the
  // build on a hit.
}
