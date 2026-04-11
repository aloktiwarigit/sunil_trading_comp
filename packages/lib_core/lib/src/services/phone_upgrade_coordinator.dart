// =============================================================================
// PhoneUpgradeCoordinator — orchestrates the anonymous → phone upgrade flow.
//
// PRD I6.2 Walking Skeleton. SAD §4 Flow 1 (happy path) + SAD §4 Flow 4
// (credential-already-in-use collision merger).
//
// Architecture rationale: AuthProvider is a low-level adapter and must not
// depend on CustomerRepo or Cloud Function callers. This coordinator sits
// above both and is the single call site used by the Sprint 5 commit
// screen (C3.4). Keeping the orchestration here means the AuthProvider
// interface can be swapped (R8 mitigation) without touching the upgrade
// flow logic.
//
// Collision path (SAD §4 Flow 4):
//   1. anonymous user tries linkWithCredential with phone credential
//   2. Firebase returns credential-already-in-use (someone already
//      phone-verified that number with a different UID)
//   3. coordinator signs in to the existing UID via the credential
//   4. coordinator calls joinDecisionCircle (Cloud Function, SAD §7 Fn 6)
//      to migrate Decision Circle membership + Project drafts + chat
//      thread participation from sourceUid → destUid
//   5. coordinator marks the orphaned anonymous Customer doc for cleanup
//   6. coordinator returns the final (destUid) AppUser
//
// For Sprint 2, the Cloud Function call site is stubbed — the real
// joinDecisionCircle Cloud Function ships in Sprint 5-6 per the Cloud
// Functions inventory. The stub is injectable so the integration test
// can pass a fake implementation.
// =============================================================================

import 'package:logging/logging.dart';

import '../adapters/auth_provider.dart';
import '../observability/analytics_events.dart';
import '../repositories/customer_repo.dart';

/// Stub interface for the `joinDecisionCircle` Cloud Function (SAD §7 Fn 6).
/// Real HTTPS-callable implementation lands in Sprint 5–6 with C3.4.
///
/// The coordinator calls this when a collision merger needs to move state
/// from the abandoned anonymous UID to the existing phone-verified UID.
abstract class StateMigrationCaller {
  /// Request that server-side state attached to [sourceUid] be reassigned
  /// to [destUid]. For Sprint 2 this is a no-op stub implementation; for
  /// Sprint 5+ this issues an HTTPS callable to `joinDecisionCircle` which
  /// atomically rewrites Decision Circle memberships, ChatThread
  /// participants, and Project drafts.
  ///
  /// Throws if the call fails. The coordinator does NOT swallow failures —
  /// a partial migration leaves the user in a worse state than the
  /// original collision, so the caller must surface the error to the UI.
  Future<void> migrateState({
    required String sourceUid,
    required String destUid,
  });
}

/// Sprint 2 no-op stub. Replaced by a real HttpsCallable-backed impl in
/// Sprint 5–6 when joinDecisionCircle deploys to dev.
class NoopStateMigrationCaller implements StateMigrationCaller {
  const NoopStateMigrationCaller();

  static final Logger _log = Logger('NoopStateMigrationCaller');

  @override
  Future<void> migrateState({
    required String sourceUid,
    required String destUid,
  }) async {
    _log.warning(
      'NoopStateMigrationCaller.migrateState called — no real migration '
      'performed. sourceUid=$sourceUid destUid=$destUid. This is expected '
      'during Sprint 2–4; replace with real HttpsCallable in Sprint 5+.',
    );
  }
}

/// Result of a successful upgrade, surfacing which path was taken.
class PhoneUpgradeResult {
  const PhoneUpgradeResult({
    required this.user,
    required this.path,
    this.orphanedAnonymousUid,
  });

  /// The final signed-in user after the upgrade completes.
  final AppUser user;

  /// Which path the upgrade took — useful for analytics.
  final PhoneUpgradePath path;

  /// If [path] == [PhoneUpgradePath.collisionMerger], the UID of the
  /// anonymous session that was orphaned and marked for cleanup.
  final String? orphanedAnonymousUid;
}

enum PhoneUpgradePath {
  /// Clean linkWithCredential. Anonymous UID is preserved.
  /// SAD §4 Flow 1.
  happyPath,

  /// credential-already-in-use collision. Existing phone-verified UID
  /// signed into. Anonymous state migrated via Cloud Function. Orphan
  /// marked for cleanup. SAD §4 Flow 4.
  collisionMerger,
}

/// The coordinator itself.
class PhoneUpgradeCoordinator {
  PhoneUpgradeCoordinator({
    required AuthProvider authProvider,
    required CustomerRepo customerRepo,
    StateMigrationCaller? migrationCaller,
  })  : _authProvider = authProvider,
        _customerRepo = customerRepo,
        _migrationCaller = migrationCaller ?? const NoopStateMigrationCaller();

  final AuthProvider _authProvider;
  final CustomerRepo _customerRepo;
  final StateMigrationCaller _migrationCaller;
  static final Logger _log = Logger('PhoneUpgradeCoordinator');

  /// Upgrade the currently-signed-in anonymous user to phone-verified.
  ///
  /// Steps:
  ///   1. Confirm the phone OTP via AuthProvider. If the current session
  ///      is anonymous, AuthProviderFirebase calls `linkWithCredential`
  ///      internally so the UID is preserved (SAD §4 Flow 1).
  ///   2. On success (happy path): write `phoneVerifiedAt` + `phoneNumber`
  ///      to the Customer Firestore doc per PRD I6.2 AC #3.
  ///   3. On [AuthErrorCode.credentialAlreadyInUse]: run the merger logic
  ///      per SAD §4 Flow 4.
  ///
  /// Returns a [PhoneUpgradeResult] with the final user and the path taken.
  ///
  /// Throws [AuthException] for unrecoverable errors (invalid code, expired
  /// code, network). The caller (Sprint 5 commit screen) must surface those
  /// to the UI.
  Future<PhoneUpgradeResult> upgradeAnonymousToPhone({
    required String verificationId,
    required String otpCode,
    required String phoneE164,
  }) async {
    final sourceUser = _authProvider.currentUser;
    if (sourceUser == null) {
      throw const AuthException(
        AuthErrorCode.unknown,
        'upgradeAnonymousToPhone called with no signed-in user',
      );
    }
    if (!sourceUser.isAnonymous) {
      _log.warning(
        'upgradeAnonymousToPhone called on non-anonymous user uid=${sourceUser.uid} '
        '— this indicates a UI flow bug. Proceeding anyway (link will fail or be no-op).',
      );
    }

    final sourceUid = sourceUser.uid;

    try {
      // Happy path: linkWithCredential preserves the UID.
      final linkedUser = await _authProvider.confirmPhoneVerification(
        verificationId,
        otpCode,
      );

      // PRD I6.2 AC #3: write the upgrade stamp to the Customer doc.
      await _customerRepo.markPhoneVerified(linkedUser.uid, phoneE164);

      _log.info(
        'phone upgrade happy path: uid=${linkedUser.uid} phone=$phoneE164',
      );
      return PhoneUpgradeResult(
        user: linkedUser,
        path: PhoneUpgradePath.happyPath,
      );
    } on AuthException catch (e) {
      // Only one error code triggers the merger path.
      if (e.code != AuthErrorCode.credentialAlreadyInUse) {
        rethrow;
      }

      _log.info(
        'credential-already-in-use collision detected for uid=$sourceUid '
        '— running merger logic per SAD §4 Flow 4',
      );

      // SAD §4 Flow 4 Step 1: sign in to the existing phone-verified UID
      // via the same credential. The current anonymous session becomes the
      // "source" that needs migration; the newly-signed-in session is the
      // "destination" that will survive.
      //
      // NOTE: AuthProvider doesn't currently expose a "sign in with phone
      // credential without linking" method because Firebase's
      // signInWithCredential works identically regardless of whether an
      // anonymous user is currently signed in — it signs out the anonymous
      // user and signs in with the credential. So a second call to
      // confirmPhoneVerification with the same verificationId + code
      // achieves the sign-in, provided we first sign out of the anonymous
      // session. We DON'T sign out the anonymous session first because
      // that destroys the session we need to read sourceUid from.
      //
      // Instead, the AuthProviderFirebase implementation inspects
      // `_auth.currentUser` before calling signInWithCredential. When
      // called after a credential-already-in-use failure, the anonymous
      // user has already been detached from the credential by Firebase,
      // and signInWithCredential returns the existing phone-verified user.
      //
      // For Sprint 2, we reconfirm with the same verificationId+otp:
      final destUser = await _signInToExistingUid(verificationId, otpCode);

      // SAD §4 Flow 4 Step 2: migrate Decision Circle membership + Project
      // drafts + chat thread participation via the joinDecisionCircle
      // Cloud Function. For Sprint 2 this is a NoopStateMigrationCaller
      // that logs intent only; real migration lands in Sprint 5–6.
      await _migrationCaller.migrateState(
        sourceUid: sourceUid,
        destUid: destUser.uid,
      );

      // SAD §4 Flow 4 Step 3: write phone stamp to the destination
      // customer doc (may or may not already be set; merge is safe).
      await _customerRepo.markPhoneVerified(destUser.uid, phoneE164);

      // SAD §4 Flow 4 Step 4: mark the orphaned anonymous customer doc
      // for cleanup. A periodic Cloud Function sweep will hard-delete it
      // after the safe retention window.
      await _customerRepo.markForCleanup(sourceUid);

      _log.info(
        'phone upgrade collision merger complete: sourceUid=$sourceUid '
        'destUid=${destUser.uid} phone=$phoneE164',
      );

      return PhoneUpgradeResult(
        user: destUser,
        path: PhoneUpgradePath.collisionMerger,
        orphanedAnonymousUid: sourceUid,
      );
    }
  }

  /// Sprint 2 simplification: after a collision, re-confirm with the same
  /// credential. In Sprint 5 when the real commit screen exists, this path
  /// may be extended to regenerate a fresh OTP request if the original
  /// credential was consumed.
  Future<AppUser> _signInToExistingUid(
    String verificationId,
    String otpCode,
  ) async {
    // A second call to confirmPhoneVerification — the anonymous session
    // should already have been detached from the credential by Firebase's
    // initial failure, so this call does a plain signInWithCredential.
    return _authProvider.confirmPhoneVerification(verificationId, otpCode);
  }
}

/// Analytics event name for the upgrade path taken — wired by the caller
/// (Sprint 5 commit screen) via `Observability.analytics.logEvent`.
///
/// Note: these are not in [AnalyticsEvents] because they're sub-events of
/// `auth_phone_verified` which IS in the canonical set. The caller fires
/// the canonical event + this as a parameter.
class PhoneUpgradeAnalyticsParams {
  PhoneUpgradeAnalyticsParams._();

  static const String paramPath = 'upgrade_path';
  static const String valueHappyPath = 'happy';
  static const String valueCollisionMerger = 'collision';

  /// Convenience: build the params map for a given [PhoneUpgradeResult].
  static Map<String, Object> forResult(PhoneUpgradeResult result) {
    return <String, Object>{
      paramPath: switch (result.path) {
        PhoneUpgradePath.happyPath => valueHappyPath,
        PhoneUpgradePath.collisionMerger => valueCollisionMerger,
      },
      if (result.orphanedAnonymousUid != null)
        'orphaned_uid': result.orphanedAnonymousUid!,
    };
  }
}
