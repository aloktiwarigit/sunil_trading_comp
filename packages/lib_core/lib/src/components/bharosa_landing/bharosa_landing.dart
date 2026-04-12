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

    Widget body = Column(
      children: [
        // D-8: Connectivity banner — slides down when offline
        YugmaConnectivityBanner(strings: widget.strings),

        // Hero: face + name + tagline
        _BharosaHero(
          theme: theme,
          entranceAnimation: _entranceController,
          strings: widget.strings,
          onLocaleToggle: widget.onLocaleToggle,
          currentLocaleCode: widget.currentLocaleCode,
        ),

        // Meta bar: years in business, GST, map
        _MetaBar(theme: theme, strings: widget.strings),

        // Greeting voice note card — suppressed if no voice note exists
        // (B1.3 AC #8)
        if (widget.hasGreetingVoiceNote)
          _GreetingCard(
            theme: theme,
            strings: widget.strings,
            isMuted: _isMuted,
            onPlay: widget.onGreetingPlay,
            onMuteToggle: () => setState(() => _isMuted = !_isMuted),
            durationSeconds: widget.greetingDurationSeconds,
          ),

        // Curated shortlist preview
        Expanded(
          child: _ShortlistPreviewScroll(
            theme: theme,
            strings: widget.strings,
            shortlists: widget.previewShortlists,
            onTap: widget.onShortlistTap,
          ),
        ),

        // Presence Dock — B-2: nav buttons wired when callbacks provided
        ShopkeeperPresenceDock(
          onVoiceNote: widget.onPresenceVoiceNote,
          strings: widget.strings,
          onMyListTap: widget.onMyListTap,
          onOrdersTap: widget.onOrdersTap,
        ),
      ],
    );

    // B1.2 AC #6: pull-to-refresh
    if (widget.onRefresh != null) {
      body = RefreshIndicator(
        onRefresh: widget.onRefresh!,
        color: theme.shopAccent,
        backgroundColor: theme.shopSurface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: body,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.shopBackground,
      body: body,
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

  const _ShortlistPreviewScroll({
    required this.theme,
    required this.strings,
    required this.shortlists,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: YugmaSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                Text(
                  strings.shortlistPreviewHeadline(theme.ownerName),
                  style: TextStyle(
                    fontFamily: theme.fontFamilyDevanagariDisplay,
                    fontSize: theme.isElderTier ? 16 : 14,
                    color: theme.shopPrimary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
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
        onTap: onTap,
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
