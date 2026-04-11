// =============================================================================
// AuthProviderEmailMagicLink — last-resort R8 fallback stub.
//
// If Firebase Auth itself becomes unavailable in India (regulatory or service
// change), this stub kicks in. Email is structurally weaker for this market
// but exists as the most disruptive of the three swap paths.
//
// PRD I6.1 AC #3 — this is one of the three required stubs.
//
// Status: SCAFFOLDING.
// =============================================================================

import 'auth_provider.dart';
import 'auth_provider_firebase.dart';

/// Email magic-link fallback. Held in reserve.
class AuthProviderEmailMagicLink implements AuthProvider {
  AuthProviderEmailMagicLink({
    required AuthProviderFirebase firebaseDelegate,
  }) : _firebase = firebaseDelegate;

  final AuthProviderFirebase _firebase;

  @override
  Stream<AppUser?> get authStateChanges => _firebase.authStateChanges;

  @override
  AppUser? get currentUser => _firebase.currentUser;

  @override
  Future<AppUser> signInAnonymous() => _firebase.signInAnonymous();

  /// Email path uses [requestEmailMagicLink] not [requestPhoneVerification].
  /// The phone path becomes a no-op — UI must skip the phone step entirely
  /// when this strategy is active.
  @override
  Future<PhoneVerificationResult> requestPhoneVerification(String phoneE164) {
    throw UnimplementedError(
      'AuthProviderEmailMagicLink does not support phone verification. '
      'UI must call requestEmailMagicLink(email) instead when this strategy '
      'is active. The customer journey switches to the email-link flow.',
    );
  }

  @override
  Future<AppUser> confirmPhoneVerification(
    String verificationId,
    String code,
  ) {
    throw UnimplementedError(
      'AuthProviderEmailMagicLink.confirmPhoneVerification — see '
      'requestPhoneVerification comment. UI must use the email path.',
    );
  }

  /// Parallel path exposed only on this implementation — UI checks for it
  /// via `runtimeType` when `auth_provider_strategy == 'email'`.
  Future<void> requestEmailMagicLink(String email) {
    // TODO(R8-last-resort): use FirebaseAuth.sendSignInLinkToEmail
    throw UnimplementedError('requestEmailMagicLink — stub');
  }

  @override
  Future<AppUser> signInWithGoogle() => _firebase.signInWithGoogle();

  @override
  Future<void> signOut() => _firebase.signOut();
}
