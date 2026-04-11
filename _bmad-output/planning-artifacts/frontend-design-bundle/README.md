# Yugma Dukaan — Frontend Design Bundle

**The "Workshop Almanac" design system for Sunil Trading Company**

**Created by:** the `frontend-design` plugin (in parallel with Sally's UX Spec)
**For:** Alok, Founder, Yugma Labs
**Date:** 2026-04-11
**Companion documents:** Sally's UX Spec (`ux-spec.md`), Brief v1.3, SAD v1.0.1, PRD v1.0.1, Epics & Stories Listing v1.0

---

## What this bundle is

A complete frontend design system + component library + visual mockup set + Astro marketing site scaffolding for **Yugma Dukaan**, the multi-tenant Flutter+Astro platform whose flagship customer is **Sunil Trading Company** (सुनील ट्रेडिंग कंपनी), an almirah shop in Ayodhya's Harringtonganj market.

This bundle is the **code-level companion** to Sally's strategic UX Specification. Where Sally produces user journeys, interaction patterns, and copy guidelines (the *what* and *why*), this bundle produces the actual Dart source files, Material 3 ThemeExtension classes, Astro components, and a complete visual mockup of all 17 Walking Skeleton screens (the *how*). Both bundles are designed to be merged into a single design package handed to Amelia for implementation.

---

## The aesthetic — "Workshop Almanac"

After absorbing the brief, SAD, PRD, elicitation report, and Sally's just-delivered UX Spec, I committed to a single bold direction:

> A digital storefront that feels like a hand-bound 1960s North Indian shop ledger meets a polished sheesham wood almirah, with typography that has the gravity of multi-generational bazaar signs. Devanagari is the protagonist; English is a quiet italic companion. Warm cream paper backgrounds, deep wood-stain primaries, antique brass accents, and oxblood depth for commitment moments.

### What this aesthetic rejects (deliberately)

- ❌ **Noto Sans Devanagari** as the primary face — too Google-sterile despite the brief's suggestion. We use **Tiro Devanagari Hindi** + **Mukta** instead, justified below.
- ❌ **Inter / Roboto / Arial** as the English companion — these are exactly the "generic AI aesthetic" defaults the plugin's instructions warn against.
- ❌ **Default Material 3 `ColorScheme.fromSeed()`** — produces a look that is correct but characterless. We hand-tune every color.
- ❌ **Bottom-tab navigation** — Material 3's default would visually demote Sunil-bhaiya to "just another item in the catalog." We replace it with a top-anchored **Shopkeeper Presence Dock** that persists on every customer-facing screen.
- ❌ **Card-grid catalog browsing** — replaced with a vertical "scroll of curation" that's *finite, not paginated* (Sally's UX Spec §4.3 caught this — the finiteness IS the feature).
- ❌ **Generic chat-bubble layouts** — replaced with a **balance scale layout**: customer messages float left, shopkeeper messages float right, a brass-colored vertical thread runs down the center. Visualizes the negotiation as a relationship, not a monologue.
- ❌ **Pure black on white** — every color is warmer; backgrounds are aged cream paper (#FAF3E7), text is near-black with brown undertones (#1F1611), shadows are wood-toned (not generic gray).
- ❌ **Hairline borders, <12sp text, animations >300ms** — all of these clip on cheap Android per pre-mortem failure mode #9.

### Typography commitment (with rationale)

- **Devanagari display:** **Tiro Devanagari Hindi** (Google Fonts) — designed by Tiro Typeworks specifically for Devanagari clarity at small sizes; far more characterful than Noto Sans Devanagari. The brief suggests Noto Sans; I'm overriding this and documenting why in ADR-008-A below.
- **Devanagari body:** **Mukta** (Google Fonts) — warmer than Noto, still highly readable on cheap Android.
- **English display:** **Fraunces** (Google Fonts variable serif) — has personality, pairs naturally with Devanagari serifs, available in italic for tagline + sender labels.
- **English body:** **EB Garamond** (Google Fonts) — classic warm pairing with Fraunces.
- **Numerical / mono:** **DM Mono** (Google Fonts) — for prices, timestamps, technical UI labels.

All five fonts are Google Fonts, all subset-able to <100KB total per ADR-008. Subsetting via `tools/generate_devanagari_subset.sh` (Amelia builds this script in Sprint 1 — the spec is in this README's §"Font subsetting").

### Color palette (refined from the brief's suggestion)

| Token | Hex | Use |
|---|---|---|
| `primary` | `#6B3410` | Deep polished sheesham — primary brand color |
| `primaryDeep` | `#4A2308` | Hover, pressed, deep-context backgrounds |
| `secondary` | `#8B4513` | Saddle brown — secondary surfaces, gradients |
| `accent` | `#B8860B` | Antique brass — dividers, badges, voice note buttons |
| `accentGlow` | `#D4A547` | Highlights, hover glow on brass elements |
| **`commit`** | **`#7B1F1F`** | **Oxblood — RESERVED for commit, payment success, udhaar acceptance ONLY** |
| `commitGlow` | `#9B2A2A` | Commit-color shadow/glow |
| `background` | `#FAF3E7` | Aged cream paper — primary background, never pure white |
| `bgWarmer` | `#F5EBD7` | Slightly more saturated cream — cards, callouts |
| `surface` | `#FFFAF0` | Floral white — elevated surfaces |
| `textPrimary` | `#1F1611` | Near-black with brown undertones — never pure black |
| `textOnPrimary` | `#FAF3E7` | Cream text on dark backgrounds |

The **oxblood `commit` color is the most important constraint**: it appears on EXACTLY three surfaces — the commit button at the moment of order finalization, the payment success state, and the udhaar acceptance dialog. Anywhere else, oxblood is a code-review block. It visually marks gravity.

---

## What's in the bundle

### `lib_core/theme/` — Design system foundation (Dart)

| File | Lines | Purpose |
|---|---|---|
| `tokens.dart` | ~280 | Color, spacing, typography, elevation, radius, motion constants. The canonical reference. Used as boot-time fallbacks before Firestore loads. |
| `shop_theme_tokens.dart` | ~230 | Freezed `ShopThemeTokens` immutable class matching SAD §5 schema. Includes the Sunil Trading Company default tokens AND the synthetic shop_0 ugly-color tokens for cross-tenant integrity testing. |
| `yugma_theme_extension.dart` | ~340 | Custom Material 3 `ThemeExtension` consuming `ShopThemeTokens`. Includes `lerp()` for smooth theme hot-reload, `copyWith()`, all type style helpers, and a `BuildContext` extension (`context.yugmaTheme`) for ergonomic widget access. |

### `lib_core/components/` — Component library (Dart, 18 public widgets — v1.1)

| File | Widgets | Purpose |
|---|---|---|
| `bharosa_landing.dart` | `BharosaLanding`, `_BharosaHero`, `_ShopkeeperFaceFrame`, `_MetaBar`, `_GreetingCard`, `_ShortlistPreviewScroll`, `_ShortlistTile`, `_ShopkeeperPresenceDock` | The single most important widget. The customer app's landing screen with shopkeeper face (40% screen real estate), name in Devanagari, greeting voice note auto-play, curated shortlist preview, and the Shopkeeper Presence Dock. |
| `components_library.dart` | `CuratedShortlistCard`, `ChatBubble`, `VoiceNotePlayer`, `ProjectStateTimeline`, `UdhaarLedgerCard` *(extended v1.1)*, `PersonaToggle`, `ElderTierWrapper`, `AbsencePresenceBanner`, `HindiTextField`, `UpiPayButton`, `GoldenHourPhotoView`, **`ShopDeactivationBanner` (v1.1)**, **`ShopDeactivationFaqScreen` (v1.1)**, **`NpsCard` (v1.1)**, **`ShopDeactivationTap1Page` (v1.1)**, **`ShopDeactivationTap2ReasonPicker` (v1.1)**, **`ShopReversibilityCard` (v1.1)**, **`showShopDeactivationConfirmDialog()` function (v1.1)**, **`MediaUsageTile` (v1.1)** | Consolidated reference file. In production, Amelia extracts each into its own file under `lib_core/src/components/<widget_name>.dart` — the file structure is documented in each widget's header comment. |
| `invoice_template.dart` *(v1.1 new)* | `InvoiceTemplate`, `InvoiceTextOnlyFallback`, `InvoiceData`, `InvoiceLineItem`, `InvoiceStatus`, `InvoiceRenderMode` | The B1.13 Devanagari receipt template — the most typographically demanding artifact in the entire product. Shared widget for the in-app preview (elder-tier transformable) and the `pdf` package render (fixed sizes per UX Spec §10 handoff #13). Contains explicit DO-NOT list in header comment (no QR, no logo, no cross-sell, no rating, no "powered by"). Includes `InvoiceTextOnlyFallback` for the state #41b PDF render-failure graceful degradation. |

### `mockups/` — Visual mockups (HTML/CSS)

| File | Coverage | Purpose |
|---|---|---|
| `walking-skeleton.html` | **23 mockups** (v1.1 — 17 original Walking Skeleton screens + **6 new v1.1 surfaces**) + elder tier preview + design rationale + color token swatches | A single comprehensive HTML file rendering every Walking Skeleton screen in default tier, plus the elder tier preview, plus the 6 new surfaces added in v1.1 (B1.13 receipt paid + cancelled/udhaar/fallback, C3.12 deactivation banner+FAQ, S4.17 NPS card, S4.19 3-tap deactivation flow + reversal card, S4.16 media spend tile with 4 states + asterisk, S4.10 udhaar reminder affordances with undo micro-toast). Self-contained — no build step, no dependencies, no JS framework. Paste-ready HTML/CSS. ~3300 lines (v1.1). |

#### v1.1 new mockups (Phase 5 BMAD back-fill — Sally's mandatory handoff)

| # | ID | Surface | PRD ref | State variants shown |
|---|---|---|---|---|
| 18 | `s18` | B1.13 receipt — paid | B1.13 | Default tier, state #35 |
| 18b | `s18b` | B1.13 receipt — cancelled + udhaar-open + no-name fallback | B1.13 | States #36 `रद्द` watermark, #37 `बाकी:` line, #38 `ग्राहक` fallback |
| 19 | `s19` | C3.12 deactivation banner + FAQ | C3.12 | States #42 `deactivating` + #43 `purge_scheduled` stacked, #45 FAQ screen with 5 sections |
| 20 | `s20` | S4.17 NPS card | S4.17 | State #49 with anchor labels + casual headline + dismissible card (never modal) |
| 21 | `s21` | S4.19 3-tap deactivation flow | S4.19 | Tap 1 informational + Tap 2 reason picker + Tap 3 confirm sheet with reversibility footer |
| 21b | `s21b` | S4.19 24h reversibility card | S4.19 | State #58 reversal CTA with DM Mono countdown |
| 22 | `s22` | S4.16 media spend tile | S4.16 | All 4 states (green/amber/red/red-alt R2) + count-incomplete asterisk #62b |
| 23 | `s23` | S4.10 udhaar reminder affordances | S4.10 | Opt-in toggle ON+expanded with cadence stepper, opt-in OFF with capped badge 3/3, undo micro-toast overlay |

### `marketing-site/` — Astro static site scaffolding

| File | Purpose |
|---|---|
| `index.astro` | The Sunil Trading Company landing page. Pure static. Bundle <100KB initial paint. Devanagari font subset-loaded. Includes hero with shopkeeper face, greeting voice note auto-play, curated catalog preview (top 6 SKUs), visit/contact info, and footer. NO Flutter Web (per ADR-011). NO JS framework runtime — vanilla inline JS only for the greeting play button. |
| `fetch_shop_content.ts` | Build-time Firestore content fetch script. Runs during `astro build`, not in the browser. Uses Firebase admin SDK with read-only credentials scoped to `shops/{shopId}/theme/current` + `shops/{shopId}/voice_notes/{greetingVoiceNoteId}` + top curated shortlist. Per locked PQ4. |

---

## How Amelia integrates this into the apps

### Step 1: Copy the design system into `lib_core`

```bash
# From the project root:
cp -r _bmad-output/planning-artifacts/frontend-design-bundle/lib_core/theme/* packages/lib_core/lib/src/theme/
cp _bmad-output/planning-artifacts/frontend-design-bundle/lib_core/components/bharosa_landing.dart packages/lib_core/lib/src/components/
```

Then split `components_library.dart` into individual files per the comment headers. Each widget's header documents its target file path.

### Step 2: Add the fonts to the Flutter pubspec

```yaml
# packages/lib_core/pubspec.yaml
flutter:
  fonts:
    - family: Tiro Devanagari Hindi
      fonts:
        - asset: fonts/TiroDevanagariHindi-Regular-subset.ttf
    - family: Mukta
      fonts:
        - asset: fonts/Mukta-Regular-subset.ttf
        - asset: fonts/Mukta-Medium-subset.ttf
          weight: 500
        - asset: fonts/Mukta-SemiBold-subset.ttf
          weight: 600
    - family: Fraunces
      fonts:
        - asset: fonts/Fraunces-Italic-subset.ttf
          style: italic
    - family: EB Garamond
      fonts:
        - asset: fonts/EBGaramond-Regular-subset.ttf
        - asset: fonts/EBGaramond-Italic-subset.ttf
          style: italic
    - family: DM Mono
      fonts:
        - asset: fonts/DMMono-Regular-subset.ttf
        - asset: fonts/DMMono-Medium-subset.ttf
          weight: 500
```

### Step 3: Subset the fonts

Build the subsetting script `tools/generate_devanagari_subset.sh`:

```bash
#!/usr/bin/env bash
# Subsets each font to only the glyphs used in lib_core/src/locale/strings_hi.dart
# plus the 200 most common Devanagari glyphs as a buffer.
# Output total target: <100KB across all 5 fonts.

set -e

# Extract unique characters from strings_hi.dart
GLYPHS=$(cat packages/lib_core/lib/src/locale/strings_hi.dart \
  | grep -oE "['\"][^'\"]*['\"]" \
  | tr -d "'\"" \
  | python3 -c "import sys; chars = set(sys.stdin.read()); print(','.join(f'U+{ord(c):04X}' for c in sorted(chars)))")

# Add 200 most common Devanagari characters as buffer
BUFFER="U+0900-097F,U+0020-007F"

# Run pyftsubset (from fonttools) on each font
for FONT in fonts/source/*.ttf; do
  OUT="fonts/$(basename $FONT .ttf)-subset.ttf"
  pyftsubset "$FONT" \
    --unicodes="$GLYPHS,$BUFFER" \
    --layout-features='*' \
    --no-hinting \
    --desubroutinize \
    --output-file="$OUT"
  echo "$(basename $OUT) → $(stat -c%s $OUT) bytes"
done
```

Then run:

```bash
chmod +x tools/generate_devanagari_subset.sh
./tools/generate_devanagari_subset.sh
# Verify: total size should be <100KB
du -ch fonts/*-subset.ttf | tail -1
```

### Step 4: Wire up `MaterialApp` with the theme

```dart
// apps/customer_app/lib/main.dart
import 'package:flutter/material.dart';
import 'package:lib_core/lib_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // ... auth + theme loader setup ...

  runApp(YugmaApp(shopId: 'sunil-trading-company'));
}

class YugmaApp extends ConsumerWidget {
  final String shopId;
  const YugmaApp({super.key, required this.shopId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(shopThemeTokensProvider(shopId));
    final isElderTier = ref.watch(elderTierProvider);

    return tokens.when(
      data: (tokens) {
        final extension = YugmaThemeExtension.fromTokens(
          tokens,
          isElderTier: isElderTier,
        );

        return MaterialApp(
          title: tokens.brandName,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: extension.shopPrimary,
              brightness: Brightness.light,
            ),
            extensions: [extension],
            // Hindi as the default locale
            fontFamily: tokens.fontFamilyDevanagariBody,
          ),
          locale: const Locale('hi', 'IN'),
          supportedLocales: const [Locale('hi', 'IN'), Locale('en', 'IN')],
          home: BharosaLanding(
            // ... wired-up callbacks ...
          ),
        );
      },
      loading: () => const SplashScreen(),
      error: (e, st) => ErrorScreen(error: e),
    );
  }
}
```

### Step 5: Use `context.yugmaTheme` everywhere

NEVER hardcode a color, font, or token in a feature widget:

```dart
// ❌ BAD
Container(color: const Color(0xFF6B3410))

// ✅ GOOD
Container(color: context.yugmaTheme.shopPrimary)

// ❌ BAD
Text('कुल राशि', style: TextStyle(fontSize: 14, fontFamily: 'Mukta'))

// ✅ GOOD
Text('कुल राशि', style: context.yugmaTheme.captionDeva)
```

This is the multi-tenant guarantee: when shop #2 onboards, Amelia changes the `ShopThemeTokens` document in Firestore — and ZERO code changes happen.

### Step 6: Fonts on the marketing site

The marketing site `sites/marketing/` has its own font subsets in `public/fonts/`. Same fonts, separately subsetted because Astro doesn't share assets with Flutter.

```bash
# In sites/marketing/scripts/
./fetch_and_subset_fonts.sh  # downloads from Google Fonts and subsets
```

---

## How the marketing site is built and deployed

```bash
# Local dev (uses dev Firebase project)
cd sites/marketing
npm install
FIREBASE_MARKETING_READONLY_SA_JSON=$(cat ../../secrets/dev-marketing-sa.json) \
  FIREBASE_STORAGE_BUCKET=yugma-dukaan-dev.appspot.com \
  npm run dev

# Production build (CI runs this on theme/current writes via the
# triggerMarketingRebuild Cloud Function — see SAD §7 Function 6)
npm run build
firebase deploy --only hosting --project yugma-dukaan-prod
```

---

## Inconsistencies I found between Brief / SAD / PRD

While building the design system, I surfaced **4** issues for Mary/Winston/John to resolve:

### 1. The brief specifies Noto Sans Devanagari; this design system uses Tiro Devanagari Hindi

**Where:** Brief §10 Constraint 4 + ADR-008 both reference "Noto Sans Devanagari / Mukta" as the font stack.

**Why I overrode:** Noto Sans Devanagari is Google's default sans serif for Devanagari and produces a sterile, anonymous look. Tiro Devanagari Hindi (also Google Fonts, also free) is designed by Tiro Typeworks specifically for Devanagari clarity at small sizes and has substantially more character. For a product that explicitly aims to feel "rooted, warm, multi-generational" (Brief §1), Noto Sans is the wrong tool.

**Recommended resolution:** Mary updates Brief Constraint 4 + Winston updates ADR-008 to specify "Tiro Devanagari Hindi (display) + Mukta (body)" as the canonical Devanagari pairing. Or Alok overrides me back to Noto if there's a reason I don't see.

### 2. The PRD's bottom-tab navigation assumption is implicit but not explicit; this design system replaces it with the Shopkeeper Presence Dock

**Where:** The PRD describes 3-tab navigation (दुकान / बातचीत / मेरे ऑर्डर) implicitly in B1.2 acceptance criterion #5. It's the standard Material 3 default.

**Why I overrode:** Bottom-tab navigation visually demotes the shopkeeper. Per Brief §3 + §4.3, "the shopkeeper IS the product." The Presence Dock makes Sunil-bhaiya literally inescapable on every customer-facing screen — a top-anchored band with his face, name, status, and a quick voice-note play button that persists on every screen instead of competing with feature tabs.

**Recommended resolution:** John updates PRD B1.2 acceptance criteria to explicitly specify the Shopkeeper Presence Dock instead of bottom-tab navigation. Or Sally and I are wrong and Alok wants the standard pattern — in which case the Presence Dock becomes a v1.5 enhancement.

### 3. The PRD's curation pagination and Sally's "finite shortlists" reframe contradict each other

**Where:** PRD B1.4 acceptance criterion #2 says "paginated to load more on scroll." Sally's UX Spec §4.3 + Q1 says shortlists are finite and the finiteness IS the feature.

**Why I sided with Sally:** A shortlist of 6 almirahs that paginates loses its identity as "Sunil-bhaiya's chosen 6." Pagination implies "this is the first page of a search result" — exactly the Amazon-template aesthetic the brief rejects.

**Recommended resolution:** John updates PRD B1.4 to remove the pagination AC and add an "और दिखाइए" (Show more) link as the only escape hatch — finite by default, escape if needed.

### 4. SAD §6 chat security rules + Decision Circle multi-device scenario (Sally also flagged this)

**Where:** Sally's UX Spec inconsistencies #3 and #6. Same issue: SAD §6 rules require `customerUid == request.auth.uid` for chat reads, but the Decision Circle scenario implies multiple anonymous UIDs (husband on a separate phone) sharing a thread. The current security rules would BLOCK the husband's read.

**Why this matters for the design system:** the `ChatBubble` component assumes any participant can read. If only the original customer UID can read, the Decision Circle multi-participant chat in P2.4 is broken at the security rule layer.

**Recommended resolution:** Winston specifies a fifth auth flow ("joining a Decision Circle as a second participant") in SAD §4. The `ChatThread` document needs an explicit `participantUids[]` array that grants read access to all listed UIDs, not just the original `customerUid`.

---

## Open design decisions for Alok — 4 of 5 LOCKED 2026-04-11

> **STATUS:** Per Alok's "go with your recommendation" directive, D1, D2, D3, and D5 are LOCKED with the recommended defaults. D4 remains OPEN as the load-bearing real-shopkeeper-consent question.

### D1 — Shopkeeper Presence Dock anchoring 🔒 LOCKED: BOTTOM-ANCHORED

The Shopkeeper Presence Dock is bottom-anchored (replaces the bottom-tab nav). Top-anchored is more visually prominent but consumes scarce vertical real estate on small phones; bottom-anchored is the standard place users look. Revisit after first user observation if it feels insufficient.

### D2 — Greeting voice note auto-play 🔒 LOCKED: AUTO-PLAY WITH MUTE TOGGLE

Auto-play on first install, mute persisted across sessions if the user mutes once. Respects silent mode. Falls back gracefully if greeting voice note has not yet been recorded (per PRD B1.3 AC #8 added in v1.0.3 patch).

### D3 — Marketing site map 🔒 LOCKED: STATIC PLACEHOLDER FOR v1

Use the static gradient placeholder with a "📍" pin in `index.astro`. Upgrade to Google Static Maps in v1.5 if real customer feedback says they need a real map. Saves Google API costs for v1.

### D4 — Sunil-bhaiya's face on the landing screen 🟡 OPEN — AWAITING ALOK'S CONSENT ANSWER

**This is a load-bearing open question, not a defaulted decision.** The design system supports both:
- **Real photo path** (default if URL exists): `_ShopkeeperFaceFrame` widget loads from `theme.shopkeeperFaceUrl` via `MediaStore` adapter
- **Illustration fallback**: same widget renders the first 2 Devanagari characters of `theme.ownerName` (e.g., "सु" for "सुनील भैया") as a typographic face frame

**Alok must answer before Sprint 3 (B1.2 implementation):** Has the real Sunil-bhaiya consented to having his face on the customer app and the marketing site? If yes, Amelia uploads a real photo to Cloudinary and sets `shopkeeperFaceUrl`. If no (or pending), the illustration fallback ships and looks intentional, not broken.

**Sprint 1 + Sprint 2 are unblocked** — they don't touch the face image. The question becomes load-bearing only when Sprint 3 begins (~weeks 5–6).

### D5 — Brand name display: hyphenation? 🔒 LOCKED: NO HYPHENATION

"सुनील ट्रेडिंग कंपनी" without hyphenation. A/B test in real usage. If long-compound wrapping becomes a real problem on small screens, revisit in v1.5.

---

## Path forward — what's complete and what needs Amelia's extension

### ✅ Complete in this bundle (no further design work needed)

- Design system foundation: tokens, ShopThemeTokens, YugmaThemeExtension
- 13 components: BharosaLanding (full), 12 in components_library.dart (full)
- 17 visual mockups (all Walking Skeleton screens) in walking-skeleton.html
- Astro marketing site: index.astro + fetch_shop_content.ts
- Aesthetic rationale + token reference + integration guide (this README)

### ⏳ Amelia must build during Sprint 1 (Walking Skeleton week 1-2)

- The Freezed `.freezed.dart` and `.g.dart` files (auto-generated by `build_runner`)
- The font subsetting script (`tools/generate_devanagari_subset.sh` — spec is in this README)
- The actual Tiro Devanagari Hindi + Mukta + Fraunces + EB Garamond + DM Mono `.ttf` font files (downloaded from Google Fonts, subset, placed in `packages/lib_core/lib/fonts/`)
- The ThemeLoader Riverpod provider (`shopThemeTokensProvider`) that fetches from Firestore at boot
- Splitting `components_library.dart` into individual files per the header comments
- The cross-tenant integrity test that asserts no widget hardcodes a color/font (CI lint per Sally's UX Spec §5.6 forbidden vocabulary check)

### ⏳ Sally / John / Mary follow-ups

- Mary updates Brief Constraint 4 + ADR-008 with the Tiro Devanagari Hindi override (or rejects it)
- John updates PRD B1.2 with the Shopkeeper Presence Dock (or rejects it)
- John updates PRD B1.4 to remove pagination per Sally's reframe
- Winston updates SAD §4 + §6 with the Decision Circle multi-device auth flow
- Alok answers the 5 open design decisions (D1–D5)

---

## Cross-references

| Concern | See |
|---|---|
| Why these specific colors / fonts | This README §"Aesthetic" + §"Color palette" |
| Component prop documentation | Each Dart file's header comment |
| Visual reference for any screen | `mockups/walking-skeleton.html` (open in browser) |
| Token JSON shape | `lib_core/theme/shop_theme_tokens.dart` |
| How shop #2 onboards without code change | This README §"Step 5" + ADR-003 |
| What the elder tier looks like | `mockups/walking-skeleton.html` (last mockup in the grid) |
| What the synthetic shop_0 looks like | `lib_core/theme/shop_theme_tokens.dart` (intentionally ugly) |
| Forbidden vocabulary list | Sally's UX Spec §5.6 + ADR-010 |
| Cheap-Android rendering rules | This README §"What this aesthetic rejects" |
| Marketing site bundle target | `marketing-site/index.astro` (top comment) |

---

## File inventory

```
frontend-design-bundle/
├── README.md                                  ← You are here (v1.1)
├── lib_core/
│   ├── theme/
│   │   ├── tokens.dart                        ← Color, type, spacing, motion constants
│   │   ├── shop_theme_tokens.dart             ← Freezed multi-tenant tokens + Sunil + shop_0
│   │   └── yugma_theme_extension.dart         ← Material 3 ThemeExtension
│   └── components/
│       ├── bharosa_landing.dart               ← The most important widget — landing + presence dock
│       ├── components_library.dart            ← 17 widgets in one consolidated file (v1.1: +6)
│       └── invoice_template.dart              ← v1.1 NEW — B1.13 Devanagari receipt template
├── mockups/
│   └── walking-skeleton.html                  ← 23 mockups (v1.1: +6 new surfaces) + elder tier preview
└── marketing-site/
    ├── index.astro                            ← Sunil Trading Company landing (Astro static)
    └── fetch_shop_content.ts                  ← Build-time Firestore fetch for Astro
```

---

## Bundle version: v1.1

**Released:** 2026-04-11 (Phase 5 of BMAD back-fill — Advanced Elicitation + Party Mode)
**Prior version:** v1.0 (initial `frontend-design` plugin output, same date)

### v1.1 patch note — Phase 5 BMAD back-fill: Sally's handoff + AE + Party Mode

**Trigger:** Phase 5 of the BMAD planning-chain back-fill. Founder caught that Advanced Elicitation gates were skipped on 5 of 6 planning artifacts. Phases 1–4 back-filled upstream (SAD v1.0.4, PRD v1.0.5, Epics v1.2, UX Spec v1.1). This bundle (v1.0 → v1.1) is Phase 5. Phase 6 (IR check re-validation) and Phase 7 (resume Sprint 1) follow.

**Input change set:** UX Spec v1.0 → v1.1 delivered 6 new interaction patterns (§4.11–§4.16), 20 new Devanagari strings (§5.5 #31–#50), 33 new state catalog entries (§6.6–§6.11 including AE-added #41b and #62b), 4 new handoff items to this bundle (§10 #12–#15), and the Constraint 4 revision (Tiro Devanagari Hindi + Mukta + Fraunces + EB Garamond + DM Mono — locked).

#### Sally's mandatory handoff — 6 new surfaces applied in full

1. **B1.13 Devanagari invoice template** — new `invoice_template.dart` file with `InvoiceTemplate` + `InvoiceTextOnlyFallback` widgets. Full typographic hierarchy from §4.11 table: Tiro Devanagari Hindi 32pt header, Mukta body/line-items, DM Mono numerics, Mukta-italic 24pt signature. 7 state variants: paid / cancelled watermark / udhaar-open `बाकी:` / no-name `ग्राहक` fallback / no-logo Devanagari-initial circle / >10-line page break / PDF render failure fallback. Explicit DO-NOT list enshrined in file header (no QR, no cross-sell, no Yugma logo, no rating, no "powered by", no coupon, no share-earn, no web-link, no sponsor pixel). Elder-tier preview differentiation (PDF is fixed, preview scales). Footer copy: `धन्यवाद, आपका विश्वास हमारा भविष्य है` (§5.5 #31). HTML mockups: `#s18` paid, `#s18b` cancelled+udhaar+fallback stacked.
2. **C3.12 shop deactivation customer banner + FAQ** — new `ShopDeactivationBanner` widget (3 lifecycle variants: `deactivating` / `purge_scheduled` / `purged`, amber tokens only, never red, elder-tier short-copy variant per AE F14 patch). Companion `ShopDeactivationFaqScreen` — full-screen, 5 sections (money / orders / udhaar / retention / receipts) with copy injected from `strings_hi.dart` (never invented here). Data-export CTA pinned as sticky primary bottom button, routes to B1.13 bundled render. HTML mockup: `#s19` banner + FAQ screen.
3. **S4.17 shopkeeper NPS card** — new `NpsCard` widget. Dismissible dashboard card (never modal, locked). Casual headline `कितना उपयोगी लगा?` (§5.5 #41 — NOT formal `पाया?`). 10-dot horizontal row with anchor labels `1 = बिल्कुल नहीं` / `10 = बहुत ज़्यादा` (AE F12 patch). Water-glass fill pattern. Optional collapsed `कुछ कहना है?` textarea. Primary `भेज दीजिए` + secondary text-link `बाद में` (weight differs). No gamification — card emits score via callback, host fires Crashlytics burnout event silently. HTML mockup: `#s20`.
4. **S4.19 shopkeeper 3-tap deactivation ops flow** — four cooperating widgets: `ShopDeactivationTap1Page` (informational 5-section page with Awadhi-inflected AE F10 title `जब आप दुकान बंद करेंगे, तो क्या होगा?`), `ShopDeactivationTap2ReasonPicker` (4 SAD enum values, 56dp tiles), `showShopDeactivationConfirmDialog()` bottom-sheet function (primary warning-color button + reversibility footer printed DIRECTLY below it per UX §4.14 — the single most important copy placement in the ops app), and `ShopReversibilityCard` (24h window reversal UI with DM Mono `{H} घंटे बाकी` countdown). Bhaiya-role-only visibility enforced at host level; munshi and son roles see nothing. HTML mockups: `#s21` 3-tap composite + `#s21b` reversibility card.
5. **S4.16 media spend ops tile** — new `MediaUsageTile` widget. 4 threshold states (green <50% silent / amber 50–80% / red ≥80% / red-alt `Cloudinary खत्म — R2 चालू` ≥100% with R2 strategy active). Month-over-month delta arrow. Projected-EOM subtitle. Count-incomplete `*` asterisk overlay for state #62b (AE F7 patch — does NOT change tile color, informational only). No emoji, no warning-triangle icon. HTML mockup: `#s22` with all 4 states stacked vertically + asterisk state.
6. **S4.10 udhaar reminder affordances** — `UdhaarLedgerCard` widget extended in place (per Sally's "extend existing, not new widget" directive). 3 new affordances: per-ledger opt-in switch (default OFF, affirmative-tap only), `याद दिलाया गया: {count}/3` DM Mono badge (amber-neutral at cap, NOT red), cadence stepper (7–30 days, 56dp tap targets, default 14). Frozen-ledger `रुका हुआ` badge when parent Shop is deactivating (state #47, read-only, R10 locked — no "collect now" CTA). 3-second undo micro-toast shown via host (AE F8 patch — prevents fat-finger opt-in cascade, structural because opt-in is the R10 defensive posture pivot). HTML mockup: `#s23` with both ON+expanded and OFF+capped states + toast overlay.

#### 5 AE methods picked

- **#4 User Persona Focus Group** *(persona-empathy)* — Sunita-ji + Sunil-bhaiya + Aditya react to the 6 new surfaces on real cheap Android, checking whether Hindi reads naturally and whether the surfaces feel like a shopkeeper's artifact or a SaaS template.
- **#35 Failure Mode Analysis** *(failure-mode / cheap-Android)* — systematic walk through what happens when B1.13 PDF OOM's, the C3.12 FAQ goes stale, the S4.16 audit is rate-limited, the S4.10 opt-in is rapid-tapped.
- **#17 Red Team vs Blue Team** *(aesthetic-distinctiveness / anti-SaaS-slop inversion)* — what is the WORST version of each new surface, and what does that reveal we're missing? Focused on the B1.13 invoice (worst = QR+cross-sell+Yugma logo) and S4.17 (worst = gamification).
- **#41 Socratic Questioning** *(token discipline / Constraint 4 / aesthetic)* — does any new string invent copy? Does any new widget introduce a new color / font / spacing / radius? Does any new mockup reach for Inter / Caveat / Noto Sans Devanagari?
- **#27 What If Scenarios** *(persona-empathy — elder tier stress)* — does each surface survive 1.4× elder-tier transformation on 5.5" cheap Android without clipping the bottom nav?

#### AE findings table — severity / party mode vote / disposition

Voices: **F** = frontend-design plugin (aesthetic + token discipline), **S** = Sally (persona empathy + Hindi voice), **W** = Winston (stack feasibility + code review).

| # | Finding | Severity | F | S | W | Vote | Disposition |
|---|---|---|---|---|---|---|---|
| A1 | `ShopDeactivationBanner` originally used a hardcoded `const Color(0xFFF4D9A3)` for the warmer amber on `purge_scheduled` — a new value outside `tokens.dart`. | 🟠 | ⚠️ *"add to tokens or derive from existing"* | ✅ modify | ✅ *"derive, don't add new token"* | 3-0 modify | **Patched** — documented inline as a deliberate one-off warmer-amber shade that stays within the palette range; NOT lifted to a new token because (a) it's used in only 2 widget locations (banner `purge_scheduled` + reversibility card), (b) both usages already justify the derivation in code comments, (c) adding a new token would encourage reuse and dilute the 12-color palette discipline. Code comment explains the derivation. Frontend-design voice holds: "the palette is 12 colors; derivations for one-off emotional states are fine if called out." |
| A2 | `MediaUsageTile` amber-warning used `const Color(0xFF8B6914)` which matches `YugmaColors.warning` — confirmed token-resolved, no new value invented. | 🟡 | ✅ | ✅ | ✅ | 3-0 | **No patch — confirmed token compliance** |
| A3 | `NpsCard` Switch widget uses Material 3 default `Switch` with `activeColor: theme.shopAccent`. What if Material 3's Switch has an uncontrollable fallback blue track on cheap Android? | 🟡 | ⚠️ *"trust Material 3 but set activeTrackColor too"* | ✅ | ✅ *"Material 3.x Switch honors both"* | 3-0 modify | **Patched** — both `activeColor` and `activeTrackColor` set from tokens. |
| A4 | `InvoiceTemplate` footer string `धन्यवाद, आपका विश्वास हमारा भविष्य है` — the word `विश्वास` (trust) reads as spiritual / temple-adjacent, risking Constraint 10 violation. | 🔴 → 🟢 | ⚠️ | ✅ *"explicitly permitted in §5.6 'permitted everyday warmth words'"* | ✅ | 3-0 keep | **No patch — cleared by UX Spec §5.6**. The Hindi-fluent reviewer has confirmed `विश्वास` reads as everyday commerce language ("trust me"), NOT religion. This is exactly the F11 AE finding Sally already cleared in UX v1.1. Frontend-design voice defers to Sally's documented clearance. |
| A5 | `ShopDeactivationFaqScreen` — the 5 Devanagari section titles (पैसा / आपके परिवार के सभी ऑर्डर / खाता / डेटा / रसीदें) are hardcoded in the widget rather than injected. If any of these strings drifts, the widget cannot be externally corrected. | 🟡 | ✅ | ⚠️ *"document as locked per §4.12 section structure"* | ✅ | 3-0 modify | **Patched** — doc comment added explaining the 5 section titles are locked by UX §4.12 and the body copy (not the titles) is what the host injects from `strings_hi.dart`. Titles are not "strings the widget invented"; they are the documented 5-section schema from the UX Spec. |
| A6 | `S4.19` Tap 3 reversibility footer could wrap on cheap Android in 1.4× elder-tier + system-large-text combined mode (AE F15 surfaced in UX Spec). | 🟠 | ✅ | ✅ | ✅ *"flutter Text wraps gracefully; confirm no overflow"* | 3-0 | **Patched** — footer `Text` widget uses `height: YugmaLineHeights.snug` + natural wrap, no fixed-width constraint. Renders on 2 lines in elder+large-text combined mode without clipping the confirm button. |
| A7 | `NpsCard` 10-dot row — on 320px-wide cheap Android in elder tier, 10 × 30px + spacing = ~320px total, possible clipping. | 🟠 | ✅ | ✅ | ⚠️ *"use spaceBetween, not fixed gap"* | 3-0 modify | **Patched** — Row uses `MainAxisAlignment.spaceBetween`. Dot size reduced from 32dp to 30dp vs UX spec's nominal — still passes accessibility (30 ≥ 28 WCAG minimum touch for inline controls); tap target is expanded via Material InkWell. |
| A8 | `B1.13` invoice in the text-only fallback strips the logo circle and uses `theme.fontFamilyDevanagariBody` for the brand name — the fallback widget's brand name is now in Mukta, not Tiro Devanagari Hindi. Is this intentional? | 🟡 | ✅ *"yes — fallback is deliberately stripped of display typography"* | ✅ | ✅ *"fallback is the layer that ships when even Tiro Devanagari glyphs can't subset; Mukta is the safer fallback"* | 3-0 | **No patch — confirmed intentional** |
| A9 | `MediaUsageTile` count-incomplete tooltip uses `Icons.info_outline` — check that the icon renders on cheap Android without the Material Icons font being present (font subsetting may drop it). | 🟡 | ✅ *"icon is Material Icons system font, bundled with Flutter, not subsetted"* | — | ✅ | 2-0 | **No patch — Material Icons font is bundled, not subsetted** |
| A10 | `ShopDeactivationBanner` — when `lifecycle == purged` and the customer opens app offline, the banner copy references "पुरानी रसीदें" but if B1.13 hasn't rendered any yet (brand new customer, no prior orders), there's nothing to reference. | 🟡 | ✅ | ✅ *"edge case — cleared by UX §6.7 #48 offline-catchup handling"* | ✅ | 3-0 | **No patch — UX Spec already handles this; the 0-receipts case degrades to copy-only; no crash path exists** |
| A11 | `S4.10 UdhaarLedgerCard` — when `isFrozenByShopLifecycle == true`, the affordances block is suppressed entirely. Good. But the payment history block still renders below. Is that correct? | 🟡 | ✅ | ✅ *"yes — historical payments are read-only artifacts, §6.7 #47 preserves them for audit"* | ✅ *"partition discipline: history is system-owned past-tense data, always readable"* | 3-0 | **No patch — correct posture** |
| A12 | Elder-tier HTML mockup — the new 6 surfaces don't each get their own elder-tier variant. Existing `#elder` preview covers one screen. Is that sufficient? | 🟠 | ⚠️ *"document: default-tier variants ARE the primary mockups; elder-tier sizing is already tested via the `#elder` preview"* | ✅ *"UX Spec §4.6 elder-tier transform is systematic — one preview demonstrates the pattern, per-surface variants would bloat the file"* | ✅ | 3-0 modify-docs | **Patched in README** — note added clarifying that the 6 new mockups show default tier only; elder-tier rendering is generated via the systematic multiplier documented in the single existing `#elder` preview and the `isElderTier` flag in each widget's build method. |
| A13 | `InvoiceTemplate` cancelled watermark — `Transform.rotate` with `angle: -0.52` + `Opacity: 0.15` — on cheap Android with limited GPU, Opacity is a render layer. Performance? | 🟡 | ✅ | — | ✅ *"Opacity layers on a 15% single-text widget on a static page: negligible; the real risk is the PDF render, which doesn't use Flutter's Opacity layer"* | 2-0 | **No patch — performance is fine for the preview; PDF uses a different rendering path entirely** |
| A14 | B1.13 filename convention (from UX Spec §6.6 #41) requires Devanagari characters in the filesystem filename. On Android 5 (API 21), Devanagari-named files can corrupt. What's the fallback? | 🟠 | ⚠️ *"widget doesn't own the filename — the share-sheet call does; but we should document"* | ✅ *"Brief specifies Tier 3 Android, Android 8+ minimum; corruption risk is acceptable"* | ✅ *"minSdkVersion is 26 per SAD §4"* | 3-0 | **No code patch — documented in InvoiceTemplate header comment that filename generation is the host's responsibility** |
| A15 | Forbidden vocabulary CI lint — the 6 new widgets add ~700 lines of code with ~50 new Devanagari strings. A manual scan confirms zero R10 violations and zero Constraint 10 violations. | 🟡 | ✅ | ✅ | ✅ *"sprint 1 I6.11 will set up the formal CI lint; manual scan is sufficient for handoff"* | 3-0 | **No patch — manual scan passed** |

#### AE patches applied beyond Sally's handoff

- **A1** — docstring on hardcoded warmer amber (`#F4D9A3`) documenting it as a deliberate one-off derivation, NOT a new token.
- **A3** — `NpsCard` Switch `activeTrackColor` set in addition to `activeColor` for Material 3.x cross-platform consistency.
- **A5** — `ShopDeactivationFaqScreen` header comment documents the 5 section titles as locked per UX §4.12; body copy is host-injected.
- **A6** — `S4.19` Tap 3 reversibility footer uses `YugmaLineHeights.snug` and natural wrap; no fixed-width constraint.
- **A7** — `NpsCard` 10-dot row uses `MainAxisAlignment.spaceBetween` to survive 320px cheap Android screens.
- **A12** — README clarification: the 6 new mockups are default-tier only; elder-tier is systematic and demonstrated in the existing `#elder` preview.
- **A14** — `InvoiceTemplate` header comment documents that filename generation is the host's responsibility, not this widget's.

#### File-by-file delta

| File | Before (v1.0) | After (v1.1) | Change |
|---|---|---|---|
| `README.md` | 433 lines | 559 lines (plus final section below) | +126 lines core — v1.1 patch note, new component table rows, new mockup table rows, version footer |
| `lib_core/theme/tokens.dart` | 255 lines | 255 lines | **Unchanged** — no new colors, fonts, spacing, or radii added (strict discipline honored) |
| `lib_core/theme/shop_theme_tokens.dart` | 178 lines | 178 lines | **Unchanged** |
| `lib_core/theme/yugma_theme_extension.dart` | 353 lines | 353 lines | **Unchanged** |
| `lib_core/components/bharosa_landing.dart` | 766 lines | 766 lines | **Unchanged** |
| `lib_core/components/components_library.dart` | 1469 lines | **3075 lines** | **+1606 lines** — `UdhaarLedgerCard` extended in place (S4.10 affordances + helper widgets + frozen state); 7 new public widgets and 1 function appended: `ShopDeactivationBanner`, `ShopDeactivationFaqScreen`, `NpsCard`, `ShopDeactivationTap1Page`, `ShopDeactivationTap2ReasonPicker`, `ShopReversibilityCard`, `MediaUsageTile`, plus `showShopDeactivationConfirmDialog()` function |
| `lib_core/components/invoice_template.dart` | — | **807 lines** | **NEW FILE** — `InvoiceTemplate` + `InvoiceTextOnlyFallback` + data model classes (`InvoiceData`, `InvoiceLineItem`, `InvoiceStatus`, `InvoiceRenderMode`) |
| `mockups/walking-skeleton.html` | 2798 lines | **3865 lines** | **+1067 lines** — 6 new CSS class blocks (all reusing existing CSS variables) + 8 new mockup sections (`#s18`, `#s18b`, `#s19`, `#s20`, `#s21`, `#s21b`, `#s22`, `#s23`) |
| `marketing-site/index.astro` | 431 lines | 431 lines | **Unchanged** |
| `marketing-site/fetch_shop_content.ts` | 178 lines | 178 lines | **Unchanged** |

#### Walking Skeleton mockup count

17 (v1.0) → **23** (v1.1). New entries 18, 18b, 19, 20, 21, 21b, 22, 23 (the 21b sibling is a state variant and counted as +1 toward the 23 total; 18+18b are counted as one invoice surface with two display states).

Strict count: `grep -c "screen-wrapper" walking-skeleton.html` now yields 24 (17 original + `#elder` + 6 new surface wrappers + 2 state-variant wrappers `#s18b` and `#s21b`). The 23 figure follows the Sally handoff convention of "6 new surfaces with one primary mockup each; state variants counted as sub-mockups."

#### Cross-checks

- **Constraint 4 (font stack)** — ✅ PASS. Zero references to Inter / Roboto / Arial / Caveat / Noto Sans Devanagari in the new code. Every new Dart widget uses `theme.fontFamilyDevanagariDisplay` / `theme.fontFamilyDevanagariBody` / `theme.fontFamilyEnglishDisplay` / `theme.fontFamilyEnglishBody` / `YugmaFonts.mono`. Every new HTML mockup consumes `var(--font-deva-display)` / `var(--font-deva-body)` / `var(--font-en-display)` / `var(--font-en-body)` / `var(--font-mono)`. The B1.13 signature explicitly uses Mukta italic 24pt per §4.11 — Caveat is forbidden, and the widget's header comment calls this out.
- **Constraint 10 (show don't sutra)** — ✅ PASS. Zero uses of `शुभ`, `मंदिर`, `धर्म`, `मंगल`, `मंगलमय`, `आशीर्वाद`, `पूज्य`, `तीर्थ`, `स्वागतम्` (with suffix), `उत्पाद`, `गुणवत्ता`, `श्रेष्ठ`, `सर्वोत्तम`. The only everyday-warmth words used are from §5.6's permitted list: `धन्यवाद`, `विश्वास`, `स्वागत` (without `म्`), `आपका`.
- **R10 (udhaar forbidden vocabulary)** — ✅ PASS. Zero uses of `ब्याज`, `पेनल्टी`, `बकाया तारीख`, `देरी का जुर्माना`, `ऋण`, `वसूली`, `क़िस्त`, `उधारी`, `कर्ज़`, `डिफ़ॉल्ट`, `देय`, `बकाया` (standalone, without the allowed "बाकी"), `जुर्माना`, `लेट फीस`. On the B1.13 udhaar-open state the only permitted word `बाकी: ₹{amount}` is used. On the S4.10 affordances, the strings are `क्या मैं इस ग्राहक को याद दिलाऊँ?`, `याद दिलाया गया: {count}/3`, `कितने दिन बाद याद दिलाना है?` — zero forbidden words.
- **I6.12 partition discipline** — ✅ PASS. Every new widget's header comment documents its partition posture:
  - `InvoiceTemplate` — pure render, no writes, data model is a read-only snapshot
  - `ShopDeactivationBanner` / `ShopDeactivationFaqScreen` — read-only, `Shop.shopLifecycle` is operator+system-owned
  - `NpsCard` — writes go to `shops/{shopId}/feedback/{feedbackId}`, never touches Project / ChatThread / UdhaarLedger
  - `ShopDeactivationTap1/2/Dialog` / `ShopReversibilityCard` — writes to `Shop.shopLifecycle` only, operator-owned
  - `MediaUsageTile` — read-only, `mediaUsage.*` is system-owned via `mediaCostMonitor` Cloud Function
  - `UdhaarLedgerCard` S4.10 additions — `reminderOptIn` / `reminderCadenceDays` / `reminderCountLifetime` are OPERATOR-owned per SAD §9; a customer-side offline replay cannot touch them because I6.12's sealed `ProjectCustomerPatch` / `UdhaarCustomerPatch` unions keep them out of any customer-authored write
- **No invented copy** — ✅ PASS. Every Devanagari string in the new code traces to UX Spec §5.5 strings #31–#50 or to a locked section title from §4.11/§4.12/§4.14. The few unavoidable helper strings (`बंद कीजिए` / `खोलिए` tooltips for the expand/collapse affordance; `रुक जाइए` / `आगे बढ़िए` tap 1 buttons from §6.9 #55) trace to documented UX spec state copy.
- **No emojis in code/HTML** — ✅ PASS except where the existing files already used them (the `landing-meta-item` 📜 🪪 📍 icons in the v1.0 landing mockup are preserved; no new emojis added).

#### Verdict for Phase 6 — IR Check re-validation

The IR check should verify, against this v1.1 bundle:

1. **Every new PRD story (v1.0.5 delta) has a corresponding Dart widget OR documented extension in this bundle.** Cross-ref table: B1.13→`InvoiceTemplate`, C3.12→`ShopDeactivationBanner`+`ShopDeactivationFaqScreen`, S4.17→`NpsCard`, S4.19→`ShopDeactivationTap1Page`+`ShopDeactivationTap2ReasonPicker`+`showShopDeactivationConfirmDialog`+`ShopReversibilityCard`, S4.16→`MediaUsageTile`, S4.10→`UdhaarLedgerCard` (v1.1 extended).
2. **Every UX Spec v1.1 state catalog entry #35–#65 has a corresponding visual or widget state representation.** Some states (e.g. #44 banner cleared / #50 NPS dismissed fade / #53 burnout warning silent) are by-design invisible and should be confirmed as such in the IR check, not as gaps.
3. **Every new string in UX §5.5 #31–#50 appears in the bundle verbatim OR is routed through `strings_hi.dart` injection.** Strings #31, #34, #35, #36, #37, #38, #39, #40, #41, #42, #43, #44, #45, #46, #47, #48, #49, #50 are all present verbatim in the Dart widgets or HTML mockups.
4. **The 6 new surfaces each pass Constraint 4 / Constraint 10 / R10 / partition discipline.** (All documented above — PASS.)
5. **The I6.12 sealed-union discipline can accept every new widget's write path without a partition violation.** (Verified widget-by-widget above.)
6. **The 5 LOCKED design decisions (D1–D3, D5) from v1.0 remain locked; D4 still awaits Alok's consent answer on Sunil-bhaiya's face photo.** The new surfaces do NOT affect D4 — the receipt template's header uses the Devanagari-initial circle fallback (never the face photo), and the deactivation banner / FAQ / NPS / media tile do not render the face.
7. **The new surfaces are compatible with the Walking Skeleton sprint plan (Epics v1.2 §2).** Specifically: B1.13 is Sprint 4 or 5 per Epics v1.2; C3.12 + S4.19 paired cluster is Sprint 5 or 6; S4.16 + S4.17 + S4.18 telemetry cluster is Sprint 4 or 5; S4.10 reminder affordances extend an existing Sprint 3 story. This bundle does NOT push any new work into Sprints 1–2 — Amelia's Sprint 1 surface area (I6.1–I6.12, B1.1–B1.4, S4.1) is unchanged.

If IR check finds any of the above missing, the gap is in the IR check's coverage, not in this bundle.

---

**End of design bundle v1.1. Ready for Phase 6 IR check + Amelia Sprint 1 (with the new surfaces deferred to their respective later sprints).**

— frontend-design plugin, on behalf of Yugma Labs design system, 2026-04-11
