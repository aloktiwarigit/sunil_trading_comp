// =============================================================================
// FirebaseClient — wraps Firebase initialization + App Check.
//
// Single entry point for both customer_app and shopkeeper_app `main.dart` files.
// Ensures App Check is activated BEFORE any Firestore or Auth call.
// =============================================================================

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Wrapper around Firebase init + App Check activation.
class FirebaseClient {
  FirebaseClient._();

  static final Logger _log = Logger('FirebaseClient');
  static bool _initialized = false;

  /// Initialize Firebase and activate App Check.
  ///
  /// Must be called from `main()` before `runApp(...)`.
  ///
  /// In debug builds, App Check uses the debug provider so devs aren't
  /// locked out (PRD I6.10 AC #6).
  static Future<void> initialize({
    required FirebaseOptions options,
  }) async {
    if (_initialized) {
      _log.warning('FirebaseClient.initialize called twice — ignoring');
      return;
    }

    await Firebase.initializeApp(options: options);

    // App Check — Play Integrity (Android) + DeviceCheck (iOS) in release;
    // debug providers in debug builds (PRD I6.10 AC #4 + #6).
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode
          ? AppleProvider.debug
          : AppleProvider.deviceCheck,
    );

    _initialized = true;
    _log.info('Firebase + App Check initialized (debug=$kDebugMode)');
  }

  /// True after [initialize] completes successfully.
  static bool get isInitialized => _initialized;

  @visibleForTesting
  static void resetForTest() {
    _initialized = false;
  }
}
