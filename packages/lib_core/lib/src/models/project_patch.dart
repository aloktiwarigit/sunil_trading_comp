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

/// The second cross-partition customer mutation: committing a draft Project.
///
/// This is the PRD C3.4 "promote-to-operator-patch" — the customer_app writes
/// operator-partition fields (`state`, `totalAmount`, `committedAt`,
/// `customerPhone`, `customerDisplayName`) for this ONE gated transition.
///
/// Security rule gate: `state in ['draft', 'negotiating'] &&
/// request.auth.uid == resource.data.customerUid`.
///
/// **Phase 3 (2026-04-30):** the customer commit no longer pre-sets
/// `amountReceivedByShop`. That field stays at 0 from creation through
/// commit; it only becomes nonzero when the operator confirms cash/UPI/
/// transfer received via `applyOperatorMarkPaidPatch`. Pre-setting it here
/// would disarm the Triple Zero invariant on every later checkpoint.
@freezed
class ProjectCustomerCommitPatch with _$ProjectCustomerCommitPatch {
  const factory ProjectCustomerCommitPatch({
    /// E.164 phone number from the OTP upgrade (null if OTP was skipped).
    String? customerPhone,

    /// Display name captured during the OTP flow (null if unavailable).
    String? customerDisplayName,
  }) = _ProjectCustomerCommitPatch;

  const ProjectCustomerCommitPatch._();

  /// Build the Firestore map. The caller (ProjectRepo.applyCustomerCommitPatch)
  /// supplies `totalAmount` computed from line items — this patch does not
  /// carry it because the repo transaction reads the authoritative line items
  /// from the server snapshot, not from client state.
  Map<String, Object?> toFirestoreMap({
    required int totalAmount,
  }) {
    return <String, Object?>{
      'state': 'committed',
      // Phase 3: totalAmount is set at commit; amountReceivedByShop stays at
      // 0 until the operator confirms cash/UPI/transfer received. Setting it
      // here would disarm the Triple Zero invariant downstream.
      'totalAmount': totalAmount,
      if (customerPhone != null) 'customerPhone': customerPhone,
      if (customerDisplayName != null)
        'customerDisplayName': customerDisplayName,
    };
  }
}

/// The third cross-partition customer mutation: recording a UPI payment claim.
///
/// **Phase 3 (2026-04-30):** customer self-attestation cannot move a project to
/// `paid` without an operator confirmation or a verified PSP webhook (future).
/// The claim parks the project in `awaiting_verification`; the operator then
/// verifies and runs `applyOperatorMarkPaidPatch` to advance to `paid`.
///
/// Security rule gate (D.2 branch (3)): source state == 'committed', target
/// state == 'awaiting_verification', paymentMethod ∈ {upi, bank_transfer},
/// affectedKeys ⊆ {state, paymentMethod, customerVpa, updatedAt}.
@freezed
class ProjectCustomerPaymentPatch with _$ProjectCustomerPaymentPatch {
  const factory ProjectCustomerPaymentPatch({
    /// UPI VPA the customer used (captured from the UPI intent return).
    String? customerVpa,
  }) = _ProjectCustomerPaymentPatch;

  const ProjectCustomerPaymentPatch._();

  Map<String, Object?> toFirestoreMap() {
    // Phase 3: customer self-attestation parks at awaiting_verification.
    // Operator's typed mark-paid is the only path to `paid`.
    return <String, Object?>{
      'state': 'awaiting_verification',
      'paymentMethod': 'upi',
      if (customerVpa != null) 'customerVpa': customerVpa,
    };
  }
}

/// The fourth cross-partition customer mutation: selecting COD payment.
///
/// PRD C3.6 — committed → delivering transition. Skips `paid` state entirely;
/// the shopkeeper marks `paid` after collecting cash on delivery.
/// Security rule gate: `state == 'committed' &&
/// request.auth.uid == resource.data.customerUid`.
@freezed
class ProjectCustomerCodPatch with _$ProjectCustomerCodPatch {
  const factory ProjectCustomerCodPatch() = _ProjectCustomerCodPatch;

  const ProjectCustomerCodPatch._();

  Map<String, Object?> toFirestoreMap() {
    return <String, Object?>{
      'state': 'delivering',
      'paymentMethod': 'cod',
    };
  }
}

/// The fifth cross-partition customer mutation: self-reporting bank transfer.
///
/// PRD C3.7 — committed → awaiting_verification transition. The shopkeeper
/// must manually verify the transfer and move to `paid`.
/// Security rule gate: `state == 'committed' &&
/// request.auth.uid == resource.data.customerUid`.
@freezed
class ProjectCustomerBankTransferPatch with _$ProjectCustomerBankTransferPatch {
  const factory ProjectCustomerBankTransferPatch() =
      _ProjectCustomerBankTransferPatch;

  const ProjectCustomerBankTransferPatch._();

  Map<String, Object?> toFirestoreMap() {
    return <String, Object?>{
      'state': 'awaiting_verification',
      'paymentMethod': 'bank_transfer',
    };
  }
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
    String? paymentMethod,
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
    if (paymentMethod != null) out['paymentMethod'] = paymentMethod;
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
