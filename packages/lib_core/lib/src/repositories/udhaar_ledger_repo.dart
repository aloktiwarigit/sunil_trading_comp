// =============================================================================
// UdhaarLedgerRepo — operator-write-only per ADR-010 + Standing Rule 11.
//
// Customers have read access only. There is no customer patch class and
// no customer write method here. Reminders are system-written by the
// `sendUdhaarReminder` Cloud Function (Fn 3), not by client code.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import '../models/udhaar_ledger.dart';
import '../models/udhaar_ledger_patch.dart';
import '../shop_id_provider.dart';

class UdhaarLedgerRepo {
  UdhaarLedgerRepo({
    required FirebaseFirestore firestore,
    required ShopIdProvider shopIdProvider,
  })  : _firestore = firestore,
        _shopIdProvider = shopIdProvider;

  final FirebaseFirestore _firestore;
  final ShopIdProvider _shopIdProvider;
  static final Logger _log = Logger('UdhaarLedgerRepo');

  CollectionReference<Map<String, dynamic>> _collection() =>
      _firestore
          .collection('shops')
          .doc(_shopIdProvider.shopId)
          .collection('udhaarLedger');

  Future<UdhaarLedger?> getById(String ledgerId) async {
    final snap = await _collection().doc(ledgerId).get();
    if (!snap.exists) return null;
    return UdhaarLedger.fromJson(<String, dynamic>{
      ...snap.data()!,
      'ledgerId': ledgerId,
    });
  }

  Stream<List<UdhaarLedger>> watchByCustomer(String customerId) =>
      _collection()
          .where('customerId', isEqualTo: customerId)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => UdhaarLedger.fromJson(<String, dynamic>{
                    ...d.data(),
                    'ledgerId': d.id,
                  }))
              .toList());

  /// Operator-only write path. Customers have no write access to this
  /// collection per ADR-010. The Firestore rule layer will reject any
  /// write attempt from a non-operator auth context regardless.
  Future<void> applyOperatorPatch(
    String ledgerId,
    UdhaarLedgerOperatorPatch patch,
  ) async {
    final map = patch.toFirestoreMap();
    if (map.isEmpty) return;
    await _collection().doc(ledgerId).set(map, SetOptions(merge: true));
    _log.info('operator patch applied: ledgerId=$ledgerId');
  }
}
