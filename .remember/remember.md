# Handoff

## State
CI green on commit `3429f4a` (WS5.7+5.8). Flutter CI ✅ + Cross-tenant ✅. WS5.1-5.8 complete. Two plans: `modular-shimmying-deer.md` (state snapshot) and `shiny-swimming-kitten.md` (authoritative WS1–WS9 roadmap).

## Next
1. **WS5.9** — path mismatches (theme/current vs themeTokens/active, curated_shortlists vs curatedShortlists, customer_memory naming, golden_hour_photos). ~1-1.5d. See shiny-swimming-kitten WS5.9.
2. **WS1** — customer-app tenant resolver (5-8d): app_links + boot shopId from deep link + AndroidManifest. The big Phase 1 item.
3. **WS4** — provisionNewShop CF (4-6d).

## Context
- Repo: https://github.com/aloktiwarigit/sunil_trading_comp (public, CI green)
- CI note: marketing-ci + cloud-functions-ci show 0s "failure" on every push — this is a GitHub workflow ID corruption from April 11 initial commit. Benign, non-blocking. Real correctness gates are Flutter CI + Cross-tenant integrity (both ✅ green).
- shopkeeper_app APK smoke-build disabled (record_linux upstream bug).
- Gate of No Return: WS5.1-5.8 ✅, WS5.9 ❌, WS1 ❌, WS4 ❌.
