// =============================================================================
// CustomerMemoryRepo — Firestore access for
//   /shops/{shopId}/customer_memory/{customerUid}.
//
// OPERATOR-ONLY writes. Customer must NEVER have read or write access.
// Per B1.11 AC #1 + S4.9 ACs.
//
// Write surface:
//   - getMemory(customerUid) — fetch existing memory doc (or null).
//   - watchMemory(customerUid) — real-time stream.
//   - upsertMemory(customerUid, fields) — create-or-update. Auto-save path
//     from S4.9 edit sheet calls this with debounced field changes.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import '../models/customer_memory.dart';
import '../shop_id_provider.dart';

/// Normalize Firestore Timestamp → ISO8601 for Freezed JSON parsing.
Object? _normalizeTimestamp(Object? value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate().toIso8601String();
  if (value is DateTime) return value.toIso8601String();
  return value;
}

/// Normalize timestamp fields in raw Firestore map for CustomerMemory.
Map<String, dynamic> _normalizeMemoryTimestamps(Map<String, dynamic> raw) {
  return <String, dynamic>{
    ...raw,
    'firstSeenAt': _normalizeTimestamp(raw['firstSeenAt']),
    'lastSeenAt': _normalizeTimestamp(raw['lastSeenAt']),
  };
}

class CustomerMemoryRepoException implements Exception {
  const CustomerMemoryRepoException(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => 'CustomerMemoryRepoException($code): $message';
}

class CustomerMemoryRepo {
  CustomerMemoryRepo({
    required FirebaseFirestore firestore,
    required ShopIdProvider shopIdProvider,
  })  : _firestore = firestore,
        _shopIdProvider = shopIdProvider;

  final FirebaseFirestore _firestore;
  final ShopIdProvider _shopIdProvider;
  static final Logger _log = Logger('CustomerMemoryRepo');

  CollectionReference<Map<String, dynamic>> _collection() => _firestore
      .collection('shops')
      .doc(_shopIdProvider.shopId)
      .collection('customer_memory');

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  Future<CustomerMemory?> getMemory(String customerUid) async {
    final snap = await _collection().doc(customerUid).get();
    if (!snap.exists) return null;
    return CustomerMemory.fromJson(<String, dynamic>{
      ..._normalizeMemoryTimestamps(snap.data()!),
      'customerUid': customerUid,
      'shopId': _shopIdProvider.shopId,
    });
  }

  Stream<CustomerMemory?> watchMemory(String customerUid) =>
      _collection().doc(customerUid).snapshots().map((snap) {
        if (!snap.exists) return null;
        return CustomerMemory.fromJson(<String, dynamic>{
          ..._normalizeMemoryTimestamps(snap.data()!),
          'customerUid': customerUid,
          'shopId': _shopIdProvider.shopId,
        });
      });

  // ---------------------------------------------------------------------------
  // Writes (operator-only)
  // ---------------------------------------------------------------------------

  /// Create or update the customer memory document. Uses merge semantics
  /// so partial updates (e.g., only notes changed) don't clobber other fields.
  ///
  /// Edge case #1 from S4.9: memory doc doesn't exist yet → created on first
  /// edit via set-with-merge.
  ///
  /// Edge case #2: two operators edit simultaneously → last write wins. This
  /// is acceptable per PRD ("rare; typically one operator handles
  /// relationships").
  Future<void> upsertMemory({
    required String customerUid,
    String? notes,
    String? relationshipNotes,
    List<PreferredOccasion>? preferredOccasions,
    int? preferredPriceMin,
    int? preferredPriceMax,
  }) async {
    final data = <String, Object?>{
      'shopId': _shopIdProvider.shopId,
      'customerUid': customerUid,
      'lastSeenAt': FieldValue.serverTimestamp(),
    };

    if (notes != null) data['notes'] = notes;
    if (relationshipNotes != null) {
      data['relationshipNotes'] = relationshipNotes;
    }
    if (preferredOccasions != null) {
      data['preferredOccasions'] =
          preferredOccasions.map((e) => e.name).toList();
    }
    // CR #2: always include price fields — use FieldValue.delete() to clear
    // when null, so previously-set values don't persist after the operator
    // clears the field.
    data['preferredPriceMin'] =
        preferredPriceMin ?? FieldValue.delete();
    data['preferredPriceMax'] =
        preferredPriceMax ?? FieldValue.delete();

    await _collection().doc(customerUid).set(
      data,
      SetOptions(merge: true),
    );
    _log.info('upsertMemory customerUid=$customerUid');
  }
}
