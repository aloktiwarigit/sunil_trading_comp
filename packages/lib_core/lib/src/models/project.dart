// =============================================================================
// Project — Freezed model for /shops/{shopId}/projects/{projectId}.
//
// Schema per SAD v1.0.4 §5, Project section, with §9 v1.0.4 field-partition
// table annotations. Every field is tagged with its partition owner in the
// doc comment so the sealed-union patches in `project_patch.dart` stay in
// sync without drift.
// =============================================================================

import 'package:freezed_annotation/freezed_annotation.dart';

import 'line_item.dart';

part 'project.freezed.dart';
part 'project.g.dart';

/// Project state machine — owned by operator (cannot be written by customer
/// except for the special `draft → cancelled` transition, gated by rule).
enum ProjectState {
  @JsonValue('draft')
  draft,

  @JsonValue('negotiating')
  negotiating,

  @JsonValue('committed')
  committed,

  @JsonValue('paid')
  paid,

  @JsonValue('delivering')
  delivering,

  @JsonValue('closed')
  closed,

  @JsonValue('cancelled')
  cancelled,
}

/// The Project document.
///
/// Field partition (SAD §9 v1.0.4):
///   Customer-owned: `occasion`, `unreadCountForCustomer`
///   Operator-owned: `state`, `totalAmount`, `amountReceivedByShop`,
///                   `lineItems`, `committedAt`, `paidAt`, `deliveredAt`,
///                   `closedAt`, `customerDisplayName`, `customerPhone`,
///                   `customerVpa`, `decisionCircleId`, `udhaarLedgerId`,
///                   `unreadCountForShopkeeper`
///   System-owned:   `lastMessagePreview`, `lastMessageAt`, `updatedAt`
///                   (Cloud Function writes only)
///
/// Enforcement is at compile-time via the three sealed-union patch classes
/// in `project_patch.dart`. Repository methods accept ONLY typed patches,
/// never `Map<String, dynamic>`. See PRD Standing Rule 11.
@freezed
class Project with _$Project {
  const factory Project({
    // ---- Identity ----
    required String projectId,
    required String shopId,
    required String customerId,
    required String customerUid,

    // ---- Customer-owned fields (SAD §9 partition) ----

    /// Customer-owned. Set at Project creation, immutable thereafter.
    /// One of: `shaadi`, `griha_pravesh`, `tyohaar`, `hadiya`, `dowry`, `other`.
    String? occasion,

    /// Customer-owned. Reset to 0 on open by the customer.
    @Default(0) int unreadCountForCustomer,

    // ---- Operator-owned fields (SAD §9 partition) ----

    /// Operator-owned. State machine transitions are gated by security rules
    /// (special-cased `draft → cancelled` by customer is allowed via
    /// `ProjectCustomerCancelPatch` per I6.12 edge case #1).
    @Default(ProjectState.draft) ProjectState state,

    /// Operator-owned. Negotiated total in INR (paise omitted for v1 —
    /// almirah prices are round rupees at this scale).
    @Default(0) int totalAmount,

    /// Operator-owned. **Triple Zero invariant (C3.4 AC #4 + C3.5 AC #8):**
    /// must equal `totalAmount` at the `paid` state. Customer cannot write.
    /// Enforced at CI by cross-tenant integrity test.
    @Default(0) int amountReceivedByShop,

    /// Operator-owned. Denormalized line items for offline reads.
    @Default(<LineItem>[]) List<LineItem> lineItems,

    /// Operator-owned. Set when customer enters phone OTP at commit.
    DateTime? committedAt,
    DateTime? paidAt,
    DateTime? deliveredAt,
    DateTime? closedAt,

    /// Operator-owned. Read from customer_memory or UPI intent return.
    String? customerDisplayName,
    String? customerPhone,
    String? customerVpa,

    /// Operator-owned. Links to the Pariwar pillar (feature-flagged).
    String? decisionCircleId,

    /// Operator-owned. Links to the ADR-010 accounting mirror.
    String? udhaarLedgerId,

    /// Operator-owned. Reset to 0 on open by any operator.
    @Default(0) int unreadCountForShopkeeper,

    // ---- System-owned fields (Cloud Function writes only) ----

    /// System-owned. Short preview of the most recent chat message for
    /// Project list rendering without an extra read.
    String? lastMessagePreview,

    /// System-owned. Monotonically advances via transactional get + set in
    /// the new-message Cloud Function (SAD §9 invariant #3).
    DateTime? lastMessageAt,

    /// System-owned. Server timestamp on every write regardless of actor.
    DateTime? updatedAt,

    // ---- Timestamps (immutable after create) ----
    required DateTime createdAt,
  }) = _Project;

  factory Project.fromJson(Map<String, dynamic> json) =>
      _$ProjectFromJson(json);

  const Project._();

  /// True iff `amountReceivedByShop == totalAmount`. Required invariant at
  /// the `paid` state (Triple Zero, zero-commission math, CI-enforced).
  bool get zeroCommissionSatisfied => amountReceivedByShop == totalAmount;
}
