// =============================================================================
// OperatorRepo — read + write access to /shops/{shopId}/operators/{uid}.
//
// Scoped by ShopIdProvider. Writes are bhaiya-only at the rule layer
// (firestore.rules enforces isOperatorOf + role check); this repo does
// NOT duplicate the rule check client-side — it lets the rule reject
// unauthorized writes with the normalized exception surface.
//
// Consumed by:
//   - PRD S4.1 (Shopkeeper Google sign-in — first-time Operator read)
//   - PRD S4.2 (Multi-operator role-based access — read/write by bhaiya)
//   - PRD S4.12 (Shop settings — operator list management)
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import '../models/operator.dart';
import '../shop_id_provider.dart';

/// Normalized exceptions thrown by OperatorRepo.
class OperatorRepoException implements Exception {
  /// Wrap a code + message for UI-layer routing.
  const OperatorRepoException(this.code, this.message);

  /// Stable code — matches FirebaseException codes where possible.
  final String code;

  /// Human-readable message.
  final String message;
  @override
  String toString() => 'OperatorRepoException($code): $message';
}

/// Repository for Operator documents.
class OperatorRepo {
  /// Construct with a Firestore instance + a ShopIdProvider that resolves
  /// the current tenant at call time.
  OperatorRepo({
    required FirebaseFirestore firestore,
    required ShopIdProvider shopIdProvider,
  })  : _firestore = firestore,
        _shopIdProvider = shopIdProvider;

  final FirebaseFirestore _firestore;
  final ShopIdProvider _shopIdProvider;
  static final Logger _log = Logger('OperatorRepo');

  CollectionReference<Map<String, dynamic>> _collection() => _firestore
      .collection('shops')
      .doc(_shopIdProvider.shopId)
      .collection('operators');

  /// Read one Operator by Google UID.
  Future<Operator?> getByUid(String uid) async {
    try {
      final snap = await _collection().doc(uid).get();
      if (!snap.exists) return null;
      return Operator.fromJson(<String, dynamic>{
        ...snap.data()!,
        'uid': uid,
        'joinedAt': _normalizeTimestamp(snap.data()!['joinedAt']),
        'lastActiveAt': _normalizeTimestamp(snap.data()!['lastActiveAt']),
      });
    } on FirebaseException catch (e) {
      throw OperatorRepoException(
        e.code,
        'Failed to read operator $uid: ${e.message ?? e.code}',
      );
    }
  }

  /// Stream one Operator doc. Used by the ops-app sign-in flow to
  /// reactively respond to role changes (e.g., bhaiya removes beta).
  Stream<Operator?> watchByUid(String uid) =>
      _collection().doc(uid).snapshots().map((snap) {
        if (!snap.exists) return null;
        final raw = snap.data()!;
        return Operator.fromJson(<String, dynamic>{
          ...raw,
          'uid': uid,
          'joinedAt': _normalizeTimestamp(raw['joinedAt']),
          'lastActiveAt': _normalizeTimestamp(raw['lastActiveAt']),
        });
      });

  /// List all operators for the current shop. Used by S4.12 Settings.
  /// Returns an unordered list — UI sorts by role + displayName as needed.
  Future<List<Operator>> listAll() async {
    try {
      final snap = await _collection().get();
      return snap.docs.map((doc) {
        final raw = doc.data();
        return Operator.fromJson(<String, dynamic>{
          ...raw,
          'uid': doc.id,
          'joinedAt': _normalizeTimestamp(raw['joinedAt']),
          'lastActiveAt': _normalizeTimestamp(raw['lastActiveAt']),
        });
      }).toList();
    } on FirebaseException catch (e) {
      throw OperatorRepoException(
        e.code,
        'Failed to list operators: ${e.message ?? e.code}',
      );
    }
  }

  /// Create a new Operator document. Called ONLY by the bhaiya via
  /// S4.12 Settings → "Add operator" flow, OR by the initial shop
  /// onboarding manual Operator creation per PRD PQ-C locked answer
  /// (Yugma Labs ops creates the first Operator doc).
  Future<void> create(Operator operator) async {
    try {
      await _collection().doc(operator.uid).set(<String, dynamic>{
        ...operator.toJson(),
        'joinedAt': FieldValue.serverTimestamp(),
      });
      _log.info(
        'operator created: uid=${operator.uid} role=${operator.role.name}',
      );
    } on FirebaseException catch (e) {
      throw OperatorRepoException(
        e.code,
        'Failed to create operator ${operator.uid}: ${e.message ?? e.code}',
      );
    }
  }

  /// Update the `lastActiveAt` timestamp for an operator. Called on every
  /// ops-app cold launch + periodically during active sessions to feed
  /// the S4.17 burnout telemetry (Brief R1 mitigation).
  Future<void> touchLastActive(String uid) async {
    try {
      await _collection().doc(uid).set(
        <String, dynamic>{'lastActiveAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    } on FirebaseException catch (e) {
      _log.warning(
        'touchLastActive failed for uid=$uid: ${e.code} ${e.message}',
      );
      // Swallow — telemetry failures must not block the sign-in flow.
    }
  }

  /// Normalize Firestore Timestamp → ISO8601 for Freezed JSON round-trip.
  static Object? _normalizeTimestamp(Object? value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    return value;
  }
}
