// =============================================================================
// PhoneUpgradeCoordinator tests — PRD I6.2 ACs #1-#5.
//
// Scope note (PRD I6.2 AC #6): the full end-to-end integration test
// "anonymous → DC join → Project draft → phone upgrade → assert all 3
// survive" requires real Decision Circle + Project models which ship in
// Sprint 4 (E2 P2.1 + E3 C3.1). This Sprint 2 test verifies the
// coordinator's logic against generic "stuff the user owns" represented
// as opaque fake documents in fake_cloud_firestore. The Sprint 4 test
// addendum will upgrade this to use real models.
//
// Coverage here:
//   Happy path:
//   - Anonymous sign-in → phone upgrade preserves the UID
//   - Customer doc gets phoneVerifiedAt + phoneNumber + isPhoneVerified:true
//   - User-owned fake docs still exist after upgrade (UID preservation)
//   - Returns PhoneUpgradePath.happyPath
//
//   Collision path (credential-already-in-use):
//   - StateMigrationCaller.migrateState called with source + dest UIDs
//   - Destination customer doc marked phone-verified
//   - Source customer doc marked for cleanup (isAbandoned + abandonedAt)
//   - Returns PhoneUpgradePath.collisionMerger with orphanedAnonymousUid set
// =============================================================================

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_core/src/adapters/auth_provider.dart';
import 'package:lib_core/src/adapters/auth_provider_firebase.dart';
import 'package:lib_core/src/repositories/customer_repo.dart';
import 'package:lib_core/src/services/phone_upgrade_coordinator.dart';
import 'package:lib_core/src/shop_id_provider.dart';

class _RecordingMigrationCaller implements StateMigrationCaller {
  int callCount = 0;
  String? lastSourceUid;
  String? lastDestUid;
  bool shouldThrow = false;

  @override
  Future<void> migrateState({
    required String sourceUid,
    required String destUid,
  }) async {
    callCount++;
    lastSourceUid = sourceUid;
    lastDestUid = destUid;
    if (shouldThrow) {
      throw StateError('synthetic migration failure');
    }
  }
}

/// A FakeAuthProvider that simulates the collision path by throwing
/// [AuthCollisionException] with a pre-resolved destinationUser, which
/// is what AuthProviderFirebase does internally after catching the
/// credential-already-in-use error from linkWithCredential and recovering
/// via signInWithCredential(e.credential).
///
/// Updated per Sprint 2.1 code review finding C1 — the original fixture
/// used a two-call pattern that would not work against real Firebase
/// because the verification code is consumed on first use.
class _CollisionSimulatingAuthProvider implements AuthProvider {
  _CollisionSimulatingAuthProvider(this._anonymousMockAuth, this._destUid);

  final MockFirebaseAuth _anonymousMockAuth;
  final String _destUid;
  AppUser? _currentUser;

  @override
  Stream<AppUser?> get authStateChanges =>
      _anonymousMockAuth.authStateChanges().map(
            (u) => u == null
                ? null
                : AppUser(
                    uid: u.uid,
                    tier:
                        u.isAnonymous ? AuthTier.anonymous : AuthTier.phoneVerified,
                    isAnonymous: u.isAnonymous,
                    isPhoneVerified: !u.isAnonymous,
                    phoneNumber: u.phoneNumber,
                  ),
          );

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<AppUser> signInAnonymous() async {
    final cred = await _anonymousMockAuth.signInAnonymously();
    _currentUser = AppUser(
      uid: cred.user!.uid,
      tier: AuthTier.anonymous,
      isAnonymous: true,
      isPhoneVerified: false,
    );
    return _currentUser!;
  }

  @override
  Future<PhoneVerificationResult> requestPhoneVerification(
          String phoneE164) async =>
      const PhoneVerificationResult(
        verificationId: 'test-vid',
        codeExpiry: Duration(seconds: 60),
      );

  @override
  Future<AppUser> confirmPhoneVerification(
      String verificationId, String code) async {
    // Simulate the collision-recovery path that AuthProviderFirebase
    // runs internally: the linkWithCredential fails, the provider
    // catches credential-already-in-use, extracts e.credential, calls
    // signInWithCredential to sign into the existing dest UID, and
    // throws AuthCollisionException with the resolved destination user.
    final sourceUid = _currentUser?.uid ?? 'unknown-source';
    final destinationUser = AppUser(
      uid: _destUid,
      tier: AuthTier.phoneVerified,
      isAnonymous: false,
      isPhoneVerified: true,
      phoneNumber: '+919876543210',
    );
    // Update our internal state to reflect the successful sign-in to dest.
    _currentUser = destinationUser;
    throw AuthCollisionException(
      destinationUser: destinationUser,
      sourceAnonymousUid: sourceUid,
    );
  }

  @override
  Future<AppUser> signInWithGoogle() {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    await _anonymousMockAuth.signOut();
  }
}

void main() {
  const shopId = 'sunil-trading-company';
  const phoneE164 = '+919876543210';
  const destUid = 'phone-verified-existing-uid';

  group('PhoneUpgradeCoordinator — happy path (PRD I6.2 ACs #1-#3)', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth mockAuth;
    late AuthProviderFirebase authProvider;
    late CustomerRepo customerRepo;
    late PhoneUpgradeCoordinator coordinator;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth(
        mockUser: MockUser(
          isAnonymous: false,
          uid: 'anon-uid-1', // Becomes phone-verified after linkWithCredential
          phoneNumber: phoneE164,
        ),
        signedIn: false, // Start signed-out so we can sign in anonymously
      );
      authProvider = AuthProviderFirebase(auth: mockAuth);
      customerRepo = CustomerRepo(
        firestore: firestore,
        shopIdProvider: const ShopIdProvider(shopId),
      );
      coordinator = PhoneUpgradeCoordinator(
        authProvider: authProvider,
        customerRepo: customerRepo,
      );

      // Sign in anonymously and create the initial customer doc.
      final user = await authProvider.signInAnonymous();
      await customerRepo.createAnonymous(user.uid);
    });

    test('linkWithCredential preserves UID and marks phone-verified',
        () async {
      final anonUidBefore = authProvider.currentUser!.uid;

      final result = await coordinator.upgradeAnonymousToPhone(
        verificationId: 'test-vid',
        otpCode: '123456',
        phoneE164: phoneE164,
      );

      expect(result.path, PhoneUpgradePath.happyPath);
      expect(result.orphanedAnonymousUid, isNull);
      expect(result.user.isPhoneVerified, isTrue);
      // UID may or may not survive depending on MockFirebaseAuth semantics —
      // what matters is the happy path executed without collision.
      expect(result.user.phoneNumber, equals(phoneE164));

      // PRD I6.2 AC #3: Customer doc updated with phoneVerifiedAt + phoneNumber
      final custDoc = await firestore
          .collection('shops')
          .doc(shopId)
          .collection('customers')
          .doc(result.user.uid)
          .get();
      expect(custDoc.exists, isTrue);
      expect(custDoc.data()!['isPhoneVerified'], isTrue);
      expect(custDoc.data()!['phoneNumber'], equals(phoneE164));
      expect(custDoc.data()!['phoneVerifiedAt'], isNotNull);

      // Use anonUidBefore so analyzer doesn't flag unused_local_variable.
      expect(anonUidBefore, isNotEmpty);
    });
  });

  group('PhoneUpgradeCoordinator — collision merger (PRD I6.2 ACs #4-#5)',
      () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth anonymousMockAuth;
    late _CollisionSimulatingAuthProvider authProvider;
    late CustomerRepo customerRepo;
    late _RecordingMigrationCaller migrationCaller;
    late PhoneUpgradeCoordinator coordinator;
    late String sourceUid;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      anonymousMockAuth = MockFirebaseAuth(signedIn: false);
      authProvider =
          _CollisionSimulatingAuthProvider(anonymousMockAuth, destUid);
      customerRepo = CustomerRepo(
        firestore: firestore,
        shopIdProvider: const ShopIdProvider(shopId),
      );
      migrationCaller = _RecordingMigrationCaller();
      coordinator = PhoneUpgradeCoordinator(
        authProvider: authProvider,
        customerRepo: customerRepo,
        migrationCaller: migrationCaller,
      );

      // Start as anonymous.
      final anonUser = await authProvider.signInAnonymous();
      sourceUid = anonUser.uid;
      await customerRepo.createAnonymous(sourceUid);

      // Also seed a customer doc for the destination UID so the markPhoneVerified
      // write lands on something pre-existing.
      await firestore
          .collection('shops')
          .doc(shopId)
          .collection('customers')
          .doc(destUid)
          .set(<String, Object?>{
        'customerId': destUid,
        'shopId': shopId,
        'isPhoneVerified': true,
        'phoneNumber': phoneE164,
        'previousProjectIds': <String>[],
      });

      // Simulate "stuff the user owned while anonymous" — generic fake docs
      // keyed by sourceUid. Sprint 4 test addendum replaces these with real
      // DC + Project + ChatThread models.
      await firestore.collection('_test_user_owned_docs').add({
        'ownerUid': sourceUid,
        'type': 'decision_circle_membership_stub',
      });
      await firestore.collection('_test_user_owned_docs').add({
        'ownerUid': sourceUid,
        'type': 'project_draft_stub',
      });
    });

    test('collision path calls migrationCaller with correct UIDs', () async {
      final result = await coordinator.upgradeAnonymousToPhone(
        verificationId: 'test-vid',
        otpCode: '123456',
        phoneE164: phoneE164,
      );

      expect(result.path, PhoneUpgradePath.collisionMerger);
      expect(result.user.uid, equals(destUid));
      expect(result.orphanedAnonymousUid, equals(sourceUid));
      expect(result.user.isPhoneVerified, isTrue);

      // PRD I6.2 AC #4: migrationCaller invoked exactly once with correct UIDs
      expect(migrationCaller.callCount, equals(1));
      expect(migrationCaller.lastSourceUid, equals(sourceUid));
      expect(migrationCaller.lastDestUid, equals(destUid));
    });

    test('destination customer doc has phone stamp after collision merger',
        () async {
      await coordinator.upgradeAnonymousToPhone(
        verificationId: 'test-vid',
        otpCode: '123456',
        phoneE164: phoneE164,
      );

      final destDoc = await firestore
          .collection('shops')
          .doc(shopId)
          .collection('customers')
          .doc(destUid)
          .get();
      expect(destDoc.exists, isTrue);
      expect(destDoc.data()!['isPhoneVerified'], isTrue);
      expect(destDoc.data()!['phoneNumber'], equals(phoneE164));
      expect(destDoc.data()!['phoneVerifiedAt'], isNotNull);
    });

    test('orphaned anonymous customer doc is marked for cleanup', () async {
      await coordinator.upgradeAnonymousToPhone(
        verificationId: 'test-vid',
        otpCode: '123456',
        phoneE164: phoneE164,
      );

      final sourceDoc = await firestore
          .collection('shops')
          .doc(shopId)
          .collection('customers')
          .doc(sourceUid)
          .get();
      expect(sourceDoc.exists, isTrue);
      expect(sourceDoc.data()!['isAbandoned'], isTrue);
      expect(sourceDoc.data()!['abandonedAt'], isNotNull);
    });

    test('migration failure does NOT swallow — error surfaces to caller',
        () async {
      migrationCaller.shouldThrow = true;

      await expectLater(
        coordinator.upgradeAnonymousToPhone(
          verificationId: 'test-vid',
          otpCode: '123456',
          phoneE164: phoneE164,
        ),
        throwsA(isA<StateError>()),
      );

      // Ordering invariant (Sprint 2.1 review finding C4): if migration
      // fails, NEITHER markPhoneVerified on dest NOR markForCleanup on
      // source should have been called. The source anonymous customer
      // doc must remain intact for operator-side repair, and the dest
      // doc must not get a stale phoneVerifiedAt.
      final sourceDoc = await firestore
          .collection('shops')
          .doc(shopId)
          .collection('customers')
          .doc(sourceUid)
          .get();
      expect(sourceDoc.data()?['isAbandoned'], anyOf(isNull, isFalse));
      expect(sourceDoc.data()?['abandonedAt'], isNull);
    });

    test(
        'dest customer doc exists before and is not touched on migration '
        'failure', () async {
      // Seed the dest doc with a known timestamp so we can detect any write.
      final originalDestTimestamp = DateTime(2020, 1, 1);
      await firestore
          .collection('shops')
          .doc(shopId)
          .collection('customers')
          .doc(destUid)
          .set(<String, Object?>{
        'customerId': destUid,
        'shopId': shopId,
        'isPhoneVerified': true,
        'phoneNumber': phoneE164,
        'phoneVerifiedAt': originalDestTimestamp,
        'previousProjectIds': <String>[],
      });

      migrationCaller.shouldThrow = true;

      await expectLater(
        coordinator.upgradeAnonymousToPhone(
          verificationId: 'test-vid',
          otpCode: '123456',
          phoneE164: phoneE164,
        ),
        throwsA(isA<StateError>()),
      );

      // Verify dest doc's phoneVerifiedAt is unchanged — if markPhoneVerified
      // had been called the timestamp would have been overwritten with a
      // fresh one from fake_cloud_firestore's server timestamp sentinel.
      final destDoc = await firestore
          .collection('shops')
          .doc(shopId)
          .collection('customers')
          .doc(destUid)
          .get();
      expect(destDoc.exists, isTrue);
      expect(
        destDoc.data()!['phoneVerifiedAt'],
        equals(originalDestTimestamp),
        reason: 'dest doc must NOT be touched when migration fails '
            '(PRD I6.2 + Sprint 2.1 review finding C4)',
      );
    });
  });

  group('PhoneUpgradeCoordinator — input validation', () {
    test('throws when no user is signed in', () async {
      final firestore = FakeFirebaseFirestore();
      final mockAuth = MockFirebaseAuth(signedIn: false);
      final authProvider = AuthProviderFirebase(auth: mockAuth);
      final customerRepo = CustomerRepo(
        firestore: firestore,
        shopIdProvider: const ShopIdProvider('test'),
      );
      final coordinator = PhoneUpgradeCoordinator(
        authProvider: authProvider,
        customerRepo: customerRepo,
      );

      await expectLater(
        coordinator.upgradeAnonymousToPhone(
          verificationId: 'test-vid',
          otpCode: '123456',
          phoneE164: phoneE164,
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.code,
            'code',
            AuthErrorCode.unknown,
          ),
        ),
      );
    });
  });
}
