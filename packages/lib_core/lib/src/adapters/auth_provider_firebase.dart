// =============================================================================
// AuthProviderFirebase — the default implementation of AuthProvider.
//
// Wraps `firebase_auth` and `google_sign_in`. Anonymous + Phone + Google are
// all routed through Firebase. The 10k/mo Blaze SMS quota is the cost ceiling
// (per SAD §10).
//
// PRD I6.1 AC #2: this class.
// =============================================================================

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logging/logging.dart';

import 'auth_provider.dart';

/// Firebase-backed [AuthProvider]. Production default.
class AuthProviderFirebase implements AuthProvider {
  /// [auth] and [googleSignIn] are injectable for testability — production
  /// callers should pass `fb.FirebaseAuth.instance` and a default `GoogleSignIn`.
  AuthProviderFirebase({
    required fb.FirebaseAuth auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final fb.FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  static final Logger _log = Logger('AuthProviderFirebase');

  @override
  Stream<AppUser?> get authStateChanges =>
      _auth.authStateChanges().map(_toAppUser);

  @override
  AppUser? get currentUser => _toAppUser(_auth.currentUser);

  // ---------------------------------------------------------------------------
  // Tier 0 — Anonymous
  // ---------------------------------------------------------------------------

  @override
  Future<AppUser> signInAnonymous() async {
    // Idempotent — if already signed in (anonymous OR upgraded), return current.
    final existing = _auth.currentUser;
    if (existing != null) {
      return _toAppUser(existing)!;
    }

    try {
      final cred = await _auth.signInAnonymously();
      final user = cred.user;
      if (user == null) {
        throw const AuthException(
          AuthErrorCode.unknown,
          'Anonymous sign-in returned null user',
        );
      }
      _log.info('Anonymous sign-in successful: ${user.uid}');
      return _toAppUser(user)!;
    } on fb.FirebaseAuthException catch (e) {
      throw _normalize(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Tier 1 — Phone OTP (with anonymous → phone upgrade preserving UID)
  // ---------------------------------------------------------------------------

  @override
  Future<PhoneVerificationResult> requestPhoneVerification(
    String phoneE164,
  ) async {
    if (!_isE164(phoneE164)) {
      throw AuthException(
        AuthErrorCode.invalidPhoneNumber,
        'Phone number "$phoneE164" is not in E.164 format',
      );
    }

    final completer = Completer<PhoneVerificationResult>();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneE164,
        timeout: const Duration(seconds: 60),

        // Android instant-verification path. We treat this as a normal code
        // delivery so the upper layer flow is consistent with iOS.
        verificationCompleted: (fb.PhoneAuthCredential credential) {
          // Intentional no-op: we want the user to type the code so the funnel
          // event is recorded the same way on every platform. Instant-verify
          // does happen on the device but we ignore it.
        },

        verificationFailed: (fb.FirebaseAuthException e) {
          if (!completer.isCompleted) {
            completer.completeError(_normalize(e));
          }
        },

        codeSent: (String verificationId, int? resendToken) {
          if (!completer.isCompleted) {
            completer.complete(
              PhoneVerificationResult(
                verificationId: verificationId,
                codeExpiry: const Duration(seconds: 60),
                resendToken: resendToken,
              ),
            );
          }
        },

        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto-retrieval timed out — that's fine, the user types it manually.
        },
      );
    } on fb.FirebaseAuthException catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(_normalize(e));
      }
    }

    return completer.future;
  }

  @override
  Future<AppUser> confirmPhoneVerification(
    String verificationId,
    String code,
  ) async {
    final credential = fb.PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: code,
    );

    try {
      final existing = _auth.currentUser;

      // Anonymous → Phone upgrade — preserves UID per SAD §4 Flow 1.
      if (existing != null && existing.isAnonymous) {
        final cred = await existing.linkWithCredential(credential);
        final user = cred.user;
        if (user == null) {
          throw const AuthException(
            AuthErrorCode.unknown,
            'linkWithCredential returned null user',
          );
        }
        _log.info('Anonymous → Phone upgrade successful: ${user.uid}');
        return _toAppUser(user)!;
      }

      // No existing session, or already phone-verified — plain sign-in.
      final cred = await _auth.signInWithCredential(credential);
      final user = cred.user;
      if (user == null) {
        throw const AuthException(
          AuthErrorCode.unknown,
          'signInWithCredential returned null user',
        );
      }
      _log.info('Phone sign-in successful: ${user.uid}');
      return _toAppUser(user)!;
    } on fb.FirebaseAuthException catch (e) {
      throw _normalize(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Tier 2 — Google Sign-In (shopkeeper ops only)
  // ---------------------------------------------------------------------------

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User dismissed the picker.
        throw const AuthException(
          AuthErrorCode.cancelled,
          'Google sign-in cancelled by user',
        );
      }

      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);
      final user = cred.user;
      if (user == null) {
        throw const AuthException(
          AuthErrorCode.unknown,
          'Google signInWithCredential returned null user',
        );
      }
      _log.info('Google sign-in successful: ${user.uid} (${user.email})');
      return _toAppUser(user)!;
    } on fb.FirebaseAuthException catch (e) {
      throw _normalize(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Sign out
  // ---------------------------------------------------------------------------

  @override
  Future<void> signOut() async {
    try {
      // Sign out of Google first (no-op if not signed in via Google).
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
      _log.info('Signed out');
    } on fb.FirebaseAuthException catch (e) {
      throw _normalize(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static final RegExp _e164Pattern = RegExp(r'^\+[1-9]\d{6,14}$');

  static bool _isE164(String phone) => _e164Pattern.hasMatch(phone);

  AppUser? _toAppUser(fb.User? user) {
    if (user == null) return null;

    final tier = _resolveTier(user);
    return AppUser(
      uid: user.uid,
      tier: tier,
      isAnonymous: user.isAnonymous,
      isPhoneVerified: user.phoneNumber != null && user.phoneNumber!.isNotEmpty,
      phoneNumber: user.phoneNumber,
      email: user.email,
      displayName: user.displayName,
      phoneVerifiedAt: user.metadata.lastSignInTime,
    );
  }

  AuthTier _resolveTier(fb.User user) {
    if (user.providerData
        .any((p) => p.providerId == fb.GoogleAuthProvider.PROVIDER_ID)) {
      return AuthTier.googleOperator;
    }
    if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
      return AuthTier.phoneVerified;
    }
    if (user.isAnonymous) {
      return AuthTier.anonymous;
    }
    return AuthTier.signedOut;
  }

  AuthException _normalize(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-verification-code':
        return AuthException(AuthErrorCode.invalidCode, e.message ?? '', e);
      case 'session-expired':
      case 'expired-action-code':
        return AuthException(AuthErrorCode.codeExpired, e.message ?? '', e);
      case 'invalid-phone-number':
        return AuthException(
            AuthErrorCode.invalidPhoneNumber, e.message ?? '', e);
      case 'quota-exceeded':
      case 'too-many-requests':
        return AuthException(AuthErrorCode.quotaExhausted, e.message ?? '', e);
      case 'network-request-failed':
        return AuthException(AuthErrorCode.network, e.message ?? '', e);
      case 'credential-already-in-use':
      case 'account-exists-with-different-credential':
        return AuthException(
            AuthErrorCode.credentialAlreadyInUse, e.message ?? '', e);
      default:
        _log.warning('Unmapped FirebaseAuthException: ${e.code} — ${e.message}');
        return AuthException(AuthErrorCode.unknown, e.message ?? e.code, e);
    }
  }
}
