// =============================================================================
// FeatureFlags — string constants for the Remote Config flag set.
//
// All v1 stories that ship behind a flag MUST reference one of these constants
// (per PRD Standing Rule #6). Adding a new flag means adding it here AND in
// RemoteConfigLoader._defaults.
// =============================================================================

/// Constants for the Remote Config feature flag set.
class FeatureFlags {
  FeatureFlags._();

  // ---------- Adapter strategies ----------
  static const String authProviderStrategy = 'auth_provider_strategy';
  static const String commsChannelStrategy = 'comms_channel_strategy';
  static const String mediaStoreStrategy = 'media_store_strategy';

  // ---------- Locale (SAD v1.0.4 + Brief Constraint 15 + PRD I6.11) ----------

  /// Default locale for the customer app. `"hi"` = Hindi-first (Constraint 4
  /// honored), `"en"` = English-first (Constraint 15 fallback triggered
  /// because Hindi-native design capacity was not secured before Sprint 1).
  /// Default: `"hi"`. See sprint-0-i6-11-checklist.md for the decision tree.
  static const String defaultLocale = 'default_locale';

  // ---------- Two-pillar features ----------

  /// Decision Circle (Pariwar pillar) — feature-flagged per ADR-009.
  /// Default: false. Flipped on once R11 hypothesis is validated with
  /// real shopkeepers.
  static const String decisionCircleEnabled = 'decision_circle_enabled';

  /// OTP at commit moment — feature-flagged per R12.
  /// Default: true. Flipped off if cultural rejection > 30%.
  static const String otpAtCommitEnabled = 'otp_at_commit_enabled';

  /// In-app chat (Sunil-bhaiya Ka Kamra). Feature-flagged per R13.
  /// Default: true. Flipped off if WhatsApp competition wins.
  static const String inAppChatEnabled = 'in_app_chat_enabled';

  /// Elder accessibility tier (P2.8 + P2.3). Default: true.
  static const String elderTierEnabled = 'elder_tier_enabled';

  /// Golden Hour photo capture flow (S4.5). Default: true.
  static const String goldenHourPhotoEnabled = 'golden_hour_photo_enabled';

  // ---------- Cloud Function feature gates ----------

  /// C-6: joinDecisionCircle Cloud Function — gates the real UID merger.
  /// Default: false. Flipped on once the function is deployed to dev.
  static const String joinDecisionCircleEnabled =
      'join_decision_circle_enabled';

  // ---------- Cost / quota guardrails ----------

  /// Master kill-switch (set by `killSwitchOnBudgetAlert` Cloud Function).
  static const String killSwitchActive = 'kill_switch_active';

  static const String cloudinaryUploadsBlocked = 'cloudinary_uploads_blocked';
  static const String firestoreWritesBlocked = 'firestore_writes_blocked';

  // ---------- Media adapter config ----------

  /// Cloudinary cloud_name for catalog image delivery URLs.
  /// Default: dev cloud name. Overridden per environment in Remote Config.
  static const String cloudinaryCloudName = 'cloudinary_cloud_name';
}
