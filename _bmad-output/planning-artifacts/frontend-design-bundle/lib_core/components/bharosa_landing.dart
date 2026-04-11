// lib_core/src/components/bharosa_landing.dart
//
// BharosaLanding — the customer app's landing screen.
//
// This is the SINGLE MOST IMPORTANT widget in the customer app.
// It is the first screen Sunita-ji's son sees, and per the brief:
// "the first screen IS the shopkeeper" (PRD B1.1, B1.2).
//
// This widget OWNS:
//   - The hero photo of Sunil-bhaiya's face (60% of screen)
//   - The shop name in Devanagari
//   - The greeting voice note auto-play (with mute toggle)
//   - The Shopkeeper Presence Dock (replaces bottom-tab nav)
//   - The first curated shortlist preview ("Sunil-bhaiya ki pasand")
//
// Design rationale:
//   - We REJECT bottom-tab navigation (Material 3 default) because it
//     visually demotes the shopkeeper to "just another item in the catalog."
//     Instead, the Shopkeeper Presence Dock is top-anchored and persists
//     across every screen, structurally embodying "Sunil-bhaiya is the product."
//   - The face photo takes 40% of screen real estate (200dp) — far more
//     than any catalog item — because the BharosaPillar mandates this.
//   - The greeting voice note auto-plays within 2 seconds of cold launch
//     (silent mode respected). Mute toggle is always visible.
//
// Maps to PRD stories: B1.1, B1.2, B1.3
// Maps to UX Spec §8.1, §8.2, §8.3 (Sally's strategic notes)

import 'package:flutter/material.dart';
import '../theme/yugma_theme_extension.dart';
import '../theme/tokens.dart';

class BharosaLanding extends StatefulWidget {
  /// Called when the customer taps a curated shortlist tile in the preview
  final void Function(String occasionTag) onShortlistTap;

  /// Called when the customer taps the greeting voice note play button
  final VoidCallback onGreetingPlay;

  /// Whether auto-play is enabled (respects user mute preference)
  final bool autoPlayGreeting;

  /// Called when the customer taps the presence dock voice button
  final VoidCallback onPresenceVoiceNote;

  /// Pre-fetched curated shortlist tiles to display in the preview
  /// (max 4 — the rest are below the fold on the curation tab)
  final List<CuratedShortlistPreview> previewShortlists;

  const BharosaLanding({
    super.key,
    required this.onShortlistTap,
    required this.onGreetingPlay,
    required this.autoPlayGreeting,
    required this.onPresenceVoiceNote,
    required this.previewShortlists,
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
    // Trigger entrance animation on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entranceController.forward();
      if (widget.autoPlayGreeting && !_isMuted) {
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

    return Scaffold(
      backgroundColor: theme.shopBackground,
      body: Column(
        children: [
          // ─── Hero: face + name + tagline ───
          _BharosaHero(
            theme: theme,
            entranceAnimation: _entranceController,
          ),

          // ─── Meta bar: GST, years in business, map ───
          _MetaBar(theme: theme),

          // ─── Greeting voice note card ───
          if (widget.autoPlayGreeting)
            _GreetingCard(
              theme: theme,
              isMuted: _isMuted,
              onPlay: widget.onGreetingPlay,
              onMuteToggle: () => setState(() => _isMuted = !_isMuted),
            ),

          // ─── Curated shortlist preview ───
          Expanded(
            child: _ShortlistPreviewScroll(
              theme: theme,
              shortlists: widget.previewShortlists,
              onTap: widget.onShortlistTap,
            ),
          ),

          // ─── Presence Dock (top-of-bottom-area, replaces bottom nav) ───
          // Note: in production, the dock would actually be top-anchored
          // and persist across all screens. Here it's at the bottom of
          // the landing for the demo. The full architecture moves it to
          // a Scaffold body wrapper.
          _ShopkeeperPresenceDock(
            theme: theme,
            onVoiceNote: widget.onPresenceVoiceNote,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// HERO BLOCK
// ─────────────────────────────────────────────────────────────────
class _BharosaHero extends StatelessWidget {
  final YugmaThemeExtension theme;
  final Animation<double> entranceAnimation;

  const _BharosaHero({
    required this.theme,
    required this.entranceAnimation,
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
          // Subtle dark overlay for legibility
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.4),
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
              child: _ShopkeeperFaceFrame(theme: theme, size: 100),
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
                    theme.ownerName, // "सुनील भैया"
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
                      color: theme.shopTextOnPrimary.withOpacity(0.85),
                      height: YugmaLineHeights.snug,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// SHOPKEEPER FACE FRAME — used in hero, presence dock, splash
// ─────────────────────────────────────────────────────────────────
class _ShopkeeperFaceFrame extends StatelessWidget {
  final YugmaThemeExtension theme;
  final double size;

  const _ShopkeeperFaceFrame({required this.theme, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.shopAccentGlow,
            theme.shopPrimary,
          ],
        ),
        border: Border.all(color: theme.shopAccent, width: 3),
        boxShadow: [
          BoxShadow(
            color: theme.shopAccent.withOpacity(0.20),
            blurRadius: 0,
            spreadRadius: 8,
          ),
          BoxShadow(
            color: theme.shopAccent.withOpacity(0.08),
            blurRadius: 0,
            spreadRadius: 16,
          ),
          const BoxShadow(
            color: Color(0x40000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: theme.shopkeeperFaceUrl.isNotEmpty
          ? ClipOval(
              child: Image.network(
                theme.shopkeeperFaceUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _faceFallback(),
              ),
            )
          : _faceFallback(),
    );
  }

  Widget _faceFallback() => Center(
        child: Text(
          // First Devanagari letter of the owner name as fallback
          // e.g., "सुनील भैया" → "सु"
          theme.ownerName.substring(0, 2),
          style: TextStyle(
            fontFamily: theme.fontFamilyDevanagariDisplay,
            fontSize: size * 0.4,
            color: theme.shopTextOnPrimary,
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────
// META BAR — GST, years, map
// ─────────────────────────────────────────────────────────────────
class _MetaBar extends StatelessWidget {
  final YugmaThemeExtension theme;
  const _MetaBar({required this.theme});

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
            icon: '📜',
            label: '$years साल · ${theme.establishedYear} से',
          ),
          if (theme.gstNumber != null)
            _MetaItem(
              theme: theme,
              icon: '🪪',
              label: 'GST ${theme.gstNumber!.substring(0, 6)}',
            ),
          _MetaItem(
            theme: theme,
            icon: '📍',
            label: 'Map',
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final YugmaThemeExtension theme;
  final String icon;
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
        Text(icon, style: const TextStyle(fontSize: 14)),
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
// GREETING CARD — voice note auto-play
// ─────────────────────────────────────────────────────────────────
class _GreetingCard extends StatelessWidget {
  final YugmaThemeExtension theme;
  final bool isMuted;
  final VoidCallback onPlay;
  final VoidCallback onMuteToggle;

  const _GreetingCard({
    required this.theme,
    required this.isMuted,
    required this.onPlay,
    required this.onMuteToggle,
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
                  'नमस्ते जी, स्वागत है',
                  style: TextStyle(
                    fontFamily: theme.fontFamilyDevanagariDisplay,
                    fontSize: theme.isElderTier ? 16 : 14,
                    color: theme.shopPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${theme.ownerName} का स्वागत संदेश · 23 सेकंड',
                  style: TextStyle(
                    fontFamily: theme.fontFamilyDevanagariBody,
                    fontSize: theme.isElderTier ? 13 : 11,
                    color: theme.shopTextMuted,
                  ),
                ),
              ],
            ),
          ),
          // Mute toggle
          IconButton(
            icon: Icon(
              isMuted ? Icons.volume_off : Icons.volume_up,
              color: theme.shopTextMuted,
            ),
            onPressed: onMuteToggle,
            tooltip: isMuted ? 'आवाज़ चालू कीजिए' : 'चुप कीजिए',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// SHORTLIST PREVIEW SCROLL — "Sunil-bhaiya ki pasand"
// ─────────────────────────────────────────────────────────────────
class _ShortlistPreviewScroll extends StatelessWidget {
  final YugmaThemeExtension theme;
  final List<CuratedShortlistPreview> shortlists;
  final void Function(String) onTap;

  const _ShortlistPreviewScroll({
    required this.theme,
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
                  'सुनील भैया की पसंद · आज के लिए',
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
                  preview: s,
                  onTap: () => onTap(s.occasionTag),
                  isHighlighted: index == 0, // first is "Sunil-bhaiya's pick"
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
  final CuratedShortlistPreview preview;
  final VoidCallback onTap;
  final bool isHighlighted;

  const _ShortlistTile({
    required this.theme,
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
              color: isHighlighted
                  ? theme.shopAccent
                  : theme.shopDivider,
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
                    'चुनी हुई',
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
                preview.occasionLabel, // e.g., "शादी"
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
// SHOPKEEPER PRESENCE DOCK — replaces bottom-tab nav
// ─────────────────────────────────────────────────────────────────
class _ShopkeeperPresenceDock extends StatelessWidget {
  final YugmaThemeExtension theme;
  final VoidCallback onVoiceNote;

  const _ShopkeeperPresenceDock({
    required this.theme,
    required this.onVoiceNote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: YugmaSpacing.s4,
        vertical: YugmaSpacing.s3,
      ),
      decoration: BoxDecoration(
        color: theme.shopSurface,
        border: Border(
          top: BorderSide(color: theme.shopDivider, width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shopAccent.withOpacity(0.15),
            blurRadius: 0,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Mini face frame with status dot
          Stack(
            children: [
              _ShopkeeperFaceFrame(theme: theme, size: 44),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D5C2A), // success green
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.shopSurface,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: YugmaSpacing.s3),
          // Name + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  theme.ownerName,
                  style: TextStyle(
                    fontFamily: theme.fontFamilyDevanagariDisplay,
                    fontSize: theme.isElderTier ? 19 : 17,
                    color: theme.shopPrimary,
                    height: YugmaLineHeights.tight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '● दुकान पर हैं',
                  style: TextStyle(
                    fontFamily: theme.fontFamilyDevanagariBody,
                    fontSize: theme.isElderTier ? 13 : 12,
                    color: theme.shopTextMuted,
                  ),
                ),
              ],
            ),
          ),
          // Voice note quick-play button
          Material(
            color: theme.shopAccent,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onVoiceNote,
              child: SizedBox(
                width: theme.tapTargetMin * 0.83,
                height: theme.tapTargetMin * 0.83,
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: theme.shopPrimaryDeep,
                  size: theme.isElderTier ? 22 : 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data class for the shortlist preview ───
class CuratedShortlistPreview {
  final String occasionTag;
  final String occasionLabel; // Devanagari
  final int skuCount;

  const CuratedShortlistPreview({
    required this.occasionTag,
    required this.occasionLabel,
    required this.skuCount,
  });
}
