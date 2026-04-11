# Staging Firebase setup runbook

**Purpose:** document the exact steps to enable `yugma-dukaan-staging` (and eventually `yugma-dukaan-prod`) to the same service baseline as `yugma-dukaan-dev`. This is a **dev-env decision that requires Alok's approval** — the runbook exists so that when the approval lands, the steps are mechanical and fast.

**Current state (as of Phase 1.8, 2026-04-11):**

```
yugma-dukaan-dev      ✅ Firestore deployed, Auth enabled, apps registered, rules deployed
yugma-dukaan-staging  ⏸ Project exists, NO services enabled
yugma-dukaan-prod     ⏸ Project exists, NO services enabled
```

**Why `staging` before `prod`:** per Brief §9 R9, the first time multi-tenant logic is exercised in production is the highest-risk moment in the product timeline. Staging absorbs that risk first. Sprint 5 integration tests + Sprint 6 Month 3 gate validation both run against staging, not dev, so the `dev` project stays available for day-to-day development.

---

## Prerequisites (one-time per environment)

### 1. Alok's approval
Staging setup touches billing (Blaze upgrade), rule deployment, and custom-claim provisioning — all outside the "autonomous commit at phase boundary" scope. Never run this runbook without an explicit go from Alok.

### 2. Firebase CLI authenticated
```bash
firebase login
# Verify:
firebase projects:list | grep yugma-dukaan
```

Expect 3 projects: `yugma-dukaan-dev`, `yugma-dukaan-staging`, `yugma-dukaan-prod`.

### 3. The `staging` alias exists in `.firebaserc`
Verify with `firebase use` — the list should include `staging`. If not, add it:

```bash
firebase use --add
# Select yugma-dukaan-staging → alias staging
```

---

## Step 1 — Enable Firestore (one-time)

```bash
firebase use staging
firebase firestore:databases:list
```

If the default database does not exist, create it in `asia-south1` (Mumbai) — **this must match dev exactly** per SAD §1. Firestore region cannot be changed after creation.

1. Open the Firebase console → Firestore Database → Create database
2. Select **asia-south1 (Mumbai)**
3. Start in **production mode** (rules will be deployed in step 3 below — do NOT use "test mode")

---

## Step 2 — Enable Authentication providers

Firebase console → Authentication → Get started, then enable:

| Provider | Why |
|---|---|
| **Anonymous** | Customer app browse phase (PRD I6.1 + I6.2) |
| **Phone** | Customer app commit phase (PRD I6.2 + C3.4) — uses the 10k/mo Blaze free quota |
| **Google** | Shopkeeper ops app (PRD S4.1) |

No Apple / Facebook / email — not in scope per Brief §10.

---

## Step 3 — Deploy Firestore rules + indexes

From the project root:

```bash
cd "C:/Alok/Business Projects/Almira-Project"
firebase deploy --only firestore:rules,firestore:indexes --project yugma-dukaan-staging
```

Verify:

```bash
firebase firestore:rules --project yugma-dukaan-staging
# Should print the current firestore.rules version with Sprint 1.4 + 2.x fixes
```

**Known pre-existing drift (flagged Phase 1.2):** `firestore.rules` lines 50-52 use `'shopkeeper' / 'son' / 'munshi'` for `callerRole()` whereas SAD §5 + PRD canonical use `'bhaiya' / 'beta' / 'munshi'`. This drift will propagate to staging on deploy. Fix is queued for Sprint 4 P2.4 when chat rules extend to cover the `operators` collection with role-specific checks.

---

## Step 4 — Register both apps via flutterfire

```bash
cd apps/customer_app
flutterfire configure --project yugma-dukaan-staging
# This regenerates lib/firebase_options.dart — you'll need to choose
# a dart-only mode that does NOT overwrite the dev options.
# RECOMMENDED: use the `--config-out` flag to write to a separate file
# (e.g. firebase_options_staging.dart) so the dev + staging options
# can coexist. The app's main.dart switches between them via a
# --dart-define flag at build time.

cd ../shopkeeper_app
flutterfire configure --project yugma-dukaan-staging
```

**IMPORTANT:** Do NOT run `flutterfire configure` with the default output path when the dev options are already committed — that will clobber dev. The SAD §3 build pipeline expects dev / staging / prod options to coexist in the same repo selectable at build time. This is a one-time per-environment decision.

---

## Step 5 — Enable Storage (deferred until B1.6 voice notes land)

Storage is required by the `MediaStoreCloudinaryFirebase.uploadVoiceNote` path (Phase 1.1). Until Sprint 3 B1.3 / B1.6 actually need to upload voice notes against staging, Storage stays un-enabled.

When ready:

1. Firebase console → Storage → Get started
2. Select the same region (`asia-south1`) — MUST match Firestore
3. Start in **production mode**
4. Deploy `storage.rules`:
   ```bash
   firebase deploy --only storage --project yugma-dukaan-staging
   ```

---

## Step 6 — Blaze upgrade + budget alerts

**Required before:** Cloud Functions deploy (Sprint 5–6), Phone Auth SMS beyond free quota, or any scheduled job.

1. Firebase console → Settings → Usage and billing → Modify plan → Blaze (Pay-as-you-go)
2. Link a billing account (requires Google Cloud billing account)
3. Set up budget alerts at **$0.10 / $0.50 / $1.00** per Brief §10 + ADR-007:
   - Firebase console → Settings → Billing → Budgets & alerts
   - Create budget → amount = $1.00
   - Alerts at 10% / 50% / 100% of budget
   - Subscribe the Yugma Labs ops contact email
4. The `killSwitchOnBudgetAlert` Cloud Function (SAD §7 Function 1) subscribes to the Pub/Sub topic the budget alerts write to — deploy that function **before** the first real customer traffic hits staging so the kill-switch is live.

**Safety posture:** the $1 cap is a safety rail against SMS pumping attacks or runaway queries — NOT an expected spend. Real staging traffic at one-shop scale should cost $0.00 across an entire month. If staging ever approaches the cap, treat it as an incident and investigate before raising the cap.

---

## Step 7 — Seed the synthetic `shop_0` tenant

```bash
cd tools
npm ci
npm run build
GCLOUD_PROJECT=yugma-dukaan-staging node dist/seed_synthetic_shop_0.js
```

This creates one document of every entity type under `/shops/shop_0/`. The cross-tenant integrity test (`cross_tenant_integrity_test.dart`) uses these docs to assert a `shop_1` authed session cannot read or write them.

Without the seed, the cross-tenant test will silently pass against an empty tenant — which is a false positive.

---

## Step 8 — Deploy the first operator (manual, per PQ-C locked answer)

Per PRD PQ-C the first Operator doc must be created manually during shop onboarding (Yugma Labs ops action, not a self-serve flow). For the staging test run:

1. Ask Alok to sign in to a test Gmail account on a test Android device
2. Note the resulting Firebase UID from Firebase console → Authentication
3. Create the Operator document at `/shops/sunil-trading-company/operators/{uid}` with:
   ```json
   {
     "uid": "<google-uid>",
     "shopId": "sunil-trading-company",
     "role": "bhaiya",
     "displayName": "Sunil (staging test)",
     "email": "<test-email>",
     "joinedAt": <server-timestamp>,
     "permissions": {
       "canEditInventory": true,
       "canApproveDiscounts": true,
       "canRecordUdhaar": true,
       "canDeleteOrders": true,
       "canManageOperators": true
     },
     "weeklyHoursCommitted": 20
   }
   ```

After this, the shopkeeper_app signed in with that Gmail account gets full bhaiya access to staging's `sunil-trading-company` tenant.

---

## Step 9 — Smoke test

From the customer_app:

```bash
cd apps/customer_app
flutter run --dart-define=FIREBASE_ENV=staging
```

Expected:
- Anonymous sign-in succeeds silently
- Shop document loads (the one from `seed_synthetic_shop_0.js` + any manually seeded docs)
- Cross-tenant integrity test passes against the staging tenant
- Crashlytics + Analytics events start appearing in the staging project's Firebase console within 30 seconds

If any of these fails, do NOT proceed to the Month 3 gate validation — fix the staging bootstrap first.

---

## Rollback

If staging ever gets corrupted (wrong data, wrong rules version, wrong auth provider config):

1. Firebase console → Firestore → select the database → **Clear all data** (not "delete database" — that requires re-creation)
2. Re-deploy rules: `firebase deploy --only firestore:rules --project yugma-dukaan-staging`
3. Re-seed: `GCLOUD_PROJECT=yugma-dukaan-staging node tools/dist/seed_synthetic_shop_0.js`
4. Re-create the first Operator doc (step 8)

Prod rollback is **never** done via this runbook — production recovery is a separate incident response playbook that doesn't exist yet (Sprint 6 deliverable).

---

## When to run this runbook

**Trigger 1:** Sprint 5 integration test preparation. Alok approves → run steps 1–8 in one sitting, then proceed to integration test script.

**Trigger 2:** Sprint 6 Month 3 gate validation. By this point staging should already be fully configured — this trigger is only a sanity-check re-run of step 9 smoke test.

**Trigger 3:** Staging corruption incident. Run the rollback + re-run of steps 3, 7, 8.

---

*Last updated: 2026-04-11 (Phase 1.8 / staging prep runbook, approval pending Alok's go for Sprint 5).*
