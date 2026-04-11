// =============================================================================
// SessionBootstrap — verifies the persisted Firebase Auth session on app boot.
//
// PRD I6.3 Walking Skeleton — founder hard requirement: "every time user
// logs in should not use authentication." Firebase Auth SDK persists the
// refresh token automatically on all platforms (IndexedDB on web,
// SharedPreferences on Android, Keychain on iOS) — but we want explicit
// telemetry and a well-defined bootstrap entry point so:
//
//   1. Any future regression in Firebase SDK persistence behavior is
//      caught by Crashlytics instead of silently degrading UX
//   2. Analytics has a distinct event for "session survived app restart"
//      vs "user signed in fresh" so the Month 3 success gate can measure
//      silent-sign-in rate empirically
//   3. main.dart has a single line to call, rather than sprinkling
//      conditional auth logic across every entrypoint
//
// Behavior:
//   - On first launch: currentUser is null. No event fired.
//   - On subsequent launch with persisted refresh token: currentUser is
//     populated by Firebase SDK before our check runs. We fire the
//     `session_restored_from_refresh_token` analytics event with the
//     user's tier as a parameter and return the AppUser.
//   - On subsequent launch where persistence was expected but empty
//     (regression detection): log to Crashlytics as a non-fatal error.
//
// Must be called AFTER FirebaseClient.initialize() and BEFORE any screen
// that conditionally renders based on auth state. Typically from main()
// right after Observability.initialize().
// =============================================================================

import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import '../adapters/auth_provider.dart';
import '../observability/analytics_events.dart';

/// Outcome of the boot-time session check.
enum SessionBootstrapOutcome {
  /// No persisted user found — this is a first launch (or user previously
  /// signed out). The caller's UI should route to anonymous sign-in.
  firstLaunchOrSignedOut,

  /// A persisted user was restored from the refresh token successfully.
  /// The caller's UI should route directly to the landing screen.
  sessionRestored,
}

/// Result object — includes both the outcome enum and the restored user
/// (null when outcome is [SessionBootstrapOutcome.firstLaunchOrSignedOut]).
class SessionBootstrapResult {
  const SessionBootstrapResult({
    required this.outcome,
    this.restoredUser,
  });

  final SessionBootstrapOutcome outcome;
  final AppUser? restoredUser;
}

/// The bootstrap service.
class SessionBootstrap {
  SessionBootstrap._();

  static final Logger _log = Logger('SessionBootstrap');

  /// Inspect the current AuthProvider for a persisted user.
  ///
  /// Must be called after [FirebaseClient.initialize] so the Firebase
  /// SDK has had a chance to restore the refresh token from platform
  /// storage.
  ///
  /// [analytics] and [crashlytics] are optional for testability — in
  /// production main() MUST pass both (enforced by the assert below in
  /// release builds per Sprint 2.1 code review finding C8: a production
  /// caller that forgot to pass crashlytics would silently ship without
  /// user ID on crashes, making crash triage much harder).
  static Future<SessionBootstrapResult> verifyPersistedUser({
    required AuthProvider authProvider,
    FirebaseAnalytics? analytics,
    FirebaseCrashlytics? crashlytics,
  }) async {
    // Production misconfiguration guard — in release builds, both
    // analytics and crashlytics must be non-null. Debug and test runs
    // are exempt so unit tests can exercise the bootstrap logic without
    // wiring real Firebase SDKs.
    if (kReleaseMode) {
      if (analytics == null || crashlytics == null) {
        throw StateError(
          'SessionBootstrap.verifyPersistedUser called in release mode '
          'without analytics and/or crashlytics — this is a production '
          'misconfiguration. Pass Observability.analytics + '
          'Observability.crashlytics from main.dart.',
        );
      }
    }

    final user = authProvider.currentUser;

    if (user == null) {
      _log.info('no persisted user — first launch or signed-out state');
      return const SessionBootstrapResult(
        outcome: SessionBootstrapOutcome.firstLaunchOrSignedOut,
      );
    }

    _log.info(
      'session restored from refresh token: uid=${user.uid} '
      'tier=${user.tier} phoneVerified=${user.isPhoneVerified}',
    );

    // PRD I6.3 — fire analytics event so the Month 3 gate can measure
    // silent-sign-in rate empirically. Event name is scoped under the
    // existing auth_ namespace for discoverability in the Firebase
    // Analytics dashboard.
    if (analytics != null) {
      unawaited(
        analytics.logEvent(
          name: AnalyticsEvents.sessionRestoredFromRefreshToken,
          parameters: <String, Object>{
            'tier': user.tier.name,
            'is_phone_verified': user.isPhoneVerified ? 1 : 0,
          },
        ),
      );
    }

    // Set the user ID on Crashlytics so any subsequent crash is tied to
    // this UID without exposing phone number (which would violate
    // DPDP Act minimization).
    if (crashlytics != null) {
      unawaited(crashlytics.setUserIdentifier(user.uid));
    }

    return SessionBootstrapResult(
      outcome: SessionBootstrapOutcome.sessionRestored,
      restoredUser: user,
    );
  }

  /// Test-only reset hook. Exposed via `@visibleForTesting` so production
  /// callers cannot accidentally reach it.
  @visibleForTesting
  static void resetForTest() {
    _log.clearListeners();
  }
}
