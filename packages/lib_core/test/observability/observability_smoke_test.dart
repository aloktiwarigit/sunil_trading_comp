// =============================================================================
// observability smoke test — PRD I6.10 coverage.
//
// Deliberate scope: this is a SHAPE test on the Observability + analytics
// event constants. Real Crashlytics/Analytics/Performance wiring requires
// a live Firebase instance and cannot be unit-tested meaningfully — the
// integration test lives in ci-flutter.yml via `flutter build apk --debug`
// which fails if the SDKs misconfigure.
//
// What this test verifies (PRD I6.10 AC #2):
//   - All 9 required analytics event constants exist
//   - Constants use the expected naming convention (snake_case)
//   - No duplicate values
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:lib_core/src/observability/analytics_events.dart';

void main() {
  group('AnalyticsEvents — PRD I6.10 AC #2 coverage', () {
    // All 9 required events from PRD I6.10 AC #2
    const requiredEvents = <String>{
      'auth_anonymous_signed_in',
      'auth_phone_otp_requested',
      'auth_phone_verified',
      'project_created',
      'project_committed',
      'decision_circle_persona_switched',
      'voice_note_recorded',
      'udhaar_recorded',
      'feature_flag_swap_triggered',
    };

    test('all 9 required events are defined', () {
      final defined = <String>{
        AnalyticsEvents.authAnonymousSignedIn,
        AnalyticsEvents.authPhoneOtpRequested,
        AnalyticsEvents.authPhoneVerified,
        AnalyticsEvents.projectCreated,
        AnalyticsEvents.projectCommitted,
        AnalyticsEvents.decisionCirclePersonaSwitched,
        AnalyticsEvents.voiceNoteRecorded,
        AnalyticsEvents.udhaarRecorded,
        AnalyticsEvents.featureFlagSwapTriggered,
      };

      // Must contain all required events; additional Sprint-added events
      // (e.g. session_restored_from_refresh_token added in Sprint 2.2) are
      // allowed and the set equality check below uses requiredEvents as
      // a subset check implicitly — we only assert the required ones are
      // all present.
      expect(defined, equals(requiredEvents));
    });

    test('Sprint 2.2 added session_restored_from_refresh_token', () {
      // PRD I6.3 — fired by SessionBootstrap.verifyPersistedUser when a
      // refresh-token-persisted user is loaded on app launch.
      expect(
        AnalyticsEvents.sessionRestoredFromRefreshToken,
        equals('session_restored_from_refresh_token'),
      );
      // Snake-case + under 40 chars
      expect(
        RegExp(r'^[a-z][a-z0-9_]*$')
            .hasMatch(AnalyticsEvents.sessionRestoredFromRefreshToken),
        isTrue,
      );
      expect(
        AnalyticsEvents.sessionRestoredFromRefreshToken.length,
        lessThanOrEqualTo(40),
      );
    });

    test('every event name is snake_case', () {
      final all = <String>[
        AnalyticsEvents.authAnonymousSignedIn,
        AnalyticsEvents.authPhoneOtpRequested,
        AnalyticsEvents.authPhoneVerified,
        AnalyticsEvents.projectCreated,
        AnalyticsEvents.projectCommitted,
        AnalyticsEvents.decisionCirclePersonaSwitched,
        AnalyticsEvents.voiceNoteRecorded,
        AnalyticsEvents.udhaarRecorded,
        AnalyticsEvents.featureFlagSwapTriggered,
      ];

      final snakeCase = RegExp(r'^[a-z][a-z0-9_]*$');
      for (final name in all) {
        expect(
          snakeCase.hasMatch(name),
          isTrue,
          reason:
              '"$name" is not snake_case — fails Firebase Analytics name convention',
        );
      }
    });

    test('no duplicate event names', () {
      final all = <String>[
        AnalyticsEvents.authAnonymousSignedIn,
        AnalyticsEvents.authPhoneOtpRequested,
        AnalyticsEvents.authPhoneVerified,
        AnalyticsEvents.projectCreated,
        AnalyticsEvents.projectCommitted,
        AnalyticsEvents.decisionCirclePersonaSwitched,
        AnalyticsEvents.voiceNoteRecorded,
        AnalyticsEvents.udhaarRecorded,
        AnalyticsEvents.featureFlagSwapTriggered,
      ];

      expect(all.length, equals(all.toSet().length));
    });

    test('every name fits Firebase Analytics 40-char constraint', () {
      final all = <String>[
        AnalyticsEvents.authAnonymousSignedIn,
        AnalyticsEvents.authPhoneOtpRequested,
        AnalyticsEvents.authPhoneVerified,
        AnalyticsEvents.projectCreated,
        AnalyticsEvents.projectCommitted,
        AnalyticsEvents.decisionCirclePersonaSwitched,
        AnalyticsEvents.voiceNoteRecorded,
        AnalyticsEvents.udhaarRecorded,
        AnalyticsEvents.featureFlagSwapTriggered,
      ];

      for (final name in all) {
        expect(
          name.length,
          lessThanOrEqualTo(40),
          reason: '"$name" exceeds Firebase Analytics 40-char name limit',
        );
      }
    });
  });
}
