// =============================================================================
// Observability — wires Crashlytics + Analytics + Performance for both apps.
//
// PRD I6.10 — single entry point so the customer_app and shopkeeper_app
// `main.dart` can call one method.
// =============================================================================

import 'dart:async';
import 'dart:isolate';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Bootstraps Crashlytics + Analytics + Performance.
///
/// Wires the Flutter framework error handler, Dart isolate error handler,
/// and PlatformDispatcher.onError to Crashlytics so nothing escapes.
class Observability {
  Observability._();

  static final Logger _log = Logger('Observability');
  static bool _wired = false;

  /// Wire all three SDKs. Must be called from `main()` after
  /// [FirebaseClient.initialize] and inside a `runZonedGuarded` block.
  static Future<void> initialize() async {
    if (_wired) {
      _log.warning('Observability.initialize called twice — ignoring');
      return;
    }

    // Crashlytics is disabled in debug to avoid noise during development.
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);

    // Catch Flutter framework errors.
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      FirebaseCrashlytics.instance.recordFlutterError(details);
    };

    // Catch errors outside the Flutter framework (raw isolate / async).
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Catch errors from background isolates.
    Isolate.current.addErrorListener(
      RawReceivePort((dynamic pair) {
        final list = pair as List<dynamic>;
        final error = list.first;
        final stack = list.last as String?;
        FirebaseCrashlytics.instance.recordError(
          error,
          stack == null ? null : StackTrace.fromString(stack),
          fatal: true,
        );
      }).sendPort,
    );

    // Performance auto-traces (per PRD I6.10 AC #3).
    await FirebasePerformance.instance
        .setPerformanceCollectionEnabled(!kDebugMode);

    // Analytics — start a default screen on launch so funnels work.
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(!kDebugMode);

    _wired = true;
    _log.info('Observability initialized (debug=$kDebugMode)');
  }

  /// Convenience accessor for Analytics — use this rather than the raw SDK.
  static FirebaseAnalytics get analytics => FirebaseAnalytics.instance;

  /// Convenience accessor for Crashlytics.
  static FirebaseCrashlytics get crashlytics => FirebaseCrashlytics.instance;

  @visibleForTesting
  static void resetForTest() {
    _wired = false;
  }
}
