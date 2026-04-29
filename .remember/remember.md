# Handoff

## State
Phase 0 P0 backlog done + WS5.1+WS5.2 done. Main is at `80aea8e`. Repo is public-safe (audit confirmed). chatThreads + decision_circles reads are now tenant-scoped in firestore.rules (46/46 TS rules + 21/21 Dart cross-tenant tests green). Two plans: `modular-shimmying-deer.md` (Phase 0 status) and `shiny-swimming-kitten.md` (authoritative WS1–WS9 roadmap).

## Next
1. **WS5.3** — scope `/system/*` reads per-shop (bhaiya of shop_A reads shop_B audit today). See shiny-swimming-kitten.md WS5.3 (~1.5-2d). Trickier than WS5.1+WS5.2 — needs IS-yugma-admin gate.
2. **WS1** — customer-app tenant resolver (5-8 days): `app_links` + boot shopId resolution + AndroidManifest intent-filter + assetlinks.json. See shiny-swimming-kitten.md WS1.
3. **4 ops steps still pending**: Blaze upgrade → `firebase functions:secrets:set JOIN_TOKEN_HMAC_SECRET`; Firebase Console App Check; GitHub Pro for branch protection; ratify DPDP grace 30d.

## Context
- Repo is at `aloktiwarigit/sunil_trading_comp` — public-safe per 3-agent audit.
- Keystore password `yugmadukaan2024` is LOCAL only (gitignored), but should be rotated before first Play Store upload.
- `CLAUDE.md` still untracked — commit if you want project memory in public repo.
- shiny-swimming-kitten.md WS5 items 5.1+5.2 closed; 5.3–5.9 still open and blocking shop #2.
