# Handoff

## State
CI green on commit `c1f538b` (WS1 format fix). Flutter CI ✅ + Cross-tenant ✅. WS5.1-5.9 + WS1 complete. Two plans: `modular-shimmying-deer.md` (state snapshot) and `shiny-swimming-kitten.md` (authoritative WS1–WS9 roadmap).

## Next
1. **WS2** — marketing site full parameterization (~3-4d): astro.config.mjs site: from env, visit.astro fetches shop content, BaseLayout description from props, assetlinks.json Astro endpoint. See shiny-swimming-kitten WS2.
2. **WS3** — per-shop hosting + DNS (~2-3d): firebase.json multi-target, .firebaserc per-shop bindings, ci-marketing.yml derives target from shop_id. See shiny-swimming-kitten WS3.
3. **WS4** — provisionNewShop CF (4-6d): bhaiya-only HTTPS callable, creates shop doc + theme + operator + custom claims. See shiny-swimming-kitten WS4.

## Context
- Repo: https://github.com/aloktiwarigit/sunil_trading_comp (public, CI green)
- CI note: marketing-ci + cloud-functions-ci 0s "failure" = GitHub workflow ID corruption from April 11, benign.
- WS1 shipped: TenantResolver in lib_core, deep-link boot in main.dart, AndroidManifest, splash tenant-neutral, router redirect, 344/344 tests.
- Gate of No Return: WS5.1-5.9 ✅, WS1 ✅, WS2 ❌, WS3 ❌, WS4 ❌.
