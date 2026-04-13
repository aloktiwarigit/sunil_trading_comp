// =============================================================================
// ShortlistScreen — vertical scroll of EXACTLY 6 SKU cards for a curated
// shortlist occasion.
//
// Per PRD B1.4 AC #2: finite, NOT paginated. The list is EXACTLY 6 cards
// maximum — the finiteness IS the feature.
//
// Per PRD B1.4 AC #5: if the shortlist is empty (shopkeeper hasn't curated
// yet), renders the "Sunil-bhaiya ne abhi tak nahi chuna" empty state.
//
// All strings come from AppStrings via parameters — no hardcoded Devanagari.
// All colors via context.yugmaTheme per ADR-003.
// =============================================================================

import 'package:flutter/material.dart';

import '../../locale/strings_base.dart';
import '../../models/curated_shortlist.dart';
import '../../models/inventory_sku.dart';
import '../../theme/tokens.dart';
import '../../theme/yugma_theme_extension.dart';
import 'curated_shortlist_card.dart';

/// Vertical scroll screen showing the SKU cards in a curated shortlist.
///
/// The screen title comes from the [shortlist]'s occasion title. The body
/// is either a list of [CuratedShortlistCard]s or an empty-state message.
class ShortlistScreen extends StatelessWidget {
  /// The curated shortlist metadata (occasion, title, SKU IDs).
  final CuratedShortlist shortlist;

  /// Resolved SKU models for each ID in [shortlist.skuIdsInOrder].
  /// Must be in the same order as the shortlist. Entries that failed to
  /// resolve should be omitted (the card count may be < 6).
  final List<InventorySku> skus;

  /// Locale-resolved strings for all labels.
  final AppStrings strings;

  /// Called when the user taps a SKU card. Receives the tapped SKU.
  final ValueChanged<InventorySku>? onSkuTap;

  const ShortlistScreen({
    super.key,
    required this.shortlist,
    required this.skus,
    required this.strings,
    this.onSkuTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;

    return Scaffold(
      backgroundColor: theme.shopBackground,
      appBar: AppBar(
        backgroundColor: theme.shopBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.shopPrimary),
        title: Text(
          _shortlistTitle(shortlist.occasion),
          style: theme.h2Deva,
        ),
      ),
      body: shortlist.isCurated
          ? _buildSkuList(theme)
          : _buildEmptyState(theme),
    );
  }

  Widget _buildSkuList(YugmaThemeExtension theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: YugmaSpacing.s4),
      itemCount: skus.length,
      itemBuilder: (context, index) {
        final sku = skus[index];
        return CuratedShortlistCard(
          nameDevanagari: sku.nameDevanagari,
          nameEnglish: sku.name,
          materialLabel: _materialLabel(sku.material),
          dimensionsLabel:
              '${sku.dimensions.heightCm} \u00D7 ${sku.dimensions.widthCm} \u00D7 ${sku.dimensions.depthCm} cm',
          priceInr: sku.basePrice,
          negotiable: sku.negotiableDownTo < sku.basePrice,
          negotiableLabel: strings.skuNegotiableLabel,
          topPickBadgeLabel: strings.skuTopPickBadge,
          thumbnailUrl: sku.goldenHourPhotoIds.isNotEmpty
              ? null // Photo URL resolution is done at the consuming app level
              : (sku.fallbackPhotoUrls.isNotEmpty
                  ? sku.fallbackPhotoUrls.first
                  : null),
          isShopkeepersTopPick: true, // All cards in a curated shortlist get the badge per B1.4 AC #4
          description: sku.description,
          onTap: () => onSkuTap?.call(sku),
        );
      },
    );
  }

  Widget _buildEmptyState(YugmaThemeExtension theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(YugmaSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: theme.shopTextMuted,
            ),
            const SizedBox(height: YugmaSpacing.s4),
            Text(
              strings.emptyShortlistNotYetCurated,
              style: theme.bodyDeva.copyWith(color: theme.shopTextMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Resolve the shortlist title from AppStrings based on the occasion.
  String _shortlistTitle(ShortlistOccasion occasion) {
    switch (occasion) {
      case ShortlistOccasion.shaadi:
        return strings.shortlistTitleShaadi;
      case ShortlistOccasion.nayaGhar:
        return strings.shortlistTitleNayaGhar;
      case ShortlistOccasion.betiKaGhar:
        return strings.shortlistTitleBetiKaGhar;
      case ShortlistOccasion.replacement:
        return strings.shortlistTitlePuranaBadlne;
      case ShortlistOccasion.budget:
        return strings.shortlistTitleBudget;
      case ShortlistOccasion.ladies:
        return strings.shortlistTitleLadies;
    }
  }

  /// Human-readable material label. In a production app this would come
  /// from AppStrings; for now we use short English labels since the
  /// material enum is English-keyed and the shopkeeper may set their own
  /// label per SKU in future sprints.
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
