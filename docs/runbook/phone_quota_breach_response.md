# Phone-auth SMS quota incident response runbook

> When the Firebase Phone Auth SMS quota approaches or hits its monthly cap. Either we have legitimate growth (Triple Zero economics break — see Brief §2.4), or we have an SMS-pumping attack. The response branches sharply on which.

---

## What this is

Firebase Auth Phone OTP gives 10,000 free SMS per month on the Blaze plan (per Brief §10 + ADR-002). At one-shop scale this is plenty. As the platform grows past shop #33 (per the SAD §10 cost ceiling table) the quota becomes the **first economic ceiling** — the moment Triple Zero "ops cost = ₹0" stops being viable for phone OTP at signup.

The `phoneAuthQuotaMonitor` Cloud Function (`functions/src/phone_auth_quota_monitor.ts`, scheduled `0 10 * * *` IST) reads the SMS counter from `/system/phone_auth_quota/{YYYY-MM}` and:

- At **80%** of cap: flips `auth_provider_strategy` Remote Config flag to `msg91` (the MSG91 fallback adapter).
- At **95%** of cap: flips `otpAtCommitEnabled` runtime flag to `false`. Customers can browse but cannot OTP-verify at commit.

The MSG91 fallback adapter (`AuthProviderMsg91`) exists in `lib_core` but was a stub at the time of writing — drift §15.2.M. Verify it works before relying on it.

---

## Trigger

| Channel | Signal |
|---|---|
| **`phoneAuthQuotaMonitor` daily run** | 10:00 IST writes `/system/phone_auth_quota/{YYYY-MM}/checks/history/{auto}` with `pct >= 80` or `pct >= 95`. |
| **Firebase Auth Console** | "Phone auth usage" graph approaching cap. |
| **App-side OTP failures** | Customers reporting OTP not arriving (post-95% threshold). |
| **Cloud Billing** | If Phone Auth burst past free tier, billing alerts will fire — see `kill_switch_response.md`. |

Set a daily review of the quota usage row in the operator dashboard (Sprint 4+ S4.16). Until that's wired, the operator should glance at the Auth Console weekly.

---

## Severity

| Tier | Condition |
|---|---|
| **P0** | SMS pumping attack confirmed (irregular geographic distribution, or rate-of-use is faster than legitimate signup growth could explain). |
| **P1** | Legitimate growth has us at 95%+. OTP-at-commit is disabled, customers can't pay. |
| **P2** | At 80%. MSG91 fallback flipped. New customers see MSG91-branded OTP screens (possibly different UX). |
| **P3** | < 80%. Informational. |

---

## Containment

### Path A — SMS pumping attack (P0)

**Signs:**
- High SMS rate from a single client / IP / phone-number prefix.
- Phone numbers in unusual geographies or all from a small range.
- Rate exceeds plausible signup growth (e.g., 1,000 SMS in an hour at one-shop scale).

**Steps (≤ 5 min):**

1. **Disable Phone Auth entirely** at the project level:
   - Firebase Console → Authentication → Sign-in method → Phone → Disable.
   - This stops new SMS sends within seconds.
2. **Set `otpAtCommitEnabled = false`** at every active shop's `/shops/{shopId}/featureFlags/runtime`. Apps will hide the OTP step on next snapshot.
3. **Notify Alok** (P0 — phone call).
4. **Open Firebase Auth Console → Users** and look at recent sign-ins. If many anonymous-to-phone upgrades from a small range of phone numbers, those are the attack vector.

**Don't yet:**
- Re-enable Phone Auth — wait until you have App Check + rate limiting in place (see Resolution).
- Refund the SMS spend — it's not refundable.

### Path B — legitimate growth (P1/P2)

**Signs:**
- SMS sends correlate with onboarding day count (a new shop just launched, real customers signing up).
- No anomalies in geographic / number distribution.
- Sunil-bhaiya is happy because lots of customers are arriving.

**Steps:**

1. The 80% / 95% flag flips already happened (the monitor function did its job). Confirm the flip is in effect:
   - `/system/phone_auth_quota/{YYYY-MM}` should show the latest run with `pct` value.
   - Remote Config should show `auth_provider_strategy: msg91` (cached up to 12h on clients).
2. **MSG91 fallback adapter** — verify it actually works. If `AuthProviderMsg91` is still a stub, we have an outage from 80% on. Test in a debug build before assuming customers are getting OTPs.
3. **Customer-facing notice** — if OTP-at-commit is disabled (95% reached), shop should display "OTP service temporarily unavailable" copy. Customers can still browse and DC, but cannot pay until next month or until the cap resets.

---

## Diagnosis

### 1. Get the rate

```bash
gcloud logging read 'resource.type="firebase_auth" jsonPayload.event="phone_verification_sent"' \
  --limit 100 --project yugma-dukaan-{env} --format json | jq '.[] | .timestamp'
```

Compare the rate of SMS over the last 24h vs the last week. A 10x spike = attack. A steady ramp = growth.

### 2. Geographic / number-prefix analysis

For each SMS event, the destination phone number is logged (last 4 digits hashed for DPDP). If 80%+ of recent sends are to one prefix (e.g., +91 8XXXXXXXXX), it's a targeted pump.

### 3. Verify monitor function ran

```bash
firebase functions:log --only phoneAuthQuotaMonitor --project yugma-dukaan-{env} --limit 30
```

Look for the most recent `pct` value. If `pct >= 80` and the Remote Config update wasn't propagated (clients still have cached `firebase`), force a Remote Config fetch in the customer_app via Firebase Console → Remote Config → Publish.

---

## Resolution

### Path A resolution — pumping attack

1. **Add App Check to Phone Auth** — Firebase Auth has reCAPTCHA Enterprise integration that drastically slows pumpers. Enable in Auth Console → Settings → SMS region policy.
2. **Restrict SMS regions** — if your customers are India-only, restrict SMS sends to `+91` only. Auth Console → Settings → SMS region policy → Restricted to allow countries.
3. **Re-enable Phone Auth** only after the above are in place.
4. **Reset `otpAtCommitEnabled = true`** in `/shops/{shopId}/featureFlags/runtime` once new defenses are deployed.
5. **Document the attack pattern** for future detection.

### Path B resolution — legitimate growth

1. **Decide whether to upgrade the SMS quota** — Firebase doesn't sell extra SMS directly; you'd be paying per-SMS at standard rates (~$0.05/SMS). At 10k/month additional, that's $500/month — Triple Zero economics break here unless absorbed by Yugma Labs.
2. **Decide whether to switch primary AuthProvider to MSG91 permanently** — MSG91's pricing is INR-based and more favorable for Indian volume. This is the path the SAD anticipated.
3. **Wait for next month** — the quota resets on the 1st. If we're close to month-end, just ride it out with MSG91 fallback.

The decision is a Yugma Labs business call, not a runbook step.

---

## Communication

| Audience | When | Channel | Message |
|---|---|---|---|
| **Alok** | P0 immediately; P1 within 1h | WhatsApp / phone | Tier + cause (attack vs growth) + current containment state. |
| **Sunil-bhaiya / shopkeepers** | When `otpAtCommitEnabled = false` is in effect | wa.me | "Bhaiya, OTP service abhi 1-2 din ke liye band hai. Customer browse kar sakte hain, lekin payment month-end tak rukega." |
| **Customers (in-app)** | At 95% + flag flip | App banner via `RuntimeFeatureFlags.otpAtCommitEnabled` | "OTP service abhi unavailable hai — agle hafte try kijiye." |
| **Yugma Labs ops contact** | Next billing cycle | Email | If month-over-month phone auth spend > $0, that's a scaling event Alok needs to budget for. |

---

## Post-mortem

Specific items for phone-auth incidents:

1. **Was the trigger detected within 1 day?** The monitor runs daily — late detection means the function failed or the audit doc wasn't checked.
2. **Was the MSG91 fallback functional?** If it was still a stub (drift §15.2.M), file an urgent task to wire it before the next incident.
3. **Was the 80% threshold the right inflection?** If 80% → 95% → cap took only days, the thresholds may need to move down (e.g., 60% / 80%) at higher shop count.
4. **Was the attack vector fixed?** App Check on Phone Auth must be in place before re-enabling Phone Auth post-attack.

File at `docs/incidents/{YYYY-MM-DD}-phone-quota-{tier}.md`.

---

## See also

- `docs/architecture-source-of-truth.md` §3 (phone auth as the FIRST cost ceiling), ADR-002 (AuthProvider adapter), ADR-007 (kill-switch).
- `functions/src/phone_auth_quota_monitor.ts` (the monitor function).
- `packages/lib_core/lib/src/adapters/auth_provider_msg91.dart` (the fallback — verify it's not a stub).
- Brief §2.4 (kill gates: phone auth quota < 5,000/mo → fail over to MSG91).
- `docs/runbook/kill_switch_response.md` (if SMS spend triggers Cloud Billing alerts).
