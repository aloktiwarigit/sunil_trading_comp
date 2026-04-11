// =============================================================================
// AuthProviderMsg91 — R8 fallback stub.
//
// If Firebase Phone Auth quota becomes unaffordable, flip Remote Config flag
// `auth_provider_strategy` to `msg91` and this implementation handles the
// phone OTP flow against MSG91's HTTP API at ~₹0.20/SMS.
//
// Anonymous + Google sign-in delegate to a wrapped AuthProviderFirebase
// because they don't carry SMS cost.
//
// PRD I6.1 AC #3 — this is one of the three required stubs.
//
// Status: SCAFFOLDING. Implementation is intentionally `UnimplementedError`
// until R8 actually fires. The interface contract is fully honored so the
// swap requires zero code changes — only a Remote Config flag flip.
// =============================================================================

import 'auth_provider.dart';
import 'auth_provider_firebase.dart';

/// MSG91 SMS-OTP fallback. Wraps a Firebase delegate for non-SMS flows.
///
/// Flip `auth_provider_strategy` Remote Config flag from `firebase` to `msg91`
/// when `firebasePhoneAuthQuotaMonitor` Cloud Function fires the 80% alert.
class AuthProviderMsg91 implements AuthProvider {
  AuthProviderMsg91({
    required AuthProviderFirebase firebaseDelegate,
    required this.msg91AuthKey,
  }) : _firebase = firebaseDelegate;

  final AuthProviderFirebase _firebase;

  /// MSG91 auth key — loaded from Remote Config secret OR env var, never
  /// hardcoded. Required for the `requestPhoneVerification` HTTP call.
  final String msg91AuthKey;

  @override
  Stream<AppUser?> get authStateChanges => _firebase.authStateChanges;

  @override
  AppUser? get currentUser => _firebase.currentUser;

  @override
  Future<AppUser> signInAnonymous() => _firebase.signInAnonymous();

  @override
  Future<PhoneVerificationResult> requestPhoneVerification(String phoneE164) {
    // TODO(R8-fallback): POST to https://control.msg91.com/api/v5/otp
    //   - body: {mobile: phoneE164.substring(1), authkey: msg91AuthKey, ...}
    //   - response carries verificationId we return below
    //   - cost ~₹0.20/SMS at MSG91 standard pricing
    throw UnimplementedError(
      'AuthProviderMsg91.requestPhoneVerification — stub. Activate when '
      'firebasePhoneAuthQuotaMonitor alerts at 80% of 10k SMS quota.',
    );
  }

  @override
  Future<AppUser> confirmPhoneVerification(
    String verificationId,
    String code,
  ) {
    // TODO(R8-fallback): POST to https://control.msg91.com/api/v5/otp/verify
    //   - on success, exchange MSG91 verification token for a custom Firebase
    //     auth token via a Cloud Function (msg91ToFirebaseToken)
    //   - sign in to Firebase with that custom token to preserve the rest of
    //     the architecture (security rules still see request.auth)
    //   - if anonymous → upgrade preserves UID via linkWithCredential
    throw UnimplementedError(
      'AuthProviderMsg91.confirmPhoneVerification — stub.',
    );
  }

  @override
  Future<AppUser> signInWithGoogle() => _firebase.signInWithGoogle();

  @override
  Future<void> signOut() => _firebase.signOut();
}
