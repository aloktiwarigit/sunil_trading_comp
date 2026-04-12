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
                // "Other ways" secondary link (AC #1 — secondary)
                // COD / bank transfer / udhaar are depth stories, not here.
                Center(
                  child: TextButton(
                    onPressed: () {
                      // Depth story placeholder — show a snackbar for WS.
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            strings.paymentOtherMethods,
                            style: TextStyle(
                              fontFamily: theme.fontFamilyDevanagariBody,
                            ),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
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
