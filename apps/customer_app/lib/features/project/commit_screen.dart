// =============================================================================
// CommitScreen — the C3.4 commit flow UI.
//
// Per C3.4:
//   AC #1: Prominent oxblood "ऑर्डर पक्का कीजिए" button from draft view
//   AC #2: OTP ceremony with bhaiya framing (otpPromptBhaiyaNeedsIt)
//   AC #5: Post-commit confirmation with line items, total, payment CTA
//   AC #8: Standing Rule 11 — uses ProjectCustomerCommitPatch via controller
//
// Oxblood `shopCommit` color is the FIRST legitimate use (reserved for
// commit button + payment success per handoff §4).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lib_core/lib_core.dart';

import 'package:customer_app/features/project/commit_controller.dart';
import 'package:customer_app/features/project/draft_controller.dart';

/// The commit flow screen.
///
/// Shows order summary → OTP flow (if needed) → confirmation.
class CommitScreen extends ConsumerStatefulWidget {
  const CommitScreen({
    super.key,
    required this.projectId,
    required this.strings,
  });

  final String projectId;
  final AppStrings strings;

  @override
  ConsumerState<CommitScreen> createState() => _CommitScreenState();
}

class _CommitScreenState extends ConsumerState<CommitScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _phoneFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;
    final commitAsync =
        ref.watch(commitControllerProvider(widget.projectId));
    final draftAsync = ref.watch(draftControllerProvider);

    return Scaffold(
      backgroundColor: theme.shopBackground,
      appBar: AppBar(
        title: Text(
          widget.strings.commitButtonPakka,
          style: theme.h2Deva,
        ),
        backgroundColor: theme.shopBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: theme.shopPrimary),
      ),
      body: commitAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: theme.shopAccent),
        ),
        error: (err, _) => Center(
          child: Text(err.toString(), style: theme.bodyDeva),
        ),
        data: (flowState) {
          return switch (flowState.stage) {
            CommitFlowStage.idle => _buildOrderSummary(
                context, theme, draftAsync),
            CommitFlowStage.enteringPhone => _buildPhoneInput(
                context, theme),
            CommitFlowStage.awaitingOtp => _buildOtpInput(
                context, theme),
            CommitFlowStage.committing => _buildCommitting(
                context, theme),
            CommitFlowStage.committed => _buildConfirmation(
                context, theme, flowState),
            CommitFlowStage.error => _buildError(
                context, theme, flowState),
          };
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stage: idle — Order summary with commit button
  // ---------------------------------------------------------------------------

  Widget _buildOrderSummary(
    BuildContext context,
    YugmaThemeExtension theme,
    AsyncValue<DraftState> draftAsync,
  ) {
    return draftAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: theme.shopAccent),
      ),
      error: (err, _) => Center(
        child: Text(err.toString(), style: theme.bodyDeva),
      ),
      data: (draftState) {
        if (draftState.isEmpty) {
          return Center(
            child: Text(
              widget.strings.emptyDraftList,
              style: theme.bodyDeva,
              textAlign: TextAlign.center,
            ),
          );
        }

        final items = draftState.lineItems;
        var total = 0;
        for (final item in items) {
          total += item.quantity * item.unitPriceInr;
        }

        return Column(
          children: [
            // Line items list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(YugmaSpacing.s4),
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    Divider(color: theme.shopDivider, height: 1),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: YugmaSpacing.s3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.skuName,
                            style: theme.bodyDeva
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          '${item.quantity} × ₹${formatInr(item.unitPriceInr)}',
                          style: theme.monoNumeral,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Total + commit button
            _buildCommitBar(context, theme, total),
          ],
        );
      },
    );
  }

  Widget _buildCommitBar(
    BuildContext context,
    YugmaThemeExtension theme,
    int total,
  ) {
    return Container(
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
            // Total row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.strings.orderTotalLabel,
                  style: theme.bodyDeva
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '₹${formatInr(total)}',
                  style: theme.monoNumeral.copyWith(
                    fontSize: theme.isElderTier ? 22.0 : 18.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: YugmaSpacing.s4),
            // Oxblood commit button — FIRST legitimate use of shopCommit
            SizedBox(
              height: theme.tapTargetMin,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  ref
                      .read(commitControllerProvider(widget.projectId)
                          .notifier)
                      .startCommit();
                },
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
                child: Text(widget.strings.commitButtonPakka),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stage: enteringPhone — Phone number input with bhaiya framing
  // ---------------------------------------------------------------------------

  Widget _buildPhoneInput(
    BuildContext context,
    YugmaThemeExtension theme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(YugmaSpacing.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: YugmaSpacing.s8),
          // Bhaiya framing — the critical R12 copy
          Text(
            widget.strings.otpPromptBhaiyaNeedsIt,
            style: theme.bodyDeva.copyWith(
              fontSize: theme.isElderTier ? 20.0 : 16.0,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: YugmaSpacing.s8),
          // Phone number field
          Form(
            key: _phoneFormKey,
            child: TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: theme.monoNumeral.copyWith(
                fontSize: theme.isElderTier ? 22.0 : 18.0,
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                if (digits.isEmpty) return 'Phone number is required';
                final normalized = digits.startsWith('91') && digits.length > 10
                    ? digits.substring(2)
                    : digits;
                if (normalized.length != 10) {
                  return 'Enter a valid 10-digit mobile number';
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: widget.strings.phoneInputLabel,
                labelStyle: theme.bodyDeva.copyWith(
                  color: theme.shopTextSecondary,
                ),
                prefixText: '+91 ',
                prefixStyle: theme.monoNumeral.copyWith(
                  fontSize: theme.isElderTier ? 22.0 : 18.0,
                  color: theme.shopTextSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(YugmaRadius.md),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(YugmaRadius.md),
                  borderSide: BorderSide(color: theme.shopPrimary, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(height: YugmaSpacing.s6),
          // Send OTP button (with cooldown guard)
          Builder(builder: (context) {
            final controller = ref.read(
                commitControllerProvider(widget.projectId).notifier);
            final cooldown = controller.otpCooldownSeconds;
            final isCoolingDown = cooldown > 0;

            return SizedBox(
              height: theme.tapTargetMin,
              child: ElevatedButton(
                onPressed: isCoolingDown
                    ? null
                    : () {
                        if (!(_phoneFormKey.currentState?.validate() ?? false)) return;
                        var raw = _phoneController.text.trim();
                        if (raw.isEmpty) return;
                        // Strip non-digits and normalize to E.164 (India).
                        raw = raw.replaceAll(RegExp(r'[^0-9]'), '');
                        // Handle if user entered with country code.
                        if (raw.startsWith('91') && raw.length > 10) {
                          raw = raw.substring(2);
                        }
                        if (raw.length != 10) return; // Indian mobile = 10 digits
                        final phoneE164 = '+91$raw';
                        controller.sendOtp(phoneE164);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.shopPrimary,
                  foregroundColor: theme.shopTextOnPrimary,
                  disabledBackgroundColor:
                      theme.shopPrimary.withOpacity(0.4),
                  disabledForegroundColor:
                      theme.shopTextOnPrimary.withOpacity(0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(YugmaRadius.md),
                  ),
                  textStyle: TextStyle(
                    fontFamily: theme.fontFamilyDevanagariBody,
                    fontSize: theme.isElderTier ? 18.0 : 15.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(
                  isCoolingDown
                      ? widget.strings.otpResendCountdown(cooldown)
                      : widget.strings.otpSendButton,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stage: awaitingOtp — OTP code entry
  // ---------------------------------------------------------------------------

  Widget _buildOtpInput(
    BuildContext context,
    YugmaThemeExtension theme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(YugmaSpacing.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: YugmaSpacing.s8),
          Text(
            widget.strings.otpCodeLabel,
            style: theme.bodyDeva.copyWith(
              fontSize: theme.isElderTier ? 20.0 : 16.0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: YugmaSpacing.s8),
          // OTP code field
          Form(
            key: _otpFormKey,
            child: TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: theme.monoNumeral.copyWith(
                fontSize: theme.isElderTier ? 28.0 : 24.0,
                letterSpacing: 8,
              ),
              maxLength: 6,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                if (digits.isEmpty) return 'OTP is required';
                if (digits.length != 6) return 'Enter the 6-digit OTP code';
                return null;
              },
              decoration: InputDecoration(
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(YugmaRadius.md),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(YugmaRadius.md),
                  borderSide: BorderSide(color: theme.shopPrimary, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(height: YugmaSpacing.s6),
          // Verify button
          SizedBox(
            height: theme.tapTargetMin,
            child: ElevatedButton(
              onPressed: () {
                if (!(_otpFormKey.currentState?.validate() ?? false)) return;
                final code = _otpController.text.trim();
                if (code.length < 6) return;
                ref
                    .read(commitControllerProvider(widget.projectId).notifier)
                    .verifyOtpAndCommit(code);
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
              child: Text(widget.strings.otpVerifyButton),
            ),
          ),
          const SizedBox(height: YugmaSpacing.s4),
          // Resend OTP with cooldown
          Builder(builder: (context) {
            final controller = ref.read(
                commitControllerProvider(widget.projectId).notifier);
            final cooldown = controller.otpCooldownSeconds;
            final isCoolingDown = cooldown > 0;
            final flowState = ref.read(
                commitControllerProvider(widget.projectId)).valueOrNull;

            return TextButton(
              onPressed: isCoolingDown || flowState?.phoneE164 == null
                  ? null
                  : () => controller.sendOtp(flowState!.phoneE164!),
              child: Text(
                isCoolingDown
                    ? widget.strings.otpResendCountdown(cooldown)
                    : widget.strings.otpSendButton,
                style: theme.bodyDeva.copyWith(
                  color: isCoolingDown
                      ? theme.shopTextSecondary
                      : theme.shopPrimary,
                  fontSize: theme.isElderTier ? 16.0 : 14.0,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stage: committing — loading spinner
  // ---------------------------------------------------------------------------

  Widget _buildCommitting(
    BuildContext context,
    YugmaThemeExtension theme,
  ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: theme.shopCommit),
          const SizedBox(height: YugmaSpacing.s4),
          Text(
            widget.strings.commitButtonPakka,
            style: theme.bodyDeva,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stage: committed — confirmation screen (AC #5)
  // ---------------------------------------------------------------------------

  Widget _buildConfirmation(
    BuildContext context,
    YugmaThemeExtension theme,
    CommitFlowState flowState,
  ) {
    final project = flowState.committedProject;
    final items = project?.lineItems ?? [];
    final total = project?.totalAmount ?? 0;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(YugmaSpacing.s6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: YugmaSpacing.s6),
                // Success icon
                Icon(
                  Icons.check_circle_outline,
                  size: 72,
                  color: theme.shopCommit,
                  semanticLabel: 'Order confirmed',
                ),
                const SizedBox(height: YugmaSpacing.s4),
                // Success title
                Text(
                  widget.strings.commitSuccessTitle,
                  style: theme.h2Deva.copyWith(color: theme.shopCommit),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: YugmaSpacing.s6),
                // Line items summary
                ...items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: YugmaSpacing.s2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(item.skuName, style: theme.bodyDeva),
                          ),
                          Text(
                            '${item.quantity} × ₹${formatInr(item.unitPriceInr)}',
                            style: theme.monoNumeral,
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: YugmaSpacing.s4),
                Divider(color: theme.shopDivider),
                const SizedBox(height: YugmaSpacing.s2),
                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.strings.orderTotalLabel,
                      style: theme.bodyDeva
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '₹${formatInr(total)}',
                      style: theme.monoNumeral.copyWith(
                        fontSize: theme.isElderTier ? 22.0 : 18.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Payment CTA
        Container(
          decoration: BoxDecoration(
            color: theme.shopSurface,
            boxShadow: YugmaShadows.card,
          ),
          padding: const EdgeInsets.all(YugmaSpacing.s4),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: theme.tapTargetMin,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to C3.5 payment screen.
                  context.push('/project/${widget.projectId}/payment');
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
                child: Text(widget.strings.proceedToPayment),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Stage: error — retry screen
  // ---------------------------------------------------------------------------

  Widget _buildError(
    BuildContext context,
    YugmaThemeExtension theme,
    CommitFlowState flowState,
  ) {
    // Map error key to localized string.
    final errorText = switch (flowState.errorMessage) {
      'otpInvalidCode' => widget.strings.otpInvalidCode,
      'otpCodeExpired' => widget.strings.otpCodeExpired,
      _ => widget.strings.commitFailed,
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
            semanticLabel: 'Error',
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
                    .read(commitControllerProvider(widget.projectId).notifier)
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
              child: Text(widget.strings.commitButtonPakka),
            ),
          ),
        ],
      ),
    );
  }

}
