// =============================================================================
// CommsChannelFactory tests — PRD I6.5 strategy resolution via Remote Config.
// =============================================================================

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_core/src/adapters/comms_channel_factory.dart';
import 'package:lib_core/src/adapters/comms_channel_firestore.dart';
import 'package:lib_core/src/adapters/comms_channel_whatsapp.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemoteConfig extends Mock implements FirebaseRemoteConfig {}

class _MockCrashlytics extends Mock implements FirebaseCrashlytics {}

class _FakeStackTrace extends Fake implements StackTrace {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeStackTrace());
  });

  group('CommsChannelFactory', () {
    late _MockRemoteConfig remoteConfig;
    late FakeFirebaseFirestore firestore;
    late _MockCrashlytics crashlytics;

    setUp(() {
      remoteConfig = _MockRemoteConfig();
      firestore = FakeFirebaseFirestore();
      crashlytics = _MockCrashlytics();
    });

    test('empty Remote Config value → falls through to default firestore', () {
      when(() => remoteConfig.getString('comms_channel_strategy'))
          .thenReturn('');

      final adapter = CommsChannelFactory.build(
        remoteConfig: remoteConfig,
        firestore: firestore,
      );

      expect(adapter, isA<CommsChannelFirestore>());
    });

    test('explicit firestore strategy returns CommsChannelFirestore', () {
      when(() => remoteConfig.getString('comms_channel_strategy'))
          .thenReturn('firestore');

      final adapter = CommsChannelFactory.build(
        remoteConfig: remoteConfig,
        firestore: firestore,
      );

      expect(adapter, isA<CommsChannelFirestore>());
    });

    test('explicit whatsapp_wa_me strategy returns CommsChannelWhatsApp', () {
      when(() => remoteConfig.getString('comms_channel_strategy'))
          .thenReturn('whatsapp_wa_me');

      final adapter = CommsChannelFactory.build(
        remoteConfig: remoteConfig,
        firestore: firestore,
      );

      expect(adapter, isA<CommsChannelWhatsApp>());
    });

    test(
      'unknown strategy falls back to firestore AND logs to Crashlytics',
      () {
        when(() => remoteConfig.getString('comms_channel_strategy'))
            .thenReturn('smoke-signals');
        when(
          () => crashlytics.recordError(
            any<Object>(),
            any<StackTrace>(),
            reason: any<dynamic>(named: 'reason'),
          ),
        ).thenAnswer((_) async {});

        final adapter = CommsChannelFactory.build(
          remoteConfig: remoteConfig,
          firestore: firestore,
          crashlytics: crashlytics,
        );

        expect(adapter, isA<CommsChannelFirestore>());
        verify(
          () => crashlytics.recordError(
            any<Object>(),
            any<StackTrace>(),
            reason: any<dynamic>(named: 'reason'),
          ),
        ).called(1);
      },
    );

    test(
      'unknown strategy without crashlytics still falls back gracefully',
      () {
        when(() => remoteConfig.getString('comms_channel_strategy'))
            .thenReturn('bad-value');

        final adapter = CommsChannelFactory.build(
          remoteConfig: remoteConfig,
          firestore: firestore,
        );

        expect(adapter, isA<CommsChannelFirestore>());
      },
    );
  });
}
