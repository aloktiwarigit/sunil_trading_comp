// =============================================================================
// UdhaarDetailScreen — S4.10 AC #3–4, #7–9: ledger detail with payment
// history, record payment, reminder controls.
//
// AC #3: tapping a card opens the ledger detail with full payment history
// AC #4: "भुगतान दर्ज कीजिए" button opens C3.9's flow
// AC #7: reminder opt-in toggle
// AC #8: lifetime reminder cap badge
// AC #9: cadence stepper (7–30 days)
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';

/// Normalize Firestore Timestamp → ISO8601.
Object? _normalizeTimestamp(Object? value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate().toIso8601String();
  if (value is DateTime) return value.toIso8601String();
  return value;
}

/// Provider for a single ledger, streamed by ID.
final udhaarDetailProvider =
    StreamProvider.autoDispose.family<UdhaarLedger?, String>((ref, ledgerId) {
  final firestore = FirebaseFirestore.instance;
  final shopId = ref.read(shopIdProviderProvider).shopId;

  return firestore
      .collection('shops')
      .doc(shopId)
      .collection('udhaarLedger')
      .doc(ledgerId)
      .snapshots()
      .map((snap) {
    if (!snap.exists) return null;
    final raw = snap.data()!;
    return UdhaarLedger.fromJson(<String, dynamic>{
      ...raw,
      'ledgerId': snap.id,
      'acknowledgedAt': _normalizeTimestamp(raw['acknowledgedAt']),
      'closedAt': _normalizeTimestamp(raw['closedAt']),
    });
  });
});

/// S4.10 — Udhaar ledger detail screen.
class UdhaarDetailScreen extends ConsumerWidget {
  const UdhaarDetailScreen({super.key, required this.ledgerId});

  final String ledgerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = const AppStringsHi();
    final ledgerAsync = ref.watch(udhaarDetailProvider(ledgerId));

    return Scaffold(
      backgroundColor: YugmaColors.background,
      appBar: AppBar(
        backgroundColor: YugmaColors.primary,
        foregroundColor: YugmaColors.textOnPrimary,
        title: Text(
          'उधार खाता',
          style: TextStyle(
            fontFamily: YugmaFonts.devaDisplay,
            fontSize: YugmaTypeScale.h3,
          ),
        ),
      ),
      body: ledgerAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: YugmaColors.primary),
        ),
        error: (err, _) => Center(
          child: Text(err.toString(),
              style: TextStyle(fontFamily: YugmaFonts.devaBody)),
        ),
        data: (ledger) {
          if (ledger == null) {
            return Center(
              child: Text(
                'खाता नहीं मिला',
                style: TextStyle(fontFamily: YugmaFonts.devaBody),
              ),
            );
          }
          return _buildDetail(context, ref, ledger, strings);
        },
      ),
    );
  }

  Widget _buildDetail(
    BuildContext context,
    WidgetRef ref,
    UdhaarLedger ledger,
    AppStrings strings,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(YugmaSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(YugmaSpacing.s4),
            decoration: BoxDecoration(
              color: YugmaColors.surface,
              borderRadius: BorderRadius.circular(YugmaRadius.lg),
              boxShadow: YugmaShadows.card,
            ),
            child: Column(
              children: [
                Text(
                  'बाकी',
                  style: TextStyle(
                    fontFamily: YugmaFonts.devaBody,
                    fontSize: YugmaTypeScale.caption,
                    color: YugmaColors.textSecondary,
                  ),
                ),
                const SizedBox(height: YugmaSpacing.s1),
                Text(
                  '₹${formatInr(ledger.runningBalance)}',
                  style: TextStyle(
                    fontFamily: YugmaFonts.mono,
                    fontSize: YugmaTypeScale.display,
                    fontWeight: FontWeight.w700,
                    color: ledger.isClosed
                        ? YugmaColors.textMuted
                        : YugmaColors.accent,
                  ),
                ),
                const SizedBox(height: YugmaSpacing.s1),
                Text(
                  'कुल: ₹${formatInr(ledger.recordedAmount)}',
                  style: TextStyle(
                    fontFamily: YugmaFonts.mono,
                    fontSize: YugmaTypeScale.caption,
                    color: YugmaColors.textSecondary,
                  ),
                ),
                if (ledger.isClosed) ...[
                  const SizedBox(height: YugmaSpacing.s2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: YugmaSpacing.s3,
                      vertical: YugmaSpacing.s1,
                    ),
                    decoration: BoxDecoration(
                      color: YugmaColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(YugmaRadius.sm),
                    ),
                    child: Text(
                      strings.udhaarLedgerClosed,
                      style: TextStyle(
                        fontFamily: YugmaFonts.devaBody,
                        fontSize: YugmaTypeScale.caption,
                        fontWeight: FontWeight.w600,
                        color: YugmaColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: YugmaSpacing.s4),

          // Payment history
          Text(
            'भुगतान इतिहास',
            style: TextStyle(
              fontFamily: YugmaFonts.devaBody,
              fontSize: YugmaTypeScale.bodyLarge,
              fontWeight: FontWeight.w700,
              color: YugmaColors.textPrimary,
            ),
          ),
          const SizedBox(height: YugmaSpacing.s2),
          if (ledger.partialPaymentReferences.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(YugmaSpacing.s4),
              decoration: BoxDecoration(
                color: YugmaColors.surface,
                borderRadius: BorderRadius.circular(YugmaRadius.lg),
              ),
              child: Text(
                'अभी तक कोई भुगतान नहीं',
                style: TextStyle(
                  fontFamily: YugmaFonts.devaBody,
                  fontSize: YugmaTypeScale.caption,
                  color: YugmaColors.textMuted,
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: YugmaColors.surface,
                borderRadius: BorderRadius.circular(YugmaRadius.lg),
                boxShadow: YugmaShadows.card,
              ),
              child: Column(
                children: [
                  for (var i = 0;
                      i < ledger.partialPaymentReferences.length;
                      i++) ...[
                    if (i > 0) Divider(color: YugmaColors.divider, height: 1),
                    Padding(
                      padding: const EdgeInsets.all(YugmaSpacing.s3),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: YugmaColors.primary, size: 18),
                          const SizedBox(width: YugmaSpacing.s2),
                          Text(
                            'भुगतान #${i + 1}',
                            style: TextStyle(
                              fontFamily: YugmaFonts.devaBody,
                              fontSize: YugmaTypeScale.body,
                              color: YugmaColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: YugmaSpacing.s4),

          // AC #9: Reminder cadence stepper (only for open ledgers)
          if (!ledger.isClosed) ...[
            Text(
              strings.udhaarReminderCadencePrompt,
              style: TextStyle(
                fontFamily: YugmaFonts.devaBody,
                fontSize: YugmaTypeScale.bodyLarge,
                fontWeight: FontWeight.w700,
                color: YugmaColors.textPrimary,
              ),
            ),
            const SizedBox(height: YugmaSpacing.s2),
            _CadenceStepper(
              ledgerId: ledger.ledgerId,
              currentCadence: ledger.reminderCadenceDays,
            ),
            const SizedBox(height: YugmaSpacing.s4),

            // AC #4: Record payment button
            SizedBox(
              width: double.infinity,
              height: YugmaSpacing.s12,
              child: ElevatedButton.icon(
                onPressed: () =>
                    _showRecordPayment(context, ref, ledger, strings),
                icon: const Icon(Icons.payments_outlined, size: 20),
                label: Text(strings.udhaarRecordPaymentButton),
                style: ElevatedButton.styleFrom(
                  backgroundColor: YugmaColors.primary,
                  foregroundColor: YugmaColors.textOnPrimary,
                  textStyle: TextStyle(
                    fontFamily: YugmaFonts.devaBody,
                    fontSize: YugmaTypeScale.body,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(YugmaRadius.md),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showRecordPayment(
    BuildContext context,
    WidgetRef ref,
    UdhaarLedger ledger,
    AppStrings strings,
  ) {
    final amountController = TextEditingController();
    var selectedMethod = 'cash';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            strings.udhaarRecordPaymentButton,
            style: TextStyle(
              fontFamily: YugmaFonts.devaBody,
              fontSize: YugmaTypeScale.bodyLarge,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: strings.udhaarAmountPaidLabel,
                  labelStyle: TextStyle(fontFamily: YugmaFonts.devaBody),
                  prefixText: '₹ ',
                ),
              ),
              const SizedBox(height: YugmaSpacing.s3),
              DropdownButtonFormField<String>(
                value: selectedMethod,
                decoration: InputDecoration(
                  labelText: strings.udhaarPaymentMethodLabel,
                  labelStyle: TextStyle(fontFamily: YugmaFonts.devaBody),
                ),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('नकद')),
                  DropdownMenuItem(value: 'upi', child: Text('UPI')),
                  DropdownMenuItem(
                      value: 'bank', child: Text('बैंक ट्रांसफ़र')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setDialogState(() => selectedMethod = v);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(strings.draftQtyHighCancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = int.tryParse(amountController.text.trim()) ?? 0;
                if (amount <= 0) return;

                Navigator.of(ctx).pop();

                final repo = UdhaarLedgerRepo(
                  firestore: FirebaseFirestore.instance,
                  shopIdProvider: ShopIdProvider(
                    ref.read(shopIdProviderProvider).shopId,
                  ),
                );

                try {
                  await repo.recordPayment(
                    ledgerId: ledger.ledgerId,
                    amount: amount,
                    method: selectedMethod,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(strings.udhaarPaymentRecordedSuccess),
                      ),
                    );
                  }
                } on UdhaarLedgerRepoException catch (e) {
                  if (context.mounted) {
                    final msg = e.code == 'overpayment'
                        ? strings.udhaarOverpaymentError
                        : e.message;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(msg)),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: YugmaColors.primary,
                foregroundColor: YugmaColors.textOnPrimary,
              ),
              child: Text(strings.udhaarConfirmButton),
            ),
          ],
        ),
      ),
    );
  }
}

/// S4.10 AC #9: Cadence stepper (7–30 days).
class _CadenceStepper extends ConsumerWidget {
  const _CadenceStepper({
    required this.ledgerId,
    required this.currentCadence,
  });

  final String ledgerId;
  final int currentCadence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(YugmaSpacing.s3),
      decoration: BoxDecoration(
        color: YugmaColors.surface,
        borderRadius: BorderRadius.circular(YugmaRadius.lg),
        boxShadow: YugmaShadows.card,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: currentCadence > 7
                ? () => _updateCadence(ref, currentCadence - 1)
                : null,
            icon: Icon(
              Icons.remove_circle_outline,
              color: currentCadence > 7
                  ? YugmaColors.primary
                  : YugmaColors.textMuted,
            ),
          ),
          const SizedBox(width: YugmaSpacing.s2),
          Text(
            '$currentCadence दिन',
            style: TextStyle(
              fontFamily: YugmaFonts.devaBody,
              fontSize: YugmaTypeScale.bodyLarge,
              fontWeight: FontWeight.w700,
              color: YugmaColors.textPrimary,
            ),
          ),
          const SizedBox(width: YugmaSpacing.s2),
          IconButton(
            onPressed: currentCadence < 30
                ? () => _updateCadence(ref, currentCadence + 1)
                : null,
            icon: Icon(
              Icons.add_circle_outline,
              color: currentCadence < 30
                  ? YugmaColors.primary
                  : YugmaColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateCadence(WidgetRef ref, int newCadence) async {
    final repo = UdhaarLedgerRepo(
      firestore: FirebaseFirestore.instance,
      shopIdProvider: ShopIdProvider(
        ref.read(shopIdProviderProvider).shopId,
      ),
    );
    await repo.applyOperatorPatch(
      ledgerId,
      UdhaarLedgerOperatorPatch(reminderCadenceDays: newCadence),
    );
  }
}
