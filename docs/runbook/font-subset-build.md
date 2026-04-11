# Font subset build — one-time setup + rebuild procedure

This runbook describes how to run `tools/generate_devanagari_subset.sh` to
produce the bundled Devanagari + English + mono font files consumed by
`apps/customer_app` and `apps/shopkeeper_app`.

## Why

Per **Brief Constraint 4** the Yugma Dukaan font stack is exactly five
families, none of them substitutable:

| Role | Family | Source |
|---|---|---|
| Devanagari display | **Tiro Devanagari Hindi** | Google Fonts (OFL) |
| Devanagari body | **Mukta** (Regular + Medium) | Google Fonts (OFL) |
| English display | **Fraunces** (italic reserved for the B1.13 invoice signature) | Google Fonts (OFL) |
| English body | **EB Garamond** | Google Fonts (OFL) |
| Numerics / timestamps / prices | **DM Mono** | Google Fonts (OFL) |

Caveat, Inter, Roboto, and Noto Sans Devanagari are **forbidden as bundled
assets** per Brief Constraint 4. Noto is permitted as a *runtime fallback*
only (when a glyph is missing from the subsetted bundle — PRD I6.9 AC
edge case #1).

Per **PRD I6.9 AC #4** the bundled payload must fit inside:

- Devanagari pair (Tiro Devanagari Hindi + Mukta): **≤ 100 KB**
- English + mono (Fraunces + EB Garamond + DM Mono): **≤ 60 KB**

Subsetting is mandatory — shipping the full TTFs would blow both budgets
by 20-50× and hurt Tier-3 3G cold-start times in ways the Brief § UX
Spec §7 specifically prohibits.

Per the **free features only** memory rule, the entire pipeline is free:
all 5 fonts are Open Font License, `fonttools` is BSD, `curl` is free.
Zero subscriptions, zero API keys.

## One-time dev environment setup

Install `fonttools` with brotli + zopfli encoders (needed for woff2 output):

```bash
pip install fonttools brotli zopfli
```

Verify:

```bash
pyftsubset --help | head -3
# Expect: "usage: fonttools subset ..."
```

## Running the subset build

From the project root:

```bash
bash tools/generate_devanagari_subset.sh
```

Output files land in `assets/fonts/subset/` as `.woff2`:

```
assets/fonts/subset/
├── TiroDevanagariHindi-Regular.woff2
├── Mukta-Regular.woff2
├── Mukta-Medium.woff2
├── Fraunces-Regular.woff2
├── EBGaramond-Regular.woff2
└── DMMono-Regular.woff2
```

The script prints a budget check at the end:

```
Budget check vs PRD I6.9 AC #4:
  Devanagari pair: 87234 bytes (85 KB) — budget 102400 (100 KB)
  English + mono: 52110 bytes (50 KB) — budget 61440 (60 KB)
```

If either pair exceeds its budget, the script prints a `WARNING` line.
Investigate which glyphs are pulling the weight via:

```bash
pyftsubset --help-options
# --text-file= is what the script uses
# Experiment with smaller coverage if the budget is breached
```

## When to rerun

Rerun the script whenever `strings_hi.dart` or `strings_en.dart` gains a
new glyph not already covered by the 200-character Devanagari safety
buffer or the Latin basic coverage. The script auto-extracts glyphs from
both strings files on every run, so the source-of-truth is always current.

**CI integration (future):** a GitHub Actions workflow `ci-fonts.yml`
will re-run this script on every PR that touches `strings_*.dart` and
fail the build if the subsetted output differs from the committed
`assets/fonts/subset/` files. That CI wire-up is deferred until the
first successful local run produces the initial subset set.

## Wiring the subset files into the Flutter apps

After the script produces the output files, register them in
`apps/customer_app/pubspec.yaml` and `apps/shopkeeper_app/pubspec.yaml`
under `flutter.fonts`:

```yaml
flutter:
  fonts:
    - family: Tiro Devanagari Hindi
      fonts:
        - asset: ../../assets/fonts/subset/TiroDevanagariHindi-Regular.woff2
    - family: Mukta
      fonts:
        - asset: ../../assets/fonts/subset/Mukta-Regular.woff2
        - asset: ../../assets/fonts/subset/Mukta-Medium.woff2
          weight: 500
    - family: Fraunces
      fonts:
        - asset: ../../assets/fonts/subset/Fraunces-Regular.woff2
    - family: EB Garamond
      fonts:
        - asset: ../../assets/fonts/subset/EBGaramond-Regular.woff2
    - family: DM Mono
      fonts:
        - asset: ../../assets/fonts/subset/DMMono-Regular.woff2
```

## Current Phase 1.4 state (2026-04-11)

- `tools/generate_devanagari_subset.sh` is the canonical pipeline script.
- `docs/runbook/font-subset-build.md` (this file) documents the setup.
- The actual `assets/fonts/subset/*.woff2` files have NOT been generated
  yet — the dev environment needs `pip install fonttools brotli zopfli`
  first, which is a deliberate per-developer decision (not an autonomous
  agent action).
- The first successful run is Phase 1.4.1 — a short follow-up where the
  dev with the installed `fonttools` runs the script once, commits the
  output files, and updates the app pubspecs. After that it's steady-state
  rerun-on-strings-change.
- No Sprint 2 B1.1/B1.2 screen can render Devanagari correctly until this
  one-time build has been done. Until then, the system fallback font
  (typically Noto Sans Devanagari on Android) is used — functional but
  visually wrong.

## Cleaning up

To remove the subset files and start over:

```bash
rm -rf assets/fonts/subset/
bash tools/generate_devanagari_subset.sh
```

The script is idempotent — rerunning produces identical output if the
source strings files haven't changed.
