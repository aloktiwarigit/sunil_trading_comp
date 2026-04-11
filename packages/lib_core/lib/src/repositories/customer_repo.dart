// =============================================================================
// CustomerRepo — Firestore access for /shops/{shopId}/customers/{customerId}.
//
// Sprint 2.1 scope: the minimum write surface needed by the phone-upgrade
// coordinator (I6.2). Full customer-owned / operator-owned partition
// discipline consistent with Standing Rule 11 lands in Sprint 4 when
// customer-written fields (occasion, preferences) start appearing.
//
// For Sprint 2, this repo exposes only the system-owned writes that the
// upgrade flow needs:
//   - createAnonymous(uid) — first-time anonymous customer doc creation
//   - markPhoneVerified(uid, phoneE164) — upgrade stamp per PRD I6.2 AC #3
//   - markForCleanup(uid) — orphan marker for PRD I6.2 AC #4 collision path
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import '../models/customer.dart';
import '../shop_id_provider.dart';

class CustomerRepoException implements Exception {
  const CustomerRepoException(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => 'CustomerRepoException($code): $message';
}

class CustomerRepo {
  CustomerRepo({
    required FirebaseFirestore firestore,
    required ShopIdProvider shopIdProvider,
  })  : _firestore = firestore,
        _shopIdProvider = shopIdProvider;

  final FirebaseFirestore _firestore;
  final ShopIdProvider _shopIdProvider;
  static final Logger _log = Logger('CustomerRepo');

  CollectionReference<Map<String, dynamic>> _collection() => _firestore
      .collection('shops')
      .doc(_shopIdProvider.shopId)
      .collection('customers');

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  Future<Customer?> getByUid(String uid) async {
    final snap = await _collection().doc(uid).get();
    if (!snap.exists) return null;
    return Customer.fromJson(<String, dynamic>{
      ...snap.data()!,
      'customerId': uid,
    });
  }

  Stream<Customer?> watchByUid(String uid) =>
      _collection().doc(uid).snapshots().map((snap) {
        if (!snap.exists) return null;
        return Customer.fromJson(<String, dynamic>{
          ...snap.data()!,
          'customerId': uid,
        });
      });

  // ---------------------------------------------------------------------------
  // System writes (upgrade flow only — not user-initiated)
  // ---------------------------------------------------------------------------

  /// Create a minimal customer document on first anonymous sign-in.
  ///
  /// Truly idempotent — wraps the write in a Firestore transaction that
  /// first checks if the document exists. If it exists, no write happens
  /// at all. If it doesn't exist, the fields below are written with
  /// server timestamp `createdAt`.
  ///
  /// **Why a transaction:** a naive `set(..., merge: true)` with
  /// `FieldValue.serverTimestamp()` would overwrite `createdAt` on every
  /// retry because Firestore regenerates the timestamp on every merge
  /// regardless of field existence. This was flagged as finding B3 in
  /// the Sprint 2.1 code review.
  Future<void> createAnonymous(String uid) async {
    final ref = _collection().doc(uid);
    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (snap.exists) {
        // Already created — do nothing. createdAt is preserved verbatim.
        return;
      }
      txn.set(ref, <String, Object?>{
        'customerId': uid,
        'shopId': _shopIdProvider.shopId,
        'isPhoneVerified': false,
        'previousProjectIds': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
    _log.info('createAnonymous uid=$uid');
  }

  /// Mark a customer as phone-verified with E.164 phone number.
  ///
  /// Called by PhoneUpgradeCoordinator after a successful
  /// `linkWithCredential` on the Firebase Auth side per PRD I6.2 AC #3.
  /// Uses server timestamp for `phoneVerifiedAt` so the value is
  /// authoritative regardless of clock skew.
  Future<void> markPhoneVerified(String uid, String phoneE164) async {
    await _collection().doc(uid).set(
      <String, Object?>{
        'isPhoneVerified': true,
        'phoneNumber': phoneE164,
        'phoneVerifiedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    _log.info('markPhoneVerified uid=$uid phone=$phoneE164');
  }

  /// Mark an anonymous customer document as orphaned after a phone-upgrade
  /// collision. The `cleanupAfter` timestamp is written so a periodic
  /// Cloud Function sweep can hard-delete it after a safe retention window.
  ///
  /// Per PRD I6.2 AC #4: when `linkWithCredential` fails with
  /// `credential-already-in-use`, the caller signs into the existing
  /// phone-verified UID, migrates state via a one-shot Cloud Function,
  /// and calls this method on the orphaned anonymous UID.
  Future<void> markForCleanup(String uid) async {
    await _collection().doc(uid).set(
      <String, Object?>{
        'isAbandoned': true,
        'abandonedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    _log.info('markForCleanup uid=$uid');
  }
}
