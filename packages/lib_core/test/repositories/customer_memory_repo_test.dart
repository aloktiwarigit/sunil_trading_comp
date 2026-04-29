// =============================================================================
// CustomerMemoryRepo — Firestore integration test with fake_cloud_firestore.
//
// Covers S4.9:
//   1. upsertMemory creates doc on first edit (edge case #1)
//   2. upsertMemory merges fields on subsequent edits
//   3. getMemory returns null for non-existent customer
//   4. watchMemory streams updates
//   5. Cross-tenant: repo scopes to shopId (shape test)
// =============================================================================

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_core/src/models/customer_memory.dart';
import 'package:lib_core/src/repositories/customer_memory_repo.dart';
import 'package:lib_core/src/shop_id_provider.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late CustomerMemoryRepo repo;

  const shopId = 'sunil-trading-company';
  const customerUid = 'cust_001';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repo = CustomerMemoryRepo(
      firestore: fakeFirestore,
      shopIdProvider: const ShopIdProvider(shopId),
    );
  });

  group('CustomerMemoryRepo', () {
    test('getMemory returns null for non-existent customer', () async {
      final result = await repo.getMemory('does_not_exist');
      expect(result, isNull);
    });

    test('upsertMemory creates doc on first edit (S4.9 edge #1)', () async {
      await repo.upsertMemory(
        customerUid: customerUid,
        notes: 'Sunita ki bahen Geeta bhi hamari customer hai',
      );

      final result = await repo.getMemory(customerUid);
      expect(result, isNotNull);
      expect(result!.customerUid, equals(customerUid));
      expect(result.shopId, equals(shopId));
      expect(result.notes, contains('Geeta'));
    });

    test('upsertMemory merges fields on subsequent edits', () async {
      // First edit: notes only.
      await repo.upsertMemory(
        customerUid: customerUid,
        notes: 'First note',
      );

      // Second edit: add occasions + price range.
      await repo.upsertMemory(
        customerUid: customerUid,
        preferredOccasions: [PreferredOccasion.shaadi],
        preferredPriceMin: 20000,
        preferredPriceMax: 50000,
      );

      final result = await repo.getMemory(customerUid);
      expect(result, isNotNull);
      // First edit's notes are preserved (merge semantics).
      expect(result!.notes, equals('First note'));
      // Second edit's fields are also present.
      expect(result.preferredOccasions, contains(PreferredOccasion.shaadi));
      expect(result.preferredPriceMin, equals(20000));
      expect(result.preferredPriceMax, equals(50000));
    });

    test('upsertMemory overwrites fields when explicitly set', () async {
      await repo.upsertMemory(
        customerUid: customerUid,
        notes: 'Original note',
      );

      await repo.upsertMemory(
        customerUid: customerUid,
        notes: 'Updated note',
      );

      final result = await repo.getMemory(customerUid);
      expect(result!.notes, equals('Updated note'));
    });

    test('watchMemory streams updates in real time', () async {
      final stream = repo.watchMemory(customerUid);

      // Initially null.
      expect(
          stream,
          emitsInOrder([
            isNull,
            isNotNull,
          ]));

      // Trigger creation.
      await repo.upsertMemory(
        customerUid: customerUid,
        notes: 'Hello from stream test',
      );
    });

    test('cross-tenant: repo scopes reads to its shopId', () async {
      // Write memory under shop-1.
      await fakeFirestore
          .collection('shops')
          .doc('other-shop')
          .collection('customer_memory')
          .doc(customerUid)
          .set(<String, dynamic>{
        'shopId': 'other-shop',
        'customerUid': customerUid,
        'notes': 'This belongs to other-shop',
      });

      // Read from our repo (scoped to sunil-trading-company) → null.
      final result = await repo.getMemory(customerUid);
      expect(result, isNull);
    });

    test('multiple customers have independent memories', () async {
      await repo.upsertMemory(
        customerUid: 'cust_a',
        notes: 'Customer A',
      );
      await repo.upsertMemory(
        customerUid: 'cust_b',
        notes: 'Customer B',
      );

      final a = await repo.getMemory('cust_a');
      final b = await repo.getMemory('cust_b');

      expect(a!.notes, equals('Customer A'));
      expect(b!.notes, equals('Customer B'));
    });
  });
}
