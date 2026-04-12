// =============================================================================
// ProjectRepo tests — commit transaction + Triple Zero invariant (C3.4 AC #4).
//
// Tests applyCustomerCommitPatch against fake_cloud_firestore to verify:
//   1. Happy path: draft → committed transition
//   2. Triple Zero invariant: amountReceivedByShop == totalAmount
//   3. State precondition: rejects non-draft/negotiating states
//   4. Total amount computed from server-side line items
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_core/src/models/project.dart';
import 'package:lib_core/src/models/project_patch.dart';
import 'package:lib_core/src/repositories/project_repo.dart';
import 'package:lib_core/src/shop_id_provider.dart';

const shopId = 'sunil-trading-company';

void main() {
  late FakeFirebaseFirestore firestore;
  late ProjectRepo repo;
  late CollectionReference<Map<String, dynamic>> projectsCol;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = ProjectRepo(
      firestore: firestore,
      shopIdProvider: const ShopIdProvider(shopId),
    );
    projectsCol =
        firestore.collection('shops').doc(shopId).collection('projects');
  });

  /// Helper: seed a draft project with line items.
  Future<String> seedDraftProject({
    required List<Map<String, dynamic>> lineItems,
    String state = 'draft',
  }) async {
    final ref = projectsCol.doc();
    await ref.set({
      'projectId': ref.id,
      'shopId': shopId,
      'customerId': 'test-customer-uid',
      'customerUid': 'test-customer-uid',
      'state': state,
      'totalAmount': 0,
      'amountReceivedByShop': 0,
      'lineItems': lineItems,
      'unreadCountForCustomer': 0,
      'unreadCountForShopkeeper': 0,
      'createdAt': Timestamp.fromDate(DateTime(2026, 4, 12)),
    });
    return ref.id;
  }

  // ===========================================================================
  // applyCustomerCommitPatch — happy path
  // ===========================================================================

  group('applyCustomerCommitPatch', () {
    test('transitions draft → committed with correct totalAmount', () async {
      final projectId = await seedDraftProject(
        lineItems: [
          {
            'lineItemId': 'li-1',
            'skuId': 'sku-1',
            'skuName': 'शीशम अलमीरा',
            'quantity': 2,
            'unitPriceInr': 15000,
          },
          {
            'lineItemId': 'li-2',
            'skuId': 'sku-2',
            'skuName': 'सागवान डबल डोर',
            'quantity': 1,
            'unitPriceInr': 22000,
          },
        ],
      );

      await repo.applyCustomerCommitPatch(
        projectId,
        const ProjectCustomerCommitPatch(
          customerPhone: '+919876543210',
          customerDisplayName: 'Sunita',
        ),
      );

      final snap = await projectsCol.doc(projectId).get();
      final data = snap.data()!;

      expect(data['state'], 'committed');
      expect(data['totalAmount'], 52000); // 2*15000 + 1*22000
      expect(data['customerPhone'], '+919876543210');
      expect(data['customerDisplayName'], 'Sunita');
    });

    // =========================================================================
    // C3.4 AC #4 — Triple Zero invariant (machine-verifiable)
    // =========================================================================

    test('Triple Zero invariant: amountReceivedByShop == totalAmount at commit',
        () async {
      final projectId = await seedDraftProject(
        lineItems: [
          {
            'lineItemId': 'li-1',
            'skuId': 'sku-1',
            'skuName': 'शीशम अलमीरा',
            'quantity': 1,
            'unitPriceInr': 18000,
          },
        ],
      );

      await repo.applyCustomerCommitPatch(
        projectId,
        const ProjectCustomerCommitPatch(),
      );

      final snap = await projectsCol.doc(projectId).get();
      final data = snap.data()!;

      // THE invariant — zero commission, zero platform fee.
      expect(data['amountReceivedByShop'], data['totalAmount']);
      expect(data['amountReceivedByShop'], 18000);
      expect(data['totalAmount'], 18000);
    });

    test('rejects commit on Project in committed state', () async {
      final projectId = await seedDraftProject(
        lineItems: [
          {
            'lineItemId': 'li-1',
            'skuId': 'sku-1',
            'skuName': 'Test',
            'quantity': 1,
            'unitPriceInr': 5000,
          },
        ],
        state: 'committed',
      );

      expect(
        () => repo.applyCustomerCommitPatch(
          projectId,
          const ProjectCustomerCommitPatch(),
        ),
        throwsA(isA<ProjectRepoException>().having(
          (e) => e.code,
          'code',
          'invalid-state-transition',
        )),
      );
    });

    test('rejects commit on cancelled Project', () async {
      final projectId = await seedDraftProject(
        lineItems: [],
        state: 'cancelled',
      );

      expect(
        () => repo.applyCustomerCommitPatch(
          projectId,
          const ProjectCustomerCommitPatch(),
        ),
        throwsA(isA<ProjectRepoException>()),
      );
    });

    test('allows commit from negotiating state', () async {
      final projectId = await seedDraftProject(
        lineItems: [
          {
            'lineItemId': 'li-1',
            'skuId': 'sku-1',
            'skuName': 'Test',
            'quantity': 3,
            'unitPriceInr': 10000,
          },
        ],
        state: 'negotiating',
      );

      await repo.applyCustomerCommitPatch(
        projectId,
        const ProjectCustomerCommitPatch(),
      );

      final snap = await projectsCol.doc(projectId).get();
      expect(snap.data()!['state'], 'committed');
      expect(snap.data()!['totalAmount'], 30000);
      expect(snap.data()!['amountReceivedByShop'], 30000);
    });

    test('throws on non-existent Project', () async {
      expect(
        () => repo.applyCustomerCommitPatch(
          'does-not-exist',
          const ProjectCustomerCommitPatch(),
        ),
        throwsA(isA<ProjectRepoException>().having(
          (e) => e.code,
          'code',
          'not-found',
        )),
      );
    });

    test('rejects commit with empty line items (code review P3)', () async {
      final projectId = await seedDraftProject(lineItems: []);

      expect(
        () => repo.applyCustomerCommitPatch(
          projectId,
          const ProjectCustomerCommitPatch(),
        ),
        throwsA(isA<ProjectRepoException>().having(
          (e) => e.code,
          'code',
          'empty-cart',
        )),
      );
    });
  });

  // ===========================================================================
  // applyCustomerPaymentPatch — C3.5
  // ===========================================================================

  group('applyCustomerPaymentPatch', () {
    /// Helper: seed a committed project (post-C3.4).
    Future<String> seedCommittedProject({
      int totalAmount = 18000,
      int? amountReceivedByShop,
    }) async {
      final ref = projectsCol.doc();
      await ref.set({
        'projectId': ref.id,
        'shopId': shopId,
        'customerId': 'test-customer-uid',
        'customerUid': 'test-customer-uid',
        'state': 'committed',
        'totalAmount': totalAmount,
        'amountReceivedByShop': amountReceivedByShop ?? totalAmount,
        'lineItems': [],
        'unreadCountForCustomer': 0,
        'unreadCountForShopkeeper': 0,
        'createdAt': Timestamp.fromDate(DateTime(2026, 4, 12)),
      });
      return ref.id;
    }

    test('transitions committed → paid', () async {
      final projectId = await seedCommittedProject();

      await repo.applyCustomerPaymentPatch(
        projectId,
        const ProjectCustomerPaymentPatch(customerVpa: 'sunita@okicici'),
      );

      final snap = await projectsCol.doc(projectId).get();
      expect(snap.data()!['state'], 'paid');
      expect(snap.data()!['customerVpa'], 'sunita@okicici');
    });

    test('Triple Zero invariant re-verified at paid transition', () async {
      final projectId = await seedCommittedProject(totalAmount: 22000);

      // The transaction internally asserts amountReceivedByShop == totalAmount
      // before writing. If the invariant were violated, this would throw
      // ProjectRepoException('triple-zero-violation'). The fact that it
      // succeeds IS the assertion.
      await repo.applyCustomerPaymentPatch(
        projectId,
        const ProjectCustomerPaymentPatch(),
      );

      final snap = await projectsCol.doc(projectId).get();
      expect(snap.data()!['state'], 'paid');
    });

    test('rejects paid transition if Triple Zero violated', () async {
      // Artificially break the invariant.
      final projectId = await seedCommittedProject(
        totalAmount: 22000,
        amountReceivedByShop: 21000, // != totalAmount — violation
      );

      expect(
        () => repo.applyCustomerPaymentPatch(
          projectId,
          const ProjectCustomerPaymentPatch(),
        ),
        throwsA(isA<ProjectRepoException>().having(
          (e) => e.code,
          'code',
          'triple-zero-violation',
        )),
      );
    });

    test('rejects payment on draft Project', () async {
      final projectId = await seedDraftProject(lineItems: []);

      expect(
        () => repo.applyCustomerPaymentPatch(
          projectId,
          const ProjectCustomerPaymentPatch(),
        ),
        throwsA(isA<ProjectRepoException>().having(
          (e) => e.code,
          'code',
          'invalid-state-transition',
        )),
      );
    });

    test('rejects payment on already-paid Project', () async {
      final ref = projectsCol.doc();
      await ref.set({
        'projectId': ref.id,
        'shopId': shopId,
        'customerId': 'test-customer-uid',
        'customerUid': 'test-customer-uid',
        'state': 'paid',
        'totalAmount': 5000,
        'amountReceivedByShop': 5000,
        'lineItems': [],
        'createdAt': Timestamp.fromDate(DateTime(2026, 4, 12)),
      });

      expect(
        () => repo.applyCustomerPaymentPatch(
          ref.id,
          const ProjectCustomerPaymentPatch(),
        ),
        throwsA(isA<ProjectRepoException>()),
      );
    });
  });
}
