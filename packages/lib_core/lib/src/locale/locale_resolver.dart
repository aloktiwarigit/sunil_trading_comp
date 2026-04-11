// =============================================================================
// LocaleResolver — selects the active AppStrings implementation based on
// Remote Config `defaultLocale` flag (SAD v1.0.4 §5 FeatureFlags).
//
// Default is `hi` (Devanagari-first) per Brief Constraint 4. If Sprint 0
// closes END STATE B (Hindi-native design capacity not secured), the flag
// flips to `en` and this resolver returns the English implementation as
// the customer app's default locale.
//
// The customer can always override at runtime via the in-app Hindi/English
// toggle on the Bharosa landing (B1.2 AC #7 + v1.0.3 patch) — that toggle
// persists in shared_preferences and takes precedence over the Remote
// Config default on subsequent launches.
// =============================================================================

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:logging/logging.dart';

import '../feature_flags/feature_flags.dart';
import 'strings_base.dart';
import 'strings_en.dart';
import 'strings_hi.dart';

/// Selects an [AppStrings] implementation based on Remote Config or an
/// explicit user override.
class LocaleResolver {
  LocaleResolver._();

  static final Logger _log = Logger('LocaleResolver');

  /// Canonical Devanagari implementation — the Brief Constraint 4 default.
  static const AppStringsHi hi = AppStringsHi();

  /// Canonical English implementation — used for the toggle and for the
  /// Constraint 15 END STATE B fallback.
  static const AppStringsEn en = AppStringsEn();

  /// Resolve the active AppStrings instance.
  ///
  /// [remoteConfig]: the FirebaseRemoteConfig instance from
  /// `RemoteConfigLoader.initialize()`. Used to read `defaultLocale`.
  ///
  /// [userOverride]: optional explicit locale code (`hi` or `en`) from
  /// the user's toggle preference (stored in shared_preferences). If
  /// present, overrides the Remote Config default.
  ///
  /// **Precedence:** `userOverride` > `remoteConfig.defaultLocale` > `hi`.
  static AppStrings resolve({
    required FirebaseRemoteConfig remoteConfig,
    String? userOverride,
  }) {
    // User toggle wins if present and valid.
    if (userOverride != null && userOverride.isNotEmpty) {
      final resolved = _resolveFromCode(userOverride);
      _log.info('LocaleResolver: user override = $userOverride');
      return resolved;
    }

    // Otherwise defer to Remote Config. Empty string = flag not set yet
    // (first launch offline) → fall through to the Brief default `hi`.
    final flag = remoteConfig.getString(FeatureFlags.defaultLocale);
    if (flag.isEmpty) {
      _log.fine('LocaleResolver: defaultLocale flag empty → hi');
      return hi;
    }

    final resolved = _resolveFromCode(flag);
    _log.info('LocaleResolver: remote_config defaultLocale = $flag');
    return resolved;
  }

  /// Pure-function code → AppStrings mapping. Used by both the resolver
  /// and by tests that want to bypass Remote Config entirely.
  static AppStrings forCode(String code) => _resolveFromCode(code);

  static AppStrings _resolveFromCode(String code) {
    switch (code.toLowerCase()) {
      case 'hi':
        return hi;
      case 'en':
        return en;
      default:
        _log.warning(
          'LocaleResolver: unknown locale code "$code" — falling back to hi',
        );
        return hi;
    }
  }
}
