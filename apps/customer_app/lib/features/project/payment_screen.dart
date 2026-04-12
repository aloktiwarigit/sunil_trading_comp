// =============================================================================
// PaymentScreen — the C3.5 UPI payment flow UI.
//
// Per C3.5:
//   AC #1: UPI primary CTA (full width) + "और तरीके" secondary link
//   AC #2: UPI deep link launched via url_launcher
//   AC #5: On success → Project.state = paid
//   AC #6: On failure → retry screen with "try another way"
//   AC #8: Triple Zero invariant — amount passed to UPI equals totalAmount
//
// Oxblood `shopCommit` color used for payment success state.
// COD / bank transfer / udhaar are separate depth stories — shown as
// disabled placeholders under "और तरीके" for WS completeness.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';

import 'package:customer_app/features/project/payment_controller.dart';

/// The payment flow screen (C3.5).
class PaymentScreen extends ConsumerWidget {
  const PaymentScreen({
    super.key,
    required this.projectId,
    required this.strings,
  });

  final String projectId;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.yugmaTheme;
    final paymentAsync = ref.watch(paymentControllerProvider(projectId));

    return Scaffold(
      backgroundColor: theme.shopBackground,
      appBar: AppBar(
        title: Text(
          strings.upiPayButton,
          style: theme.h2Deva,
        ),
        backgroundColor: theme.shopBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: theme.shopPrimary),
      ),
      body: paymentAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: theme.shopAccent),
        ),
        error: (err, _) => Center(
          child: Text(err.toString(), style: theme.bodyDeva),
        ),
        data: (flowState) {
          return switch (flowState.stage) {
            PaymentFlowStage.idle => _buildPaymentOptions(
                context, ref, theme, flowState),
            PaymentFlowStage.launching => _buildLoading(theme),
            PaymentFlowStage.awaitingReturn => _buildAwaitingReturn(
                context, ref, theme, flowState),
            PaymentFlowStage.recording => _buildLoading(theme),
            PaymentFlowStage.paid => _buildSuccess(
                context, theme, flowState),
            PaymentFlowStage.error => _buildError(
                context, ref, theme, flowState),
          };
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stage: idle — Payment options (AC #1)
  // ---------------------------------------------------------------------------

  Widget _buildPaymentOptions(
    BuildContext context,
    WidgetRef ref,
    YugmaThemeExtension theme,
    PaymentFlowState flowState,
  ) {
    final project = flowState.project;
    final total = project?.totalAmount ?? 0;

    return Column(
      children: [
        // Order summary header
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(YugmaSpacing.s6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Amount display
                const SizedBox(height: YugmaSpacing.s8),
                Text(
                  strings.orderTotalLabel,
                  style: theme.bodyDeva.copyWith(
                    color: theme.shopTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: YugmaSpacing.s2),
                Text(
                  '₹${_formatInr(total)}',
                  style: theme.monoNumeral.copyWith(
                    fontSize: theme.isElderTier ? 36.0 : 28.0,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: YugmaSpacing.s8),
              ],
            ),
          ),
        ),
        // Payment CTAs
        Container(
          decoration: BoxDecoration(
            color: theme.shopSurface,
            boxShadow: YugmaShadows.card,
          ),
          padding: const EdgeInsets.all(YugmaSpacing.s4),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Big UPI button (AC #1 — primary CTA)
                SizedBox(
                  height: theme.tapTargetMin + 8,
                  child: ElevatedButton(
                    onPressed: total > 0 && theme.upiVpa.isNotEmpty
                        ? () {
                            ref
                                .read(paymentControllerProvider(projectId)
                                    .notifier)
                                .launchUpiPayment(
                                  shopVpa: theme.upiVpa,
                                  shopName: theme.brandName,
                                  totalAmount: total,
                                );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.shopCommit,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(YugmaRadius.md),
                      ),
                      textStyle: TextStyle(
                        fontFamily: theme.fontFamilyDevanagariBody,
                        fontSize: theme.isElderTier ? 20.0 : 16.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(strings.upiPayButton),
                  ),
                ),
                const SizedBox(height: YugmaSpacing.s3),
                // "Other ways" expandable section (C3.6 + C3.7)
                Center(
                  child: TextButton(
                    onPressed: () {
                      _showOtherMethods(context, ref, theme, total);
                    },
                    child: Text(
                      strings.paymentOtherMethods,
                      style: theme.bodyDeva.copyWith(
                        color: theme.shopTextSecondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Stage: awaitingReturn — Customer returns from UPI app
  // ---------------------------------------------------------------------------

  Widget _buildAwaitingReturn(
    BuildContext context,
    WidgetRef ref,
    YugmaThemeExtension theme,
    PaymentFlowState flowState,
  ) {
    return Padding(
      padding: const EdgeInsets.all(YugmaSpacing.s6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: theme.shopAccent,
          ),
          const SizedBox(height: YugmaSpacing.s4),
          Text(
            strings.paymentProcessing,
            style: theme.bodyDeva.copyWith(
              fontSize: theme.isElderTier ? 18.0 : 15.0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: YugmaSpacing.s8),
          // "I paid" confirmation button — WS uses manual confirmation
          // since full UPI callback parsing is a depth-story enhancement.
          SizedBox(
            height: theme.tapTargetMin,
            child: ElevatedButton(
              onPressed: () {
                ref
                    .read(paymentControllerProvider(projectId).notifier)
                    .confirmPayment();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.shopCommit,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(YugmaRadius.md),
                ),
                textStyle: TextStyle(
                  fontFamily: theme.fontFamilyDevanagariBody,
                  fontSize: theme.isElderTier ? 18.0 : 15.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(strings.paymentSuccessPakka),
            ),
          ),
          const SizedBox(height: YugmaSpacing.s3),
          // Retry / different method
          Center(
            child: TextButton(
              onPressed: () {
                ref
                    .read(paymentControllerProvider(projectId).notifier)
                    .retry();
              },
              child: Text(
                strings.paymentOtherMethods,
                style: theme.bodyDeva.copyWith(
                  color: theme.shopTextSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stage: loading
  // ---------------------------------------------------------------------------

  Widget _buildLoading(YugmaThemeExtension theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: theme.shopCommit),
          const SizedBox(height: YugmaSpacing.s4),
          Text(strings.paymentProcessing, style: theme.bodyDeva),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stage: paid — success screen with oxblood accent
  // ---------------------------------------------------------------------------

  Widget _buildSuccess(
    BuildContext context,
    YugmaThemeExtension theme,
    PaymentFlowState flowState,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(YugmaSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 80,
              color: theme.shopCommit,
            ),
            const SizedBox(height: YugmaSpacing.s4),
            Text(
              strings.paymentSuccessPakka,
              style: theme.h2Deva.copyWith(color: theme.shopCommit),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: YugmaSpacing.s2),
            if (flowState.project != null)
              Text(
                '₹${_formatInr(flowState.project!.totalAmount)}',
                style: theme.monoNumeral.copyWith(
                  fontSize: theme.isElderTier ? 28.0 : 22.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stage: error — retry
  // ---------------------------------------------------------------------------

  Widget _buildError(
    BuildContext context,
    WidgetRef ref,
    YugmaThemeExtension theme,
    PaymentFlowState flowState,
  ) {
    final errorText = switch (flowState.errorMessage) {
      'noUpiApp' => strings.noUpiAppFound,
      _ => strings.paymentFailed,
    };

    return Padding(
      padding: const EdgeInsets.all(YugmaSpacing.s6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: theme.shopCommit,
          ),
          const SizedBox(height: YugmaSpacing.s4),
          Text(
            errorText,
            style: theme.bodyDeva.copyWith(
              fontSize: theme.isElderTier ? 18.0 : 15.0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: YugmaSpacing.s8),
          SizedBox(
            height: theme.tapTargetMin,
            child: ElevatedButton(
              onPressed: () {
                ref
                    .read(paymentControllerProvider(projectId).notifier)
                    .retry();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.shopPrimary,
                foregroundColor: theme.shopTextOnPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(YugmaRadius.md),
                ),
                textStyle: TextStyle(
                  fontFamily: theme.fontFamilyDevanagariBody,
                  fontSize: theme.isElderTier ? 18.0 : 15.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(strings.upiPayButton),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // "Other ways" bottom sheet (C3.6 COD + C3.7 Bank Transfer)
  // ---------------------------------------------------------------------------

  void _showOtherMethods(
    BuildContext context,
    WidgetRef ref,
    YugmaThemeExtension theme,
    int total,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.shopSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(YugmaSpacing.s4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  strings.paymentOtherMethods,
                  style: theme.h2Deva,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: YugmaSpacing.s4),
                // C3.6 — COD option
                _OtherMethodTile(
                  icon: Icons.local_shipping_outlined,
                  label: strings.codOption,
                  theme: theme,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showCodConfirmation(context, ref, theme, total);
                  },
                ),
                const SizedBox(height: YugmaSpacing.s2),
                // C3.7 — Bank transfer option (hidden if no bank details)
                if (theme.hasBankDetails)
                  _OtherMethodTile(
                    icon: Icons.account_balance_outlined,
                    label: strings.bankTransferOption,
                    theme: theme,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _showBankDetails(context, ref, theme);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// C3.6 AC #2 — COD confirmation dialog.
  void _showCodConfirmation(
    BuildContext context,
    WidgetRef ref,
    YugmaThemeExtension theme,
    int total,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.shopSurface,
          title: Text(strings.codOption, style: theme.h2Deva),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '₹${_formatInr(total)}',
                style: theme.monoNumeral.copyWith(
                  fontSize: theme.isElderTier ? 28.0 : 22.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: YugmaSpacing.s3),
              Text(
                strings.codConfirmNote,
                style: theme.bodyDeva,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                strings.paymentOtherMethods,
                style: TextStyle(color: theme.shopTextSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                ref
                    .read(paymentControllerProvider(projectId).notifier)
                    .selectCod();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.shopCommit,
                foregroundColor: Colors.white,
              ),
              child: Text(strings.codConfirmButton),
            ),
          ],
        );
      },
    );
  }

  /// C3.7 AC #2 — Bank details display + "Mark as paid" button.
  void _showBankDetails(
    BuildContext context,
    WidgetRef ref,
    YugmaThemeExtension theme,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.shopSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(YugmaSpacing.s6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  strings.bankTransferOption,
                  style: theme.h2Deva,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: YugmaSpacing.s6),
                // Bank details (AC #2 — long-press to copy)
                _BankDetailRow(
                  label: strings.bankAccountNumberLabel,
                  value: theme.bankAccountNumber ?? '',
                  theme: theme,
                ),
                _BankDetailRow(
                  label: strings.bankIfscLabel,
                  value: theme.bankIfsc ?? '',
                  theme: theme,
                ),
                _BankDetailRow(
                  label: strings.bankAccountHolderLabel,
                  value: theme.bankAccountHolderName ?? '',
                  theme: theme,
                ),
                _BankDetailRow(
                  label: strings.bankBranchLabel,
                  value: theme.bankBranch ?? '',
                  theme: theme,
                ),
                // UPI VPA as secondary option
                if (theme.upiVpa.isNotEmpty)
                  _BankDetailRow(
                    label: 'UPI',
                    value: theme.upiVpa,
                    theme: theme,
                  ),
                const SizedBox(height: YugmaSpacing.s6),
                // "Mark as paid" button (AC #3)
                SizedBox(
                  height: theme.tapTargetMin,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      ref
                          .read(paymentControllerProvider(projectId).notifier)
                          .selectBankTransfer();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.shopCommit,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(YugmaRadius.md),
                      ),
                      textStyle: TextStyle(
                        fontFamily: theme.fontFamilyDevanagariBody,
                        fontSize: theme.isElderTier ? 18.0 : 15.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(strings.bankTransferMarkPaid),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static String _formatInr(int amount) {
    final s = amount.toString();
    if (s.length <= 3) return s;
    final lastThree = s.substring(s.length - 3);
    final rest = s.substring(0, s.length - 3);
    final buffer = StringBuffer();
    for (var i = 0; i < rest.length; i++) {
      if (i != 0 && (rest.length - i) % 2 == 0) {
        buffer.write(',');
      }
      buffer.write(rest[i]);
    }
    return '$buffer,$lastThree';
  }
}

/// Tile for an alternative payment method in the bottom sheet.
class _OtherMethodTile extends StatelessWidget {
  const _OtherMethodTile({
    required this.icon,
    required this.label,
    required this.theme,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final YugmaThemeExtension theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.shopBackground,
      borderRadius: BorderRadius.circular(YugmaRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(YugmaRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: YugmaSpacing.s4,
            vertical: YugmaSpacing.s3,
          ),
          child: Row(
            children: [
              Icon(icon, color: theme.shopPrimary, size: 24),
              const SizedBox(width: YugmaSpacing.s3),
              Expanded(
                child: Text(label, style: theme.bodyDeva),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.shopTextMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bank detail row with long-press to copy (C3.7 edge case #2).
class _BankDetailRow extends StatelessWidget {
  const _BankDetailRow({
    required this.label,
    required this.value,
    required this.theme,
  });

  final String label;
  final String value;
  final YugmaThemeExtension theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: YugmaSpacing.s2),
      child: GestureDetector(
        onLongPress: () {
          // Copy to clipboard on long-press (C3.7 edge case #2).
          // Full clipboard wiring is a depth polish item.
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: theme.bodyDeva.copyWith(
                  color: theme.shopTextSecondary,
                  fontSize: theme.isElderTier ? 16.0 : 13.0,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: theme.monoNumeral.copyWith(
                  fontSize: theme.isElderTier ? 18.0 : 15.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
