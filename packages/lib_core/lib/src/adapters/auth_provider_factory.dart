// =============================================================================
// AuthProviderFactory — Remote Config-driven runtime selection.
//
// PRD I6.1 AC #4: runtime selection happens via
//   RemoteConfig.getString('auth_provider_strategy')
// PRD I6.1 Edge case #1: unknown strategy → fall back to `firebase` and log
// a warning to Crashlytics.
// =============================================================================

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:logging/logging.dart';

import 'auth_provider.dart';
import 'auth_provider_email_magic_link.dart';
import 'auth_provider_firebase.dart';
import 'auth_provider_msg91.dart';
import 'auth_provider_upi_only.dart';

/// Strategy values. Mirrored in Remote Config under key `auth_provider_strategy`.
class AuthProviderStrategy {
  AuthProviderStrategy._();

  /// Default — Firebase Phone Auth + Anonymous + Google.
  static const String firebase = 'firebase';

  /// MSG91 SMS fallback. Activated when 10k/mo Firebase quota is at 80%.
  static const String msg91 = 'msg91';

  /// Email magic link. Last resort.
  static const String email = 'email';

  /// UPI-only — R12 fallback if OTP cultural rejection > 30%.
  static const String upiOnly = 'upi_only';

  static const String defaultValue = firebase;
}

/// Builds the active [AuthProvider] based on Remote Config.
class AuthProviderFactory {
  AuthProviderFactory._();

  static final Logger _log = Logger('AuthProviderFactory');

  /// Read the strategy from Remote Config and return the matching adapter.
  ///
  /// MUST be called after `Firebase.initializeApp()` and after
  /// `RemoteConfigLoader.fetchAndActivate()` so the value is current.
  static AuthProvider build({
    required FirebaseRemoteConfig remoteConfig,
    required fb.FirebaseAuth firebaseAuth,
    String? msg91AuthKey,
    FirebaseCrashlytics? crashlytics,
  }) {
    final firebaseDelegate = AuthProviderFirebase(auth: firebaseAuth);

    final strategy = remoteConfig.getString('auth_provider_strategy');
    final effective =
        strategy.isEmpty ? AuthProviderStrategy.defaultValue : strategy;

    _log.info('AuthProvider strategy resolved to: $effective');

    switch (effective) {
      case AuthProviderStrategy.firebase:
        return firebaseDelegate;

      case AuthProviderStrategy.msg91:
        if (msg91AuthKey == null || msg91AuthKey.isEmpty) {
          _log.warning(
            'msg91 strategy requested but no msg91AuthKey provided — '
            'falling back to firebase',
          );
          crashlytics?.recordError(
            'msg91 strategy requested without auth key',
            StackTrace.current,
            reason: 'AuthProviderFactory misconfiguration',
          );
          return firebaseDelegate;
        }
        return AuthProviderMsg91(
          firebaseDelegate: firebaseDelegate,
          msg91AuthKey: msg91AuthKey,
        );

      case AuthProviderStrategy.email:
        return AuthProviderEmailMagicLink(firebaseDelegate: firebaseDelegate);

      case AuthProviderStrategy.upiOnly:
        return AuthProviderUpiOnly(firebaseDelegate: firebaseDelegate);

      default:
        // Unknown strategy → log a Crashlytics warning and fall back per
        // PRD I6.1 Edge case #1.
        _log.warning(
          'Unknown auth_provider_strategy "$effective" — falling back to firebase',
        );
        crashlytics?.recordError(
          'Unknown auth_provider_strategy: $effective',
          StackTrace.current,
          reason: 'AuthProviderFactory unknown strategy fallback',
        );
        return firebaseDelegate;
    }
  }
}
