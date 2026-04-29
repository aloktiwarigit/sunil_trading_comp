// ═══════════════════════════════════════════════════════════════════════════
// BharosaLanding — "Editorial Showroom" landing screen.
//
// Aesthetic: Myntra's aspirational banners + Flipkart's clean category
// circles + Amazon's image-dominant product grid + Meesho's streamlined
// simplicity. The shopkeeper's voice greeting is the ONE feature no
// Flipkart/Amazon/Myntra has — it gets the warmest visual treatment.
//
// Layout rhythm (intentional pacing — dense→breathe→dense→breathe):
//   1. Header bar (dense — compact, functional)
//   2. Hero carousel (BREATHE — full-bleed, aspirational)
//   3. Category circles (dense — quick scan, functional)
//   4. Voice greeting (BREATHE — warm, personal, unique)
//   5. Product grid (dense — shopping mode, browsing)
//   6. Trust footer (BREATHE — confidence, closure)
//
// ALL strings from AppStrings. ALL theme from context.yugmaTheme.
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../locale/strings_base.dart';
import '../../models/inventory_sku.dart';
import '../../theme/tokens.dart';
import '../../theme/yugma_theme_extension.dart';
import 'shopkeeper_face_frame.dart';
import 'shopkeeper_presence_dock.dart';

/// Data class for the curated shortlist preview tiles.
class CuratedShortlistPreview {
  final String occasionTag;
  final String occasionLabel;
  final int skuCount;

  const CuratedShortlistPreview({
    required this.occasionTag,
    required this.occasionLabel,
    required this.skuCount,
  });
}

/// The Bharosa landing screen — first screen every customer sees.
class BharosaLanding extends StatefulWidget {
  final void Function(String occasionTag) onShortlistTap;
  final VoidCallback onGreetingPlay;
  final bool autoPlayGreeting;
  final VoidCallback onPresenceVoiceNote;
  final List<CuratedShortlistPreview> previewShortlists;
  final AppStrings strings;
  final bool hasGreetingVoiceNote;
  final int greetingDurationSeconds;
  final VoidCallback? onLocaleToggle;
  final String currentLocaleCode;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onMyListTap;
  final VoidCallback? onOrdersTap;
  final VoidCallback? onUdhaarTap;
  final String? shopLifecycle;
  final DateTime? dpdpRetentionUntil;
  final VoidCallback? onDeactivationFaqTap;
  final String presenceStatus;
  final String presenceMessage;
  final Widget? deactivationBanner;
  final Widget? presenceBanner;
  final List<InventorySku> featuredProducts;
  final void Function(String skuId)? onProductTap;

  const BharosaLanding({
    super.key,
    required this.onShortlistTap,
    required this.onGreetingPlay,
    required this.autoPlayGreeting,
    required this.onPresenceVoiceNote,
    required this.previewShortlists,
    required this.strings,
    this.hasGreetingVoiceNote = false,
    this.greetingDurationSeconds = 0,
    this.onLocaleToggle,
    this.currentLocaleCode = 'hi',
    this.onRefresh,
    this.onMyListTap,
    this.onOrdersTap,
    this.onUdhaarTap,
    this.shopLifecycle,
    this.dpdpRetentionUntil,
    this.onDeactivationFaqTap,
    this.presenceStatus = 'available',
    this.presenceMessage = '',
    this.deactivationBanner,
    this.presenceBanner,
    this.featuredProducts = const [],
    this.onProductTap,
  });

  @override
  State<BharosaLanding> createState() => _BharosaLandingState();
}

class _BharosaLandingState extends State<BharosaLanding>
    with SingleTickerProviderStateMixin {
  bool _isMuted = false;
  late final AnimationController _entranceController;
  late final PageController _bannerController;
  Timer? _bannerTimer;
  int _currentBannerPage = 0;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _bannerController = PageController(viewportFraction: 0.92);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entranceController.forward();
      if (widget.autoPlayGreeting && widget.hasGreetingVoiceNote && !_isMuted) {
        Future.delayed(
          const Duration(milliseconds: 800),
          widget.onGreetingPlay,
        );
      }
      _startBannerAutoScroll();
    });
  }

  void _startBannerAutoScroll() {
    if (widget.featuredProducts.length <= 1) return;
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_bannerController.hasClients) return;
      _currentBannerPage =
          (_currentBannerPage + 1) % widget.featuredProducts.take(4).length;
      _bannerController.animateToPage(
        _currentBannerPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  // ── Occasion → icon mapping ──
  static IconData _occasionIcon(String tag) => switch (tag) {
        'shaadi' => Icons.favorite_rounded,
        'naya_ghar' => Icons.home_rounded,
        'beti_ka_ghar' => Icons.card_giftcard_rounded,
        'replacement' => Icons.swap_horiz_rounded,
        'budget' => Icons.savings_rounded,
        _ => Icons.category_rounded,
      };

  // ── Occasion → accent color mapping ──
  static Color _occasionColor(String tag) => switch (tag) {
        'shaadi' => const Color(0xFFD81B60),
        'naya_ghar' => const Color(0xFF2E7D32),
        'beti_ka_ghar' => const Color(0xFFE65100),
        'replacement' => const Color(0xFF3949AB),
        'budget' => const Color(0xFF00796B),
        _ => const Color(0xFF546E7A),
      };

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;
    final years = DateTime.now().year - theme.establishedYear;
    final products = widget.featuredProducts;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5), // Neutral warm grey
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── 0. Deactivation Banner ──
                      if (widget.deactivationBanner != null)
                        widget.deactivationBanner!,

                      // ── 1. HEADER BAR ──
                      _HeaderBar(
                        theme: theme,
                        years: years,
                        entranceController: _entranceController,
                        currentLocaleCode: widget.currentLocaleCode,
                        onLocaleToggle: widget.onLocaleToggle,
                      ),

                      // ── 1b. Presence Banner ──
                      if (widget.presenceBanner != null) widget.presenceBanner!,

                      // ── 2. HERO CAROUSEL ──
                      if (products.isNotEmpty)
                        _buildBannerCarousel(theme, products),

                      // ── 3. CATEGORY CIRCLES ──
                      if (widget.previewShortlists.isNotEmpty)
                        _buildCategoryStrip(theme),

                      // ── 4. VOICE GREETING (the warm moment) ──
                      if (widget.hasGreetingVoiceNote)
                        _buildVoiceGreeting(theme),

                      // ── 5. PRODUCT GRID ──
                      if (products.isNotEmpty)
                        _buildProductGrid(theme, products),

                      // ── 6. TRUST FOOTER ──
                      _buildTrustFooter(theme, years),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
              // Dock
              ShopkeeperPresenceDock(
                onVoiceNote: widget.onPresenceVoiceNote,
                strings: widget.strings,
                onMyListTap: widget.onMyListTap,
                onOrdersTap: widget.onOrdersTap,
                onUdhaarTap: widget.onUdhaarTap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 2. HERO CAROUSEL — Myntra-style peek carousel with depth
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildBannerCarousel(
      YugmaThemeExtension theme, List<InventorySku> products) {
    final bannerItems = products.take(4).toList();
    if (bannerItems.isEmpty) return const SizedBox.shrink();

    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.15, 0.7, curve: Curves.easeOut),
      ),
      child: Column(
        children: [
          const SizedBox(height: YugmaSpacing.s3),
          SizedBox(
            height: 210,
            child: PageView.builder(
              controller: _bannerController,
              itemCount: bannerItems.length,
              onPageChanged: (i) => setState(() => _currentBannerPage = i),
              itemBuilder: (context, index) {
                final product = bannerItems[index];
                final imageUrl = product.fallbackPhotoUrls.isNotEmpty
                    ? product.fallbackPhotoUrls.first
                    : null;

                return _ScaleOnScroll(
                  controller: _bannerController,
                  index: index,
                  currentPage: _currentBannerPage,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onProductTap?.call(product.skuId);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Product image — full bleed
                          if (imageUrl != null)
                            Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _BannerPlaceholder(theme: theme),
                            )
                          else
                            _BannerPlaceholder(theme: theme),

                          // Cinematic gradient — stronger, more dramatic
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  stops: const [0.0, 0.45, 1.0],
                                  colors: [
                                    Colors.black.withValues(alpha: 0.05),
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.75),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Floating price badge — top-right
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Text(
                                '\u20B9${_formatPrice(product.basePrice)}',
                                style: TextStyle(
                                  fontFamily: YugmaFonts.mono,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: theme.shopPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                          ),

                          // Product name + CTA — bottom
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 14,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        product.nameDevanagari,
                                        style: TextStyle(
                                          fontFamily:
                                              theme.fontFamilyDevanagariDisplay,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          height: YugmaLineHeights.tight,
                                          shadows: const [
                                            Shadow(
                                              offset: Offset(0, 1),
                                              blurRadius: 6,
                                              color: Color(0x66000000),
                                            ),
                                          ],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (product.description.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 3),
                                          child: Text(
                                            product.description,
                                            style: TextStyle(
                                              fontFamily: theme
                                                  .fontFamilyDevanagariBody,
                                              fontSize: 12,
                                              color: Colors.white
                                                  .withValues(alpha: 0.8),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // CTA pill
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '\u0926\u0947\u0916\u093F\u090F',
                                    style: TextStyle(
                                      fontFamily:
                                          theme.fontFamilyDevanagariBody,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: theme.shopPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Page indicator — pill style like Myntra
          if (bannerItems.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(bannerItems.length, (i) {
                  final isActive = i == _currentBannerPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    width: isActive ? 24 : 8,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isActive
                          ? theme.shopPrimary
                          : theme.shopPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 3. CATEGORY STRIP — Flipkart-style clean circles
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildCategoryStrip(YugmaThemeExtension theme) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.3, 0.85, curve: Curves.easeOut),
      ),
      child: Container(
        margin: const EdgeInsets.only(top: YugmaSpacing.s5),
        padding: const EdgeInsets.symmetric(vertical: YugmaSpacing.s4),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header with accent underline
            Padding(
              padding: const EdgeInsets.only(
                left: YugmaSpacing.s4,
                right: YugmaSpacing.s4,
                bottom: YugmaSpacing.s4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.strings.shortlistPreviewHeadline(theme.ownerName),
                    style: TextStyle(
                      fontFamily: theme.fontFamilyDevanagariDisplay,
                      fontSize: 17,
                      color: theme.shopTextPrimary,
                      fontWeight: FontWeight.w600,
                      height: YugmaLineHeights.tight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Accent underline — 36px, 2.5px thick
                  Container(
                    width: 36,
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: theme.shopAccent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
            // Scrollable category circles
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: YugmaSpacing.s4,
                ),
                itemCount: widget.previewShortlists.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: YugmaSpacing.s4),
                itemBuilder: (context, index) {
                  final s = widget.previewShortlists[index];
                  final color = _occasionColor(s.occasionTag);

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onShortlistTap(s.occasionTag);
                    },
                    child: SizedBox(
                      width: 68,
                      child: Column(
                        children: [
                          // Circle with tinted background
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color.withValues(alpha: 0.08),
                              border: Border.all(
                                color: color.withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              _occasionIcon(s.occasionTag),
                              color: color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            s.occasionLabel,
                            style: TextStyle(
                              fontFamily: theme.fontFamilyDevanagariBody,
                              fontSize: 11,
                              color: theme.shopTextPrimary,
                              fontWeight: FontWeight.w500,
                              height: YugmaLineHeights.tight,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 4. VOICE GREETING — the warm, personal moment
  //    This is the ONE section that breaks the neutral/white pattern
  //    with a warm gradient to signal "this is different, this is us."
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildVoiceGreeting(YugmaThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        YugmaSpacing.s4,
        YugmaSpacing.s5,
        YugmaSpacing.s4,
        0,
      ),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            widget.onGreetingPlay();
          },
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.shopPrimary,
                  theme.shopPrimaryDeep,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(YugmaSpacing.s4),
              child: Row(
                children: [
                  // Face — large enough to feel personal
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const ShopkeeperFaceFrame(size: 48),
                  ),
                  const SizedBox(width: YugmaSpacing.s3),
                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.strings.greetingCardTitle,
                          style: TextStyle(
                            fontFamily: theme.fontFamilyDevanagariDisplay,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.strings.greetingVoiceNoteSublabel(
                            theme.ownerName,
                            widget.greetingDurationSeconds,
                          ),
                          style: TextStyle(
                            fontFamily: theme.fontFamilyDevanagariBody,
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: YugmaSpacing.s2),
                  // Waveform bars + play circle
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Mini waveform
                      ...([
                        5.0,
                        12.0,
                        7.0,
                        16.0,
                        9.0,
                        13.0,
                        6.0
                      ].map((h) => Container(
                            width: 2.5,
                            height: h,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color:
                                  theme.shopAccentGlow.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ))),
                      const SizedBox(width: 10),
                      // Play circle
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(
                          _isMuted
                              ? Icons.volume_off_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 5. PRODUCT GRID — Amazon/Flipkart style, image-dominant
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildProductGrid(
      YugmaThemeExtension theme, List<InventorySku> products) {
    return Container(
      margin: const EdgeInsets.only(top: YugmaSpacing.s5),
      padding: const EdgeInsets.only(
        top: YugmaSpacing.s4,
        bottom: YugmaSpacing.s4,
      ),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.only(
              left: YugmaSpacing.s4,
              right: YugmaSpacing.s4,
              bottom: YugmaSpacing.s4,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // "सुनील भैया की पसंद" → "बेस्ट सेलर"
                        '\u092C\u0947\u0938\u094D\u091F \u0938\u0947\u0932\u0930',
                        style: TextStyle(
                          fontFamily: theme.fontFamilyDevanagariDisplay,
                          fontSize: 17,
                          color: theme.shopTextPrimary,
                          fontWeight: FontWeight.w600,
                          height: YugmaLineHeights.tight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 36,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: theme.shopAccent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                // "See all" — pill button
                GestureDetector(
                  onTap: widget.onMyListTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.shopPrimary.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(
                        YugmaRadius.pill,
                      ),
                    ),
                    child: Text(
                      '\u0938\u092C \u0926\u0947\u0916\u0947\u0902',
                      style: TextStyle(
                        fontFamily: theme.fontFamilyDevanagariBody,
                        fontSize: 12,
                        color: theme.shopPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 2-column product grid
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: YugmaSpacing.s4,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tileWidth = (constraints.maxWidth - 10) / 2;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: products.map((product) {
                    return _ProductCard(
                      product: product,
                      width: tileWidth,
                      theme: theme,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onProductTap?.call(product.skuId);
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 6. TRUST FOOTER — confidence & closure
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildTrustFooter(YugmaThemeExtension theme, int years) {
    return Padding(
      padding: const EdgeInsets.only(
        top: YugmaSpacing.s6,
        bottom: YugmaSpacing.s2,
        left: YugmaSpacing.s4,
        right: YugmaSpacing.s4,
      ),
      child: Column(
        children: [
          // Three trust columns
          Row(
            children: [
              _TrustColumn(
                icon: Icons.verified_rounded,
                value: '$years+',
                label:
                    '\u0938\u093E\u0932 \u0915\u093E \u0905\u0928\u0941\u092D\u0935',
                theme: theme,
              ),
              Container(
                width: 1,
                height: 36,
                color: theme.shopDivider,
              ),
              _TrustColumn(
                icon: Icons.storefront_rounded,
                value: theme.marketArea,
                label: theme.city,
                theme: theme,
              ),
              Container(
                width: 1,
                height: 36,
                color: theme.shopDivider,
              ),
              _TrustColumn(
                icon: Icons.local_shipping_outlined,
                value: '\u0921\u093F\u0932\u0940\u0935\u0930\u0940',
                label: '\u0918\u0930 \u092A\u0930',
                theme: theme,
              ),
            ],
          ),
          const SizedBox(height: YugmaSpacing.s5),
          // Brand lockup
          Text(
            theme.brandName,
            style: TextStyle(
              fontFamily: theme.fontFamilyDevanagariDisplay,
              fontSize: 14,
              color: theme.shopTextMuted.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            theme.taglineDevanagari,
            style: TextStyle(
              fontFamily: theme.fontFamilyDevanagariBody,
              fontSize: 11,
              color: theme.shopTextMuted.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  /// Format price with Indian comma grouping (1,23,456).
  static String _formatPrice(int price) {
    if (price < 1000) return '$price';
    final str = price.toString();
    final last3 = str.substring(str.length - 3);
    var rest = str.substring(0, str.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '${parts.join(',')},${last3}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EXTRACTED WIDGETS — clean separation for readability
// ═══════════════════════════════════════════════════════════════════════════

/// Compact header bar — Flipkart-inspired.
class _HeaderBar extends StatelessWidget {
  final YugmaThemeExtension theme;
  final int years;
  final AnimationController entranceController;
  final String currentLocaleCode;
  final VoidCallback? onLocaleToggle;

  const _HeaderBar({
    required this.theme,
    required this.years,
    required this.entranceController,
    required this.currentLocaleCode,
    this.onLocaleToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: YugmaSpacing.s4,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: theme.shopPrimary,
        boxShadow: [
          BoxShadow(
            color: theme.shopPrimaryDeep.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Shop face
          ScaleTransition(
            scale: CurvedAnimation(
              parent: entranceController,
              curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
            ),
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: const ShopkeeperFaceFrame(size: 32),
            ),
          ),
          const SizedBox(width: YugmaSpacing.s3),
          // Brand name
          Expanded(
            child: Text(
              theme.brandName,
              style: TextStyle(
                fontFamily: theme.fontFamilyDevanagariDisplay,
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Status pill
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20).withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(YugmaRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Color(0xFF66BB6A),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '\u0916\u0941\u0932\u093E \u0939\u0948',
                  style: TextStyle(
                    fontFamily: theme.fontFamilyDevanagariBody,
                    fontSize: 10,
                    color: const Color(0xFFA5D6A7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (onLocaleToggle != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onLocaleToggle!();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(
                    YugmaRadius.pill,
                  ),
                ),
                child: Text(
                  currentLocaleCode == 'hi' ? 'EN' : '\u0939\u093F\u0902',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Product card — image-dominant, clean price, stock badge.
class _ProductCard extends StatelessWidget {
  final InventorySku product;
  final double width;
  final YugmaThemeExtension theme;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.width,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.fallbackPhotoUrls.isNotEmpty
        ? product.fallbackPhotoUrls.first
        : null;

    // Calculate fake MRP (20-30% higher) for strikethrough effect
    final mrp = (product.basePrice * 1.25).round();
    final discountPct = (((mrp - product.basePrice) / mrp) * 100).round();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 0.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image — 1:1 aspect
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    )
                  else
                    _imagePlaceholder(),

                  // Discount badge — top-left (like Flipkart)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF388E3C),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$discountPct% OFF',
                        style: const TextStyle(
                          fontFamily: 'DM Mono',
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  // Wishlist heart — top-right (like Godrej Interio)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.favorite_border_rounded,
                        size: 16,
                        color: theme.shopTextMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Product info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    product.nameDevanagari,
                    style: TextStyle(
                      fontFamily: theme.fontFamilyDevanagariBody,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: theme.shopTextPrimary,
                      height: YugmaLineHeights.snug,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Price row — selling price + MRP strikethrough
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '\u20B9${_BharosaLandingState._formatPrice(product.basePrice)}',
                        style: TextStyle(
                          fontFamily: YugmaFonts.mono,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: theme.shopTextPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // MRP strikethrough
                      Text(
                        '\u20B9${_BharosaLandingState._formatPrice(mrp)}',
                        style: TextStyle(
                          fontFamily: YugmaFonts.mono,
                          fontSize: 11,
                          color: theme.shopTextMuted,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: theme.shopTextMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Dimensions
                  Text(
                    '${product.dimensions.heightCm} \u00D7 ${product.dimensions.widthCm} \u00D7 ${product.dimensions.depthCm} cm',
                    style: TextStyle(
                      fontFamily: YugmaFonts.mono,
                      fontSize: 10,
                      color: theme.shopTextMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // "Free delivery" tag (like Amazon/Flipkart)
                  Row(
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        size: 12,
                        color: theme.shopAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '\u092B\u094D\u0930\u0940 \u0921\u093F\u0932\u0940\u0935\u0930\u0940',
                        style: TextStyle(
                          fontFamily: theme.fontFamilyDevanagariBody,
                          fontSize: 10,
                          color: theme.shopAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFF0F0F0),
      child: Center(
        child: Icon(
          Icons.kitchen_rounded,
          size: 44,
          color: const Color(0xFFBDBDBD),
        ),
      ),
    );
  }
}

/// Banner placeholder when no product image is available.
class _BannerPlaceholder extends StatelessWidget {
  final YugmaThemeExtension theme;
  const _BannerPlaceholder({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.shopSecondary.withValues(alpha: 0.2),
            theme.shopPrimaryDeep.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.kitchen_rounded,
          size: 56,
          color: theme.shopPrimary.withValues(alpha: 0.15),
        ),
      ),
    );
  }
}

/// Trust footer column.
class _TrustColumn extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final YugmaThemeExtension theme;

  const _TrustColumn({
    required this.icon,
    required this.value,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: theme.shopTextMuted),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: theme.fontFamilyDevanagariBody,
              fontSize: 12,
              color: theme.shopTextPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
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
      ),
    );
  }
}

/// Scales carousel items based on distance from current page.
class _ScaleOnScroll extends StatelessWidget {
  final PageController controller;
  final int index;
  final int currentPage;
  final Widget child;

  const _ScaleOnScroll({
    required this.controller,
    required this.index,
    required this.currentPage,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        double scale = 1.0;
        if (controller.position.haveDimensions) {
          final page = controller.page ?? currentPage.toDouble();
          scale = 1.0 - (page - index).abs() * 0.06;
          scale = scale.clamp(0.9, 1.0);
        }
        return Transform.scale(scale: scale, child: child!);
      },
      child: child,
    );
  }
}
