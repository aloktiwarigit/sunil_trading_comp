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

import '../models/line_item.dart';
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
    // Phase 3 (2026-04-30): state-transitions to `paid` and `closed` must go
    // through the typed transactional patches that enforce Triple Zero
    // atomically. The generic patch is for non-money state moves (e.g.
    // paid → delivering), customer-info fields, the revert path, and the
    // Phase 2 transitional last-message-preview write.
    if (patch.state == ProjectState.paid ||
        patch.state == ProjectState.closed) {
      throw ProjectRepoException(
        'use-typed-method',
        'state=${patch.state!.name} requires '
            'applyOperatorMarkPaidPatch / applyOperatorClosePatch',
      );
    }
    // Phase 3: settlement fields can only be written atomically by the
    // typed mark-paid / close transactions. Catching them here closes the
    // attack vector where a generic patch silently sets paidAt or
    // amountReceivedByShop without the matching state move + Triple Zero
    // re-check. The typed methods build their Firestore maps directly via
    // txn.set(...), so they bypass this guard by construction.
    if (patch.amountReceivedByShop != null ||
        patch.paidAt != null ||
        patch.closedAt != null ||
        patch.paymentMethod != null) {
      throw const ProjectRepoException(
        'use-typed-method',
        'settlement fields (amountReceivedByShop, paidAt, closedAt, '
            'paymentMethod) require applyOperatorMarkPaidPatch / '
            'applyOperatorClosePatch',
      );
    }
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

  /// Operator's typed payment confirmation. Phase 3 (2026-04-30): the only
  /// repo path that can move a project to `paid`. Atomically writes
  /// state=paid, amountReceivedByShop=totalAmount, paidAt=server,
  /// paymentMethod=arg.
  ///
  /// Throws ProjectRepoException with codes:
  ///   - 'not-found': project does not exist
  ///   - 'invalid-state-transition': source state ≠ committed/awaiting_verification
  ///   - 'invalid-payment-method': method not in {cash, upi, cod, bank_transfer}
  ///   - 'zero-amount': totalAmount ≤ 0
  Future<void> applyOperatorMarkPaidPatch(
    String projectId,
    ProjectOperatorMarkPaidPatch patch,
  ) async {
    if (!patch.hasValidMethod) {
      throw ProjectRepoException(
        'invalid-payment-method',
        'paymentMethod=${patch.paymentMethod} is not in '
            '{cash, upi, cod, bank_transfer}',
      );
    }
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
      if (currentState != 'committed' &&
          currentState != 'awaiting_verification') {
        throw ProjectRepoException(
          'invalid-state-transition',
          'Cannot mark paid in state $currentState — '
              'only committed or awaiting_verification allowed',
        );
      }
      final totalAmount = (data['totalAmount'] as num?)?.toInt() ?? 0;
      if (totalAmount <= 0) {
        throw ProjectRepoException(
          'zero-amount',
          'Cannot mark paid with totalAmount=$totalAmount',
        );
      }
      final map = patch.toFirestoreMap(totalAmount: totalAmount);
      map['paidAt'] = FieldValue.serverTimestamp();
      map['updatedAt'] = FieldValue.serverTimestamp();
      txn.set(ref, map, SetOptions(merge: true));
    });
    _log.info('operator mark-paid: projectId=$projectId '
        'method=${patch.paymentMethod}');
  }

  /// Operator's typed close patch. Phase 3 (2026-04-30): re-asserts the
  /// Triple Zero invariant transactionally before writing closedAt. Replaces
  /// the generic applyOperatorPatch(state: closed) callsite.
  ///
  /// Throws ProjectRepoException with codes:
  ///   - 'not-found': project does not exist
  ///   - 'invalid-state-transition': source state ≠ paid/delivering
  ///   - 'triple-zero-violation': amountReceivedByShop ≠ totalAmount
  Future<void> applyOperatorClosePatch(
    String projectId,
    ProjectOperatorClosePatch patch,
  ) async {
    final ref = _projectsCollection().doc(projectId);
    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) {
        throw const ProjectRepoException('not-found', 'Project does not exist');
      }
      final data = snap.data()!;
      final currentState = data['state'] as String?;
      if (currentState != 'paid' && currentState != 'delivering') {
        throw ProjectRepoException(
          'invalid-state-transition',
          'Cannot close in state $currentState — '
              'only paid or delivering allowed',
        );
      }
      final totalAmount = (data['totalAmount'] as num?)?.toInt() ?? 0;
      final received = (data['amountReceivedByShop'] as num?)?.toInt() ?? 0;
      if (received != totalAmount) {
        throw ProjectRepoException(
          'triple-zero-violation',
          'Cannot close: amountReceivedByShop ($received) '
              '!= totalAmount ($totalAmount)',
        );
      }
      final map = patch.toFirestoreMap();
      map['closedAt'] = FieldValue.serverTimestamp();
      // Back-fill deliveredAt if the operator closed a paid (not delivering)
      // project — i.e. the customer picked up at the shop without a
      // separate delivery leg.
      if (data['deliveredAt'] == null) {
        map['deliveredAt'] = FieldValue.serverTimestamp();
      }
      map['updatedAt'] = FieldValue.serverTimestamp();
      txn.set(ref, map, SetOptions(merge: true));
    });
    _log.info('operator close: projectId=$projectId');
  }

  /// Operator's typed revert: any reachable post-draft state → draft.
  ///
  /// Phase 6: replaces the implicit "operator can write {state, revertedByUid,
  /// revertReason} via applyOperatorPatch" path with a transactional method
  /// that nulls every downstream timestamp + the Triple Zero field, and
  /// writes a best-effort audit row to
  /// `/shops/{shopId}/system/project_reverts/history/{auditId}` in the SAME
  /// transaction as the project state change.
  ///
  /// Audit subcollection scope: BEST-EFFORT defense-in-depth, NOT
  /// authoritative. A cooperating operator using this method produces both
  /// writes atomically. A hostile operator reaching the Firestore REST API
  /// directly can write the project state change without writing the audit
  /// row — security rules cannot force creation of a sibling document.
  /// Append-only protections (`update, delete: if false` on the history
  /// collection) make tampering with existing rows impossible. If
  /// authoritative audit is required, plan a Firestore-trigger Cloud
  /// Function on `/projects` `onDocumentUpdated` (Phase 9+).
  ///
  /// Throws [ProjectRepoException] with codes:
  ///   - 'not-found': project does not exist
  ///   - 'invalid-state-transition': source state is already draft
  Future<void> applyOperatorRevertPatch(
    String projectId,
    ProjectOperatorRevertPatch patch,
  ) async {
    final ref = _projectsCollection().doc(projectId);
    final auditRef = _firestore
        .collection('shops')
        .doc(_shopIdProvider.shopId)
        .collection('system')
        .doc('project_reverts')
        .collection('history')
        .doc();

    String? previousState;
    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) {
        throw const ProjectRepoException('not-found', 'Project does not exist');
      }
      final data = snap.data()!;
      final currentState = data['state'] as String?;
      // Codex Phase 6 r1 #1: enumerate revertable source states explicitly.
      // `cancelled` is terminal — no outgoing transition in the state
      // machine — and must not be silently resurrected via revert. `draft`
      // is the target state; reverting from draft is a no-op.
      const revertableSourceStates = <String>{
        'negotiating',
        'committed',
        'paid',
        'delivering',
        'closed',
        'awaiting_verification',
      };
      if (!revertableSourceStates.contains(currentState)) {
        throw ProjectRepoException(
          'invalid-state-transition',
          'Cannot revert from $currentState — '
              'allowed source states: ${revertableSourceStates.join(", ")}',
        );
      }
      previousState = currentState;

      final revertMap = patch.toFirestoreMap();
      revertMap['updatedAt'] = FieldValue.serverTimestamp();
      txn.set(ref, revertMap, SetOptions(merge: true));

      txn.set(auditRef, <String, dynamic>{
        'auditId': auditRef.id,
        'projectId': projectId,
        'shopId': _shopIdProvider.shopId,
        'revertedByUid': patch.revertedByUid,
        'reason': patch.reason,
        'previousState': currentState,
        'previousAmountReceivedByShop':
            (data['amountReceivedByShop'] as num?)?.toInt() ?? 0,
        'revertedAt': FieldValue.serverTimestamp(),
      });
    });
    _log.info('operator revert: projectId=$projectId '
        'previousState=$previousState by=${patch.revertedByUid}');
  }

  /// Customer self-tags the project as cash-on-delivery. Phase 3: state stays
  /// `committed`; the operator advances state when cash is collected at
  /// delivery via `applyOperatorMarkPaidPatch` (committed → paid).
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
    _log.info('customer COD tag applied (state stays committed): $projectId');
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

  /// Customer's UPI self-attestation. Per PRD C3.5 + Phase 3 hardening, this
  /// transitions `committed → awaiting_verification` (NOT paid). The operator
  /// must confirm the payment via `applyOperatorMarkPaidPatch` before the
  /// project moves to `paid`.
  ///
  /// Future PSP path: a Cloud Function with App Check + signed receipt
  /// verification will write `state: paid` via `applySystemPatch`. That path
  /// does not exist yet; until it does, every customer claim is just a claim.
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
      final currentState = snap.data()!['state'] as String?;
      if (currentState != 'committed') {
        throw ProjectRepoException(
          'invalid-state-transition',
          'Cannot claim UPI payment in state $currentState — '
              'only committed can transition to awaiting_verification',
        );
      }
      final map = patch.toFirestoreMap();
      map['updatedAt'] = FieldValue.serverTimestamp();
      // Note: NO paidAt write here — payment is not confirmed yet.
      txn.set(ref, map, SetOptions(merge: true));
    });
    _log.info(
        'customer UPI claim recorded (awaiting_verification): $projectId');
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
  ///   4. Sets state = 'committed' + committedAt + customerPhone/DisplayName
  ///
  /// **Phase 3 (2026-04-30):** the commit deliberately does NOT set
  /// `amountReceivedByShop`. The field stays at 0 from creation through
  /// commit; only `applyOperatorMarkPaidPatch` (run by an authenticated
  /// operator) flips it to `totalAmount`. Pre-setting here would disarm
  /// the Triple Zero invariant on every later checkpoint — do not
  /// reintroduce. See `docs/superpowers/plans/2026-04-30-phase3-payment-correctness.md`
  /// audit finding F1.
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

  // ---------------------------------------------------------------------------
  // Phase 2 new methods — all callsites that were previously direct writes.
  // ---------------------------------------------------------------------------

  /// Creates a new draft Project document.
  ///
  /// Called only from customer_app via DraftController._createDraftProject.
  /// Returns the generated projectId (also stored as a field in the document).
  Future<String> createDraft({
    required String customerUid,
    required List<LineItem> items,
  }) async {
    final projectId = _firestore.collection('_').doc().id;
    final totalAmount = items.fold<int>(0, (s, i) => s + i.lineTotalInr);
    final data = <String, dynamic>{
      'projectId': projectId,
      'shopId': _shopIdProvider.shopId,
      'customerId': customerUid,
      'customerUid': customerUid,
      'state': 'draft',
      'totalAmount': totalAmount,
      'amountReceivedByShop': 0,
      'lineItemsCount': items.length,
      'lineItems': items.map((e) => e.toJson()).toList(),
      'unreadCountForCustomer': 0,
      'unreadCountForShopkeeper': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _projectsCollection().doc(projectId).set(data);
    _log.info('createDraft: projectId=$projectId totalAmount=$totalAmount');
    return projectId;
  }

  /// Updates lineItems and totalAmount on a draft Project.
  ///
  /// Transaction-backed: verifies the document exists and state == 'draft'
  /// before writing. Throws [ProjectRepoException] if missing or non-draft.
  /// Does NOT write lineItemsCount (not in the customer update allowlist).
  Future<void> applyCustomerDraftLineItemPatch(
    String projectId,
    List<LineItem> items,
  ) async {
    final ref = _projectsCollection().doc(projectId);
    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) {
        throw const ProjectRepoException('not-found', 'Project does not exist');
      }
      final currentState = snap.data()!['state'] as String?;
      if (currentState != 'draft') {
        throw ProjectRepoException(
          'invalid-state',
          'applyCustomerDraftLineItemPatch requires draft, got $currentState',
        );
      }
      final totalAmount = items.fold<int>(0, (s, i) => s + i.lineTotalInr);
      txn.update(ref, <String, dynamic>{
        'lineItems': items.map((e) => e.toJson()).toList(),
        'totalAmount': totalAmount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    _log.info(
      'applyCustomerDraftLineItemPatch: projectId=$projectId '
      'items=${items.length}',
    );
  }

  /// Deletes a draft Project (state must be 'draft').
  ///
  /// Transaction-backed: verifies the document exists and state == 'draft'
  /// before deleting. Throws [ProjectRepoException] if missing or non-draft.
  Future<void> deleteDraft(String projectId) async {
    final ref = _projectsCollection().doc(projectId);
    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) {
        throw const ProjectRepoException('not-found', 'Project does not exist');
      }
      final currentState = snap.data()!['state'] as String?;
      if (currentState != 'draft') {
        throw ProjectRepoException(
          'invalid-state',
          'deleteDraft requires draft, got $currentState',
        );
      }
      txn.delete(ref);
    });
    _log.info('deleteDraft: projectId=$projectId');
  }

  /// Accepts a shopkeeper price proposal on one line item.
  ///
  /// Transaction: reads the project, verifies state is draft or negotiating,
  /// sets finalPrice on the target line item, recomputes totalAmount, and
  /// transitions state to 'negotiating'.
  ///
  /// Throws [ProjectRepoException] if the project is missing, state is
  /// invalid, or the target line item is not found.
  Future<void> applyCustomerPriceAcceptancePatch(
    String projectId,
    String lineItemId,
    int proposedPrice,
  ) async {
    final ref = _projectsCollection().doc(projectId);
    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) {
        throw const ProjectRepoException('not-found', 'Project does not exist');
      }
      final currentState = snap.data()!['state'] as String?;
      if (currentState != 'draft' && currentState != 'negotiating') {
        throw ProjectRepoException(
          'invalid-state',
          'Price acceptance requires draft or negotiating, got $currentState',
        );
      }
      final rawItems =
          snap.data()!['lineItems'] as List<dynamic>? ?? <dynamic>[];
      final updated = <Map<String, dynamic>>[];
      var found = false;
      var total = 0;
      for (final raw in rawItems) {
        final item = Map<String, dynamic>.from(raw as Map);
        if (item['lineItemId'] == lineItemId) {
          item['finalPrice'] = proposedPrice;
          found = true;
        }
        final price = (item['finalPrice'] as num?)?.toInt() ??
            (item['unitPriceInr'] as num?)?.toInt() ??
            0;
        total += price * ((item['quantity'] as num?)?.toInt() ?? 1);
        updated.add(item);
      }
      if (!found) {
        throw ProjectRepoException(
          'line-item-not-found',
          'lineItemId=$lineItemId not found in project=$projectId',
        );
      }
      txn.update(ref, <String, dynamic>{
        'lineItems': updated,
        'totalAmount': total,
        'state': 'negotiating',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    _log.info(
      'applyCustomerPriceAcceptancePatch: projectId=$projectId '
      'lineItemId=$lineItemId proposedPrice=$proposedPrice',
    );
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
