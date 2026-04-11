// =============================================================================
// InventorySkuRepo — read + write access to /shops/{shopId}/inventory/{skuId}.
//
// Read is public-to-shop-members (customer + operator); write is
// operator-only at the rule layer. This repo provides both paths with
// the same ShopIdProvider-scoped pattern.
//
// Consumed by:
//   - PRD B1.4 (curated shortlist → resolves skuIdsInOrder to SKUs)
//   - PRD B1.5 (SKU detail read)
//   - PRD S4.3 (inventory create)
//   - PRD S4.4 (inventory edit — update price, stock, etc.)
//   - PRD S4.5 (Golden Hour photo attach — updates goldenHourPhotoIds)
//
// **Read-budget discipline per Standing Rule 1:** the repo exposes
// individual-SKU reads (1 read each), a finite-list read for one
// shortlist (up to 6 reads via whereIn), and NO unbounded browse query.
// The customer app never reaches directly for "all inventory" — that
// would blow the 30-reads-per-session budget on a big catalog.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import '../models/inventory_sku.dart';
import '../shop_id_provider.dart';

/// Normalized exceptions thrown by InventorySkuRepo.
class InventorySkuRepoException implements Exception {
  /// Wrap a code + message.
  const InventorySkuRepoException(this.code, this.message);
  /// Stable code.
  final String code;
  /// Human-readable message.
  final String message;
  @override
  String toString() => 'InventorySkuRepoException($code): $message';
}

/// Repository for InventorySku documents.
class InventorySkuRepo {
  /// Construct with Firestore + shopIdProvider.
  InventorySkuRepo({
    required FirebaseFirestore firestore,
    required ShopIdProvider shopIdProvider,
  })  : _firestore = firestore,
        _shopIdProvider = shopIdProvider;

  final FirebaseFirestore _firestore;
  final ShopIdProvider _shopIdProvider;
  static final Logger _log = Logger('InventorySkuRepo');

  CollectionReference<Map<String, dynamic>> _collection() =>
      _firestore
          .collection('shops')
          .doc(_shopIdProvider.shopId)
          .collection('inventory');

  /// Read one SKU by ID. 1 read against the session budget.
  Future<InventorySku?> getById(String skuId) async {
    try {
      final snap = await _collection().doc(skuId).get();
      if (!snap.exists) return null;
      final raw = snap.data()!;
      return InventorySku.fromJson(<String, dynamic>{
        ...raw,
        'skuId': skuId,
        'createdAt': _normalizeTimestamp(raw['createdAt']),
        'updatedAt': _normalizeTimestamp(raw['updatedAt']),
      });
    } on FirebaseException catch (e) {
      throw InventorySkuRepoException(
        e.code,
        'Failed to read SKU $skuId: ${e.message ?? e.code}',
      );
    }
  }

  /// Stream one SKU document. Used by B1.5 for real-time price /
  /// stock updates while the customer is on the detail screen.
  Stream<InventorySku?> watchById(String skuId) =>
      _collection().doc(skuId).snapshots().map((snap) {
        if (!snap.exists) return null;
        final raw = snap.data()!;
        return InventorySku.fromJson(<String, dynamic>{
          ...raw,
          'skuId': skuId,
          'createdAt': _normalizeTimestamp(raw['createdAt']),
          'updatedAt': _normalizeTimestamp(raw['updatedAt']),
        });
      });

  /// Bulk read by ID. Used by B1.4 to resolve a CuratedShortlist's
  /// skuIdsInOrder into actual SKU objects in one whereIn query (max
  /// 10 per Firestore `whereIn` limit — fits well within the 6-SKU cap).
  ///
  /// **Read budget:** N reads where N = skuIds.length (typically ≤6).
  Future<List<InventorySku>> getByIds(List<String> skuIds) async {
    if (skuIds.isEmpty) return const <InventorySku>[];
    if (skuIds.length > 10) {
      // Firestore whereIn is capped at 10. For shortlists this should
      // never happen (cap is 6), but if a future caller passes more,
      // split into multiple queries.
      throw const InventorySkuRepoException(
        'too-many-ids',
        'getByIds accepts at most 10 SKU IDs per call (Firestore whereIn limit)',
      );
    }
    try {
      final snap = await _collection()
          .where(FieldPath.documentId, whereIn: skuIds)
          .get();
      // Preserve the input order — Firestore returns whereIn results in
      // arbitrary order, but callers (B1.4) need the shopkeeper's
      // curated order.
      final byId = <String, InventorySku>{
        for (final doc in snap.docs)
          doc.id: InventorySku.fromJson(<String, dynamic>{
            ...doc.data(),
            'skuId': doc.id,
            'createdAt': _normalizeTimestamp(doc.data()['createdAt']),
            'updatedAt': _normalizeTimestamp(doc.data()['updatedAt']),
          }),
      };
      return skuIds
          .map((id) => byId[id])
          .whereType<InventorySku>()
          .toList(growable: false);
    } on FirebaseException catch (e) {
      throw InventorySkuRepoException(
        e.code,
        'Failed to read SKUs: ${e.message ?? e.code}',
      );
    }
  }

  /// Create or fully replace a SKU document. Write is operator-only at
  /// the rule layer; this repo surfaces rule rejections as
  /// `InventorySkuRepoException('permission-denied', ...)`.
  Future<void> upsert(InventorySku sku) async {
    try {
      await _collection().doc(sku.skuId).set(<String, dynamic>{
        ...sku.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _log.info('SKU upserted: skuId=${sku.skuId}');
    } on FirebaseException catch (e) {
      throw InventorySkuRepoException(
        e.code,
        'Failed to upsert SKU ${sku.skuId}: ${e.message ?? e.code}',
      );
    }
  }

  /// Soft-delete — marks `isActive: false`. Per PRD PQ-D v1 never
  /// hard-deletes SKUs (past Project line-items preserve price snapshots
  /// so deletion is safe anyway, but the soft-delete pattern keeps
  /// audit trails simple).
  Future<void> softDelete(String skuId) async {
    try {
      await _collection().doc(skuId).set(
        <String, dynamic>{
          'isActive': false,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      _log.info('SKU soft-deleted: skuId=$skuId');
    } on FirebaseException catch (e) {
      throw InventorySkuRepoException(
        e.code,
        'Failed to soft-delete SKU $skuId: ${e.message ?? e.code}',
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
