// lib_core/src/theme/yugma_theme_extension.dart
//
// Custom Material 3 ThemeExtension that consumes ShopThemeTokens
// and exposes them as a coherent ThemeData layer.
//
// Every screen reads colors via:
//   final theme = Theme.of(context).extension<YugmaThemeExtension>()!;
//   Container(color: theme.shopPrimary, ...)
//
// Per ADR-003: NO hardcoded colors in any feature widget. Adding shop #2
// requires a new ShopThemeTokens document, not a code change.
//
// The ThemeExtension implements lerp() so theme transitions
// (e.g., when shopkeeper updates colors via Settings) animate
// smoothly without jarring cuts.

import 'package:flutter/material.dart';
import 'shop_theme_tokens.dart';
import 'tokens.dart';

@immutable
class YugmaThemeExtension extends ThemeExtension<YugmaThemeExtension> {
  // ─── Identity ───
  final String shopId;
  final String brandName; // Devanagari
  final String brandNameEnglish;
  final String ownerName; // "सुनील भैया"
  final String taglineDevanagari;
  final String taglineEnglish;

  // ─── Colors (live, parsed from ShopThemeTokens hex strings) ───
  final Color shopPrimary;
  final Color shopPrimaryDeep;
  final Color shopSecondary;
  final Color shopAccent;
  final Color shopAccentGlow;
  final Color shopCommit; // ONLY for commit/payment-success/udhaar acceptance
  final Color shopBackground;
  final Color shopBackgroundWarmer;
  final Color shopSurface;
  final Color shopSurfaceElevated;
  final Color shopDivider;
  final Color shopTextPrimary;
  final Color shopTextSecondary;
  final Color shopTextMuted;
  final Color shopTextOnPrimary;

  // ─── Typography ───
  final String fontFamilyDevanagariDisplay;
  final String fontFamilyDevanagariBody;
  final String fontFamilyEnglishDisplay;
  final String fontFamilyEnglishBody;

  // ─── Asset references ───
  final String shopkeeperFaceUrl;
  final String greetingVoiceNoteId;

  // ─── Identity metadata ───
  final String city;
  final String marketArea;
  final int establishedYear;
  final String whatsappNumberE164;
  final String upiVpa;
  final String? gstNumber;

  // ─── Mode flags ───
  final bool isElderTier; // Per PRD P2.3 — 1.4× text, 56dp tap targets

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

  // ─── Factory: build from ShopThemeTokens document ───
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
      shopBackgroundWarmer: const Color(0xFFF5EBD7), // derived
      shopSurface: _hexToColor(tokens.surfaceColorHex),
      shopSurfaceElevated: const Color(0xFFFFFFFF),
      shopDivider: _hexToColor(tokens.primaryColorHex).withOpacity(0.12),
      shopTextPrimary: _hexToColor(tokens.textPrimaryColorHex),
      shopTextSecondary: const Color(0xFF4A3826),
      shopTextMuted: const Color(0xFF7A6655),
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

  // ─── Hex parsing helper ───
  static Color _hexToColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    final value = int.parse(cleaned, radix: 16);
    // If 6 chars provided, add full alpha
    return Color(cleaned.length == 6 ? value | 0xFF000000 : value);
  }

  // ─── Type style helpers (consume by widgets) ───

  TextStyle get displayDeva => TextStyle(
        fontFamily: fontFamilyDevanagariDisplay,
        fontSize: isElderTier
            ? YugmaTypeScale.elder(YugmaTypeScale.display)
            : YugmaTypeScale.display,
        height: YugmaLineHeights.tight,
        color: shopPrimary,
      );

  TextStyle get h1Deva => TextStyle(
        fontFamily: fontFamilyDevanagariDisplay,
        fontSize: isElderTier
            ? YugmaTypeScale.elder(YugmaTypeScale.h1)
            : YugmaTypeScale.h1,
        height: YugmaLineHeights.tight,
        color: shopPrimary,
      );

  TextStyle get h2Deva => TextStyle(
        fontFamily: fontFamilyDevanagariDisplay,
        fontSize: isElderTier
            ? YugmaTypeScale.elder(YugmaTypeScale.h2)
            : YugmaTypeScale.h2,
        height: YugmaLineHeights.snug,
        color: shopTextPrimary,
      );

  TextStyle get bodyDeva => TextStyle(
        fontFamily: fontFamilyDevanagariBody,
        fontSize: isElderTier
            ? YugmaTypeScale.elder(YugmaTypeScale.body)
            : YugmaTypeScale.body,
        height: YugmaLineHeights.normal,
        color: shopTextPrimary,
        fontWeight: FontWeight.w400,
      );

  TextStyle get captionDeva => TextStyle(
        fontFamily: fontFamilyDevanagariBody,
        fontSize: isElderTier
            ? YugmaTypeScale.elder(YugmaTypeScale.caption)
            : YugmaTypeScale.caption,
        height: YugmaLineHeights.snug,
        color: shopTextMuted,
      );

  TextStyle get monoNumeral => TextStyle(
        fontFamily: YugmaFonts.mono,
        fontSize: isElderTier
            ? YugmaTypeScale.elder(YugmaTypeScale.bodyLarge)
            : YugmaTypeScale.bodyLarge,
        height: 1.0,
        color: shopPrimary,
        fontWeight: FontWeight.w600,
      );

  // English italic display — used for tagline cards and English-toggle text
  TextStyle get displayEnglish => TextStyle(
        fontFamily: fontFamilyEnglishDisplay,
        fontSize: isElderTier ? 22.0 : 16.0,
        fontStyle: FontStyle.italic,
        color: shopTextSecondary,
      );

  // ─── Tap target ───
  double get tapTargetMin =>
      isElderTier ? YugmaTapTargets.minElder : YugmaTapTargets.minDefault;

  // ─── Motion duration helper ───
  Duration get motionFast =>
      isElderTier ? YugmaMotion.elderFast : YugmaMotion.fast;
  Duration get motionNormal =>
      isElderTier ? YugmaMotion.elderNormal : YugmaMotion.normal;

  // ─── ThemeExtension contract ───

  @override
  YugmaThemeExtension copyWith({
    bool? isElderTier,
    Color? shopPrimary,
    // ... (full copyWith would be auto-generated by Freezed in production)
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
      shopPrimaryDeep:
          Color.lerp(shopPrimaryDeep, other.shopPrimaryDeep, t)!,
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
      shopkeeperFaceUrl:
          t < 0.5 ? shopkeeperFaceUrl : other.shopkeeperFaceUrl,
      greetingVoiceNoteId:
          t < 0.5 ? greetingVoiceNoteId : other.greetingVoiceNoteId,
      city: t < 0.5 ? city : other.city,
      marketArea: t < 0.5 ? marketArea : other.marketArea,
      establishedYear:
          t < 0.5 ? establishedYear : other.establishedYear,
      whatsappNumberE164:
          t < 0.5 ? whatsappNumberE164 : other.whatsappNumberE164,
      upiVpa: t < 0.5 ? upiVpa : other.upiVpa,
      gstNumber: t < 0.5 ? gstNumber : other.gstNumber,
      isElderTier: t < 0.5 ? isElderTier : other.isElderTier,
    );
  }
}

// ─── Convenience extension for context lookup ───
extension YugmaThemeContext on BuildContext {
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
