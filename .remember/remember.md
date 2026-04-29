# Handoff

## State
CI green on commit `b68952f` (WS5.9). Flutter CI ✅ + Cross-tenant ✅. WS5.1-5.9 complete. Two plans: `modular-shimmying-deer.md` (state snapshot) and `shiny-swimming-kitten.md` (authoritative WS1–WS9 roadmap).

## Next
1. **WS1** — customer-app tenant resolver (5-8d): app_links + boot shopId from deep link + AndroidManifest. The big Phase 1 item.
2. **WS4** — provisionNewShop CF (4-6d).
3. **WS0 items** — HMAC join token (0.1), App Check (0.2), DPDP grace (0.3), bilingual FCM (0.4), three runbooks (0.5), Codex gate in CI (0.6).

## Context
- Repo: https://github.com/aloktiwarigit/sunil_trading_comp (public, CI green)
- CI note: marketing-ci + cloud-functions-ci show 0s "failure" on every push — this is a GitHub workflow ID corruption from April 11 initial commit. Benign, non-blocking. Real correctness gates are Flutter CI + Cross-tenant integrity (both ✅ green).
- shopkeeper_app APK smoke-build disabled (record_linux upstream bug).
- Gate of No Return: WS5.1-5.9 ✅, WS1 ❌, WS4 ❌, WS0 ❌.
