// lib_core/src/theme/tokens.dart
//
// Yugma Dukaan — "Workshop Almanac" Design Tokens
// Aesthetic: deep polished sheesham wood + antique brass + aged cream paper
//
// These constants are the SAFE FALLBACKS used when ShopThemeTokens has not
// yet been loaded from Firestore at app boot. They are also the values used
// for the synthetic shop_0 tenant during cross-tenant integrity testing.
//
// IMPORTANT: at runtime, every consumer reads from `YugmaThemeExtension`,
// not from these constants directly. These constants exist for:
//   1. Boot-time defaults before Firestore loads
//   2. Synthetic shop_0 testing
//   3. Component widget defaults in tests
//   4. Documentation of the design system's anchor values
//
// Per ADR-008 (Devanagari source-of-truth) and Brief Constraint 15
// (Hindi-native design capacity), this file is the canonical reference
// for the design system's typographic and color decisions.

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────
// COLOR TOKENS
// ─────────────────────────────────────────────────────────────────
//
// The palette rejects Material 3's default ColorScheme.fromSeed()
// generic look. These are hand-tuned to the warm-multi-generational-
// wood-shop aesthetic the brief calls for.
//
// "Sheesham" = Indian rosewood; the primary references its polished
// surface. "Brass" accents are antique (#B8860B), NOT candy gold.
// Oxblood (#7B1F1F) is reserved EXCLUSIVELY for commit/payment-success/
// udhaar-acceptance moments — it visually marks gravity.

class YugmaColors {
  YugmaColors._();

  // Primary scale — polished sheesham wood
  static const Color primary = Color(0xFF6B3410);
  static const Color primaryDeep = Color(0xFF4A2308);
  static const Color secondary = Color(0xFF8B4513);

  // Brass accents — antique, never candy
  static const Color accent = Color(0xFFB8860B);
  static const Color accentGlow = Color(0xFFD4A547);

  // Commitment color — RESERVED for: order commit, payment success,
  // udhaar khaata acceptance moments. Do not use elsewhere.
  static const Color commit = Color(0xFF7B1F1F);
  static const Color commitGlow = Color(0xFF9B2A2A);

  // Background scale — aged cream paper, never pure white
  static const Color background = Color(0xFFFAF3E7);
  static const Color backgroundWarmer = Color(0xFFF5EBD7);
  static const Color surface = Color(0xFFFFFAF0);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color paperLine = Color(0xFFE8DCC4);
  static const Color divider = Color(0x1F6B3410); // 12% primary

  // Text scale — never pure black
  static const Color textPrimary = Color(0xFF1F1611);
  static const Color textSecondary = Color(0xFF4A3826);
  static const Color textMuted = Color(0xFF7A6655);
  static const Color textOnPrimary = Color(0xFFFAF3E7);

  // Semantic — derived from the wood/brass palette, not generic Material
  static const Color success = Color(0xFF3D5C2A); // forest moss
  static const Color warning = Color(0xFF8B6914); // weathered brass
  static const Color error = Color(0xFF7B1F1F); // same as commit (intentional)
  static const Color info = Color(0xFF2C4A5C); // monsoon ink
}

// ─────────────────────────────────────────────────────────────────
// TYPOGRAPHY TOKENS
// ─────────────────────────────────────────────────────────────────
//
// Font choices REJECT the brief's "Noto Sans Devanagari" suggestion.
// Noto Sans is too Google-sterile. We use:
//
//   - Tiro Devanagari Hindi (display) — characterful, designed by
//     Tiro Typeworks specifically for Devanagari clarity at small sizes
//   - Mukta (body) — warmer than Noto, still highly readable
//   - Fraunces (English display) — variable serif with personality
//   - EB Garamond (English body) — classic warm pairing
//   - DM Mono (numerals/labels) — for prices, timestamps, technical UI
//
// All four are Google Fonts, all subset-able to <100 KB total per
// ADR-008. Subsetting script lives at tools/generate_devanagari_subset.sh
//
// Line heights are DELIBERATELY GENEROUS (1.4–1.85×). Devanagari conjuncts
// need vertical room — pre-mortem failure mode #9 specifically warned
// about clipping on cheap Android. Never use line-height < 1.4 for
// Devanagari text.

class YugmaFonts {
  YugmaFonts._();

  // Devanagari (source-of-truth locale per ADR-008)
  static const String devaDisplay = 'Tiro Devanagari Hindi';
  static const String devaBody = 'Mukta';

  // English (secondary toggle)
  static const String enDisplay = 'Fraunces';
  static const String enBody = 'EB Garamond';

  // Universal — for numbers, prices, timestamps, technical UI
  static const String mono = 'DM Mono';
}

// Type scale — sized for cheap-Android Devanagari rendering
// All sizes in logical pixels (sp on Android, pt on iOS)
class YugmaTypeScale {
  YugmaTypeScale._();

  // Default tier
  static const double display = 32.0;
  static const double h1 = 26.0;
  static const double h2 = 22.0;
  static const double h3 = 18.0;
  static const double bodyLarge = 17.0;
  static const double body = 15.0;
  static const double bodySmall = 14.0;
  static const double caption = 13.0;
  static const double label = 12.0;

  // Elder tier multiplier (per PRD P2.3, brief Constraint accessibility)
  static const double elderMultiplier = 1.4;

  // Helper for elder tier sizes
  static double elder(double base) => base * elderMultiplier;
}

// Line heights — generous for Devanagari
class YugmaLineHeights {
  YugmaLineHeights._();
  static const double tight = 1.25;
  static const double snug = 1.4;
  static const double normal = 1.6;
  static const double loose = 1.85;
}

// ─────────────────────────────────────────────────────────────────
// SPACING — 4dp grid
// ─────────────────────────────────────────────────────────────────
class YugmaSpacing {
  YugmaSpacing._();
  static const double s1 = 4.0;
  static const double s2 = 8.0;
  static const double s3 = 12.0;
  static const double s4 = 16.0;
  static const double s5 = 20.0;
  static const double s6 = 24.0;
  static const double s8 = 32.0;
  static const double s10 = 40.0;
  static const double s12 = 48.0;
  static const double s16 = 64.0;
}

// ─────────────────────────────────────────────────────────────────
// RADIUS
// ─────────────────────────────────────────────────────────────────
class YugmaRadius {
  YugmaRadius._();
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double pill = 9999.0;
}

// ─────────────────────────────────────────────────────────────────
// TAP TARGETS — accessibility minimums
// ─────────────────────────────────────────────────────────────────
//
// Per Sally's UX Spec §7 and PRD P2.3 elder tier requirements
class YugmaTapTargets {
  YugmaTapTargets._();
  static const double minDefault = 48.0;
  static const double minElder = 56.0;
}

// ─────────────────────────────────────────────────────────────────
// ELEVATION / SHADOWS
// ─────────────────────────────────────────────────────────────────
//
// Shadows use wood-tone alpha (warm dark brown), not generic black.
// This keeps the aesthetic warm — generic shadows would feel cold.
class YugmaShadows {
  YugmaShadows._();

  static List<BoxShadow> get card => const [
        BoxShadow(
          color: Color(0x1A4A2308), // 10% primaryDeep
          blurRadius: 3,
          offset: Offset(0, 1),
        ),
        BoxShadow(
          color: Color(0x0F4A2308), // 6% primaryDeep
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get elevated => const [
        BoxShadow(
          color: Color(0x1F4A2308), // 12% primaryDeep
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
        BoxShadow(
          color: Color(0x1A4A2308), // 10% primaryDeep
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get brassGlow => const [
        BoxShadow(
          color: Color(0x33B8860B), // 20% accent
          blurRadius: 0,
          spreadRadius: 2,
        ),
        BoxShadow(
          color: Color(0x2EB8860B), // 18% accent
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ];
}

// ─────────────────────────────────────────────────────────────────
// MOTION DURATIONS — restrained
// ─────────────────────────────────────────────────────────────────
//
// Per pre-mortem #9 and brief Constraint cheap-Android: no animations
// > 300ms, no spring-bouncy curves. Motion should feel deliberate,
// not snappy.
class YugmaMotion {
  YugmaMotion._();

  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 280);

  // Elder tier — slower per P2.3
  static const Duration elderFast = Duration(milliseconds: 350);
  static const Duration elderNormal = Duration(milliseconds: 450);

  // Curves — restrained, never bouncy
  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutQuart;
  static const Curve elder = Curves.easeInOutCubic;
}
