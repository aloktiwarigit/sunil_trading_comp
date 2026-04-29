// =============================================================================
// CuratedShortlistRepo — /shops/{shopId}/curatedShortlists/{shortlistId}.
//
// Consumed by:
//   - PRD B1.4 (customer reads the 6 occasion shortlists)
//   - PRD B1.12 (shopkeeper one-tap curation UI)
//
// Per UX Spec v1.1 §4.3 + PRD B1.4 AC #2 the shortlists are finite (max
// 6 SKUs per shortlist) and the SKU order is shopkeeper-curated. This
// repo provides a `reorderSkus` method that writes the new order
// atomically so drag-to-reorder in B1.12 never leaves a half-applied
// state.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import '../models/curated_shortlist.dart';
import '../shop_id_provider.dart';

/// Normalized exceptions thrown by CuratedShortlistRepo.
class CuratedShortlistRepoException implements Exception {
  /// Wrap a code + message.
  const CuratedShortlistRepoException(this.code, this.message);

  /// Stable error code.
  final String code;

  /// Human-readable message.
  final String message;
  @override
  String toString() => 'CuratedShortlistRepoException($code): $message';
}

/// Repository for CuratedShortlist documents.
class CuratedShortlistRepo {
  /// Construct with Firestore + shopIdProvider.
  CuratedShortlistRepo({
    required FirebaseFirestore firestore,
    required ShopIdProvider shopIdProvider,
  })  : _firestore = firestore,
        _shopIdProvider = shopIdProvider;

  final FirebaseFirestore _firestore;
  final ShopIdProvider _shopIdProvider;
  static final Logger _log = Logger('CuratedShortlistRepo');

  /// Max SKUs per shortlist per UX Spec v1.1 §4.3. Enforced client-side
  /// as a defense-in-depth check above the security rule.
  static const int finiteCap = 6;

  CollectionReference<Map<String, dynamic>> _collection() => _firestore
      .collection('shops')
      .doc(_shopIdProvider.shopId)
      .collection('curatedShortlists');

  /// Fetch one shortlist by ID.
  Future<CuratedShortlist?> getById(String shortlistId) async {
    try {
      final snap = await _collection().doc(shortlistId).get();
      if (!snap.exists) return null;
      final raw = snap.data()!;
      return CuratedShortlist.fromJson(<String, dynamic>{
        ...raw,
        'shortlistId': shortlistId,
        'createdAt': _normalizeTimestamp(raw['createdAt']),
        'updatedAt': _normalizeTimestamp(raw['updatedAt']),
      });
    } on FirebaseException catch (e) {
      throw CuratedShortlistRepoException(
        e.code,
        'Failed to read shortlist $shortlistId: ${e.message ?? e.code}',
      );
    }
  }

  /// Stream one shortlist for real-time updates — used by B1.4 so the
  /// customer sees the shopkeeper's mid-session drag-to-reorder live.
  Stream<CuratedShortlist?> watchById(String shortlistId) =>
      _collection().doc(shortlistId).snapshots().map((snap) {
        if (!snap.exists) return null;
        final raw = snap.data()!;
        return CuratedShortlist.fromJson(<String, dynamic>{
          ...raw,
          'shortlistId': shortlistId,
          'createdAt': _normalizeTimestamp(raw['createdAt']),
          'updatedAt': _normalizeTimestamp(raw['updatedAt']),
        });
      });

  /// List every active shortlist for the current shop. Used by B1.12
  /// curation UI to render all 6 occasion tabs in one screen.
  /// **Read budget:** up to 6 reads (one per shortlist).
  Future<List<CuratedShortlist>> listAll() async {
    try {
      final snap = await _collection().where('isActive', isEqualTo: true).get();
      return snap.docs.map((doc) {
        final raw = doc.data();
        return CuratedShortlist.fromJson(<String, dynamic>{
          ...raw,
          'shortlistId': doc.id,
          'createdAt': _normalizeTimestamp(raw['createdAt']),
          'updatedAt': _normalizeTimestamp(raw['updatedAt']),
        });
      }).toList();
    } on FirebaseException catch (e) {
      throw CuratedShortlistRepoException(
        e.code,
        'Failed to list shortlists: ${e.message ?? e.code}',
      );
    }
  }

  /// Create or fully replace a shortlist. Operator-only at rule layer.
  ///
  /// **Phase 1.9 code review cleanup (Agent B finding #3):** also rejects
  /// duplicate SKU IDs in the skuIdsInOrder array. A duplicate would render
  /// the same almirah twice in B1.4 which is a UX bug even if the drag-to-
  /// reorder UI in B1.12 happens to produce it. This is defense-in-depth
  /// above any UI-layer guard.
  ///
  /// **Phase 1.9 code review cleanup (Agent B finding #4 — design clarification):**
  /// this method does NOT validate that the referenced SKU IDs exist in the
  /// `inventory` collection. Dangling-ref handling is a B1.4-side concern per
  /// PRD B1.4 edge case #3: "SKU is removed from inventory but still in the
  /// shortlist: filter out at read time". The customer app resolves the
  /// shortlist → SKU list via InventorySkuRepo.getByIds then filters. The
  /// shopkeeper's curation intent is preserved even when a SKU is softly
  /// deleted after curation.
  Future<void> upsert(CuratedShortlist shortlist) async {
    if (shortlist.skuIdsInOrder.length > finiteCap) {
      throw CuratedShortlistRepoException(
        'finite-cap-exceeded',
        'CuratedShortlist.skuIdsInOrder exceeds finite cap of $finiteCap '
            'per UX Spec §4.3 — got ${shortlist.skuIdsInOrder.length}',
      );
    }
    if (shortlist.skuIdsInOrder.toSet().length !=
        shortlist.skuIdsInOrder.length) {
      throw const CuratedShortlistRepoException(
        'duplicate-sku-ids',
        'CuratedShortlist.skuIdsInOrder contains duplicate SKU IDs — '
            'the B1.4 shortlist would render the same almirah twice',
      );
    }
    try {
      await _collection().doc(shortlist.shortlistId).set(<String, dynamic>{
        ...shortlist.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _log.info(
        'shortlist upserted: id=${shortlist.shortlistId} '
        'skuCount=${shortlist.skuIdsInOrder.length}',
      );
    } on FirebaseException catch (e) {
      throw CuratedShortlistRepoException(
        e.code,
        'Failed to upsert shortlist ${shortlist.shortlistId}: '
        '${e.message ?? e.code}',
      );
    }
  }

  /// Atomic reorder of SKUs within a shortlist — used by B1.12 drag-to-
  /// reorder. Writes the new `skuIdsInOrder` array in a single set() so
  /// the customer-side watcher sees the reorder as one update, not as a
  /// partial add + delete sequence.
  ///
  /// **Phase 1.9 code review cleanup (Agent B finding #3):** also rejects
  /// duplicate SKU IDs. The B1.12 drag handler shouldn't produce duplicates
  /// under normal operation, but a misfiring handler (or a test that
  /// exercises the flow with bad data) could. Rejecting at the repo layer
  /// prevents a shortlist from ever rendering the same almirah twice.
  Future<void> reorderSkus(
    String shortlistId,
    List<String> newOrder,
  ) async {
    if (newOrder.length > finiteCap) {
      throw CuratedShortlistRepoException(
        'finite-cap-exceeded',
        'reorderSkus would exceed finite cap of $finiteCap — got ${newOrder.length}',
      );
    }
    if (newOrder.toSet().length != newOrder.length) {
      throw const CuratedShortlistRepoException(
        'duplicate-sku-ids',
        'reorderSkus received duplicate SKU IDs — the B1.4 shortlist '
            'would render the same almirah twice',
      );
    }
    try {
      await _collection().doc(shortlistId).set(
        <String, dynamic>{
          'skuIdsInOrder': newOrder,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      _log.info('shortlist reorder: id=$shortlistId count=${newOrder.length}');
    } on FirebaseException catch (e) {
      throw CuratedShortlistRepoException(
        e.code,
        'Failed to reorder shortlist $shortlistId: ${e.message ?? e.code}',
      );
    }
  }

  /// Normalize Firestore Timestamp → ISO8601.
  static Object? _normalizeTimestamp(Object? value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    return value;
  }
}
