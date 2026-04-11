// =============================================================================
// MediaStoreFactory tests — PRD I6.6 AC #4 runtime selection.
//
// Coverage:
//   - Default strategy (empty Remote Config value) → cloudinary_firebase
//   - Explicit cloudinary_firebase → MediaStoreCloudinaryFirebase
//   - Explicit r2 → MediaStoreR2
//   - Unknown strategy → falls back to cloudinary_firebase + logs to Crashlytics
// =============================================================================

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_core/src/adapters/media_store_cloudinary_firebase.dart';
import 'package:lib_core/src/adapters/media_store_factory.dart';
import 'package:lib_core/src/adapters/media_store_r2.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemoteConfig extends Mock implements FirebaseRemoteConfig {}

class _MockFirebaseStorage extends Mock implements FirebaseStorage {}

class _MockCrashlytics extends Mock implements FirebaseCrashlytics {}

class _FakeStackTrace extends Fake implements StackTrace {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeStackTrace());
  });

  group('MediaStoreFactory', () {
    late _MockRemoteConfig remoteConfig;
    late _MockFirebaseStorage storage;
    late _MockCrashlytics crashlytics;

    setUp(() {
      remoteConfig = _MockRemoteConfig();
      storage = _MockFirebaseStorage();
      crashlytics = _MockCrashlytics();
    });

    test('empty Remote Config value → falls through to default', () {
      when(() => remoteConfig.getString('media_store_strategy')).thenReturn('');

      final adapter = MediaStoreFactory.build(
        remoteConfig: remoteConfig,
        firebaseStorage: storage,
        cloudinaryCloudName: 'yugma-test',
      );

      expect(adapter, isA<MediaStoreCloudinaryFirebase>());
    });

    test('explicit cloudinary_firebase strategy returns default impl', () {
      when(() => remoteConfig.getString('media_store_strategy'))
          .thenReturn('cloudinary_firebase');

      final adapter = MediaStoreFactory.build(
        remoteConfig: remoteConfig,
        firebaseStorage: storage,
        cloudinaryCloudName: 'yugma-test',
      );

      expect(adapter, isA<MediaStoreCloudinaryFirebase>());
    });

    test('explicit r2 strategy returns stub', () {
      when(() => remoteConfig.getString('media_store_strategy'))
          .thenReturn('r2');

      final adapter = MediaStoreFactory.build(
        remoteConfig: remoteConfig,
        firebaseStorage: storage,
        cloudinaryCloudName: 'yugma-test',
      );

      expect(adapter, isA<MediaStoreR2>());
    });

    test('unknown strategy falls back to default AND logs to Crashlytics', () {
      when(() => remoteConfig.getString('media_store_strategy'))
          .thenReturn('wildcard-unknown');
      when(
        () => crashlytics.recordError(
          any<Object>(),
          any<StackTrace>(),
          reason: any<dynamic>(named: 'reason'),
        ),
      ).thenAnswer((_) async {});

      final adapter = MediaStoreFactory.build(
        remoteConfig: remoteConfig,
        firebaseStorage: storage,
        cloudinaryCloudName: 'yugma-test',
        crashlytics: crashlytics,
      );

      expect(adapter, isA<MediaStoreCloudinaryFirebase>());
      verify(
        () => crashlytics.recordError(
          any<Object>(),
          any<StackTrace>(),
          reason: any<dynamic>(named: 'reason'),
        ),
      ).called(1);
    });

    test('unknown strategy without crashlytics still falls back gracefully', () {
      when(() => remoteConfig.getString('media_store_strategy'))
          .thenReturn('nope');

      final adapter = MediaStoreFactory.build(
        remoteConfig: remoteConfig,
        firebaseStorage: storage,
        cloudinaryCloudName: 'yugma-test',
      );

      expect(adapter, isA<MediaStoreCloudinaryFirebase>());
    });
  });
}
