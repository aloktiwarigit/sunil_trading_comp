# Contributing to Yugma Dukaan

This document is for engineers working on the Yugma Dukaan monorepo. It captures the non-obvious rules every contributor must follow — the things that would otherwise bite a new contributor on their first PR.

Read this before your first PR.

---

## The canonical planning bundle

Every decision in this repo traces back to one of six planning artifacts. When in doubt, these are authoritative in this order:

1. `_bmad-output/planning-artifacts/product-brief.md` — the **why** and **what**
2. `_bmad-output/planning-artifacts/solution-architecture.md` — the **how** (16 sections + 15 ADRs)
3. `_bmad-output/planning-artifacts/prd.md` — 67 stories + 11 Standing Rules in the preamble
4. `_bmad-output/planning-artifacts/epics-and-stories.md` — sprint plan + dependency graphs
5. `_bmad-output/planning-artifacts/ux-spec.md` — 67-state catalog + 50 voice & tone strings
6. `_bmad-output/planning-artifacts/frontend-design-bundle/README.md` — "Workshop Almanac" design system

The **PRD Standing Rules** in `prd.md` preamble are binding acceptance criteria on every story — they don't get restated per-story, they apply everywhere.

---

## Standing Rule 11 — Project field-partition discipline

The most load-bearing rule in the codebase. Skip reading it at your peril.

### The rule

Repository methods **cannot** construct a `Project`, `ChatThread`, or `UdhaarLedger` patch that crosses the customer/operator/system field partition defined in SAD v1.0.4 §9.

### Enforced via Freezed sealed unions

Three patch classes per partitioned entity. Each lives in `packages/lib_core/lib/src/models/<entity>_patch.dart`:

**Project** (`project_patch.dart`)
- `ProjectCustomerPatch` — customer_app writes. Fields: `occasion`, `unreadCountForCustomer`
- `ProjectOperatorPatch` — shopkeeper_app writes. Fields: `state`, `totalAmount`, `amountReceivedByShop`, `lineItems[]`, `committedAt`, `paidAt`, `deliveredAt`, `closedAt`, `customerDisplayName`, `customerPhone`, `customerVpa`, `decisionCircleId`, `udhaarLedgerId`, `unreadCountForShopkeeper`
- `ProjectSystemPatch` — Cloud Functions only. Fields: `lastMessagePreview`, `lastMessageAt`, `updatedAt`
- `ProjectCustomerCancelPatch` — the one customer cross-partition mutation (draft → cancelled, gated by rule on `state == 'draft'`)
- `ProjectOperatorRevertPatch` — the operator cross-partition mutation (committed → draft with audit log)

**ChatThread** (`chat_thread_patch.dart`)
- `ChatThreadParticipantPatch` — customer writes. Fields: `unreadCountForCustomer`
- `ChatThreadOperatorPatch` — operator writes. Fields: `unreadCountForShopkeeper`, `participantUids`
- `ChatThreadSystemPatch` — Cloud Functions. Fields: `lastMessageAt`, `lastMessagePreview`

**UdhaarLedger** (`udhaar_ledger_patch.dart`)
- `UdhaarLedgerOperatorPatch` — operator writes only (customers have READ access but NEVER write per ADR-010). Fields: `runningBalance`, `acknowledgedAt`, `closedAt`, `reminderOptInByBhaiya`, `reminderCadenceDays`
- `UdhaarLedgerSystemPatch` — `sendUdhaarReminder` Cloud Function (SAD §7 Function 3). Fields: `reminderCountLifetime` (hard-capped at 3), `lastReminderAt`

### Why three separate classes, not a sealed union

A sealed `ProjectPatch` union would let the customer_app compiler accept `ProjectPatch.operator(...)` calls — which is exactly the bug we're trying to prevent. By making them three **independent** classes, the Dart import graph itself becomes the enforcement:

- `customer_app` imports **only** `ProjectCustomerPatch` + `ProjectCustomerCancelPatch`
- `shopkeeper_app` imports **only** `ProjectOperatorPatch` + `ProjectOperatorRevertPatch`
- Cloud Functions import **only** `ProjectSystemPatch`

Cross-imports are caught by two layers:
1. `tools/audit_project_patch_imports.sh` in CI (PRD I6.12 AC #3)
2. `packages/lib_core/test/fails_to_compile/customer_app_constructs_operator_patch.dart` — a negative compilation test

### Adding a new field to a partitioned entity

When you add a field to `Project`, `ChatThread`, or `UdhaarLedger`, you must:

1. Classify the field as customer / operator / system partition in the PR description.
2. Add it to **exactly one** of the three partition patch classes.
3. Do NOT add a generic `updateX(Map<String, dynamic>)` method to the repository — the typed patches are the only write path.
4. Update the PRD Standing Rule 11 preamble if the field crosses a partition edge that wasn't already documented.

---

## Forbidden vocabulary

Every contributor must treat these lists as compile-time constants.

### Udhaar khaata vocabulary (ADR-010, RBI-defensive)

**Never use, in any language, anywhere in the codebase or UI:**

```
interest, interestRate, overdueFee, dueDate, lendingTerms,
borrowerObligation, defaultStatus, collectionAttempt
```

Devanagari equivalents are equally forbidden:

```
ब्याज / ब्याज दर / देय तिथि / जुर्माना / ऋण / वसूली / डिफ़ॉल्ट /
क़िस्त / क़िस्त बंदी / भुगतान विफल / बकाया (as obligation)
```

The Firestore security rules at `firestore.rules` lines 105-116 reject any UdhaarLedger write that contains these field names. The test `test/locale/strings_test.dart` scans both `strings_hi.dart` and `strings_en.dart` for the same vocabulary on every PR.

**Permitted vocabulary:** `खाता` (account), `बाकी` (remaining), `भुगतान` (payment — action), `पूरा हुआ` (completed), `धन्यवाद` (thank you).

### Mythic / Sanskritized vocabulary (Brief Constraint 10)

Never use, in UI strings, copy, or anywhere that renders to a user:

```
शुभ / मंगल / मंगलमय / मंदिर / धर्म / धार्मिक / पूज्य /
आशीर्वाद / तीर्थ / तीर्थयात्री / स्वागतम् / उत्पाद /
गुणवत्ता / श्रेष्ठ / सर्वोत्तम
```

Plain everyday warmth words are fine: `धन्यवाद / विश्वास / आपका / स्वागत` (without the Sanskritized `म्` suffix).

---

## Free features only

Yugma Dukaan ships on Firebase Blaze free tier + Google Fonts + Cloudinary Free + GitHub Actions free. **Never** propose a dependency that requires a paid subscription, paid API key, or recurring bill:

- No WhatsApp Business Cloud API
- No paid Cloudinary plan
- No paid SMS provider contracts
- No Twilio / SendGrid / Mixpanel / Amplitude / paid Sentry
- No paid translation APIs, paid STT services, paid image optimization SaaS
- No Google Places / Maps embedded APIs beyond free quota

Free-tier Blaze **with the $1/month safety cap** is sanctioned by Brief Constraint 3 + ADR-007. Firebase Auth, Firestore, Storage, Functions, Analytics, Crashlytics, Performance, Remote Config, FCM, App Check are all free at one-shop scale.

If a feature cannot be built with the free stack, flag it explicitly in the PR description — don't silently propose a premium path.

---

## Code review

Every PR goes through BMAD's adversarial code-review pass. Reviewers use:

- **🔴 Blocker** — PR cannot merge. Fix before requesting re-review.
- **🟠 Should-fix** — PR can merge, finding queues for the next cleanup pass.
- **🟡 Nice-to-have** — low priority, triaged during retros.
- **✅ Clean** — no concerns.
- **❓ Question** — needs product / architecture clarification.

Anything that violates a Standing Rule, leaks forbidden vocabulary, breaks the multi-tenant integrity test, or crosses a partition boundary is automatically 🔴.

---

## Monorepo layout

```
yugma-dukaan/
├── apps/
│   ├── customer_app/          # Flutter, Android first
│   └── shopkeeper_app/        # Flutter, Android first
├── packages/
│   └── lib_core/              # Shared Freezed models + adapters + repos
├── sites/
│   └── marketing/             # Astro static (NOT Flutter Web per ADR-011)
├── functions/                 # TypeScript Cloud Functions
├── tools/                     # Build scripts, font subset, CI helpers
├── firestore.rules
├── firestore.indexes.json
├── storage.rules
├── melos.yaml
└── _bmad-output/planning-artifacts/  # The 6 canonical planning artifacts
```

See `packages/lib_core/README.md` for the shared library structure in detail.

---

## Workflow

```bash
# Bootstrap the workspace
melos bootstrap

# Generate Freezed + JSON + Riverpod code
melos run build_runner

# Static analysis
melos run analyze

# Unit + shape tests
melos run test

# Cross-tenant integrity test (shape level — Dart + fake_cloud_firestore)
melos run test:cross-tenant

# Real rules test (TypeScript + Firebase emulator)
cd tools
npm ci
npm run build
# In another terminal: firebase emulators:start --only firestore,auth --project yugma-dukaan-rules-test
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 GCLOUD_PROJECT=yugma-dukaan-rules-test npm run test:rules
```

---

*Last updated: 2026-04-11 (Phase 1.7 / PRD I6.12 AC #7 closure).*
