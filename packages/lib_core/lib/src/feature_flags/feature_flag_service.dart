// =============================================================================
// FeatureFlagService — centralized typed access to all feature flags.
//
// Wraps FirebaseRemoteConfig (slow-changing flags fetched on app start)
// and KillSwitchListener (real-time Firestore-driven flags for cost control).
//
// Provides a single injection point for tests via FeatureFlagServiceStub.
// =============================================================================

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:lib_core/src/feature_flags/feature_flags.dart';

/// Centralized typed access to all feature flags.
class FeatureFlagService {
  FeatureFlagService({
    required FirebaseRemoteConfig remoteConfig,
  }) : _remoteConfig = remoteConfig;

  final FirebaseRemoteConfig _remoteConfig;

  // ---------- Adapter strategies ----------
  String get authProviderStrategy =>
      _remoteConfig.getString(FeatureFlags.authProviderStrategy);
  String get commsChannelStrategy =>
      _remoteConfig.getString(FeatureFlags.commsChannelStrategy);
  String get mediaStoreStrategy =>
      _remoteConfig.getString(FeatureFlags.mediaStoreStrategy);

  // ---------- Locale ----------
  String get defaultLocale =>
      _remoteConfig.getString(FeatureFlags.defaultLocale);

  // ---------- Feature gates ----------
  bool get decisionCircleEnabled =>
      _remoteConfig.getBool(FeatureFlags.decisionCircleEnabled);
  bool get otpAtCommitEnabled =>
      _remoteConfig.getBool(FeatureFlags.otpAtCommitEnabled);
  bool get inAppChatEnabled =>
      _remoteConfig.getBool(FeatureFlags.inAppChatEnabled);
  bool get elderTierEnabled =>
      _remoteConfig.getBool(FeatureFlags.elderTierEnabled);
  bool get goldenHourPhotoEnabled =>
      _remoteConfig.getBool(FeatureFlags.goldenHourPhotoEnabled);
  bool get joinDecisionCircleEnabled =>
      _remoteConfig.getBool(FeatureFlags.joinDecisionCircleEnabled);

  // ---------- Cost / quota guardrails ----------
  bool get killSwitchActive =>
      _remoteConfig.getBool(FeatureFlags.killSwitchActive);
  bool get cloudinaryUploadsBlocked =>
      _remoteConfig.getBool(FeatureFlags.cloudinaryUploadsBlocked);
  bool get firestoreWritesBlocked =>
      _remoteConfig.getBool(FeatureFlags.firestoreWritesBlocked);

  // ---------- Media config ----------
  String get cloudinaryCloudName =>
      _remoteConfig.getString(FeatureFlags.cloudinaryCloudName);
}

/// Test stub that allows per-test flag overrides.
class FeatureFlagServiceStub implements FeatureFlagService {
  FeatureFlagServiceStub({
    this.authProviderStrategy = 'firebase',
    this.commsChannelStrategy = 'firestore',
    this.mediaStoreStrategy = 'cloudinary_firebase',
    this.defaultLocale = 'hi',
    this.decisionCircleEnabled = false,
    this.otpAtCommitEnabled = true,
    this.inAppChatEnabled = true,
    this.elderTierEnabled = true,
    this.goldenHourPhotoEnabled = true,
    this.joinDecisionCircleEnabled = false,
    this.killSwitchActive = false,
    this.cloudinaryUploadsBlocked = false,
    this.firestoreWritesBlocked = false,
    this.cloudinaryCloudName = 'yugma-dukaan-dev',
  });

  @override
  String authProviderStrategy;
  @override
  String commsChannelStrategy;
  @override
  String mediaStoreStrategy;
  @override
  String defaultLocale;
  @override
  bool decisionCircleEnabled;
  @override
  bool otpAtCommitEnabled;
  @override
  bool inAppChatEnabled;
  @override
  bool elderTierEnabled;
  @override
  bool goldenHourPhotoEnabled;
  @override
  bool joinDecisionCircleEnabled;
  @override
  bool killSwitchActive;
  @override
  bool cloudinaryUploadsBlocked;
  @override
  bool firestoreWritesBlocked;
  @override
  String cloudinaryCloudName;

  // Private member required by implements — unused by stub (all getters overridden above).
  @override
  // ignore: unused_field
  FirebaseRemoteConfig get _remoteConfig =>
      throw UnsupportedError('Stub does not use RemoteConfig');
}
