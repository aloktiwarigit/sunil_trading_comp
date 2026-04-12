// =============================================================================
// ShopThemeTokens — the multi-tenant theme document.
//
// One ShopThemeTokens document lives at /shops/{shopId}/theme/current
// in Firestore per SAD §5 schema. Loaded at app boot via the
// ThemeLoader (lands in Sprint 2 alongside B1.2); consumed by
// YugmaThemeExtension to build the live ThemeData.
//
// Adding a new shop = adding a new ShopThemeTokens document. NO code change.
// This is the strangler-fig pattern's actual on-ramp for shop #2 onboarding.
//
// Per ADR-003 + ADR-008: every visual decision in the app reads from a
// token here, never hardcoded. The synthetic shop_0 tenant has deliberately
// ugly colors so cross-tenant leakage is visually obvious in screenshots.
//
// Ported faithfully from `_bmad-output/planning-artifacts/frontend-design-
// bundle/lib_core/theme/shop_theme_tokens.dart` during Phase 2.0 Wave 1.
//
// **Sprint 0 / Constraint 15 note:** the Sally-authored Devanagari taglines
// + shop identity strings in `sunilTradingCompanyDefault` are pending
// Hindi-native review per PRD I6.11. These are the approved UX Spec v1.1
// defaults — reviewer can override at Sprint 0 close by writing a new
// Firestore document. The shop's LITERAL name (`सुनील ट्रेडिंग कंपनी`) and
// owner name (`सुनील भैया`) are not subject to review — they are the
// shop's legal identity per Alok's directive.
// =============================================================================

import 'package:freezed_annotation/freezed_annotation.dart';

part 'shop_theme_tokens.freezed.dart';
part 'shop_theme_tokens.g.dart';

/// The multi-tenant theme document at `/shops/{shopId}/theme/current`.
///
/// Every visual decision in the app reads from a field here rather than
/// hardcoding. Adding a new shop is zero-code — create a new Firestore
/// document with the shop's tokens and the theme loader picks it up at
/// next boot.
@freezed
class ShopThemeTokens with _$ShopThemeTokens {
  /// Construct a ShopThemeTokens record. All fields are required — there
  /// is no partial theme. Defaults for Sunil Trading Company are available
  /// via [sunilTradingCompanyDefault]; synthetic testing defaults via
  /// [syntheticShop0].
  const factory ShopThemeTokens({
    /// Slug — matches the document ID at /shops/{shopId}.
    /// e.g., "sunil-trading-company"
    required String shopId,

    /// Devanagari display name — used in app bars, hero, splash.
    /// e.g., "सुनील ट्रेडिंग कंपनी"
    required String brandName,

    /// English display name — used when locale toggle is English.
    /// e.g., "Sunil Trading Company"
    required String brandNameEnglish,

    /// Owner's display name (informal) — e.g., "सुनील भैया".
    /// Used in the Shopkeeper Presence Dock + chat thread sender label.
    required String ownerName,

    /// Tagline in Devanagari for hero + landing.
    required String taglineDevanagari,

    /// Tagline in English (italic Fraunces in display).
    required String taglineEnglish,

    // ─── Color tokens ──────────────────────────
    // All as hex strings (parsed by YugmaThemeExtension) for easy
    // editing in the ops app Settings screen and easy storage in JSON

    /// Primary sheesham brown hex (e.g., "#6B3410").
    required String primaryColorHex,

    /// Deep sheesham hover/pressed hex.
    required String primaryDeepColorHex,

    /// Secondary saddle brown hex.
    required String secondaryColorHex,

    /// Antique brass accent hex.
    required String accentColorHex,

    /// Brighter brass glow hex.
    required String accentGlowColorHex,

    /// Oxblood commit hex — RESERVED for commit/payment/udhaar moments.
    required String commitColorHex,

    /// Aged cream background hex.
    required String backgroundColorHex,

    /// Card/panel surface hex.
    required String surfaceColorHex,

    /// Primary text hex (warm near-black).
    required String textPrimaryColorHex,

    /// Text on primary-colored surfaces (cream on dark).
    required String textOnPrimaryColorHex,

    // ─── Font tokens ──────────────────────────
    // Defaults to Tiro Devanagari Hindi / Mukta / Fraunces / EB Garamond
    // but each shop CAN override (e.g., a Bengali shop in v1.5 might
    // swap to Tiro Bangla)

    /// Devanagari display font family name.
    required String fontFamilyDevanagariDisplay,

    /// Devanagari body font family name.
    required String fontFamilyDevanagariBody,

    /// English display font family name.
    required String fontFamilyEnglishDisplay,

    /// English body font family name.
    required String fontFamilyEnglishBody,

    // ─── Asset references ──────────────────────────

    /// Cloudinary public ID OR Cloud Storage path for shopkeeper face.
    /// Empty string triggers the D4 Devanagari-initial fallback per
    /// frontend-design-bundle.
    required String shopkeeperFaceUrl,

    /// Cloud Storage path fragment for the greeting voice note.
    /// Format: `{voiceNoteId}` — the full path is constructed via
    /// `shops/{shopId}/voice_notes/{voiceNoteId}.m4a` in MediaStore.
    required String greetingVoiceNoteId,

    // ─── Identity ──────────────────────────

    /// City the shop is located in (e.g., "Ayodhya").
    required String city,

    /// Market area / neighborhood (e.g., "Harringtonganj").
    required String marketArea,

    /// Year the shop was established.
    required int establishedYear,

    /// E.164 WhatsApp number for wa.me deep links.
    required String whatsappNumberE164,

    /// UPI VPA for payment intents (e.g., "shopkeeper@oksbi").
    required String upiVpa,

    /// GST registration number (nullable — not every shop has one).
    required String? gstNumber,

    // ─── Versioning (for cache invalidation) ──────────────────────────

    /// Bumped on every Settings save by the shopkeeper.
    /// Customer app re-fetches if local cached version != Firestore version.
    required int version,

    /// Server timestamp of last write.
    required DateTime updatedAt,
  }) = _ShopThemeTokens;

  /// JSON round-trip for Firestore serialization.
  factory ShopThemeTokens.fromJson(Map<String, dynamic> json) =>
      _$ShopThemeTokensFromJson(json);

  // ─── Default tokens for SUNIL TRADING COMPANY (the flagship) ───────
  //
  // These are the working defaults shipped in the app binary as a
  // fallback. The runtime app fetches the live document from Firestore
  // and overrides these on first successful read.
  //
  // Per Brief v1.4 §1: "Sunil Trading Company (सुनील ट्रेडिंग कंपनी)
  // — a real multi-generational almirah shop in Ayodhya's
  // Harringtonganj market"

  /// Compile-time defaults for the flagship Sunil Trading Company shop.
  /// Used as fallback when Firestore is unreachable on first launch.
  ///
  /// **Sprint 0 / Constraint 15 discipline (Phase 2.0 Option C scope):**
  /// - `brandName` + `ownerName` are the shop's LEGAL IDENTITY per
  ///   Alok's directive — Sunil-bhaiya's real shop + real name. Not
  ///   subject to Hindi-native design review. Already in production
  ///   via Sprint 1.6 `_BootSplashScreen`.
  /// - `taglineDevanagari` + `taglineEnglish` intentionally start as
  ///   EMPTY STRINGS. The Sally-authored tagline from UX Spec v1.1 §5.5
  ///   lives in the runtime Firestore document at
  ///   `/shops/sunil-trading-company/theme/current`, NOT here. When
  ///   Sprint 0 closes (END STATE A or B), the reviewer populates the
  ///   tagline in the Firestore document. Until then, the customer app
  ///   renders no tagline on first-launch-offline — an empty Text widget
  ///   is cleaner than shipping unreviewed design copy.
  static ShopThemeTokens sunilTradingCompanyDefault() => ShopThemeTokens(
        shopId: 'sunil-trading-company',
        brandName: 'सुनील ट्रेडिंग कंपनी', // shop's legal name
        brandNameEnglish: 'Sunil Trading Company',
        ownerName: 'सुनील भैया', // shopkeeper's literal first name + honorific
        taglineDevanagari: '', // populated at runtime post-Sprint-0
        taglineEnglish: '', // populated at runtime post-Sprint-0
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
        shopkeeperFaceUrl: '', // populated post-onboarding (D4 fallback until)
        greetingVoiceNoteId: 'vn_greeting_v1',
        city: 'Ayodhya',
        marketArea: 'Harringtonganj',
        establishedYear: 2003,
        whatsappNumberE164: '+91XXXXXXXXXX', // TBD pending onboarding
        upiVpa: 'sunil@oksbi', // TBD pending onboarding
        gstNumber: null, // TBD pending onboarding
        version: 1,
        updatedAt: DateTime(2026, 4, 11),
      );

  // ─── Synthetic shop_0 tenant — for cross-tenant integrity testing ───
  //
  // Per ADR-012: this tenant is maintained continuously from day one
  // of v1 development. The colors are DELIBERATELY UGLY so any
  // accidental cross-tenant leakage is immediately visible in screenshots.
  // If shop_0 ever appears in a real screenshot, the bug is obvious.

  /// Synthetic shop_0 tenant defaults — deliberately ugly colors so any
  /// cross-tenant leakage is visually obvious. Used by the cross-tenant
  /// integrity test per ADR-012.
  static ShopThemeTokens syntheticShop0() => ShopThemeTokens(
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
