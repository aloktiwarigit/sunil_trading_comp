// =============================================================================
// AuthProviderFactory tests — PRD I6.1 AC #4 + Edge case #1.
//
// We test the strategy-resolution logic without actually invoking Firebase
// Remote Config (which requires a live Firebase init). The factory accepts
// the FirebaseRemoteConfig instance as a parameter so a mocked stand-in
// can be passed.
// =============================================================================

import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_core/src/adapters/auth_provider_email_magic_link.dart';
import 'package:lib_core/src/adapters/auth_provider_factory.dart';
import 'package:lib_core/src/adapters/auth_provider_firebase.dart';
import 'package:lib_core/src/adapters/auth_provider_msg91.dart';
import 'package:lib_core/src/adapters/auth_provider_upi_only.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemoteConfig extends Mock implements FirebaseRemoteConfig {}

void main() {
  late _MockRemoteConfig remoteConfig;
  late MockFirebaseAuth mockAuth;

  setUp(() {
    remoteConfig = _MockRemoteConfig();
    mockAuth = MockFirebaseAuth();
  });

  group('AuthProviderFactory.build', () {
    test('returns AuthProviderFirebase when strategy is "firebase"', () {
      when(() => remoteConfig.getString('auth_provider_strategy'))
          .thenReturn(AuthProviderStrategy.firebase);

      final provider = AuthProviderFactory.build(
        remoteConfig: remoteConfig,
        firebaseAuth: mockAuth,
      );

      expect(provider, isA<AuthProviderFirebase>());
    });

    test('returns AuthProviderMsg91 when strategy is "msg91" with valid key',
        () {
      when(() => remoteConfig.getString('auth_provider_strategy'))
          .thenReturn(AuthProviderStrategy.msg91);

      final provider = AuthProviderFactory.build(
        remoteConfig: remoteConfig,
        firebaseAuth: mockAuth,
        msg91AuthKey: 'test-key',
      );

      expect(provider, isA<AuthProviderMsg91>());
    });

    test('falls back to firebase when "msg91" strategy missing auth key', () {
      when(() => remoteConfig.getString('auth_provider_strategy'))
          .thenReturn(AuthProviderStrategy.msg91);

      final provider = AuthProviderFactory.build(
        remoteConfig: remoteConfig,
        firebaseAuth: mockAuth,
        // No msg91AuthKey
      );

      expect(provider, isA<AuthProviderFirebase>());
    });

    test('returns AuthProviderEmailMagicLink when strategy is "email"', () {
      when(() => remoteConfig.getString('auth_provider_strategy'))
          .thenReturn(AuthProviderStrategy.email);

      final provider = AuthProviderFactory.build(
        remoteConfig: remoteConfig,
        firebaseAuth: mockAuth,
      );

      expect(provider, isA<AuthProviderEmailMagicLink>());
    });

    test('returns AuthProviderUpiOnly when strategy is "upi_only"', () {
      when(() => remoteConfig.getString('auth_provider_strategy'))
          .thenReturn(AuthProviderStrategy.upiOnly);

      final provider = AuthProviderFactory.build(
        remoteConfig: remoteConfig,
        firebaseAuth: mockAuth,
      );

      expect(provider, isA<AuthProviderUpiOnly>());
    });

    // ----- PRD I6.1 Edge case #1 -----
    test('falls back to firebase when strategy is unknown', () {
      when(() => remoteConfig.getString('auth_provider_strategy'))
          .thenReturn('martian-quantum-auth');

      final provider = AuthProviderFactory.build(
        remoteConfig: remoteConfig,
        firebaseAuth: mockAuth,
      );

      expect(provider, isA<AuthProviderFirebase>());
    });

    test('falls back to firebase when strategy string is empty', () {
      when(() => remoteConfig.getString('auth_provider_strategy'))
          .thenReturn('');

      final provider = AuthProviderFactory.build(
        remoteConfig: remoteConfig,
        firebaseAuth: mockAuth,
      );

      expect(provider, isA<AuthProviderFirebase>());
    });
  });
}
