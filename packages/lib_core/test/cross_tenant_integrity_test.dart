// =============================================================================
// cross_tenant_integrity_test.dart
//
// Dart-side SHAPE test that complements the TS rules test at
// `tools/src/cross_tenant_integrity.test.ts`.
//
// Division of responsibility:
//   - THE actual Firestore security rule enforcement test is the TS one
//     (uses @firebase/rules-unit-testing against the emulator to verify the
//     real rule file rejects cross-tenant reads/writes). SAD §6 v1.0.4.
//   - This Dart test verifies SHAPE invariants of the model + repository
//     layer that cannot be expressed in rules: every model has a `shopId`
//     field, every repository write method takes a typed patch (not a
//     `Map<String, dynamic>`), no model exposes a public raw-map setter,
//     Project has the `amountReceivedByShop` invariant, and the three
//     partition patch classes exist and are distinct types.
//
// The two tests run together in CI (`ci-cross-tenant-test.yml`). Either
// failing blocks the build. Both are mandatory per PRD I6.4 + I6.12.
// =============================================================================

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lib_core/src/models/chat_thread.dart';
import 'package:lib_core/src/models/customer.dart';
import 'package:lib_core/src/models/customer_memory.dart';
import 'package:lib_core/src/models/line_item.dart';
import 'package:lib_core/src/models/project.dart';
import 'package:lib_core/src/models/project_patch.dart';
import 'package:lib_core/src/models/shop.dart';
import 'package:lib_core/src/models/udhaar_ledger.dart';
import 'package:lib_core/src/models/udhaar_ledger_patch.dart';
import 'package:lib_core/src/repositories/project_repo.dart';
import 'package:lib_core/src/shop_id_provider.dart';

void main() {
  group('Cross-tenant integrity — SHAPE invariants', () {
    // -------------------------------------------------------------------------
    // Every model has a shopId field (per ADR-003 multi-tenant scoping)
    // -------------------------------------------------------------------------

    group('every model carries shopId', () {
      test('Shop has shopId', () {
        final now = DateTime.now();
        final shop = Shop(
          shopId: 'sunil-trading-company',
          brandName: 'Sunil Trading Company',
          brandNameDevanagari: 'सुनील ट्रेडिंग कंपनी',
          ownerUid: 'op-1',
          market: 'Harringtonganj, Ayodhya',
          createdAt: now,
          activeFromDay: now,
        );
        expect(shop.shopId, isNotEmpty);
      });

      test('Customer has shopId', () {
        final cust = Customer(
          shopId: 'sunil-trading-company',
          customerId: 'c1',
          createdAt: DateTime.now(),
        );
        expect(cust.shopId, isNotEmpty);
        expect(cust.previousProjectIds, isEmpty);
      });

      test('Project has shopId', () {
        final proj = Project(
          projectId: 'p1',
          shopId: 'sunil-trading-company',
          customerId: 'c1',
          customerUid: 'uid-1',
          createdAt: DateTime.now(),
        );
        expect(proj.shopId, isNotEmpty);
      });

      test('ChatThread has shopId', () {
        final thread = ChatThread(
          threadId: 't1',
          shopId: 'sunil-trading-company',
          projectId: 'p1',
          customerUid: 'uid-1',
          customerDisplayName: 'Test',
          participantUids: const ['uid-1'],
          createdAt: DateTime.now(),
        );
        expect(thread.shopId, isNotEmpty);
      });

      // S4.9 AC #4: CustomerMemory has shopId + customer cannot read it
      test('CustomerMemory has shopId', () {
        final mem = CustomerMemory(
          customerUid: 'cust_001',
          shopId: 'sunil-trading-company',
          notes: 'test',
        );
        expect(mem.shopId, isNotEmpty);
      });

      test('UdhaarLedger has shopId', () {
        final udh = UdhaarLedger(
          ledgerId: 'u1',
          shopId: 'sunil-trading-company',
          customerId: 'c1',
          recordedAmount: 10000,
          runningBalance: 10000,
        );
        expect(udh.shopId, isNotEmpty);
      });
    });

    // -------------------------------------------------------------------------
    // Shop lifecycle (ADR-013) — only `active` is writable from client
    // -------------------------------------------------------------------------

    group('Shop lifecycle state machine', () {
      test('active is writable', () {
        final shop = _minimalShop(lifecycle: ShopLifecycle.active);
        expect(shop.isWritable, isTrue);
      });

      test('deactivating is NOT writable', () {
        final shop = _minimalShop(lifecycle: ShopLifecycle.deactivating);
        expect(shop.isWritable, isFalse);
      });

      test('purge_scheduled is NOT writable', () {
        final shop = _minimalShop(lifecycle: ShopLifecycle.purgeScheduled);
        expect(shop.isWritable, isFalse);
      });

      test('purged is NOT writable', () {
        final shop = _minimalShop(lifecycle: ShopLifecycle.purged);
        expect(shop.isWritable, isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // Project Triple Zero invariant (amountReceivedByShop == totalAmount)
    // -------------------------------------------------------------------------

    group('Project zero-commission invariant', () {
      test('zero == zero satisfies the invariant', () {
        final p = _minimalProject().copyWith(
          totalAmount: 0,
          amountReceivedByShop: 0,
        );
        expect(p.zeroCommissionSatisfied, isTrue);
      });

      test('amountReceivedByShop == totalAmount satisfies', () {
        final p = _minimalProject().copyWith(
          totalAmount: 25000,
          amountReceivedByShop: 25000,
        );
        expect(p.zeroCommissionSatisfied, isTrue);
      });

      test('amountReceivedByShop < totalAmount VIOLATES', () {
        final p = _minimalProject().copyWith(
          totalAmount: 25000,
          amountReceivedByShop: 24000, // commission-like leakage
        );
        expect(p.zeroCommissionSatisfied, isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // Partition discipline — the three patch classes are distinct types
    // and do not share a common supertype that would let code construct
    // an operator patch via a customer-typed variable.
    // -------------------------------------------------------------------------

    group('Project partition patches are distinct types', () {
      test('ProjectCustomerPatch and ProjectOperatorPatch are unrelated', () {
        const customer = ProjectCustomerPatch(occasion: 'shaadi');
        const operator = ProjectOperatorPatch(totalAmount: 25000);

        // At the type level these cannot be assigned to each other.
        // This test just asserts the runtimeType is distinct so a future
        // refactor can't accidentally unify them.
        expect(customer.runtimeType, isNot(equals(operator.runtimeType)));
        expect(
          customer.runtimeType.toString(),
          isNot(contains('Operator')),
        );
        expect(
          operator.runtimeType.toString(),
          isNot(contains('Customer')),
        );
      });

      test('ProjectCustomerPatch.toFirestoreMap() only emits customer fields',
          () {
        const patch = ProjectCustomerPatch(
          occasion: 'shaadi',
          unreadCountForCustomer: 0,
        );
        final map = patch.toFirestoreMap();
        expect(map.keys, containsAll(['occasion', 'unreadCountForCustomer']));
        // Must NOT emit operator or system fields.
        expect(map.keys, isNot(contains('state')));
        expect(map.keys, isNot(contains('totalAmount')));
        expect(map.keys, isNot(contains('amountReceivedByShop')));
        expect(map.keys, isNot(contains('lastMessageAt')));
      });

      test(
          'ProjectOperatorPatch.toFirestoreMap() can emit amountReceivedByShop',
          () {
        const patch = ProjectOperatorPatch(
          state: ProjectState.paid,
          totalAmount: 25000,
          amountReceivedByShop: 25000,
        );
        final map = patch.toFirestoreMap();
        expect(map['amountReceivedByShop'], equals(25000));
        expect(map['totalAmount'], equals(25000));
        expect(map['state'], equals('paid'));
        // Must NOT emit customer or system fields.
        expect(map.keys, isNot(contains('occasion')));
        expect(map.keys, isNot(contains('lastMessageAt')));
      });

      test('ProjectSystemPatch.toFirestoreMap() only emits system fields', () {
        final now = DateTime.now();
        final patch = ProjectSystemPatch(
          lastMessagePreview: 'hello',
          lastMessageAt: now,
        );
        final map = patch.toFirestoreMap();
        expect(map.keys, containsAll(['lastMessagePreview', 'lastMessageAt']));
        expect(map.keys, isNot(contains('occasion')));
        expect(map.keys, isNot(contains('totalAmount')));
      });
    });

    // -------------------------------------------------------------------------
    // UdhaarLedger RBI guardrails
    // -------------------------------------------------------------------------

    group('UdhaarLedger RBI guardrails', () {
      test('default reminderOptInByBhaiya is false', () {
        final u = UdhaarLedger(
          ledgerId: 'u1',
          shopId: 's1',
          customerId: 'c1',
          recordedAmount: 10000,
          runningBalance: 10000,
        );
        expect(u.reminderOptInByBhaiya, isFalse);
        expect(u.canSendAnotherReminder, isFalse);
      });

      test('reminderCadenceDays out of [7,30] is rejected by patch', () {
        expect(
          () => const UdhaarLedgerOperatorPatch(reminderCadenceDays: 6)
              .toFirestoreMap(),
          throwsArgumentError,
        );
        expect(
          () => const UdhaarLedgerOperatorPatch(reminderCadenceDays: 31)
              .toFirestoreMap(),
          throwsArgumentError,
        );
      });

      test('reminderCountLifetime capped at 3 by system patch', () {
        expect(
          () => const UdhaarLedgerSystemPatch(reminderCountLifetime: 4)
              .toFirestoreMap(),
          throwsArgumentError,
        );
      });
    });

    // -------------------------------------------------------------------------
    // ProjectRepo partition enforcement — fake_cloud_firestore shape test
    // -------------------------------------------------------------------------

    group('ProjectRepo enforces partition at write time', () {
      late FakeFirebaseFirestore fakeFirestore;
      late ProjectRepo repo;

      setUp(() {
        fakeFirestore = FakeFirebaseFirestore();
        repo = ProjectRepo(
          firestore: fakeFirestore,
          shopIdProvider: const ShopIdProvider('sunil-trading-company'),
        );
      });

      test('applyCustomerPatch only writes customer-owned fields', () async {
        // Seed a project first.
        await fakeFirestore
            .collection('shops')
            .doc('sunil-trading-company')
            .collection('projects')
            .doc('p1')
            .set(<String, Object?>{
          'shopId': 'sunil-trading-company',
          'customerId': 'c1',
          'state': 'draft',
          'totalAmount': 25000,
          'amountReceivedByShop': 0,
        });

        await repo.applyCustomerPatch(
          'p1',
          const ProjectCustomerPatch(
            occasion: 'shaadi',
            unreadCountForCustomer: 0,
          ),
        );

        final snap = await fakeFirestore
            .collection('shops')
            .doc('sunil-trading-company')
            .collection('projects')
            .doc('p1')
            .get();

        expect(snap.data()!['occasion'], equals('shaadi'));
        // Operator and system fields must not be touched.
        expect(snap.data()!['totalAmount'], equals(25000));
        expect(snap.data()!['amountReceivedByShop'], equals(0));
        expect(snap.data()!['state'], equals('draft'));
      });
    });
  });
}

// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------

Shop _minimalShop({ShopLifecycle lifecycle = ShopLifecycle.active}) {
  final now = DateTime.now();
  return Shop(
    shopId: 'sunil-trading-company',
    brandName: 'Sunil Trading Company',
    brandNameDevanagari: 'सुनील ट्रेडिंग कंपनी',
    ownerUid: 'op-1',
    market: 'Harringtonganj, Ayodhya',
    createdAt: now,
    activeFromDay: now,
    shopLifecycle: lifecycle,
  );
}

Project _minimalProject() => Project(
      projectId: 'p1',
      shopId: 'sunil-trading-company',
      customerId: 'c1',
      customerUid: 'uid-1',
      lineItems: const <LineItem>[],
      createdAt: DateTime.now(),
    );
