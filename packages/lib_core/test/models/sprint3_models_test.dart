// =============================================================================
// Sprint 3 shared models — JSON round-trip + domain enum serialization.
//
// Covers: Operator, InventorySku, CuratedShortlist, VoiceNote.
//
// These are the 4 shared Freezed models Sprint 3 leaf stories (B1.3 /
// B1.4 / B1.5 / S4.1) consume. The tests assert:
//   1. fromJson/toJson round-trip preserves every field
//   2. Domain enums serialize to their @JsonValue strings (canonical
//      SAD §5 names: bhaiya/beta/munshi, shaadi/naya_ghar/..., etc.)
//   3. Convenience getters work (isBhaiya, hasValidDuration, isCurated, ...)
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:lib_core/src/models/curated_shortlist.dart';
import 'package:lib_core/src/models/inventory_sku.dart';
import 'package:lib_core/src/models/operator.dart';
import 'package:lib_core/src/models/voice_note.dart';

void main() {
  // ===========================================================================
  // Operator
  // ===========================================================================

  group('Operator', () {
    test('round-trips bhaiya with full permissions', () {
      final original = Operator(
        uid: 'google_uid_sunil',
        shopId: 'sunil-trading-company',
        role: OperatorRole.bhaiya,
        displayName: 'Sunil',
        email: 'sunil@example.com',
        joinedAt: DateTime.parse('2026-04-11T00:00:00Z'),
        permissions: const OperatorPermissions(
          canEditInventory: true,
          canApproveDiscounts: true,
          canRecordUdhaar: true,
          canDeleteOrders: true,
          canManageOperators: true,
        ),
        weeklyHoursCommitted: 40,
      );

      final json = original.toJson();
      final restored = Operator.fromJson(json);

      expect(restored.uid, equals('google_uid_sunil'));
      expect(restored.role, equals(OperatorRole.bhaiya));
      expect(restored.permissions.canManageOperators, isTrue);
      expect(restored.isBhaiya, isTrue);
    });

    test('role enum serializes to canonical SAD names (not rules drift)', () {
      // Per SAD §5 + PRD canonical: bhaiya / beta / munshi
      // NOT per deployed firestore.rules line 50: shopkeeper / son / munshi
      // The rules drift is a separate pre-existing concern — this model
      // uses the canonical names which are authoritative.
      const roleMap = <OperatorRole, String>{
        OperatorRole.bhaiya: 'bhaiya',
        OperatorRole.beta: 'beta',
        OperatorRole.munshi: 'munshi',
      };

      for (final entry in roleMap.entries) {
        final op = Operator(
          uid: 'u',
          shopId: 's',
          role: entry.key,
          displayName: 'D',
          email: 'e@x.com',
          joinedAt: DateTime.parse('2026-04-11T00:00:00Z'),
        );
        expect(op.toJson()['role'], equals(entry.value));
      }
    });

    test('isBhaiya getter is true only for bhaiya role', () {
      for (final role in OperatorRole.values) {
        final op = Operator(
          uid: 'u',
          shopId: 's',
          role: role,
          displayName: 'D',
          email: 'e@x.com',
          joinedAt: DateTime.parse('2026-04-11T00:00:00Z'),
        );
        expect(op.isBhaiya, equals(role == OperatorRole.bhaiya));
      }
    });

    test('default permissions are restrictive (beta-safe)', () {
      const perms = OperatorPermissions();
      expect(
        perms.canEditInventory,
        isTrue,
        reason: 'beta should be able to edit inventory by default',
      );
      expect(
        perms.canManageOperators,
        isFalse,
        reason: 'beta must not be able to manage operators',
      );
      expect(perms.canApproveDiscounts, isFalse);
      expect(perms.canDeleteOrders, isFalse);
    });
  });

  // ===========================================================================
  // InventorySku
  // ===========================================================================

  group('InventorySku', () {
    test('round-trips a full SKU with domain-grounded fields', () {
      final original = InventorySku(
        skuId: 'sku_01',
        shopId: 'sunil-trading-company',
        name: 'Steel Almirah 4-Door Brown',
        nameDevanagari: 'स्टील अल्मीरा 4-दरवाज़ा भूरा',
        description: 'Mazboot, taala bhi achha',
        category: SkuCategory.steelAlmirah,
        material: SkuMaterial.steel,
        dimensions: const SkuDimensions(heightCm: 152, widthCm: 92, depthCm: 51),
        basePrice: 14000,
        negotiableDownTo: 12500,
        stockCount: 3,
        occasionTags: const <String>['shaadi', 'dahej'],
        createdAt: DateTime.parse('2026-04-11T00:00:00Z'),
      );

      final json = original.toJson();
      final restored = InventorySku.fromJson(json);

      expect(restored.nameDevanagari, equals('स्टील अल्मीरा 4-दरवाज़ा भूरा'));
      expect(restored.category, equals(SkuCategory.steelAlmirah));
      expect(restored.material, equals(SkuMaterial.steel));
      expect(restored.dimensions.heightCm, equals(152));
      expect(restored.basePrice, equals(14000));
      expect(restored.negotiableDownTo, equals(12500));
      expect(restored.occasionTags, contains('shaadi'));
    });

    test('category enum serializes to canonical snake_case names', () {
      const map = <SkuCategory, String>{
        SkuCategory.steelAlmirah: 'steel_almirah',
        SkuCategory.woodenWardrobe: 'wooden_wardrobe',
        SkuCategory.modular: 'modular',
        SkuCategory.dressing: 'dressing',
        SkuCategory.sideCabinet: 'side_cabinet',
      };

      for (final entry in map.entries) {
        final sku = InventorySku(
          skuId: 's',
          shopId: 'sh',
          name: 'n',
          nameDevanagari: 'न',
          category: entry.key,
          material: SkuMaterial.steel,
          dimensions: const SkuDimensions(heightCm: 100, widthCm: 100, depthCm: 50),
          basePrice: 10000,
          negotiableDownTo: 9000,
          createdAt: DateTime.parse('2026-04-11T00:00:00Z'),
        );
        expect(sku.toJson()['category'], equals(entry.value));
      }
    });

    test('hasGoldenHourPhoto is false when no photo IDs attached', () {
      final sku = InventorySku(
        skuId: 's',
        shopId: 'sh',
        name: 'n',
        nameDevanagari: 'न',
        category: SkuCategory.steelAlmirah,
        material: SkuMaterial.steel,
        dimensions: const SkuDimensions(heightCm: 100, widthCm: 100, depthCm: 50),
        basePrice: 10000,
        negotiableDownTo: 9000,
        createdAt: DateTime.parse('2026-04-11T00:00:00Z'),
      );
      expect(sku.hasGoldenHourPhoto, isFalse);
      expect(sku.hasVoiceNote, isFalse);
    });

    test('hasGoldenHourPhoto is true when at least one ID present', () {
      final sku = InventorySku(
        skuId: 's',
        shopId: 'sh',
        name: 'n',
        nameDevanagari: 'न',
        category: SkuCategory.steelAlmirah,
        material: SkuMaterial.steel,
        dimensions: const SkuDimensions(heightCm: 100, widthCm: 100, depthCm: 50),
        basePrice: 10000,
        negotiableDownTo: 9000,
        goldenHourPhotoIds: const <String>['ghp_01'],
        voiceNoteIds: const <String>['vn_01'],
        createdAt: DateTime.parse('2026-04-11T00:00:00Z'),
      );
      expect(sku.hasGoldenHourPhoto, isTrue);
      expect(sku.hasVoiceNote, isTrue);
    });
  });

  // ===========================================================================
  // CuratedShortlist
  // ===========================================================================

  group('CuratedShortlist', () {
    test('round-trips a shaadi shortlist with curated SKU order', () {
      final original = CuratedShortlist(
        shortlistId: 'sl_01',
        shopId: 'sunil-trading-company',
        occasion: ShortlistOccasion.shaadi,
        titleDevanagari: 'शादी के लिए',
        titleEnglish: 'For a wedding',
        description: 'Sunil-bhaiya ki sabse pasand wali shaadi almirahs',
        skuIdsInOrder: const <String>['sku_a', 'sku_b', 'sku_c', 'sku_d'],
        createdAt: DateTime.parse('2026-04-11T00:00:00Z'),
      );

      final json = original.toJson();
      final restored = CuratedShortlist.fromJson(json);

      expect(restored.occasion, equals(ShortlistOccasion.shaadi));
      expect(restored.titleDevanagari, equals('शादी के लिए'));
      expect(
        restored.skuIdsInOrder,
        equals(const <String>['sku_a', 'sku_b', 'sku_c', 'sku_d']),
        reason: 'SKU order is load-bearing — must round-trip exactly',
      );
      expect(restored.isCurated, isTrue);
      expect(restored.atFiniteCap, isFalse);
    });

    test('occasion enum serializes with canonical SAD names', () {
      const map = <ShortlistOccasion, String>{
        ShortlistOccasion.shaadi: 'shaadi',
        ShortlistOccasion.nayaGhar: 'naya_ghar',
        ShortlistOccasion.dahej: 'dahej',
        ShortlistOccasion.replacement: 'replacement',
        ShortlistOccasion.budget: 'budget',
        ShortlistOccasion.ladies: 'ladies',
      };

      for (final entry in map.entries) {
        final sl = CuratedShortlist(
          shortlistId: 's',
          shopId: 'sh',
          occasion: entry.key,
          titleDevanagari: 'द',
          titleEnglish: 'e',
          createdAt: DateTime.parse('2026-04-11T00:00:00Z'),
        );
        expect(sl.toJson()['occasion'], equals(entry.value));
      }
    });

    test('atFiniteCap is true exactly at 6 SKUs per UX Spec §4.3', () {
      CuratedShortlist withCount(int count) => CuratedShortlist(
            shortlistId: 's',
            shopId: 'sh',
            occasion: ShortlistOccasion.shaadi,
            titleDevanagari: 'द',
            titleEnglish: 'e',
            skuIdsInOrder: List.generate(count, (i) => 'sku_$i'),
            createdAt: DateTime.parse('2026-04-11T00:00:00Z'),
          );

      expect(withCount(0).atFiniteCap, isFalse);
      expect(withCount(5).atFiniteCap, isFalse);
      expect(withCount(6).atFiniteCap, isTrue);
    });

    test('isCurated is false for empty SKU list', () {
      final sl = CuratedShortlist(
        shortlistId: 's',
        shopId: 'sh',
        occasion: ShortlistOccasion.shaadi,
        titleDevanagari: 'द',
        titleEnglish: 'e',
        createdAt: DateTime.parse('2026-04-11T00:00:00Z'),
      );
      expect(sl.isCurated, isFalse);
    });
  });

  // ===========================================================================
  // VoiceNote
  // ===========================================================================

  group('VoiceNote', () {
    VoiceNote sample({
      int duration = 23,
      VoiceNoteAuthorRole role = VoiceNoteAuthorRole.bhaiya,
      VoiceNoteAttachment attachment = VoiceNoteAttachment.sku,
      String refId = 'sku_01',
    }) =>
        VoiceNote(
          voiceNoteId: 'vn_01',
          shopId: 'sunil-trading-company',
          authorUid: 'google_sunil',
          authorRole: role,
          durationSeconds: duration,
          audioStorageRef: 'shops/sunil-trading-company/voice_notes/vn_01.m4a',
          audioSizeBytes: 187000,
          attachmentType: attachment,
          attachmentRefId: refId,
          recordedAt: DateTime.parse('2026-04-11T00:00:00Z'),
        );

    test('round-trips a bhaiya SKU voice note', () {
      final original = sample();
      final json = original.toJson();
      final restored = VoiceNote.fromJson(json);

      expect(restored.voiceNoteId, equals('vn_01'));
      expect(restored.authorRole, equals(VoiceNoteAuthorRole.bhaiya));
      expect(restored.attachmentType, equals(VoiceNoteAttachment.sku));
      expect(restored.durationSeconds, equals(23));
      expect(restored.isByBhaiya, isTrue);
      expect(restored.hasValidDuration, isTrue);
    });

    test('author role serializes with canonical names', () {
      expect(
        sample(role: VoiceNoteAuthorRole.bhaiya).toJson()['authorRole'],
        equals('bhaiya'),
      );
      expect(
        sample(role: VoiceNoteAuthorRole.beta).toJson()['authorRole'],
        equals('beta'),
      );
    });

    test('attachment type serializes with snake_case for multi-word', () {
      const map = <VoiceNoteAttachment, String>{
        VoiceNoteAttachment.sku: 'sku',
        VoiceNoteAttachment.project: 'project',
        VoiceNoteAttachment.customer: 'customer',
        VoiceNoteAttachment.absenceStatus: 'absence_status',
        VoiceNoteAttachment.shopLanding: 'shop_landing',
      };

      for (final entry in map.entries) {
        expect(
          sample(attachment: entry.key).toJson()['attachmentType'],
          equals(entry.value),
        );
      }
    });

    test('hasValidDuration boundary: 5 and 60 pass, 4 and 61 fail', () {
      expect(sample(duration: 5).hasValidDuration, isTrue);
      expect(sample(duration: 60).hasValidDuration, isTrue);
      expect(sample(duration: 4).hasValidDuration, isFalse);
      expect(sample(duration: 61).hasValidDuration, isFalse);
    });

    test('isByBhaiya discriminates bhaiya vs beta', () {
      expect(sample(role: VoiceNoteAuthorRole.bhaiya).isByBhaiya, isTrue);
      expect(sample(role: VoiceNoteAuthorRole.beta).isByBhaiya, isFalse);
    });
  });
}
