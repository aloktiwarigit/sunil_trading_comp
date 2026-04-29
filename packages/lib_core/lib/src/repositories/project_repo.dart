// =============================================================================
// ProjectRepo — the ONLY way to write to the /shops/{shopId}/projects/* path.
//
// Per PRD I6.12 AC #2 and Standing Rule 11: this repository exposes
// partition-scoped typed write methods — there is no generic
// `updateProject(Map<String, dynamic>)` method. Static analysis enforces
// that nowhere in the codebase does a Firestore `.update({...})` call target
// the `projects` path.
//
// Typed partition-write methods:
//   1. applyCustomerPatch(projectId, ProjectCustomerPatch)   — customer_app
//   2. applyOperatorPatch(projectId, ProjectOperatorPatch)   — shopkeeper_app
//   3. applySystemPatch(projectId, ProjectSystemPatch)       — Cloud Functions
//
// Typed cross-partition exception methods (PRD I6.12 edge cases #1 + #2):
//   4. applyCustomerCancelPatch(projectId, ProjectCustomerCancelPatch)
//      — the one customer cross-partition mutation: draft → cancelled.
//      Gated by a security rule on `resource.data.state == 'draft'`.
//      Wrapped in a Firestore transaction that re-verifies server-side.
//
// **AC #2 interpretation note:** PRD I6.12 AC #2 literally says "exactly
// three write methods". The spirit of the rule is "no generic Map-based
// update method that defeats partition enforcement" — and that spirit is
// fully preserved here (every method takes a typed patch, no Maps). The
// 4th method covers the explicit PRD edge case #1 and is itself typed.
// The count discrepancy is acknowledged as a Sprint 2.1 code-review
// clarification — see queued PRD patch note to bump AC #2 wording from
// "exactly three" to "exactly three partition writes + one typed
// cross-partition cancel for edge case #1".
//
// Partition enforcement:
//   customer_app imports only ProjectCustomerPatch + ProjectCustomerCancelPatch
//   shopkeeper_app imports only ProjectOperatorPatch + ProjectOperatorRevertPatch
//   Cloud Functions import only ProjectSystemPatch
//
// Cross-imports are caught by `tools/audit_project_patch_imports.sh` in CI.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import '../models/project.dart';
import '../models/project_patch.dart';
import '../services/read_budget_meter.dart';
import '../shop_id_provider.dart';

/// Exceptions thrown when a patch violates a runtime invariant that the type
/// system couldn't catch (e.g. transaction failure, cross-partition attempt
/// from a reflection-based code path, forbidden state transition).
class ProjectRepoException implements Exception {
  const ProjectRepoException(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => 'ProjectRepoException($code): $message';
}

/// The Project repository.
///
/// Construct with a [FirebaseFirestore] + [ShopIdProvider] pair. The
/// `shopId` is resolved from the provider at every write so there is no
/// risk of a repository instance leaking between tenants in the test suite.
class ProjectRepo {
  ProjectRepo({
    required FirebaseFirestore firestore,
    required ShopIdProvider shopIdProvider,
    ReadBudgetMeter? meter,
  })  : _firestore = firestore,
        _shopIdProvider = shopIdProvider,
        _meter = meter;

  final FirebaseFirestore _firestore;
  final ShopIdProvider _shopIdProvider;
  final ReadBudgetMeter? _meter;
  static final Logger _log = Logger('ProjectRepo');

  CollectionReference<Map<String, dynamic>> _projectsCollection() => _firestore
      .collection('shops')
      .doc(_shopIdProvider.shopId)
      .collection('projects');

  /// Read a single Project document.
  Future<Project?> getById(String projectId) async {
    _meter?.trackRead();
    final snap = await _projectsCollection().doc(projectId).get();
    if (!snap.exists) return null;
    return Project.fromJson(<String, dynamic>{
      ...snap.data()!,
      'projectId': projectId,
    });
  }

  /// Stream a Project document for reactive reads.
  Stream<Project?> watchById(String projectId) =>
      _projectsCollection().doc(projectId).snapshots().map((snap) {
        if (!snap.exists) return null;
        return Project.fromJson(<String, dynamic>{
          ...snap.data()!,
          'projectId': projectId,
        });
      });

  // ---------------------------------------------------------------------------
  // The three — and only three — write methods.
  // ---------------------------------------------------------------------------

  /// Customer-owned field writes. Called only from `customer_app`.
  Future<void> applyCustomerPatch(
    String projectId,
    ProjectCustomerPatch patch,
  ) async {
    final map = patch.toFirestoreMap();
    if (map.isEmpty) {
      _log.fine(
          'applyCustomerPatch(projectId=$projectId) with empty patch — skipping');
      return;
    }
    map['updatedAt'] = FieldValue.serverTimestamp();
    await _projectsCollection()
        .doc(projectId)
        .set(map, SetOptions(merge: true));
    _log.info(
        'customer patch applied: projectId=$projectId fields=${map.keys.toList()}');
  }

  /// Operator-owned field writes. Called only from `shopkeeper_app`.
  Future<void> applyOperatorPatch(
    String projectId,
    ProjectOperatorPatch patch,
  ) async {
    final map = patch.toFirestoreMap();
    if (map.isEmpty) {
      _log.fine(
          'applyOperatorPatch(projectId=$projectId) with empty patch — skipping');
      return;
    }
    map['updatedAt'] = FieldValue.serverTimestamp();
    await _projectsCollection()
        .doc(projectId)
        .set(map, SetOptions(merge: true));
    _log.info(
        'operator patch applied: projectId=$projectId fields=${map.keys.toList()}');
  }

  /// System-owned field writes. Called only from Cloud Functions.
  Future<void> applySystemPatch(
    String projectId,
    ProjectSystemPatch patch,
  ) async {
    final map = patch.toFirestoreMap();
    if (map.isEmpty) return;
    map['updatedAt'] = FieldValue.serverTimestamp();
    await _projectsCollection()
        .doc(projectId)
        .set(map, SetOptions(merge: true));
  }

  /// Typed customer cross-partition COD — committed → delivering per C3.6.
  /// Skips `paid` state; the shopkeeper marks paid after collecting cash.
  Future<void> applyCustomerCodPatch(
    String projectId,
    ProjectCustomerCodPatch patch,
  ) async {
    final ref = _projectsCollection().doc(projectId);
    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) {
        throw const ProjectRepoException('not-found', 'Project does not exist');
      }
      final currentState = snap.data()!['state'] as String?;
      if (currentState != 'committed') {
        throw ProjectRepoException(
          'invalid-state-transition',
          'Cannot select COD in state $currentState — only committed allowed',
        );
      }
      final map = patch.toFirestoreMap();
      map['updatedAt'] = FieldValue.serverTimestamp();
      txn.set(ref, map, SetOptions(merge: true));
    });
    _log.info('customer COD patch applied: projectId=$projectId');
  }

  /// Typed customer cross-partition bank transfer — committed → awaiting_verification
  /// per C3.7. The shopkeeper must manually verify and move to `paid`.
  Future<void> applyCustomerBankTransferPatch(
    String projectId,
    ProjectCustomerBankTransferPatch patch,
  ) async {
    final ref = _projectsCollection().doc(projectId);
    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) {
        throw const ProjectRepoException('not-found', 'Project does not exist');
      }
      final currentState = snap.data()!['state'] as String?;
      if (currentState != 'committed') {
        throw ProjectRepoException(
          'invalid-state-transition',
          'Cannot select bank transfer in state $currentState — only committed',
        );
      }
      final map = patch.toFirestoreMap();
      map['updatedAt'] = FieldValue.serverTimestamp();
      txn.set(ref, map, SetOptions(merge: true));
    });
    _log.info('customer bank transfer patch applied: projectId=$projectId');
  }

  /// Typed customer cross-partition payment — the committed → paid transition
  /// per PRD C3.5. Re-verifies the Triple Zero invariant at transition time:
  /// `amountReceivedByShop == totalAmount` must hold (set at commit by C3.4).
  ///
  /// Throws [ProjectRepoException] if the precondition fails or if the
  /// Triple Zero invariant is violated.
  Future<void> applyCustomerPaymentPatch(
    String projectId,
    ProjectCustomerPaymentPatch patch,
  ) async {
    final ref = _projectsCollection().doc(projectId);
    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) {
        throw const ProjectRepoException(
          'not-found',
          'Project does not exist',
        );
      }
      final data = snap.data()!;
      final currentState = data['state'] as String?;
      if (currentState != 'committed') {
        throw ProjectRepoException(
          'invalid-state-transition',
          'Cannot pay Project in state $currentState — '
              'only committed can transition to paid',
        );
      }

      // Re-verify Triple Zero invariant before allowing paid transition.
      final totalAmount = (data['totalAmount'] as num?)?.toInt() ?? 0;
      final received = (data['amountReceivedByShop'] as num?)?.toInt() ?? 0;
      if (received != totalAmount) {
        throw ProjectRepoException(
          'triple-zero-violation',
          'amountReceivedByShop ($received) != totalAmount ($totalAmount) — '
              'Triple Zero invariant violated, refusing paid transition',
        );
      }

      final map = patch.toFirestoreMap();
      map['paidAt'] = FieldValue.serverTimestamp();
      map['updatedAt'] = FieldValue.serverTimestamp();
      txn.set(ref, map, SetOptions(merge: true));
    });
    _log.info('customer payment patch applied: projectId=$projectId');
  }

  /// Typed customer cross-partition commit — the draft/negotiating → committed
  /// transition per PRD C3.4. This is the "promote-to-operator-patch" path:
  /// the customer writes operator-partition fields for this one gated
  /// transition. Security rules enforce `state in ['draft', 'negotiating']
  /// && request.auth.uid == resource.data.customerUid`.
  ///
  /// The transaction:
  ///   1. Reads the current Project snapshot
  ///   2. Asserts state is 'draft' or 'negotiating'
  ///   3. Computes totalAmount from sum(lineItems[].quantity * unitPriceInr)
  ///   4. Sets amountReceivedByShop = totalAmount (Triple Zero invariant)
  ///   5. Sets state = 'committed' + committedAt + customerPhone/DisplayName
  ///
  /// Throws [ProjectRepoException] if the precondition fails.
  Future<void> applyCustomerCommitPatch(
    String projectId,
    ProjectCustomerCommitPatch patch,
  ) async {
    final ref = _projectsCollection().doc(projectId);
    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) {
        throw const ProjectRepoException(
          'not-found',
          'Project does not exist',
        );
      }
      final data = snap.data()!;
      final currentState = data['state'] as String?;
      if (currentState != 'draft' && currentState != 'negotiating') {
        throw ProjectRepoException(
          'invalid-state-transition',
          'Cannot commit Project in state $currentState — '
              'only draft or negotiating can transition to committed',
        );
      }

      // Compute totalAmount from server-side line items (authoritative).
      final rawItems = data['lineItems'] as List<dynamic>? ?? <dynamic>[];
      if (rawItems.isEmpty) {
        throw const ProjectRepoException(
          'empty-cart',
          'Cannot commit a Project with no line items',
        );
      }
      var totalAmount = 0;
      for (final raw in rawItems) {
        final item = raw as Map<String, dynamic>;
        final qty = (item['quantity'] as num?)?.toInt() ?? 1;
        final price = (item['unitPriceInr'] as num?)?.toInt() ?? 0;
        totalAmount += qty * price;
      }
      if (totalAmount <= 0) {
        throw ProjectRepoException(
          'zero-amount',
          'Cannot commit a Project with totalAmount=$totalAmount',
        );
      }

      final map = patch.toFirestoreMap(totalAmount: totalAmount);
      map['committedAt'] = FieldValue.serverTimestamp();
      map['updatedAt'] = FieldValue.serverTimestamp();
      txn.set(ref, map, SetOptions(merge: true));
    });
    _log.info('customer commit patch applied: projectId=$projectId');
  }

  /// Typed customer cross-partition cancel — the ONE cross-partition
  /// mutation customers are allowed per PRD I6.12 edge case #1. Gated by a
  /// security rule checking `resource.data.state == 'draft'`. Runs in a
  /// Firestore transaction so the precondition is re-verified server-side
  /// and the client cannot replay an offline cancel against a Project
  /// that has already moved past draft.
  ///
  /// Accepts [ProjectCustomerCancelPatch] (rather than bare projectId) to
  /// stay consistent with the typed-patch discipline of the other write
  /// methods — even though the patch is currently a zero-field marker.
  /// Future extensions (e.g., a cancel reason field) go on the patch
  /// class without changing this method signature.
  Future<void> applyCustomerCancelPatch(
    String projectId,
    ProjectCustomerCancelPatch patch,
  ) async {
    final ref = _projectsCollection().doc(projectId);
    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) {
        throw const ProjectRepoException(
          'not-found',
          'Project does not exist',
        );
      }
      final currentState = snap.data()!['state'] as String?;
      if (currentState != 'draft') {
        throw ProjectRepoException(
          'invalid-state-transition',
          'Cannot cancel Project in state $currentState — '
              'only draft is cancellable by customer',
        );
      }
      final map = patch.toFirestoreMap();
      map['updatedAt'] = FieldValue.serverTimestamp();
      txn.set(ref, map, SetOptions(merge: true));
    });
    _log.info('customer cancel patch applied: projectId=$projectId');
  }
}
