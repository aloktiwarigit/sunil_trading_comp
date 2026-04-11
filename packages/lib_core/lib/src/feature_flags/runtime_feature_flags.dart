// =============================================================================
// RuntimeFeatureFlags — Freezed model for /shops/{shopId}/featureFlags/runtime.
//
// This is the Firestore-resident mirror of the Remote Config flag set.
// Unlike Remote Config (which polls with a 1-hour minimum fetch interval),
// this document is watched via `onSnapshot` for real-time (<5s) propagation
// of kill-switch flags per PRD I6.7 AC #7 + SAD ADR-007 v1.0.4.
//
// Written by the `killSwitchOnBudgetAlert` Cloud Function (SAD §7 Fn 1) via
// the admin SDK. Client writes are denied at the rule layer (firestore.rules
// line 152: `allow write: if false`). Clients only READ this doc.
//
// The full canonical flag list lives in the SAD §5 FeatureFlags schema and
// the `FeatureFlags` string constants in `feature_flags.dart`. This model
// captures the subset of flags that matter for real-time kill-switch
// behavior + adapter strategy selection — the flags that must propagate in
// <5s per PRD I6.7 AC #7.
//
// Slow-changing cosmetic flags (`decisionCircleEnabled`, `guestModeEnabled`,
// `voiceSearchEnabled`, `arPlacementEnabled`, `defaultLocale`) stay on
// Remote Config and do NOT live in this model — they are read via
// `FirebaseRemoteConfig.getString(...)` at boot + 1-hour re-fetch intervals.
// =============================================================================

import 'package:freezed_annotation/freezed_annotation.dart';

part 'runtime_feature_flags.freezed.dart';
part 'runtime_feature_flags.g.dart';

/// The real-time subset of the feature flag document. Every field defaults
/// to a safe value so a missing or partial document degrades gracefully
/// without throwing or blocking adapters from starting up.
@freezed
class RuntimeFeatureFlags with _$RuntimeFeatureFlags {
  /// Construct a snapshot of the runtime flags. All fields default to safe
  /// values — missing/partial docs resolve to "nothing is kill-switched,
  /// default adapter strategies selected."
  const factory RuntimeFeatureFlags({
    // ---- Kill-switch flags ----

    /// Master kill-switch (set to true by `killSwitchOnBudgetAlert` Cloud
    /// Function when the $1/month Blaze budget cap is hit).
    @Default(false) bool killSwitchActive,

    /// Cloudinary catalog-image uploads are blocked (cost circuit breaker).
    /// Consumed by `MediaStoreCloudinaryFirebase.uploadCatalogImage`.
    @Default(false) bool cloudinaryUploadsBlocked,

    /// Firestore writes are blocked globally (emergency freeze).
    /// Consumed by `CommsChannelFirestore.sendText` / `sendVoiceNote`.
    @Default(false) bool firestoreWritesBlocked,

    // ---- Adapter strategy flags (real-time swappable) ----

    /// Auth provider strategy. Real-time because a quota breach on Firebase
    /// Phone Auth should flip to MSG91 (or upiOnly) within 5 seconds of the
    /// ops team hitting the switch — waiting for a Remote Config poll would
    /// burn more SMS charges during the gap.
    @Default('firebase') String authProviderStrategy,

    /// Comms channel strategy. Real-time because R13 (WhatsApp eats
    /// in-app chat) may be triggered during a live customer session and
    /// the change needs to be visible immediately.
    @Default('firestore') String commsChannelStrategy,

    /// Media store strategy. Real-time because a Cloudinary credit breach
    /// should swap to R2 without waiting for Remote Config polling.
    @Default('cloudinary_firebase') String mediaStoreStrategy,

    /// OTP at commit is one of the R12 kill-switches — real-time because
    /// a cultural-rejection spike in the commit funnel needs immediate
    /// fallback to UPI-metadata-only verification.
    @Default(true) bool otpAtCommitEnabled,

    // ---- Metadata ----

    /// Server timestamp of the last write. Used to detect stale snapshots.
    DateTime? updatedAt,

    /// UID of the operator (or Cloud Function identifier) that last wrote
    /// this doc. Audit trail.
    String? updatedByUid,
  }) = _RuntimeFeatureFlags;

  /// JSON round-trip for Firestore deserialization.
  factory RuntimeFeatureFlags.fromJson(Map<String, dynamic> json) =>
      _$RuntimeFeatureFlagsFromJson(json);

  const RuntimeFeatureFlags._();

  /// Safe defaults used when no document exists yet (first-boot / fresh
  /// tenant). Every flag is in the "nothing is kill-switched, default
  /// strategies selected" state.
  static const RuntimeFeatureFlags safeDefaults = RuntimeFeatureFlags();
}
