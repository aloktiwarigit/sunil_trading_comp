// =============================================================================
// PriceProposalBubble — renders a shopkeeper price proposal in the chat.
//
// Per C3.3:
//   AC #2: shopkeeper sends type: "price_proposal" with proposedPrice + lineItemId
//   AC #3: customer-side renders with "Accept" button → updates finalPrice
//   AC #4: multiple proposals allowed; only the most recent accepted applies
//   AC #6: history preserved in the chat thread (messages are immutable)
//
// The bubble shows:
//   - "Bhaiya's offer — {skuName}" label
//   - Original price (strikethrough) + proposed price (prominent)
//   - "Accept" button (customer side only; disabled if already accepted)
//   - "Accepted" badge when the proposal has been acted on
//
// BINDING RULES:
//   - ALL strings via AppStrings (no hardcoded Devanagari)
//   - ALL colors via YugmaThemeExtension (no hardcoded colors)
//   - Oxblood MUST NOT appear (binding rule #7 — chat zone)
//   - Font refs via YugmaFonts (binding rule #5)
// =============================================================================

import 'package:flutter/material.dart';

import 'package:lib_core/src/locale/strings_base.dart';
import 'package:lib_core/src/models/message.dart';
import 'package:lib_core/src/theme/tokens.dart';
import 'package:lib_core/src/theme/yugma_theme_extension.dart';

/// Renders a price proposal message bubble in the chat.
///
/// Used by [ChatBubble] when the message type is [MessageType.priceProposal].
class PriceProposalBubble extends StatelessWidget {
  const PriceProposalBubble({
    super.key,
    required this.message,
    required this.strings,
    required this.skuName,
    this.originalPrice,
    this.isAccepted = false,
    this.isCustomerSide = true,
    this.onAccept,
  });

  /// The price_proposal message.
  final Message message;

  /// Locale-resolved strings.
  final AppStrings strings;

  /// The SKU name for the line item being negotiated.
  final String skuName;

  /// The original catalog price (for strikethrough display). Null if unknown.
  final int? originalPrice;

  /// True if this proposal has been accepted by the customer.
  final bool isAccepted;

  /// True if rendering on the customer side (shows Accept button).
  final bool isCustomerSide;

  /// Called when the customer taps "Accept". Null disables the button.
  final VoidCallback? onAccept;

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;
    final proposedPrice = message.proposedPrice ?? 0;

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: theme.shopAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(YugmaRadius.lg),
        border: Border.all(
          color: theme.shopAccent.withValues(alpha: 0.25),
        ),
      ),
      padding: const EdgeInsets.all(YugmaSpacing.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label: "Bhaiya's offer — {skuName}"
          Text(
            strings.proposalBubbleLabel(skuName),
            style: theme.captionDeva.copyWith(
              color: theme.shopAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: YugmaSpacing.s2),

          // Price display
          Row(
            children: [
              // Original price (strikethrough) if available
              if (originalPrice != null && originalPrice != proposedPrice) ...[
                Text(
                  strings.proposalPriceLine(originalPrice!),
                  style: theme.monoNumeral.copyWith(
                    fontSize: theme.isElderTier ? 16.0 : 13.0,
                    color: theme.shopTextMuted,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: YugmaSpacing.s2),
              ],
              // Proposed price (prominent)
              Text(
                strings.proposalPriceLine(proposedPrice),
                style: theme.monoNumeral.copyWith(
                  fontSize: theme.isElderTier ? 22.0 : 18.0,
                  fontWeight: FontWeight.w700,
                  color: theme.shopPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: YugmaSpacing.s2),

          // Accept button or Accepted badge
          if (isAccepted)
            _buildAcceptedBadge(theme)
          else if (isCustomerSide)
            _buildAcceptButton(theme),
        ],
      ),
    );
  }

  Widget _buildAcceptButton(YugmaThemeExtension theme) {
    return SizedBox(
      height: theme.tapTargetMin,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onAccept,
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
        child: Text(strings.proposalAcceptButton),
      ),
    );
  }

  Widget _buildAcceptedBadge(YugmaThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: YugmaSpacing.s3,
        vertical: YugmaSpacing.s1,
      ),
      decoration: BoxDecoration(
        color: theme.shopAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(YugmaRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: theme.isElderTier ? 18.0 : 14.0,
            color: theme.shopAccent,
          ),
          const SizedBox(width: YugmaSpacing.s1),
          Text(
            strings.proposalAcceptedBadge,
            style: theme.captionDeva.copyWith(
              color: theme.shopAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
