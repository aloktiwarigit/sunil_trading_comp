// =============================================================================
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
//
// Ported faithfully from `_bmad-output/planning-artifacts/frontend-design-
// bundle/lib_core/theme/tokens.dart` during Phase 2.0 Wave 1. Zero
// Devanagari strings here — pure Flutter constants, 100% Sprint 0 safe.
// =============================================================================

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

/// Color constants for the Yugma Dukaan design system.
class YugmaColors {
  YugmaColors._();

  // Primary scale — polished sheesham wood

  /// Primary sheesham brown. The dominant color of the customer app.
  static const Color primary = Color(0xFF6B3410);

  /// Darker sheesham for hover / pressed states.
  static const Color primaryDeep = Color(0xFF4A2308);

  /// Secondary saddle brown — supporting accents.
  static const Color secondary = Color(0xFF8B4513);

  // Brass accents — antique, never candy

  /// Antique brass for dividers, badges, highlights.
  static const Color accent = Color(0xFFB8860B);

  /// Brighter brass glow for focus rings.
  static const Color accentGlow = Color(0xFFD4A547);

  // Commitment color — RESERVED for: order commit, payment success,
  // udhaar khaata acceptance moments. Do not use elsewhere.

  /// Oxblood. RESERVED for commit / payment-success / udhaar-acceptance.
  /// Never use for general UI — it visually marks gravity.
  static const Color commit = Color(0xFF7B1F1F);

  /// Lighter oxblood for commit button glow states.
  static const Color commitGlow = Color(0xFF9B2A2A);

  // Background scale — aged cream paper, never pure white

  /// Aged cream paper — the canvas. Never pure white.
  static const Color background = Color(0xFFFAF3E7);

  /// Slightly warmer cream for cards on the background.
  static const Color backgroundWarmer = Color(0xFFF5EBD7);

  /// Surface color for elevated cards.
  static const Color surface = Color(0xFFFFFAF0);

  /// Maximum elevation surface — dialogs, modals.
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  /// Subtle line for paper-ruled dividers.
  static const Color paperLine = Color(0xFFE8DCC4);

  /// Generic divider — 12% primary.
  static const Color divider = Color(0x1F6B3410);

  // Text scale — never pure black

  /// Primary text on background. Warm near-black.
  static const Color textPrimary = Color(0xFF1F1611);

  /// Secondary text for captions + metadata.
  static const Color textSecondary = Color(0xFF4A3826);

  /// Muted text for disabled + placeholder states.
  static const Color textMuted = Color(0xFF7A6655);

  /// Text on primary-colored surfaces.
  static const Color textOnPrimary = Color(0xFFFAF3E7);

  // Semantic — derived from the wood/brass palette, not generic Material

  /// Success / confirmation — forest moss.
  static const Color success = Color(0xFF3D5C2A);

  /// Warning — weathered brass.
  static const Color warning = Color(0xFF8B6914);

  /// Error — same as commit (intentional visual gravity).
  static const Color error = Color(0xFF7B1F1F);

  /// Info — monsoon ink.
  static const Color info = Color(0xFF2C4A5C);
}

// ─────────────────────────────────────────────────────────────────
// TYPOGRAPHY TOKENS
// ─────────────────────────────────────────────────────────────────
//
// Font choices per Brief v1.4 Constraint 4:
//
//   - Tiro Devanagari Hindi (display) — characterful, designed by
//     Tiro Typeworks specifically for Devanagari clarity at small sizes
//   - Mukta (body) — warmer than Noto, still highly readable
//   - Fraunces (English display) — variable serif with personality
//   - EB Garamond (English body) — classic warm pairing
//   - DM Mono (numerals/labels) — for prices, timestamps, technical UI
//
// All five are Google Fonts, all subset-able to ≤160 KB total per
// PRD I6.9 AC #4 (100 KB Devanagari pair + 60 KB English+mono pair).
// Subsetting script lives at `tools/generate_devanagari_subset.sh`.
//
// Line heights are DELIBERATELY GENEROUS (1.4–1.85×). Devanagari conjuncts
// need vertical room — pre-mortem failure mode #9 specifically warned
// about clipping on cheap Android. Never use line-height < 1.4 for
// Devanagari text.

/// Font family names per Brief v1.4 Constraint 4.
class YugmaFonts {
  YugmaFonts._();

  // Devanagari (source-of-truth locale per ADR-008)

  /// Devanagari display font — characterful, designed for clarity.
  static const String devaDisplay = 'Tiro Devanagari Hindi';

  /// Devanagari body font — warm and highly readable.
  static const String devaBody = 'Mukta';

  // English (secondary toggle)

  /// English display font — variable serif with personality.
  static const String enDisplay = 'Fraunces';

  /// English body font — classic warm pairing with Fraunces.
  static const String enBody = 'EB Garamond';

  // Universal — for numbers, prices, timestamps, technical UI

  /// Monospace font for numerals, prices, timestamps.
  static const String mono = 'DM Mono';
}

/// Type scale in logical pixels (sp on Android, pt on iOS).
class YugmaTypeScale {
  YugmaTypeScale._();

  // Default tier

  /// Display size — hero headings.
  static const double display = 32.0;

  /// H1 — top-level screen titles.
  static const double h1 = 26.0;

  /// H2 — section headings.
  static const double h2 = 22.0;

  /// H3 — sub-section headings.
  static const double h3 = 18.0;

  /// Body large — prominent paragraph text.
  static const double bodyLarge = 17.0;

  /// Body — default paragraph text.
  static const double body = 15.0;

  /// Body small — dense lists + metadata.
  static const double bodySmall = 14.0;

  /// Caption — photo captions + footnotes.
  static const double caption = 13.0;

  /// Label — buttons + chips.
  static const double label = 12.0;

  // Elder tier multiplier (per PRD P2.3, brief Constraint accessibility)

  /// Multiplier applied to every type size when elder tier is active.
  /// 1.4× means 15sp body → 21sp body.
  static const double elderMultiplier = 1.4;

  /// Helper to compute elder-tier size from a base size.
  static double elder(double base) => base * elderMultiplier;
}

/// Line heights — generous for Devanagari conjuncts.
class YugmaLineHeights {
  YugmaLineHeights._();

  /// Tight line height — for display headings only.
  static const double tight = 1.25;

  /// Snug — for sub-headings.
  static const double snug = 1.4;

  /// Normal — default for body text.
  static const double normal = 1.6;

  /// Loose — for poetry / long-form / ritual copy.
  static const double loose = 1.85;
}

// ─────────────────────────────────────────────────────────────────
// SPACING — 4dp grid
// ─────────────────────────────────────────────────────────────────

/// Spacing scale on a 4dp grid.
class YugmaSpacing {
  YugmaSpacing._();

  /// 4dp — minimum breathing room.
  static const double s1 = 4.0;

  /// 8dp — tight padding.
  static const double s2 = 8.0;

  /// 12dp — list item padding.
  static const double s3 = 12.0;

  /// 16dp — default content padding.
  static const double s4 = 16.0;

  /// 20dp — between sections.
  static const double s5 = 20.0;

  /// 24dp — card outer padding.
  static const double s6 = 24.0;

  /// 32dp — major section breaks.
  static const double s8 = 32.0;

  /// 40dp — hero padding.
  static const double s10 = 40.0;

  /// 48dp — edge-of-screen hero margin.
  static const double s12 = 48.0;

  /// 64dp — max outer margin.
  static const double s16 = 64.0;
}

// ─────────────────────────────────────────────────────────────────
// RADIUS
// ─────────────────────────────────────────────────────────────────

/// Corner radius tokens.
class YugmaRadius {
  YugmaRadius._();

  /// 4dp — subtle rounding for chips.
  static const double sm = 4.0;

  /// 8dp — default button radius.
  static const double md = 8.0;

  /// 12dp — card radius.
  static const double lg = 12.0;

  /// 16dp — hero card radius.
  static const double xl = 16.0;

  /// Pill shape — fully rounded.
  static const double pill = 9999.0;
}

// ─────────────────────────────────────────────────────────────────
// TAP TARGETS — accessibility minimums
// ─────────────────────────────────────────────────────────────────
//
// Per Sally's UX Spec §7 and PRD P2.3 elder tier requirements

/// Tap target size thresholds.
class YugmaTapTargets {
  YugmaTapTargets._();

  /// 48dp — WCAG AA minimum for default tier.
  static const double minDefault = 48.0;

  /// 56dp — elder tier minimum per PRD P2.3.
  static const double minElder = 56.0;
}

// ─────────────────────────────────────────────────────────────────
// ELEVATION / SHADOWS
// ─────────────────────────────────────────────────────────────────
//
// Shadows use wood-tone alpha (warm dark brown), not generic black.
// This keeps the aesthetic warm — generic shadows would feel cold.

/// Shadow presets using warm wood-tone alpha (not generic black).
class YugmaShadows {
  YugmaShadows._();

  /// Card elevation — light, close shadow.
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

  /// Elevated surface — heavier shadow for dialogs + modals.
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

  /// Brass glow — for focus rings + accent emphasis.
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

/// Motion duration + curve tokens.
class YugmaMotion {
  YugmaMotion._();

  /// 100ms — instant feedback (toasts, taps).
  static const Duration instant = Duration(milliseconds: 100);

  /// 200ms — fast transitions.
  static const Duration fast = Duration(milliseconds: 200);

  /// 280ms — default transition speed.
  static const Duration normal = Duration(milliseconds: 280);

  // Elder tier — slower per P2.3

  /// 350ms — elder tier fast.
  static const Duration elderFast = Duration(milliseconds: 350);

  /// 450ms — elder tier normal.
  static const Duration elderNormal = Duration(milliseconds: 450);

  // Curves — restrained, never bouncy

  /// Standard ease-out cubic.
  static const Curve standard = Curves.easeOutCubic;

  /// Emphasized ease-out quart.
  static const Curve emphasized = Curves.easeOutQuart;

  /// Elder tier — smoother, less sharp.
  static const Curve elder = Curves.easeInOutCubic;
}
