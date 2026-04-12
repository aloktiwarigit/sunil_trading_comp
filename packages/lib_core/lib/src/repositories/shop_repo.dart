// =============================================================================
// ShopRepo — Firestore access for /shops/{shopId}.
//
// The Shop document is the top-level tenant root. Unlike subcollection repos
// (ProjectRepo, CustomerRepo, etc.) this repo reads from the top-level
// `shops` collection directly — there is no ShopIdProvider scoping because
// the Shop document IS the tenant document.
//
// Sprint 2.1 scope: read-only surface for the session bootstrap flow and
// lifecycle-aware UI (ADR-013). Write methods are Cloud Function–owned
// (shopDeactivationSweep, Function 8) and are NOT exposed here.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import '../models/shop.dart';

class ShopRepoException implements Exception {
  const ShopRepoException(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => 'ShopRepoException($code): $message';
}

/// The Shop repository.
///
/// Construct with a [FirebaseFirestore] instance. No [ShopIdProvider] is
/// needed because the Shop document IS the tenant root — the caller passes
/// the `shopId` directly to each method.
class ShopRepo {
  ShopRepo({required FirebaseFirestore firestore}) : _firestore = firestore;

  final FirebaseFirestore _firestore;
  static final Logger _log = Logger('ShopRepo');

  CollectionReference<Map<String, dynamic>> _collection() =>
      _firestore.collection('shops');

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  /// Read a single shop document.
  Future<Shop?> getShop(String shopId) async {
    final snap = await _collection().doc(shopId).get();
    if (!snap.exists) return null;
    final raw = snap.data()!;
    return Shop.fromJson(<String, dynamic>{
      ...raw,
      'shopId': shopId,
      'createdAt': _normalizeTimestamp(raw['createdAt']),
      'activeFromDay': _normalizeTimestamp(raw['activeFromDay']),
      'shopLifecycleChangedAt':
          _normalizeTimestamp(raw['shopLifecycleChangedAt']),
      'dpdpRetentionUntil': _normalizeTimestamp(raw['dpdpRetentionUntil']),
    });
  }

  /// Watch a shop document in real-time.
  Stream<Shop?> watchShop(String shopId) =>
      _collection().doc(shopId).snapshots().map((snap) {
        if (!snap.exists) return null;
        final raw = snap.data()!;
        return Shop.fromJson(<String, dynamic>{
          ...raw,
          'shopId': shopId,
          'createdAt': _normalizeTimestamp(raw['createdAt']),
          'activeFromDay': _normalizeTimestamp(raw['activeFromDay']),
          'shopLifecycleChangedAt':
              _normalizeTimestamp(raw['shopLifecycleChangedAt']),
          'dpdpRetentionUntil':
              _normalizeTimestamp(raw['dpdpRetentionUntil']),
        });
      });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Normalize Firestore Timestamp → ISO8601.
  static Object? _normalizeTimestamp(Object? value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    return value;
  }
}
