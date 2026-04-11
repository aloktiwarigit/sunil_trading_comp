// =============================================================================
// UdhaarLedger — Freezed model for /shops/{shopId}/udhaarLedger/{ledgerId}.
//
// Schema per SAD v1.0.4 §5 with ADR-010 forbidden vocabulary discipline and
// the v1.0.4 RBI guardrail fields (Fn 3 reminder constraints).
//
// **ADR-010 compliance:** this file MUST NOT introduce any of the forbidden
// field names even in doc comments: `interest`, `interestRate`, `overdueFee`,
// `dueDate`, `lendingTerms`, `borrowerObligation`, `defaultStatus`,
// `collectionAttempt`. The custom lint at analysis_options.yaml will flag
// any future drift.
// =============================================================================

import 'package:freezed_annotation/freezed_annotation.dart';

part 'udhaar_ledger.freezed.dart';
part 'udhaar_ledger.g.dart';

/// An entry in the shop's udhaar khaata — an accounting mirror of a
/// remaining balance the customer owes the shopkeeper. It is NOT a lending
/// instrument. It is a record of trust. Per ADR-010 the forbidden vocabulary
/// is enforced at the Firestore security rule layer as well.
@freezed
class UdhaarLedger with _$UdhaarLedger {
  const factory UdhaarLedger({
    required String ledgerId,
    required String shopId,
    required String customerId,

    /// The original recorded amount (in INR) the customer still owes.
    /// Set once when the udhaar is first recorded, immutable thereafter.
    required int recordedAmount,

    /// Live running balance (recordedAmount − sum of partial payments).
    /// Updated atomically with `partialPaymentReferences` appends.
    required int runningBalance,

    /// When the customer acknowledged the balance (either in-app or via
    /// a shopkeeper-initiated confirm flow). Null if never acknowledged.
    DateTime? acknowledgedAt,

    /// References to partial payment records — each one is a Project/payment
    /// that reduced the `runningBalance`. Append-only.
    @Default(<String>[]) List<String> partialPaymentReferences,

    /// Set when `runningBalance == 0` and the ledger is formally closed.
    DateTime? closedAt,

    // ---- SAD v1.0.4 Fn 3 RBI guardrail fields ----

    /// Whether the shopkeeper has explicitly opted in to sending reminders
    /// for this specific ledger entry. **Default false** — reminders never
    /// fire unless the shopkeeper actively flips this on via the ops UI
    /// (S4.10). This is the core RBI defensive posture: reminders are not
    /// automatic, they are operator-initiated per entry.
    @Default(false) bool reminderOptInByBhaiya,

    /// Total number of reminders sent over the lifetime of this ledger.
    /// **Capped at 3.** The `sendUdhaarReminder` Cloud Function (Fn 3)
    /// refuses to fire once this reaches 3. Per S4.10 AC #8.
    @Default(0) int reminderCountLifetime,

    /// Minimum days between reminders. **Shopkeeper-controlled in the
    /// range [7, 30], default 14.** Per S4.10 AC #9.
    @Default(14) int reminderCadenceDays,
  }) = _UdhaarLedger;

  factory UdhaarLedger.fromJson(Map<String, dynamic> json) =>
      _$UdhaarLedgerFromJson(json);

  const UdhaarLedger._();

  bool get isClosed => closedAt != null || runningBalance == 0;

  bool get canSendAnotherReminder =>
      reminderOptInByBhaiya && reminderCountLifetime < 3;
}
