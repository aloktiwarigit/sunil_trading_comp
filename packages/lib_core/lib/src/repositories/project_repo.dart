// =============================================================================
// ProjectRepo — the ONLY way to write to the /shops/{shopId}/projects/* path.
//
// Per PRD I6.12 AC #2 and Standing Rule 11: this repository exposes EXACTLY
// three write methods, one per partition. There is no generic
// `updateProject(Map<String, dynamic>)` method. Static analysis enforces
// that nowhere in the codebase does a Firestore `.update({...})` call target
// the `projects` path.
//
// Partition enforcement:
//   customer_app imports applyCustomerPatch only
//   shopkeeper_app imports applyOperatorPatch only
//   Cloud Functions import applySystemPatch only
//
// Cross-imports are caught by `tools/audit_project_patch_imports.sh` in CI.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import '../models/project.dart';
import '../models/project_patch.dart';
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
  })  : _firestore = firestore,
        _shopIdProvider = shopIdProvider;

  final FirebaseFirestore _firestore;
  final ShopIdProvider _shopIdProvider;
  static final Logger _log = Logger('ProjectRepo');

  CollectionReference<Map<String, dynamic>> _projectsCollection() =>
      _firestore
          .collection('shops')
          .doc(_shopIdProvider.shopId)
          .collection('projects');

  /// Read a single Project document.
  Future<Project?> getById(String projectId) async {
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
      _log.fine('applyCustomerPatch(projectId=$projectId) with empty patch — skipping');
      return;
    }
    map['updatedAt'] = FieldValue.serverTimestamp();
    await _projectsCollection()
        .doc(projectId)
        .set(map, SetOptions(merge: true));
    _log.info('customer patch applied: projectId=$projectId fields=${map.keys.toList()}');
  }

  /// Operator-owned field writes. Called only from `shopkeeper_app`.
  Future<void> applyOperatorPatch(
    String projectId,
    ProjectOperatorPatch patch,
  ) async {
    final map = patch.toFirestoreMap();
    if (map.isEmpty) {
      _log.fine('applyOperatorPatch(projectId=$projectId) with empty patch — skipping');
      return;
    }
    map['updatedAt'] = FieldValue.serverTimestamp();
    await _projectsCollection()
        .doc(projectId)
        .set(map, SetOptions(merge: true));
    _log.info('operator patch applied: projectId=$projectId fields=${map.keys.toList()}');
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

  /// Special-cased customer cancel — the ONE cross-partition mutation
  /// customers are allowed. Gated by a security rule checking
  /// `resource.data.state == 'draft'`. Runs in a transaction so the
  /// precondition is re-verified server-side.
  Future<void> cancelDraftAsCustomer(String projectId) async {
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
          'Cannot cancel Project in state $currentState — only draft is cancellable by customer',
        );
      }
      txn.set(
        ref,
        <String, Object?>{
          'state': 'cancelled',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
    _log.info('customer-cancel applied: projectId=$projectId');
  }
}
