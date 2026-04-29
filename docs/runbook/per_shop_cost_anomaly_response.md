# Per-shop cost anomaly response runbook

> When the cost attribution dashboard shows unexpected spend for a specific shop. Goal: contain the bleeding before it cascades to other shops or hits the Blaze $1 kill-switch.

---

## What this is

The `aggregateCostAttribution` CF (daily 12:00 IST) writes per-shop summaries to `shops/{shopId}/cost_attribution/{YYYY-MM}`. The shopkeeper_app reads these via the `MediaSpendTile`. This runbook covers what to do when the numbers look wrong.

---

## Trigger

| Signal | Where to see it |
|---|---|
| Operator reports "spend tile shows high usage" | Shopkeeper app → Dashboard → Media Spend |
| Cloud Billing alert fires ($0.10 / $0.50 / $1.00) | Email to `aloktiwari49@gmail.com` |
| `mediaCostMonitor` CF logs `cloudinaryUploadsBlocked: true` | Cloud Logging |
| `system/media_usage_counter/shops/{shopId}` shows spike | Firestore Console |
| `kill_switch_response.md` scenario (global $1 cap breach) | See that runbook |

---

## Severity

| Tier | Condition | Response window |
|---|---|---|
| **P0** | Kill-switch fired (global $1 cap hit) | See `kill_switch_response.md`, 15 min |
| **P1** | Single shop driving 80%+ of total spend | 1 hour |
| **P2** | Cloudinary uploads blocked for one shop but others fine | Same day |
| **P3** | Cost attribution shows unexpected values (data quality) | Next day |

---

## Reading the dashboard

`shops/{shopId}/cost_attribution/{YYYY-MM}`:

```
usedCloudinaryCredits: 18      // Cloudinary uploads this month
cloudinaryFreeQuota: 25        // Free tier limit
cloudinaryPct: 72              // % of free quota used
smsOtpCount: 420               // OTP sends this month
smsFreeQuota: 10000            // Free tier limit per account (shared)
smsPct: 4                      // % of SMS quota used
```

**Warning thresholds (per-shop):**
- Cloudinary ≥ 80%: uploads will be blocked at 100%
- SMS ≥ 80% of the global pool: MSG91 fallback will activate
- Either at 95%: emergency (feature disable)

---

## Containment

### Path A — Cloudinary spike (P1/P2)

1. Check `system/media_usage_counter/shops/{shopId}` in Firestore — is the count realistic for the shop's size?
2. If a bot is pumping uploads, revoke the offending session via Firebase Auth Console.
3. Manually set `cloudinaryUploadsBlocked: true` in `/shops/{shopId}/featureFlags/runtime` to stop new uploads while investigating:
   ```
   Firestore Console → shops/{shopId}/featureFlags/runtime
   cloudinaryUploadsBlocked: true
   ```
4. Check Cloudinary dashboard for the upload history — identify which filenames/IPs are responsible.
5. After investigation, flip `cloudinaryUploadsBlocked` back to `false` once confirmed safe.

### Path B — SMS OTP spike (P1)

Check `system/phone_auth_quota/shops/{shopId}` in Firestore. If a single shop is draining the global SMS pool:

1. Set `otpAtCommitEnabled: false` in `/shops/{shopId}/featureFlags/runtime` — disables OTP for that shop only, other shops unaffected.
2. Investigate: is it a legitimate launch event (expected spike) or a pumping attack?
3. If attack: revoke affected sessions + enable SMS region restriction in Firebase Auth Console.
4. After fix: flip `otpAtCommitEnabled: true` and reset the counter if appropriate.

### Path C — Data quality issue (P3)

`aggregateCostAttribution` produces wrong numbers:
1. Check the CF logs for errors during the last run.
2. Verify `system/media_usage_counter/shops/{shopId}` and `system/phone_auth_quota/shops/{shopId}/{YYYY-MM}` source data looks correct.
3. If the aggregation is wrong: manually re-trigger by deleting the cost_attribution doc and waiting for the next daily run, or deploy a fix to the CF.

---

## Resolution

After containment:

1. **Document the incident** in `system/cost_attribution/{shopId}/{YYYY-MM}` by adding a `notes` field: `"2026-05-01: anomaly investigation, resolved by revoking bot session"`.
2. **Restore all flags** to operational state.
3. **Notify the shopkeeper** if their customers were impacted (OTP disabled, uploads blocked): `"Bhaiya, ek technical issue tha — ab theek ho gaya. Koi data nahi gaya."` (There was a technical issue — it's fixed now. No data was lost.)
4. **Post-mortem**: file a drift item in `docs/architecture-source-of-truth.md` §15 if the root cause was a code gap.

---

## Cost ceiling reference (from architecture doc §9.8)

| Shop count | Monthly cost | First ceiling |
|---|---|---|
| #1 | ₹0 | — |
| #5–7 | ~₹0–350 | **Cloudinary** (FIRST ceiling) |
| #25 | ~₹1,400 | Cloud Storage |
| #33 | ~₹2,050 | Phone Auth SMS |

At these counts, Triple Zero economics break. The billing model evolution playbook (`docs/runbook/triple_zero_evolution.md`) should be consulted before onboarding past shop #5–7.

---

## See also

- `docs/runbook/kill_switch_response.md` — global $1 cap response
- `docs/runbook/phone_quota_breach_response.md` — SMS quota exhaustion
- `functions/src/aggregate_cost_attribution.ts` — the aggregation CF
- `functions/src/media_cost_monitor.ts` — Cloudinary threshold monitor
- `functions/src/phone_auth_quota_monitor.ts` — SMS threshold monitor
