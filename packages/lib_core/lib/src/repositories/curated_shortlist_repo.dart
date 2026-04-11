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

  CollectionReference<Map<String, dynamic>> _collection() =>
      _firestore
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
  Future<void> upsert(CuratedShortlist shortlist) async {
    if (shortlist.skuIdsInOrder.length > finiteCap) {
      throw CuratedShortlistRepoException(
        'finite-cap-exceeded',
        'CuratedShortlist.skuIdsInOrder exceeds finite cap of $finiteCap '
        'per UX Spec §4.3 — got ${shortlist.skuIdsInOrder.length}',
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
