// =============================================================================
// PaymentController repo-path tests — Phase 3 payment correctness.
//
// PaymentController reads FirebaseFirestore.instance directly today, so the
// controller itself is exercised end-to-end via the Firebase emulator (not
// here). These tests drive the same repo path the controller uses
// (ProjectRepo on a fake Firestore) and verify the Phase 3 contract:
//
//   1. confirmPayment / UPI claim → committed → awaiting_verification
//   2. selectCod → stays committed, paymentMethod=cod, no money write
//   3. selectBankTransfer → committed → awaiting_verification, method=bank_transfer
//   4. None of these write amountReceivedByShop or paidAt
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer_app/features/project/payment_controller.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_core/lib_core.dart';

const _shopId = 'sunil-trading-company';

void main() {
  late FakeFirebaseFirestore firestore;
  late ProjectRepo repo;
  late CollectionReference<Map<String, dynamic>> projectsCol;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = ProjectRepo(
      firestore: firestore,
      shopIdProvider: const ShopIdProvider(_shopId),
    );
    projectsCol =
        firestore.collection('shops').doc(_shopId).collection('projects');
  });

  Future<String> seedCommittedProject() async {
    final ref = projectsCol.doc();
    await ref.set({
      'projectId': ref.id,
      'shopId': _shopId,
      'customerId': 'cust-uid',
      'customerUid': 'cust-uid',
      'state': 'committed',
      'totalAmount': 18000,
      'amountReceivedByShop': 0,
      'lineItems': <Map<String, dynamic>>[],
      'createdAt': Timestamp.fromDate(DateTime(2026, 4, 12)),
    });
    return ref.id;
  }

  test('confirmPayment moves committed → awaiting_verification, never paid',
      () async {
    final projectId = await seedCommittedProject();
    await repo.applyCustomerPaymentPatch(
      projectId,
      const ProjectCustomerPaymentPatch(customerVpa: 'sunita@okicici'),
    );
    final data = (await projectsCol.doc(projectId).get()).data()!;
    expect(data['state'], 'awaiting_verification');
    expect(data['paymentMethod'], 'upi');
    expect((data['amountReceivedByShop'] as num?)?.toInt() ?? 0, 0);
    expect(data['paidAt'], isNull);
  });

  test('selectCod stays in committed (or null under fake merge) and tags COD',
      () async {
    final projectId = await seedCommittedProject();
    await repo.applyCustomerCodPatch(
      projectId,
      const ProjectCustomerCodPatch(),
    );
    final data = (await projectsCol.doc(projectId).get()).data()!;
    expect(data['paymentMethod'], 'cod');
    final stateAfter = data['state'];
    expect(
      stateAfter == null || stateAfter == 'committed',
      isTrue,
      reason: 'COD must not advance past committed; got $stateAfter',
    );
    expect((data['amountReceivedByShop'] as num?)?.toInt() ?? 0, 0);
  });

  test('selectBankTransfer moves committed → awaiting_verification', () async {
    final projectId = await seedCommittedProject();
    await repo.applyCustomerBankTransferPatch(
      projectId,
      const ProjectCustomerBankTransferPatch(),
    );
    final data = (await projectsCol.doc(projectId).get()).data()!;
    expect(data['state'], 'awaiting_verification');
    expect(data['paymentMethod'], 'bank_transfer');
    expect(data['paidAt'], isNull);
    expect((data['amountReceivedByShop'] as num?)?.toInt() ?? 0, 0);
  });

  test('PaymentFlowStage.paid alias resolves to .submitted (deprecated)', () {
    // Phase 4 G2: `paid` was renamed to `submitted`. The old name remains
    // as a deprecated static getter inside the enum body for one release
    // so any in-flight branch still compiles. Removed in Phase 5.
    // ignore: deprecated_member_use_from_same_package
    expect(PaymentFlowStage.paid, PaymentFlowStage.submitted);
  });
}
