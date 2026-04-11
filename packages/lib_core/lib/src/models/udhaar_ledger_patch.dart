// =============================================================================
// UdhaarLedger patches — partition discipline for UdhaarLedger writes.
//
// Per PRD Standing Rule 11: UdhaarLedger is operator-write-only from the
// client side. Customers have read access but NEVER write. This is
// consistent with the ADR-010 posture that udhaar is a shopkeeper-initiated
// accounting mirror, not a customer-facing lending instrument.
//
// So there is only ONE client-side patch class: `UdhaarLedgerOperatorPatch`.
// The `UdhaarLedgerSystemPatch` is used by the `sendUdhaarReminder` Cloud
// Function (Fn 3) to increment `reminderCountLifetime` safely.
// =============================================================================

import 'package:freezed_annotation/freezed_annotation.dart';

part 'udhaar_ledger_patch.freezed.dart';

/// Operator-owned writes on an udhaar ledger entry.
///
/// Forbidden fields (ADR-010, rule-enforced): interest, interestRate,
/// overdueFee, dueDate, lendingTerms, borrowerObligation, defaultStatus,
/// collectionAttempt. Attempting to include any of these in the Firestore
/// payload will be rejected at the rule layer — the client-side type
/// system simply doesn't expose them.
@freezed
class UdhaarLedgerOperatorPatch with _$UdhaarLedgerOperatorPatch {
  const factory UdhaarLedgerOperatorPatch({
    int? runningBalance,
    DateTime? acknowledgedAt,
    DateTime? closedAt,
    bool? reminderOptInByBhaiya,
    int? reminderCadenceDays,
  }) = _UdhaarLedgerOperatorPatch;

  const UdhaarLedgerOperatorPatch._();

  /// Converts to a Firestore-ready map.
  ///
  /// Throws [ArgumentError] if `reminderCadenceDays` is outside [7, 30]
  /// per PRD S4.10 AC #9.
  Map<String, Object?> toFirestoreMap() {
    if (reminderCadenceDays != null) {
      if (reminderCadenceDays! < 7 || reminderCadenceDays! > 30) {
        throw ArgumentError(
          'reminderCadenceDays must be in [7, 30], got $reminderCadenceDays',
        );
      }
    }

    final out = <String, Object?>{};
    if (runningBalance != null) out['runningBalance'] = runningBalance;
    if (acknowledgedAt != null) out['acknowledgedAt'] = acknowledgedAt;
    if (closedAt != null) out['closedAt'] = closedAt;
    if (reminderOptInByBhaiya != null) {
      out['reminderOptInByBhaiya'] = reminderOptInByBhaiya;
    }
    if (reminderCadenceDays != null) {
      out['reminderCadenceDays'] = reminderCadenceDays;
    }
    return out;
  }
}

/// System-owned writes — used by the `sendUdhaarReminder` Cloud Function
/// (SAD §7 Fn 3) to increment `reminderCountLifetime` after successfully
/// dispatching a reminder. Not exposed to any client app.
@freezed
class UdhaarLedgerSystemPatch with _$UdhaarLedgerSystemPatch {
  const factory UdhaarLedgerSystemPatch({
    int? reminderCountLifetime,
    DateTime? lastReminderAt,
  }) = _UdhaarLedgerSystemPatch;

  const UdhaarLedgerSystemPatch._();

  Map<String, Object?> toFirestoreMap() {
    final out = <String, Object?>{};
    if (reminderCountLifetime != null) {
      if (reminderCountLifetime! > 3) {
        throw ArgumentError(
          'reminderCountLifetime is capped at 3 per S4.10 AC #8, '
          'got $reminderCountLifetime',
        );
      }
      out['reminderCountLifetime'] = reminderCountLifetime;
    }
    if (lastReminderAt != null) out['lastReminderAt'] = lastReminderAt;
    return out;
  }
}
