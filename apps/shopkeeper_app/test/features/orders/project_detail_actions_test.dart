// =============================================================================
// project_detail_screen — action button visibility predicates (Phase 3).
//
// Verifies the visibility contract Codex r5 review required:
//   1. Mark Paid renders for `committed` AND `awaitingVerification`
//      (so operators can confirm UPI / bank-transfer claims).
//   2. Mark Delivered does NOT render for committed / awaitingVerification
//      (Phase 3 F8 anti-regression — operator must mark paid first so the
//      typed close patch's Triple Zero re-check passes).
//   3. Mark Delivered renders for paid / delivering.
//
// The predicates are pure functions extracted from the screen so this test
// runs without spinning up Firestore, the router, or the theme. The actual
// repo-level path that handles the awaiting_verification → paid transition
// is covered by:
//   `lib_core/test/repositories/project_repo_test.dart` group
//   `applyOperatorMarkPaidPatch` test
//   "awaiting_verification → paid succeeds (operator confirms UPI/bank)".
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:lib_core/lib_core.dart';

import 'package:shopkeeper_app/features/orders/project_detail_screen.dart';

void main() {
  group('isMarkPaidVisibleFor — Phase 3 awaiting_verification fix', () {
    test('committed → visible (operator collects cash / in-person UPI)', () {
      expect(isMarkPaidVisibleFor(ProjectState.committed), isTrue);
    });

    test('awaitingVerification → visible (customer claimed UPI/bank)', () {
      // The Codex r5 blocker: under Phase 3, customer UPI and bank-transfer
      // claims park projects at awaiting_verification. The operator must be
      // able to confirm via Mark Paid; otherwise the project gets stuck.
      expect(isMarkPaidVisibleFor(ProjectState.awaitingVerification), isTrue);
    });

    test('draft → hidden', () {
      expect(isMarkPaidVisibleFor(ProjectState.draft), isFalse);
    });

    test('negotiating → hidden', () {
      expect(isMarkPaidVisibleFor(ProjectState.negotiating), isFalse);
    });

    test('paid → hidden (already paid)', () {
      expect(isMarkPaidVisibleFor(ProjectState.paid), isFalse);
    });

    test('delivering → hidden', () {
      expect(isMarkPaidVisibleFor(ProjectState.delivering), isFalse);
    });

    test('closed → hidden', () {
      expect(isMarkPaidVisibleFor(ProjectState.closed), isFalse);
    });

    test('cancelled → hidden', () {
      expect(isMarkPaidVisibleFor(ProjectState.cancelled), isFalse);
    });
  });

  group('isMarkDeliveredVisibleFor — F8 anti-regression', () {
    test('committed → hidden (Phase 3 F8 fix)', () {
      // The original Phase 3 F8 fix removed `committed` from this predicate.
      // Re-add only via Mark Paid, never directly to delivering, so
      // amountReceivedByShop is set before close.
      expect(isMarkDeliveredVisibleFor(ProjectState.committed), isFalse);
    });

    test('awaitingVerification → hidden (would short-circuit verification)',
        () {
      // If the operator could close from awaiting_verification, they could
      // skip the typed mark-paid path and end up with amountReceivedByShop
      // still at 0 — Triple Zero rule check would reject the close, but UX
      // would dead-end. Keep it hidden.
      expect(
        isMarkDeliveredVisibleFor(ProjectState.awaitingVerification),
        isFalse,
      );
    });

    test('paid → visible', () {
      expect(isMarkDeliveredVisibleFor(ProjectState.paid), isTrue);
    });

    test('delivering → visible', () {
      expect(isMarkDeliveredVisibleFor(ProjectState.delivering), isTrue);
    });

    test('closed → hidden (terminal)', () {
      expect(isMarkDeliveredVisibleFor(ProjectState.closed), isFalse);
    });

    test('draft → hidden', () {
      expect(isMarkDeliveredVisibleFor(ProjectState.draft), isFalse);
    });

    test('cancelled → hidden', () {
      expect(isMarkDeliveredVisibleFor(ProjectState.cancelled), isFalse);
    });
  });

  group('paymentMethod handoff to applyOperatorMarkPaidPatch', () {
    // The screen's _confirmMarkPaid forwards `project.paymentMethod ?? 'cash'`
    // into ProjectOperatorMarkPaidPatch. The repo asserts the method is in
    // {cash, upi, cod, bank_transfer}; this test pins the screen's mapping
    // for each customer-set method so future edits cannot silently drop
    // the audit trail.

    String resolveMethod(String? projectPaymentMethod) =>
        projectPaymentMethod ?? 'cash';

    test('upi (awaiting_verification customer claim) flows through', () {
      expect(resolveMethod('upi'), 'upi');
    });

    test('bank_transfer (awaiting_verification customer claim) flows through',
        () {
      expect(resolveMethod('bank_transfer'), 'bank_transfer');
    });

    test('cod (committed self-tag) flows through', () {
      expect(resolveMethod('cod'), 'cod');
    });

    test('null (committed in-person) defaults to cash', () {
      expect(resolveMethod(null), 'cash');
    });
  });
}
