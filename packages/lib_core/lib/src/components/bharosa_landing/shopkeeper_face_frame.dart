// Shopkeeper face frame — reusable circular avatar with D4 fallback.
//
// Used in: BharosaHero, ShopkeeperPresenceDock, splash screen.
//
// D4 consent secured (2026-04-12). Primary path = real face photo.
// Fallback = Devanagari-initial circle (first 2 chars of ownerName).
//
// Maps to PRD B1.2 AC #1, edge case #1.

import 'package:flutter/material.dart';

import '../../theme/yugma_theme_extension.dart';

/// Circular shopkeeper face frame with brass border and glow rings.
///
/// When [faceUrl] is empty or the image fails to load, renders a
/// Devanagari-initial fallback circle using the first two characters
/// of [ownerName] (e.g., "सुनील भै��ा" → "सु").
class ShopkeeperFaceFrame extends StatelessWidget {
  /// Size of the circular frame in logical pixels.
  final double size;

  /// Override face URL. If null, reads from theme.
  final String? faceUrl;

  /// Override owner name for the fallback initial. If null, reads from theme.
  final String? ownerName;

  const ShopkeeperFaceFrame({
    super.key,
    required this.size,
    this.faceUrl,
    this.ownerName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;
    final url = faceUrl ?? theme.shopkeeperFaceUrl;
    final name = ownerName ?? theme.ownerName;

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
            color: theme.shopAccent.withValues(alpha: 0.20),
            blurRadius: 0,
            spreadRadius: 8,
          ),
          BoxShadow(
            color: theme.shopAccent.withValues(alpha: 0.08),
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
      child: url.isNotEmpty
          ? ClipOval(
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _faceFallback(theme, name),
              ),
            )
          : _faceFallback(theme, name),
    );
  }

  Widget _faceFallback(YugmaThemeExtension theme, String name) {
    // First 2 Devanagari characters as initial — e.g., "सुनील भैया" → "सु"
    final initial = name.length >= 2 ? name.substring(0, 2) : name;
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          fontFamily: theme.fontFamilyDevanagariDisplay,
          fontSize: size * 0.4,
          color: theme.shopTextOnPrimary,
        ),
      ),
    );
  }
}
