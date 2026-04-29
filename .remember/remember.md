# Handoff

## State
CI green on commit `99baec0` (WS5.6 format fix). Flutter CI ✅ + Cross-tenant ✅. WS5.1-5.6 complete. Two plans: `modular-shimmying-deer.md` (state snapshot) and `shiny-swimming-kitten.md` (authoritative WS1–WS9 roadmap).

## Next
1. **WS5.7** — shopkeeper_app theme from Firestore (currently hardcoded default). See shiny-swimming-kitten.md WS5.7. Mirror customer_app onboarding controller. ~1d.
2. **WS5.8** — seed_synthetic_shop_0.ts role: 'shopkeeper' → 'bhaiya' correction. ~0.25d. Bundled with WS5.9.
3. **WS5.9** — path mismatches (theme/current vs themeTokens/active, curated_shortlists vs curatedShortlists, etc.). ~1-1.5d.

## Context
- Repo: https://github.com/aloktiwarigit/sunil_trading_comp (public, CI green)
- CI non-blocking failures: marketing-ci + cloud-functions-ci (GitHub workflow ID corruption, benign); deploy-staging (needs SA key).
- shopkeeper_app APK smoke-build disabled (record_linux upstream bug).
- Gate of No Return: WS5.1-5.6 ✅, WS5.7-5.9 ❌, WS1 ❌, WS4 ❌.
- WS5.6 fix: AuthProvider interface now has getTokenClaims(); all 3 stub providers delegate to firebase; auth_controller reads role from token claims with beta fallback.
