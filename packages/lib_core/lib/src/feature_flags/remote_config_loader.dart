// =============================================================================
// RemoteConfigLoader — wraps firebase_remote_config with sensible defaults
// for the Yugma Dukaan feature-flag set.
//
// Defaults are baked here so the first launch (no network yet) still gets
// known-good values. Network-fetched values override on next activation.
// =============================================================================

import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:logging/logging.dart';

import '../adapters/auth_provider_factory.dart';
import 'feature_flags.dart';

/// Wraps Remote Config init + default registration.
class RemoteConfigLoader {
  RemoteConfigLoader._();

  static final Logger _log = Logger('RemoteConfigLoader');

  /// Default values applied on first launch (offline-safe).
  static final Map<String, Object> _defaults = <String, Object>{
    // ---- Adapter selection ----
    'auth_provider_strategy': AuthProviderStrategy.firebase,
    'comms_channel_strategy': 'firestore', // vs 'whatsapp_wa_me'
    'media_store_strategy': 'cloudinary_firebase', // vs 'r2'

    // ---- Locale (SAD v1.0.4 + Brief Constraint 15 fallback) ----
    // Default "hi" = Hindi-first honors Constraint 4.
    // Flipped to "en" only if Hindi-native design capacity wasn't secured
    // before Sprint 1 (see sprint-0-i6-11-checklist.md END STATE B).
    FeatureFlags.defaultLocale: 'hi',

    // ---- Feature flags from PRD standing rules ----
    FeatureFlags.decisionCircleEnabled: false,
    FeatureFlags.otpAtCommitEnabled: true,
    FeatureFlags.inAppChatEnabled: true,
    FeatureFlags.elderTierEnabled: true,
    FeatureFlags.goldenHourPhotoEnabled: true,

    // ---- Cost / quota guardrails ----
    'kill_switch_active': false,
    'cloudinary_uploads_blocked': false,
    'firestore_writes_blocked': false,
  };

  /// Initialize Remote Config: set defaults, configure fetch interval,
  /// fetch + activate.
  ///
  /// MUST be called after `Firebase.initializeApp()` and BEFORE
  /// `AuthProviderFactory.build(...)`.
  static Future<FirebaseRemoteConfig> initialize() async {
    final config = FirebaseRemoteConfig.instance;

    await config.setDefaults(_defaults);
    await config.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        // 1 hour minimum between fetches in production. In debug, fetch every time.
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );

    try {
      final activated = await config.fetchAndActivate();
      _log.info('Remote Config fetched and activated: $activated');
    } on Object catch (e, st) {
      // First launch with no network is the common case — fall back to defaults.
      _log.warning('Remote Config fetchAndActivate failed: $e\n$st');
    }

    return config;
  }
}
