# DNS Subdomain Provisioning Runbook

> Adds a new shop subdomain `{slug}.yugmalabs.ai` via Firebase Hosting custom domain.

## When to use

Run this runbook when onboarding a new shop that needs its own marketing site at
`{slug}.yugmalabs.ai`. For shop #1 (Sunil Trading Company) this has already been
completed.

---

## Step-by-step: provision `{slug}.yugmalabs.ai`

### Step 1 — Add hosting config to firebase.json and .firebaserc

In `firebase.json`, add a new entry to the `hosting` array:

```json
{
  "target": "marketing-{slug}",
  "public": "apps/marketing_site/dist",
  "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
  "headers": [
    {
      "source": "**/*.@(woff2|woff)",
      "headers": [{"key": "Cache-Control", "value": "public,max-age=31536000,immutable"}]
    },
    {
      "source": "**/*.@(jpg|jpeg|png|gif|webp|avif|svg)",
      "headers": [{"key": "Cache-Control", "value": "public,max-age=2592000"}]
    }
  ]
}
```

In `.firebaserc`, add the target binding under each environment alias:

```json
"targets": {
  "yugma-dukaan-dev": {
    "hosting": {
      "marketing-{slug}": ["yugma-dukaan-dev"],
      "marketing-sunil-trading-company": ["yugma-dukaan-dev"]
    }
  },
  "yugma-dukaan-staging": {
    "hosting": {
      "marketing-{slug}": ["yugma-dukaan-staging"],
      "marketing-sunil-trading-company": ["yugma-dukaan-staging"]
    }
  },
  "yugma-dukaan-prod": {
    "hosting": {
      "marketing-{slug}": ["yugma-dukaan-prod"],
      "marketing-sunil-trading-company": ["yugma-dukaan-prod"]
    }
  }
}
```

Commit and merge these changes to `main` before proceeding.

---

### Step 2 — Add the custom domain in Firebase Console

1. Go to **Firebase Console → Hosting** for the target project (`yugma-dukaan-prod`).
2. Click **Add custom domain**.
3. Enter `{slug}.yugmalabs.ai`.
4. Firebase shows a TXT record to verify domain ownership. Add this TXT record at
   your DNS provider (currently: wherever `yugmalabs.ai` is managed).
5. Wait for verification — typically 5–30 minutes. Firebase polls automatically.
6. Once verified, Firebase provisions an SSL certificate via Let's Encrypt.
   **SSL provisioning takes up to 24 hours.** During this window the subdomain
   returns a certificate error — this is expected.

---

### Step 3 — Add the DNS A/CNAME records

After Firebase shows the required IP addresses (two A records for IPv4) or a CNAME:

| Record type | Host | Value |
|---|---|---|
| `A` | `{slug}.yugmalabs.ai` | Firebase-provided IP #1 |
| `A` | `{slug}.yugmalabs.ai` | Firebase-provided IP #2 |

Add both records at the DNS provider. TTL of 300 (5 min) during initial rollout,
then raise to 3600 once SSL is confirmed green.

SSL fully provisioned when Firebase Console shows **"Connected"** status (green).

---

## Set SITE_URL for the Astro build

The Astro config reads `SITE_URL` at build time to set the canonical URL. For the
new shop, set the GitHub Actions secret or environment variable:

```
SITE_URL=https://{slug}.yugmalabs.ai
```

In `apps/marketing_site/astro.config.mjs` the value is consumed as:

```js
site: process.env.SITE_URL ?? 'https://sunil-trading-company.yugmalabs.ai',
```

Add the new shop's `SITE_URL` as a GitHub Actions environment variable or repository
secret named `SITE_URL_{SLUG_UPPER}` and thread it through the CI workflow.

---

## Checklist

- [ ] `firebase.json` — new `marketing-{slug}` target added
- [ ] `.firebaserc` — binding added for dev / staging / prod
- [ ] Changes committed and merged to `main`
- [ ] Firebase Console → Hosting → custom domain → TXT record added at DNS
- [ ] TXT record verified by Firebase (green)
- [ ] A records added at DNS
- [ ] SSL certificate provisioned (Firebase Console shows "Connected") — up to 24h
- [ ] `SITE_URL` env var set for CI builds
- [ ] Smoke-test: `curl -I https://{slug}.yugmalabs.ai` returns HTTP 200
