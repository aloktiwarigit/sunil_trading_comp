# Handoff

## State
CI green on commit `61cc21d` (WS2). Flutter CI ✅ + Cross-tenant ✅. WS1 + WS2 + WS5.1-5.9 complete. Two plans: `modular-shimmying-deer.md` and `shiny-swimming-kitten.md`.

## Next
1. **WS3** — per-shop hosting + DNS (~2-3d): firebase.json multi-target, .firebaserc per-shop bindings, ci-marketing.yml derives target from shop_id input. See shiny-swimming-kitten WS3.
2. **WS4** — provisionNewShop CF (4-6d): bhaiya-only HTTPS callable, creates shop doc + theme + operator + custom claims. See shiny-swimming-kitten WS4.

## Context
- Repo: https://github.com/aloktiwarigit/sunil_trading_comp (public, CI green)
- CI non-blocking failures: marketing-ci + cloud-functions-ci (0s, GitHub workflow ID corruption, April 11); Deploy-staging (43s, needs FIREBASE_STAGING_SA_KEY secret — ops step).
- Gate of No Return: WS5.1-5.9 ✅, WS1 ✅, WS2 ✅, WS3 ❌, WS4 ❌.
