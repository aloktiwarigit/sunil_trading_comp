// =============================================================================
// AuthProviderUpiOnly — R12 fallback stub.
//
// If customers culturally reject OTP at commit (R12 — funnel drop-off > 30%),
// flip `auth_provider_strategy` to `upi_only`. The commit screen no longer
// asks for a phone number; payment proceeds directly via UPI intent, which
// captures the VPA on return. The VPA becomes the de-facto identity.
//
// PRD I6.1 AC #3 — this is one of the three required stubs.
//
// Status: SCAFFOLDING.
// =============================================================================

import 'auth_provider.dart';
import 'auth_provider_firebase.dart';

/// UPI-only verification fallback for R12. Phone verification becomes a no-op.
class AuthProviderUpiOnly implements AuthProvider {
  AuthProviderUpiOnly({
    required AuthProviderFirebase firebaseDelegate,
  }) : _firebase = firebaseDelegate;

  final AuthProviderFirebase _firebase;

  @override
  Stream<AppUser?> get authStateChanges => _firebase.authStateChanges;

  @override
  AppUser? get currentUser => _firebase.currentUser;

  @override
  Future<AppUser> signInAnonymous() => _firebase.signInAnonymous();

  /// Phone verification is a structural no-op in this strategy. UI must skip
  /// the OTP screen and proceed directly to UPI payment.
  @override
  Future<PhoneVerificationResult> requestPhoneVerification(String phoneE164) {
    throw UnimplementedError(
      'AuthProviderUpiOnly does not collect phone numbers at commit. '
      'UI must skip the OTP screen and proceed to UPI intent. The VPA '
      'returned by the payment is captured by the ops app (S4.2) and '
      'becomes the de-facto identity.',
    );
  }

  @override
  Future<AppUser> confirmPhoneVerification(
    String verificationId,
    String code,
  ) {
    throw UnimplementedError(
      'AuthProviderUpiOnly.confirmPhoneVerification — see '
      'requestPhoneVerification comment.',
    );
  }

  @override
  Future<AppUser> signInWithGoogle() => _firebase.signInWithGoogle();

  @override
  Future<void> signOut() => _firebase.signOut();
}
