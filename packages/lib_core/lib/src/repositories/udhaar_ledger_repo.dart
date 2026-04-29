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

class UdhaarLedgerRepoException implements Exception {
  const UdhaarLedgerRepoException(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => 'UdhaarLedgerRepoException($code): $message';
}

class UdhaarLedgerRepo {
  UdhaarLedgerRepo({
    required FirebaseFirestore firestore,
    required ShopIdProvider shopIdProvider,
  })  : _firestore = firestore,
        _shopIdProvider = shopIdProvider;

  final FirebaseFirestore _firestore;
  final ShopIdProvider _shopIdProvider;
  static final Logger _log = Logger('UdhaarLedgerRepo');

  CollectionReference<Map<String, dynamic>> _collection() => _firestore
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

  Stream<List<UdhaarLedger>> watchByCustomer(String customerId) => _collection()
      .where('customerId', isEqualTo: customerId)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => UdhaarLedger.fromJson(<String, dynamic>{
                ...d.data(),
                'ledgerId': d.id,
              }))
          .toList());

  /// Create a new udhaar ledger entry. Operator-only. Links the ledger
  /// to the project by setting `Project.udhaarLedgerId` in the same
  /// Firestore transaction (C3.8 AC #5 + #6).
  Future<String> createLedger({
    required String projectId,
    required String customerId,
    required int recordedAmount,
    required int runningBalance,
  }) async {
    final ledgerRef = _collection().doc();
    final projectRef = _firestore
        .collection('shops')
        .doc(_shopIdProvider.shopId)
        .collection('projects')
        .doc(projectId);

    await _firestore.runTransaction((txn) async {
      final projectSnap = await txn.get(projectRef);
      if (!projectSnap.exists) {
        throw UdhaarLedgerRepoException(
          'project-not-found',
          'Project $projectId does not exist',
        );
      }

      // Create the ledger document.
      txn.set(ledgerRef, {
        'ledgerId': ledgerRef.id,
        'shopId': _shopIdProvider.shopId,
        'customerId': customerId,
        'recordedAmount': recordedAmount,
        'runningBalance': runningBalance,
        'partialPaymentReferences': <String>[],
        'reminderOptInByBhaiya': false,
        'reminderCountLifetime': 0,
        'reminderCadenceDays': 14,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Link to the project.
      txn.update(projectRef, {
        'udhaarLedgerId': ledgerRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    _log.info('udhaar ledger created: ${ledgerRef.id} for project=$projectId');
    return ledgerRef.id;
  }

  /// Record a partial payment. Decrements `runningBalance` atomically.
  /// If balance reaches 0, sets `closedAt`. (C3.9 AC #4 + #5)
  Future<void> recordPayment({
    required String ledgerId,
    required int amount,
    required String method,
    String? notes,
  }) async {
    final ref = _collection().doc(ledgerId);

    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) {
        throw UdhaarLedgerRepoException(
          'not-found',
          'Ledger $ledgerId does not exist',
        );
      }

      final data = snap.data()!;
      final currentBalance = (data['runningBalance'] as num?)?.toInt() ?? 0;

      // C3.9 Edge #1: reject overpayment.
      if (amount > currentBalance) {
        throw UdhaarLedgerRepoException(
          'overpayment',
          'Payment $amount exceeds balance $currentBalance',
        );
      }

      final newBalance = currentBalance - amount;
      final paymentId = _firestore.collection('_').doc().id;

      // Append payment reference.
      final refs =
          List<String>.from(data['partialPaymentReferences'] as List? ?? []);
      refs.add(paymentId);

      final update = <String, dynamic>{
        'runningBalance': newBalance,
        'partialPaymentReferences': refs,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // C3.9 AC #5: close ledger when balance reaches 0.
      if (newBalance == 0) {
        update['closedAt'] = FieldValue.serverTimestamp();
      }

      txn.update(ref, update);

      _log.info(
        'payment recorded: ledger=$ledgerId amount=$amount '
        'newBalance=$newBalance paymentId=$paymentId',
      );
    });
  }

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
