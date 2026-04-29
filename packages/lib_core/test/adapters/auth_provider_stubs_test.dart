// =============================================================================
// AuthProvider stubs tests — PRD I6.1 AC #3 + AC #6.
//
// The three R8/R12 stubs (Msg91, EmailMagicLink, UpiOnly) MUST:
//   1. Throw UnimplementedError on the phone-verification path (they are stubs)
//   2. Delegate signInAnonymous + signInWithGoogle + signOut to a wrapped
//      AuthProviderFirebase instance
//   3. Forward authStateChanges from the delegate
// =============================================================================

import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_core/src/adapters/auth_provider.dart';
import 'package:lib_core/src/adapters/auth_provider_email_magic_link.dart';
import 'package:lib_core/src/adapters/auth_provider_firebase.dart';
import 'package:lib_core/src/adapters/auth_provider_msg91.dart';
import 'package:lib_core/src/adapters/auth_provider_upi_only.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseAuth mockAuth;
  late AuthProviderFirebase delegate;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    delegate = AuthProviderFirebase(auth: mockAuth);
  });

  // ---------------------------------------------------------------------------
  // AuthProviderMsg91
  // ---------------------------------------------------------------------------

  group('AuthProviderMsg91', () {
    late AuthProviderMsg91 stub;

    setUp(() {
      stub = AuthProviderMsg91(
        firebaseDelegate: delegate,
        msg91AuthKey: 'test-key',
      );
    });

    test('signInAnonymous delegates to the firebase wrapper', () async {
      final user = await stub.signInAnonymous();
      expect(user.tier, AuthTier.anonymous);
    });

    test('requestPhoneVerification throws UnimplementedError (stub)', () async {
      await expectLater(
        stub.requestPhoneVerification('+919876543210'),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('confirmPhoneVerification throws UnimplementedError (stub)', () async {
      await expectLater(
        stub.confirmPhoneVerification('vid', '123456'),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('signOut delegates', () async {
      await stub.signInAnonymous();
      await stub.signOut();
      expect(stub.currentUser, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // AuthProviderEmailMagicLink
  // ---------------------------------------------------------------------------

  group('AuthProviderEmailMagicLink', () {
    late AuthProviderEmailMagicLink stub;

    setUp(() {
      stub = AuthProviderEmailMagicLink(firebaseDelegate: delegate);
    });

    test('signInAnonymous delegates', () async {
      final user = await stub.signInAnonymous();
      expect(user.tier, AuthTier.anonymous);
    });

    test('phone path throws UnimplementedError (use email magic link instead)',
        () async {
      await expectLater(
        stub.requestPhoneVerification('+919876543210'),
        throwsA(isA<UnimplementedError>()),
      );

      await expectLater(
        stub.confirmPhoneVerification('vid', '123456'),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('requestEmailMagicLink throws UnimplementedError (stub)', () async {
      await expectLater(
        stub.requestEmailMagicLink('test@example.com'),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // AuthProviderUpiOnly
  // ---------------------------------------------------------------------------

  group('AuthProviderUpiOnly', () {
    late AuthProviderUpiOnly stub;

    setUp(() {
      stub = AuthProviderUpiOnly(firebaseDelegate: delegate);
    });

    test('signInAnonymous delegates', () async {
      final user = await stub.signInAnonymous();
      expect(user.tier, AuthTier.anonymous);
    });

    test('phone path throws UnimplementedError (UI must skip OTP screen)',
        () async {
      await expectLater(
        stub.requestPhoneVerification('+919876543210'),
        throwsA(isA<UnimplementedError>()),
      );

      await expectLater(
        stub.confirmPhoneVerification('vid', '123456'),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
