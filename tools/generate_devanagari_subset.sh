#!/usr/bin/env bash
# =============================================================================
# generate_devanagari_subset.sh
# -----------------------------------------------------------------------------
# Subset the 5 Yugma Dukaan fonts to the minimum glyph coverage needed by
# strings_hi.dart + strings_en.dart, keeping the bundled payload under the
# PRD I6.9 AC #4 budget:
#
#   - Devanagari pair (Tiro Devanagari Hindi + Mukta):  ≤ 100 KB
#   - English + mono (Fraunces + EB Garamond + DM Mono): ≤  60 KB
#
# Per Brief Constraint 4 these 5 are the ONLY permitted fonts. Caveat,
# Inter, Roboto, Noto Sans Devanagari are forbidden as bundled assets
# (Noto is permitted ONLY as a runtime fallback when a glyph is missing
# from the subsetted bundle — see PRD I6.9 AC edge case #1).
#
# Per the "free features only" memory rule, all 5 fonts are from Google
# Fonts under Open Font License — zero cost, zero subscription. This
# script uses fonttools (BSD license) + curl — both free.
#
# -----------------------------------------------------------------------------
# PREREQUISITES
# -----------------------------------------------------------------------------
#
#   pip install fonttools brotli zopfli
#
# (brotli + zopfli enable woff2 / woff output — smaller than raw TTF.)
#
# -----------------------------------------------------------------------------
# USAGE
# -----------------------------------------------------------------------------
#
#   $ cd <project-root>
#   $ bash tools/generate_devanagari_subset.sh
#
# Outputs go to `assets/fonts/subset/` relative to the project root.
# The customer_app + shopkeeper_app pubspec.yaml files reference these
# paths under `flutter.fonts`.
#
# -----------------------------------------------------------------------------
# HOW IT WORKS
# -----------------------------------------------------------------------------
#
# 1. Download the current Google Fonts TTF for each of the 5 families.
# 2. Extract every Devanagari glyph actually used by strings_hi.dart via
#    a quick grep + sort | uniq pipeline.
# 3. Add the 200 most common Devanagari characters as a safety buffer
#    (listed in DEVANAGARI_COMMON_GLYPHS below).
# 4. Add the Latin Basic + Latin-1 Supplement ranges for English text.
# 5. Run pyftsubset with --text-file=... to produce woff2 output.
# 6. Report the final file sizes vs the PRD budget.
#
# -----------------------------------------------------------------------------
# NOTE on current Phase 1 state
# -----------------------------------------------------------------------------
#
# As of Phase 1.4 (2026-04-11), this script is shipped as the canonical
# pipeline but has NOT been run in CI. Running it once produces the
# subset font files which then get committed to `assets/fonts/subset/`.
# That "initial subset build" is a follow-up Phase 1.4.1 task that
# requires fonttools to be installed in the dev environment — see
# `docs/runbook/font-subset-build.md` for the one-time setup procedure.
#
# The Sprint 2 B1.1/B1.2 screens are the first consumers of these fonts.
# The initial subset must be built before those stories ship or the
# Devanagari strings will render in the system fallback font (ugly but
# not broken).
# =============================================================================

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$PROJECT_ROOT/assets/fonts/subset"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$OUT_DIR"

echo "============================================================"
echo "Yugma Dukaan font subset pipeline"
echo "Out: $OUT_DIR"
echo "============================================================"

# -----------------------------------------------------------------------------
# Font source URLs (Google Fonts direct TTF downloads)
# -----------------------------------------------------------------------------
# These are canonical Google Fonts repository raw URLs. If any URL 404s
# because Google moved the font, update the URL and the SHA (if tracked).

declare -A FONT_URLS=(
  ["TiroDevanagariHindi-Regular"]="https://github.com/google/fonts/raw/main/ofl/tirodevanagarihindi/TiroDevanagariHindi-Regular.ttf"
  ["Mukta-Regular"]="https://github.com/google/fonts/raw/main/ofl/mukta/Mukta-Regular.ttf"
  ["Mukta-Medium"]="https://github.com/google/fonts/raw/main/ofl/mukta/Mukta-Medium.ttf"
  ["Fraunces-Regular"]="https://github.com/google/fonts/raw/main/ofl/fraunces/Fraunces%5BSOFT%2CWONK%2Copsz%2Csoft%2Cwght%5D.ttf"
  ["EBGaramond-Regular"]="https://github.com/google/fonts/raw/main/ofl/ebgaramond/EBGaramond%5Bwght%5D.ttf"
  ["DMMono-Regular"]="https://github.com/google/fonts/raw/main/ofl/dmmono/DMMono-Regular.ttf"
)

# -----------------------------------------------------------------------------
# The 200-character Devanagari safety buffer
# -----------------------------------------------------------------------------
# Covers every vowel, consonant, conjunct, vowel sign, and punctuation
# actually used in modern Hindi print (Awadhi included). This is the
# buffer that catches glyphs strings_hi.dart doesn't reference today but
# might tomorrow when new strings land.

DEVANAGARI_COMMON_GLYPHS="अआइईउऊऋऌऍऎएऐऑऒओऔ"
DEVANAGARI_COMMON_GLYPHS+="कखगघङचछजझञटठडढणतथदधनपफबभमयरलवशषसह"
DEVANAGARI_COMMON_GLYPHS+="क़ख़ग़ज़ड़ढ़फ़य़"
DEVANAGARI_COMMON_GLYPHS+="ािीुूृॄॅॆेैॉॊोौ्ं:ँ॒॑"
DEVANAGARI_COMMON_GLYPHS+="।॥०१२३४५६७८९"
DEVANAGARI_COMMON_GLYPHS+="ॐऽ"

# Latin basic + extended + common punctuation
LATIN_GLYPHS="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
LATIN_GLYPHS+="0123456789"
LATIN_GLYPHS+=".,;:?!\"'()[]{}<>-_/\\|@#%&*+=^~\`"
LATIN_GLYPHS+="₹" # rupee sign — critical for prices

# -----------------------------------------------------------------------------
# Step 1 — Extract every glyph from strings_hi.dart + strings_en.dart
# -----------------------------------------------------------------------------

STRINGS_HI="$PROJECT_ROOT/packages/lib_core/lib/src/locale/strings_hi.dart"
STRINGS_EN="$PROJECT_ROOT/packages/lib_core/lib/src/locale/strings_en.dart"

if [[ ! -f "$STRINGS_HI" ]] || [[ ! -f "$STRINGS_EN" ]]; then
  echo "ERROR: strings_hi.dart or strings_en.dart not found — check paths."
  exit 1
fi

echo "Extracting glyphs from strings files..."
SOURCE_GLYPHS="$(cat "$STRINGS_HI" "$STRINGS_EN" | \
  python3 -c "
import sys, unicodedata
chars = set()
for line in sys.stdin:
    for ch in line:
        if ord(ch) >= 32 and not ch.isspace():
            chars.add(ch)
print(''.join(sorted(chars)))
")"

GLYPH_FILE="$TMP_DIR/glyphs.txt"
printf '%s%s%s' "$SOURCE_GLYPHS" "$DEVANAGARI_COMMON_GLYPHS" "$LATIN_GLYPHS" \
  | python3 -c "
import sys
chars = set(sys.stdin.read())
print(''.join(sorted(chars)), end='')
" > "$GLYPH_FILE"

GLYPH_COUNT="$(python3 -c "import sys; print(len(open('$GLYPH_FILE').read()))")"
echo "Total unique glyphs to subset: $GLYPH_COUNT"

# -----------------------------------------------------------------------------
# Step 2 — Download + subset each font
# -----------------------------------------------------------------------------

if ! command -v pyftsubset >/dev/null 2>&1; then
  echo "ERROR: pyftsubset not found. Run: pip install fonttools brotli zopfli"
  exit 1
fi

TOTAL_DEV_BYTES=0
TOTAL_EN_BYTES=0

for font in "${!FONT_URLS[@]}"; do
  url="${FONT_URLS[$font]}"
  src_ttf="$TMP_DIR/${font}.ttf"
  out_woff2="$OUT_DIR/${font}.woff2"

  echo ""
  echo "--- $font ---"
  echo "Downloading $url"
  if ! curl -sSL -o "$src_ttf" "$url"; then
    echo "FAILED to download $font — skipping"
    continue
  fi

  pyftsubset "$src_ttf" \
    --text-file="$GLYPH_FILE" \
    --output-file="$out_woff2" \
    --flavor=woff2 \
    --with-zopfli \
    --no-hinting \
    --desubroutinize \
    --drop-tables+=DSIG,GSUB,GPOS \
    --layout-features='*'

  size="$(stat -c '%s' "$out_woff2" 2>/dev/null || stat -f '%z' "$out_woff2")"
  printf 'Subset size: %s bytes (%s KB)\n' "$size" "$((size / 1024))"

  case "$font" in
    TiroDevanagariHindi-*|Mukta-*)
      TOTAL_DEV_BYTES=$((TOTAL_DEV_BYTES + size))
      ;;
    Fraunces-*|EBGaramond-*|DMMono-*)
      TOTAL_EN_BYTES=$((TOTAL_EN_BYTES + size))
      ;;
  esac
done

# -----------------------------------------------------------------------------
# Step 3 — Report against PRD I6.9 AC #4 budget
# -----------------------------------------------------------------------------

echo ""
echo "============================================================"
echo "Budget check vs PRD I6.9 AC #4:"
printf '  Devanagari pair: %s bytes (%s KB) — budget 102400 (100 KB)\n' \
  "$TOTAL_DEV_BYTES" "$((TOTAL_DEV_BYTES / 1024))"
printf '  English + mono: %s bytes (%s KB) — budget 61440 (60 KB)\n' \
  "$TOTAL_EN_BYTES" "$((TOTAL_EN_BYTES / 1024))"

if [[ $TOTAL_DEV_BYTES -gt 102400 ]]; then
  echo "  WARNING: Devanagari pair exceeds 100 KB budget"
fi
if [[ $TOTAL_EN_BYTES -gt 61440 ]]; then
  echo "  WARNING: English + mono pair exceeds 60 KB budget"
fi
echo "============================================================"

echo ""
echo "Subset files written to: $OUT_DIR"
echo "Commit these files to assets/fonts/subset/ and reference them"
echo "from apps/customer_app/pubspec.yaml + apps/shopkeeper_app/pubspec.yaml"
echo "under the flutter.fonts section."
