// =============================================================================
// MediaStoreFactory — Remote Config-driven runtime selection.
//
// Mirrors AuthProviderFactory's shape (same Remote Config pattern, same
// fallback-with-Crashlytics-log on unknown strategy).
//
// PRD I6.6 AC #4: strategy selection via Remote Config.
// PRD I6.7 AC #7: `media_store_strategy` is one of the real-time kill-switch
//   flags and is consumed via Firestore onSnapshot with <5s propagation.
//   This factory reads the current Remote Config value at construction time;
//   the real-time flip is handled by the Phase 1.3 KillSwitchListener which
//   can rebuild the active adapter via a Riverpod provider when the flag
//   changes.
// =============================================================================

import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logging/logging.dart';

import 'media_store.dart';
import 'media_store_cloudinary_firebase.dart';
import 'media_store_r2.dart';

/// Strategy values. Mirrored in Remote Config under key `media_store_strategy`.
class MediaStoreStrategy {
  MediaStoreStrategy._();

  /// Default — Cloudinary catalog + Firebase Storage voice notes.
  /// Active at shop #1 through ~shop #20.
  static const String cloudinaryFirebase = 'cloudinary_firebase';

  /// R2 migration path. Activated at shop #25+ per SAD ADR-014.
  /// Stub in v1; real implementation in v1.5.
  static const String r2 = 'r2';

  /// The fallback strategy used when Remote Config returns empty or unknown.
  static const String defaultValue = cloudinaryFirebase;
}

/// Builds the active [MediaStore] based on Remote Config.
class MediaStoreFactory {
  MediaStoreFactory._();

  static final Logger _log = Logger('MediaStoreFactory');

  /// Read the strategy from Remote Config and return the matching adapter.
  ///
  /// MUST be called after `Firebase.initializeApp()` and after
  /// `RemoteConfigLoader.initialize()` so the value is current.
  ///
  /// [cloudinaryCloudName] is the Cloudinary account's cloud_name — required
  /// by the default implementation to build delivery URLs. Pass the dev / staging /
  /// prod value from your environment config. A placeholder cloud_name is
  /// acceptable in Phase 1 because `uploadCatalogImage` throws `notYetWired`
  /// and `getCatalogUrl` is a pure function that just embeds the name in a
  /// URL template.
  ///
  /// [isUploadKillSwitchActive] is an optional probe callback. When provided,
  /// the default implementation short-circuits `uploadCatalogImage` on kill-switch
  /// activation. The Phase 1.3 `KillSwitchListener` supplies this probe in
  /// production; unit tests can pass `() => false` or `() => true` directly.
  static MediaStore build({
    required FirebaseRemoteConfig remoteConfig,
    required FirebaseStorage firebaseStorage,
    required String cloudinaryCloudName,
    Future<bool> Function()? isUploadKillSwitchActive,
    FirebaseCrashlytics? crashlytics,
  }) {
    final strategy = remoteConfig.getString('media_store_strategy');
    final effective =
        strategy.isEmpty ? MediaStoreStrategy.defaultValue : strategy;

    _log.info('MediaStore strategy resolved to: $effective');

    switch (effective) {
      case MediaStoreStrategy.cloudinaryFirebase:
        return MediaStoreCloudinaryFirebase(
          firebaseStorage: firebaseStorage,
          cloudinaryCloudName: cloudinaryCloudName,
          isUploadKillSwitchActive: isUploadKillSwitchActive,
        );

      case MediaStoreStrategy.r2:
        return const MediaStoreR2();

      default:
        // Unknown strategy → log a Crashlytics warning and fall back.
        _log.warning(
          'Unknown media_store_strategy "$effective" — falling back to '
          '${MediaStoreStrategy.defaultValue}',
        );
        if (crashlytics != null) {
          unawaited(
            crashlytics.recordError(
              'Unknown media_store_strategy: $effective',
              StackTrace.current,
              reason: 'MediaStoreFactory unknown strategy fallback',
            ),
          );
        }
        return MediaStoreCloudinaryFirebase(
          firebaseStorage: firebaseStorage,
          cloudinaryCloudName: cloudinaryCloudName,
          isUploadKillSwitchActive: isUploadKillSwitchActive,
        );
    }
  }
}
