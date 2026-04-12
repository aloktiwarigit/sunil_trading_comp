// Shopkeeper Presence Dock — replaces bottom-tab navigation.
//
// Per design rationale: bottom-tab nav demotes the shopkeeper to "just
// another item in the catalog." The dock makes Sunil-bhaiya structurally
// inescapable on every screen — Brief §3 + §4.3.
//
// Maps to PRD B1.2 AC #5. Persists on EVERY customer-facing screen.
// Contains: face frame (44dp), name, presence status, voice-note play.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../locale/strings_base.dart';
import '../../theme/tokens.dart';
import '../../theme/yugma_theme_extension.dart';
import 'shopkeeper_face_frame.dart';

/// Top-anchored presence dock with shopkeeper avatar, name, status,
/// and quick voice-note play button.
class ShopkeeperPresenceDock extends StatelessWidget {
  /// Called when the voice note quick-play button is tapped.
  final VoidCallback onVoiceNote;

  /// Called when the "My List" (draft) navigation target is tapped.
  final VoidCallback? onMyListTap;

  /// Called when the "My Orders" navigation target is tapped.
  final VoidCallback? onOrdersTap;

  /// Locale strings for status labels.
  final AppStrings strings;

  const ShopkeeperPresenceDock({
    super.key,
    required this.onVoiceNote,
    required this.strings,
    this.onMyListTap,
    this.onOrdersTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;

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
            color: theme.shopAccent.withValues(alpha: 0.15),
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
              const ShopkeeperFaceFrame(size: 44),
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
                  strings.presenceStatusAvailable,
                  style: TextStyle(
                    fontFamily: theme.fontFamilyDevanagariBody,
                    fontSize: theme.isElderTier ? 13 : 12,
                    color: theme.shopTextMuted,
                  ),
                ),
              ],
            ),
          ),
          // Navigation targets — "My List" and "My Orders"
          if (onMyListTap != null)
            _DockNavButton(
              icon: Icons.list_alt_rounded,
              onTap: onMyListTap!,
              theme: theme,
            ),
          if (onOrdersTap != null)
            _DockNavButton(
              icon: Icons.receipt_long_rounded,
              onTap: onOrdersTap!,
              theme: theme,
            ),
          if (onMyListTap != null || onOrdersTap != null)
            const SizedBox(width: YugmaSpacing.s2),
          // Voice note quick-play button
          Material(
            color: theme.shopAccent,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                HapticFeedback.lightImpact();
                onVoiceNote();
              },
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

/// Compact icon button for dock navigation targets.
class _DockNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final YugmaThemeExtension theme;

  const _DockNavButton({
    required this.icon,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final size = theme.tapTargetMin * 0.83;
    return Padding(
      padding: const EdgeInsets.only(right: YugmaSpacing.s1),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            color: theme.shopTextSecondary,
            size: theme.isElderTier ? 22 : 18,
          ),
        ),
      ),
    );
  }
}
