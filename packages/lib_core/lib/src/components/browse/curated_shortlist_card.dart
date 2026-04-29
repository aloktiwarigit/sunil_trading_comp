// =============================================================================
// CuratedShortlistCard — SKU card rendered inside a curated shortlist.
//
// Ported from design bundle Widget 1 (components_library.dart lines 40-238).
// Uses context.yugmaTheme for all colors per ADR-003. ALL user-visible strings
// come from AppStrings — no hardcoded Devanagari in the render path.
//
// Layout: horizontal row with thumbnail (left) + text body (right).
// Thumbnail shows optional Golden Hour photo with "Sunil-bhaiya ki pasand"
// badge. Body shows Devanagari name, English name, material + dimensions,
// price with optional "negotiable" indicator.
//
// Consumed by B1.4 ShortlistScreen's vertical scroll of 6 SKU cards.
// =============================================================================

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../../utils/format_inr.dart';
import '../../theme/yugma_theme_extension.dart';

/// A single SKU card in a curated shortlist.
///
/// All text strings are passed in as parameters (resolved from AppStrings by
/// the consuming screen) — this widget has zero hardcoded Devanagari.
class CuratedShortlistCard extends StatelessWidget {
  /// Devanagari SKU name — the dominant label.
  final String nameDevanagari;

  /// English SKU name — secondary label for the toggle locale.
  final String nameEnglish;

  /// Material label (e.g., "स्टील", "शीशम").
  final String materialLabel;

  /// Dimensions label (e.g., "152 × 92 × 51 cm").
  final String dimensionsLabel;

  /// Base price in INR rupees.
  final int priceInr;

  /// Whether the price is negotiable ("मोल भाव").
  final bool negotiable;

  /// Localized label for "negotiable" — from AppStrings.skuNegotiableLabel.
  final String negotiableLabel;

  /// Localized label for "Sunil-bhaiya ki pasand" badge — from
  /// AppStrings.skuTopPickBadge.
  final String topPickBadgeLabel;

  /// Thumbnail image URL. Null shows a placeholder icon.
  final String? thumbnailUrl;

  /// Whether to show the "Sunil-bhaiya ki pasand" badge.
  final bool isShopkeepersTopPick;

  /// 1-line Hindi description.
  final String description;

  /// Called when the user taps this card.
  final VoidCallback onTap;

  const CuratedShortlistCard({
    super.key,
    required this.nameDevanagari,
    required this.nameEnglish,
    required this.materialLabel,
    required this.dimensionsLabel,
    required this.priceInr,
    required this.negotiable,
    required this.negotiableLabel,
    required this.topPickBadgeLabel,
    required this.thumbnailUrl,
    required this.isShopkeepersTopPick,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(YugmaRadius.lg),
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: YugmaSpacing.s4,
            vertical: YugmaSpacing.s2,
          ),
          constraints: BoxConstraints(
            minHeight: theme.isElderTier ? 130 : 110,
          ),
          decoration: BoxDecoration(
            color: theme.shopSurface,
            borderRadius: BorderRadius.circular(YugmaRadius.lg),
            border: Border.all(color: theme.shopDivider),
            boxShadow: YugmaShadows.card,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(YugmaRadius.lg),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Thumbnail with optional "top pick" badge
                  _buildThumbnail(theme),
                  // Body
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(YugmaSpacing.s3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildNameSection(theme),
                          if (description.isNotEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: YugmaSpacing.s1),
                              child: Text(
                                description,
                                style: TextStyle(
                                  fontFamily: theme.fontFamilyDevanagariBody,
                                  fontSize: theme.isElderTier ? 14.0 : 11.0,
                                  color: theme.shopTextSecondary,
                                  height: YugmaLineHeights.snug,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          _buildMetaRow(theme),
                          _buildPriceRow(theme),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(YugmaThemeExtension theme) {
    final size = theme.isElderTier ? 130.0 : 110.0;
    return Stack(
      children: [
        Container(
          width: size,
          constraints: BoxConstraints(minHeight: size),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.shopSecondary,
                theme.shopPrimaryDeep,
              ],
            ),
          ),
          child: thumbnailUrl != null
              ? Image.network(thumbnailUrl!, fit: BoxFit.cover)
              : Center(
                  child: Icon(
                    Icons.rectangle_outlined,
                    color: theme.shopAccentGlow,
                    size: 36,
                  ),
                ),
        ),
        if (isShopkeepersTopPick)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: theme.shopAccent,
                borderRadius: BorderRadius.circular(YugmaRadius.sm),
              ),
              child: Text(
                topPickBadgeLabel,
                style: TextStyle(
                  fontFamily: theme.fontFamilyDevanagariBody,
                  fontSize: theme.isElderTier ? 12.0 : 9.0,
                  color: theme.shopPrimaryDeep,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNameSection(YugmaThemeExtension theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nameDevanagari,
          style: TextStyle(
            fontFamily: theme.fontFamilyDevanagariDisplay,
            fontSize: theme.isElderTier ? 18.0 : 15.0,
            color: theme.shopTextPrimary,
            height: YugmaLineHeights.snug,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          nameEnglish,
          style: TextStyle(
            fontFamily: theme.fontFamilyEnglishDisplay,
            fontSize: theme.isElderTier ? 13.0 : 11.0,
            fontStyle: FontStyle.italic,
            color: theme.shopTextMuted,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildMetaRow(YugmaThemeExtension theme) {
    return Row(
      children: [
        Text(
          '$materialLabel \u00B7 $dimensionsLabel',
          style: TextStyle(
            fontFamily: theme.fontFamilyDevanagariBody,
            fontSize: theme.isElderTier ? 13.0 : 11.0,
            color: theme.shopTextMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(YugmaThemeExtension theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '\u20B9${formatInr(priceInr)}',
          style: TextStyle(
            fontFamily: YugmaFonts.mono,
            fontSize: theme.isElderTier ? 19.0 : 16.0,
            fontWeight: FontWeight.w600,
            color: theme.shopPrimary,
          ),
        ),
        if (negotiable) ...[
          const SizedBox(width: 4),
          Text(
            negotiableLabel,
            style: TextStyle(
              fontFamily: theme.fontFamilyDevanagariBody,
              fontSize: theme.isElderTier ? 13.0 : 10.0,
              color: theme.shopAccent,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

}
