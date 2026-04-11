// lib_core/src/theme/shop_theme_tokens.dart
//
// ShopThemeTokens — the multi-tenant theme document.
//
// One ShopThemeTokens document lives at /shops/{shopId}/theme/current
// in Firestore per SAD §5 schema. Loaded at app boot via the
// ThemeLoader; consumed by YugmaThemeExtension to build the live ThemeData.
//
// Adding a new shop = adding a new ShopThemeTokens document. NO code change.
// This is the strangler-fig pattern's actual on-ramp for shop #2 onboarding.
//
// Per ADR-003 + ADR-008: every visual decision in the app reads from a
// token here, never hardcoded. The synthetic shop_0 tenant has deliberately
// ugly colors so cross-tenant leakage is visually obvious in screenshots.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'shop_theme_tokens.freezed.dart';
part 'shop_theme_tokens.g.dart';

@freezed
class ShopThemeTokens with _$ShopThemeTokens {
  const factory ShopThemeTokens({
    /// Slug — matches the document ID at /shops/{shopId}
    /// e.g., "sunil-trading-company"
    required String shopId,

    /// Devanagari display name — used in app bars, hero, splash
    /// e.g., "सुनील ट्रेडिंग कंपनी"
    required String brandName,

    /// English display name — used when locale toggle is English
    /// e.g., "Sunil Trading Company"
    required String brandNameEnglish,

    /// Owner's display name (informal) — e.g., "सुनील भैया"
    /// Used in the Shopkeeper Presence Dock + chat thread sender label
    required String ownerName,

    /// Tagline in Devanagari for hero + landing
    /// e.g., "हर शादी की पहली खुशी, यहाँ से"
    required String taglineDevanagari,

    /// Tagline in English (italic Fraunces in display)
    required String taglineEnglish,

    // ─── Color tokens ──────────────────────────
    // All as hex strings (parsed by YugmaThemeExtension) for easy
    // editing in the ops app Settings screen and easy storage in JSON
    required String primaryColorHex, // e.g., "#6B3410"
    required String primaryDeepColorHex,
    required String secondaryColorHex,
    required String accentColorHex,
    required String accentGlowColorHex,
    required String commitColorHex,
    required String backgroundColorHex,
    required String surfaceColorHex,
    required String textPrimaryColorHex,
    required String textOnPrimaryColorHex,

    // ─── Font tokens ──────────────────────────
    // Defaults to Tiro Devanagari Hindi / Mukta / Fraunces / EB Garamond
    // but each shop CAN override (e.g., a Bengali shop in v1.5 might
    // swap to Tiro Bangla)
    required String fontFamilyDevanagariDisplay,
    required String fontFamilyDevanagariBody,
    required String fontFamilyEnglishDisplay,
    required String fontFamilyEnglishBody,

    // ─── Asset references ──────────────────────────
    /// Cloudinary public ID OR Cloud Storage path for shopkeeper face
    required String shopkeeperFaceUrl,

    /// Cloud Storage path for the greeting voice note
    /// Format: shops/{shopId}/voice_notes/{voiceNoteId}.m4a
    required String greetingVoiceNoteId,

    // ─── Identity ──────────────────────────
    required String city,
    required String marketArea,
    required int establishedYear,
    required String whatsappNumberE164,
    required String upiVpa,
    required String? gstNumber,

    // ─── Versioning (for cache invalidation) ──────────────────────────
    /// Bumped on every Settings save by the shopkeeper.
    /// Customer app re-fetches if local cached version != Firestore version.
    required int version,
    required DateTime updatedAt,
  }) = _ShopThemeTokens;

  factory ShopThemeTokens.fromJson(Map<String, dynamic> json) =>
      _$ShopThemeTokensFromJson(json);

  // ─── Default tokens for SUNIL TRADING COMPANY (the flagship) ───────
  //
  // These are the working defaults shipped in the app binary as a
  // fallback. The runtime app fetches the live document from Firestore
  // and overrides these on first successful read.
  //
  // Per Brief v1.3 §1: "Sunil Trading Company (सुनील ट्रेडिंग कंपनी)
  // — a real multi-generational almirah shop in Ayodhya's
  // Harringtonganj market"

  static ShopThemeTokens get sunilTradingCompanyDefault => ShopThemeTokens(
        shopId: 'sunil-trading-company',
        brandName: 'सुनील ट्रेडिंग कंपनी',
        brandNameEnglish: 'Sunil Trading Company',
        ownerName: 'सुनील भैया',
        taglineDevanagari: 'हर शादी की पहली खुशी, यहाँ से',
        taglineEnglish: "Where every wedding's first joy begins",
        primaryColorHex: '#6B3410',
        primaryDeepColorHex: '#4A2308',
        secondaryColorHex: '#8B4513',
        accentColorHex: '#B8860B',
        accentGlowColorHex: '#D4A547',
        commitColorHex: '#7B1F1F',
        backgroundColorHex: '#FAF3E7',
        surfaceColorHex: '#FFFAF0',
        textPrimaryColorHex: '#1F1611',
        textOnPrimaryColorHex: '#FAF3E7',
        fontFamilyDevanagariDisplay: 'Tiro Devanagari Hindi',
        fontFamilyDevanagariBody: 'Mukta',
        fontFamilyEnglishDisplay: 'Fraunces',
        fontFamilyEnglishBody: 'EB Garamond',
        shopkeeperFaceUrl: '', // populated post-onboarding
        greetingVoiceNoteId: 'vn_greeting_v1',
        city: 'Ayodhya',
        marketArea: 'Harringtonganj',
        establishedYear: 2003,
        whatsappNumberE164: '+91XXXXXXXXXX', // TBD
        upiVpa: 'sunil@oksbi', // TBD
        gstNumber: null, // TBD during onboarding
        version: 1,
        updatedAt: DateTime(2026, 4, 11),
      );

  // ─── Synthetic shop_0 tenant — for cross-tenant integrity testing ───
  //
  // Per ADR-012: this tenant is maintained continuously from day one
  // of v1 development. The colors are DELIBERATELY UGLY so any
  // accidental cross-tenant leakage is immediately visible in screenshots.
  // If shop_0 ever appears in a real screenshot, the bug is obvious.

  static ShopThemeTokens get syntheticShop0 => ShopThemeTokens(
        shopId: 'shop_0',
        brandName: 'TEST SHOP — DO NOT DISPLAY',
        brandNameEnglish: 'CROSS-TENANT INTEGRITY TEST TENANT',
        ownerName: 'shop_0_test_user',
        taglineDevanagari: 'यह शो नहीं होना चाहिए',
        taglineEnglish: 'IF YOU SEE THIS, FILE A P0 BUG',
        primaryColorHex: '#FF00FF', // ugly magenta
        primaryDeepColorHex: '#CC00CC',
        secondaryColorHex: '#00FF00', // ugly green
        accentColorHex: '#FFFF00', // ugly yellow
        accentGlowColorHex: '#FFFF66',
        commitColorHex: '#00FFFF', // ugly cyan
        backgroundColorHex: '#FF00FF',
        surfaceColorHex: '#FFFF00',
        textPrimaryColorHex: '#000000',
        textOnPrimaryColorHex: '#FFFFFF',
        fontFamilyDevanagariDisplay: 'Tiro Devanagari Hindi',
        fontFamilyDevanagariBody: 'Mukta',
        fontFamilyEnglishDisplay: 'Fraunces',
        fontFamilyEnglishBody: 'EB Garamond',
        shopkeeperFaceUrl: '',
        greetingVoiceNoteId: 'vn_test_silence_1sec',
        city: 'TEST',
        marketArea: 'TEST',
        establishedYear: 2026,
        whatsappNumberE164: '+10000000000',
        upiVpa: 'test@test',
        gstNumber: null,
        version: 1,
        updatedAt: DateTime(2026, 4, 11),
      );
}
