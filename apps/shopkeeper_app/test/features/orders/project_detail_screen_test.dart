// =============================================================================
// project_detail_screen — real button → callback → repo widget test.
//
// Phase 4 G3 (2026-05-01): replaces the predicate-only test from Phase 3 r5
// with a test that pumps the actual screen, finds the actual button, taps
// it, and asserts the actual Firestore write that lands. Provider extraction
// (firestoreProvider, projectRepoProvider — both in lib_core) lets us
// override firestore with a FakeFirebaseFirestore in the ProviderScope so
// the screen's stream providers + the typed mark-paid write all see the
// same fake.
//
// What this test proves end-to-end:
//   1. An awaiting_verification project with paymentMethod=upi renders the
//      "भुगतान मिला" Mark Paid button (Phase 3 r5 visibility fix).
//   2. Tapping the button triggers the dialog confirm flow.
//   3. The confirm flow calls applyOperatorMarkPaidPatch under the hood
//      (the typed transactional path).
//   4. The Firestore doc reflects state=paid, paymentMethod=upi,
//      amountReceivedByShop=totalAmount, paidAt non-null.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_core/lib_core.dart';

import 'package:shopkeeper_app/features/orders/project_detail_screen.dart';

const _shopId = 'test-shop';

/// Mirrors the production theme so widgets that read context.yugmaTheme
/// (used inside ProjectDetailScreen) can build inside tests.
ThemeData _testTheme() => ThemeData(
      extensions: <ThemeExtension<dynamic>>[
        YugmaThemeExtension.fromTokens(
          ShopThemeTokens.sunilTradingCompanyDefault(),
        ),
      ],
    );

Future<void> _seedAwaitingVerificationProject(
  FakeFirebaseFirestore fake,
  String projectId,
) async {
  await fake
      .collection('shops')
      .doc(_shopId)
      .collection('projects')
      .doc(projectId)
      .set({
    'projectId': projectId,
    'shopId': _shopId,
    'customerId': 'cust-uid',
    'customerUid': 'cust-uid',
    'state': 'awaiting_verification',
    'totalAmount': 18000,
    'amountReceivedByShop': 0,
    'paymentMethod': 'upi',
    'customerVpa': 'sunita@okicici',
    'lineItems': <Map<String, dynamic>>[],
    'createdAt': Timestamp.fromDate(DateTime(2026, 5, 1)),
  });
}

void main() {
  testWidgets(
    'awaiting_verification → operator taps भुगतान मिला → repo writes paid',
    (tester) async {
      final fake = FakeFirebaseFirestore();
      const projectId = 'p-aw-verify';
      await _seedAwaitingVerificationProject(fake, projectId);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firestoreProvider.overrideWithValue(fake),
            shopIdProviderProvider.overrideWithValue(
              const ShopIdProvider(_shopId),
            ),
          ],
          child: MaterialApp(
            theme: _testTheme(),
            home: const ProjectDetailScreen(projectId: projectId),
          ),
        ),
      );
      // First pump renders the loading spinner. Settle the stream so the
      // project loads.
      await tester.pumpAndSettle();

      // 1. Mark Paid button is rendered.
      final markPaidFinder = find.text('भुगतान मिला');
      expect(markPaidFinder, findsOneWidget,
          reason: 'awaiting_verification must show Mark Paid');

      // 2. Tap the button. The screen opens a confirmation dialog.
      await tester.tap(markPaidFinder);
      await tester.pumpAndSettle();

      // 3. Confirm in the dialog. The dialog's confirm button uses
      //    `strings.draftQtyHighConfirm` which resolves to 'हाँ, जोड़िए'.
      final confirmFinder = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('हाँ, जोड़िए'),
      );
      expect(confirmFinder, findsOneWidget,
          reason: 'mark-paid dialog must surface a confirm button');
      await tester.tap(confirmFinder);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 4. Read back the Firestore doc and verify the typed mark-paid
      //    transaction landed.
      final after = await fake
          .collection('shops')
          .doc(_shopId)
          .collection('projects')
          .doc(projectId)
          .get();
      final data = after.data()!;
      expect(data['state'], 'paid',
          reason: 'mark-paid must transition state to paid');
      expect(data['paymentMethod'], 'upi',
          reason: 'mark-paid must preserve customer-claimed paymentMethod');
      expect(data['amountReceivedByShop'], 18000,
          reason: 'Triple Zero: amountReceivedByShop = totalAmount');
      expect(data['paidAt'], isNotNull, reason: 'mark-paid must stamp paidAt');
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
