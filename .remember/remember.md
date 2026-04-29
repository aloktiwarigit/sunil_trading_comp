# Handoff

## State
CI green on commit `94c7d8d` (WS5.4). Cross-tenant integrity 50/50. WS5.1-5.4 complete. Two plans: `modular-shimmying-deer.md` (state snapshot) and `shiny-swimming-kitten.md` (authoritative WS1–WS9 roadmap).

## Next
1. **WS5.5** — expand `cross_tenant_integrity.test.ts` to cover all 12 subcollections + N tenants (currently 4 of 12 private + 2 shops). See shiny-swimming-kitten.md WS5.5. ~2-2.5d. Blockers shop #2.
2. **WS5.6** — shopkeeper_app reads `role` from token claims (not Firestore Operator doc). See WS5.6. ~1-1.5d.
3. **WS1** — customer-app tenant resolver (5-8d): app_links + boot shopId from deep link + AndroidManifest.

## Context
- Repo: https://github.com/aloktiwarigit/sunil_trading_comp (public, CI green)
- CI non-blocking known failures: `marketing-ci.yml` + `cloud-functions-ci.yml` (GitHub ID corruption, benign); `deploy-staging` (needs FIREBASE_STAGING_SA_KEY secret).
- shopkeeper_app APK smoke-build disabled (record_linux upstream bug).
- 4 ops steps still needed: JOIN_TOKEN_HMAC_SECRET, App Check Console toggle, GitHub branch protection, DPDP grace ratification.
- Gate of No Return: WS5.1-5.4 ✅, WS5.5-5.9 ❌, WS1 ❌, WS4 ❌, WS6 ❌, WS8 ❌.
