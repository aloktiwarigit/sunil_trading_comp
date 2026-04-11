// =============================================================================
// Project patches — the three partition-scoped patch types for Project writes.
//
// This file is the compile-time enforcement of PRD Standing Rule 11 and
// SAD v1.0.4 §9 field-partition discipline.
//
// **Critical design note — why three SEPARATE classes, not one sealed union:**
//
// If these were variants of a single sealed `ProjectPatch` class, a customer_app
// import of `ProjectPatch` would let the compiler accept `ProjectPatch.operator(...)`
// calls — which is exactly the bug we're trying to prevent. By making them three
// independent classes, the Dart import graph becomes the enforcement mechanism:
//
//   - `customer_app` imports ONLY `ProjectCustomerPatch` + `ProjectCustomerCancelPatch`
//   - `shopkeeper_app` imports ONLY `ProjectOperatorPatch` + `ProjectOperatorRevertPatch`
//   - Cloud Functions import ONLY `ProjectSystemPatch`
//
// Cross-imports are caught by `tools/audit_project_patch_imports.sh` in CI
// (PRD I6.12 AC #3) and by the negative compilation test at
// `test/fails_to_compile/customer_app_constructs_operator_patch.dart`.
//
// The `ChatThread` and `UdhaarLedger` patches in `chat_thread_patch.dart` and
// `udhaar_ledger_patch.dart` follow the identical pattern.
// =============================================================================

import 'package:freezed_annotation/freezed_annotation.dart';

import 'line_item.dart';
import 'project.dart';

part 'project_patch.freezed.dart';

// -----------------------------------------------------------------------------
// Customer-owned patches
// -----------------------------------------------------------------------------

/// Fields the customer_app is allowed to mutate on a Project document.
///
/// Partition per SAD §9 v1.0.4: customer-owned = `occasion` (at creation only),
/// `unreadCountForCustomer` (reset on open). Both are immutable-against-replay
/// because `occasion` is write-once and `unreadCountForCustomer` is monotonic.
@freezed
class ProjectCustomerPatch with _$ProjectCustomerPatch {
  const factory ProjectCustomerPatch({
    /// Write-once at Project creation. Attempting to change after the Project
    /// is no longer in `draft` state is rejected by the security rule.
    String? occasion,

    /// Reset to 0 by customer on project open. Monotonic — cannot increase
    /// from customer side (the incrementing happens via new-message Cloud
    /// Function writing to the operator's unread field, not the customer's).
    int? unreadCountForCustomer,
  }) = _ProjectCustomerPatch;

  const ProjectCustomerPatch._();

  /// Converts to a Firestore-ready map with only the non-null fields set.
  Map<String, Object?> toFirestoreMap() {
    final out = <String, Object?>{};
    if (occasion != null) out['occasion'] = occasion;
    if (unreadCountForCustomer != null) {
      out['unreadCountForCustomer'] = unreadCountForCustomer;
    }
    return out;
  }
}

/// The one cross-partition customer mutation: cancelling a draft Project.
/// Gated by a security rule that checks `resource.data.state == 'draft'`
/// (PRD I6.12 edge case #1). If the Project has advanced past draft, this
/// patch is rejected at the rule layer.
@freezed
class ProjectCustomerCancelPatch with _$ProjectCustomerCancelPatch {
  const factory ProjectCustomerCancelPatch({
    @Default(ProjectState.cancelled) ProjectState state,
  }) = _ProjectCustomerCancelPatch;

  const ProjectCustomerCancelPatch._();

  Map<String, Object?> toFirestoreMap() => <String, Object?>{
        'state': 'cancelled',
      };
}

// -----------------------------------------------------------------------------
// Operator-owned patches
// -----------------------------------------------------------------------------

/// Fields the shopkeeper_app is allowed to mutate on a Project document.
///
/// Partition per SAD §9 v1.0.4. Includes the Triple Zero invariant field
/// `amountReceivedByShop` which customer code paths MUST NOT write.
@freezed
class ProjectOperatorPatch with _$ProjectOperatorPatch {
  const factory ProjectOperatorPatch({
    ProjectState? state,
    int? totalAmount,

    /// Triple Zero invariant — at `paid` state, must equal `totalAmount`.
    /// CI cross-tenant integrity test verifies this invariant every PR.
    int? amountReceivedByShop,

    List<LineItem>? lineItems,
    DateTime? committedAt,
    DateTime? paidAt,
    DateTime? deliveredAt,
    DateTime? closedAt,
    String? customerDisplayName,
    String? customerPhone,
    String? customerVpa,
    String? decisionCircleId,
    String? udhaarLedgerId,
    int? unreadCountForShopkeeper,
  }) = _ProjectOperatorPatch;

  const ProjectOperatorPatch._();

  Map<String, Object?> toFirestoreMap() {
    final out = <String, Object?>{};
    if (state != null) out['state'] = state!.name;
    if (totalAmount != null) out['totalAmount'] = totalAmount;
    if (amountReceivedByShop != null) {
      out['amountReceivedByShop'] = amountReceivedByShop;
    }
    if (lineItems != null) {
      out['lineItems'] = lineItems!.map((e) => e.toJson()).toList();
    }
    if (committedAt != null) out['committedAt'] = committedAt;
    if (paidAt != null) out['paidAt'] = paidAt;
    if (deliveredAt != null) out['deliveredAt'] = deliveredAt;
    if (closedAt != null) out['closedAt'] = closedAt;
    if (customerDisplayName != null) {
      out['customerDisplayName'] = customerDisplayName;
    }
    if (customerPhone != null) out['customerPhone'] = customerPhone;
    if (customerVpa != null) out['customerVpa'] = customerVpa;
    if (decisionCircleId != null) out['decisionCircleId'] = decisionCircleId;
    if (udhaarLedgerId != null) out['udhaarLedgerId'] = udhaarLedgerId;
    if (unreadCountForShopkeeper != null) {
      out['unreadCountForShopkeeper'] = unreadCountForShopkeeper;
    }
    return out;
  }
}

/// Operator cross-partition mutation: reverting a committed Project back to
/// `draft` (PRD I6.12 edge case #2). Writes an audit log entry to
/// `shops/{shopId}/audit/{eventId}` as part of the same transaction.
///
/// **Revert discipline (fixed Sprint 2.1 code review finding B1):** ALL
/// downstream state timestamps AND the Triple Zero invariant field must
/// be nulled when reverting, otherwise a Project that was paid/delivered/
/// closed and then reverted to draft would carry stale timestamps from
/// its prior state machine path. The security rule at §6 enforces
/// `state == 'draft'` → `paidAt == null AND deliveredAt == null AND
/// closedAt == null AND amountReceivedByShop == 0`.
@freezed
class ProjectOperatorRevertPatch with _$ProjectOperatorRevertPatch {
  const factory ProjectOperatorRevertPatch({
    required String revertedByUid,
    required String reason,
  }) = _ProjectOperatorRevertPatch;

  const ProjectOperatorRevertPatch._();

  Map<String, Object?> toFirestoreMap() => <String, Object?>{
        'state': 'draft',
        // Null every downstream timestamp — the revert returns the Project
        // to the draft state machine root, so any paidAt/deliveredAt/
        // closedAt recorded under the committed subtree is now invalid.
        'committedAt': null,
        'paidAt': null,
        'deliveredAt': null,
        'closedAt': null,
        // Reset the Triple Zero invariant field. A paid Project reverted
        // to draft must not carry a non-zero amountReceivedByShop because
        // the `paid` state is no longer reachable from `draft` without
        // going through C3.5 UPI payment flow again.
        'amountReceivedByShop': 0,
        // Audit trail — who reverted and why (written alongside the
        // transaction that modifies the Project doc).
        'revertedByUid': revertedByUid,
        'revertReason': reason,
      };
}

// -----------------------------------------------------------------------------
// System-owned patches (Cloud Functions only)
// -----------------------------------------------------------------------------

/// Fields only Cloud Functions are allowed to mutate on a Project document.
/// All three fields maintain monotonic invariants — `lastMessageAt` uses
/// `FieldValue.serverTimestamp()` + transactional get per SAD §9 invariant #3.
@freezed
class ProjectSystemPatch with _$ProjectSystemPatch {
  const factory ProjectSystemPatch({
    String? lastMessagePreview,
    DateTime? lastMessageAt,
    DateTime? updatedAt,
  }) = _ProjectSystemPatch;

  const ProjectSystemPatch._();

  Map<String, Object?> toFirestoreMap() {
    final out = <String, Object?>{};
    if (lastMessagePreview != null) {
      out['lastMessagePreview'] = lastMessagePreview;
    }
    if (lastMessageAt != null) out['lastMessageAt'] = lastMessageAt;
    if (updatedAt != null) out['updatedAt'] = updatedAt;
    return out;
  }
}
