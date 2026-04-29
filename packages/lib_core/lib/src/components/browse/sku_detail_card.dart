// =============================================================================
// SkuDetailCard — Godrej Interio-inspired product detail page.
//
// Layout:
//   1. Image gallery with page dots (swipe between photos)
//   2. Price section: selling price + MRP strikethrough + discount badge
//   3. Product name + description
//   4. Specs table (dimensions, material, warranty)
//   5. Delivery & trust signals
//   6. Action buttons: "Add to List" + "Talk to Bhaiya"
//
// All strings from AppStrings. All colors via context.yugmaTheme.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../locale/strings_base.dart';
import '../../utils/format_inr.dart';
import '../../models/inventory_sku.dart';
import '../../theme/tokens.dart';
import '../../theme/yugma_theme_extension.dart';

/// Full SKU detail view — image gallery + specs + action buttons.
class SkuDetailCard extends StatefulWidget {
  final InventorySku sku;
  final AppStrings strings;
  final String goldenHourPhotoUrl;
  final String? workingLightPhotoUrl;
  final VoidCallback? onAddToList;
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
  State<SkuDetailCard> createState() => _SkuDetailCardState();
}

class _SkuDetailCardState extends State<SkuDetailCard> {
  int _currentImageIndex = 0;

  List<String> get _imageUrls {
    final urls = <String>[];
    if (widget.goldenHourPhotoUrl.isNotEmpty) {
      urls.add(widget.goldenHourPhotoUrl);
    }
    if (widget.workingLightPhotoUrl != null &&
        widget.workingLightPhotoUrl!.isNotEmpty) {
      urls.add(widget.workingLightPhotoUrl!);
    }
    // Also add any remaining fallback URLs
    for (final url in widget.sku.fallbackPhotoUrls) {
      if (!urls.contains(url)) urls.add(url);
    }
    return urls;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;
    final sku = widget.sku;
    final images = _imageUrls;

    // MRP calculation (25% markup for display)
    final mrp = (sku.basePrice * 1.25).round();
    final discountPct = (((mrp - sku.basePrice) / mrp) * 100).round();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. IMAGE GALLERY ──
                  _buildImageGallery(theme, images),

                  // ── 2. PRICE SECTION ──
                  _buildPriceSection(theme, sku, mrp, discountPct),

                  // Divider
                  Divider(height: 1, color: theme.shopDivider),

                  // ── 3. NAME + DESCRIPTION ──
                  _buildProductInfo(theme, sku),

                  // Divider
                  Divider(height: 1, color: theme.shopDivider),

                  // ── 4. SPECS TABLE ──
                  _buildSpecsTable(theme, sku),

                  // Divider
                  Divider(height: 1, color: theme.shopDivider),

                  // ── 5. DELIVERY & TRUST ──
                  _buildTrustSection(theme),

                  const SizedBox(height: 100), // Button clearance
                ],
              ),
            ),
          ),

          // ── 6. STICKY ACTION BUTTONS ──
          _buildStickyButtons(theme, sku),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 1. IMAGE GALLERY — swipeable with page dots
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildImageGallery(
      YugmaThemeExtension theme, List<String> images) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        // Image carousel
        SizedBox(
          height: screenWidth, // 1:1 square
          child: images.isEmpty
              ? Container(
                  color: const Color(0xFFF5F5F5),
                  child: Center(
                    child: Icon(Icons.kitchen_rounded,
                        size: 80, color: theme.shopDivider),
                  ),
                )
              : PageView.builder(
                  itemCount: images.length,
                  onPageChanged: (i) =>
                      setState(() => _currentImageIndex = i),
                  itemBuilder: (context, index) {
                    return Image.network(
                      images[index],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFF5F5F5),
                        child: Center(
                          child: Icon(Icons.kitchen_rounded,
                              size: 80, color: theme.shopDivider),
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Back button — top-left
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 20),
            ),
          ),
        ),

        // Share button — top-right
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 8,
          child: Material(
            color: Colors.white.withValues(alpha: 0.9),
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                HapticFeedback.lightImpact();
              },
              child: const SizedBox(
                width: 40, height: 40,
                child: Icon(Icons.share_outlined, size: 20),
              ),
            ),
          ),
        ),

        // Wishlist heart — top-right, below share
        Positioned(
          top: MediaQuery.of(context).padding.top + 56,
          right: 8,
          child: Material(
            color: Colors.white.withValues(alpha: 0.9),
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                HapticFeedback.lightImpact();
              },
              child: const SizedBox(
                width: 40, height: 40,
                child: Icon(Icons.favorite_border_rounded, size: 20),
              ),
            ),
          ),
        ),

        // Page indicator dots — bottom center
        if (images.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (i) {
                final isActive = i == _currentImageIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: isActive ? 20 : 8,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isActive
                        ? theme.shopPrimary
                        : Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),

        // Image count badge — bottom-right
        if (images.length > 1)
          Positioned(
            bottom: 12,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentImageIndex + 1}/${images.length}',
                style: const TextStyle(
                  fontFamily: 'DM Mono',
                  fontSize: 11,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 2. PRICE SECTION — like Godrej Interio / Flipkart
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildPriceSection(
      YugmaThemeExtension theme, InventorySku sku, int mrp, int discountPct) {
    return Padding(
      padding: const EdgeInsets.all(YugmaSpacing.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          // Selling price — large
          Text(
            '\u20B9${formatInr(sku.basePrice)}',
            style: TextStyle(
              fontFamily: YugmaFonts.mono,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: theme.shopTextPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 10),
          // MRP strikethrough
          Text(
            'MRP \u20B9${formatInr(mrp)}',
            style: TextStyle(
              fontFamily: YugmaFonts.mono,
              fontSize: 14,
              color: theme.shopTextMuted,
              decoration: TextDecoration.lineThrough,
              decorationColor: theme.shopTextMuted,
            ),
          ),
          const SizedBox(width: 10),
          // Discount badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 3,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF388E3C),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$discountPct% OFF',
              style: const TextStyle(
                fontFamily: 'DM Mono',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 3. NAME + DESCRIPTION
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildProductInfo(YugmaThemeExtension theme, InventorySku sku) {
    return Padding(
      padding: const EdgeInsets.all(YugmaSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Devanagari name
          Text(
            sku.nameDevanagari,
            style: TextStyle(
              fontFamily: theme.fontFamilyDevanagariDisplay,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: theme.shopTextPrimary,
              height: YugmaLineHeights.snug,
            ),
          ),
          const SizedBox(height: 4),
          // English name
          Text(
            sku.name,
            style: TextStyle(
              fontFamily: theme.fontFamilyEnglishBody,
              fontSize: 14,
              color: theme.shopTextSecondary,
            ),
          ),
          if (sku.description.isNotEmpty) ...[
            const SizedBox(height: YugmaSpacing.s4),
            Text(
              sku.description,
              style: TextStyle(
                fontFamily: theme.fontFamilyDevanagariBody,
                fontSize: 14,
                color: theme.shopTextSecondary,
                height: YugmaLineHeights.normal,
              ),
            ),
          ],
          // Negotiable label
          if (sku.negotiableDownTo < sku.basePrice) ...[
            const SizedBox(height: YugmaSpacing.s3),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5,
              ),
              decoration: BoxDecoration(
                color: theme.shopAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.handshake_outlined,
                      size: 16, color: theme.shopAccent),
                  const SizedBox(width: 6),
                  Text(
                    widget.strings.skuNegotiableLabel,
                    style: TextStyle(
                      fontFamily: theme.fontFamilyDevanagariBody,
                      fontSize: 13,
                      color: theme.shopAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 4. SPECS TABLE — clean rows like Godrej Interio
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildSpecsTable(YugmaThemeExtension theme, InventorySku sku) {
    return Padding(
      padding: const EdgeInsets.all(YugmaSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Text(
            // "विवरण" = Specifications
            '\u0935\u093F\u0935\u0930\u0923',
            style: TextStyle(
              fontFamily: theme.fontFamilyDevanagariDisplay,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.shopTextPrimary,
            ),
          ),
          const SizedBox(height: YugmaSpacing.s3),
          // Specs rows
          _SpecRow(
            label: '\u0938\u093E\u0907\u091C\u093C',
            value:
                '${sku.dimensions.heightCm} \u00D7 ${sku.dimensions.widthCm} \u00D7 ${sku.dimensions.depthCm} cm',
            theme: theme,
          ),
          _SpecRow(
            label: '\u0938\u093E\u092E\u0917\u094D\u0930\u0940',
            value: _materialLabel(sku.material),
            theme: theme,
          ),
          _SpecRow(
            label: '\u0915\u0948\u091F\u0947\u0917\u0930\u0940',
            value: _categoryLabel(sku.category),
            theme: theme,
          ),
          _SpecRow(
            label: '\u0938\u094D\u091F\u0949\u0915',
            value: sku.inStock
                ? '\u0939\u093E\u0901, \u0909\u092A\u0932\u092C\u094D\u0927'
                : '\u0909\u092A\u0932\u092C\u094D\u0927 \u0928\u0939\u0940\u0902',
            theme: theme,
            valueColor: sku.inStock
                ? const Color(0xFF2E7D32)
                : const Color(0xFFC62828),
          ),
          if (sku.stockCount != null)
            _SpecRow(
              label: '\u0938\u0902\u0916\u094D\u092F\u093E',
              value: '${sku.stockCount}',
              theme: theme,
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 5. TRUST SECTION — delivery, warranty signals
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildTrustSection(YugmaThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.all(YugmaSpacing.s4),
      child: Row(
        children: [
          _TrustItem(
            icon: Icons.local_shipping_outlined,
            label:
                '\u092B\u094D\u0930\u0940 \u0921\u093F\u0932\u0940\u0935\u0930\u0940',
            theme: theme,
          ),
          const SizedBox(width: YugmaSpacing.s6),
          _TrustItem(
            icon: Icons.verified_user_outlined,
            label: '10 \u0938\u093E\u0932 \u0935\u093E\u0930\u0902\u091F\u0940',
            theme: theme,
          ),
          const SizedBox(width: YugmaSpacing.s6),
          _TrustItem(
            icon: Icons.swap_horiz_rounded,
            label:
                '\u0906\u0938\u093E\u0928 \u0930\u093F\u091F\u0930\u094D\u0928',
            theme: theme,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 6. STICKY ACTION BUTTONS — pinned at bottom
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildStickyButtons(YugmaThemeExtension theme, InventorySku sku) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        YugmaSpacing.s4, YugmaSpacing.s3,
        YugmaSpacing.s4, YugmaSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // "Talk to Bhaiya" — secondary
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    widget.onTalkToBhaiya?.call();
                  },
                  icon: Icon(Icons.chat_bubble_outline_rounded,
                      size: 18, color: theme.shopPrimary),
                  label: Text(
                    widget.strings.skuTalkToBhaiya,
                    style: TextStyle(
                      fontFamily: theme.fontFamilyDevanagariBody,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.shopPrimary,
                    side: BorderSide(color: theme.shopPrimary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // "Add to List" — primary
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    widget.onAddToList?.call();
                  },
                  icon: const Icon(Icons.add_shopping_cart_rounded,
                      size: 18, color: Colors.white),
                  label: Text(
                    widget.strings.skuAddToList,
                    style: TextStyle(
                      fontFamily: theme.fontFamilyDevanagariBody,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.shopPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _materialLabel(SkuMaterial material) => switch (material) {
        SkuMaterial.steel =>
            '\u0938\u094D\u091F\u0940\u0932 (Steel)',
        SkuMaterial.woodSheesham =>
            '\u0936\u0940\u0936\u092E (Sheesham)',
        SkuMaterial.woodTeak =>
            '\u0938\u093E\u0917\u094C\u0928 (Teak)',
        SkuMaterial.plyLaminate =>
            '\u092A\u094D\u0932\u093E\u0908/\u0932\u0948\u092E\u093F\u0928\u0947\u091F',
      };

  static String _categoryLabel(SkuCategory category) => switch (category) {
        SkuCategory.steelAlmirah =>
            '\u0938\u094D\u091F\u0940\u0932 \u0905\u0932\u092E\u093E\u0930\u0940',
        SkuCategory.woodenWardrobe =>
            '\u0932\u0915\u0921\u093C\u0940 \u0935\u093E\u0930\u094D\u0921\u0930\u094B\u092C',
        SkuCategory.modular =>
            '\u092E\u0949\u0921\u094D\u092F\u0941\u0932\u0930',
        SkuCategory.dressing =>
            '\u0921\u094D\u0930\u0947\u0938\u093F\u0902\u0917 \u091F\u0947\u092C\u0932',
        SkuCategory.sideCabinet =>
            '\u0938\u093E\u0907\u0921 \u0915\u0948\u092C\u093F\u0928\u0947\u091F',
      };
}

/// A single spec row — label: value.
class _SpecRow extends StatelessWidget {
  final String label;
  final String value;
  final YugmaThemeExtension theme;
  final Color? valueColor;

  const _SpecRow({
    required this.label,
    required this.value,
    required this.theme,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: theme.fontFamilyDevanagariBody,
                fontSize: 13,
                color: theme.shopTextMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: theme.fontFamilyDevanagariBody,
                fontSize: 13,
                color: valueColor ?? theme.shopTextPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Trust item — icon + label.
class _TrustItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final YugmaThemeExtension theme;

  const _TrustItem({
    required this.icon,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 22, color: theme.shopAccent),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: theme.fontFamilyDevanagariBody,
            fontSize: 10,
            color: theme.shopTextMuted,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
