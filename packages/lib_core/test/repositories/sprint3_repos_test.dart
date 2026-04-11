// =============================================================================
// Sprint 3 repository tests — OperatorRepo, InventorySkuRepo,
// CuratedShortlistRepo, VoiceNoteRepo.
//
// Each repo is tested against fake_cloud_firestore with a stub
// ShopIdProvider. Coverage per repo:
//   - CRUD happy path
//   - Shop-scoped path verification
//   - Key invariants (finite cap, duration bounds, soft delete)
//   - Read-order preservation (curated SKU order, bulk getByIds)
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_core/src/models/curated_shortlist.dart';
import 'package:lib_core/src/models/inventory_sku.dart';
import 'package:lib_core/src/models/operator.dart';
import 'package:lib_core/src/models/voice_note.dart';
import 'package:lib_core/src/repositories/curated_shortlist_repo.dart';
import 'package:lib_core/src/repositories/inventory_sku_repo.dart';
import 'package:lib_core/src/repositories/operator_repo.dart';
import 'package:lib_core/src/repositories/voice_note_repo.dart';
import 'package:lib_core/src/shop_id_provider.dart';

const shopId = 'sunil-trading-company';

void main() {
  late FakeFirebaseFirestore firestore;
  late ShopIdProvider shopIdProvider;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    shopIdProvider = const ShopIdProvider(shopId);
  });

  // ===========================================================================
  // OperatorRepo
  // ===========================================================================

  group('OperatorRepo', () {
    late OperatorRepo repo;

    setUp(() {
      repo = OperatorRepo(
        firestore: firestore,
        shopIdProvider: shopIdProvider,
      );
    });

    test('create + getByUid round-trips a bhaiya', () async {
      final op = Operator(
        uid: 'google_sunil',
        shopId: shopId,
        role: OperatorRole.bhaiya,
        displayName: 'Sunil',
        email: 'sunil@example.com',
        joinedAt: DateTime.parse('2026-04-11T00:00:00Z'),
      );

      await repo.create(op);

      final fetched = await repo.getByUid('google_sunil');
      expect(fetched, isNotNull);
      expect(fetched!.role, equals(OperatorRole.bhaiya));
      expect(fetched.displayName, equals('Sunil'));
    });

    test('uses canonical shop-scoped path shops/{shopId}/operators', () async {
      final op = Operator(
        uid: 'google_aditya',
        shopId: shopId,
        role: OperatorRole.beta,
        displayName: 'Aditya',
        email: 'aditya@example.com',
        joinedAt: DateTime.parse('2026-04-11T00:00:00Z'),
      );

      await repo.create(op);

      // Verify directly via the canonical path.
      final doc = await firestore
          .collection('shops')
          .doc(shopId)
          .collection('operators')
          .doc('google_aditya')
          .get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['role'], equals('beta'));
    });

    test('getByUid returns null for missing operator', () async {
      expect(await repo.getByUid('ghost'), isNull);
    });

    test('listAll returns all operators for the current shop', () async {
      for (var i = 0; i < 3; i++) {
        await repo.create(Operator(
          uid: 'uid_$i',
          shopId: shopId,
          role: i == 0 ? OperatorRole.bhaiya : OperatorRole.beta,
          displayName: 'Op $i',
          email: 'op$i@example.com',
          joinedAt: DateTime.parse('2026-04-11T00:00:00Z'),
        ));
      }

      final all = await repo.listAll();
      expect(all, hasLength(3));
      expect(
        all.where((o) => o.isBhaiya).length,
        equals(1),
        reason: 'exactly one bhaiya per shop in this seed',
      );
    });

    test('touchLastActive writes a timestamp without touching other fields',
        () async {
      await repo.create(Operator(
        uid: 'u',
        shopId: shopId,
        role: OperatorRole.bhaiya,
        displayName: 'Original',
        email: 'o@x.com',
        joinedAt: DateTime.parse('2026-04-11T00:00:00Z'),
      ));

      await repo.touchLastActive('u');

      final doc = await firestore
          .collection('shops')
          .doc(shopId)
          .collection('operators')
          .doc('u')
          .get();
      expect(doc.data()!['displayName'], equals('Original'));
      expect(doc.data()!['lastActiveAt'], isNotNull);
    });
  });

  // ===========================================================================
  // InventorySkuRepo
  // ===========================================================================

  group('InventorySkuRepo', () {
    late InventorySkuRepo repo;

    InventorySku buildSku(String id, {int basePrice = 14000}) => InventorySku(
          skuId: id,
          shopId: shopId,
          name: 'Almirah $id',
          nameDevanagari: 'अल्मीरा $id',
          category: SkuCategory.steelAlmirah,
          material: SkuMaterial.steel,
          dimensions: const SkuDimensions(
            heightCm: 152,
            widthCm: 92,
            depthCm: 51,
          ),
          basePrice: basePrice,
          negotiableDownTo: basePrice - 1500,
          createdAt: DateTime.parse('2026-04-11T00:00:00Z'),
        );

    setUp(() {
      repo = InventorySkuRepo(
        firestore: firestore,
        shopIdProvider: shopIdProvider,
      );
    });

    test('upsert + getById round-trips', () async {
      await repo.upsert(buildSku('sku_01'));
      final fetched = await repo.getById('sku_01');

      expect(fetched, isNotNull);
      expect(fetched!.nameDevanagari, equals('अल्मीरा sku_01'));
      expect(fetched.basePrice, equals(14000));
    });

    test('getByIds preserves the input order (load-bearing for B1.4)',
        () async {
      // Write out of order to verify the repo preserves caller-specified
      // order (shopkeeper's curation intent), not Firestore's arbitrary
      // document order.
      await repo.upsert(buildSku('sku_c'));
      await repo.upsert(buildSku('sku_a'));
      await repo.upsert(buildSku('sku_b'));

      final fetched = await repo.getByIds(<String>['sku_a', 'sku_b', 'sku_c']);
      expect(
        fetched.map((s) => s.skuId).toList(),
        equals(<String>['sku_a', 'sku_b', 'sku_c']),
        reason: 'shopkeeper-curated order must be preserved',
      );
    });

    test('getByIds with empty list returns empty without a query', () async {
      final fetched = await repo.getByIds(const <String>[]);
      expect(fetched, isEmpty);
    });

    test('getByIds rejects >10 IDs (Firestore whereIn cap)', () async {
      await expectLater(
        repo.getByIds(List.generate(11, (i) => 'sku_$i')),
        throwsA(
          isA<InventorySkuRepoException>().having(
            (e) => e.code,
            'code',
            'too-many-ids',
          ),
        ),
      );
    });

    test('softDelete sets isActive false without removing the doc', () async {
      await repo.upsert(buildSku('sku_to_remove'));
      await repo.softDelete('sku_to_remove');

      final doc = await firestore
          .collection('shops')
          .doc(shopId)
          .collection('inventory')
          .doc('sku_to_remove')
          .get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['isActive'], isFalse);
    });

    test('getById returns null for unknown SKU', () async {
      expect(await repo.getById('ghost'), isNull);
    });
  });

  // ===========================================================================
  // CuratedShortlistRepo
  // ===========================================================================

  group('CuratedShortlistRepo', () {
    late CuratedShortlistRepo repo;

    CuratedShortlist build({
      required String id,
      required ShortlistOccasion occasion,
      List<String> skus = const <String>[],
    }) =>
        CuratedShortlist(
          shortlistId: id,
          shopId: shopId,
          occasion: occasion,
          titleDevanagari: 'द',
          titleEnglish: 'e',
          skuIdsInOrder: skus,
          createdAt: DateTime.parse('2026-04-11T00:00:00Z'),
        );

    setUp(() {
      repo = CuratedShortlistRepo(
        firestore: firestore,
        shopIdProvider: shopIdProvider,
      );
    });

    test('upsert + getById round-trips with curated SKU order', () async {
      await repo.upsert(build(
        id: 'sl_shaadi',
        occasion: ShortlistOccasion.shaadi,
        skus: const <String>['sku_a', 'sku_b', 'sku_c'],
      ));

      final fetched = await repo.getById('sl_shaadi');
      expect(fetched, isNotNull);
      expect(fetched!.occasion, equals(ShortlistOccasion.shaadi));
      expect(
        fetched.skuIdsInOrder,
        equals(const <String>['sku_a', 'sku_b', 'sku_c']),
      );
    });

    test('upsert enforces finite cap of 6 per UX Spec §4.3', () async {
      final tooMany = build(
        id: 'sl_big',
        occasion: ShortlistOccasion.shaadi,
        skus: List.generate(7, (i) => 'sku_$i'),
      );

      await expectLater(
        repo.upsert(tooMany),
        throwsA(
          isA<CuratedShortlistRepoException>().having(
            (e) => e.code,
            'code',
            'finite-cap-exceeded',
          ),
        ),
      );
    });

    test('reorderSkus is atomic — final state matches requested order',
        () async {
      await repo.upsert(build(
        id: 'sl_budget',
        occasion: ShortlistOccasion.budget,
        skus: const <String>['sku_a', 'sku_b', 'sku_c'],
      ));

      await repo.reorderSkus('sl_budget', <String>['sku_c', 'sku_a', 'sku_b']);

      final fetched = await repo.getById('sl_budget');
      expect(
        fetched!.skuIdsInOrder,
        equals(const <String>['sku_c', 'sku_a', 'sku_b']),
      );
    });

    test('reorderSkus enforces finite cap', () async {
      await repo.upsert(build(
        id: 'sl_dahej',
        occasion: ShortlistOccasion.dahej,
        skus: const <String>['sku_a'],
      ));

      await expectLater(
        repo.reorderSkus(
          'sl_dahej',
          List.generate(7, (i) => 'sku_$i'),
        ),
        throwsA(
          isA<CuratedShortlistRepoException>().having(
            (e) => e.code,
            'code',
            'finite-cap-exceeded',
          ),
        ),
      );
    });

    test('listAll returns only active shortlists', () async {
      await repo.upsert(build(
        id: 'sl_active',
        occasion: ShortlistOccasion.shaadi,
      ));
      // Manually write an inactive shortlist.
      await firestore
          .collection('shops')
          .doc(shopId)
          .collection('curatedShortlists')
          .doc('sl_inactive')
          .set(<String, dynamic>{
        'shortlistId': 'sl_inactive',
        'shopId': shopId,
        'occasion': 'ladies',
        'titleDevanagari': 'लेडीज',
        'titleEnglish': 'Ladies',
        'skuIdsInOrder': <String>[],
        'createdAt': Timestamp.fromDate(DateTime.parse('2026-04-11T00:00:00Z')),
        'isActive': false,
      });

      final all = await repo.listAll();
      expect(all, hasLength(1));
      expect(all.first.shortlistId, equals('sl_active'));
    });
  });

  // ===========================================================================
  // VoiceNoteRepo
  // ===========================================================================

  group('VoiceNoteRepo', () {
    late VoiceNoteRepo repo;

    VoiceNote build({
      required String id,
      int duration = 23,
      VoiceNoteAttachment attachment = VoiceNoteAttachment.sku,
      String refId = 'sku_01',
    }) =>
        VoiceNote(
          voiceNoteId: id,
          shopId: shopId,
          authorUid: 'google_sunil',
          authorRole: VoiceNoteAuthorRole.bhaiya,
          durationSeconds: duration,
          audioStorageRef: 'shops/$shopId/voice_notes/$id.m4a',
          audioSizeBytes: 187000,
          attachmentType: attachment,
          attachmentRefId: refId,
          recordedAt: DateTime.parse('2026-04-11T00:00:00Z'),
        );

    setUp(() {
      repo = VoiceNoteRepo(
        firestore: firestore,
        shopIdProvider: shopIdProvider,
      );
    });

    test('create + getById round-trips', () async {
      await repo.create(build(id: 'vn_01'));
      final fetched = await repo.getById('vn_01');

      expect(fetched, isNotNull);
      expect(fetched!.durationSeconds, equals(23));
      expect(fetched.authorRole, equals(VoiceNoteAuthorRole.bhaiya));
      expect(fetched.attachmentType, equals(VoiceNoteAttachment.sku));
    });

    test('create rejects duration below 5 seconds (PRD B1.6 AC #2)', () async {
      await expectLater(
        repo.create(build(id: 'vn_short', duration: 3)),
        throwsA(
          isA<VoiceNoteRepoException>().having(
            (e) => e.code,
            'code',
            'invalid-duration',
          ),
        ),
      );
    });

    test('create rejects duration above 60 seconds (PRD B1.6 AC #2)', () async {
      await expectLater(
        repo.create(build(id: 'vn_long', duration: 61)),
        throwsA(
          isA<VoiceNoteRepoException>().having(
            (e) => e.code,
            'code',
            'invalid-duration',
          ),
        ),
      );
    });

    test('boundary durations 5 and 60 are accepted', () async {
      await repo.create(build(id: 'vn_min', duration: 5));
      await repo.create(build(id: 'vn_max', duration: 60));

      expect(await repo.getById('vn_min'), isNotNull);
      expect(await repo.getById('vn_max'), isNotNull);
    });

    test('listByAttachment returns only matching voice notes', () async {
      await repo.create(build(
        id: 'vn_sku_a',
        attachment: VoiceNoteAttachment.sku,
        refId: 'sku_wanted',
      ));
      await repo.create(build(
        id: 'vn_sku_b',
        attachment: VoiceNoteAttachment.sku,
        refId: 'sku_other',
      ));
      await repo.create(build(
        id: 'vn_landing',
        attachment: VoiceNoteAttachment.shopLanding,
        refId: 'shop_sunil',
      ));

      final notes = await repo.listByAttachment(
        attachmentType: VoiceNoteAttachment.sku,
        attachmentRefId: 'sku_wanted',
      );

      expect(notes, hasLength(1));
      expect(notes.first.voiceNoteId, equals('vn_sku_a'));
    });

    test('getByIds bulk read preserves input order', () async {
      await repo.create(build(id: 'vn_a'));
      await repo.create(build(id: 'vn_b'));
      await repo.create(build(id: 'vn_c'));

      final fetched = await repo.getByIds(<String>['vn_b', 'vn_a', 'vn_c']);
      expect(
        fetched.map((n) => n.voiceNoteId).toList(),
        equals(<String>['vn_b', 'vn_a', 'vn_c']),
      );
    });
  });
}
