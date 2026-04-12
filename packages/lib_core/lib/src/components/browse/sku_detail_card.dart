// =============================================================================
// SkuDetailCard — full SKU detail screen for B1.5.
//
// Per PRD B1.5:
//   AC #1: Full-width Golden Hour photo (~70% screen height)
//   AC #2: SKU name in Devanagari, full description, price, dimensions, material
//   AC #3: "असली रूप दिखाइए" toggle to working-light photo
//   AC #4: 2 buttons: "इसे शॉर्टलिस्ट करें" + "सुनील भैया से बात करें"
//   AC #7: The "negotiable down to" floor is NOT shown to customers
//
// All strings come from AppStrings via parameters. No hardcoded Devanagari.
// All colors via context.yugmaTheme per ADR-003.
// =============================================================================

import 'package:flutter/material.dart';

import '../../locale/strings_base.dart';
import '../../utils/format_inr.dart';
import '../../models/inventory_sku.dart';
import '../../theme/tokens.dart';
import '../../theme/yugma_theme_extension.dart';
import 'golden_hour_photo_view.dart';

/// Full SKU detail view — hero photo + info + action buttons.
class SkuDetailCard extends StatelessWidget {
  /// The SKU to display.
  final InventorySku sku;

  /// Locale-resolved strings.
  final AppStrings strings;

  /// Golden Hour photo URL (resolved by the consuming app from the SKU's
  /// goldenHourPhotoIds via MediaStore).
  final String goldenHourPhotoUrl;

  /// Working-light fallback photo URL. Null if no fallback exists.
  final String? workingLightPhotoUrl;

  /// Called when the user taps "इसे शॉर्टलिस्ट करें".
  final VoidCallback? onAddToList;

  /// Called when the user taps "सुनील भैया से बात करें".
  final VoidCallback? onTalkToBhaiya;

  const SkuDetailCard({
    super.key,
    required this.sku,
    required this.strings,
    required this.goldenHourPhotoUrl,
    this.workingLightPhotoUrl,
    this.onAddToList,
    this.onTalkToBhaiya,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: theme.shopBackground,
      body: CustomScrollView(
        slivers: [
          // Hero photo — ~70% screen height per B1.5 AC #1
          SliverToBoxAdapter(
            child: GoldenHourPhotoView(
              goldenHourImageUrl: goldenHourPhotoUrl,
              workingLightImageUrl: workingLightPhotoUrl,
              height: screenHeight * 0.7,
              asliRoopLabel: strings.asliRoopToggle,
              goldenHourToggleLabel: strings.goldenHourToggleBeautiful,
            ),
          ),

          // SKU info section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(YugmaSpacing.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Devanagari name
                  Text(
                    sku.nameDevanagari,
                    style: theme.h1Deva,
                  ),
                  const SizedBox(height: YugmaSpacing.s1),
                  // English name
                  Text(
                    sku.name,
                    style: theme.displayEnglish,
                  ),
                  const SizedBox(height: YugmaSpacing.s4),

                  // Description
                  if (sku.description.isNotEmpty) ...[
                    Text(
                      sku.description,
                      style: theme.bodyDeva,
                    ),
                    const SizedBox(height: YugmaSpacing.s4),
                  ],

                  // Price row — negotiableDownTo is NEVER shown per B1.5 AC #7
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '\u20B9${formatInr(sku.basePrice)}',
                        style: theme.monoNumeral.copyWith(
                          fontSize: theme.isElderTier ? 28.0 : 22.0,
                        ),
                      ),
                      if (sku.negotiableDownTo < sku.basePrice) ...[
                        const SizedBox(width: YugmaSpacing.s2),
                        Text(
                          strings.skuNegotiableLabel,
                          style: TextStyle(
                            fontFamily: theme.fontFamilyDevanagariBody,
                            fontSize: theme.isElderTier ? 16.0 : 13.0,
                            color: theme.shopAccent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: YugmaSpacing.s4),

                  // Dimensions + Material
                  _buildInfoRow(
                    theme,
                    icon: Icons.straighten_outlined,
                    text:
                        '${sku.dimensions.heightCm} \u00D7 ${sku.dimensions.widthCm} \u00D7 ${sku.dimensions.depthCm} cm',
                  ),
                  const SizedBox(height: YugmaSpacing.s2),
                  _buildInfoRow(
                    theme,
                    icon: Icons.layers_outlined,
                    text: _materialLabel(sku.material),
                  ),

                  const SizedBox(height: YugmaSpacing.s8),

                  // Action buttons — B1.5 AC #4
                  _buildActionButtons(theme),

                  const SizedBox(height: YugmaSpacing.s8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    YugmaThemeExtension theme, {
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.shopTextMuted),
        const SizedBox(width: YugmaSpacing.s2),
        Text(
          text,
          style: theme.captionDeva.copyWith(color: theme.shopTextSecondary),
        ),
      ],
    );
  }

  Widget _buildActionButtons(YugmaThemeExtension theme) {
    final buttonHeight = theme.tapTargetMin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary CTA: "इसे शॉर्टलिस्ट करें"
        SizedBox(
          height: buttonHeight,
          child: ElevatedButton(
            onPressed: onAddToList,
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
            child: Text(strings.skuAddToList),
          ),
        ),
        const SizedBox(height: YugmaSpacing.s3),
        // Secondary CTA: "सुनील भैया से बात करें"
        SizedBox(
          height: buttonHeight,
          child: OutlinedButton(
            onPressed: onTalkToBhaiya,
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.shopPrimary,
              side: BorderSide(color: theme.shopPrimary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(YugmaRadius.md),
              ),
              textStyle: TextStyle(
                fontFamily: theme.fontFamilyDevanagariBody,
                fontSize: theme.isElderTier ? 18.0 : 15.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(strings.skuTalkToBhaiya),
          ),
        ),
      ],
    );
  }

  static String _materialLabel(SkuMaterial material) {
    switch (material) {
      case SkuMaterial.steel:
        return 'Steel';
      case SkuMaterial.woodSheesham:
        return 'Sheesham';
      case SkuMaterial.woodTeak:
        return 'Teak';
      case SkuMaterial.plyLaminate:
        return 'Ply/Laminate';
    }
  }
}
