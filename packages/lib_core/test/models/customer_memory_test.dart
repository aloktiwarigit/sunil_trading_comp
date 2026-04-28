// =============================================================================
// CustomerMemory model — JSON round-trip, enum serialization, domain getters.
//
// Covers S4.9 foundation: the CustomerMemory Freezed model at
// packages/lib_core/lib/src/models/customer_memory.dart.
//
// Tests assert:
//   1. fromJson/toJson round-trip preserves every field
//   2. PreferredOccasion enums serialize to domain names
//   3. hasContent getter works across all branches
//   4. Default values are sane
//   5. Partial JSON (first-edit scenario) deserializes without crash
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:lib_core/src/models/customer_memory.dart';

void main() {
  group('CustomerMemory', () {
    test('round-trips full document losslessly', () {
      final original = CustomerMemory(
        customerUid: 'cust_001',
        shopId: 'sunil-trading-company',
        notes: 'Sunita ki bahen Geeta bhi hamari customer hai',
        relationshipNotes: 'Sunita-ji ki saas ne 2019 mein Storwel li thi',
        preferredOccasions: [
          PreferredOccasion.shaadi,
          PreferredOccasion.nayaGhar,
        ],
        preferredPriceMin: 15000,
        preferredPriceMax: 45000,
        firstSeenAt: DateTime.parse('2025-06-15T10:30:00Z'),
        lastSeenAt: DateTime.parse('2026-04-10T14:00:00Z'),
        totalProjectsLifetime: 3,
      );

      final json = original.toJson();
      final restored = CustomerMemory.fromJson(json);

      expect(restored.customerUid, equals('cust_001'));
      expect(restored.shopId, equals('sunil-trading-company'));
      expect(restored.notes, contains('Geeta'));
      expect(restored.relationshipNotes, contains('Storwel'));
      expect(restored.preferredOccasions, hasLength(2));
      expect(restored.preferredOccasions, contains(PreferredOccasion.shaadi));
      expect(restored.preferredOccasions, contains(PreferredOccasion.nayaGhar));
      expect(restored.preferredPriceMin, equals(15000));
      expect(restored.preferredPriceMax, equals(45000));
      expect(restored.totalProjectsLifetime, equals(3));
    });

    test('PreferredOccasion enums serialize to domain names', () {
      // Domain-grounded: shaadi, nayaGhar, betiKaGhar (wire: 'dahej'), puranaBadalne
      // NOT: wedding, newHome, dowry, replacement
      // betiKaGhar writes as 'dahej' for Firestore backward compat (@JsonValue).
      final m = CustomerMemory(
        customerUid: 'test',
        shopId: 'test-shop',
        preferredOccasions: PreferredOccasion.values,
      );

      final json = m.toJson();
      final occasions = json['preferredOccasions'] as List;
      expect(occasions, contains('shaadi'));
      expect(occasions, contains('nayaGhar'));
      expect(occasions, contains('dahej')); // wire key for betiKaGhar (legacy compat)
      expect(occasions, contains('puranaBadalne'));
      expect(occasions, contains('budget'));
      expect(occasions, contains('ladies'));
      expect(occasions, contains('other'));
      // No forbidden generic terms
      expect(occasions, isNot(contains('wedding')));
      expect(occasions, isNot(contains('newHome')));
    });

    test('legacy dahej wire value deserializes to betiKaGhar', () {
      // Firestore docs written before the rename carry 'dahej' as the wire value.
      final json = <String, dynamic>{
        'customerUid': 'cust_legacy',
        'shopId': 'sunil-trading-company',
        'preferredOccasions': ['dahej'],
      };
      final m = CustomerMemory.fromJson(json);
      expect(m.preferredOccasions, contains(PreferredOccasion.betiKaGhar));
    });

    test('hasContent is false for default empty memory', () {
      final empty = CustomerMemory(
        customerUid: 'cust_new',
        shopId: 'sunil-trading-company',
      );

      expect(empty.hasContent, isFalse);
      expect(empty.notes, isEmpty);
      expect(empty.relationshipNotes, isEmpty);
      expect(empty.preferredOccasions, isEmpty);
      expect(empty.preferredPriceMin, isNull);
      expect(empty.preferredPriceMax, isNull);
    });

    test('hasContent is true when only notes are filled', () {
      final withNotes = CustomerMemory(
        customerUid: 'cust_001',
        shopId: 'sunil-trading-company',
        notes: 'Prefers dark finishes',
      );

      expect(withNotes.hasContent, isTrue);
    });

    test('hasContent is true when only occasions are filled', () {
      final withOccasions = CustomerMemory(
        customerUid: 'cust_001',
        shopId: 'sunil-trading-company',
        preferredOccasions: [PreferredOccasion.shaadi],
      );

      expect(withOccasions.hasContent, isTrue);
    });

    test('hasContent is true when only price range is set', () {
      final withPrice = CustomerMemory(
        customerUid: 'cust_001',
        shopId: 'sunil-trading-company',
        preferredPriceMin: 20000,
      );

      expect(withPrice.hasContent, isTrue);
    });

    test('partial JSON from first-edit scenario deserializes safely', () {
      // When the memory doc is first created, only a subset of fields exist.
      final partialJson = <String, dynamic>{
        'customerUid': 'cust_first_edit',
        'shopId': 'sunil-trading-company',
        'notes': 'Just met today',
      };

      final m = CustomerMemory.fromJson(partialJson);
      expect(m.notes, equals('Just met today'));
      expect(m.relationshipNotes, isEmpty);
      expect(m.preferredOccasions, isEmpty);
      expect(m.totalProjectsLifetime, equals(0));
      expect(m.hasContent, isTrue);
    });

    test('defaults are sane', () {
      final m = CustomerMemory(
        customerUid: 'x',
        shopId: 'y',
      );
      expect(m.totalProjectsLifetime, equals(0));
      expect(m.preferredOccasions, isEmpty);
      expect(m.notes, isEmpty);
      expect(m.relationshipNotes, isEmpty);
      expect(m.firstSeenAt, isNull);
      expect(m.lastSeenAt, isNull);
    });
  });
}
