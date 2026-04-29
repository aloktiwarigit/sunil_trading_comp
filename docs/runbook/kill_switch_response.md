# Kill-switch incident response runbook

> When the `killSwitchOnBudgetAlert` Cloud Function flips `killSwitchActive=true` in `/shops/{shopId}/featureFlags/runtime`. Apps go read-only within ~5s. This is the **circuit breaker fired** — figure out why before resetting.

---

## What this is

Cloud Billing publishes budget threshold crossings ($0.10 / $0.50 / $1.00) to the `budget-alerts` Pub/Sub topic. The `killSwitchOnBudgetAlert` Cloud Function (`functions/src/kill_switch.ts`, ADR-007 v1.0.4) listens on that topic and, on the **100% threshold**, writes:

```
/shops/{shopId}/featureFlags/runtime
  killSwitchActive: true
  firestoreWritesBlocked: true
  cloudinaryUploadsBlocked: true
  updatedAt: <serverTimestamp>
  updatedByUid: 'system_kill_switch'
```

Every customer / shopkeeper app's `KillSwitchListener` (`packages/lib_core/lib/src/feature_flags/kill_switch_listener.dart`) is on a Firestore `onSnapshot` of this doc and propagates the flags through `RuntimeFeatureFlags` within ~5 seconds. Adapters (`AuthProvider`, `CommsChannel`, `MediaStore`) honor the flags and stop new writes.

---

## Trigger

| Channel | Signal |
|---|---|
| **Email** | Cloud Billing alert to `aloktiwari49@gmail.com` (subject: "Budget alert: yugma-dukaan-..."). |
| **App** | Users see the kill-switch banner ("दुकान अभी बंद है"). New writes silently fail. |
| **Audit log** | New row in `/system/budget_alerts/history/{auto}` with `costAmount >= 1.00`. |
| **GCP console** | Billing → Budgets shows breach. |

---

## Severity

| Tier | Condition | First action within |
|---|---|---|
| **P0 — page** | Real spend, root cause unknown, real customer traffic on shop. | 15 min |
| **P1 — wake-up** | Real spend, root cause obvious (e.g., known load test), apps blocked. | 1 hour |
| **P2 — next day** | Test payload triggered the alert (manual `pubsub publish`). | next morning |
| **P3 — informational** | $0.10 or $0.50 threshold (kill-switch did NOT fire — only logged). | n/a |

Default to P0 in production until severity downgrades on diagnosis.

---

## Containment (≤ 5 minutes)

The kill-switch **already self-contained the problem**. Do NOT immediately reset it. The system is working as designed — money stopped being burned.

What to do:

1. **Confirm the flip is real.** Open the Firestore console (Firebase project `yugma-dukaan-{env}`) → `/shops/{shopId}/featureFlags/runtime` → look at `killSwitchActive`, `updatedAt`, `updatedByUid`. If `updatedByUid == 'system_kill_switch'` and `updatedAt` is recent, the flip is automatic and real.

2. **Notify Alok** if you're not Alok. The kill-switch should never fire silently in production.

3. **Do NOT manually reset the flags** until you've completed Diagnosis. Resetting `killSwitchActive=false` while the underlying spend cause is still active will burn through the next budget cap immediately and force a human-managed Blaze cap raise.

---

## Diagnosis (5–30 minutes)

Walk through, in order:

### 1. Cloud Billing breakdown

GCP Console → Billing → Reports → group by SKU. Identify which service is bleeding:

| SKU | Likely cause |
|---|---|
| **Cloud Functions invocations** | Runaway loop, missing debounce, retry storm. Check `firebase functions:log` for repeated identical entries. |
| **Firestore reads** | A `collectionGroup` query without a tenant filter, or a missed index causing fan-out. Check for queries scanning >1000 docs. |
| **Firestore writes** | A bot pumping inventory. Check `multiTenantAudit` history for `shopId_mismatch` flags. |
| **Cloud Storage egress** | Large media file linked from a high-traffic page. |
| **Cloud Build** | First-deploy IAM rebuilds (one-time). Should not happen at $1 scale. |
| **Phone Auth SMS** | SMS pumping attack — see `phone_quota_breach_response.md`. |

### 2. Recent deploys

```bash
firebase functions:log --project yugma-dukaan-{env} --limit 200
```

If a deploy in the last 24h introduced a runaway behavior, identify it via the function names + timestamps.

### 3. Cross-tenant audit

```bash
# Check for cross-tenant integrity violations that could indicate
# a malicious or runaway client.
firebase firestore:get system/audit_results/$(date +%Y-%m-%d)/summary --project yugma-dukaan-{env}
```

### 4. Application logs

Crashlytics dashboard → Issues → filter by last 1h. Look for repeated error patterns that could correlate with the spike.

---

## Resolution

### Path A — false positive (P2)

Someone published a test payload to `budget-alerts` (e.g., the staging-setup smoke test). The system worked correctly — it just wasn't supposed to fire.

1. Confirm the test payload (look at `/system/budget_alerts/history/{auto}` for entries with `cost == budget` and recent timestamp; the `triggeredBy` field, if present, may say `manual_test`).
2. Manually reset the flags via Firestore console:
   ```
   /shops/{shopId}/featureFlags/runtime
     killSwitchActive: false
     firestoreWritesBlocked: false
     cloudinaryUploadsBlocked: false
     updatedAt: <serverTimestamp>
     updatedByUid: '<your-uid>'
   ```
3. Apps will detect the reset within 5s and resume normal operation.

### Path B — real spend, root cause fixed (P1)

You found and fixed the offending behavior (e.g., reverted a deploy, patched a runaway loop, throttled a spammy query):

1. Verify the fix is deployed and the bleed has stopped (Cloud Billing → Reports → "last 1 hour" should show flat spend).
2. Reset the flags as above.
3. Capture the incident in `/system/budget_alerts/history` with a manual entry containing the root cause and the fix.

### Path C — real spend, ongoing (P0)

You can't fix the cause within the budget reset window. Escalate:

1. Decide with Alok whether to raise the Blaze cap (requires GCP billing account access and intentional over-spend approval) or accept the outage.
2. If raising: GCP Console → Billing → Budgets → edit → raise the budget. The kill-switch will NOT auto-reset on cap raise — the flags must be manually flipped (Path B step 2) once the spend rate is back under control.

---

## Communication

| Audience | When | Channel | Message template |
|---|---|---|---|
| **Alok (founder)** | Immediately on P0/P1 detection | WhatsApp | "Kill-switch fired on `{env}` shop `{shopId}` at `{time}`. Cause: `{tbd / known}`. Apps are read-only. Investigating." |
| **Sunil-bhaiya (operator)** | Within 30 min if customer-visible | WhatsApp | "Bhaiya, app abhi update ho raha hai — 30 minute mein theek ho jayega. Customer ko bata dijiye agar koi aaye." (Hindi: app is being updated — will be fine in 30 min; tell any customers who arrive.) |
| **Customers** | Only if outage > 2h or DPDP-relevant | n/a v1 | DPDP requires notification only on data-loss incidents. Pure availability outages don't trigger this. |
| **Yugma Labs status page** | Eventually (post-shop #2) | n/a v1 | Not yet exists. |

---

## Post-mortem

After resolution, within 24h:

1. Add a row to `/system/budget_alerts/history` (manual write via Firestore console) with `kind: 'incident'`, `rootCause: '...'`, `resolution: '...'`, `preventionTodo: '...'`.
2. Open a tracking task. Title: `Post-incident: kill-switch fired {date} — {root cause}`.
3. If the cause is an architectural gap, file a drift item in `docs/architecture-source-of-truth.md` §15.
4. If the kill-switch responded correctly but recovery was slow, file a runbook improvement against this file.

---

## See also

- `docs/architecture-source-of-truth.md` §8.5 (kill-switch sequence diagram), ADR-007.
- `functions/src/kill_switch.ts` (the function itself).
- `packages/lib_core/lib/src/feature_flags/kill_switch_listener.dart` (the client-side listener).
- `docs/runbook/staging-setup.md` Step 6 (how the topic, function, and budget are wired in the first place).
- `docs/runbook/multi_tenant_breach_response.md` (when the kill-switch was caused by a tenant breach).
- `docs/runbook/phone_quota_breach_response.md` (when the kill-switch was caused by SMS pumping).
