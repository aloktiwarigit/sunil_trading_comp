// =============================================================================
// CommsChannelFactory — Remote Config-driven runtime selection.
//
// Mirrors MediaStoreFactory + AuthProviderFactory shapes. Strategy flag
// `comms_channel_strategy` is one of the real-time kill-switch-aware flags
// per PRD I6.7 AC #7 — when `firestore_writes_blocked` OR the strategy
// itself changes, the Phase 1.3 KillSwitchListener triggers a rebuild of
// the active adapter via a Riverpod provider.
// =============================================================================

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:logging/logging.dart';

import 'comms_channel.dart';
import 'comms_channel_firestore.dart';
import 'comms_channel_whatsapp.dart';

/// Strategy values. Mirrored in Remote Config under key `comms_channel_strategy`.
class CommsChannelStrategy {
  CommsChannelStrategy._();

  /// Default — in-app Firestore real-time chat (the Sunil-bhaiya Ka Kamra
  /// thread). Active from shop #1.
  static const String firestore = 'firestore';

  /// R13 fallback — launch the native WhatsApp app via a `wa.me` deep link.
  /// Activated when in-app chat loses to WhatsApp habituation (measured in
  /// Month 3 / Month 6 telemetry per Brief §9 R13).
  static const String whatsappWaMe = 'whatsapp_wa_me';

  /// The fallback strategy used when Remote Config returns empty or unknown.
  static const String defaultValue = firestore;
}

/// Builds the active [CommsChannel] based on Remote Config.
class CommsChannelFactory {
  CommsChannelFactory._();

  static final Logger _log = Logger('CommsChannelFactory');

  /// Read the strategy from Remote Config and return the matching adapter.
  ///
  /// MUST be called after `Firebase.initializeApp()` and after
  /// `RemoteConfigLoader.initialize()`.
  ///
  /// [isWriteKillSwitchActive] is an optional probe for the
  /// `firestore_writes_blocked` flag. In production, supply the probe
  /// from the Phase 1.3 KillSwitchListener; in tests, pass a simple
  /// lambda or omit to default to false.
  static CommsChannel build({
    required FirebaseRemoteConfig remoteConfig,
    required FirebaseFirestore firestore,
    FutureOr<bool> Function()? isWriteKillSwitchActive,
    FirebaseCrashlytics? crashlytics,
  }) {
    final strategy = remoteConfig.getString('comms_channel_strategy');
    final effective =
        strategy.isEmpty ? CommsChannelStrategy.defaultValue : strategy;

    _log.info('CommsChannel strategy resolved to: $effective');

    switch (effective) {
      case CommsChannelStrategy.firestore:
        return CommsChannelFirestore(
          firestore: firestore,
          isWriteKillSwitchActive: isWriteKillSwitchActive,
        );

      case CommsChannelStrategy.whatsappWaMe:
        return CommsChannelWhatsApp(firestore: firestore);

      default:
        _log.warning(
          'Unknown comms_channel_strategy "$effective" — falling back to '
          '${CommsChannelStrategy.defaultValue}',
        );
        if (crashlytics != null) {
          unawaited(
            crashlytics.recordError(
              'Unknown comms_channel_strategy: $effective',
              StackTrace.current,
              reason: 'CommsChannelFactory unknown strategy fallback',
            ),
          );
        }
        return CommsChannelFirestore(
          firestore: firestore,
          isWriteKillSwitchActive: isWriteKillSwitchActive,
        );
    }
  }
}
