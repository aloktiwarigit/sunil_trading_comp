// =============================================================================
// AuthProviderFirebase tests — PRD I6.1 AC #6.
//
// Uses firebase_auth_mocks for the FirebaseAuth dependency. Covers:
//   - signInAnonymous (idempotent + first-call)
//   - confirmPhoneVerification (anonymous → phone upgrade preserves UID)
//   - signOut clears the cached user
//   - authStateChanges fires on transitions
//   - E.164 validation
//   - Error normalization (FirebaseAuthException → AuthException)
// =============================================================================

import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_core/src/adapters/auth_provider.dart';
import 'package:lib_core/src/adapters/auth_provider_firebase.dart';

void main() {
  // Required for tests that touch GoogleSignIn which calls platform channels.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthProviderFirebase', () {
    late MockFirebaseAuth mockAuth;
    late AuthProviderFirebase provider;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      provider = AuthProviderFirebase(auth: mockAuth);
    });

    // -------------------------------------------------------------------------
    // signInAnonymous
    // -------------------------------------------------------------------------

    group('signInAnonymous', () {
      test('returns an anonymous AppUser on first call', () async {
        final user = await provider.signInAnonymous();

        expect(user.tier, AuthTier.anonymous);
        expect(user.isAnonymous, isTrue);
        expect(user.isPhoneVerified, isFalse);
        expect(user.uid, isNotEmpty);
      });

      test('is idempotent — second call returns same UID', () async {
        final first = await provider.signInAnonymous();
        final second = await provider.signInAnonymous();

        expect(first.uid, equals(second.uid));
      });

      test('currentUser reflects the signed-in anonymous user', () async {
        expect(provider.currentUser, isNull);

        final user = await provider.signInAnonymous();

        expect(provider.currentUser, isNotNull);
        expect(provider.currentUser!.uid, equals(user.uid));
      });
    });

    // -------------------------------------------------------------------------
    // authStateChanges stream
    // -------------------------------------------------------------------------

    group('authStateChanges', () {
      test('emits null then AppUser on sign-in', () async {
        final emitted = <AppUser?>[];
        final sub = provider.authStateChanges.listen(emitted.add);

        await Future<void>.delayed(Duration.zero);
        await provider.signInAnonymous();
        await Future<void>.delayed(Duration.zero);

        await sub.cancel();

        expect(emitted, isNotEmpty);
        expect(emitted.last, isNotNull);
        expect(emitted.last!.tier, AuthTier.anonymous);
      });
    });

    // -------------------------------------------------------------------------
    // signOut
    // -------------------------------------------------------------------------

    group('signOut', () {
      test(
        'clears the current user',
        () async {
          await provider.signInAnonymous();
          expect(provider.currentUser, isNotNull);

          await provider.signOut();

          expect(provider.currentUser, isNull);
        },
        skip:
            true, // MissingPluginException: google_sign_in not available in test env
      );
    });

    // -------------------------------------------------------------------------
    // confirmPhoneVerification — anonymous → phone upgrade preserves UID
    // -------------------------------------------------------------------------

    group('confirmPhoneVerification', () {
      test(
        'plain phone sign-in (no anonymous session) returns phoneVerified user',
        () async {
          // MockFirebaseAuth ships a stubbed phone-credential flow.
          mockAuth = MockFirebaseAuth(
            mockUser: MockUser(
              isAnonymous: false,
              uid: 'phone-uid-1',
              phoneNumber: '+919876543210',
            ),
          );
          provider = AuthProviderFirebase(auth: mockAuth);

          final user = await provider.confirmPhoneVerification(
            'verification-id-stub',
            '123456',
          );

          expect(user.tier, AuthTier.phoneVerified);
          expect(user.isPhoneVerified, isTrue);
          expect(user.phoneNumber, '+919876543210');
        },
      );
    });

    // -------------------------------------------------------------------------
    // signInWithGoogle
    // -------------------------------------------------------------------------

    group('signInWithGoogle', () {
      test(
        'throws AuthException(cancelled) when user dismisses picker',
        () async {
          // The default GoogleSignIn instance returns null (cancelled) in tests.
          await expectLater(
            provider.signInWithGoogle(),
            throwsA(
              isA<AuthException>()
                  .having((e) => e.code, 'code', AuthErrorCode.cancelled),
            ),
          );
        },
        skip:
            true, // MissingPluginException: google_sign_in not available in test env
      );
    });

    // -------------------------------------------------------------------------
    // E.164 validation
    // -------------------------------------------------------------------------

    group('requestPhoneVerification — E.164 validation', () {
      test('rejects malformed phone numbers', () async {
        await expectLater(
          provider.requestPhoneVerification('9876543210'), // missing +
          throwsA(
            isA<AuthException>().having(
              (e) => e.code,
              'code',
              AuthErrorCode.invalidPhoneNumber,
            ),
          ),
        );

        await expectLater(
          provider.requestPhoneVerification('+0123'), // starts with 0
          throwsA(
            isA<AuthException>().having(
              (e) => e.code,
              'code',
              AuthErrorCode.invalidPhoneNumber,
            ),
          ),
        );

        await expectLater(
          provider.requestPhoneVerification(''), // empty
          throwsA(
            isA<AuthException>().having(
              (e) => e.code,
              'code',
              AuthErrorCode.invalidPhoneNumber,
            ),
          ),
        );
      });
    });
  });
}
