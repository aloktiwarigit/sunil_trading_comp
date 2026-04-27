# Multi-tenant breach incident response runbook

> When data from one shop leaks into another shop's view, OR a client of shop A successfully writes/reads shop B's data. The cross-tenant invariant is the load-bearing security claim of the platform — a real breach is a P0.

---

## What this is

The platform's strongest single claim is per-shop isolation: every Firestore document has a `shopId` field, every read/write is gated by `shopIdMatches()` + `isShopOperator()` / `isCustomerOf()` rule helpers, and the cross-tenant integrity test (`tools/src/cross_tenant_integrity.test.ts`) runs on every PR with no path filter (ADR-012).

**A breach means one of those layers failed.** Possible failure modes:

1. **Rule layer:** a new collection was added without proper `shopId` gating, OR a helper function was misused (e.g., `isSignedIn()` where `isShopMember(shopId)` was meant).
2. **Function layer:** a Cloud Function with Admin SDK access (privileged) reads/writes the wrong shop because input validation is missing.
3. **Data layer:** a document was created without a `shopId` field, OR with the wrong `shopId`, and now appears in queries for the wrong tenant.
4. **App layer:** a `shopId` resolver bug binds the app to the wrong tenant for a real user.

---

## Trigger

| Channel | Signal |
|---|---|
| **`multiTenantAudit` weekly run** | Sun 03:00 IST writes `/system/audit_results/{date}/summary` with `flagged > 0` (`shopId_mismatch` / `shop_0_missing` / `shop_0_mutated`). |
| **CI gate failure** | `ci-cross-tenant-test.yml` fails on a PR (the gate is no-path-filter). |
| **Customer / shopkeeper report** | "I see a customer/order/almirah that isn't ours." Treat as immediate P0 until disproven. |
| **Firestore console manual review** | Operator notices anomalous data. |

Per drift §15.3.I, audit-flagged violations don't auto-page yet. Until that's wired, the operator must manually check the `system/audit_results/{date}/summary` doc weekly. **Add a calendar reminder for every Sunday at 09:00 IST.**

---

## Severity

| Tier | Condition |
|---|---|
| **P0 — drop everything** | Confirmed real-customer PII (phone, name, VPA) crossed tenant boundaries. |
| **P1 — same-day** | Audit script flagged `shopId_mismatch` on a non-PII collection (e.g., `voiceNotes` with wrong `shopId`). |
| **P2 — next-day** | Synthetic shop_0 mutation detected (someone wrote to it — synthetic must stay pristine). |
| **P3 — review** | CI test fails on a PR but the change wasn't merged. Block merge, fix the rule, no real-data risk. |

DPDP Act 2023 mandates **breach notification within 72 hours** to the Data Protection Board for any PII breach affecting data principals. P0 timer starts at the moment of confirmation.

---

## Containment (≤ 30 minutes)

### 1. Stop the active leak

Identify the breach surface:

- **Read leak:** the offending client successfully READ another shop's data. Stop further reads:
  - Firestore console → `/shops/{shopId}/featureFlags/runtime` → set `firestoreWritesBlocked: true` AND `killSwitchActive: true` for the AFFECTED shop. This freezes apps without nuking the audit trail.
  - If the read was via a Cloud Function with Admin SDK, deploy an empty version of the function to disable it: `firebase deploy --only functions:{name} --project {env}` after replacing the function body with `throw new Error('disabled pending breach review')`.

- **Write leak:** a doc with the wrong `shopId` exists. **Don't delete it yet** — it's evidence. Read the doc, screenshot/export the data, then continue diagnosis.

- **Auth leak:** a session has wrong `shopId` claim. Force token refresh: revoke the user's tokens via Firebase Auth Console → Users → find UID → Revoke refresh tokens. The next request from that user will require re-auth.

### 2. Snapshot the breach state

```bash
# Export the offending shop's data for forensic analysis.
gcloud firestore export gs://yugma-dukaan-{env}-breach-snapshots/$(date +%Y%m%d-%H%M)/ \
  --collection-ids=projects,customers,udhaarLedger,chatThreads \
  --project yugma-dukaan-{env}
```

(If the breach-snapshots GCS bucket doesn't exist yet, create it first: `gcloud storage buckets create gs://yugma-dukaan-{env}-breach-snapshots --location=asia-south1`. This is a one-time setup deferred from drift §15.2.X — Firestore backup strategy.)

### 3. Notify Alok

P0 breach: WhatsApp + phone call, not email. The 72-hour DPDP clock starts now.

---

## Diagnosis (30 min – 4 hours)

### 1. Identify scope

Run a manual cross-tenant audit query in the Firestore console:

```
collection group: projects (or customers, udhaarLedger, etc.)
where shopId == "<wrong-shop-id>"
```

Count how many docs are in the wrong shop. Then cross-reference against the actual customer doc to identify affected real customers.

### 2. Identify the failure layer

Walk the layers in order:

1. **App layer:** Check the customer_app or shopkeeper_app `shopIdProviderProvider` override. Was a deep link or session token issuing the wrong shopId? Check `Observability` for `session_restored_from_refresh_token` events with shopId in the wrong scope.
2. **Function layer:** Was a Callable invoked with a forged `shopId` input? Check function logs for the relevant call. The HMAC join token (drift §15.1.A) must be implemented to close this surface for `joinDecisionCircle`.
3. **Rule layer:** Did the rule allow the read/write? Try the same operation in the Firestore Rules Playground with the offending UID + claims. If it succeeds in the playground, the rule is the bug.
4. **Data layer:** Was the doc created without a `shopId`? Check `_create` audit (if available) — likely a Cloud Function or seed script bug.

### 3. Correlate with recent deploys

`git log --since="3 days ago" -- firestore.rules functions/ packages/lib_core/lib/src/repositories/` — any of these touched in the last few days could be the regression.

---

## Resolution

### Path A — single-doc breach (P1)

A handful of docs (≤ 10) ended up with wrong `shopId`:

1. Identify the correct `shopId` for each via the original creator (customer phone number, operator's session at creation time, etc.).
2. Update the docs in place via Firestore console: change `shopId` to the correct value, add a `breachReassignedAt` field with the timestamp.
3. Re-run the cross-tenant integrity audit script:
   ```bash
   GCLOUD_PROJECT=yugma-dukaan-{env} npx tsx tools/src/cross_tenant_integrity.test.ts
   ```
4. Document the incident in `/system/audit_results/{date}/summary.incidents`.

### Path B — large-scale leak (P0)

> 10 docs OR PII was shared across tenants:

1. Quarantine all affected docs by setting `quarantinedAt` field. Apps treat quarantined docs as deleted.
2. Notify all affected real customers by FCM + WhatsApp (Hindi + English):
   - "Aapki kuch jaankari galat shop ke saath dikh rahi thi. Hum thik kar rahe hain. 24 ghante mein aapko update milega." (Some of your information was visible to the wrong shop. We are fixing it. You'll get an update within 24 hours.)
3. File the DPDP breach notification within 72 hours. Template lives at `docs/legal/dpdp_breach_template.md` (TBD — file as a follow-up if not present).
4. After fix is deployed and tests pass for 24 hours, restore the docs to their correct tenant.
5. Schedule a customer apology + udhaar discount as goodwill (in-product, not legally required).

### Path C — synthetic shop_0 mutation (P2)

Synthetic `shop_0` was supposed to be pristine. A mutation indicates either:
- A real client successfully wrote to it (rule failure)
- The seeder script collided with itself (idempotency bug)

1. Identify the writing UID from the doc's `updatedByUid` field.
2. If a real client UID, freeze that client's session (refresh-token revoke).
3. Re-seed shop_0 from clean state: `GCLOUD_PROJECT=yugma-dukaan-{env} node tools/dist/seed_synthetic_shop_0.js`.
4. Investigate which rule allowed the write.

### Path D — CI gate caught a regression (P3)

The cross-tenant integrity test failed on a PR before merge. **No real-data impact.**

1. Block the PR merge.
2. Read the failure output — the test names (e.g., `shop_1 operator cannot read /shops/shop_0/...`) say which collection's rule regressed.
3. Patch the rule.
4. Re-run the test, get green, merge.

---

## Communication

| Audience | When | Channel | Message |
|---|---|---|---|
| **Alok** | Immediately, any tier ≥ P1 | WhatsApp + phone | "Multi-tenant breach detected on `{env}`. Tier `{P0/P1}`. `{N}` docs affected. Containment in progress." |
| **Affected real customers** | Within 24h on confirmed P0 PII leak | FCM (bilingual) + wa.me link | See "Path B" template above. |
| **Affected shopkeepers** | Within 1h on P0 | wa.me | "Bhaiya, ek security issue tha — aapka data abhi safe hai. Detail mein 1 ghante mein bata raha hoon." (There was a security issue — your data is safe now. I'll explain in detail in 1 hour.) |
| **Data Protection Board (DPDP)** | Within 72h on confirmed P0 PII leak | Email per DPDP template | Required by law. |
| **Cross-tenant integrity test maintainers** | After resolution | PR comment | What test would have caught this earlier? Add it. |

---

## Post-mortem

Within 1 week of resolution:

1. **Root cause:** which layer failed, why.
2. **Detection time:** breach occurred at T0, detected at T1. T1 - T0 should be < 24h. If longer, file a detection-improvement task.
3. **Containment time:** detection to stop-the-bleed. Should be < 30 min.
4. **Resolution time:** stop-the-bleed to all-clear. Should be < 24h on P0.
5. **Test added:** every P0 breach must result in a new cross-tenant test case.
6. **Communication audit:** were all required parties notified within their SLA?

File the post-mortem at `docs/incidents/{YYYY-MM-DD}-multi-tenant-breach.md` and link from `docs/architecture-source-of-truth.md` §15.

---

## See also

- `docs/architecture-source-of-truth.md` §9.2 (multi-tenancy isolation), ADR-012 (synthetic shop_0).
- `firestore.rules` (the rule layer being defended).
- `tools/src/cross_tenant_integrity.test.ts` (the PR-blocker test).
- `functions/src/multi_tenant_audit.ts` (the weekly audit Cloud Function).
- `docs/runbook/kill_switch_response.md` (when containment requires the kill-switch).
- DPDP Act 2023 §8(6) — breach notification within 72 hours.
