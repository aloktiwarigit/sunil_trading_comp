# Shop deactivation full lifecycle runbook

> The complete DPDP-compliant lifecycle from bhaiya's 3-tap deactivation to final PII anonymization. Covers what the shopkeeper and customers see at each stage, and how to verify the sweep CF ran correctly.

---

## The lifecycle at a glance

```
Bhaiya taps 3-tap deactivation
         ↓
  shopLifecycle = 'deactivating'
  All client writes frozen (shopIsWritable = false)
         ↓ (up to 30 days — DPDP grace window)
  shopDeactivationSweep CF daily sweep
         ↓
  shopLifecycle = 'purgeScheduled'
  Active projects cancelled, open udhaar frozen
  Bilingual FCM sent to customers + operator
         ↓ (180 days — DPDP retention period)
  shopDeactivationSweep CF daily sweep
         ↓
  shopLifecycle = 'purged'
  7 PII fields anonymized to '[purged]'
  Final bilingual FCM sent
```

---

## Trigger

Bhaiya navigates to Settings → Shop Closure (S4.19) and completes the 3-tap confirmation in the shopkeeper_app. The app writes `shopLifecycle: 'deactivating'` to `/shops/{shopId}`.

**Immediately after this write:**
- `shopIsWritable()` returns false for this shop
- All customer and operator writes are frozen
- Reads continue (customers can still view their order history)
- The kill-switch is NOT triggered (spend limit is separate)

---

## What operator and customers see

### During `deactivating` (grace window — up to 30 days)

| Audience | Visibility |
|---|---|
| Bhaiya | Can still read all data; cannot write |
| Customers | Can view their own orders; cannot commit new projects |
| Marketing site | Still live; no banner |

### After `purgeScheduled` (180-day retention)

| Audience | Visibility |
|---|---|
| Bhaiya | FCM: "दुकान बंद हो रही है — 180 दिन में जानकारी हटा दी जाएगी" |
| Customers with open udhaar | FCM: "बकाया हो तो पूरा कर लीजिए" |
| Marketing site | Can be manually taken down |

### After `purged` (final)

| Audience | Visibility |
|---|---|
| All | FCM: "DPDP कानून के अनुसार जानकारी हटा दी गई" |
| Bhaiya's Firestore doc | 7 fields anonymized to `[purged]` |

---

## How to verify the sweep CF ran correctly

The sweep CF runs daily at 02:00 IST. Check the audit trail:

```
Firestore Console →
  system/deactivation_sweeps/history/{auto-id}
  Fields: executedAt, transitioned, purged, projectsCancelled,
          ledgersFrozen, notificationsSent, errorCount, errors
```

**Transition not happening on schedule?** Check:
1. `shopLifecycle` field is exactly `'deactivating'` (not 'Deactivating' or similar)
2. `shopLifecycleChangedAt` timestamp is set (the sweep uses it for the 30-day gate)
3. Check Cloud Functions logs for the `shopDeactivationSweep` function

**FCM not delivered?** Check:
- Customer FCM tokens land on `udhaarLedger` docs (`customerFcmToken` field) — only customers with open udhaar receive the first notification
- Operator FCM tokens land on `operators/{uid}` doc (`fcmToken` field) — may be absent if shopkeeper_app hasn't registered its token yet

---

## How to undo during the 30-day grace window

While `shopLifecycle == 'deactivating'`, bhaiya can undo by writing `shopLifecycle: 'active'` via the Firebase Console (Admin SDK required — client writes are frozen):

```typescript
await admin.firestore()
  .collection('shops').doc(shopId)
  .update({ shopLifecycle: 'active', shopLifecycleChangedAt: admin.firestore.FieldValue.serverTimestamp() });
```

After this, `shopIsWritable()` returns true again and normal operations resume.

**Cannot undo after `purgeScheduled`.** The 180-day retention period has begun and data deletion is scheduled.

---

## Severity tiers

| State | Severity | Response |
|---|---|---|
| `deactivating` | P3 informational | No action required — grace window active |
| Transition to `purgeScheduled` premature (< 30 days) | P0 | Contact Alok; restore `shopLifecycle: 'active'` via Admin SDK; investigate sweep CF bug |
| FCM not sent at `purgeScheduled` | P1 | Check function logs; manually send via Admin SDK if needed; file follow-up |
| PII NOT anonymized at `purged` after 180 days | P0 + DPDP notification | Manual anonymization via Admin SDK; file incident; DPDP board notification within 72h if PII leaked |
| PII anonymized too early | P0 | Restore from Firestore export backup; file incident; DPDP notification |

---

## See also

- `functions/src/shop_deactivation_sweep.ts` — the sweep implementation
- `docs/runbook/kill_switch_response.md` — if budget alerts fire during deactivation
- `docs/runbook/multi_tenant_breach_response.md` — if PII crosses tenant boundaries during deactivation
- `docs/architecture-source-of-truth.md` §8.7 — deactivation sequence diagram
