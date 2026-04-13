// BharosaLanding — the customer app's landing screen.
//
// The SINGLE MOST IMPORTANT widget in the customer app. Per Brief §3:
// "the first screen IS the shopkeeper."
//
// This widget OWNS:
//   - The hero photo of Sunil-bhaiya's face (top 40% of screen)
//   - The shop name in Devanagari
//   - The greeting voice note auto-play card (B1.3)
//   - The curated shortlist preview ("Sunil-bhaiya ki pasand")
//   - The Shopkeeper Presence Dock (replaces bottom-tab nav)
//
// ALL strings sourced from AppStrings. NO hardcoded Devanagari.
// ALL theme from context.yugmaTheme. NO hardcoded colors/fonts.
//
// Maps to PRD B1.1, B1.2, B1.3.
// Maps to UX Spec §8.1, §8.2, §8.3.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../locale/strings_base.dart';
import '../../theme/tokens.dart';
import '../../theme/yugma_theme_extension.dart';
import '../yugma_connectivity_banner.dart';
import 'shopkeeper_face_frame.dart';
import 'shopkeeper_presence_dock.dart';

/// Data class for the curated shortlist preview tiles shown on the
/// landing screen. Max 4 tiles — the rest are below the fold on the
/// curation tab (B1.4).
class CuratedShortlistPreview {
  /// Occasion tag slug (e.g., "shaadi", "naya_ghar").
  final String occasionTag;

  /// Localized occasion label (from AppStrings shortlist title keys).
  final String occasionLabel;

  /// Number of SKUs in this shortlist.
  final int skuCount;

  const CuratedShortlistPreview({
    required this.occasionTag,
    required this.occasionLabel,
    required this.skuCount,
  });
}

/// The Bharosa landing screen — first screen every customer sees.
///
/// B1.2 AC #1: Shopkeeper face as dominant visual (top 40%).
/// B1.2 AC #5: Shopkeeper Presence Dock (NOT bottom-tab nav).
/// B1.2 AC #7: EN/हिं locale toggle in top-right.
/// B1.3 AC #1-7: Greeting voice note auto-play card.
class BharosaLanding extends StatefulWidget {
  /// Called when the customer taps a curated shortlist tile.
  final void Function(String occasionTag) onShortlistTap;

  /// Called when the customer taps the greeting voice note play button.
  final VoidCallback onGreetingPlay;

  /// Whether auto-play is enabled (respects mute preference).
  final bool autoPlayGreeting;

  /// Called when the presence dock voice note button is tapped.
  final VoidCallback onPresenceVoiceNote;

  /// Pre-fetched curated shortlist tiles (max 4).
  final List<CuratedShortlistPreview> previewShortlists;

  /// Locale strings.
  final AppStrings strings;

  /// Whether a greeting voice note exists for this shop.
  /// Per B1.3 AC #8: if false, the greeting card is suppressed entirely.
  final bool hasGreetingVoiceNote;

  /// Duration of the greeting voice note in seconds.
  final int greetingDurationSeconds;

  /// Called when the locale toggle is tapped.
  /// B1.2 AC #7.
  final VoidCallback? onLocaleToggle;

  /// Current locale code ('hi' or 'en') for the toggle display.
  final String currentLocaleCode;

  /// Called on pull-to-refresh. B1.2 AC #6.
  final Future<void> Function()? onRefresh;

  /// B-2: Called when dock "My List" icon is tapped.
  final VoidCallback? onMyListTap;

  /// B-2: Called when dock "My Orders" icon is tapped.
  final VoidCallback? onOrdersTap;

  /// B-2: Called when dock "Udhaar" icon is tapped.
  final VoidCallback? onUdhaarTap;

  /// C3.12: Shop lifecycle string for DeactivationBanner.
  final String? shopLifecycle;

  /// C3.12: DPDP retention deadline.
  final DateTime? dpdpRetentionUntil;

  /// C3.12: Called when deactivation FAQ is tapped.
  final VoidCallback? onDeactivationFaqTap;

  /// B1.9: Presence status ('available', 'away', 'busyWithCustomer', 'atEvent').
  final String presenceStatus;

  /// B1.9: Presence message to display.
  final String presenceMessage;

  /// Optional banner widget shown at the top of the body when the shop is
  /// deactivating. Passed from the router so lib_core stays decoupled.
  final Widget? deactivationBanner;

  /// Optional presence banner shown between hero and trust bar.
  final Widget? presenceBanner;

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
  });

  @override
  State<BharosaLanding> createState() => _BharosaLandingState();
}

class _BharosaLandingState extends State<BharosaLanding>
    with SingleTickerProviderStateMixin {
  bool _isMuted = false;
  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entranceController.forward();
      // B1.3 AC #3: auto-play within 2 seconds of cold launch
      if (widget.autoPlayGreeting &&
          widget.hasGreetingVoiceNote &&
          !_isMuted) {
        Future.delayed(
          const Duration(milliseconds: 800),
          widget.onGreetingPlay,
        );
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;

    final years = DateTime.now().year - theme.establishedYear;

    // Brass dot separator
    Widget brassDot() => Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: theme.shopAccent.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
        );

    // Brass ornament line (─ ◆ ─)
    Widget brassOrnament({double width = 100}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: width * 0.4,
              height: 1,
              color: theme.shopAccent.withValues(alpha: 0.4),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '\u25C6',
                style: TextStyle(
                  fontSize: 8,
                  color: theme.shopAccent.withValues(alpha: 0.6),
                ),
              ),
            ),
            Container(
              width: width * 0.4,
              height: 1,
              color: theme.shopAccent.withValues(alpha: 0.4),
            ),
          ],
        );

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.shopBackground,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── 0. Deactivation Banner (C3.12) ──
                      if (widget.deactivationBanner != null)
                        widget.deactivationBanner!,

                      // ── 1. HERO SECTION (content-sized) ──
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              theme.shopSecondary,
                              theme.shopPrimary,
                              theme.shopPrimaryDeep,
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Locale toggle pill (EN/हिं) — top-right
                            if (widget.onLocaleToggle != null)
                              Positioned(
                                top: YugmaSpacing.s3,
                                right: YugmaSpacing.s4,
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    widget.onLocaleToggle!();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(
                                        YugmaRadius.pill,
                                      ),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Text(
                                      widget.currentLocaleCode == 'hi'
                                          ? 'EN'
                                          : '\u0939\u093F\u0902',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: theme.shopTextOnPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // Center column content
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 24,
                                bottom: 28,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Face frame with brass border ring
                                    ScaleTransition(
                                      scale: CurvedAnimation(
                                        parent: _entranceController,
                                        curve: const Interval(
                                          0.0,
                                          0.6,
                                          curve: Curves.easeOutBack,
                                        ),
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: theme.shopAccentGlow
                                                .withValues(alpha: 0.5),
                                            width: 3,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 16,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const ShopkeeperFaceFrame(
                                          size: 130,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: YugmaSpacing.s4),

                                    // Name + ornament + tagline + brand
                                    FadeTransition(
                                      opacity: CurvedAnimation(
                                        parent: _entranceController,
                                        curve: const Interval(
                                          0.3,
                                          0.8,
                                          curve: Curves.easeOut,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          // Owner name — large Devanagari
                                          Text(
                                            theme.ownerName,
                                            style: TextStyle(
                                              fontFamily: theme
                                                  .fontFamilyDevanagariDisplay,
                                              fontSize: 28,
                                              color:
                                                  theme.shopTextOnPrimary,
                                              fontWeight: FontWeight.w600,
                                              height:
                                                  YugmaLineHeights.tight,
                                              shadows: const [
                                                Shadow(
                                                  offset: Offset(0, 2),
                                                  blurRadius: 8,
                                                  color: Color(0x66000000),
                                                ),
                                              ],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(
                                            height: YugmaSpacing.s2,
                                          ),

                                          // Brass ornament line
                                          brassOrnament(width: 80),
                                          const SizedBox(
                                            height: YugmaSpacing.s2,
                                          ),

                                          // Tagline in italic
                                          Text(
                                            theme.taglineDevanagari,
                                            style: TextStyle(
                                              fontFamily: theme
                                                  .fontFamilyDevanagariBody,
                                              fontSize: theme.isElderTier
                                                  ? 16
                                                  : 14,
                                              fontStyle: FontStyle.italic,
                                              color: theme
                                                  .shopTextOnPrimary
                                                  .withValues(alpha: 0.9),
                                              height:
                                                  YugmaLineHeights.snug,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(
                                            height: YugmaSpacing.s1,
                                          ),

                                          // Brand name in small caps style
                                          Text(
                                            theme.brandName.toUpperCase(),
                                            style: TextStyle(
                                              fontFamily: theme
                                                  .fontFamilyDevanagariBody,
                                              fontSize: 11,
                                              letterSpacing: 2.0,
                                              color: theme
                                                  .shopTextOnPrimary
                                                  .withValues(alpha: 0.6),
                                              height:
                                                  YugmaLineHeights.snug,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── 1b. Presence Banner (B1.9) ──
                      if (widget.presenceBanner != null)
                        widget.presenceBanner!,

                      // ── 2. TRUST RIBBON (compact inline) ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: YugmaSpacing.s4,
                          vertical: YugmaSpacing.s2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.shopSurface,
                          border: Border(
                            bottom: BorderSide(
                              color:
                                  theme.shopAccent.withValues(alpha: 0.15),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$years+ \u0938\u093E\u0932',
                              style: TextStyle(
                                fontFamily:
                                    theme.fontFamilyDevanagariBody,
                                fontSize: 11,
                                color: theme.shopTextMuted,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: YugmaSpacing.s2,
                              ),
                              child: brassDot(),
                            ),
                            Text(
                              theme.marketArea,
                              style: TextStyle(
                                fontFamily:
                                    theme.fontFamilyDevanagariBody,
                                fontSize: 11,
                                color: theme.shopTextMuted,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: YugmaSpacing.s2,
                              ),
                              child: brassDot(),
                            ),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: YugmaColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: YugmaSpacing.s1),
                            Text(
                              '\u0926\u0941\u0915\u093E\u0928 \u092A\u0930 \u0939\u0948\u0902',
                              style: TextStyle(
                                fontFamily:
                                    theme.fontFamilyDevanagariBody,
                                fontSize: 11,
                                color: theme.shopTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── 3. VOICE GREETING CARD (conditional) ──
                      if (widget.hasGreetingVoiceNote)
                        Padding(
                          padding: const EdgeInsets.all(YugmaSpacing.s4),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              widget.onGreetingPlay();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(
                                YugmaSpacing.s3,
                              ),
                              decoration: BoxDecoration(
                                color: theme.shopPrimary
                                    .withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(
                                  YugmaRadius.lg,
                                ),
                                border: Border.all(
                                  color: theme.shopAccent
                                      .withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Play circle
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: theme.shopAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _isMuted
                                          ? Icons.volume_off
                                          : Icons.play_arrow,
                                      color: theme.shopPrimaryDeep,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: YugmaSpacing.s3),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.strings
                                              .greetingCardTitle,
                                          style: TextStyle(
                                            fontFamily: theme
                                                .fontFamilyDevanagariBody,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: theme.shopPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          widget.strings
                                              .greetingVoiceNoteSublabel(
                                            theme.ownerName,
                                            widget
                                                .greetingDurationSeconds,
                                          ),
                                          style: TextStyle(
                                            fontFamily: theme
                                                .fontFamilyDevanagariBody,
                                            fontSize: 11,
                                            color: theme.shopTextMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // ── 4. COLLECTIONS (2-column grid) ──
                      if (widget.previewShortlists.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            YugmaSpacing.s4,
                            YugmaSpacing.s5,
                            YugmaSpacing.s4,
                            YugmaSpacing.s3,
                          ),
                          child: Text(
                            widget.strings.shortlistPreviewHeadline(
                              theme.ownerName,
                            ),
                            style: TextStyle(
                              fontFamily:
                                  theme.fontFamilyDevanagariDisplay,
                              fontSize: 17,
                              color: theme.shopPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: YugmaSpacing.s4,
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final tileWidth =
                                  (constraints.maxWidth - 12) / 2;
                              return Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: widget.previewShortlists
                                    .map((s) {
                                  return GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      widget
                                          .onShortlistTap(s.occasionTag);
                                    },
                                    child: Container(
                                      width: tileWidth,
                                      height: 110,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            theme.shopPrimary
                                                .withValues(alpha: 0.85),
                                            theme.shopPrimaryDeep,
                                          ],
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.shopPrimaryDeep
                                                .withValues(alpha: 0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        children: [
                                          // Brass corner ornament (top-right L-shape)
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: Container(
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  top: BorderSide(
                                                    color: theme
                                                        .shopAccent
                                                        .withValues(
                                                          alpha: 0.4,
                                                        ),
                                                    width: 1.5,
                                                  ),
                                                  right: BorderSide(
                                                    color: theme
                                                        .shopAccent
                                                        .withValues(
                                                          alpha: 0.4,
                                                        ),
                                                    width: 1.5,
                                                  ),
                                                ),
                                                borderRadius:
                                                    const BorderRadius
                                                        .only(
                                                  topRight:
                                                      Radius.circular(14),
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Content at bottom-left
                                          Positioned(
                                            left: YugmaSpacing.s3,
                                            bottom: YugmaSpacing.s3,
                                            right: YugmaSpacing.s3,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                              mainAxisSize:
                                                  MainAxisSize.min,
                                              children: [
                                                Text(
                                                  s.occasionLabel,
                                                  style: TextStyle(
                                                    fontFamily: theme
                                                        .fontFamilyDevanagariDisplay,
                                                    fontSize: 15,
                                                    color: theme
                                                        .shopAccentGlow,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    height:
                                                        YugmaLineHeights
                                                            .snug,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${s.skuCount} \u0938\u093E\u092E\u093E\u0928 \u2192',
                                                  style: TextStyle(
                                                    fontFamily: theme
                                                        .fontFamilyDevanagariBody,
                                                    fontSize: 11,
                                                    color: theme
                                                        .shopTextOnPrimary
                                                        .withValues(
                                                          alpha: 0.6,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ),
                      ],

                      // ── 5. FOOTER (elegant closer) ──
                      Padding(
                        padding: const EdgeInsets.only(
                          top: YugmaSpacing.s6,
                          bottom: YugmaSpacing.s4,
                        ),
                        child: Column(
                          children: [
                            // Brass ornament divider
                            brassOrnament(width: 120),
                            const SizedBox(height: YugmaSpacing.s3),
                            // Brand name centered
                            Text(
                              theme.brandName,
                              style: TextStyle(
                                fontFamily:
                                    theme.fontFamilyDevanagariDisplay,
                                fontSize: 16,
                                color: theme.shopPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: YugmaSpacing.s1),
                            // Market + years subtitle
                            Text(
                              '${theme.marketArea} \u00B7 $years+ \u0938\u093E\u0932 \u0915\u093E \u092D\u0930\u094B\u0938\u093E',
                              style: TextStyle(
                                fontFamily:
                                    theme.fontFamilyDevanagariBody,
                                fontSize: 11,
                                color: theme.shopTextMuted,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      // ── Bottom padding for dock clearance ──
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
              // Dock pinned at bottom
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
}

// ─────────────────────────────────────────────────────────────────
// HERO BLOCK — face photo (40% screen), name, tagline
// ─────────────────────────────────────────────────────────────────
class _BharosaHero extends StatelessWidget {
  final YugmaThemeExtension theme;
  final Animation<double> entranceAnimation;
  final AppStrings strings;
  final VoidCallback? onLocaleToggle;
  final String currentLocaleCode;

  const _BharosaHero({
    required this.theme,
    required this.entranceAnimation,
    required this.strings,
    required this.onLocaleToggle,
    required this.currentLocaleCode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.shopSecondary,
            theme.shopPrimary,
            theme.shopPrimaryDeep,
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dark overlay for legibility
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.4),
                ],
              ),
            ),
          ),

          // Shopkeeper face frame (animated entrance)
          Positioned(
            top: 24,
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: entranceAnimation,
                curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
              ),
              child: const ShopkeeperFaceFrame(size: 100),
            ),
          ),

          // Name + tagline
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: entranceAnimation,
                curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
              ),
              child: Column(
                children: [
                  Text(
                    theme.ownerName,
                    style: TextStyle(
                      fontFamily: theme.fontFamilyDevanagariDisplay,
                      fontSize: theme.isElderTier ? 30 : 24,
                      color: theme.shopTextOnPrimary,
                      height: YugmaLineHeights.tight,
                      shadows: const [
                        Shadow(
                          offset: Offset(0, 2),
                          blurRadius: 8,
                          color: Color(0x66000000),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${theme.brandName} · ${theme.marketArea}, ${theme.city}',
                    style: TextStyle(
                      fontFamily: theme.fontFamilyDevanagariBody,
                      fontSize: theme.isElderTier ? 14 : 12,
                      color: theme.shopTextOnPrimary.withValues(alpha: 0.85),
                      height: YugmaLineHeights.snug,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // B1.2 AC #7: EN / हिं locale toggle
          if (onLocaleToggle != null)
            Positioned(
              top: 8,
              right: 8,
              child: SafeArea(
                child: Material(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(YugmaRadius.pill),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(YugmaRadius.pill),
                    onTap: onLocaleToggle,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      child: Text(
                        currentLocaleCode == 'hi' ? 'EN' : 'हिं',
                        style: TextStyle(
                          fontFamily: currentLocaleCode == 'hi'
                              ? theme.fontFamilyEnglishBody
                              : theme.fontFamilyDevanagariBody,
                          fontSize: 12,
                          color: theme.shopAccentGlow,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// META BAR — years in business, GST, map
// ─────────────────────────────────────────────────────────────────
class _MetaBar extends StatelessWidget {
  final YugmaThemeExtension theme;
  final AppStrings strings;

  const _MetaBar({required this.theme, required this.strings});

  @override
  Widget build(BuildContext context) {
    final years = DateTime.now().year - theme.establishedYear;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: YugmaSpacing.s4,
        vertical: YugmaSpacing.s3,
      ),
      decoration: BoxDecoration(
        color: theme.shopSurface,
        border: Border(
          bottom: BorderSide(color: theme.shopDivider, width: 1.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _MetaItem(
            theme: theme,
            icon: Icons.auto_stories_outlined,
            label: strings.metaBarYearsInBusiness(years, theme.establishedYear),
          ),
          if (theme.gstNumber != null)
            _MetaItem(
              theme: theme,
              icon: Icons.badge_outlined,
              label: 'GST ${theme.gstNumber!.substring(0, 6)}',
            ),
          _MetaItem(
            theme: theme,
            icon: Icons.place_outlined,
            label: strings.metaBarMapLabel,
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final YugmaThemeExtension theme;
  final IconData icon;
  final String label;

  const _MetaItem({
    required this.theme,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.shopTextMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: theme.fontFamilyDevanagariBody,
            fontSize: theme.isElderTier ? 13 : 11,
            color: theme.shopTextMuted,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// GREETING CARD — voice note auto-play (B1.3)
// ─────────────────────────────────────────────────────────────────
class _GreetingCard extends StatelessWidget {
  final YugmaThemeExtension theme;
  final AppStrings strings;
  final bool isMuted;
  final VoidCallback onPlay;
  final VoidCallback onMuteToggle;
  final int durationSeconds;

  const _GreetingCard({
    required this.theme,
    required this.strings,
    required this.isMuted,
    required this.onPlay,
    required this.onMuteToggle,
    required this.durationSeconds,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(YugmaSpacing.s4),
      padding: const EdgeInsets.all(YugmaSpacing.s4),
      decoration: BoxDecoration(
        color: theme.shopBackgroundWarmer,
        border: Border(
          left: BorderSide(color: theme.shopAccent, width: 3),
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(YugmaRadius.md),
          bottomRight: Radius.circular(YugmaRadius.md),
        ),
      ),
      child: Row(
        children: [
          // Play button
          Material(
            color: theme.shopAccent,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPlay,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: theme.shopPrimaryDeep,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: YugmaSpacing.s3),
          // Voice note label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.greetingCardTitle,
                  style: TextStyle(
                    fontFamily: theme.fontFamilyDevanagariDisplay,
                    fontSize: theme.isElderTier ? 16 : 14,
                    color: theme.shopPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  strings.greetingVoiceNoteSublabel(
                    theme.ownerName,
                    durationSeconds,
                  ),
                  style: TextStyle(
                    fontFamily: theme.fontFamilyDevanagariBody,
                    fontSize: theme.isElderTier ? 13 : 11,
                    color: theme.shopTextMuted,
                  ),
                ),
              ],
            ),
          ),
          // Mute toggle (B1.3 AC #4)
          IconButton(
            icon: Icon(
              isMuted ? Icons.volume_off : Icons.volume_up,
              color: theme.shopTextMuted,
            ),
            onPressed: onMuteToggle,
            tooltip: isMuted ? strings.muteToggleOn : strings.muteToggleMute,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// SHORTLIST PREVIEW SCROLL — "Sunil-bhaiya ki pasand · aaj ke liye"
// ─────────────────────────────────────────────────────────────────
class _ShortlistPreviewScroll extends StatelessWidget {
  final YugmaThemeExtension theme;
  final AppStrings strings;
  final List<CuratedShortlistPreview> shortlists;
  final void Function(String) onTap;
  final double tileSize;

  const _ShortlistPreviewScroll({
    required this.theme,
    required this.strings,
    required this.shortlists,
    required this.onTap,
    required this.tileSize,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: YugmaSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              YugmaSpacing.s4,
              0,
              YugmaSpacing.s4,
              YugmaSpacing.s3,
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 1.5,
                  color: theme.shopAccent,
                ),
                const SizedBox(width: YugmaSpacing.s2),
                Expanded(
                  child: Text(
                    strings.shortlistPreviewHeadline(theme.ownerName),
                    style: TextStyle(
                      fontFamily: theme.fontFamilyDevanagariDisplay,
                      fontSize: theme.isElderTier ? 16 : 14,
                      color: theme.shopPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: tileSize + 8, // tile + bottom padding
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: YugmaSpacing.s4,
              ),
              itemCount: shortlists.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: YugmaSpacing.s3),
              itemBuilder: (context, index) {
                final s = shortlists[index];
                return _ShortlistTile(
                  theme: theme,
                  strings: strings,
                  preview: s,
                  onTap: () => onTap(s.occasionTag),
                  isHighlighted: index == 0,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortlistTile extends StatelessWidget {
  final YugmaThemeExtension theme;
  final AppStrings strings;
  final CuratedShortlistPreview preview;
  final VoidCallback onTap;
  final bool isHighlighted;

  const _ShortlistTile({
    required this.theme,
    required this.strings,
    required this.preview,
    required this.onTap,
    required this.isHighlighted,
  });

  @override
  Widget build(BuildContext context) {
    final size = theme.isElderTier ? 130.0 : 110.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(YugmaRadius.md),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.shopPrimary,
                theme.shopPrimaryDeep,
              ],
            ),
            borderRadius: BorderRadius.circular(YugmaRadius.md),
            border: Border.all(
              color: isHighlighted ? theme.shopAccent : theme.shopDivider,
              width: isHighlighted ? 1.5 : 1,
            ),
            boxShadow: YugmaShadows.card,
          ),
          padding: const EdgeInsets.all(YugmaSpacing.s2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isHighlighted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.shopAccent,
                    borderRadius: BorderRadius.circular(YugmaRadius.sm),
                  ),
                  child: Text(
                    strings.shortlistBadgeCurated,
                    style: TextStyle(
                      fontFamily: theme.fontFamilyDevanagariBody,
                      fontSize: 9,
                      color: theme.shopPrimaryDeep,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              Text(
                preview.occasionLabel,
                style: TextStyle(
                  fontFamily: theme.fontFamilyDevanagariDisplay,
                  fontSize: 14,
                  color: theme.shopAccentGlow,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// TRUST BAR — compact trust signals row
// ─────────────────────────────────────────────────────────────────

Widget _trustDivider(YugmaThemeExtension theme) {
  return Container(
    width: 1,
    height: 16,
    color: theme.shopDivider,
  );
}

class _TrustSignal extends StatelessWidget {
  final YugmaThemeExtension theme;
  final IconData icon;
  final String label;
  final double? iconSize;
  final Color? iconColor;

  const _TrustSignal({
    required this.theme,
    required this.icon,
    required this.label,
    this.iconSize,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: iconSize ?? 14,
          color: iconColor ?? theme.shopTextMuted,
        ),
        const SizedBox(width: YugmaSpacing.s1),
        Text(
          label,
          style: TextStyle(
            fontFamily: theme.fontFamilyDevanagariBody,
            fontSize: theme.isElderTier ? 13 : 11,
            color: theme.shopTextSecondary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// HOW IT WORKS — numbered step row
// ─────────────────────────────────────────────────────────────────

class _HowItWorksStep extends StatelessWidget {
  final YugmaThemeExtension theme;
  final int stepNumber;
  final IconData icon;
  final String label;
  final String sublabel;

  const _HowItWorksStep({
    required this.theme,
    required this.stepNumber,
    required this.icon,
    required this.label,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(YugmaSpacing.s3),
      decoration: BoxDecoration(
        color: theme.shopSurface,
        borderRadius: BorderRadius.circular(YugmaRadius.md),
        boxShadow: YugmaShadows.card,
      ),
      child: Row(
        children: [
          // Numbered circle with accent background
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.shopAccent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$stepNumber',
                style: TextStyle(
                  fontFamily: theme.fontFamilyDevanagariDisplay,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.shopPrimaryDeep,
                ),
              ),
            ),
          ),
          const SizedBox(width: YugmaSpacing.s3),
          // Icon
          Icon(
            icon,
            size: 20,
            color: theme.shopPrimary,
          ),
          const SizedBox(width: YugmaSpacing.s2),
          // Label + sublabel
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: theme.fontFamilyDevanagariDisplay,
                    fontSize: theme.isElderTier ? 16 : 14,
                    color: theme.shopTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sublabel,
                  style: TextStyle(
                    fontFamily: theme.fontFamilyDevanagariBody,
                    fontSize: theme.isElderTier ? 13 : 11,
                    color: theme.shopTextMuted,
                    height: YugmaLineHeights.snug,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
