# Shop provisioning runbook

> End-to-end checklist for onboarding a new tenant onto the Yugma Dukaan platform. Follow in order — every step depends on the previous one completing cleanly.

---

## Pre-flight: Gate of No Return

Before provisioning any shop beyond Sunil Trading Company, confirm every box is checked. If even one is unchecked, stop and fix it first.

```
[ ] §15.1 P0 backlog closed on code side (commit 14e63da or later)
[ ] JOIN_TOKEN_HMAC_SECRET set in Firebase Secret Manager (all 3 envs)
[ ] App Check enforced for Firestore + Storage in Firebase Console
[ ] GitHub branch protection: Codex review gate required on main
[ ] DPDP grace period ratified (30 days canonical in codebase)
[ ] provisionNewShop CF deployed to yugma-dukaan-staging
[ ] cross_tenant_integrity.test.ts green (83+ tests)
[ ] Flutter CI + Cross-tenant CI both green on latest commit
```

---

## Step 1 — Decide the shop slug

The slug is permanent. It becomes the subdomain, the Firestore document ID, and the shopId in every token claim.

Rules:
- Lowercase alphanumeric + hyphens only: `/^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$/`
- No underscores (DNS-illegal)
- Max 63 characters
- Chosen with the shopkeeper — it appears in their URL

Example: `sunil-trading-company`, `ravi-almirahs-ayodhya`

---

## Step 2 — Run provisionNewShop CF

In Firebase Console → Functions → provisionNewShop → Test function, OR via the Admin SDK directly:

```typescript
const { data } = await functions.httpsCallable('provisionNewShop')({
  slug: '<chosen-slug>',
  brandName: 'Shop English Name',
  brandNameDevanagari: 'दुकान का नाम',
  ownerUid: '<firebase-auth-uid-of-bhaiya>',
  ownerEmail: 'bhaiya@example.com',
  whatsappNumberE164: '+919876543210',  // optional
  upiVpa: 'bhaiya@okaxis',              // optional
});
```

The caller must have `yugmaAdmin: true` in their Firebase Auth custom claims. Set this manually for the Yugma Labs team member running the provisioning.

**Verify in Firestore Console after success:**
- `/shops/{slug}` doc exists with `shopLifecycle: 'active'`
- `/shops/{slug}/theme/current` doc exists
- `/shops/{slug}/operators/{ownerUid}` doc exists with `role: 'bhaiya'`
- Auth user's custom claims show `{ shopId: slug, role: 'bhaiya' }`
- `/system/shop_provisioning_log/{slug}/{timestamp}` audit entry written

If the function returns `{ exists: true }`, the shop was already provisioned. Verify state in Firestore and proceed to Step 3.

---

## Step 3 — Update firebase.json + .firebaserc

Add the new shop's hosting target (see `docs/runbook/dns_subdomain_provisioning.md` for full DNS setup). Short version:

**firebase.json** — add a new entry to the `hosting` array:
```json
{
  "target": "marketing-{slug}",
  "public": "apps/marketing_site/dist",
  "headers": [/* same as existing entries */],
  "ignore": [/* same as existing entries */]
}
```

**.firebaserc** — add to each environment's `targets.hosting`:
```json
"marketing-{slug}": ["{firebase-project-id}"]
```

Commit these changes. CI will validate on the next PR.

---

## Step 4 — DNS + Firebase Hosting custom domain

Follow `docs/runbook/dns_subdomain_provisioning.md` in full. Expected timeline:
- TXT record verification: immediate to 1 hour
- SSL provisioning: up to 24 hours

The shop's marketing site is NOT live until the SSL certificate is issued. Schedule the launch at least 24 hours after this step.

---

## Step 5 — Trigger first marketing site build

Set the `SITE_URL` environment variable to `https://{slug}.yugmalabs.ai` and trigger a workflow dispatch:

```bash
gh workflow run marketing-ci.yml \
  --repo aloktiwarigit/sunil_trading_comp \
  -f shop_id={slug}
```

Verify the build succeeds and the site is reachable at `https://{slug}.yugmalabs.ai`.

---

## Step 6 — Operator first-login smoke test

1. Bhaiya installs the shopkeeper_app on their device.
2. Bhaiya signs in with the Google account matching `ownerEmail`.
3. Verify: dashboard loads, `opsDashboardTitle` renders in Hindi, inventory is empty (expected).
4. Verify: Firestore `operators/{uid}.role` reads as `bhaiya` and the shopkeeper_app shows the correct role gate.
5. Verify: one test inventory SKU creation succeeds.

---

## Step 7 — Customer deep-link smoke test

1. Visit `https://{slug}.yugmalabs.ai` from an Android device.
2. Tap "Open in App" CTA.
3. Verify: customer_app opens bound to `{slug}` (check SharedPreferences or logs).
4. Verify: BharosaLanding renders with the new shop's theme (might still be default until bhaiya customizes).
5. Verify cross-tenant integrity: the customer CANNOT access Sunil Trading Company's data.

---

## Post-provisioning checklist

```
[ ] Firestore docs created (shop, theme, operators)
[ ] Custom claims set on bhaiya's account
[ ] DNS verified + SSL issued
[ ] Marketing site deployed to {slug}.yugmalabs.ai
[ ] App Links verified (tap test from Android browser)
[ ] Bhaiya can sign in and create inventory
[ ] Customer deep-link binds to correct shop
[ ] Cross-tenant integrity test still passes in CI
[ ] Cost attribution showing $0 for new shop (no uploads yet)
[ ] Audit log entry visible in /system/shop_provisioning_log/{slug}/
```

---

## See also

- `docs/runbook/dns_subdomain_provisioning.md` — full DNS + TLS steps
- `docs/runbook/kill_switch_response.md` — if spend unexpectedly spikes post-launch
- `docs/runbook/per_shop_cost_anomaly_response.md` — cost monitoring
- `shiny-swimming-kitten.md` WS9 — the full shop #2 pilot plan
