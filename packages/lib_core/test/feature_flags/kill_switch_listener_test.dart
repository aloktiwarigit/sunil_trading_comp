// =============================================================================
// KillSwitchListener tests — PRD I6.7 AC #7 real-time propagation.
//
// Coverage:
//   - Pre-start state returns safeDefaults (adapters can probe before start)
//   - First snapshot populates current + emits on the broadcast stream
//   - Flipping a flag in Firestore triggers stream emission AND updates
//     current synchronously (master contract for adapter probe pattern)
//   - Master killSwitchActive implies all sub-kills (cloudinary, firestore)
//   - Missing doc → safeDefaults
//   - Partial doc → only specified fields override, others keep defaults
//   - stop() cancels subscription, current stays at last known value
//   - start() twice is idempotent
//   - Shop-scoped path: /shops/{shopId}/featureFlags/runtime
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_core/src/feature_flags/kill_switch_listener.dart';
import 'package:lib_core/src/feature_flags/runtime_feature_flags.dart';

void main() {
  group('KillSwitchListener', () {
    late FakeFirebaseFirestore firestore;
    late KillSwitchListener listener;

    const shopId = 'sunil-trading-company';

    DocumentReference<Map<String, dynamic>> runtimeDocRef() {
      return firestore
          .collection('shops')
          .doc(shopId)
          .collection('featureFlags')
          .doc('runtime');
    }

    setUp(() {
      firestore = FakeFirebaseFirestore();
      listener = KillSwitchListener(firestore: firestore, shopId: shopId);
    });

    tearDown(() async {
      await listener.dispose();
    });

    // -------------------------------------------------------------------------
    // Pre-start state — adapters can probe safely before start()
    // -------------------------------------------------------------------------

    group('pre-start state', () {
      test('current returns safeDefaults before start', () {
        expect(listener.current, equals(RuntimeFeatureFlags.safeDefaults));
        expect(listener.isKillSwitchActive, isFalse);
        expect(listener.isCloudinaryBlocked, isFalse);
        expect(listener.isFirestoreBlocked, isFalse);
        expect(listener.authProviderStrategy, equals('firebase'));
        expect(listener.commsChannelStrategy, equals('firestore'));
        expect(listener.mediaStoreStrategy, equals('cloudinary_firebase'));
        expect(listener.isOtpAtCommitEnabled, isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // Missing document
    // -------------------------------------------------------------------------

    group('missing document', () {
      test('start() with no doc existing → current is safeDefaults', () async {
        await listener.start();
        // Let the first snapshot propagate.
        await Future<void>.delayed(Duration.zero);

        expect(listener.current, equals(RuntimeFeatureFlags.safeDefaults));
        expect(listener.isCloudinaryBlocked, isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // Initial snapshot
    // -------------------------------------------------------------------------

    group('initial snapshot', () {
      test('reads pre-existing doc on start()', () async {
        await runtimeDocRef().set(<String, dynamic>{
          'shopId': shopId,
          'killSwitchActive': false,
          'cloudinaryUploadsBlocked': true,
          'firestoreWritesBlocked': false,
          'authProviderStrategy': 'firebase',
          'commsChannelStrategy': 'firestore',
          'mediaStoreStrategy': 'cloudinary_firebase',
          'otpAtCommitEnabled': true,
        });

        await listener.start();
        await Future<void>.delayed(Duration.zero);

        expect(listener.isCloudinaryBlocked, isTrue);
        expect(listener.isFirestoreBlocked, isFalse);
        expect(listener.isKillSwitchActive, isFalse);
      });

      test('uses canonical shop-scoped path featureFlags/runtime', () async {
        // Write to a DIFFERENT path and assert the listener does NOT see it.
        await firestore
            .collection('shops')
            .doc(shopId)
            .collection('wrongPath')
            .doc('runtime')
            .set(<String, dynamic>{'cloudinaryUploadsBlocked': true});

        await listener.start();
        await Future<void>.delayed(Duration.zero);

        expect(
          listener.isCloudinaryBlocked,
          isFalse,
          reason: 'listener should ignore writes outside featureFlags/runtime',
        );
      });
    });

    // -------------------------------------------------------------------------
    // Real-time propagation — the core PRD I6.7 AC #7 contract
    // -------------------------------------------------------------------------

    group('real-time propagation', () {
      test('flipping cloudinaryUploadsBlocked in Firestore updates current',
          () async {
        await runtimeDocRef().set(<String, dynamic>{
          'shopId': shopId,
          'cloudinaryUploadsBlocked': false,
        });

        await listener.start();
        await Future<void>.delayed(Duration.zero);
        expect(listener.isCloudinaryBlocked, isFalse);

        // Simulate the kill-switch Cloud Function flipping the flag.
        await runtimeDocRef().update(<String, dynamic>{
          'cloudinaryUploadsBlocked': true,
        });
        await Future<void>.delayed(Duration.zero);

        expect(
          listener.isCloudinaryBlocked,
          isTrue,
          reason: 'flip should propagate to current synchronously after '
              'onSnapshot fires',
        );
      });

      test('master killSwitchActive implies cloudinary AND firestore blocked',
          () async {
        await runtimeDocRef().set(<String, dynamic>{
          'shopId': shopId,
          'killSwitchActive': true,
          'cloudinaryUploadsBlocked': false,
          'firestoreWritesBlocked': false,
        });

        await listener.start();
        await Future<void>.delayed(Duration.zero);

        expect(listener.isKillSwitchActive, isTrue);
        expect(
          listener.isCloudinaryBlocked,
          isTrue,
          reason: 'master kill implies cloudinary blocked even if sub-flag is false',
        );
        expect(
          listener.isFirestoreBlocked,
          isTrue,
          reason: 'master kill implies firestore blocked even if sub-flag is false',
        );
      });

      test('stream emits every flag snapshot change', () async {
        await runtimeDocRef().set(<String, dynamic>{
          'shopId': shopId,
          'cloudinaryUploadsBlocked': false,
        });

        final emitted = <RuntimeFeatureFlags>[];
        final sub = listener.stream.listen(emitted.add);

        await listener.start();
        await Future<void>.delayed(Duration.zero);

        await runtimeDocRef().update(<String, dynamic>{
          'cloudinaryUploadsBlocked': true,
        });
        await Future<void>.delayed(Duration.zero);

        await runtimeDocRef().update(<String, dynamic>{
          'cloudinaryUploadsBlocked': false,
          'firestoreWritesBlocked': true,
        });
        await Future<void>.delayed(Duration.zero);

        await sub.cancel();

        // First emission = initial, then 2 updates = 3 total
        expect(emitted.length, greaterThanOrEqualTo(3));
        expect(emitted.last.firestoreWritesBlocked, isTrue);
        expect(emitted.last.cloudinaryUploadsBlocked, isFalse);
      });

      test('adapter probe lambda pattern works — reads sync from listener',
          () async {
        await runtimeDocRef().set(<String, dynamic>{
          'shopId': shopId,
          'cloudinaryUploadsBlocked': false,
        });

        await listener.start();
        await Future<void>.delayed(Duration.zero);

        // Simulate what MediaStoreFactory does — capture the listener
        // reference in a probe lambda and call it synchronously when
        // uploading.
        Future<bool> probeCloudinary() async => listener.isCloudinaryBlocked;

        expect(await probeCloudinary(), isFalse);

        await runtimeDocRef().update(<String, dynamic>{
          'cloudinaryUploadsBlocked': true,
        });
        await Future<void>.delayed(Duration.zero);

        expect(
          await probeCloudinary(),
          isTrue,
          reason: 'probe lambda reads the updated value without any re-wiring',
        );
      });
    });

    // -------------------------------------------------------------------------
    // Partial doc handling
    // -------------------------------------------------------------------------

    group('partial doc handling', () {
      test('doc with only cloudinaryUploadsBlocked set — others use defaults',
          () async {
        await runtimeDocRef().set(<String, dynamic>{
          'cloudinaryUploadsBlocked': true,
        });

        await listener.start();
        await Future<void>.delayed(Duration.zero);

        expect(listener.isCloudinaryBlocked, isTrue);
        expect(listener.isFirestoreBlocked, isFalse);
        expect(listener.authProviderStrategy, equals('firebase'));
        expect(listener.commsChannelStrategy, equals('firestore'));
        expect(listener.mediaStoreStrategy, equals('cloudinary_firebase'));
        expect(listener.isOtpAtCommitEnabled, isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // Lifecycle
    // -------------------------------------------------------------------------

    group('lifecycle', () {
      test('start() is idempotent — calling twice is a no-op', () async {
        await listener.start();
        await listener.start(); // should log a warning but not crash
        await Future<void>.delayed(Duration.zero);

        expect(listener.current, isNotNull);
      });

      test('stop() cancels subscription but preserves last known current',
          () async {
        await runtimeDocRef().set(<String, dynamic>{
          'cloudinaryUploadsBlocked': true,
        });

        await listener.start();
        await Future<void>.delayed(Duration.zero);
        expect(listener.isCloudinaryBlocked, isTrue);

        await listener.stop();

        // Current should still hold the last known value after stop.
        expect(listener.isCloudinaryBlocked, isTrue);

        // Further Firestore writes should NOT update current (listener stopped).
        await runtimeDocRef().update(<String, dynamic>{
          'cloudinaryUploadsBlocked': false,
        });
        await Future<void>.delayed(Duration.zero);

        expect(
          listener.isCloudinaryBlocked,
          isTrue,
          reason: 'current must not update after stop()',
        );
      });
    });
  });
}
