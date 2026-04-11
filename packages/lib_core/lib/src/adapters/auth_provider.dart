// =============================================================================
// AuthProvider — The first of the Three Adapters (R8 mitigation per ADR-002).
//
// Wraps Firebase Auth (default) so the customer app and shopkeeper app can
// authenticate against any provider tomorrow without rewriting screens.
//
// See SAD §4 for the four flows that consume this interface.
// See PRD I6.1 for the acceptance criteria this implementation satisfies.
// =============================================================================

import 'package:meta/meta.dart';

/// Tier of authentication a user currently holds.
///
/// Drives screen routing decisions throughout both apps. The PRD's "Auth tier"
/// field on every story maps directly to one of these.
enum AuthTier {
  /// No Firebase user yet — pre-launch state. Should be transient.
  signedOut,

  /// Tier 0 — anonymous browse session. Always available.
  /// Maps to PRD `anonymous` auth-tier value.
  anonymous,

  /// Tier 1 — phone-verified. Required at the commit moment per C3.4.
  /// Maps to PRD `phoneVerified`.
  phoneVerified,

  /// Tier 2 — Google sign-in. Shopkeeper ops app only (S4.1).
  /// Maps to PRD `googleOperator`.
  googleOperator,
}

/// The authenticated user as seen by the lib_core layer.
///
/// Deliberately framework-neutral — does not expose `firebase_auth`'s
/// `User` class directly so that swapping the underlying provider
/// (MSG91, email, UPI-only) does not require touching call sites.
@immutable
class AppUser {
  const AppUser({
    required this.uid,
    required this.tier,
    required this.isAnonymous,
    required this.isPhoneVerified,
    this.phoneNumber,
    this.email,
    this.displayName,
    this.phoneVerifiedAt,
  });

  /// Stable Firebase UID. Survives the anonymous → phone-verified upgrade
  /// per SAD §4 Flow 1 (linkWithCredential preserves the UID).
  final String uid;

  /// Current tier. Use this for routing decisions.
  final AuthTier tier;

  /// E.164 phone number, present once tier == phoneVerified.
  final String? phoneNumber;

  /// Set only for googleOperator tier.
  final String? email;

  /// Set only for googleOperator tier.
  final String? displayName;

  /// True iff the underlying Firebase user is anonymous.
  /// Note: an upgraded user has isAnonymous == false AND isPhoneVerified == true.
  final bool isAnonymous;

  /// True once a phone OTP has been confirmed.
  final bool isPhoneVerified;

  /// Server timestamp recorded when the upgrade succeeded.
  final DateTime? phoneVerifiedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          tier == other.tier &&
          phoneNumber == other.phoneNumber &&
          email == other.email &&
          isAnonymous == other.isAnonymous &&
          isPhoneVerified == other.isPhoneVerified;

  @override
  int get hashCode => Object.hash(
        uid,
        tier,
        phoneNumber,
        email,
        isAnonymous,
        isPhoneVerified,
      );

  @override
  String toString() =>
      'AppUser(uid: $uid, tier: $tier, phone: $phoneNumber, anon: $isAnonymous)';
}

/// Result of a phone verification request — opaque handle the caller must
/// pass back to [AuthProvider.confirmPhoneVerification] together with the
/// SMS code the user typed in.
@immutable
class PhoneVerificationResult {
  const PhoneVerificationResult({
    required this.verificationId,
    required this.codeExpiry,
    this.resendToken,
  });

  /// Opaque verification ID returned by the underlying provider.
  final String verificationId;

  /// How long the user has before this code is rejected.
  final Duration codeExpiry;

  /// Optional resend token (Firebase Phone Auth supports this).
  final int? resendToken;
}

/// All errors thrown by AuthProvider implementations are normalized to one
/// of these codes so screens can route on a stable enum instead of catching
/// provider-specific exceptions.
enum AuthErrorCode {
  /// User cancelled the flow (closed the OTP dialog, dismissed Google picker).
  cancelled,

  /// Code typed by the user did not match.
  invalidCode,

  /// Code expired before user typed it.
  codeExpired,

  /// Phone number was malformed (failed E.164 check).
  invalidPhoneNumber,

  /// Phone-auth daily quota exhausted (Firebase 10k/mo or MSG91 budget cap).
  quotaExhausted,

  /// Network unavailable.
  network,

  /// Account-already-in-use during anonymous → phone upgrade
  /// (per SAD §4 Flow 4 — caller must run the merger logic).
  credentialAlreadyInUse,

  /// Underlying provider rejected the request for a reason we don't model.
  unknown,
}

/// Normalized exception thrown by AuthProvider implementations.
class AuthException implements Exception {
  const AuthException(this.code, this.message, [this.cause]);

  final AuthErrorCode code;
  final String message;
  final Object? cause;

  @override
  String toString() => 'AuthException($code): $message';
}

/// Specialization of [AuthException] thrown by
/// [AuthProvider.confirmPhoneVerification] when the underlying Firebase
/// call fails with `credential-already-in-use` AND the provider has
/// successfully recovered the collision by signing into the existing
/// phone-verified UID using the same already-validated credential.
///
/// The [destinationUser] is the AppUser corresponding to the EXISTING
/// phone-verified account. Callers (PhoneUpgradeCoordinator) should:
///   1. Catch this exception specifically (before catching generic
///      AuthException)
///   2. Use [destinationUser] as the post-upgrade user
///   3. Run any state migration (Decision Circle / Project draft / chat
///      history) from the original anonymous UID to the destinationUser.uid
///   4. Mark the orphaned anonymous Customer document for cleanup
///
/// **Why an exception instead of a return value:** the collision path is
/// a real error condition at the Firebase SDK level — the original
/// `linkWithCredential` call DID fail. The coordinator needs to know both
/// that a collision happened AND what the resolved destination user is.
/// Returning a non-null result from `confirmPhoneVerification` would hide
/// the collision signal from the happy-path callers. Throwing with the
/// destination user attached preserves the "success" semantic for the
/// coordinator while surfacing the collision signal in the type system.
///
/// **Fixes Sprint 2.1 code review finding C1 + C2:** the original
/// implementation re-called `confirmPhoneVerification` on collision,
/// which broke because Firebase consumes the verification code on first
/// use. The correct Firebase pattern is to extract `e.credential` from
/// the failed-link exception and call `signInWithCredential` with it —
/// which is exactly what [AuthProviderFirebase] now does internally.
class AuthCollisionException extends AuthException {
  AuthCollisionException({
    required this.destinationUser,
    required this.sourceAnonymousUid,
    String? message,
  }) : super(
          AuthErrorCode.credentialAlreadyInUse,
          message ?? 'credential-already-in-use: collision recovered',
        );

  /// The existing phone-verified AppUser the provider signed into as
  /// recovery. This is the user the upgrade flow should treat as the
  /// surviving identity.
  final AppUser destinationUser;

  /// The UID of the anonymous session that was active BEFORE the
  /// collision. The coordinator must migrate any state attached to this
  /// UID to [destinationUser].uid and then mark the source Customer doc
  /// for cleanup.
  final String sourceAnonymousUid;

  @override
  String toString() =>
      'AuthCollisionException(source=$sourceAnonymousUid, dest=${destinationUser.uid})';
}

/// The adapter interface itself.
///
/// Every implementation MUST honor these contracts:
///
///   1. [authStateChanges] is a broadcast stream that fires whenever the
///      tier changes — sign-in, sign-out, upgrade.
///   2. [signInAnonymous] is idempotent — calling it on an already-anonymous
///      session returns the existing user.
///   3. [requestPhoneVerification] never blocks longer than 30s without
///      throwing AuthException(AuthErrorCode.network).
///   4. [confirmPhoneVerification] preserves the existing UID via
///      linkWithCredential when called on an anonymous session.
///   5. [signOut] clears any locally-cached refresh token so the next launch
///      starts fresh.
abstract class AuthProvider {
  /// Currently authenticated user (anonymous, phone-verified, or Google).
  Stream<AppUser?> get authStateChanges;

  /// Synchronous accessor for the current user. Use [authStateChanges] for
  /// reactive updates.
  AppUser? get currentUser;

  /// Tier 0: anonymous browse session. Always available.
  /// Idempotent — returns the existing anonymous user if one is already signed in.
  Future<AppUser> signInAnonymous();

  /// Tier 1, step 1 of 2: send the OTP code to the user's phone.
  ///
  /// Returns a [PhoneVerificationResult] the caller must hold and pass back
  /// to [confirmPhoneVerification] together with the code the user types.
  ///
  /// May throw [AuthException] with codes:
  ///   - [AuthErrorCode.invalidPhoneNumber]
  ///   - [AuthErrorCode.quotaExhausted]
  ///   - [AuthErrorCode.network]
  Future<PhoneVerificationResult> requestPhoneVerification(String phoneE164);

  /// Tier 1, step 2 of 2: confirm the OTP code and upgrade the current
  /// session to phone-verified.
  ///
  /// If the current session is anonymous, this call MUST preserve the UID
  /// via `linkWithCredential` so the customer's draft Project, Decision
  /// Circle membership, and chat history survive the upgrade (SAD §4 Flow 1).
  ///
  /// May throw [AuthException] with codes:
  ///   - [AuthErrorCode.invalidCode]
  ///   - [AuthErrorCode.codeExpired]
  ///   - [AuthErrorCode.credentialAlreadyInUse] — caller MUST run the merger
  ///     logic per SAD §4 Flow 4.
  Future<AppUser> confirmPhoneVerification(String verificationId, String code);

  /// Tier 2: Google Sign-In for the shopkeeper ops app (S4.1).
  Future<AppUser> signInWithGoogle();

  /// Sign out and clear locally-cached refresh token.
  Future<void> signOut();
}
