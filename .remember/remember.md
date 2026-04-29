# Handoff

## State
CI green on commit `c8af389` (WS3). WS1 + WS2 + WS3 + WS5.1-5.9 complete. Two plans: `modular-shimmying-deer.md` and `shiny-swimming-kitten.md`.

## Next
1. **WS4** — provisionNewShop CF (4-6d): bhaiya-only HTTPS callable, creates shop doc + theme + operator + custom claims + triggers marketing rebuild. This is the final big blocker before shop #2. See shiny-swimming-kitten WS4.
2. **WS6** — per-tenant observability: per-shop crash attribution, cost dashboard, phone-auth quota per shop. See shiny-swimming-kitten WS6. Can run in parallel with WS4.

## Context
- Repo: https://github.com/aloktiwarigit/sunil_trading_comp (public, CI green)
- CI non-blocking failures: marketing-ci + cloud-functions-ci (0s, GitHub ID bug, April 11); Deploy-staging (needs FIREBASE_STAGING_SA_KEY secret).
- Gate of No Return: WS5.1-5.9 ✅, WS1 ✅, WS2 ✅, WS3 ✅, WS4 ❌.
- WS3 shipped: firebase.json multi-target, .firebaserc per-shop bindings, ci-marketing.yml shop_id-derived target, dns_subdomain_provisioning.md runbook.
