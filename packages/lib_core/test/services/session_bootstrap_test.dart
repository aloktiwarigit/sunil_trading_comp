// =============================================================================
// SessionBootstrap tests — PRD I6.3 smoke coverage.
//
// The real refresh-token persistence is Firebase SDK territory and can't
// be unit-tested meaningfully (requires SharedPreferences / Keychain /
// IndexedDB). This test verifies the SessionBootstrap wrapper's
// decision logic using firebase_auth_mocks:
//
//   - No signed-in user → outcome = firstLaunchOrSignedOut, no restoredUser
//   - Anonymous signed-in user → outcome = sessionRestored, tier=anonymous
//   - Phone-verified user → outcome = sessionRestored, tier=phoneVerified
//
// Analytics/Crashlytics fire paths are null-safe — the test passes null
// for both and verifies the core outcome/restoredUser values.
// =============================================================================

import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_core/src/adapters/auth_provider.dart';
import 'package:lib_core/src/adapters/auth_provider_firebase.dart';
import 'package:lib_core/src/services/session_bootstrap.dart';

void main() {
  group('SessionBootstrap.verifyPersistedUser', () {
    test('no signed-in user → firstLaunchOrSignedOut', () async {
      final mockAuth = MockFirebaseAuth(signedIn: false);
      final authProvider = AuthProviderFirebase(auth: mockAuth);

      final result = await SessionBootstrap.verifyPersistedUser(
        authProvider: authProvider,
      );

      expect(result.outcome, SessionBootstrapOutcome.firstLaunchOrSignedOut);
      expect(result.restoredUser, isNull);
    });

    test('anonymous signed-in user → sessionRestored (tier=anonymous)',
        () async {
      final mockAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(isAnonymous: true, uid: 'anon-1'),
      );
      final authProvider = AuthProviderFirebase(auth: mockAuth);

      final result = await SessionBootstrap.verifyPersistedUser(
        authProvider: authProvider,
      );

      expect(result.outcome, SessionBootstrapOutcome.sessionRestored);
      expect(result.restoredUser, isNotNull);
      expect(result.restoredUser!.tier, AuthTier.anonymous);
      expect(result.restoredUser!.uid, equals('anon-1'));
      expect(result.restoredUser!.isPhoneVerified, isFalse);
    });

    test('phone-verified user → sessionRestored (tier=phoneVerified)',
        () async {
      final mockAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(
          isAnonymous: false,
          uid: 'phone-1',
          phoneNumber: '+919876543210',
        ),
      );
      final authProvider = AuthProviderFirebase(auth: mockAuth);

      final result = await SessionBootstrap.verifyPersistedUser(
        authProvider: authProvider,
      );

      expect(result.outcome, SessionBootstrapOutcome.sessionRestored);
      expect(result.restoredUser, isNotNull);
      expect(result.restoredUser!.tier, AuthTier.phoneVerified);
      expect(result.restoredUser!.isPhoneVerified, isTrue);
      expect(result.restoredUser!.phoneNumber, equals('+919876543210'));
    });

    test('verifyPersistedUser is idempotent — second call returns same result',
        () async {
      final mockAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(isAnonymous: true, uid: 'anon-idem'),
      );
      final authProvider = AuthProviderFirebase(auth: mockAuth);

      final r1 = await SessionBootstrap.verifyPersistedUser(
          authProvider: authProvider);
      final r2 = await SessionBootstrap.verifyPersistedUser(
          authProvider: authProvider);

      expect(r1.outcome, r2.outcome);
      expect(r1.restoredUser?.uid, r2.restoredUser?.uid);
    });
  });
}
