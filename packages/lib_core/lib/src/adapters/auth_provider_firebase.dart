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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logging/logging.dart';

import 'auth_provider.dart';

/// Firebase-backed [AuthProvider]. Production default.
class AuthProviderFirebase implements AuthProvider {
  /// [auth] and [googleSignIn] are injectable for testability — production
  /// callers should pass `fb.FirebaseAuth.instance` and a default `GoogleSignIn`.
  ///
  /// [shopId]: when provided, a successful [confirmPhoneVerification] writes a
  /// fire-and-forget increment to `system/phone_auth_quota/shops/{shopId}` so
  /// the per-shop quota monitor (WS6.2) can apply graduated responses per-shop
  /// rather than globally. Omit in tests that don't need Firestore.
  AuthProviderFirebase({
    required fb.FirebaseAuth auth,
    GoogleSignIn? googleSignIn,
    String? shopId,
    FirebaseFirestore? firestore,
  })  : _auth = auth,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _shopId = shopId,
        _firestore = firestore ?? (shopId != null ? FirebaseFirestore.instance : null);

  final fb.FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final String? _shopId;
  final FirebaseFirestore? _firestore;
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

    // Explicit completion flag — the Completer.isCompleted check alone is
    // insufficient under race conditions where two callbacks fire in the
    // same microtask (observed on slow tier-3 Android during network flap).
    // Sprint 2.1 code review finding C7: without this flag,
    // `verificationFailed` and `codeSent` firing simultaneously could both
    // pass the `isCompleted` check and throw "Future already completed".
    // The flag closes the race because Dart is single-threaded within a
    // single isolate — once any callback sets it, no other callback can
    // enter the critical section on the same event-loop turn.
    var completed = false;

    void safeComplete(PhoneVerificationResult result) {
      if (completed) return;
      completed = true;
      completer.complete(result);
    }

    void safeCompleteError(Object error) {
      if (completed) return;
      completed = true;
      completer.completeError(error);
    }

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
          safeCompleteError(_normalize(e));
        },

        codeSent: (String verificationId, int? resendToken) {
          safeComplete(
            PhoneVerificationResult(
              verificationId: verificationId,
              codeExpiry: const Duration(seconds: 60),
              resendToken: resendToken,
            ),
          );
        },

        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto-retrieval timed out — that's fine, the user types it manually.
        },
      );
    } on fb.FirebaseAuthException catch (e) {
      safeCompleteError(_normalize(e));
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

    final existing = _auth.currentUser;
    final sourceAnonymousUid =
        (existing != null && existing.isAnonymous) ? existing.uid : null;

    // ---- Anonymous → Phone upgrade (SAD §4 Flow 1) ----
    if (sourceAnonymousUid != null) {
      try {
        final linkResult = await existing!.linkWithCredential(credential);
        final user = linkResult.user;
        if (user == null) {
          throw const AuthException(
            AuthErrorCode.unknown,
            'linkWithCredential returned null user',
          );
        }
        _log.info('Anonymous → Phone upgrade successful: ${user.uid}');
        _incrementPerShopSmsCounter();
        return _toAppUser(user)!;
      } on fb.FirebaseAuthException catch (e) {
        // ---- Collision recovery (SAD §4 Flow 4) ----
        //
        // Fixed in response to Sprint 2.1 code review findings C1 + C2.
        // Original implementation threw and let the coordinator re-call
        // confirmPhoneVerification, but Firebase consumes the verification
        // code on first use — a second call would fail with
        // invalid-verification-code. The correct pattern is to extract
        // e.credential (the already-validated PhoneAuthCredential) and
        // call signInWithCredential with it, which signs into the
        // existing phone-verified UID without consuming a new OTP.
        if (e.code == 'credential-already-in-use' ||
            e.code == 'account-exists-with-different-credential') {
          final recovered = e.credential;
          if (recovered == null) {
            // Firebase didn't give us a recoverable credential — this
            // shouldn't happen for phone auth but we handle it defensively.
            _log.severe(
              'credential-already-in-use with null e.credential — '
              'cannot recover. UID=${sourceAnonymousUid}',
            );
            throw _normalize(e);
          }
          try {
            final signInResult = await _auth.signInWithCredential(recovered);
            final destUser = signInResult.user;
            if (destUser == null) {
              throw const AuthException(
                AuthErrorCode.unknown,
                'collision recovery signInWithCredential returned null user',
              );
            }
            _log.info(
              'collision recovery: source=$sourceAnonymousUid '
              'dest=${destUser.uid}',
            );
            // Throw the specialized collision exception so the coordinator
            // can detect this path and run migration + cleanup.
            throw AuthCollisionException(
              destinationUser: _toAppUser(destUser)!,
              sourceAnonymousUid: sourceAnonymousUid,
            );
          } on fb.FirebaseAuthException catch (recoveryError) {
            _log.severe(
              'collision recovery signInWithCredential failed: '
              '${recoveryError.code} — ${recoveryError.message}',
            );
            throw _normalize(recoveryError);
          }
        }
        // Other errors — normalize and rethrow.
        throw _normalize(e);
      }
    }

    // ---- Plain phone sign-in (no anonymous session) ----
    try {
      final cred = await _auth.signInWithCredential(credential);
      final user = cred.user;
      if (user == null) {
        throw const AuthException(
          AuthErrorCode.unknown,
          'signInWithCredential returned null user',
        );
      }
      _log.info('Phone sign-in successful: ${user.uid}');
      _incrementPerShopSmsCounter();
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
    // Step 1 — Google picker. Errors from google_sign_in are NOT
    // FirebaseAuthException; they are platform exceptions that must be
    // caught separately per Sprint 2.1 code review finding C6.
    final GoogleSignInAccount? googleUser;
    try {
      googleUser = await _googleSignIn.signIn();
    } on Object catch (e, st) {
      _log.severe('GoogleSignIn.signIn() failed: $e\n$st');
      throw AuthException(
        AuthErrorCode.unknown,
        'Google sign-in picker failed: $e',
        e,
      );
    }

    if (googleUser == null) {
      // User dismissed the picker.
      throw const AuthException(
        AuthErrorCode.cancelled,
        'Google sign-in cancelled by user',
      );
    }

    // Step 2 — Fetch the Google auth tokens. Can also throw
    // google_sign_in platform errors if the Google account is in a
    // weird state (revoked refresh token, network flap).
    final GoogleSignInAuthentication googleAuth;
    try {
      googleAuth = await googleUser.authentication;
    } on Object catch (e, st) {
      _log.severe('GoogleSignInAccount.authentication failed: $e\n$st');
      throw AuthException(
        AuthErrorCode.unknown,
        'Google auth token fetch failed: $e',
        e,
      );
    }

    // Step 3 — Exchange for Firebase credential + sign in. This is the
    // only step that legitimately throws FirebaseAuthException.
    final credential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    try {
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
  // Token claims
  // ---------------------------------------------------------------------------

  @override
  Future<Map<String, dynamic>> getTokenClaims({
    bool forceRefresh = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return {};
    final result = await user.getIdTokenResult(forceRefresh);
    return result.claims ?? {};
  }

  // ---------------------------------------------------------------------------
  // Per-shop SMS quota counter (WS6.2)
  // ---------------------------------------------------------------------------

  /// Fire-and-forget increment of `system/phone_auth_quota/shops/{shopId}`
  /// field `smsCount_{YYYY-MM}`. Called after every successful OTP verification.
  /// Errors are logged but never rethrow — the auth flow must not fail due to
  /// an observability write.
  void _incrementPerShopSmsCounter() {
    final db = _firestore;
    final shopId = _shopId;
    if (db == null || shopId == null || shopId.isEmpty) return;

    final now = DateTime.now().toUtc();
    final monthKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    db
        .collection('system')
        .doc('phone_auth_quota')
        .collection('shops')
        .doc(shopId)
        .set(
          {
            'smsCount_$monthKey': FieldValue.increment(1),
            'shopId': shopId,
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        )
        .then((_) {
          _log.fine('Per-shop SMS counter incremented: $shopId/$monthKey');
        })
        .catchError((Object err) {
          _log.warning(
            'Failed to increment per-shop SMS counter for $shopId: $err',
          );
        });
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  // India-primary pattern: +91 followed by a 10-digit mobile starting with
  // 6/7/8/9 (India's mobile number block per TRAI numbering plan). This is
  // the v1 target market — Sunil Trading Company is in Ayodhya and every
  // expected customer has an Indian phone number.
  static final RegExp _indiaMobilePattern = RegExp(r'^\+91[6-9]\d{9}$');

  // Permissive fallback for E.164 globally. Accepts 7-15 total digits after
  // the + per the E.164 standard. Used only if `_indiaMobilePattern` rejects
  // the input AND the caller passes an explicit non-IN phone number in a
  // future multi-country v1.5+ scenario. For Sprint 2 the India pattern
  // is what matters.
  static final RegExp _e164FallbackPattern = RegExp(r'^\+[1-9]\d{6,14}$');

  /// Validate an E.164 phone number. Indian numbers (+91) are validated
  /// strictly against the TRAI mobile block (10 digits starting with
  /// 6/7/8/9). Other countries fall back to the general E.164 shape.
  /// Tightened per Sprint 2.1 code review finding C5 (was permissive E.164
  /// only, which accepted malformed Indian numbers like `+919`).
  static bool _isE164(String phone) {
    if (phone.startsWith('+91')) {
      return _indiaMobilePattern.hasMatch(phone);
    }
    return _e164FallbackPattern.hasMatch(phone);
  }

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
      // Sprint 2.1 code review finding C12: distinguish benign duplicate
      // linking (same user already has this provider) from the real
      // collision merger path (different user has this credential).
      case 'provider-already-linked':
        return AuthException(
            AuthErrorCode.providerAlreadyLinked, e.message ?? '', e);
      default:
        _log.warning(
            'Unmapped FirebaseAuthException: ${e.code} — ${e.message}');
        return AuthException(AuthErrorCode.unknown, e.message ?? e.code, e);
    }
  }
}
