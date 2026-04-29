// =============================================================================
// AnalyticsEvents — string constants for the 9 key Analytics events.
//
// PRD I6.10 AC #2 enumerates these. Every event sent must use a constant
// from this file so we can grep them later.
// =============================================================================

/// Constants for Firebase Analytics custom events.
class AnalyticsEvents {
  AnalyticsEvents._();

  // ---------- Auth funnel ----------
  static const String authAnonymousSignedIn = 'auth_anonymous_signed_in';
  static const String authPhoneOtpRequested = 'auth_phone_otp_requested';
  static const String authPhoneVerified = 'auth_phone_verified';

  // ---------- Project funnel ----------
  static const String projectCreated = 'project_created';
  static const String projectCommitted = 'project_committed';

  // ---------- Decision Circle ----------
  static const String decisionCirclePersonaSwitched =
      'decision_circle_persona_switched';

  // ---------- Voice notes (Bharosa pillar) ----------
  static const String voiceNoteRecorded = 'voice_note_recorded';

  // ---------- Udhaar (accounting mirror) ----------
  static const String udhaarRecorded = 'udhaar_recorded';

  // ---------- Adapter swaps (R8 / R12 / R13 mitigation telemetry) ----------
  static const String featureFlagSwapTriggered = 'feature_flag_swap_triggered';

  // ---------- Session persistence (PRD I6.3 Sprint 2.2) ----------
  /// Fired by SessionBootstrap.verifyPersistedUser when the Firebase SDK
  /// restores a refresh-token-persisted user on app launch. The Month 3
  /// success gate uses the ratio of this event to app_open events to
  /// measure silent-sign-in rate empirically.
  static const String sessionRestoredFromRefreshToken =
      'session_restored_from_refresh_token';

  // ---------- Read budget enforcement (SAD §3 — ≤30 reads/session) ----------
  static const String readBudgetWarning = 'read_budget_warning';
  static const String readBudgetExceeded = 'read_budget_exceeded';
}
