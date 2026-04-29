// =============================================================================
// Operator — Freezed model for /shops/{shopId}/operators/{uid}.
//
// Per SAD §5 Operator schema + PRD S4.1 + S4.2 + Brief §5 "the app users
// — the shopkeeper, beta/bhatija, and munshi". An Operator is a Google-
// signed-in user who has a role in a specific shop. Multi-operator support
// from day one per Constraint 13 + Brief R1 burnout mitigation.
//
// Scoped to `/shops/{shopId}/operators/{googleUid}`. The doc ID is the
// Google UID (from firebase_auth) so the Firestore rule helper
// `isOperatorOf(shopId)` can `exists()` check the path without a read.
//
// **Pre-existing rules drift (flagged Phase 1.2):**
// firestore.rules lines 50-52 currently check `callerRole() == 'shopkeeper'
// || 'son' || 'munshi'` — but SAD §5 + this model use the canonical
// `bhaiya / beta / munshi`. This model follows SAD canonical. Sprint 4
// P2.4 reconciliation will fix the rules drift.
// =============================================================================

import 'package:freezed_annotation/freezed_annotation.dart';

part 'operator.freezed.dart';
part 'operator.g.dart';

/// An operator's role in the shop family. Per SAD §5 canonical naming.
///
/// Domain-grounded vocabulary (NOT generic "admin / manager / user"):
///   - `bhaiya`: Sunil-bhaiya himself — the primary shopkeeper, owner of
///     customer relationships, voice-note author, curation decider,
///     udhaar approver.
///   - `beta`: the son / nephew / digital-native younger family member
///     (Aditya in the Brief). Handles inventory entry, Golden Hour photo
///     capture, day-to-day chat replies. ~60% of daily ops volume.
///   - `munshi`: the shop's traditional bookkeeper role — optional in v1.
///     Reconciles payments, records udhaar ledger entries, manages cash.
enum OperatorRole {
  /// The primary shopkeeper. Only role with `canManageOperators: true`.
  @JsonValue('bhaiya')
  bhaiya,

  /// The digital-native son/nephew role. Handles routine ops.
  @JsonValue('beta')
  beta,

  /// The bookkeeper role. Payments + udhaar ledger only.
  @JsonValue('munshi')
  munshi,
}

/// Per-operator capability flags — what this role can actually DO. Gated
/// at the Firestore rule layer via role checks, mirrored here so the
/// customer_app / shopkeeper_app UI can decide whether to show or hide
/// buttons without waiting for a rule failure round-trip.
@freezed
class OperatorPermissions with _$OperatorPermissions {
  /// Create a permissions record. All defaults are permissive enough for
  /// `beta` — `bhaiya` sets the stricter flags to true at its discretion.
  const factory OperatorPermissions({
    /// Add / edit SKUs, upload Golden Hour photos.
    @Default(true) bool canEditInventory,

    /// Apply discounts beyond the SKU's `negotiableDownTo` floor.
    /// `bhaiya` only.
    @Default(false) bool canApproveDiscounts,

    /// Record udhaar ledger entries + payments. `bhaiya` + `munshi`.
    @Default(false) bool canRecordUdhaar,

    /// Mark Projects as cancelled / deleted. `bhaiya` only.
    @Default(false) bool canDeleteOrders,

    /// Add / remove other operators (self-exclusion enforced at rule
    /// layer). `bhaiya` only.
    @Default(false) bool canManageOperators,
  }) = _OperatorPermissions;

  /// JSON round-trip for Firestore serialization.
  factory OperatorPermissions.fromJson(Map<String, dynamic> json) =>
      _$OperatorPermissionsFromJson(json);
}

/// The Operator document.
///
/// Identity: `uid` is the Google Sign-In UID from firebase_auth. The
/// Firestore rules check `isGoogleSignedIn()` + `exists(operators/{uid})`
/// to authorize ops-app actions.
@freezed
class Operator with _$Operator {
  /// Construct an Operator.
  const factory Operator({
    required String uid,
    required String shopId,
    required OperatorRole role,
    required String displayName,
    required String email,
    required DateTime joinedAt,

    /// Capability flags — see [OperatorPermissions].
    @Default(OperatorPermissions()) OperatorPermissions permissions,

    /// Honest expectation of hours/week the operator can commit to the
    /// shop's digital operations. NOT enforced — just telemetry for the
    /// Brief R1 burnout watch.
    @Default(0) int weeklyHoursCommitted,
    DateTime? lastActiveAt,
  }) = _Operator;

  /// JSON round-trip for Firestore serialization.
  factory Operator.fromJson(Map<String, dynamic> json) =>
      _$OperatorFromJson(json);

  const Operator._();

  /// True iff this operator is the primary `bhaiya` — the only role with
  /// operator-management rights. Use for quick UI branch-point checks.
  bool get isBhaiya => role == OperatorRole.bhaiya;
}
