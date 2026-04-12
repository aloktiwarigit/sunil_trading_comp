// =============================================================================
// YugmaThemeExtension — Material 3 ThemeExtension that consumes
// ShopThemeTokens and exposes them as a coherent ThemeData layer.
//
// Every screen reads colors via:
//   final theme = context.yugmaTheme;
//   Container(color: theme.shopPrimary, ...)
//
// Per ADR-003: NO hardcoded colors in any feature widget. Adding shop #2
// requires a new ShopThemeTokens document, not a code change.
//
// The ThemeExtension implements lerp() so theme transitions
// (e.g., when shopkeeper updates colors via Settings) animate
// smoothly without jarring cuts.
//
// Ported faithfully from `_bmad-output/planning-artifacts/frontend-design-
// bundle/lib_core/theme/yugma_theme_extension.dart` during Phase 2.0 Wave 1.
// =============================================================================

import 'package:flutter/material.dart';

import 'shop_theme_tokens.dart';
import 'tokens.dart';

/// Custom Material 3 ThemeExtension that consumes [ShopThemeTokens] and
/// exposes them as live theme values for widgets to consume.
@immutable
class YugmaThemeExtension extends ThemeExtension<YugmaThemeExtension> {
  /// Construct the extension. All fields are required.
  const YugmaThemeExtension({
    required this.shopId,
    required this.brandName,
    required this.brandNameEnglish,
    required this.ownerName,
    required this.taglineDevanagari,
    required this.taglineEnglish,
    required this.shopPrimary,
    required this.shopPrimaryDeep,
    required this.shopSecondary,
    required this.shopAccent,
    required this.shopAccentGlow,
    required this.shopCommit,
    required this.shopBackground,
    required this.shopBackgroundWarmer,
    required this.shopSurface,
    required this.shopSurfaceElevated,
    required this.shopDivider,
    required this.shopTextPrimary,
    required this.shopTextSecondary,
    required this.shopTextMuted,
    required this.shopTextOnPrimary,
    required this.fontFamilyDevanagariDisplay,
    required this.fontFamilyDevanagariBody,
    required this.fontFamilyEnglishDisplay,
    required this.fontFamilyEnglishBody,
    required this.shopkeeperFaceUrl,
    required this.greetingVoiceNoteId,
    required this.city,
    required this.marketArea,
    required this.establishedYear,
    required this.whatsappNumberE164,
    required this.upiVpa,
    required this.gstNumber,
    required this.isElderTier,
  });

  /// Factory: build from a [ShopThemeTokens] document with optional elder tier.
  factory YugmaThemeExtension.fromTokens(
    ShopThemeTokens tokens, {
    bool isElderTier = false,
  }) {
    return YugmaThemeExtension(
      shopId: tokens.shopId,
      brandName: tokens.brandName,
      brandNameEnglish: tokens.brandNameEnglish,
      ownerName: tokens.ownerName,
      taglineDevanagari: tokens.taglineDevanagari,
      taglineEnglish: tokens.taglineEnglish,
      shopPrimary: _hexToColor(tokens.primaryColorHex),
      shopPrimaryDeep: _hexToColor(tokens.primaryDeepColorHex),
      shopSecondary: _hexToColor(tokens.secondaryColorHex),
      shopAccent: _hexToColor(tokens.accentColorHex),
      shopAccentGlow: _hexToColor(tokens.accentGlowColorHex),
      shopCommit: _hexToColor(tokens.commitColorHex),
      shopBackground: _hexToColor(tokens.backgroundColorHex),
      shopBackgroundWarmer: YugmaColors.backgroundWarmer, // derived constant
      shopSurface: _hexToColor(tokens.surfaceColorHex),
      shopSurfaceElevated: YugmaColors.surfaceElevated,
      shopDivider: _hexToColor(tokens.primaryColorHex).withValues(alpha: 0.12),
      shopTextPrimary: _hexToColor(tokens.textPrimaryColorHex),
      shopTextSecondary: YugmaColors.textSecondary,
      shopTextMuted: YugmaColors.textMuted,
      shopTextOnPrimary: _hexToColor(tokens.textOnPrimaryColorHex),
      fontFamilyDevanagariDisplay: tokens.fontFamilyDevanagariDisplay,
      fontFamilyDevanagariBody: tokens.fontFamilyDevanagariBody,
      fontFamilyEnglishDisplay: tokens.fontFamilyEnglishDisplay,
      fontFamilyEnglishBody: tokens.fontFamilyEnglishBody,
      shopkeeperFaceUrl: tokens.shopkeeperFaceUrl,
      greetingVoiceNoteId: tokens.greetingVoiceNoteId,
      city: tokens.city,
      marketArea: tokens.marketArea,
      establishedYear: tokens.establishedYear,
      whatsappNumberE164: tokens.whatsappNumberE164,
      upiVpa: tokens.upiVpa,
      gstNumber: tokens.gstNumber,
      isElderTier: isElderTier,
    );
  }

  // ─── Identity ───

  /// Shop ID slug (e.g., "sunil-trading-company").
  final String shopId;

  /// Devanagari brand name.
  final String brandName;

  /// English brand name.
  final String brandNameEnglish;

  /// Owner's informal name (e.g., "सुनील भैया").
  final String ownerName;

  /// Devanagari tagline for hero / landing.
  final String taglineDevanagari;

  /// English tagline.
  final String taglineEnglish;

  // ─── Colors (live, parsed from ShopThemeTokens hex strings) ───

  /// Primary sheesham brown.
  final Color shopPrimary;

  /// Deeper sheesham for pressed states.
  final Color shopPrimaryDeep;

  /// Secondary saddle brown.
  final Color shopSecondary;

  /// Antique brass accent.
  final Color shopAccent;

  /// Brass glow for focus rings.
  final Color shopAccentGlow;

  /// Oxblood commit color. ONLY for commit / payment-success / udhaar acceptance.
  final Color shopCommit;

  /// Aged cream background.
  final Color shopBackground;

  /// Warmer cream for cards on the background.
  final Color shopBackgroundWarmer;

  /// Card / panel surface.
  final Color shopSurface;

  /// Maximum elevation surface — dialogs, modals.
  final Color shopSurfaceElevated;

  /// Divider color — 12% primary.
  final Color shopDivider;

  /// Primary text (warm near-black).
  final Color shopTextPrimary;

  /// Secondary text for metadata.
  final Color shopTextSecondary;

  /// Muted text for disabled / placeholder.
  final Color shopTextMuted;

  /// Text on primary-colored surfaces.
  final Color shopTextOnPrimary;

  // ─── Typography ───

  /// Devanagari display font family name.
  final String fontFamilyDevanagariDisplay;

  /// Devanagari body font family name.
  final String fontFamilyDevanagariBody;

  /// English display font family name.
  final String fontFamilyEnglishDisplay;

  /// English body font family name.
  final String fontFamilyEnglishBody;

  // ─── Asset references ───

  /// URL or Cloudinary public_id for the shopkeeper face photo. Empty
  /// string triggers the D4 Devanagari-initial fallback.
  final String shopkeeperFaceUrl;

  /// Voice note ID fragment for the greeting (resolved via MediaStore).
  final String greetingVoiceNoteId;

  // ─── Identity metadata ───

  /// City (e.g., "Ayodhya").
  final String city;

  /// Market area (e.g., "Harringtonganj").
  final String marketArea;

  /// Year of establishment.
  final int establishedYear;

  /// E.164 WhatsApp number.
  final String whatsappNumberE164;

  /// UPI VPA for payments.
  final String upiVpa;

  /// GST number (nullable).
  final String? gstNumber;

  // ─── Mode flags ───

  /// True iff elder tier rendering is active. Enables 1.4× type + 56dp
  /// tap targets + slower motion per PRD P2.3.
  final bool isElderTier;

  // ─── Hex parsing helper ───

  /// Parse a hex string of the form `#RRGGBB` or `RRGGBB` into a [Color].
  /// Adds full alpha (0xFF000000) when only 6 hex chars are provided.
  static Color _hexToColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    final value = int.parse(cleaned, radix: 16);
    // If 6 chars provided, add full alpha
    return Color(cleaned.length == 6 ? value | 0xFF000000 : value);
  }

  // ─── Type style helpers (consumed by widgets) ───

  /// Display size Devanagari text style.
  TextStyle get displayDeva => TextStyle(
        fontFamily: fontFamilyDevanagariDisplay,
        fontSize: isElderTier
            ? YugmaTypeScale.elder(YugmaTypeScale.display)
            : YugmaTypeScale.display,
        height: YugmaLineHeights.tight,
        color: shopPrimary,
      );

  /// H1 Devanagari text style.
  TextStyle get h1Deva => TextStyle(
        fontFamily: fontFamilyDevanagariDisplay,
        fontSize: isElderTier
            ? YugmaTypeScale.elder(YugmaTypeScale.h1)
            : YugmaTypeScale.h1,
        height: YugmaLineHeights.tight,
        color: shopPrimary,
      );

  /// H2 Devanagari text style.
  TextStyle get h2Deva => TextStyle(
        fontFamily: fontFamilyDevanagariDisplay,
        fontSize: isElderTier
            ? YugmaTypeScale.elder(YugmaTypeScale.h2)
            : YugmaTypeScale.h2,
        height: YugmaLineHeights.snug,
        color: shopTextPrimary,
      );

  /// Body Devanagari text style.
  TextStyle get bodyDeva => TextStyle(
        fontFamily: fontFamilyDevanagariBody,
        fontSize: isElderTier
            ? YugmaTypeScale.elder(YugmaTypeScale.body)
            : YugmaTypeScale.body,
        height: YugmaLineHeights.normal,
        color: shopTextPrimary,
        fontWeight: FontWeight.w400,
      );

  /// Caption Devanagari text style.
  TextStyle get captionDeva => TextStyle(
        fontFamily: fontFamilyDevanagariBody,
        fontSize: isElderTier
            ? YugmaTypeScale.elder(YugmaTypeScale.caption)
            : YugmaTypeScale.caption,
        height: YugmaLineHeights.snug,
        color: shopTextMuted,
      );

  /// Monospace numeral text style — for prices, timestamps.
  TextStyle get monoNumeral => TextStyle(
        fontFamily: YugmaFonts.mono,
        fontSize: isElderTier
            ? YugmaTypeScale.elder(YugmaTypeScale.bodyLarge)
            : YugmaTypeScale.bodyLarge,
        height: 1,
        color: shopPrimary,
        fontWeight: FontWeight.w600,
      );

  /// English italic display text style — for tagline cards.
  TextStyle get displayEnglish => TextStyle(
        fontFamily: fontFamilyEnglishDisplay,
        fontSize: isElderTier ? 22.0 : 16.0,
        fontStyle: FontStyle.italic,
        color: shopTextSecondary,
      );

  // ─── Tap target ───

  /// Minimum tap target size — elder tier or default.
  double get tapTargetMin =>
      isElderTier ? YugmaTapTargets.minElder : YugmaTapTargets.minDefault;

  // ─── Motion duration helper ───

  /// Fast motion duration — respects elder tier slower curves.
  Duration get motionFast =>
      isElderTier ? YugmaMotion.elderFast : YugmaMotion.fast;

  /// Normal motion duration — respects elder tier slower curves.
  Duration get motionNormal =>
      isElderTier ? YugmaMotion.elderNormal : YugmaMotion.normal;

  // ─── ThemeExtension contract ───

  @override
  YugmaThemeExtension copyWith({
    bool? isElderTier,
    Color? shopPrimary,
  }) {
    return YugmaThemeExtension(
      shopId: shopId,
      brandName: brandName,
      brandNameEnglish: brandNameEnglish,
      ownerName: ownerName,
      taglineDevanagari: taglineDevanagari,
      taglineEnglish: taglineEnglish,
      shopPrimary: shopPrimary ?? this.shopPrimary,
      shopPrimaryDeep: shopPrimaryDeep,
      shopSecondary: shopSecondary,
      shopAccent: shopAccent,
      shopAccentGlow: shopAccentGlow,
      shopCommit: shopCommit,
      shopBackground: shopBackground,
      shopBackgroundWarmer: shopBackgroundWarmer,
      shopSurface: shopSurface,
      shopSurfaceElevated: shopSurfaceElevated,
      shopDivider: shopDivider,
      shopTextPrimary: shopTextPrimary,
      shopTextSecondary: shopTextSecondary,
      shopTextMuted: shopTextMuted,
      shopTextOnPrimary: shopTextOnPrimary,
      fontFamilyDevanagariDisplay: fontFamilyDevanagariDisplay,
      fontFamilyDevanagariBody: fontFamilyDevanagariBody,
      fontFamilyEnglishDisplay: fontFamilyEnglishDisplay,
      fontFamilyEnglishBody: fontFamilyEnglishBody,
      shopkeeperFaceUrl: shopkeeperFaceUrl,
      greetingVoiceNoteId: greetingVoiceNoteId,
      city: city,
      marketArea: marketArea,
      establishedYear: establishedYear,
      whatsappNumberE164: whatsappNumberE164,
      upiVpa: upiVpa,
      gstNumber: gstNumber,
      isElderTier: isElderTier ?? this.isElderTier,
    );
  }

  @override
  YugmaThemeExtension lerp(
    ThemeExtension<YugmaThemeExtension>? other,
    double t,
  ) {
    if (other is! YugmaThemeExtension) return this;
    // Smooth color transitions for theme hot-reload (e.g., shopkeeper
    // updates colors via Settings — customer app interpolates)
    return YugmaThemeExtension(
      shopId: t < 0.5 ? shopId : other.shopId,
      brandName: t < 0.5 ? brandName : other.brandName,
      brandNameEnglish: t < 0.5 ? brandNameEnglish : other.brandNameEnglish,
      ownerName: t < 0.5 ? ownerName : other.ownerName,
      taglineDevanagari: t < 0.5 ? taglineDevanagari : other.taglineDevanagari,
      taglineEnglish: t < 0.5 ? taglineEnglish : other.taglineEnglish,
      shopPrimary: Color.lerp(shopPrimary, other.shopPrimary, t)!,
      shopPrimaryDeep: Color.lerp(shopPrimaryDeep, other.shopPrimaryDeep, t)!,
      shopSecondary: Color.lerp(shopSecondary, other.shopSecondary, t)!,
      shopAccent: Color.lerp(shopAccent, other.shopAccent, t)!,
      shopAccentGlow: Color.lerp(shopAccentGlow, other.shopAccentGlow, t)!,
      shopCommit: Color.lerp(shopCommit, other.shopCommit, t)!,
      shopBackground: Color.lerp(shopBackground, other.shopBackground, t)!,
      shopBackgroundWarmer:
          Color.lerp(shopBackgroundWarmer, other.shopBackgroundWarmer, t)!,
      shopSurface: Color.lerp(shopSurface, other.shopSurface, t)!,
      shopSurfaceElevated:
          Color.lerp(shopSurfaceElevated, other.shopSurfaceElevated, t)!,
      shopDivider: Color.lerp(shopDivider, other.shopDivider, t)!,
      shopTextPrimary: Color.lerp(shopTextPrimary, other.shopTextPrimary, t)!,
      shopTextSecondary:
          Color.lerp(shopTextSecondary, other.shopTextSecondary, t)!,
      shopTextMuted: Color.lerp(shopTextMuted, other.shopTextMuted, t)!,
      shopTextOnPrimary:
          Color.lerp(shopTextOnPrimary, other.shopTextOnPrimary, t)!,
      fontFamilyDevanagariDisplay: t < 0.5
          ? fontFamilyDevanagariDisplay
          : other.fontFamilyDevanagariDisplay,
      fontFamilyDevanagariBody: t < 0.5
          ? fontFamilyDevanagariBody
          : other.fontFamilyDevanagariBody,
      fontFamilyEnglishDisplay: t < 0.5
          ? fontFamilyEnglishDisplay
          : other.fontFamilyEnglishDisplay,
      fontFamilyEnglishBody:
          t < 0.5 ? fontFamilyEnglishBody : other.fontFamilyEnglishBody,
      shopkeeperFaceUrl: t < 0.5 ? shopkeeperFaceUrl : other.shopkeeperFaceUrl,
      greetingVoiceNoteId:
          t < 0.5 ? greetingVoiceNoteId : other.greetingVoiceNoteId,
      city: t < 0.5 ? city : other.city,
      marketArea: t < 0.5 ? marketArea : other.marketArea,
      establishedYear: t < 0.5 ? establishedYear : other.establishedYear,
      whatsappNumberE164:
          t < 0.5 ? whatsappNumberE164 : other.whatsappNumberE164,
      upiVpa: t < 0.5 ? upiVpa : other.upiVpa,
      gstNumber: t < 0.5 ? gstNumber : other.gstNumber,
      isElderTier: t < 0.5 ? isElderTier : other.isElderTier,
    );
  }
}

// ─── Convenience extension for context lookup ───

/// Convenience extension exposing `context.yugmaTheme` on [BuildContext].
extension YugmaThemeContext on BuildContext {
  /// Read the active [YugmaThemeExtension] from this context's theme.
  /// Throws an assertion error if the extension is not registered.
  YugmaThemeExtension get yugmaTheme {
    final extension = Theme.of(this).extension<YugmaThemeExtension>();
    assert(
      extension != null,
      'YugmaThemeExtension not registered in MaterialApp.theme. '
      'Wrap your app in YugmaApp() or register the extension manually.',
    );
    return extension!;
  }
}
