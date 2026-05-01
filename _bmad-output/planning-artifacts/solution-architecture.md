---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
inputDocuments:
  - product-brief.md (v1.2)
  - party-mode-session-01-synthesis-v2.md (v2.1)
  - product-brief-elicitation-01.md
workflowType: 'architecture'
project_name: 'Almira-Project (Yugma Dukaan)'
user_name: 'Alok'
date: '2026-04-11'
author: 'Winston (System Architect)'
status: 'v1.0.4 — advanced elicitation back-fill applied (3 new ADRs, 2 new Cloud Functions, schema invariants strengthened); ready for PRD AE Phase 2'
---

# Solution Architecture Document — Yugma Dukaan

**The world-class digital storefront for the independent almirah shopkeeper of Hindi-speaking North India**

**Architect:** Winston (BMAD System Architect)
**For:** Alok, Founder, Yugma Labs
**Date:** 2026-04-11
**Inputs:** Product Brief v1.4, PRD v1.0.4, Synthesis v2.1, Elicitation Report 01, methods.csv (Advanced Elicitation), SKILL.md
**Status:** v1.0.4 — advanced-elicitation back-fill applied (5 methods + party mode, 12 findings landed, 3 new ADRs, 2 new Cloud Functions, schema invariants strengthened); ready for Phase 2 PRD AE round
**Flagship shop:** Sunil Trading Company (सुनील ट्रेडिंग कंपनी), Harringtonganj market, Ayodhya. ShopId slug: `sunil-trading-company`. Marketing subdomain: `sunil-trading-company.yugmalabs.ai`. The example slug `ramesh-bhaiya-almirahs` used in §5 schema and throughout this document is a placeholder — substitute `sunil-trading-company` in production.

---

## §1 — Executive Architecture Summary

Yugma Dukaan is a three-component Flutter + Firebase platform built for a single independent almirah shopkeeper in Tier-3 North India, with multi-tenant scaffolding underneath that allows shop #2 onwards to onboard without rewriting the architecture. This SAD describes how that system is built, what trade-offs were made, and which decisions are deliberately deferred or feature-flagged because the brief's elicitation phase identified them as fragile.

The architecture rests on **five load-bearing decisions**, three of which directly mitigate findings from the adversarial elicitation. None of them are clever; all of them are boring on purpose. Boring technology is what survives a six-to-nine-month enterprise build with a small team.

**The Five Truths:**

1. **One Firebase project per environment** (dev/staging/prod = three projects), multi-tenant by `shopId` field on every Firestore document, with a synthetic `shop_0` tenant maintained continuously from day one of v1 development. Cross-tenant integrity tests run on every CI build. This pulls the multi-tenant flip-switch risk (R9) forward to development time, where bugs are cheap, instead of leaving it for shop #2 onboarding, where bugs are expensive and visible.

2. **Auth is layered and persistent, behind a swappable adapter.** Tier 0 is Firebase Anonymous Auth for the browse/Decision Circle phase (zero friction, unlimited free, device-scoped UID). Tier 1 is Firebase Phone Auth OTP at the commitment moment, with session persistence via refresh tokens as a hard requirement — one OTP per install, silent sign-in on every subsequent open, no re-authentication ceremony. Tier 2 is Google Sign-In on the shopkeeper ops side. All three live behind a single `AuthProvider` interface so the entire identity layer can be swapped to MSG91, email magic link, or UPI-metadata-only verification without rewriting any screen. This is the R8 mitigation the elicitation demanded.

3. **Firestore is offline-first by default and the schema is designed to fit ≤30 reads per typical customer session.** Both the Riverpod 3 persistence layer and Firestore's own offline cache are enabled, belt-and-suspenders, because Tier-3 4G is what it is. Aggressive denormalization, mandatory `limit()` and indexed `orderBy()`, sub-collections per shop where it materially helps quota math. The Firestore schema is the budget; if a feature can't fit, the feature redesigns — not the budget.

4. **Decision Circle is a feature flag, not a schema foundation.** A `Project` works fully without any `DecisionCircle` document attached. The DC document type can be deleted entirely with no migration. The Guest Mode persona toggle is a Remote Config flag. This honors §3 of the brief while surviving R11 — the elicitation pre-mortem identified that real committees in 2026 may video-call instead of pass phones, and the schema must survive Decision Circle being wrong.

5. **Udhaar khaata is an accounting mirror in the schema itself, not in screen copy.** Allowed fields: `recordedAmount`, `acknowledgedAt`, `partialPaymentReferences[]`, `runningBalance`, `closedAt`. **Forbidden field names** (will not exist anywhere in the codebase): `interest`, `interestRate`, `overdueFee`, `dueDate`, `lendingTerms`, `borrowerObligation`, `defaultStatus`, `collectionAttempt`. The R10 RBI legal posture lives in the data model, not in lawyer-reviewed copy that someone might forget to maintain. When the lawyer eventually reviews the system (deferred per Step 0.9), they validate copy on screens — not whether the architecture is structurally a lending instrument. It cannot accidentally become one because the vocabulary is missing from the codebase.

**The Three Adapters** are mandatory v1 architecture, not v1.5:

- **AuthProvider** abstracts FirebaseAuth (Anonymous + Phone + Google) with stub implementations for MSG91 and UPI-metadata-only fallbacks. R8 + R12 mitigation.
- **CommsChannel** abstracts customer↔shopkeeper conversation. Default: Firestore real-time chat (the Ramesh-bhaiya Ka Kamra thread). Fallback: WhatsApp `wa.me` deep link with attached Project context blob. R5 + R13 mitigation.
- **MediaStore** abstracts catalog image storage. Default: Cloudinary Free for catalog, Firebase Storage for voice notes and branding. Fallback: Cloudflare R2 (deferred until shop #25+). Cost-discipline mitigation.

**Locked Stack:**

- **Client framework:** Flutter 3.x (Android primary, iOS soon)
- **State management:** Riverpod 3 with `riverpod_generator`
- **Navigation:** GoRouter
- **Data classes:** Freezed 3 + `build_runner`
- **UI:** Material 3 + custom `ThemeExtension` token architecture
- **Typography:** Tiro Devanagari Hindi (Devanagari display) + Mukta (Devanagari body) + Fraunces (English display, italic) + EB Garamond (English body) + DM Mono (numeric/timestamps) *(v1.0.4 / Phase 6 IR Check v1.2 patch 2026-04-11: revised from stale "Noto Sans Devanagari / Mukta primary, Inter or Roboto secondary" to match Brief v1.4 Constraint 4 — the canonical font stack locked by the frontend-design bundle)*
- **Marketing site:** Astro static site generator (NOT Flutter Web — see ADR-011)
- **Backend:** Firebase Blaze, three projects (dev/staging/prod), $1/month hard budget cap with kill-switch Cloud Function
- **Storage:** Firestore (data) + Cloud Storage (voice notes + branding) + Cloudinary Free (catalog images)
- **Comms:** WhatsApp `wa.me` deep links (no API in v1) + FCM for push + Firestore real-time for in-app chat
- **Payments:** UPI deep link intents (PhonePe / GPay / Paytm) + COD workflow + bank transfer + digital udhaar khaata
- **CI/CD:** GitHub Actions free tier (2k min/month) + Codemagic free Flutter tier
- **Dev tooling:** Claude Code + Dart/Flutter MCP server + Android Studio
- **Locale:** ICU MessageFormat via the `intl` package

**In scope for v1 (Months 1–5):** Customer Flutter app, marketing static site, shopkeeper ops Flutter app, Bharosa pillar (shopkeeper voice/face/curation/memory + Absence Presence + Golden Hour photo pipeline), Pariwar pillar (Decision Circle + Guest Mode behind feature flags), Project-based data model, layered auth with session persistence, UPI + COD + bank transfer + digital udhaar khaata, Hindi-first Devanagari UI with English toggle, multi-tenant `shopId` namespacing, synthetic `shop_0` tenant continuously exercised in CI, all three adapters fully implemented, kill-switch Cloud Function, Firebase Crashlytics + Analytics + Performance, GitHub Actions CI.

**Deferred to v1.5:** Rewards/loyalty layer, offers/promotions engine, enhanced shopkeeper analytics, customer memory amplification, WhatsApp `wa.me` deep links throughout the UX, website SEO + Google Business Profile, first multi-tenant onboarding playbook dry run.

**Deferred to v2:** Cost-per-shop unit economics validated against real shops, go-to-market playbook for shops 2–10, shop #2 onboarding pilot, optional AR room placement, optional Hindi voice search, festive re-skinning, role-based ops app access for burnout mitigation.

**Explicitly out of scope at every version:** B2B / institutional buyers, pilgrim/Mandir/religious-tourism positioning, Muhurat Mirror, Threshold Passage delivery videos, mythic heirloom screen copy, NBFC EMI, credit cards, third-party logistics, live video shop walkthrough, paid cloud infrastructure beyond Firebase Blaze.

The architecture is pragmatic, not ambitious. It does one thing — make a Tier-3 shopkeeper's relational capital travel through a screen — and refuses to do anything else.

---

## §2 — System Context Diagram

```
                    ┌────────────────────────────────────────────┐
                    │          CLIENT TIER (Flutter)              │
                    │                                              │
                    │  ┌──────────────┐  ┌──────────────────┐    │
                    │  │ customer_app │  │ shopkeeper_app   │    │
                    │  │  (mobile)    │  │  (mobile/tablet) │    │
                    │  │              │  │                  │    │
                    │  │ • Browse     │  │ • Inventory CRUD │    │
                    │  │ • DC chat    │  │ • Curation       │    │
                    │  │ • Commit/Pay │  │ • Voice notes    │    │
                    │  │ • Receive    │  │ • Orders / chat  │    │
                    │  │              │  │ • Udhaar ledger  │    │
                    │  └──────┬───────┘  └────────┬─────────┘    │
                    │         │                   │              │
                    │         └───────┬───────────┘              │
                    │                 │                          │
                    │                 ▼                          │
                    │       ┌──────────────────┐                │
                    │       │     lib_core     │  ← models      │
                    │       │  (shared pkg)    │     theme      │
                    │       │                  │     locale     │
                    │       │ AuthProvider     │     adapters   │
                    │       │ CommsChannel     │     firebase   │
                    │       │ MediaStore       │     client     │
                    │       └────────┬─────────┘                │
                    └────────────────┼──────────────────────────┘
                                     │
                                     │ Firebase SDK
                                     ▼
       ┌──────────────────────────────────────────────────────────┐
       │              FIREBASE BLAZE (3 projects)                  │
       │                                                            │
       │   yugma-dukaan-dev      yugma-dukaan-staging               │
       │                         yugma-dukaan-prod                  │
       │                                                            │
       │   Each project contains:                                   │
       │     • Firestore (data, multi-tenant by shopId)            │
       │     • Cloud Storage (voice notes, branding)               │
       │     • Cloud Functions gen 2                               │
       │         - killSwitchOnBudgetAlert                          │
       │         - generateWaMeLink                                 │
       │         - sendUdhaarReminder                               │
       │         - multiTenantAuditJob                              │
       │         - firebasePhoneAuthQuotaMonitor                    │
       │     • Auth (Anonymous + Phone + Google Sign-In)           │
       │     • FCM (push notifications)                            │
       │     • App Check (abuse / fraud protection)                │
       │     • Hosting (marketing static site)                     │
       │     • Crashlytics + Analytics + Performance               │
       │     • Remote Config (feature flags)                       │
       │                                                            │
       │   Hard $1/month budget cap → kill-switch trigger          │
       │   Alerts at $0.10, $0.50, $1.00 thresholds               │
       └─────┬──────────────────────┬───────────────────┬─────────┘
             │                      │                   │
             ▼                      ▼                   ▼
   ┌─────────────────┐    ┌─────────────────┐  ┌────────────────┐
   │   Cloudinary    │    │   WhatsApp      │  │  UPI Intent    │
   │   (Free tier,   │    │   wa.me deep    │  │  (PhonePe /    │
   │   25 cred/mo,   │    │   links — no    │  │   GPay /       │
   │   catalog imgs) │    │   API in v1)    │  │   Paytm)       │
   └─────────────────┘    └─────────────────┘  └────────────────┘

   ┌─────────────────────────────────────────┐
   │   Marketing site (Astro, static)         │
   │   Served from yugma-dukaan-prod Hosting  │
   │   <shopname>.yugmalabs.ai                │
   │                                           │
   │   Bundle: ~50KB initial                  │
   │   Devanagari fonts subset-loaded         │
   │   3G-friendly, offline-readable          │
   └─────────────────────────────────────────┘

   ┌─────────────────────────────────────────┐
   │   DEFERRED to v1.5+:                      │
   │   • YouTube Data API v3 (showcase video) │
   │   • TURN/WebRTC (live video)             │
   │   • STT services (voice search)          │
   │   • WhatsApp Business Cloud API          │
   │   • Cloudflare R2 (catalog overflow)     │
   └─────────────────────────────────────────┘
```

**Data flow notes:**

- Customer app reads/writes Firestore directly via SDK with App Check enforced
- Shopkeeper ops app reads/writes Firestore via SDK with role-scoped security rules
- Cloudinary uploads are direct from client via signed upload presets
- Voice notes upload to Cloud Storage, served via signed URLs
- WhatsApp `wa.me` links are generated by `generateWaMeLink` Cloud Function (HTTPS callable) with Project context blob
- UPI deep links are constructed client-side using URI schemes; the payer's VPA is captured via the intent return-URL and stored against the Project document
- Push notifications via FCM are triggered by Cloud Functions or directly by shopkeeper ops app SDK
- Marketing site is pure static — zero JS framework runtime, zero auth, zero Firestore reads. It's an HTML billboard that links into the customer app.

---

## §3 — The Three-Component Monorepo Structure

A single Git monorepo contains all four targets (customer app, shopkeeper app, marketing site, shared core) plus tooling and CI configuration. The Flutter targets share `lib_core` via local pubspec workspace; the marketing site is a sibling Astro project that does not depend on Dart.

### File and folder layout

```
yugma-dukaan/
├── README.md
├── .github/
│   └── workflows/
│       ├── ci-flutter.yml          # Customer + shopkeeper apps + lib_core
│       ├── ci-marketing.yml        # Astro static site
│       ├── ci-cloud-functions.yml  # TypeScript Cloud Functions
│       ├── ci-cross-tenant-test.yml # Synthetic shop_0 integrity check
│       └── deploy-staging.yml
├── pubspec.yaml                    # Workspace root pubspec
├── melos.yaml                      # OR pubspec_workspace.yaml — see note
├── analysis_options.yaml           # Shared lints
├── .gitignore
│
├── apps/
│   ├── customer_app/
│   │   ├── pubspec.yaml
│   │   ├── lib/
│   │   │   ├── main.dart
│   │   │   ├── app.dart            # MaterialApp + GoRouter setup
│   │   │   ├── routes/
│   │   │   ├── features/
│   │   │   │   ├── browse/         # Curated shortlists, Golden Hour photos
│   │   │   │   ├── decision_circle/ # Guest Mode personas (feature-flagged)
│   │   │   │   ├── chat/           # Ramesh-bhaiya Ka Kamra thread
│   │   │   │   ├── commit/         # Phone OTP upgrade + Project finalize
│   │   │   │   ├── payment/        # UPI intent + COD + bank transfer + udhaar
│   │   │   │   └── delivery_track/
│   │   │   └── widgets/            # Customer-app-specific widgets
│   │   ├── android/
│   │   ├── ios/
│   │   └── test/
│   │
│   └── shopkeeper_app/
│       ├── pubspec.yaml
│       ├── lib/
│       │   ├── main.dart
│       │   ├── app.dart
│       │   ├── routes/
│       │   ├── features/
│       │   │   ├── inventory/      # SKU CRUD + Golden Hour capture
│       │   │   ├── orders/         # Project list + Decision Circle thread access
│       │   │   ├── chat/           # Reply to Ramesh-bhaiya Ka Kamra
│       │   │   ├── voice_notes/    # Record + attach to SKUs/Projects/customers
│       │   │   ├── curation/       # Update occasion shortlists (one-tap)
│       │   │   ├── customer_memory/ # Past customers + relationships layer
│       │   │   ├── udhaar_ledger/  # Accounting mirror (no lending vocab)
│       │   │   ├── analytics/      # Sales dashboard
│       │   │   ├── absence_presence/ # Status + scheduled away messages
│       │   │   └── settings/       # Operator roles, theme tokens, premium flags
│       │   └── widgets/
│       ├── android/
│       ├── ios/
│       └── test/
│
├── packages/
│   └── lib_core/
│       ├── pubspec.yaml
│       ├── lib/
│       │   ├── lib_core.dart
│       │   ├── src/
│       │   │   ├── models/         # Freezed 3 data classes for all entities
│       │   │   │   ├── shop.dart
│       │   │   │   ├── operator.dart
│       │   │   │   ├── customer.dart
│       │   │   │   ├── project.dart
│       │   │   │   ├── line_item.dart
│       │   │   │   ├── inventory_sku.dart
│       │   │   │   ├── curated_shortlist.dart
│       │   │   │   ├── decision_circle.dart    # Optional schema
│       │   │   │   ├── chat_thread.dart
│       │   │   │   ├── message.dart
│       │   │   │   ├── voice_note.dart
│       │   │   │   ├── udhaar_ledger.dart      # Accounting mirror only
│       │   │   │   ├── customer_memory.dart
│       │   │   │   ├── golden_hour_photo.dart
│       │   │   │   ├── shop_theme_tokens.dart
│       │   │   │   └── feature_flags.dart
│       │   │   ├── adapters/       # The Three Adapters
│       │   │   │   ├── auth_provider.dart      # Interface
│       │   │   │   ├── auth_provider_firebase.dart
│       │   │   │   ├── auth_provider_msg91.dart # Stub for R8 fallback
│       │   │   │   ├── comms_channel.dart      # Interface
│       │   │   │   ├── comms_channel_firestore.dart
│       │   │   │   ├── comms_channel_whatsapp.dart # wa.me fallback
│       │   │   │   ├── media_store.dart        # Interface
│       │   │   │   ├── media_store_cloudinary.dart
│       │   │   │   ├── media_store_firebase.dart
│       │   │   │   └── media_store_r2.dart     # Stub for shop #25+
│       │   │   ├── repositories/   # Firestore-backed repos with shopId scoping
│       │   │   │   ├── shop_repo.dart
│       │   │   │   ├── project_repo.dart
│       │   │   │   ├── inventory_repo.dart
│       │   │   │   ├── chat_repo.dart
│       │   │   │   ├── udhaar_repo.dart
│       │   │   │   └── customer_memory_repo.dart
│       │   │   ├── theme/
│       │   │   │   ├── theme_loader.dart       # Boot-time token fetch
│       │   │   │   ├── theme_extension.dart    # Custom ThemeExtension
│       │   │   │   └── theme_defaults.dart     # Fallback if doc missing
│       │   │   ├── locale/
│       │   │   │   ├── strings_hi.dart         # Devanagari source-of-truth
│       │   │   │   ├── strings_en.dart         # English secondary
│       │   │   │   └── icu_loader.dart         # ICU MessageFormat helpers
│       │   │   ├── feature_flags/
│       │   │   │   └── remote_config_loader.dart
│       │   │   ├── persistence/
│       │   │   │   └── riverpod_persistence.dart # Riverpod 3 cache layer
│       │   │   ├── firebase_client.dart        # Wraps init + App Check
│       │   │   ├── shop_id_provider.dart       # Current tenant
│       │   │   └── upi_intent.dart             # UPI deep link constructor
│       │   └── ...
│       └── test/
│           ├── adapters/
│           ├── repositories/
│           └── cross_tenant_integrity_test.dart  # CRITICAL — runs in CI
│
├── sites/
│   └── marketing/
│       ├── package.json            # Astro project (Node)
│       ├── astro.config.mjs
│       ├── src/
│       │   ├── pages/
│       │   │   ├── index.astro     # Landing — shopkeeper face + voice note
│       │   │   ├── about.astro     # Shop story
│       │   │   ├── catalog.astro   # Curated shortlist preview
│       │   │   └── visit.astro     # Map + hours + WhatsApp CTA
│       │   ├── layouts/
│       │   ├── components/
│       │   ├── styles/
│       │   │   └── devanagari.css  # Subset-loaded Tiro Devanagari Hindi + Mukta (Phase 6 IR Check v1.2 patch — was stale "Noto Sans Devanagari")
│       │   └── content/
│       │       └── shops/
│       │           └── ramesh-bhaiya-almirahs.json  # Per-shop content
│       └── public/
│           └── fonts/              # Subset font files
│
├── functions/
│   ├── package.json                # TypeScript Cloud Functions
│   ├── tsconfig.json
│   └── src/
│       ├── index.ts
│       ├── kill_switch.ts
│       ├── wa_me_link.ts
│       ├── udhaar_reminder.ts
│       ├── multi_tenant_audit.ts
│       └── phone_auth_quota_monitor.ts
│
├── firestore.rules                 # Security rules — see §6
├── firestore.indexes.json          # Required composite indexes
├── storage.rules
├── firebase.json                   # Firebase project config
├── .firebaserc                     # Project aliases (dev/staging/prod)
│
├── tools/
│   ├── seed_synthetic_shop_0.ts    # Populates the synthetic tenant
│   ├── generate_devanagari_subset.sh  # Font subsetting tool
│   └── cost_forecast.ts            # Cost forecasting model (see §10)
│
└── docs/
    ├── architecture.md             # This document
    ├── adr/                        # Individual ADR files
    └── runbook/
        ├── kill_switch_response.md
        ├── multi_tenant_breach_response.md
        └── phone_quota_breach_response.md
```

### Workspace tooling

I recommend `melos` for the Dart side (mature, well-supported, used by Very Good Ventures and most production Flutter monorepos in 2026) over the newer pubspec workspaces feature. Reasoning: melos handles cross-package script execution, version pinning, and CI parallelization in ways the native workspace feature still doesn't fully cover.

The marketing site (Astro) is a sibling project — it does not need melos. It runs from its own `package.json` and is built/deployed by a separate CI workflow.

The Cloud Functions package is similarly isolated — TypeScript, npm, deployed via `firebase deploy --only functions`.

### Build pipeline (GitHub Actions)

Five workflows. Each runs on the appropriate path filter so changes to one component don't trigger irrelevant builds.

**`.github/workflows/ci-flutter.yml`** (runs on changes to `apps/**` or `packages/**`):
- Checkout
- Setup Flutter (pinned version)
- `melos bootstrap`
- `melos run analyze` (lint check across all Dart packages)
- `melos run test` (unit tests across customer_app, shopkeeper_app, lib_core)
- `melos run build_runner` (Freezed + Riverpod codegen)
- `flutter build apk --debug` for both apps (smoke test)
- Upload analysis report artifacts

**`.github/workflows/ci-marketing.yml`** (runs on changes to `sites/marketing/**`):
- Checkout
- Setup Node 22 LTS
- `npm ci`
- `npm run lint`
- `npm run build` (Astro static build)
- Upload `dist/` artifact

**`.github/workflows/ci-cloud-functions.yml`** (runs on changes to `functions/**`):
- Checkout
- Setup Node 22 LTS
- `npm ci`
- `npm run lint`
- `npm run build`
- `npm run test`

**`.github/workflows/ci-cross-tenant-test.yml`** (CRITICAL — runs on every PR to main, regardless of path):
- Checkout
- Setup Flutter + Firebase emulator
- Start Firestore emulator with security rules loaded
- Seed synthetic `shop_0` and `shop_1` tenants via `tools/seed_synthetic_shop_0.ts`
- Run `cross_tenant_integrity_test.dart` from `lib_core`
- Test attempts cross-tenant reads from `shop_1` context targeting `shop_0` documents
- Test FAILS LOUDLY if any cross-tenant read succeeds
- This is the R9 mitigation made operational

**`.github/workflows/deploy-staging.yml`** (manual trigger or main-branch merge):
- Builds all components
- Deploys Cloud Functions to `yugma-dukaan-staging`
- Deploys marketing site to `yugma-dukaan-staging` Hosting
- Updates Firestore rules + indexes
- Reports deployment status

**Free tier consumption:** GitHub Actions free tier is 2,000 minutes/month for private repos. The combined workflows here run ~5-10 minutes per PR. At ~30 PRs/month (small team velocity), that's 150-300 minutes. Well inside the free tier with substantial headroom for hotfixes and rebuilds.

---

## §4 — Auth Architecture

The single most architecturally interesting part of this system, and the part most exposed to elicitation findings R8 (Firebase quota uncertainty) and R12 (OTP cultural drop-off risk). The design must (a) work at one-shop scale today, (b) survive a Firebase pricing change tomorrow, and (c) survive customers who find phone OTP intrusive next quarter.

### The four flows

#### Flow 1 — First-time customer

```
                   Customer        customer_app           Firebase Auth          Firestore
                      │                  │                       │                    │
                      │ Open app         │                       │                    │
                      │─────────────────►│                       │                    │
                      │                  │ signInAnonymously()   │                    │
                      │                  │──────────────────────►│                    │
                      │                  │                       │                    │
                      │                  │     uid_anon          │                    │
                      │                  │◄──────────────────────│                    │
                      │                  │                       │                    │
                      │                  │ Read shop theme       │                    │
                      │                  │──────────────────────────────────────────►│
                      │                  │                       │                    │
                      │                  │     ShopThemeTokens   │                    │
                      │                  │◄──────────────────────────────────────────│
                      │                  │                       │                    │
                      │  ◄─── Browse curated shortlists, join DC, chat ───►          │
                      │                  │                       │                    │
                      │ "Place order"    │                       │                    │
                      │─────────────────►│                       │                    │
                      │                  │ verifyPhoneNumber()   │                    │
                      │                  │──────────────────────►│                    │
                      │                  │                       │                    │
                      │                  │   SMS OTP sent        │                    │
                      │                  │ ◄─── (Blaze quota) ───│                    │
                      │                  │                       │                    │
                      │ "234567"         │                       │                    │
                      │─────────────────►│                       │                    │
                      │                  │ confirmCode("234567") │                    │
                      │                  │──────────────────────►│                    │
                      │                  │                       │                    │
                      │                  │ linkWithCredential()  │                    │
                      │                  │ (Anonymous → Phone)   │                    │
                      │                  │──────────────────────►│                    │
                      │                  │                       │                    │
                      │                  │   uid_phone (=uid_anon, refresh token persisted)
                      │                  │◄──────────────────────│                    │
                      │                  │                       │                    │
                      │                  │ Update Customer doc   │                    │
                      │                  │ (verified phone, prior anon UID = same)    │
                      │                  │──────────────────────────────────────────►│
                      │                  │                       │                    │
                      │  ◄── UPI intent → payment confirm → VPA captured by ops ──►  │
                      │                  │                       │                    │
                      │                  │                       │                    │
```

The critical step is `linkWithCredential()`. Firebase Auth supports linking an Anonymous credential to a Phone credential without changing the UID. This means:

- The anonymous browse session, the Decision Circle state, the chat thread history, and the in-progress Project all carry forward to the verified session **without rewriting any document**.
- The Customer document's `uid` field stays the same; we only update `phoneNumber` and `phoneVerifiedAt`.
- Firestore security rules see the same UID before and after the upgrade — they just check whether the phone number is set.

#### Flow 2 — Returning customer (the silent sign-in)

```
                   Customer        customer_app          Firebase Auth (local)        Firestore
                      │                  │                       │                    │
                      │ Open app         │                       │                    │
                      │─────────────────►│                       │                    │
                      │                  │ getCurrentUser()      │                    │
                      │                  │──────────────────────►│                    │
                      │                  │                       │                    │
                      │                  │   refreshIdToken()    │                    │
                      │                  │ (silently, via cached │                    │
                      │                  │  refresh token)       │                    │
                      │                  │                       │                    │
                      │                  │   uid_phone (still valid)                  │
                      │                  │◄──────────────────────│                    │
                      │                  │                       │                    │
                      │                  │ Read Customer doc     │                    │
                      │                  │──────────────────────────────────────────►│
                      │                  │                       │                    │
                      │  ◄─── Resume past Project / continue browsing ───►            │
                      │                  │                       │                    │
                      │  NO SMS SENT. NO RE-AUTH CEREMONY.                            │
```

**This is the hard requirement Alok specified.** Firebase Auth's refresh token persists in secure local storage indefinitely under normal use. The `getCurrentUser()` call on app launch returns the previously authenticated user without any network round-trip beyond a token refresh. **The customer never sees an OTP screen on a returning visit unless they explicitly sign out, clear app data, or uninstall.**

SMS cost is therefore proportional to *unique new installs*, not to sessions. At one-shop scale with 200–500 unique new customers/month, we consume 2–5% of the 10k/month Blaze allowance.

#### Flow 3 — Shopkeeper ops sign-in

```
                Shopkeeper      shopkeeper_app          Firebase Auth          Firestore
                      │                  │                       │                    │
                      │ Open ops app     │                       │                    │
                      │─────────────────►│                       │                    │
                      │                  │ getCurrentUser()      │                    │
                      │                  │──────────────────────►│                    │
                      │                  │                       │                    │
                      │                  │   No user OR expired  │                    │
                      │                  │◄──────────────────────│                    │
                      │                  │                       │                    │
                      │                  │ signInWithGoogle()    │                    │
                      │                  │──────────────────────►│                    │
                      │                  │                       │                    │
                      │                  │  Google OAuth flow    │                    │
                      │                  │  (system browser)     │                    │
                      │                  │                       │                    │
                      │                  │   uid_google          │                    │
                      │                  │◄──────────────────────│                    │
                      │                  │                       │                    │
                      │                  │ Read shops/{shopId}/operators/{uid_google} │
                      │                  │──────────────────────────────────────────►│
                      │                  │                       │                    │
                      │                  │   Operator { role:    │                    │
                      │                  │     "bhaiya"          │                    │
                      │                  │     | "beta"          │                    │
                      │                  │     | "munshi"        │                    │
                      │                  │     | null }          │                    │
                      │                  │◄──────────────────────────────────────────│
                      │                  │                       │                    │
                      │  ◄── If operator exists → grant scoped access; else show error
                      │                  │                       │                    │
                      │  Returning sessions: refresh token, no re-auth                │
```

The shopkeeper, his son Aditya, and his munshi each have a Google account (anyone with a Play Store account does). On first ops-app open they sign in once with Google; on every subsequent open they're silently signed in. Their role (bhaiya / beta / munshi) is looked up from a Firestore `operators` document keyed by Google UID, enforcing role-based capabilities (only bhaiya can delete inventory; munshi can record udhaar payments but not modify shopkeeper profile; etc.).

#### Flow 4 — UID merger conflict handling

The edge case the brief flagged in §10's "what Winston needs to resolve next." What happens when:

1. A customer browses anonymously on Phone A → uid_anon_A
2. Same customer downloads the app on Phone B (new family phone) → uid_anon_B
3. On Phone B, they verify with the same phone number that was used to verify on Phone A → uid_phone (stored against the phone number, but the device session is uid_anon_B)

Firebase's standard `linkWithCredential` will *fail* in this scenario because the phone number is already linked to uid_anon_A, not uid_anon_B. The auth merger logic must handle this gracefully:

```dart
// In AuthProviderFirebase.upgradeToPhone()
try {
  final cred = PhoneAuthProvider.credential(
    verificationId: verificationId,
    smsCode: otp,
  );
  await currentAnonymousUser.linkWithCredential(cred);
  // Happy path: uid stays the same
} on FirebaseAuthException catch (e) {
  if (e.code == 'credential-already-in-use' || e.code == 'email-already-in-use') {
    // The phone number belongs to a different (existing) UID.
    // We must SIGN IN as that existing UID and forfeit the local anonymous one.
    final existingCred = e.credential;
    final existingUser = await FirebaseAuth.instance.signInWithCredential(existingCred);

    // Optionally: copy any local Decision Circle / Project draft state from
    // the orphaned anonymous session into the existing user's collections,
    // via a one-shot Cloud Function call.
    await _migrateAnonymousSessionState(
      fromUid: orphanedAnonUid,
      toUid: existingUser.user!.uid,
    );

    // The orphaned anonymous Customer document is marked for cleanup
    // (a scheduled Cloud Function deletes orphaned anonymous customers
    //  older than 30 days).
  } else {
    rethrow;
  }
}
```

This is the kind of edge case that bites hard if it isn't designed for upfront. I'm flagging it as a v1 implementation requirement, not a v1.5 polish item.

#### Flow 5 — Joining a Decision Circle as a second participant (v1.0.3 patch — Sally + frontend-design plugin convergent finding)

The earlier 4 flows assumed each customer is a single anonymous device. But the brief's Pariwar pillar describes multi-device families: a husband on his own phone joining his wife's Project, a daughter-in-law looking at the same Decision Circle from a different city. This flow specifies the auth path for that scenario.

```
   Customer A (wife)        wife's app          Cloud Function          Customer B (husband)        husband's app
        │                        │                       │                          │                       │
        │ Creates Project        │                       │                          │                       │
        │───────────────────────►│                       │                          │                       │
        │                        │ Anonymous Auth: uid_A │                          │                       │
        │                        │                       │                          │                       │
        │ Taps "Share with       │                       │                          │                       │
        │  family"               │                       │                          │                       │
        │───────────────────────►│                       │                          │                       │
        │                        │ generateWaMeLink({                               │                       │
        │                        │   shopId, projectId,                             │                       │
        │                        │   originalCustomerUid: uid_A                     │                       │
        │                        │ })                                               │                       │
        │                        │──────────────────────►│                          │                       │
        │                        │                       │ Mints opaque, signed     │                       │
        │                        │                       │ join token (HMAC, 7-day  │                       │
        │                        │                       │ expiry)                  │                       │
        │                        │   wa.me link with     │                          │                       │
        │                        │   join token in       │                          │                       │
        │                        │   query string        │                          │                       │
        │                        │◄──────────────────────│                          │                       │
        │                        │                       │                          │                       │
        │ Forwards link to       │                       │                          │                       │
        │ husband via WhatsApp   │                       │                          │                       │
        │ (out-of-band)          │                       │                          │                       │
        │ ─────────────────────────────────────────────────────────────────────────►│                       │
        │                        │                       │                          │ Taps wa.me link       │
        │                        │                       │                          │──────────────────────►│
        │                        │                       │                          │                       │ Anonymous Auth: uid_B
        │                        │                       │                          │                       │
        │                        │                       │                          │                       │ Reads join token
        │                        │                       │                          │                       │ from deep link
        │                        │                       │                          │                       │
        │                        │                       │ joinDecisionCircle({     │                       │
        │                        │                       │   joinToken,             │                       │
        │                        │                       │   joiningUid: uid_B      │                       │
        │                        │                       │ })                       │                       │
        │                        │                       │◄────────────────────────────────────────────────│
        │                        │                       │                          │                       │
        │                        │                       │ Validates token (HMAC,   │                       │
        │                        │                       │  not expired)            │                       │
        │                        │                       │                          │                       │
        │                        │                       │ Atomically appends       │                       │
        │                        │                       │ uid_B to:                │                       │
        │                        │                       │  - chat_threads          │                       │
        │                        │                       │    .participantUids      │                       │
        │                        │                       │  - decision_circles      │                       │
        │                        │                       │    .participants         │                       │
        │                        │                       │ (if DC enabled)          │                       │
        │                        │                       │                          │                       │
        │                        │                       │   { success, projectId } │                       │
        │                        │                       │─────────────────────────────────────────────────►│
        │                        │                       │                          │                       │
        │                        │                       │                          │ Husband can now read  │
        │                        │                       │                          │ + write the chat      │
        │                        │                       │                          │ thread per §6 rule    │
        │                        │                       │                          │ patch (participantUids│
        │                        │                       │                          │ array check)          │
```

**Critical properties:**

1. **Husband does NOT need to verify his phone.** Anonymous Auth is sufficient for participation. He only needs to phone-verify if HE personally commits to a separate Project of his own. His participation in the wife's Project is read+write but not commit-authoritative — only the original `customerUid` (uid_A) can transition the Project to `committed` state. The wife is the contractual customer of record; the husband is a participating viewer/discusser.

2. **Join tokens are signed and time-limited.** The `generateWaMeLink` Cloud Function (SAD §7 Function 2) is extended to also produce a join token: an HMAC-SHA256 signature over `{shopId, projectId, originalCustomerUid, expiresAt}` using a server-side secret stored in Firebase Functions config. The token expires after 7 days. Tampered or expired tokens are rejected with `permission-denied`.

3. **The `joinDecisionCircle` Cloud Function** (added to SAD §7 inventory as Function #6 — see below) is an HTTPS callable that takes the join token + the joining user's anonymous UID, validates the token, and atomically writes to both the chat thread's `participantUids` array and the Decision Circle document's `participants` array (if Decision Circle is enabled per the `decisionCircleEnabled` Remote Config flag).

4. **Cross-tenant integrity:** the Cloud Function asserts `joiningUid`'s `request.auth.uid` matches the function caller, and the join token's `shopId` matches the chat thread's `shopId`. A husband cannot use a token for shop_A to join a thread in shop_B.

5. **Read access enforcement:** §6 security rules (post-v1.0.2 patch) check `request.auth.uid in resource.data.participantUids` for chat thread reads. Once `joinDecisionCircle` writes the husband's UID to the array, the security rules grant him read access automatically.

6. **The husband does NOT see the wife's customer_memory document** — that remains operator-only per the original §5 schema and §6 rule. Customer memory is the shopkeeper's private notes, not part of the Decision Circle shared state.

This flow closes the architectural gap that Sally and the frontend-design plugin both flagged independently. It is a v1 implementation requirement, not v1.5 polish.

### The AuthProvider interface (R8 mitigation)

```dart
// packages/lib_core/lib/src/adapters/auth_provider.dart

abstract class AuthProvider {
  /// Currently authenticated user (anonymous, phone-verified, or Google).
  Stream<AppUser?> get authStateChanges;
  AppUser? get currentUser;

  /// Tier 0: anonymous browse session. Always available.
  Future<AppUser> signInAnonymous();

  /// Tier 1: upgrade an anonymous session to a phone-verified session.
  /// Implementations may use SMS OTP, WhatsApp OTP, email magic link,
  /// UPI VPA capture, or any other mechanism.
  Future<PhoneVerificationResult> requestPhoneVerification(String phoneE164);
  Future<AppUser> confirmPhoneVerification(String verificationId, String code);

  /// Tier 2: shopkeeper ops sign-in via Google.
  Future<AppUser> signInWithGoogle();

  /// Sign out and clear local refresh token.
  Future<void> signOut();
}

class AppUser {
  final String uid;
  final String? phoneNumber;
  final String? email;
  final bool isAnonymous;
  final bool isPhoneVerified;
  final DateTime? phoneVerifiedAt;
  // ...
}

class PhoneVerificationResult {
  final String verificationId;
  final Duration codeExpiry;
}
```

Four implementations live in `lib_core/src/adapters/`:

1. **`AuthProviderFirebase`** — default. Uses `firebase_auth` SDK. Anonymous + Phone + Google all routed through Firebase. The 10k/mo Blaze SMS quota is the cost ceiling.

2. **`AuthProviderMsg91Stub`** — v1 stub. Implements `requestPhoneVerification` against MSG91's HTTP API at ~₹0.20/SMS. Anonymous and Google sign-in delegate to a wrapped `AuthProviderFirebase` instance. Used if Firebase phone auth becomes unaffordable.

3. **`AuthProviderEmailMagicLinkStub`** — v1 stub. Implements `requestPhoneVerification` as a no-op and exposes a parallel `requestEmailMagicLink(email)` path for use cases where SMS is unavailable. Email is structurally weaker for this market but exists as a last-resort fallback.

4. **`AuthProviderUpiOnlyStub`** — v1 stub. Implements `requestPhoneVerification` as a no-op; verification happens later, when the UPI payment intent returns the payer's VPA. This is the R12 fallback if customers culturally reject OTP.

The runtime selection is controlled by a Remote Config feature flag (`auth_provider_strategy`) so the swap can happen without a new app build:

```dart
final strategy = remoteConfig.getString('auth_provider_strategy');
final authProvider = switch (strategy) {
  'firebase' => AuthProviderFirebase(),
  'msg91'    => AuthProviderMsg91(),
  'email'    => AuthProviderEmailMagicLink(),
  'upi_only' => AuthProviderUpiOnly(),
  _          => AuthProviderFirebase(),  // default
};
```

### Failure modes and the swap path

| Failure | Trigger | Swap action |
|---|---|---|
| Firebase 10k SMS quota turns out to be smaller, gone, or billed | `firebasePhoneAuthQuotaMonitor` Cloud Function alert at 80% consumption, OR billing dashboard shows non-zero spend | Flip Remote Config `auth_provider_strategy` from `firebase` to `msg91`. Existing Firebase phone-verified users continue working (their refresh tokens are still valid); new users go through MSG91. No app rebuild required. |
| Customers culturally reject OTP at commit (R12 — funnel drop-off > 30%) | Analytics on Project commit funnel; tracked weekly | Flip strategy to `upi_only`. The commit screen no longer asks for a phone number; payment proceeds directly via UPI intent, which captures the VPA on return. |
| Firebase Auth itself becomes unavailable in India (regulatory or service change) | Manual operational decision | Migrate to `email_magic_link` strategy and prompt all users to re-verify with email on next session. This is the most disruptive swap and is held in reserve. |

This adapter architecture costs maybe 3–4 days of upfront engineering work and pays for itself the first time any one of these triggers fires. It is the primary R8 mitigation Mary's elicitation report demanded.

---

## §5 — Firestore Schema

The schema is designed against three constraints simultaneously: (a) the Firestore Spark/Blaze free-tier daily read budget (50,000 reads/day), (b) the multi-tenant `shopId` scoping requirement, (c) the ≤30-reads-per-customer-session target. Every collection structure choice below is justified against at least one of these.

### Top-level vs. sub-collection decision

I considered three structural options:

1. **Pure top-level collections** with `shopId` as a field (e.g., `/projects/{projectId}` where each project doc has a `shopId` field).
2. **Pure sub-collections under shop** (e.g., `/shops/{shopId}/projects/{projectId}`).
3. **Hybrid** — frequently-queried-by-shop collections live as sub-collections; rarely-queried-cross-shop entities live at top level.

**My choice: hybrid, leaning sub-collection.** Sub-collections give us automatic `shopId` scoping in security rules (one less attack surface), simpler index design (composite indexes are scoped to a single sub-collection), and simpler query patterns (`firestore.collection('shops/$shopId/projects')` is unambiguous). The trade-off is that cross-shop analytics (e.g., "how many shops have >100 projects") requires collection-group queries, which need explicit indexes — but this only matters at the platform-operator level (Yugma Labs, not the shopkeeper) and is easy to add later.

**Top-level collections (3):**
- `/shops/{shopId}` — one document per shop, contains profile + ShopThemeTokens reference + feature flags
- `/users/{uid}` — minimal user profile (anonymous OR phone-verified OR Google), references back to shopId(s) the user has interacted with
- `/system/synthetic_shop_0_check` — single document used by the cross-tenant integrity test

**Sub-collections under `/shops/{shopId}/`:**
- `operators/{operatorUid}` — Google-signed-in operators (bhaiya, beta, munshi) with their roles
- `customers/{customerUid}` — Customer profiles (anonymous + phone-verified)
- `projects/{projectId}` — Orders (1-N line items)
- `inventory/{skuId}` — Inventory SKUs
- `curated_shortlists/{shortlistId}` — Occasion-based curated shortlists
- `decision_circles/{projectId}` — Decision Circle state (OPTIONAL — feature-flagged)
- `chat_threads/{projectId}` — Ramesh-bhaiya Ka Kamra threads (one per Project)
- `messages/{projectId}/messages/{messageId}` — Sub-sub-collection of chat messages
- `voice_notes/{voiceNoteId}` — Voice note metadata (audio file in Cloud Storage)
- `udhaar_ledger/{ledgerId}` — Accounting mirror documents (NOT lending instruments)
- `customer_memory/{customerUid}` — Shopkeeper's notes about a customer
- `golden_hour_photos/{photoId}` — Golden Hour SKU photos
- `feature_flags/runtime` — Per-shop feature flag overrides
- `feedback/{feedbackId}` — v1.0.4 patch — NPS survey submissions and burnout-telemetry samples (S4.17). Append-only; operators read aggregate, customers write their own.

### Document shapes (Freezed 3 / TypeScript-equivalent)

**Shop**
```typescript
{
  shopId: "ramesh-bhaiya-almirahs",         // matches doc ID, slug-based
  displayName: "रमेश भैया अल्मीरा भंडार",
  displayNameEnglish: "Ramesh Bhaiya Almirah Bhandar",
  ownerName: "TBD",                         // real shopkeeper name when known
  city: "Ayodhya",
  marketArea: "Harringtonganj",
  established: 2003,                        // year
  generationsInBusiness: 2,
  themeTokensRef: "shops/ramesh-bhaiya-almirahs/theme/current",
  whatsappNumber: "+91-XXXX-XXXXXX",
  upiVpa: "rameshbhaiya@upi",
  geoPoint: { lat: 26.7920, lng: 82.1947 },
  createdAt: <timestamp>,
  updatedAt: <timestamp>,
  isActive: true,
  isSyntheticTestTenant: false,             // true only for shop_0
  // v1.0.4 patch: shop lifecycle state (R16 + DPDP Act 2023 compliance, ADR-013).
  // Drives retention / notification / deletion behavior at §6 rule layer and
  // is swept nightly by §7 Function 8 `shopDeactivationSweep`.
  shopLifecycle: "active",                  // "active" | "deactivating" | "deactivated" | "retained_for_dpdp" | "purge_scheduled"
  shopLifecycleChangedAt: <timestamp>,      // when state last transitioned
  shopLifecycleReason: null,                // "shopkeeper_retired" | "business_closed" | "contract_terminated" | "data_deletion_request" | null
  dpdpRetentionUntil: null,                 // ISO timestamp; data kept read-only until this date for DPDP audit trail, then purged
}
```

**Operator**
```typescript
{
  uid: "<google-uid>",                      // matches doc ID
  shopId: "ramesh-bhaiya-almirahs",
  role: "bhaiya" | "beta" | "munshi",
  displayName: "Aditya",
  email: "aditya@gmail.com",
  joinedAt: <timestamp>,
  permissions: {
    canEditInventory: true,
    canApproveDiscounts: false,
    canRecordUdhaar: true,
    canDeleteOrders: false,
    canManageOperators: false              // bhaiya only
  },
  weeklyHoursCommitted: 20,                // honest expectation, not enforced
  lastActiveAt: <timestamp>
}
```

**Customer**
```typescript
{
  customerUid: "<firebase-uid>",            // matches doc ID; same UID before and after phone upgrade
  shopId: "ramesh-bhaiya-almirahs",
  isAnonymous: false,
  phoneNumber: "+91XXXXXXXXXX",             // null while anonymous
  phoneVerifiedAt: <timestamp>,             // null while anonymous
  vpaFromUpi: "customer@oksbi",             // captured at first UPI payment
  displayName: "TBD",                       // captured optionally during commit flow
  createdAt: <timestamp>,
  lastActiveAt: <timestamp>,
  totalProjectsCount: 1,                    // denormalized for ops dashboard
  totalLifetimeValue: 22000,                // denormalized, INR
  preferredLanguage: "hi",                  // "hi" or "en"
  // v1.0.4 patch — S4.18 repeat-customer event tracking. Capped last-10
  // array lets the ops dashboard and analytics triggers detect returning
  // customers in one document read instead of a collection query.
  previousProjectIds: [],                   // capped array, last 10 projectIds, most-recent-first
  // NOT a customer memory layer — that's the shopkeeper-side `customer_memory` collection
}
```

**Project (the central entity)**
```typescript
{
  projectId: "proj_<ulid>",
  shopId: "ramesh-bhaiya-almirahs",
  customerUid: "<firebase-uid>",
  state: "draft" | "negotiating" | "committed" | "paid" | "delivering" | "closed" | "cancelled",
  occasion: "shaadi" | "naya_ghar" | "dahej" | "replacement" | "general" | null,

  lineItemsCount: 2,                        // denormalized
  totalAmount: 22000,                       // INR, denormalized

  // v1.0.4 patch — Triple Zero / Differentiator #1 testability invariant.
  // amountReceivedByShop MUST equal totalAmount for every closed Project.
  // Any deviation is an architectural bug: Yugma Labs never intercepts,
  // skims, or commissions. The cross-tenant integrity test asserts
  // `amountReceivedByShop == totalAmount` on every closed project, which
  // makes the "zero commission" promise a machine-verifiable invariant,
  // not a marketing claim. If the math ever diverges, CI fails loudly.
  amountReceivedByShop: 22000,              // INR, denormalized; invariant: == totalAmount AT paid|closed (Phase 3, 2026-04-30)

  // Denormalized for ops dashboard read-budget efficiency
  customerDisplayName: "Sunita Devi",
  customerPhone: "+91XXXXXXXXXX",
  customerVpa: "customer@oksbi",

  // Denormalized chat metadata
  lastMessagePreview: "Bhaiya, polish kab tak ho jayega?",
  lastMessageAt: <timestamp>,
  unreadCountForShopkeeper: 1,
  unreadCountForCustomer: 0,

  // Decision Circle reference (null if feature flag is off)
  decisionCircleId: "dc_<ulid>" | null,

  // Udhaar ledger reference (null if fully paid up-front)
  udhaarLedgerId: "ud_<ulid>" | null,

  createdAt: <timestamp>,
  updatedAt: <timestamp>,
  committedAt: <timestamp>,                 // when state moved to "committed"
  paidAt: <timestamp>,                      // null until fully paid (incl. udhaar closure)
  deliveredAt: <timestamp>,
  closedAt: <timestamp>,
}
```

**LineItem (sub-document or sub-collection on Project)**
```typescript
// Embedded as an array on Project (not a sub-collection) for read efficiency
{
  lineItemId: "li_<ulid>",
  skuId: "sku_<ulid>",
  skuSnapshot: {                            // denormalized at the time of order
    name: "Steel Almirah 4-Door Brown",
    nameDevanagari: "स्टील अल्मीरा 4-दरवाज़ा भूरा",
    price: 14000,
    photoUrl: "https://res.cloudinary.com/...",
  },
  quantity: 1,
  finalPrice: 13500,                        // after negotiation
  notes: "Bhabhi-ji ne kaha thoda kam karo",
}
```

**Why embed LineItem?** A typical Project has 1–4 line items. Embedding avoids one extra collection read per Project view. The sku snapshot prevents the customer from being shown a different price later if the SKU's master price changes.

**InventorySku**
```typescript
{
  skuId: "sku_<ulid>",
  shopId: "ramesh-bhaiya-almirahs",
  name: "Steel Almirah 4-Door Brown",
  nameDevanagari: "स्टील अल्मीरा 4-दरवाज़ा भूरा",
  description: "Mazboot, taala bhi achha",
  category: "steel_almirah" | "wooden_wardrobe" | "modular" | "dressing" | "side_cabinet",
  material: "steel" | "wood_sheesham" | "wood_teak" | "ply_laminate",
  dimensions: { heightCm: 152, widthCm: 92, depthCm: 51 },
  basePrice: 14000,
  negotiableDownTo: 12500,                  // shopkeeper's floor
  inStock: true,
  stockCount: 3,                            // null if not tracked
  goldenHourPhotoIds: ["ghp_<ulid>", "ghp_<ulid>"],  // refs into golden_hour_photos
  fallbackPhotoUrls: ["https://...", "..."],
  voiceNoteIds: ["vn_<ulid>"],              // shopkeeper's voice note about this piece
  occasionTags: ["shaadi", "dahej"],        // which curated shortlists this belongs to
  createdAt: <timestamp>,
  updatedAt: <timestamp>,
  isActive: true,
}
```

**CuratedShortlist** (Ramesh-bhaiya ki pasand)
```typescript
{
  shortlistId: "sl_<ulid>",
  shopId: "ramesh-bhaiya-almirahs",
  occasion: "shaadi" | "naya_ghar" | "dahej" | "budget" | "replacement" | "ladies" | "gents",
  titleDevanagari: "शादी के लिए",
  titleEnglish: "For wedding",
  description: "Ramesh-bhaiya ki sabse pasand wali shaadi-grade almirahs",
  skuIdsInOrder: ["sku_a", "sku_b", "sku_c", "sku_d"],   // shopkeeper's curation order matters
  updatedAt: <timestamp>,
  isActive: true,
}
```

**DecisionCircle (OPTIONAL — feature-flagged)**
```typescript
{
  decisionCircleId: "dc_<ulid>",
  shopId: "ramesh-bhaiya-almirahs",
  projectId: "proj_<ulid>",
  participants: [                            // session-tracked, not account-tracked
    { sessionId: "ses_<ulid>", personaLabel: "bahu", deviceId: "<device>", lastSeenAt: <ts> },
    { sessionId: "ses_<ulid>", personaLabel: "mummy_ji", deviceId: "<device>", lastSeenAt: <ts> },
  ],
  currentActivePersona: "mummy_ji",
  uiTier: "elder_friendly" | "default",     // bigger fonts, slower pacing
  createdAt: <timestamp>,
  // CRITICAL: this entire document type can be deleted from the schema
  // without affecting any other collection. Project does NOT require it.
}
```

**ChatThread** (one per Project; messages live in a sub-sub-collection)
```typescript
// shops/{shopId}/chat_threads/{projectId}
{
  threadId: "<projectId>",                   // 1:1 with Project
  shopId: "sunil-trading-company",
  projectId: "proj_<ulid>",
  customerUid: "<uid>",                      // primary thread owner (the
                                              // anonymous UID that started the Project)
  // v1.0.2 patch: participantUids supports Decision Circle multi-device.
  // When a husband on a separate phone joins via a wa.me deep link, his
  // anonymous UID is appended here, granting him read+write access to
  // this thread without becoming the customerUid. Operators are NOT in
  // this array — they're authenticated via isOperatorOf(shopId) instead.
  participantUids: ["<customerUid>", "<husband-anon-uid>", "<bhabhi-anon-uid>"],
  messageCount: 12,                          // denormalized
  lastMessagePreview: "Polish kab?",
  lastMessageAt: <timestamp>,
  // Messages in: shops/{shopId}/chat_threads/{projectId}/messages/{messageId}
}
```

**Adding participants to a chat thread:** the customer who originally created the Project (and thus the chat thread) can add additional anonymous UIDs to `participantUids` via a `joinDecisionCircle()` Cloud Function call, triggered when another family member opens a `wa.me` deep link the original customer shared. The Cloud Function validates that the joining session has read access to the deep link's referenced Project, then appends the joining UID. This is the canonical "Decision Circle multi-device join" auth flow that SAD §4 originally did not specify — added in v1.0.2 patch per Sally and frontend-design plugin pushback.

**Message** (sub-sub-collection)
```typescript
// shops/{shopId}/chat_threads/{projectId}/messages/{messageId}
{
  messageId: "msg_<ulid>",
  threadId: "<projectId>",
  authorUid: "<uid>",
  authorRole: "customer" | "bhaiya" | "beta" | "munshi",
  type: "text" | "voice_note" | "image" | "system",
  textBody: "Polish kab tak ho jayega?",
  voiceNoteId: null,                         // ref into voice_notes if type=voice_note
  imageUrl: null,
  sentAt: <timestamp>,
  readByUids: ["<uid>", "<uid>"],
}
```

**VoiceNote**
```typescript
// shops/{shopId}/voice_notes/{voiceNoteId}
{
  voiceNoteId: "vn_<ulid>",
  shopId: "ramesh-bhaiya-almirahs",
  authorUid: "<bhaiya-uid>",
  authorRole: "bhaiya" | "beta",
  durationSeconds: 23,
  audioStorageRef: "shops/ramesh-bhaiya-almirahs/voice_notes/vn_<ulid>.m4a",  // Cloud Storage path
  audioSizeBytes: 187000,
  attachedTo: {
    type: "sku" | "project" | "customer" | "absence_status" | "shop_landing",
    refId: "<id>"
  },
  recordedAt: <timestamp>,
  transcript: null,                          // future v1.5 — nullable
}
```

**UdhaarLedger** (accounting mirror — note allowed and forbidden field names)
```typescript
// shops/{shopId}/udhaar_ledger/{ledgerId}
{
  ledgerId: "ud_<ulid>",
  shopId: "ramesh-bhaiya-almirahs",
  projectId: "proj_<ulid>",
  customerUid: "<uid>",
  initiatedBy: "<bhaiya-uid>",               // shopkeeper-initiated only — see ADR-010
  initiatedAt: <timestamp>,
  recordedAmount: 17000,                     // total amount the customer agreed to pay over time
  acknowledgedAt: <timestamp>,
  partialPaymentReferences: [
    { paymentId: "pay_<ulid>", amount: 5000, recordedAt: <ts>, method: "upi" | "cash" | "bank" },
    { paymentId: "pay_<ulid>", amount: 4000, recordedAt: <ts>, method: "cash" },
  ],
  runningBalance: 8000,                      // recordedAmount minus sum of partial payments
  closedAt: null,                            // becomes a timestamp when runningBalance hits 0
  notes: "Bhabhi ne kaha shaadi ke baad poora denge",  // shopkeeper's own note

  // FORBIDDEN FIELDS — these MUST NOT exist anywhere in the schema:
  // interest, interestRate, overdueFee, dueDate, lendingTerms,
  // borrowerObligation, defaultStatus, collectionAttempt
  // The integration test in cross_tenant_integrity_test.dart also asserts
  // that none of these field names exist on any UdhaarLedger document.
}
```

**CustomerMemory** (shopkeeper's private notes about a customer)
```typescript
// shops/{shopId}/customer_memory/{customerUid}
{
  customerUid: "<uid>",
  shopId: "ramesh-bhaiya-almirahs",
  notes: "Sunita didi ki saas ne 2019 mein humari Storwel li thi. Bahut khush.",
  relationshipNotes: "Sunita ki bahen Geeta bhi hamari customer hai (proj_xyz)",
  preferredOccasions: ["shaadi", "naya_ghar"],
  preferredPriceRange: { min: 12000, max: 25000 },
  firstSeenAt: <timestamp>,
  lastSeenAt: <timestamp>,
  totalProjectsLifetime: 3,
  notesUpdatedAt: <timestamp>,
}
```

**GoldenHourPhoto**
```typescript
// shops/{shopId}/golden_hour_photos/{photoId}
{
  photoId: "ghp_<ulid>",
  shopId: "ramesh-bhaiya-almirahs",
  skuId: "sku_<ulid>",
  capturedAt: <timestamp>,
  capturedByUid: "<uid>",
  cloudinaryPublicId: "shops/ramesh-bhaiya-almirahs/sku_xxx_golden",
  thumbnailUrl: "https://res.cloudinary.com/.../t_thumb",
  fullSizeUrl: "https://res.cloudinary.com/.../q_auto,f_auto",
  tier: "hero" | "working",                  // hero = curated golden hour; working = any-light fallback
  metadata: { lightCondition: "raking", timeOfDay: "14:47", monthCaptured: "april" },
}
```

**ShopThemeTokens**
```typescript
// shops/{shopId}/theme/current
{
  shopId: "ramesh-bhaiya-almirahs",
  brandName: "रमेश भैया अल्मीरा भंडार",
  logoUrl: "https://res.cloudinary.com/...",
  primaryColor: "#8B4513",                   // saddle brown — sheesham wood
  secondaryColor: "#D2691E",                 // chocolate
  accentColor: "#FFD700",                    // gold
  backgroundColor: "#FFF8DC",                // cornsilk warm
  textColor: "#2C1810",                      // dark wood
  fontFamilyDevanagariDisplay: "Tiro Devanagari Hindi",  // Phase 6 IR Check v1.2 / Brief v1.4 Constraint 4 — was stale "Noto Sans Devanagari"
  fontFamilyDevanagariBody: "Mukta",
  fontFamilyEnglishDisplay: "Fraunces",                   // italic cut
  fontFamilyEnglishBody: "EB Garamond",
  fontFamilyMono: "DM Mono",                              // numerals/timestamps
  greetingVoiceNoteId: "vn_greeting",
  shopkeeperFaceUrl: "https://res.cloudinary.com/...",
  taglineDevanagari: "हर शादी की पहली खुशी, यहाँ से",
  taglineEnglish: "Where every wedding's first joy begins",
  updatedAt: <timestamp>,
  version: 3,                                 // bump to invalidate client cache
}
```

**FeatureFlags**
```typescript
// shops/{shopId}/feature_flags/runtime
{
  shopId: "ramesh-bhaiya-almirahs",
  decisionCircleEnabled: true,               // R11 kill switch
  guestModeEnabled: true,                    // R11 kill switch (sub-feature)
  otpAtCommitEnabled: true,                  // R12 kill switch
  whatsappPrimaryChatEnabled: false,         // R13 kill switch (true = WhatsApp eats Firestore chat)
  authProviderStrategy: "firebase",          // "firebase" | "msg91" | "email" | "upi_only"
  mediaStoreStrategy: "cloudinary",          // "cloudinary" | "firebase" | "r2"
  voiceSearchEnabled: false,                 // v1.5+
  arPlacementEnabled: false,                 // v2+
  premiumPhoneAuthEnabled: false,            // future premium tier (currently moot)
  // v1.0.4 patch — Constraint 15 fallback + locale discipline (ADR-008).
  // When the Hindi-design-capacity hiring prerequisite cannot be met, the
  // team flips `defaultLocale` to "en" and the customer app boots in
  // English with a Hindi toggle instead of the default Hindi-first posture.
  // This is an architectural compatibility flag, not a product preference —
  // it lets v1 ship under the "English-first with Hindi toggle" scope
  // compromise Mary's brief §8 Constraint 15 explicitly permits.
  defaultLocale: "hi",                       // "hi" | "en"
  updatedAt: <timestamp>,
  updatedByUid: "<bhaiya-uid>",
}
```

**Feedback** (v1.0.4 patch — S4.17 NPS + burnout telemetry)
```typescript
// shops/{shopId}/feedback/{feedbackId}
{
  feedbackId: "fb_<ulid>",
  shopId: "sunil-trading-company",
  type: "customer_nps" | "customer_csat" | "shopkeeper_burnout_self_report" | "shopkeeper_usage_sample",
  authorUid: "<uid>",                        // customer OR operator (determines write rule)
  authorRole: "customer" | "bhaiya" | "beta" | "munshi",
  score: 8,                                  // 0-10 for NPS/CSAT, 1-5 for burnout self-report, null for passive usage sample
  textBody: "Sunil-bhaiya ne bahut madad ki", // optional free-text
  relatedProjectId: "proj_<ulid>" | null,    // for customer_nps — links to the Project being rated
  sampledAt: <timestamp>,
  metadata: {                                // passive usage-sample payload (shopkeeper_usage_sample only)
    sessionMinutes: 47,
    chatMessagesAnswered: 12,
    voiceNotesRecorded: 1,
    projectsTouched: 3,
  },
  createdAt: <timestamp>,
}
```

**Rule posture:** customers can `create` their own `customer_nps`/`customer_csat` documents; operators can `create` their own `shopkeeper_*` documents; both are immutable after create (no `update`). Operators of the shop can `read` all feedback for dashboarding; customers can read only their own. The `shopkeeper_burnout_self_report` + `shopkeeper_usage_sample` documents drive the §6 success-criterion "no shopkeeper burnout observed" check without relying on subjective self-report alone.

### Required composite indexes

Firebase will require us to declare indexes for any multi-field query. Initial index set (in `firestore.indexes.json`):

```json
{
  "indexes": [
    {
      "collectionGroup": "projects",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "state", "order": "ASCENDING" },
        { "fieldPath": "updatedAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "projects",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "customerUid", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "projects",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "occasion", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "messages",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "threadId", "order": "ASCENDING" },
        { "fieldPath": "sentAt", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "udhaar_ledger",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "closedAt", "order": "ASCENDING" },
        { "fieldPath": "runningBalance", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "inventory",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "isActive", "order": "ASCENDING" },
        { "fieldPath": "category", "order": "ASCENDING" }
      ]
    }
  ]
}
```

Additional indexes will be added as features land. The discipline: every query in the codebase must have a matching index, no exceptions, enforced via a CI check.

### Read budget per typical customer session

A typical customer session (browse → join Decision Circle → chat → commit → pay) reads approximately:

| Action | Reads | Notes |
|---|---|---|
| Boot: load Shop document | 1 | Cached after first read |
| Boot: load ShopThemeTokens | 1 | Cached, version-bumped on change |
| Boot: load FeatureFlags | 1 | Cached, fetched via Remote Config (not Firestore) |
| Browse: load 4 curated shortlists | 4 | One per occasion the customer might care about |
| Browse: load ~12 SKUs from active shortlist | 12 | Paginated; embedded sku snapshots avoid second-hop reads |
| Browse: load Golden Hour photos for visible SKUs | (in SKU doc, no extra read) | URLs are denormalized onto the SKU document |
| Open Project (or create new) | 1 | Project doc with embedded LineItems and denormalized customer/chat metadata |
| Open chat thread for the Project | 1 + ~10 messages | Message paginated by `limit(20)` |
| Decision Circle session state | (client-side, no Firestore) | Session state lives in Riverpod persistence |
| Customer's own profile (`Customer` doc) | 1 | Cached |
| **Total typical session reads** | **~28–32** | Comfortably inside 30-read target |

The 50,000-reads-per-day Firestore free quota at one-shop scale supports approximately **1,500 customer sessions per day** without overflow. Real volume at one-shop scale will be ~50–200 sessions per day. Headroom: 8–30×.

Any feature that pushes a typical session above 30 reads triggers a cost-design review. The Firestore schema is the budget; features fit the budget.

### Synthetic `shop_0` tenant

A second tenant document — `/shops/shop_0/` — is maintained continuously from day one of v1 development. It exists purely to exercise multi-tenant isolation. The seed script (`tools/seed_synthetic_shop_0.ts`) populates it with:

- 1 fake operator
- 1 fake customer
- 1 fake project with 1 line item
- 1 fake inventory SKU
- 1 fake chat thread with 2 messages
- 1 fake udhaar ledger entry
- 1 fake voice note metadata (audio file is a 1-second silence)
- 1 fake ShopThemeTokens document with deliberately ugly colors

The cross-tenant integrity test (`packages/lib_core/test/cross_tenant_integrity_test.dart`) does the following on every CI run:

1. Authenticates as a `shop_1` operator
2. Attempts to read every collection under `/shops/shop_0/`
3. Asserts that EVERY read fails with a `permission-denied` error
4. Attempts to write to every collection under `/shops/shop_0/`
5. Asserts that EVERY write fails

If any read or write succeeds, the test fails loudly and the CI build is blocked. This is the operational R9 mitigation.

---

## §6 — Security Rules

The Firestore security rules below enforce per-shop isolation, role-based ops access, anonymous-vs-phone-verified access tiers, and App Check on every operation.

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ─────────────────────────────────────────────────────────────────
    // Helper functions
    // ─────────────────────────────────────────────────────────────────

    function isAuthed() {
      return request.auth != null;
    }

    function appCheckPasses() {
      // App Check token must be present on every request
      return request.app != null;
    }

    function isAnonymous() {
      return isAuthed() && request.auth.token.firebase.sign_in_provider == 'anonymous';
    }

    function isPhoneVerified() {
      return isAuthed() && request.auth.token.phone_number != null;
    }

    function isGoogleAuthed() {
      return isAuthed() && request.auth.token.firebase.sign_in_provider == 'google.com';
    }

    function isOperatorOf(shopId) {
      return isGoogleAuthed() &&
        exists(/databases/$(database)/documents/shops/$(shopId)/operators/$(request.auth.uid));
    }

    function operatorRole(shopId) {
      return get(/databases/$(database)/documents/shops/$(shopId)/operators/$(request.auth.uid)).data.role;
    }

    function isBhaiyaOf(shopId) {
      return isOperatorOf(shopId) && operatorRole(shopId) == 'bhaiya';
    }

    function isCustomerOf(shopId) {
      return isAuthed() &&
        exists(/databases/$(database)/documents/shops/$(shopId)/customers/$(request.auth.uid));
    }

    function isOwnCustomerDoc(shopId, customerUid) {
      return request.auth.uid == customerUid;
    }

    // ─────────────────────────────────────────────────────────────────
    // Top-level collections
    // ─────────────────────────────────────────────────────────────────

    // Shop document is publicly readable (so the marketing site and customer
    // app can load shop branding without auth), but only operators can write.
    match /shops/{shopId} {
      allow read: if appCheckPasses();
      allow write: if appCheckPasses() && isBhaiyaOf(shopId);
    }

    // User collection is for the user's own profile only.
    match /users/{userId} {
      allow read, write: if appCheckPasses() && request.auth.uid == userId;
    }

    // System collection is read-only for clients; only Cloud Functions write.
    match /system/{doc} {
      allow read: if appCheckPasses();
      allow write: if false;  // Cloud Functions only, via admin SDK
    }

    // ─────────────────────────────────────────────────────────────────
    // Per-shop sub-collections
    // ─────────────────────────────────────────────────────────────────

    match /shops/{shopId}/operators/{operatorUid} {
      allow read: if appCheckPasses() && isOperatorOf(shopId);
      allow create, update: if appCheckPasses() && isBhaiyaOf(shopId);
      allow delete: if appCheckPasses() && isBhaiyaOf(shopId) &&
                       request.auth.uid != operatorUid;  // can't delete self
    }

    match /shops/{shopId}/customers/{customerUid} {
      // Customers can read/write their own document. Operators can read all.
      allow read: if appCheckPasses() &&
                     (isOwnCustomerDoc(shopId, customerUid) || isOperatorOf(shopId));
      allow create: if appCheckPasses() &&
                       request.auth.uid == customerUid &&
                       request.resource.data.shopId == shopId;
      allow update: if appCheckPasses() &&
                       (isOwnCustomerDoc(shopId, customerUid) || isOperatorOf(shopId));
      allow delete: if appCheckPasses() && isBhaiyaOf(shopId);
    }

    match /shops/{shopId}/projects/{projectId} {
      // Customers can read/write their own projects. Operators can read/write all.
      allow read: if appCheckPasses() &&
                     (resource.data.customerUid == request.auth.uid ||
                      isOperatorOf(shopId));
      allow create: if appCheckPasses() &&
                       isCustomerOf(shopId) &&
                       request.resource.data.customerUid == request.auth.uid &&
                       request.resource.data.shopId == shopId;
      allow update: if appCheckPasses() &&
                       (resource.data.customerUid == request.auth.uid ||
                        isOperatorOf(shopId));
      allow delete: if appCheckPasses() && isBhaiyaOf(shopId);
    }

    match /shops/{shopId}/inventory/{skuId} {
      // Inventory is publicly readable to customers, only operators write.
      allow read: if appCheckPasses();
      allow create, update: if appCheckPasses() && isOperatorOf(shopId);
      allow delete: if appCheckPasses() && isBhaiyaOf(shopId);
    }

    match /shops/{shopId}/curated_shortlists/{shortlistId} {
      allow read: if appCheckPasses();
      allow write: if appCheckPasses() && isOperatorOf(shopId);
    }

    match /shops/{shopId}/decision_circles/{circleId} {
      // Decision Circle is optional; access is project-scoped.
      allow read, write: if appCheckPasses() &&
        (resource == null ||
         get(/databases/$(database)/documents/shops/$(shopId)/projects/$(resource.data.projectId))
           .data.customerUid == request.auth.uid ||
         isOperatorOf(shopId));
    }

    match /shops/{shopId}/chat_threads/{threadId} {
      // v1.0.2 patch: chat threads now support Decision Circle multi-device
      // participants via the participantUids[] array. The original
      // customerUid is the thread owner; additional participants (e.g.,
      // husband on a separate phone joining via wa.me deep link) are
      // added to participantUids and gain read+write access.
      allow read: if appCheckPasses() &&
                     (resource.data.customerUid == request.auth.uid ||
                      request.auth.uid in resource.data.participantUids ||
                      isOperatorOf(shopId));
      allow create: if appCheckPasses() &&
                       (request.resource.data.customerUid == request.auth.uid ||
                        isOperatorOf(shopId));
      allow update: if appCheckPasses() &&
                       (resource.data.customerUid == request.auth.uid ||
                        request.auth.uid in resource.data.participantUids ||
                        isOperatorOf(shopId));
    }

    match /shops/{shopId}/chat_threads/{threadId}/messages/{messageId} {
      // v1.0.2 patch: messages readable by any participant in the
      // parent thread's participantUids array (Decision Circle multi-device
      // scenario), not just the original customerUid.
      allow read: if appCheckPasses() &&
                     (get(/databases/$(database)/documents/shops/$(shopId)/chat_threads/$(threadId))
                       .data.customerUid == request.auth.uid ||
                      request.auth.uid in get(/databases/$(database)/documents/shops/$(shopId)/chat_threads/$(threadId))
                       .data.participantUids ||
                      isOperatorOf(shopId));
      allow create: if appCheckPasses() &&
                       (request.auth.uid == request.resource.data.authorUid) &&
                       // Author must be either the thread owner, a listed
                       // participant, or an operator
                       (get(/databases/$(database)/documents/shops/$(shopId)/chat_threads/$(threadId))
                         .data.customerUid == request.auth.uid ||
                        request.auth.uid in get(/databases/$(database)/documents/shops/$(shopId)/chat_threads/$(threadId))
                         .data.participantUids ||
                        isOperatorOf(shopId));
      allow update, delete: if false;  // Messages are immutable once sent
    }

    match /shops/{shopId}/voice_notes/{voiceNoteId} {
      allow read: if appCheckPasses();  // Public — voice notes are part of catalog
      allow write: if appCheckPasses() && isOperatorOf(shopId);
    }

    match /shops/{shopId}/udhaar_ledger/{ledgerId} {
      // ONLY operators can read/write udhaar ledger entries.
      // The customer never sees the ledger directly — they see their own
      // running balance via a derived view in their Project document.
      allow read: if appCheckPasses() &&
                     (isOperatorOf(shopId) || resource.data.customerUid == request.auth.uid);
      allow create, update: if appCheckPasses() && isOperatorOf(shopId) &&
                               // CRITICAL: schema-level enforcement — forbid lending vocabulary
                               !('interest' in request.resource.data) &&
                               !('interestRate' in request.resource.data) &&
                               !('overdueFee' in request.resource.data) &&
                               !('dueDate' in request.resource.data) &&
                               !('lendingTerms' in request.resource.data) &&
                               !('borrowerObligation' in request.resource.data) &&
                               !('defaultStatus' in request.resource.data) &&
                               !('collectionAttempt' in request.resource.data);
      allow delete: if appCheckPasses() && isBhaiyaOf(shopId);
    }

    match /shops/{shopId}/customer_memory/{customerUid} {
      // Operator-only — this is shopkeeper's private notes.
      // Customers MUST NOT be able to read what the shopkeeper has written about them.
      allow read, write: if appCheckPasses() && isOperatorOf(shopId);
    }

    match /shops/{shopId}/golden_hour_photos/{photoId} {
      allow read: if appCheckPasses();
      allow write: if appCheckPasses() && isOperatorOf(shopId);
    }

    match /shops/{shopId}/theme/{themeDoc} {
      allow read: if appCheckPasses();
      allow write: if appCheckPasses() && isBhaiyaOf(shopId);
    }

    match /shops/{shopId}/feature_flags/{flagDoc} {
      allow read: if appCheckPasses();
      allow write: if appCheckPasses() && isBhaiyaOf(shopId);
    }

    // ─────────────────────────────────────────────────────────────────
    // v1.0.4 patch — Feedback collection (NPS + burnout telemetry, S4.17)
    // ─────────────────────────────────────────────────────────────────

    match /shops/{shopId}/feedback/{feedbackId} {
      // Operators read all feedback for their shop (dashboard + telemetry).
      // Customers read only their own feedback (no cross-customer visibility).
      allow read: if appCheckPasses() &&
                     (isOperatorOf(shopId) ||
                      (resource.data.authorUid == request.auth.uid &&
                       resource.data.authorRole == 'customer'));
      // Create: customer writes own customer_nps / customer_csat;
      //         operator writes own shopkeeper_burnout / usage_sample.
      allow create: if appCheckPasses() &&
                       request.resource.data.authorUid == request.auth.uid &&
                       request.resource.data.shopId == shopId &&
                       ((request.resource.data.type in ['customer_nps', 'customer_csat'] &&
                         isCustomerOf(shopId)) ||
                        (request.resource.data.type in ['shopkeeper_burnout_self_report', 'shopkeeper_usage_sample'] &&
                         isOperatorOf(shopId)));
      // Feedback is immutable once written.
      allow update, delete: if false;
    }

    // ─────────────────────────────────────────────────────────────────
    // v1.0.4 patch — Shop lifecycle / DPDP Act 2023 (R16, ADR-013)
    // ─────────────────────────────────────────────────────────────────
    //
    // When `shops/{shopId}.shopLifecycle` transitions from "active" to
    // "deactivating" or "deactivated", the rules above continue to apply
    // for read (so customers and operators can still access their own
    // data for the DPDP retention window), but client writes are frozen.
    // This is enforced by adding `shopIsWritable(shopId)` to every write
    // rule below as a PR follow-up during I6.4. Cloud Function 8
    // (`shopDeactivationSweep`, §7) owns all mutations while the shop
    // is not `active`, including scoped deletion at retention expiry.
    //
    // The rule file keeps this as a single helper function so the PR
    // follow-up is mechanical:
    //
    //   function shopIsWritable(shopId) {
    //     return get(/databases/$(database)/documents/shops/$(shopId))
    //              .data.shopLifecycle == 'active';
    //   }
    //
    // Every `allow create, update, delete` above MUST AND-gate on
    // `shopIsWritable(shopId)` before shipping I6.4. Tracked as a
    // non-optional acceptance criterion on the multi-tenant-scoping
    // PRD story. See ADR-013 for full lifecycle semantics.

    // ─────────────────────────────────────────────────────────────────
    // Default deny — anything not matched above is rejected
    // ─────────────────────────────────────────────────────────────────
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### Cross-tenant integrity test (pseudo-Dart)

```dart
// packages/lib_core/test/cross_tenant_integrity_test.dart

void main() {
  group('Cross-tenant integrity', () {
    late FakeFirebaseFirestore firestore;
    late FirebaseAuth auth;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      auth = MockFirebaseAuth();
      await seedSyntheticShops(firestore);  // creates shop_0 and shop_1
    });

    test('shop_1 operator cannot read any shop_0 document', () async {
      await auth.signInAsOperatorOf('shop_1');

      final collections = [
        'operators', 'customers', 'projects', 'inventory',
        'curated_shortlists', 'decision_circles', 'chat_threads',
        'voice_notes', 'udhaar_ledger', 'customer_memory',
        'golden_hour_photos', 'theme', 'feature_flags',
      ];

      for (final coll in collections) {
        final attempt = firestore
            .collection('shops/shop_0/$coll')
            .get();
        expect(
          () async => await attempt,
          throwsA(isA<FirebaseException>()
              .having((e) => e.code, 'code', 'permission-denied')),
          reason: 'shop_1 operator should NOT be able to read shop_0/$coll',
        );
      }
    });

    test('shop_1 operator cannot write to any shop_0 document', () async {
      await auth.signInAsOperatorOf('shop_1');

      final attempt = firestore
          .collection('shops/shop_0/inventory')
          .add({'shopId': 'shop_0', 'name': 'malicious'});

      expect(
        () async => await attempt,
        throwsA(isA<FirebaseException>()
            .having((e) => e.code, 'code', 'permission-denied')),
        reason: 'cross-tenant write must be rejected',
      );
    });

    test('udhaar ledger rejects forbidden lending vocabulary', () async {
      await auth.signInAsOperatorOf('shop_1');

      final attempt = firestore
          .collection('shops/shop_1/udhaar_ledger')
          .add({
            'shopId': 'shop_1',
            'recordedAmount': 10000,
            'interest': 100,  // FORBIDDEN
          });

      expect(
        () async => await attempt,
        throwsA(isA<FirebaseException>()
            .having((e) => e.code, 'code', 'permission-denied')),
        reason: 'forbidden lending vocabulary must be rejected at the rule layer',
      );
    });
  });
}
```

These three test cases are non-negotiable v1 acceptance criteria. They run on every CI build. They are the operational expression of R9 (multi-tenant isolation) and R10 (RBI defensive design).

---

## §7 — Cloud Functions Inventory

**Eight functions in v1** (v1.0.4 patch — was 6; added `mediaCostMonitor` and `shopDeactivationSweep`), all gen 2, all TypeScript, all deployed to each environment (dev/staging/prod) via `firebase deploy --only functions`.

### Function 1: `killSwitchOnBudgetAlert`

**Trigger:** Cloud Pub/Sub topic `budget-alerts` (subscribed to Cloud Billing budget alert)
**Runtime:** Node 22 LTS, 256 MB memory, 60s timeout
**Purpose:** Disable expensive resources when the $1/month budget cap is approached or exceeded

```typescript
// functions/src/kill_switch.ts
import { onMessagePublished } from 'firebase-functions/v2/pubsub';
import { logger } from 'firebase-functions/v2';
import * as admin from 'firebase-admin';

export const killSwitchOnBudgetAlert = onMessagePublished(
  {
    topic: 'budget-alerts',
    region: 'asia-south1',
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (event) => {
    const data = JSON.parse(
      Buffer.from(event.data.message.data, 'base64').toString()
    );

    const costAmount = data.costAmount as number;
    const budgetAmount = data.budgetAmount as number;
    const alertThresholdPercent = (costAmount / budgetAmount) * 100;

    logger.warn('Budget alert received', { costAmount, budgetAmount, alertThresholdPercent });

    // Always log to a known location for runbook visibility
    await admin.firestore()
      .collection('system')
      .doc('budget_alerts')
      .collection('history')
      .add({
        receivedAt: admin.firestore.FieldValue.serverTimestamp(),
        costAmount,
        budgetAmount,
        alertThresholdPercent,
      });

    // At 50% threshold: notify operators via FCM
    if (alertThresholdPercent >= 50) {
      await notifyOperators(`Budget alert: $${costAmount} of $${budgetAmount} consumed`);
    }

    // At 100% threshold: trigger kill-switch actions
    if (alertThresholdPercent >= 100) {
      logger.error('BUDGET CAP REACHED — triggering kill-switch actions');

      // 1. Flip all feature flags that drive billable services to "off"
      const shops = await admin.firestore().collection('shops').get();
      for (const shop of shops.docs) {
        await shop.ref.collection('feature_flags').doc('runtime').update({
          // Disable phone OTP (the most likely cost vector)
          otpAtCommitEnabled: false,
          authProviderStrategy: 'upi_only',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedByUid: 'system_kill_switch',
        });
      }

      // 2. Disable Cloud Functions concurrency (rate-limit further calls)
      // Done via runtime config update — outside this function's scope.

      // 3. Send urgent alert to Yugma Labs ops contact via SMS / email
      await sendUrgentAlert();
    }
  }
);
```

**Expected invocation rate:** 0–5 per month under normal operation. Each invocation costs ~50ms of compute, well within the Blaze free tier (2M invocations/mo, 400k GB-seconds/mo).

### Function 2: `generateWaMeLink`

**Trigger:** HTTPS callable
**Runtime:** Node 22 LTS, 256 MB memory, 30s timeout
**Purpose:** Construct a `wa.me` deep link that opens WhatsApp with a prefilled message containing structured Project context. Used by the CommsChannel adapter when falling back to WhatsApp.

```typescript
// functions/src/wa_me_link.ts
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

interface GenerateWaMeLinkRequest {
  shopId: string;
  projectId: string;
  initiatedByUid: string;
}

export const generateWaMeLink = onCall<GenerateWaMeLinkRequest>(
  {
    region: 'asia-south1',
    memory: '256MiB',
    timeoutSeconds: 30,
    enforceAppCheck: true,
  },
  async (request) => {
    const { shopId, projectId, initiatedByUid } = request.data;

    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Authentication required');
    }
    if (request.auth.uid !== initiatedByUid) {
      throw new HttpsError('permission-denied', 'UID mismatch');
    }

    // Read shop and project
    const shopDoc = await admin.firestore().doc(`shops/${shopId}`).get();
    const projectDoc = await admin.firestore()
      .doc(`shops/${shopId}/projects/${projectId}`)
      .get();

    if (!shopDoc.exists || !projectDoc.exists) {
      throw new HttpsError('not-found', 'Shop or project not found');
    }

    const shop = shopDoc.data()!;
    const project = projectDoc.data()!;

    // Build a structured prefilled message in Hindi
    const message = [
      `🛍️ ${shop.displayName}`,
      ``,
      `📋 ऑर्डर: ${projectId.slice(-6)}`,
      `💰 कुल: ₹${project.totalAmount.toLocaleString('en-IN')}`,
      `📦 सामान: ${project.lineItemsCount} पीस`,
      ``,
      `नमस्ते! मेरा यह ऑर्डर है। कृपया मदद करें।`,
    ].join('\n');

    const phone = shop.whatsappNumber.replace(/[^0-9]/g, '');
    const encoded = encodeURIComponent(message);
    const link = `https://wa.me/${phone}?text=${encoded}`;

    return { link };
  }
);
```

**Expected invocation rate:** ~50–200/day at one-shop scale. Well within free tier.

**v1.0.4 clarification (audit gap #6 — P2.9 wa.me one-tap fallback):** the prefilled WhatsApp message IS the Project context blob — it embeds the shop displayName, short projectId, total amount, and line item count server-side from authoritative Firestore data, so the receiver has enough context to continue the conversation without any client-side payload. If a future PRD story needs the shopkeeper side to reconstruct full Project state from the `wa.me` landing (deep-linking back into the ops app from a WhatsApp message), that story will extend this function to return `{link, projectContextBlobId}` where `projectContextBlobId` is a short-lived Firestore document the ops app resolves on landing. No change to this function is needed for P2.9 as written; the signature already satisfies the CommsChannel adapter's fallback contract in ADR-005.

### Function 3: `sendUdhaarReminder`

**Trigger:** Cloud Scheduler — daily at 09:00 IST
**Runtime:** Node 22 LTS, 512 MB memory, 5min timeout
**Purpose:** Scan udhaar ledger entries and send reminder push notifications via FCM. NOT a collection mechanism — it is a friendly nudge, framed as accounting hygiene.

```typescript
// functions/src/udhaar_reminder.ts
import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';

export const sendUdhaarReminder = onSchedule(
  {
    schedule: '0 9 * * *',  // 09:00 daily
    timeZone: 'Asia/Kolkata',
    region: 'asia-south1',
    memory: '512MiB',
    timeoutSeconds: 300,
  },
  async () => {
    const shopsSnapshot = await admin.firestore().collection('shops').get();

    for (const shopDoc of shopsSnapshot.docs) {
      const shopId = shopDoc.id;

      // Find ledger entries with running balance > 0 and last reminder > 7 days ago
      const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

      const openLedgers = await admin.firestore()
        .collection(`shops/${shopId}/udhaar_ledger`)
        .where('runningBalance', '>', 0)
        .where('closedAt', '==', null)
        .get();

      for (const ledger of openLedgers.docs) {
        const data = ledger.data();
        const lastReminder = data.lastReminderSentAt?.toDate();

        if (lastReminder && lastReminder > sevenDaysAgo) continue;

        // Get customer's FCM token
        const customerDoc = await admin.firestore()
          .doc(`shops/${shopId}/customers/${data.customerUid}`)
          .get();
        const fcmToken = customerDoc.data()?.fcmToken;

        if (!fcmToken) continue;

        // Send a friendly notification — NO lending language
        await admin.messaging().send({
          token: fcmToken,
          notification: {
            title: 'आपका khaata',
            body: `${shopDoc.data().displayName} में ₹${data.runningBalance} बाकी है`,
          },
          data: {
            shopId,
            ledgerId: ledger.id,
            type: 'udhaar_friendly_nudge',
          },
        });

        // Update last reminder timestamp
        await ledger.ref.update({
          lastReminderSentAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }
  }
);
```

**Expected invocation rate:** 1/day. Runs through ~5–20 ledger entries at one-shop scale. Well within free tier.

**v1.0.4 patch — RBI-defensive guardrails (finding F11, ADR-010 reinforcement):** the function body shown above is the v1.0.3 version. Before ship, add three RBI-defensive guardrails that make the reminder pattern indefensibly NOT collection activity under the Digital Lending Guidelines 2024 addendum:

1. **Shopkeeper-opt-in per ledger entry.** Add `reminderOptInByBhaiya: boolean` to the `UdhaarLedger` schema (§5). The function SKIPS any ledger where this flag is `false` or missing. The shopkeeper must affirmatively tap "Send friendly reminder" inside the ops app for each ledger entry; there is no blanket opt-in. This replicates the social gating of the offline udhaar system: the shopkeeper decides who gets nudged, per customer, per ledger.

2. **Lifetime reminder cap.** Add `reminderCountLifetime: number` (default 0) and `REMINDER_MAX_LIFETIME = 3` as a Cloud Function constant. After 3 reminders on a ledger, the function stops. Further nudges require shopkeeper action offline. This hard-caps the "persistent collection activity" shape that RBI guidelines flag.

3. **Cadence configurable by shopkeeper, not schedule-locked.** Replace the hard-coded 7-day `sevenDaysAgo` check with a per-ledger `reminderCadenceDays` field (default 14, minimum 7, maximum 30). The shopkeeper controls the pacing. This makes the cadence a social preference, not a collection schedule.

Updated pseudocode for the body of the loop:

```typescript
if (!data.reminderOptInByBhaiya) continue;
if ((data.reminderCountLifetime ?? 0) >= 3) continue;
const cadenceDays = data.reminderCadenceDays ?? 14;
const cadenceAgo = new Date(Date.now() - cadenceDays * 24 * 60 * 60 * 1000);
if (lastReminder && lastReminder > cadenceAgo) continue;
// ... send notification ...
await ledger.ref.update({
  lastReminderSentAt: admin.firestore.FieldValue.serverTimestamp(),
  reminderCountLifetime: admin.firestore.FieldValue.increment(1),
});
```

Add the three fields to the `UdhaarLedger` schema in §5:

```typescript
  reminderOptInByBhaiya: false,              // shopkeeper affirmative opt-in per ledger
  reminderCountLifetime: 0,                  // capped at 3
  reminderCadenceDays: 14,                   // shopkeeper-configurable, 7-30
```

These guardrails reinforce ADR-010's RBI-defensive posture at the runtime layer, matching the schema-level forbidden-fields defense. The lawyer review deferred per Brief §12 Step 0.9 now has a simpler job: validate screen copy, not runtime behavior.

### Function 4: `multiTenantAuditJob`

**Trigger:** Cloud Scheduler — daily at 02:00 IST
**Runtime:** Node 22 LTS, 1 GB memory, 9min timeout
**Purpose:** Sample documents across all shops and verify `shopId` consistency. Alert on any cross-tenant data leakage.

```typescript
// functions/src/multi_tenant_audit.ts
import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';

const COLLECTIONS_TO_AUDIT = [
  'projects', 'customers', 'inventory', 'chat_threads',
  'voice_notes', 'udhaar_ledger', 'customer_memory', 'golden_hour_photos',
];

export const multiTenantAuditJob = onSchedule(
  {
    schedule: '0 2 * * *',
    timeZone: 'Asia/Kolkata',
    region: 'asia-south1',
    memory: '1GiB',
    timeoutSeconds: 540,
  },
  async () => {
    const shopsSnapshot = await admin.firestore().collection('shops').get();
    const anomalies: any[] = [];

    for (const shopDoc of shopsSnapshot.docs) {
      const shopId = shopDoc.id;

      for (const collName of COLLECTIONS_TO_AUDIT) {
        // Sample up to 50 documents per collection
        const sample = await admin.firestore()
          .collection(`shops/${shopId}/${collName}`)
          .limit(50)
          .get();

        for (const doc of sample.docs) {
          const data = doc.data();
          if (data.shopId && data.shopId !== shopId) {
            anomalies.push({
              path: doc.ref.path,
              expectedShopId: shopId,
              actualShopId: data.shopId,
            });
          }
        }
      }
    }

    if (anomalies.length > 0) {
      await admin.firestore()
        .collection('system')
        .doc('audit_anomalies')
        .collection('history')
        .add({
          detectedAt: admin.firestore.FieldValue.serverTimestamp(),
          anomalies,
        });

      // Send alert to ops
      await sendUrgentAlert(`MULTI-TENANT BREACH: ${anomalies.length} anomalies`);
    }
  }
);
```

**Expected invocation rate:** 1/day. Reads ~400–800 documents per run (50 × 8 collections × 1–2 shops). Well within free tier even at shop #10+.

**v1.0.4 patch — scale-aware sampling (finding F7, What-If 100x stress test):** the naive `for shop in allShops` loop is fine at shop #1–10. At shop #100 it reads ~40,000 documents/day, consuming ~80% of the 50k/day Firestore free-read quota in a single overnight sweep. Before onboarding shop #20, change the loop to a **rotating 5-shop daily sample** so the audit coverage completes on a 5-day rolling window instead of every day:

```typescript
// At shop count >20, rotate: day-of-year % ceil(totalShops/5) selects the batch
const allShops = await admin.firestore().collection('shops').get();
const totalShops = allShops.docs.length;
const BATCH_SIZE = 5;
let shopsToAudit: typeof allShops.docs;
if (totalShops <= 20) {
  shopsToAudit = allShops.docs; // full sweep at small scale
} else {
  const dayOfYear = Math.floor((Date.now() - new Date(new Date().getFullYear(), 0, 0).getTime()) / 86400000);
  const batches = Math.ceil(totalShops / BATCH_SIZE);
  const offset = (dayOfYear % batches) * BATCH_SIZE;
  shopsToAudit = allShops.docs.slice(offset, offset + BATCH_SIZE);
}
```

At shop #1 the sweep is complete every day. At shop #100 the sweep takes 20 days to cover every shop but reads ~2,000 documents/day instead of 40,000. This keeps the audit job inside the same cost envelope across three orders of magnitude of tenant count.

### Function 5: `firebasePhoneAuthQuotaMonitor`

**Trigger:** Cloud Scheduler — every 6 hours
**Runtime:** Node 22 LTS, 256 MB memory, 60s timeout
**Purpose:** Query Firebase Auth admin SDK for daily SMS verification count and alert if approaching the 10,000/month threshold.

```typescript
// functions/src/phone_auth_quota_monitor.ts
import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';

export const firebasePhoneAuthQuotaMonitor = onSchedule(
  {
    schedule: 'every 6 hours',
    region: 'asia-south1',
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async () => {
    // Firebase Admin SDK doesn't directly expose phone auth count.
    // Workaround: maintain our own counter via a Firestore document
    // that gets incremented by a beforeUserCreated trigger.
    const counterDoc = await admin.firestore()
      .doc('system/phone_auth_counter')
      .get();

    const monthStart = new Date();
    monthStart.setDate(1);
    monthStart.setHours(0, 0, 0, 0);

    const data = counterDoc.data();
    const currentMonthCount = data?.[`${monthStart.toISOString().slice(0, 7)}`] ?? 0;

    const QUOTA_LIMIT = 10000;
    const WARN_AT = QUOTA_LIMIT * 0.8;  // 8000

    if (currentMonthCount >= WARN_AT) {
      await sendUrgentAlert(
        `Phone auth quota at ${currentMonthCount}/${QUOTA_LIMIT} (${Math.round(currentMonthCount/QUOTA_LIMIT*100)}%) — consider AuthProvider swap`
      );
    }

    if (currentMonthCount >= QUOTA_LIMIT) {
      // Auto-flip strategy to upi_only
      const shops = await admin.firestore().collection('shops').get();
      for (const shop of shops.docs) {
        await shop.ref.collection('feature_flags').doc('runtime').update({
          authProviderStrategy: 'upi_only',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedByUid: 'system_quota_monitor',
        });
      }
    }
  }
);
```

**Expected invocation rate:** 4/day. Each invocation reads 1 document. Trivial cost.

### Function 6: `joinDecisionCircle` (v1.0.3 patch — added per SAD §4 Flow 5)

**Trigger:** HTTPS callable
**Runtime:** Node 22 LTS, 256 MB memory, 30s timeout
**Purpose:** Validate a join token from a `wa.me` deep link and atomically add the joining customer's anonymous UID to the chat thread's `participantUids[]` array (and the Decision Circle document's `participants[]` array if Decision Circle is enabled). Per SAD §4 Flow 5, this is the canonical "Decision Circle multi-device join" auth flow.

```typescript
// functions/src/join_decision_circle.ts
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';

interface JoinDecisionCircleRequest {
  joinToken: string; // signed HMAC-SHA256 over {shopId, projectId, originalCustomerUid, expiresAt}
}

export const joinDecisionCircle = onCall<JoinDecisionCircleRequest>(
  {
    region: 'asia-south1',
    memory: '256MiB',
    timeoutSeconds: 30,
    enforceAppCheck: true,
    secrets: ['JOIN_TOKEN_HMAC_SECRET'],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Authentication required');
    }

    const { joinToken } = request.data;
    const joiningUid = request.auth.uid;

    // 1. Decode and validate the join token
    const [payloadBase64, signature] = joinToken.split('.');
    if (!payloadBase64 || !signature) {
      throw new HttpsError('invalid-argument', 'Malformed join token');
    }

    const expectedSignature = crypto
      .createHmac('sha256', process.env.JOIN_TOKEN_HMAC_SECRET!)
      .update(payloadBase64)
      .digest('hex');

    if (signature !== expectedSignature) {
      throw new HttpsError('permission-denied', 'Invalid join token signature');
    }

    const payload = JSON.parse(Buffer.from(payloadBase64, 'base64').toString());
    const { shopId, projectId, originalCustomerUid, expiresAt } = payload;

    if (Date.now() > expiresAt) {
      throw new HttpsError('deadline-exceeded', 'Join token expired');
    }

    // 2. Atomically append joiningUid to chat thread's participantUids array
    const chatThreadRef = admin
      .firestore()
      .doc(`shops/${shopId}/chat_threads/${projectId}`);

    await admin.firestore().runTransaction(async (txn) => {
      const snap = await txn.get(chatThreadRef);
      if (!snap.exists) {
        throw new HttpsError('not-found', 'Chat thread not found');
      }

      const data = snap.data()!;

      // Already a participant? Idempotent — return success without rewriting.
      if (data.participantUids?.includes(joiningUid)) {
        return;
      }

      // Verify the original customer UID matches the token
      if (data.customerUid !== originalCustomerUid) {
        throw new HttpsError(
          'permission-denied',
          'Token customer mismatch'
        );
      }

      // Append
      txn.update(chatThreadRef, {
        participantUids: admin.firestore.FieldValue.arrayUnion(joiningUid),
      });

      // 3. If Decision Circle is enabled, also append to the DC document
      const dcRef = admin
        .firestore()
        .doc(`shops/${shopId}/decision_circles/${projectId}`);
      const dcSnap = await txn.get(dcRef);
      if (dcSnap.exists) {
        txn.update(dcRef, {
          participants: admin.firestore.FieldValue.arrayUnion({
            sessionId: `ses_${joiningUid}`,
            personaLabel: 'guest', // husband joins as guest persona by default
            deviceId: 'wa_link_join',
            lastSeenAt: admin.firestore.FieldValue.serverTimestamp(),
          }),
        });
      }
    });

    return { success: true, projectId, shopId };
  }
);
```

**Expected invocation rate:** ~10–50/month at one-shop scale (multi-device families are a minority of customers). Well within free tier.

**Critical security properties:**
1. App Check enforced
2. Authentication required (joining UID must be a real Firebase Auth user)
3. HMAC signature validation prevents token forgery
4. Time-limited (7-day expiry) prevents stale token replay
5. Idempotent — repeated joins are no-ops
6. Cross-tenant safe — token's `shopId` must match chat thread's `shopId`
7. Original customer UID validation — token cannot be re-purposed for a different Project

This function closes the architectural gap that Sally and the frontend-design plugin both flagged independently for the Decision Circle multi-device scenario.

### Function 7: `mediaCostMonitor` (v1.0.4 patch — finding F2, audit gap #3)

**Trigger:** Cloud Scheduler — every 6 hours
**Runtime:** Node 22 LTS, 256 MB memory, 60s timeout
**Purpose:** Track MediaStore (Cloudinary + Cloud Storage) burn rate per shop and alert when approaching free-tier ceilings. Mirrors `firebasePhoneAuthQuotaMonitor` but for the media adapter surface. This is the audit-gap-#3 mitigation — §10 cost forecasting predicted Cloudinary would break first, but §7 had no programmatic monitoring for it. Function 7 closes that gap.

```typescript
// functions/src/media_cost_monitor.ts
import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';

// Cloudinary Free tier: 25 credits/month (1 credit = ~1000 transformations or ~1 GB bandwidth).
// Cloud Storage Free tier: 5 GB storage + 1 GB/day egress.
// Thresholds are per-shop; at shop #5-7 Cloudinary will break first (§10 forecast).

const CLOUDINARY_CREDITS_FREE = 25;
const CLOUDINARY_WARN_AT = 20;       // 80%
const CLOUDINARY_HARD_CAP = 25;      // 100%
const STORAGE_BYTES_FREE = 5 * 1024 * 1024 * 1024;
const STORAGE_WARN_AT = 4 * 1024 * 1024 * 1024; // 80%

export const mediaCostMonitor = onSchedule(
  {
    schedule: 'every 6 hours',
    region: 'asia-south1',
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async () => {
    // Maintain a counter document updated by the MediaStore adapter on every upload.
    // Client-side adapters increment `system/media_usage_counter/{shopId}` on upload success.
    // This function reads the counters and compares against thresholds.

    const shopsSnapshot = await admin.firestore().collection('shops').get();

    for (const shopDoc of shopsSnapshot.docs) {
      const shopId = shopDoc.id;
      const counterSnap = await admin.firestore()
        .doc(`system/media_usage_counter/${shopId}`)
        .get();

      const data = counterSnap.data() ?? {};
      const monthKey = new Date().toISOString().slice(0, 7);
      const cloudinaryCredits = data[`cloudinary_${monthKey}`] ?? 0;
      const storageBytes = data[`storage_${monthKey}`] ?? 0;

      // Cloudinary warn
      if (cloudinaryCredits >= CLOUDINARY_WARN_AT) {
        await sendUrgentAlert(
          `Shop ${shopId}: Cloudinary at ${cloudinaryCredits}/${CLOUDINARY_CREDITS_FREE} credits (${Math.round(cloudinaryCredits/CLOUDINARY_CREDITS_FREE*100)}%)`
        );
      }

      // Cloudinary hard cap — auto-flip to R2 strategy for the shop
      if (cloudinaryCredits >= CLOUDINARY_HARD_CAP) {
        await admin.firestore()
          .doc(`shops/${shopId}/feature_flags/runtime`)
          .update({
            mediaStoreStrategy: 'r2', // triggers MediaStore adapter swap on next client refresh
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedByUid: 'system_media_cost_monitor',
          });
      }

      // Storage warn
      if (storageBytes >= STORAGE_WARN_AT) {
        await sendUrgentAlert(
          `Shop ${shopId}: Cloud Storage at ${(storageBytes/1024/1024/1024).toFixed(1)} GB / 5 GB`
        );
      }
    }
  }
);
```

**Expected invocation rate:** 4/day. Each invocation reads N shops worth of counter documents (N=1 at one-shop scale). Trivial cost.

**Critical design properties:**
1. **Per-shop attribution.** Counters live under `system/media_usage_counter/{shopId}` so a cost spike is traceable to a specific tenant. At shop #20, Yugma Labs knows which shop's bill is about to break the envelope.
2. **Real-time kill-switch.** When Cloudinary hits the hard cap for a shop, the function writes directly to that shop's `feature_flags/runtime` document. The MediaStore adapter on the client listens to that doc via a Firestore real-time listener (NOT Remote Config) so the strategy swap takes effect within seconds, not 12 hours. This closes finding F9.
3. **Counter write path.** The MediaStore adapter itself (`media_store_cloudinary.dart`, `media_store_firebase.dart`) is responsible for incrementing the counter on every successful upload. The adapter's contract in ADR-006 is extended v1.0.4 to include this telemetry emission as a mandatory side effect — any new MediaStore implementation must wire the counter or the build fails CI.
4. **No new runtime service.** The counter is a Firestore document; no external metrics service; no cost.

This function, together with Function 5 (`firebasePhoneAuthQuotaMonitor`), gives Yugma Labs symmetric cost monitoring across the two free-tier ceilings the §10 forecast identified as the first to break. Audit gap #3 closed.

### Function 8: `shopDeactivationSweep` (v1.0.4 patch — finding F1, audit gap #2, R16, ADR-013, DPDP Act 2023)

**Trigger:** Cloud Scheduler — daily at 03:00 IST (after `multiTenantAuditJob`)
**Runtime:** Node 22 LTS, 1 GB memory, 9min timeout
**Purpose:** Execute the shop lifecycle state machine defined in the §5 `Shop.shopLifecycle` field. Handles the DPDP Act 2023 notification + retention + deletion sequence when a shop deactivates. This is the audit-gap-#2 mitigation.

```typescript
// functions/src/shop_deactivation_sweep.ts
import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';

// DPDP Act 2023 retention windows (set by Yugma Labs legal posture; may be tightened after lawyer review):
const NOTIFY_AFFECTED_WITHIN_DAYS = 7;        // customers must be notified within this
const RETENTION_WINDOW_DAYS = 180;            // data kept read-only for 6 months for audit trail
const PURGE_GRACE_DAYS = 30;                  // final warning window before hard delete

export const shopDeactivationSweep = onSchedule(
  {
    schedule: '0 3 * * *',
    timeZone: 'Asia/Kolkata',
    region: 'asia-south1',
    memory: '1GiB',
    timeoutSeconds: 540,
  },
  async () => {
    const db = admin.firestore();
    const nowMs = Date.now();

    // State 1: shopLifecycle == "deactivating" — transition to "deactivated",
    //          set retention timer, notify affected customers.
    const deactivating = await db.collection('shops')
      .where('shopLifecycle', '==', 'deactivating')
      .get();

    for (const shopDoc of deactivating.docs) {
      const shopId = shopDoc.id;
      const retentionUntil = new Date(nowMs + RETENTION_WINDOW_DAYS * 86400000);

      // Notify each customer with at least one Project in this shop
      const customers = await db.collection(`shops/${shopId}/customers`).get();
      for (const cust of customers.docs) {
        const fcmToken = cust.data().fcmToken;
        if (fcmToken) {
          await admin.messaging().send({
            token: fcmToken,
            notification: {
              title: 'महत्वपूर्ण सूचना',
              body: `${shopDoc.data().displayName} बंद हो रही है। आपका डेटा ${RETENTION_WINDOW_DAYS} दिन तक सुरक्षित रहेगा।`,
            },
            data: {
              shopId,
              type: 'dpdp_shop_deactivation_notice',
              retentionUntil: retentionUntil.toISOString(),
            },
          });
        }
      }

      await shopDoc.ref.update({
        shopLifecycle: 'deactivated',
        dpdpRetentionUntil: retentionUntil.toISOString(),
        shopLifecycleChangedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    // State 2: shopLifecycle == "deactivated" AND retention expired —
    //          transition to "purge_scheduled" (30-day grace) and notify one last time.
    const deactivated = await db.collection('shops')
      .where('shopLifecycle', '==', 'deactivated')
      .get();

    for (const shopDoc of deactivated.docs) {
      const data = shopDoc.data();
      const retentionUntil = data.dpdpRetentionUntil ? new Date(data.dpdpRetentionUntil) : null;
      if (!retentionUntil || retentionUntil.getTime() > nowMs) continue;

      const purgeAt = new Date(nowMs + PURGE_GRACE_DAYS * 86400000);
      await shopDoc.ref.update({
        shopLifecycle: 'purge_scheduled',
        shopLifecycleChangedAt: admin.firestore.FieldValue.serverTimestamp(),
        purgeScheduledFor: purgeAt.toISOString(),
      });
      // Final notification to customers (same pattern as above, with "30 days to export")
    }

    // State 3: shopLifecycle == "purge_scheduled" AND grace period expired —
    //          execute scoped deletion. This is a destructive operation; it runs
    //          under admin SDK with explicit path scoping to a single shop.
    const scheduled = await db.collection('shops')
      .where('shopLifecycle', '==', 'purge_scheduled')
      .get();

    for (const shopDoc of scheduled.docs) {
      const data = shopDoc.data();
      const purgeAt = data.purgeScheduledFor ? new Date(data.purgeScheduledFor) : null;
      if (!purgeAt || purgeAt.getTime() > nowMs) continue;

      const shopId = shopDoc.id;

      // Delete every sub-collection under shops/{shopId}/
      const subCollections = [
        'operators', 'customers', 'projects', 'inventory',
        'curated_shortlists', 'decision_circles', 'chat_threads',
        'voice_notes', 'udhaar_ledger', 'customer_memory',
        'golden_hour_photos', 'theme', 'feature_flags', 'feedback',
      ];
      for (const coll of subCollections) {
        await recursiveDelete(db, `shops/${shopId}/${coll}`);
      }

      // Delete Cloud Storage objects at shops/{shopId}/voice_notes/**
      const bucket = admin.storage().bucket();
      await bucket.deleteFiles({ prefix: `shops/${shopId}/` });

      // Finally delete the Shop document itself
      await shopDoc.ref.delete();

      // Write an audit log to system/dpdp_purge_audit for legal retention
      // (the audit log is itself retained beyond the shop and is legally required).
      await db.collection('system').doc('dpdp_purge_audit')
        .collection('history').add({
          shopId,
          purgedAt: admin.firestore.FieldValue.serverTimestamp(),
          retentionUntil: data.dpdpRetentionUntil,
          purgeScheduledFor: data.purgeScheduledFor,
          reason: data.shopLifecycleReason ?? 'unspecified',
        });
    }
  }
);

async function recursiveDelete(db: admin.firestore.Firestore, path: string): Promise<void> {
  // Uses the Firebase Admin SDK recursiveDelete for scoped, atomic cleanup
  await db.recursiveDelete(db.collection(path));
}
```

**Expected invocation rate:** 1/day. At one-shop scale, reads 1 Shop document per sweep. At shop #50, reads 50 — trivial. Deletion workload only when a shop transitions, which is expected <1/month even at shop #100.

**Critical design properties:**
1. **State machine is explicit and Firestore-native.** `shopLifecycle` transitions are owned solely by this function + `bhaiya`-invoked ops-app writes (the shopkeeper initiates deactivation via a Settings screen). No client-side mutation of `shopLifecycle` except the initial "active" → "deactivating" trigger.
2. **DPDP notification is bilingual and push-delivered.** Title/body are Hindi-first per Constraint 4; English translations live in the same FCM payload for users on `preferredLanguage: 'en'`.
3. **Retention window is configurable per shop.** `dpdpRetentionUntil` is stored as an ISO timestamp, so Yugma Labs legal can tighten or extend it per-shop if a lawyer review demands.
4. **Scoped deletion is atomic-per-shop.** The recursive delete uses `shops/{shopId}/` as the root path, which the multi-tenant schema guarantees is leak-free (by the §6 rule design + cross-tenant integrity test). There is no path for the sweep to accidentally delete another shop's data.
5. **Audit trail survives.** The `system/dpdp_purge_audit` collection is NOT deleted with the shop — it is a legal hold record Yugma Labs retains even after the shop is purged.
6. **Rule posture interlock.** The §6 security rule helper `shopIsWritable(shopId)` (added v1.0.4) freezes client writes as soon as `shopLifecycle` leaves `active`, so customers and operators cannot mutate data during the retention or purge windows. Reads continue under the normal rules for the retention window, then are denied once the shop document is deleted.

This function, together with the §5 `shopLifecycle` field and the §6 `shopIsWritable` helper, closes audit gap #2 (shop deactivation lifecycle). R16 mitigation moves from brief-acknowledged-risk to architectural-reality.

**Total Cloud Functions usage at one-shop scale (with v1.0.4 8-function inventory):**
- ~280–810 invocations/month (well within 2M free)
- ~170 GB-seconds compute/month (well within 400k free)
- Outbound networking: ~12 MB/month (well within 5 GB free)

**Cost: ₹0.**

---

## §8 — Multi-Tenant Theming Approach

Theming is the entry point for shop #2 onboarding. The architecture must allow a new shop to be added via a single Firestore document write (plus any custom assets in Cloudinary), with zero code changes and zero rebuilds.

### `ShopThemeTokens` document shape (already shown in §5, repeated here with annotations)

```typescript
{
  shopId: "ramesh-bhaiya-almirahs",       // Slug, also doc ID at /shops/{shopId}/theme/current
  brandName: "रमेश भैया अल्मीरा भंडार",   // Devanagari primary
  brandNameEnglish: "Ramesh Bhaiya Almirah Bhandar",
  logoUrl: "https://res.cloudinary.com/yugma/...",
  primaryColor: "#8B4513",                // Material 3 seed color
  secondaryColor: "#D2691E",
  accentColor: "#FFD700",
  backgroundColor: "#FFF8DC",
  textColor: "#2C1810",
  fontFamilyDevanagariDisplay: "Tiro Devanagari Hindi",  // Phase 6 IR Check v1.2 / Brief v1.4 Constraint 4 — was stale "Noto Sans Devanagari / Inter"
  fontFamilyDevanagariBody: "Mukta",
  fontFamilyEnglishDisplay: "Fraunces",                  // italic
  fontFamilyEnglishBody: "EB Garamond",
  fontFamilyMono: "DM Mono",
  greetingVoiceNoteId: "vn_greeting_v1",  // Reference into voice_notes collection
  shopkeeperFaceUrl: "https://res.cloudinary.com/.../face.jpg",
  taglineDevanagari: "हर शादी की पहली खुशी, यहाँ से",
  taglineEnglish: "Where every wedding's first joy begins",
  marketSubdomain: "ramesh-bhaiya-almirahs.yugmalabs.ai",
  updatedAt: <timestamp>,
  version: 3                              // Bumped to invalidate clients on hot-reload
}
```

### Boot-time loading sequence

```dart
// packages/lib_core/lib/src/theme/theme_loader.dart

class ThemeLoader {
  final String shopId;
  final FirebaseFirestore firestore;
  final SharedPreferences prefs;

  ThemeLoader({required this.shopId, required this.firestore, required this.prefs});

  /// Returns the theme tokens, preferring local cache, falling back to Firestore.
  /// Streams updates if the version bumps.
  Stream<ShopThemeTokens> load() async* {
    // 1. Yield cached version immediately if present
    final cached = _readFromCache();
    if (cached != null) yield cached;

    // 2. Subscribe to Firestore updates
    final docRef = firestore.doc('shops/$shopId/theme/current');
    yield* docRef.snapshots().map((snap) {
      if (!snap.exists) return _defaults();
      final tokens = ShopThemeTokens.fromJson(snap.data()!);
      _writeToCache(tokens);
      return tokens;
    });
  }

  ShopThemeTokens? _readFromCache() {
    final json = prefs.getString('theme_tokens_$shopId');
    if (json == null) return null;
    return ShopThemeTokens.fromJson(jsonDecode(json));
  }

  void _writeToCache(ShopThemeTokens tokens) {
    prefs.setString('theme_tokens_$shopId', jsonEncode(tokens.toJson()));
  }

  ShopThemeTokens _defaults() => ShopThemeTokens(
    shopId: shopId,
    brandName: 'दुकान',
    primaryColor: '#8B4513',
    // ... fallback values
  );
}
```

### Custom `ThemeExtension`

```dart
// packages/lib_core/lib/src/theme/theme_extension.dart

class YugmaThemeExtension extends ThemeExtension<YugmaThemeExtension> {
  final Color shopPrimary;
  final Color shopSecondary;
  final Color shopAccent;
  final Color shopBackground;
  final Color shopText;
  final String shopBrandName;
  final String shopFontFamilyDevanagari;
  final String shopFontFamilyEnglish;
  final String shopkeeperFaceUrl;
  final String taglineDevanagari;

  YugmaThemeExtension({
    required this.shopPrimary,
    required this.shopSecondary,
    // ...
  });

  factory YugmaThemeExtension.fromTokens(ShopThemeTokens tokens) {
    return YugmaThemeExtension(
      shopPrimary: Color(int.parse(tokens.primaryColor.substring(1), radix: 16) | 0xFF000000),
      shopSecondary: Color(int.parse(tokens.secondaryColor.substring(1), radix: 16) | 0xFF000000),
      // ...
    );
  }

  @override
  ThemeExtension<YugmaThemeExtension> copyWith({...}) { /* ... */ }

  @override
  ThemeExtension<YugmaThemeExtension> lerp(ThemeExtension<YugmaThemeExtension>? other, double t) {
    // Smooth interpolation when theme tokens hot-reload
  }
}
```

### Hot-reload behavior

When a shopkeeper updates `ShopThemeTokens` (e.g., via the ops app's settings screen), the `version` field bumps. All connected clients listening to `theme/current` receive the update via Firestore's real-time listener and rebuild the `MaterialApp` with the new `ThemeExtension`. Animations smooth-transition via the `lerp` method.

This is what enables a shopkeeper to change his shop's primary color in the ops app at 11 AM and see every customer's app update at 11:00:01 AM, no app restart required.

### Synthetic `shop_0` token blob

```typescript
// shops/shop_0/theme/current — used only for testing
{
  shopId: "shop_0",
  brandName: "TEST SHOP — DO NOT DISPLAY",
  primaryColor: "#FF00FF",  // deliberately ugly magenta
  secondaryColor: "#00FF00",  // ugly green
  // ... ugly values that should never appear in production UI
  version: 1
}
```

If shop_0 ever appears in a screenshot, the bug is obvious. The ugly colors are diagnostic.

### Onboarding flow for shop #2

When shop #2 (some future shopkeeper) onboards:

1. Yugma Labs creates a `/shops/<new-slug>` document in production Firestore
2. Creates `/shops/<new-slug>/theme/current` with the new shop's tokens
3. Creates `/shops/<new-slug>/operators/<google-uid>` for the new shopkeeper's Google account
4. Creates `/shops/<new-slug>/feature_flags/runtime` with default feature flag values
5. Configures DNS for `<new-slug>.yugmalabs.ai` to point at Firebase Hosting
6. Builds and deploys an Astro static marketing page for `<new-slug>` (one CI command, no code change)

**No customer app rebuild. No shopkeeper app rebuild. No Firestore migration. No security rule change.** The multi-tenant scaffolding just absorbs the new shop.

This is the strangler-fig pattern operationalized: the architecture supports shop #2 from day one, but v1 only fills it with shop #1.

---

## §9 — Offline Sync Strategy

Tier-3 4G connectivity is intermittent on a good day. The architecture treats offline as the default state and connectivity as a privilege, not the other way round.

### Two persistence layers (deliberately)

1. **Firestore offline persistence** (`PersistenceSettings(persistenceEnabled: true)`)
   - Built into `cloud_firestore` SDK
   - Automatically caches recently-read documents
   - Writes are queued locally and replayed when connectivity returns
   - Default cache size: 100 MB
   - Pros: Free, no extra package, transparent
   - Cons: Cache lifetime is tied to app install; clearing app data loses everything

2. **Riverpod 3 persistence layer** (via `riverpod_persistence` or `hive_ce`)
   - Persists Riverpod provider state across app launches
   - Includes UI state that Firestore doesn't (Decision Circle session persona, current Guest Mode, draft chat messages)
   - Survives app restart but not uninstall
   - Pros: Fine-grained control over what persists
   - Cons: Extra package, slightly more complex

**Why both?** Belt-and-suspenders. Firestore persistence handles document data; Riverpod persistence handles UI state. Together they make the app launch-time-zero-dependency on the network.

### What lives client-side only vs. server-synced

| Data | Persistence | Synced to Firestore? |
|---|---|---|
| Shop document | Firestore cache + Riverpod | ✅ Yes (read-only by client) |
| ShopThemeTokens | Firestore cache + Riverpod | ✅ Yes |
| Inventory SKUs (browsed by user) | Firestore cache | ✅ Yes |
| Curated shortlists | Firestore cache | ✅ Yes |
| Decision Circle session persona | Riverpod only | ❌ No |
| Guest Mode toggle state | Riverpod only | ❌ No |
| Draft chat message (typed but not sent) | Riverpod only | ❌ No |
| Sent chat message | Firestore cache + queued for upload | ✅ Yes |
| Project draft (before commit) | Firestore cache + Riverpod | ✅ Yes (with `state: draft`) |
| Voice note recording (in progress) | Local file system | ❌ Until finalized |
| Voice note (finalized) | Cloud Storage + Firestore metadata | ✅ Yes |
| UPI payment in flight | Riverpod only (until intent returns) | ❌ Until confirmed |

### Conflict resolution policy

**Firestore's default behavior is last-write-wins per document.** This is fine for 95% of our cases — most fields have a single writer (the shopkeeper or the customer, not both).

**Where it's NOT fine:**
- Chat messages: each message is its own document, immutable once written. No conflict possible.
- Project state transitions: only the operator can move a Project from `negotiating` → `committed`. Customer cannot. So no conflict.
- Inventory SKU updates: only operators can write. No conflict between operators is possible if they're on the same shop, since their writes are serialized through Firestore.
- Udhaar ledger payments: shopkeeper-initiated only. No customer write path.

**The one place conflicts can happen:** Customer and shopkeeper both updating the same `Project` document. Resolution: structure writes to be field-merging (`merge: true`), and use Firestore Transactions for any cross-field invariant updates.

**v1.0.4 patch — concrete field-partition policy (finding F8, audit gap #8).** Abstract "use `merge: true`" is not implementable by a PRD story author without knowing which fields each actor owns. The Project document is partitioned as follows; every repository method that writes to a Project MUST declare which partition it touches:

| Field | Owner | Written by |
|---|---|---|
| `state` | Operator | Shopkeeper ops app only (transitions `draft → negotiating → committed → paid → delivering → closed`) |
| `committedAt`, `paidAt`, `deliveredAt`, `closedAt` | Operator | Ops app, always with server timestamp |
| `totalAmount`, `amountReceivedByShop`, `lineItemsCount` | Operator | Ops app (price negotiation, line-item edits) |
| `lineItems[]` | Operator | Ops app |
| `customerDisplayName`, `customerPhone`, `customerVpa` | Operator | Ops app (from customer_memory or UPI intent return) |
| `occasion` | Customer | Customer app at Project creation, immutable after |
| `unreadCountForCustomer` | Customer | Customer app (reset on open) |
| `unreadCountForShopkeeper` | Operator | Ops app (reset on open) |
| `lastMessagePreview`, `lastMessageAt` | Either | Cloud Function triggered by new message write (neither client writes directly) |
| `decisionCircleId`, `udhaarLedgerId` | Operator | Ops app |
| `createdAt`, `updatedAt` | Either | `updatedAt` uses `FieldValue.serverTimestamp()` on every write regardless of actor |

**Offline write discipline.** When customer-app writes queue during offline, they touch ONLY customer-owned fields. When ops-app writes queue during offline, they touch ONLY operator-owned fields. Repository methods enforce this at compile time via Freezed sealed unions (`ProjectCustomerPatch` / `ProjectOperatorPatch` / `ProjectSystemPatch` — the third variant is Cloud-Function-owned, covering `lastMessagePreview` / `lastMessageAt` / `updatedAt`) — a repository method cannot construct a patch that touches the wrong partition. *(Phase 6 IR Check v1.2 patch 2026-04-11: naming corrected from stale "`CustomerProjectPatch` vs `OperatorProjectPatch`" to the canonical downstream naming used in PRD Standing Rule 11, Epics List §11 item 11, I6.12, and the bundle's `components_library.dart` comments. The `ProjectSystemPatch` third variant was implicit in the original design and is now explicit. The same sealed-union discipline extends to `ChatThread` and `UdhaarLedger` per PRD Standing Rule 11.)* This guarantees that field-merge semantics ARE always conflict-free, not just "usually conflict-free." The one remaining cross-partition write — `state: draft → cancelled` by either side — uses a Firestore Transaction with an `if-not-committed` precondition.

**Multi-day offline replay invariants.**
1. A customer offline for 3 days cannot inadvertently revert operator state by replaying stale writes — the partition prevents it.
2. An operator offline for 3 days cannot overwrite customer messages or unreadCountForCustomer — same reason.
3. `lastMessageAt` always advances monotonically because the new-message Cloud Function uses `FieldValue.serverTimestamp()` and a transaction `get` before set.
4. `amountReceivedByShop` cannot be written by the customer at all, so the Triple Zero invariant from §5 is immune to offline replay attacks.

This is concrete enough that a PRD story author can write acceptance criteria against it. Audit gap #8 closed.

Example:
```dart
// Bad: overwrites entire document
await projectRef.set(updatedProject);

// Good: merges fields, preserves concurrent writes to other fields
await projectRef.set(updatedProject, SetOptions(merge: true));

// Best for invariant-preserving updates: transaction
await firestore.runTransaction((txn) async {
  final snap = await txn.get(projectRef);
  final current = Project.fromJson(snap.data()!);
  if (current.state != 'draft') {
    throw 'Cannot finalize a non-draft project';
  }
  txn.update(projectRef, {'state': 'committed', 'committedAt': FieldValue.serverTimestamp()});
});
```

### Multi-day no-connectivity behavior

The customer is in a village with no signal for 3 days. What works?

- **Browse cached inventory:** ✅ Yes. Last-fetched SKUs and shortlists are in the Firestore cache.
- **View past chat messages:** ✅ Yes. Cached.
- **Type new chat messages:** ✅ Yes. Stored in Riverpod persistence as drafts. Sent when connectivity returns.
- **Create a new Project (browse, add line items):** ✅ Yes. Stored in Firestore cache as a draft document. Replays to server when connectivity returns.
- **Receive new shopkeeper voice notes:** ❌ No. Voice note audio files in Cloud Storage need network. Voice note metadata syncs when connectivity returns.
- **Verify phone with OTP:** ❌ No. SMS requires connectivity. UI gracefully shows "phone verification will retry when online."
- **Pay via UPI:** ❌ No. UPI intent requires the bank's PSP to be reachable. UI shows "payment will be available when online."
- **Receive push notifications:** ❌ No. FCM needs network.

**What does NOT work that the user might expect to:** Decision Circle real-time collaboration with another family member on a different device. Real-time collaboration requires network. Offline, the Decision Circle becomes a single-device session.

### Sync resume logic

When connectivity returns:

1. Firestore SDK automatically replays any queued writes
2. Riverpod persistence layer detects connectivity change (via `connectivity_plus`) and triggers a refresh of all relevant providers
3. A `syncStatus` provider exposes the sync state (idle / syncing / error) so the UI can show a small banner ("नेटवर्क वापस — डेटा अपडेट हो रहा है")
4. If any queued write fails (e.g., a security rule change rejected it), the user sees an error and the document is marked dirty for manual resolution

The sync resume is transparent to the user 99% of the time. The 1% case (failed write) is handled by a clear error UI, not silent data loss.

---

## §10 — Cost Forecasting Model

Triple Zero is a posture, not a permanent property. The brief's R3 explicitly notes this. The forecast below models the inflection points where the posture starts to bend.

### Per-shop monthly cost forecast

Assumptions:
- Each shop generates ~110 leads/month, ~45 orders/month, ~300 unique new customer installs/month (per Step 0.3 working defaults)
- Each customer session reads ~30 Firestore documents
- Each customer session writes ~5 Firestore documents (chat messages, project updates, customer doc)
- Catalog: ~150 SKUs per shop, ~3 photos per SKU = 450 Cloudinary images, transformed ~5x each = 2250 transformations/month
- Voice notes: ~30 per shop per month, ~200 KB each = 6 MB/month per shop
- Cloud Functions: ~700 invocations/month per shop

| Scale | Firestore reads/day | Firestore writes/day | Storage GB | Cloud Functions inv/mo | Phone Auth SMS/mo | Cloudinary credits/mo | Total monthly cost |
|---|---|---|---|---|---|---|---|
| **Shop #1** | ~1,500 | ~250 | <0.5 | ~700 | ~300 | ~5 | **₹0** |
| **Shop #5** | ~7,500 | ~1,250 | ~2.5 | ~3,500 | ~1,500 | ~25 | **₹0** |
| **Shop #10** | ~15,000 | ~2,500 | ~5 | ~7,000 | ~3,000 | ~50 (overage 25) | **~₹350** (Cloudinary) |
| **Shop #20** | ~30,000 | ~5,000 | ~10 | ~14,000 | ~6,000 | ~100 (overage 75) | **~₹1,050** |
| **Shop #25** | ~37,500 | ~6,250 | ~12.5 | ~17,500 | ~7,500 | ~125 (overage 100) | **~₹1,400 + Storage overage starts** |
| **Shop #33** | ~49,500 | ~8,250 | ~16.5 | ~23,000 | ~10,000 (quota saturated) | ~165 (overage 140) | **~₹2,050 + first SMS overage at ~₹85/mo for shop #33's first overflow customers** |
| **Shop #50** | ~75,000 (Firestore overage starts) | ~12,500 | ~25 | ~35,000 | ~15,000 (5,000 overage) | ~250 (overage 225) | **~₹6,500–8,000 total platform cost** |

### Where each line item breaks first

| Line item | Free ceiling | Breaks at shop # |
|---|---|---|
| **Cloudinary credits** | 25/mo | **#5–7** (the first thing to overflow) |
| **Phone auth SMS** | 10,000/mo | **#33** |
| **Firestore reads** | 50,000/day | **#33** |
| **Firestore writes** | 20,000/day | **~#80** (a long way out) |
| **Cloud Storage** | 5 GB | **~#400** (almost never relevant) |
| **Cloud Functions** | 2M inv/mo, 400k GB-s | **~#100–200** |
| **Hosting** | 10 GB/mo transfer | **~#50** |

**Cloudinary breaks first.** This is the surprising finding. Image storage and bandwidth scale linearly with catalog size and customer page views. By shop #5–7, Cloudinary's free tier is exhausted and we either upgrade to Cloudinary's $99/mo plan or migrate to Cloudflare R2 (which has unlimited egress at $0.015/GB storage).

**Yugma Labs' SaaS pricing math:**
- If Yugma charges shops a flat ₹500/month, the contribution margin per shop becomes positive at shop #2 and grows linearly until shop #20 where Cloudinary overage starts eating into it.
- At shop #50, total platform cost is ~₹7,000/mo. ₹500 × 50 = ₹25,000 revenue. Margin: 72%. Healthy.
- At shop #100, the math depends entirely on whether we've migrated to R2. If yes, margin stays >70%. If no, margin compresses to <40%.

**The migration trigger:** The MediaStore adapter's R2 implementation should be activated at shop #20, before Cloudinary overage hits painful levels. This is the v1.5/v2 work the brief's R3 references.

**Summary for Alok:** Triple Zero literal ₹0 holds at shop #1. From shop #5–7 onwards, there's a small Cloudinary line item that grows linearly. At shop #33 phone auth SMS quota saturates and adds another small line item. The full SaaS unit economics work cleanly through shop #50–100 if the MediaStore adapter swap to R2 happens at shop #20. **The architecture is sound for the first ~50 shops.** Beyond that, real cost engineering work begins.

---

## §11 — Architecture Decision Records

Each ADR uses the format: Title / Status / Context / Decision / Consequences / Alternatives / Decided By / Date.

### ADR-001: Firebase Blaze with $1 budget cap as backend

**Status:** Accepted
**Context:** Brief §8 Constraint 3 (₹0 ops cost), Constraint 6 (Firebase + free services only), R8 (phone auth quota uncertainty).
**Decision:** Use Firebase Blaze plan (not Spark) with a hard $1/month budget cap and a kill-switch Cloud Function. Three projects: dev, staging, prod.
**Consequences:** Spark plan cannot deploy Cloud Functions in production, so Blaze is required. The $1 cap is a paranoid safety rail; expected spend is ₹0 at one-shop scale per the §10 forecast. Three projects mean three separate Firebase configurations, three separate billing dashboards, but cleaner isolation and easier disaster recovery.
**Alternatives considered:**
- *Spark plan only:* rejected — cannot deploy Cloud Functions
- *Single Firebase project with environment namespacing:* rejected — too easy to confuse dev and prod data; rejected for safety
- *Supabase free tier:* rejected — pauses on inactivity (a deal-breaker for a low-traffic shop)
- *Self-hosted Pocketbase on Oracle Always Free:* rejected — single point of failure, ops burden
**Decided by:** Winston, validated by Alok via shape-first phase
**Date:** 2026-04-11

### ADR-002: Layered Anonymous + Phone Auth with session persistence + AuthProvider adapter

**Status:** Accepted
**Context:** Brief §3 Bharosa pillar requires customer trust ceremony at commit; brief §8 Constraint 4 requires Hindi-first low-friction flows; R8 requires the auth provider to be swappable; R12 requires graceful fallback if customers reject OTP; founder explicitly required session persistence (one OTP per install, never re-authenticate on subsequent opens).
**Decision:** Three-tier auth: Anonymous Auth (Tier 0), Phone OTP at commit moment (Tier 1) with refresh-token session persistence, Google Sign-In on shopkeeper ops side (Tier 2). All three behind a single `AuthProvider` Dart interface with four implementations (Firebase, MSG91 stub, email magic link stub, UPI-only stub). Runtime selection via Remote Config flag `auth_provider_strategy`.
**Consequences:** ~3-4 days extra engineering for the adapter pattern. Pays for itself the first time the Firebase quota changes or customers reject OTP. Survives R8 and R12 without app rebuild.
**Alternatives considered:**
- *Phone-only auth (no Anonymous tier):* rejected — adds friction to the browse phase
- *Anonymous-only (no phone verification ever):* rejected — customer trust ceremony at commit is a brief requirement
- *Direct Firebase Auth without adapter:* rejected — locks us to Firebase's pricing and policy decisions forever
**Decided by:** Winston, validated by Alok
**Date:** 2026-04-11

### ADR-003: Multi-tenant from day 1 with synthetic shop_0 (NOT single-tenant first)

**Status:** Accepted (with pushback acknowledged)
**Context:** Brief §8 Constraint 7 requires multi-tenant architecture underneath single-tenant experience. Elicitation pre-mortem #11 warned that pre-mature multi-tenancy is a 6-week tax that may pay off only at shop #2 — and shop #2 might never come. R9 warned that the first multi-tenant flip-switch will surface bugs that ship in front of paying customers.
**Decision:** Multi-tenant from day 1, but with two structural mitigations: (a) `shopId` is a field on every document, not a separate database, keeping the tax small; (b) a synthetic `shop_0` tenant is maintained continuously from day one of v1 development, with a cross-tenant integrity test running on every CI build. This pulls the multi-tenant bug surface forward to development time.
**Consequences:** Slightly more careful schema design (every collection thinks about `shopId` from day one). One extra CI test (~30 seconds runtime). One extra seed script. The "6-week multi-tenant tax" the elicitation warned about is largely mitigated because we don't build a separate tenant infrastructure — we just enforce a discipline.
**Alternatives considered:**
- *Single-tenant first, refactor for shop #2:* rejected — Mary's brief explicitly mandates multi-tenant scaffolding from day one, AND the refactor cost would be larger than the discipline cost
- *Per-shop separate Firestore database:* rejected — Firestore doesn't natively support multi-database, would require multiple Firebase projects per shop, expensive
**Decided by:** Winston (with explicit acknowledgment of pre-mortem #11 concern), validated by Alok
**Date:** 2026-04-11

### ADR-004: Riverpod 3 + GoRouter + Material 3 + Freezed 3 stack

**Status:** Accepted
**Context:** Brief §10 specifies these as the locked stack. Tech research subagent confirmed Riverpod 3 is the 2026 default for new projects with offline persistence built in. GoRouter is the official Flutter navigation. Material 3 is the stable design system. Freezed 3 is still the standard for immutable data classes.
**Decision:** Use Riverpod 3 with `riverpod_generator` for state management, GoRouter for navigation, Material 3 for theming with custom `ThemeExtension` for shop tokens, Freezed 3 + `build_runner` for data classes.
**Consequences:** Mature, well-supported, well-documented stack. AI-coding-tool support (Claude Code MCP, Cursor) is excellent for this stack. New team members can ramp in days.
**Alternatives considered:**
- *Bloc:* rejected — heavier ceremony, slower velocity for a small team
- *Provider:* rejected — superseded by Riverpod
- *auto_route:* rejected — GoRouter has closed the gap and is official
- *forui or shadcn_flutter:* rejected — pre-1.0, API churn risk
**Decided by:** Winston, validated by Alok
**Date:** 2026-04-11

### ADR-005: WhatsApp wa.me deep links in v1 + CommsChannel adapter for future swap

**Status:** Accepted
**Context:** Brief §10 explicitly defers WhatsApp Business Cloud API in v1 due to per-message cost. R5 warns that WhatsApp policies can change. R13 warns that WhatsApp may eat the in-app chat entirely.
**Decision:** v1 uses `wa.me` deep links exclusively (free, no API, no per-message cost). The `CommsChannel` adapter provides a Firestore real-time chat as the default and a WhatsApp `wa.me` fallback. If R13 materializes (in-app chat dies), we flip the default and the architecture survives. If R5 materializes (WhatsApp policy change), we add a Telegram or SMS or native dialer adapter and continue.
**Consequences:** v1 ships with a dual-channel architecture but uses primarily Firestore chat. Adapter cost: ~2 days extra engineering. Pays for itself if either R5 or R13 fires.
**Alternatives considered:**
- *WhatsApp Business API in v1:* rejected — per-message cost violates Triple Zero
- *Firestore-only chat with no WhatsApp fallback:* rejected — single point of failure
- *WhatsApp-only chat with no Firestore:* rejected — locks us to Meta's policies entirely
**Decided by:** Winston, validated by Alok
**Date:** 2026-04-11

### ADR-006: Cloudinary Free + Firebase Storage + (deferred) YouTube unlisted media strategy + MediaStore adapter

**Status:** Accepted
**Context:** Brief §10 specifies Cloudinary Free for catalog images. §10 cost forecast shows Cloudinary breaks first at shop #5–7. R3 (sustainability) requires a forecast for what happens at scale.
**Decision:** v1 uses Cloudinary Free for catalog images, Firebase Storage for voice notes and branding assets. The `MediaStore` adapter abstracts the storage layer with Cloudinary as the default and Cloudflare R2 as a v1.5/v2 stub. R2 migration is triggered at shop #20 when Cloudinary overage becomes painful.
**Consequences:** Cloudinary's free tier is the primary cost ceiling for the first ~5 shops. Beyond that, the migration to R2 is pre-planned and the adapter pattern makes it cheap.
**Alternatives considered:**
- *Firebase Storage only:* rejected — no built-in image transformations, no CDN, expensive at scale
- *YouTube Data API for catalog images:* absurd — rejected
- *Self-hosted MinIO on Oracle Always Free:* rejected — ops burden
**Decided by:** Winston, validated by Alok
**Date:** 2026-04-11

### ADR-007: Kill-switch Cloud Function + Cloud Billing budget alerts at $0.10/$0.50/$1.00

**Status:** Accepted
**Context:** Brief §8 Constraint 3 commits to ₹0 ops cost. Without programmatic enforcement, a runaway Firestore query or an SMS pumping attack could rack up real charges before anyone notices.
**Decision:** Set a Cloud Billing budget of $1/month with email + SMS alerts at $0.10, $0.50, and $1.00 thresholds. The $1.00 alert publishes to a Pub/Sub topic that triggers the `killSwitchOnBudgetAlert` Cloud Function, which automatically flips feature flags to disable the most likely cost vectors (phone auth, real-time chat).
**Consequences:** A runaway Firestore query or an SMS pumping attack triggers automated mitigation within minutes, not hours. False positives are possible (a legitimate spike could trip the cap), so the kill-switch is reversible: an operator can manually re-enable disabled features after investigation.

**v1.0.4 clarification (finding F9 — kill-switch real-time propagation).** The kill-switch writes to `shops/{shopId}/feature_flags/runtime`, NOT to Remote Config. This is deliberate: Remote Config caches on the client for up to 12 hours by default, which would let an SMS pumping attack continue for 12 hours after the server already flipped the flag. By writing to Firestore instead, the MediaStore / AuthProvider / CommsChannel adapters subscribe via `onSnapshot` real-time listeners and observe the flag change in <1 second. The invariant: **any flag that exists to protect billing must be consumed via Firestore real-time listener, not Remote Config polling.** Remote Config holds only slow-changing defaults (locale, cosmetic toggles) for which a 12-hour cache is acceptable. ADR-009 and I6.7 both need a PR to reflect this split — tracked as an acceptance criterion on the feature flag PRD story.
**Alternatives considered:**
- *Higher budget cap ($5 or $10):* rejected — paranoia is the right posture for v1
- *No kill-switch, just alerts:* rejected — alerts get ignored at 2 AM
- *Pause the entire Firebase project on cap:* rejected — too disruptive, alternatives exist
**Decided by:** Winston, validated by Alok
**Date:** 2026-04-11

### ADR-008: Devanagari-first build pipeline (Hindi as source-of-truth strings via ICU MessageFormat)

**Status:** Accepted
**Context:** Brief §8 Constraint 4 mandates Hindi (Devanagari) as the default UI language, English as toggle. §8 Constraint 15 requires Hindi-native design capacity. Pre-mortem #9 warned that Hindi-as-translation is a common failure mode.
**Decision:** All user-facing strings live in `strings_hi.dart` as the source of truth. `strings_en.dart` is the English translation, generated/maintained by the team. ICU MessageFormat is used via the `intl` package for plurals, gendered forms, and parameter substitution. **Font stack (revised v1.0.2 per frontend-design plugin findings):** Tiro Devanagari Hindi (Devanagari display) + Mukta (Devanagari body) + Fraunces (English display, italic variable serif) + EB Garamond (English body) + DM Mono (numeric/timestamps). Original spec of "Noto Sans Devanagari / Mukta as primary" overridden because Noto Sans Devanagari produces a sterile Google-default look incompatible with the "rooted, multi-generational" aesthetic the brief targets. Tiro Devanagari Hindi is also a free Google Font with substantially more character. Devanagari font subsetting is done at build time via `tools/generate_devanagari_subset.sh` to keep total font payload under 100 KB across all 5 faces. QA on real budget Android devices (Realme C-series, Redmi 9, Tecno Spark + 2 others) is a release prerequisite.
**Consequences:** The codebase is structurally Hindi-first. Any new feature must add a Hindi string before an English one. Forces the team to think in the user's language. Slight build complexity (font subsetting).

**v1.0.4 clarification (finding F12 — Constraint 15 fallback support).** Brief §8 Constraint 15 permits v1 to narrow to "English-first with Hindi toggle" as a named scope compromise if Hindi-native design capacity cannot be secured. The locale architecture supports this fallback **without any code change**: `strings_hi.dart` and `strings_en.dart` are parallel files with identical keys; the `defaultLocale` Remote Config flag (added to §5 FeatureFlags in v1.0.4) controls which language boots first; `Customer.preferredLanguage` persists the individual user choice. If the team triggers the fallback, Yugma Labs flips `defaultLocale` from `"hi"` to `"en"` and the customer app boots in English with a visible Hindi toggle in the top-right corner (per PRD B1.2 AC #7). No rebuild. No migration. No new story. The "source of truth" remains `strings_hi.dart` at the repository-discipline level — the fallback is a runtime default, not a team-workflow change — but the user experience pivots cleanly. This lets the team ship under Constraint 15's named compromise without restructuring the codebase.
**Alternatives considered:**
- *English source of truth, Hindi translated:* rejected — this is exactly the failure mode the brief warns against
- *Map<String, String> instead of ICU MessageFormat:* rejected — Hindi has gendered forms that need ICU support
- *No font subsetting:* rejected — full Noto Sans Devanagari is ~500 KB, too heavy for Tier-3 3G
**Decided by:** Winston, validated by Alok
**Date:** 2026-04-11

### ADR-009: Decision Circle as feature-flagged optional document, NOT schema foundation

**Status:** Accepted
**Context:** Brief §3 Pariwar pillar specifies Decision Circle / Guest Mode as a "foundation, not a feature." Elicitation pre-mortem #3 warned that committees in 2026 may video-call instead of pass phones, making Decision Circle redundant. R11 specifically requires the schema to survive Decision Circle being deleted entirely.
**Decision:** The `DecisionCircle` Firestore document type is OPTIONAL. A `Project` works fully without one attached. The `decisionCircleEnabled` Remote Config flag can be flipped to false, and the customer app stops showing any DC UI. The `DecisionCircle` document type can be deleted from the schema entirely without a migration, because no other collection has a foreign key to it (only Project has an optional `decisionCircleId` reference).
**Consequences:** The brief's "foundation" framing is honored at the schema level, but the architecture survives field validation that may invalidate it (R11). The cost is approximately zero — making something optional vs. required is the same engineering effort.
**Alternatives considered:**
- *Decision Circle as a required foundation (per literal brief reading):* rejected — would make R11 unsurvivable
- *Decision Circle as a separate top-level collection unrelated to Project:* rejected — DC has no meaning outside a Project
**Decided by:** Winston (with brief author's blessing per Mary's pushback invitation), to be validated empirically in Months 3–5
**Date:** 2026-04-11

### ADR-010: Udhaar Ledger as accounting mirror with forbidden-field-names list (RBI-defensive)

**Status:** Accepted
**Context:** Brief §3 specifies digital udhaar khaata as a Pariwar feature. R10 warns about RBI Digital Lending Guidelines (2022/2024) exposure if the feature is framed as lending rather than accounting. KhataBook's careful legal framing is the precedent.
**Decision:** The Firestore schema for `UdhaarLedger` enforces an allowed-fields list and a forbidden-fields list at the security-rule layer. Allowed: `recordedAmount`, `acknowledgedAt`, `partialPaymentReferences`, `runningBalance`, `closedAt`, `notes`. Forbidden: `interest`, `interestRate`, `overdueFee`, `dueDate`, `lendingTerms`, `borrowerObligation`, `defaultStatus`, `collectionAttempt`. Security rules reject any document with forbidden fields. The `udhaar khaata` is shopkeeper-initiated only (customer cannot self-select). Reminder push notifications use friendly language ("आपका khaata"), never collection language.
**Consequences:** The legal posture lives in the data model. A future RBI audit sees a system whose architecture cannot accidentally become a lending instrument because the vocabulary is missing from the codebase. Lawyer review (deferred to pre-launch) validates copy on screens, not architecture.
**Alternatives considered:**
- *Standard ledger with optional interest/fee fields:* rejected — exposes Yugma to RBI digital lending guidelines
- *No udhaar feature at all:* rejected — brief mandates it as a Pariwar pillar feature
- *Outsource udhaar to KhataBook integration:* rejected — KhataBook isn't an open API, and integration would compromise the unified Project experience
**Decided by:** Winston, with explicit defensive design pattern validated by Mary's elicitation
**Date:** 2026-04-11

### ADR-011: Marketing site is pure static (Astro), NOT Flutter Web

**Status:** Accepted (Winston's pushback against brief §10)
**Context:** Brief §10 mentions Flutter Web as one option for the marketing site. The brief implies code-sharing with the Flutter apps as the main rationale. However, Tier-3 3G connectivity is the brief's actual user environment (per §2 problem statement, persona A, and the brief's "show, don't sutra" warmth-via-typography principle). Flutter Web ships a 2–3 MB initial bundle. Pure static HTML+CSS+JS ships ~50 KB. The 50× difference is decisive.
**Decision:** The marketing site is built with Astro (a static site generator) and shipped as pure HTML/CSS/minimal-JS to Firebase Hosting. The `<shopname>.yugmalabs.ai` subdomain serves Astro-built static files. No Flutter Web. Code sharing with the apps is achieved by the marketing site loading shop content (name, photo, voice note URL, tagline) from Firestore at build time, not at runtime — the Astro build script generates per-shop static pages.
**Consequences:** First-time visitors load the site in <1 second on 3G. Devanagari fonts are subset-loaded for the specific shop name. The marketing site has zero JS framework runtime, zero auth, zero Firestore reads at runtime. The cost: a separate Astro project in the monorepo, a separate CI workflow, a separate build pipeline. The benefit: a marketing site that actually loads on the connections the brief's customers actually have.
**Alternatives considered:**
- *Flutter Web:* rejected — bundle weight is fatal for the target audience
- *Next.js or other React SSG:* rejected — heavier than Astro, no benefit for our use case
- *Plain hand-written HTML:* rejected — hard to maintain across multiple shops
**Decided by:** Winston (overriding §10 of the brief)
**Date:** 2026-04-11
**Brief revision required:** Mary should update §10 of the product brief to explicitly state pure static (Astro) instead of Flutter Web.

### ADR-012: Synthetic shop_0 continuous multi-tenant testing in v1 (NOT v1.5)

**Status:** Accepted (Winston's pushback against brief implication)
**Context:** Brief §7 v1.5 milestone includes "First multi-tenant dry run." Brief §7 v2 includes "Shop #2 onboarding pilot — first multi-tenant activation." The implication is that multi-tenant testing happens at the moment of shop #2 onboarding. Elicitation pre-mortem #11 warned this is exactly when cross-tenant leakage bugs ship to production. R9 specifies that multi-tenant flip-switch is the highest-risk moment in the product timeline.
**Decision:** A synthetic `shop_0` tenant is created on day one of v1 development. It is seeded with one document of every entity type. The `cross_tenant_integrity_test.dart` integration test runs on every CI build (on every PR, on every merge to main). The test asserts that a `shop_1`-authenticated session cannot read or write any `shop_0` document, and vice versa. Any test failure blocks the CI build. This pulls multi-tenant bug discovery forward by 5–9 months.
**Consequences:** ~1 day of upfront engineering work (seed script + integration test). ~30 seconds extra CI runtime per build. Catches every cross-tenant bug at PR-review time, not at shop #2 launch. Non-negotiable v1 requirement.
**Alternatives considered:**
- *Multi-tenant testing only at shop #2 onboarding (per brief implication):* rejected — bug surface is in front of paying customers
- *Manual periodic audits instead of CI test:* rejected — manual processes get skipped
- *No automated cross-tenant testing, rely on security rule review:* rejected — security rules are exactly where multi-tenant bugs hide, manual review is unreliable
**Decided by:** Winston (overriding brief implication)
**Date:** 2026-04-11
**Brief revision required:** Mary should update §7 to move "synthetic shop_0 continuous testing" from v1.5 implication to explicit v1 requirement. R9 mitigation language should be strengthened.

### ADR-013: Shop lifecycle state machine + DPDP Act 2023 scoped deletion (v1.0.4 patch)

**Status:** Accepted (v1.0.4 — back-fill per advanced elicitation round)
**Context:** Brief R16 surfaces DPDP Act 2023 exposure for shop deactivation (retention + notification + deletion requirements). PRD audit identified gap #2 — SAD had no representation of shop lifecycle states, no security-rule handling of deactivated shops, and no Cloud Function for scoped deletion. Advanced elicitation pre-mortem (finding F1) rated this 🔴 critical.
**Decision:** Add a `shopLifecycle` enum field to the `Shop` document (`"active" | "deactivating" | "deactivated" | "retained_for_dpdp" | "purge_scheduled"`), a `shopIsWritable(shopId)` security rule helper that freezes client writes when `shopLifecycle != "active"`, and Cloud Function 8 `shopDeactivationSweep` (§7) as the sole owner of state transitions after initial shopkeeper-triggered deactivation. DPDP retention window is 180 days by default (configurable per shop), followed by a 30-day purge-grace window, followed by a scoped recursive delete that removes every document and Cloud Storage object under `shops/{shopId}/`. An audit log is retained in `system/dpdp_purge_audit` beyond the shop as a legal hold record.
**Consequences:** The brief's R16 risk becomes architectural reality. A shop can be cleanly offboarded without manual ops work, in compliance with DPDP notification and deletion requirements. The schema impact is small (four new fields on Shop). The rule impact is small (one helper function AND-gated onto existing write rules). The function impact is one new scheduled function. A real-world legal review may still be required to validate the specific retention windows; those are configurable so lawyer feedback can tighten or extend them per-shop without a code change.
**Alternatives considered:**
- *Manual deactivation process via ops runbook:* rejected — DPDP notification windows are too tight for manual handling, and scoped deletion is error-prone without automation
- *Soft-delete via an `isDeleted` boolean without state machine:* rejected — DPDP requires distinct retention-window and grace-window states, not a single flag
- *Defer to v1.5:* rejected — the schema migration cost of adding `shopLifecycle` later is nontrivial, and the architectural invariant (no client writes to non-active shops) must be enforced at rule level from day one to be credible
**Decided by:** Winston, back-filled via v1.0.4 advanced elicitation round
**Date:** 2026-04-11

### ADR-014: Programmatic MediaStore cost monitoring + Cloudinary-to-R2 automated swap (v1.0.4 patch)

**Status:** Accepted (v1.0.4 — back-fill per advanced elicitation round)
**Context:** Brief R3 explicitly notes Cloudinary as the first cost ceiling to break (shop #5–7). §10 forecasting has the math. PRD audit identified gap #3 — §7 Cloud Functions inventory had no monitoring function for Cloudinary or Cloud Storage usage, only for phone auth SMS. Advanced elicitation pre-mortem (finding F2) rated this 🔴 critical because the first cost ceiling to break has no programmatic tripwire.
**Decision:** Add Cloud Function 7 `mediaCostMonitor` (§7) as a symmetric counterpart to Function 5 `firebasePhoneAuthQuotaMonitor`. The monitor reads a per-shop `system/media_usage_counter/{shopId}` document maintained by the MediaStore adapter on every upload, and compares against the Cloudinary 25-credit and Cloud Storage 5 GB ceilings. At 80% it alerts. At 100% Cloudinary credits, it writes `mediaStoreStrategy: "r2"` directly to the affected shop's `feature_flags/runtime` document — NOT to Remote Config — so the MediaStore adapter observes the swap via real-time listener and flips strategies within seconds (ADR-007 v1.0.4 clarification, finding F9). The MediaStore adapter contract in ADR-006 is extended to require counter-increment telemetry on every upload as a mandatory side effect.
**Consequences:** The §10 cost forecast moves from a static prediction to a runtime-enforced tripwire. Yugma Labs sees cost-ceiling breaches in real time, per shop, with a clean automated remediation path. The R2 migration trigger (previously documented as "manually activated at shop #20" in ADR-006) becomes automatic and per-shop — different shops can be on different MediaStore strategies simultaneously, which is a feature, not a bug. One new Cloud Function, one new collection (`system/media_usage_counter`), one new contract clause on the MediaStore adapter.
**Alternatives considered:**
- *Generalize `firebasePhoneAuthQuotaMonitor` into a multi-resource `resourceQuotaMonitor`:* rejected — the two monitors have different read patterns (phone auth polls Firebase Admin, media reads a client-maintained counter) and combining them adds coupling for no benefit
- *Use a third-party metrics service (Datadog, Grafana Cloud):* rejected — violates "Firebase + external free services only" (Constraint 6)
- *Manual weekly cost checks via Cloudinary dashboard:* rejected — cost overruns at shop #5–7 won't wait a week
- *Defer to v1.5:* rejected — audit gap #3 is not survivable past shop #5
**Decided by:** Winston, back-filled via v1.0.4 advanced elicitation round
**Date:** 2026-04-11

### ADR-015: Client-side Devanagari invoice generation via Dart template (no Cloud Function) (v1.0.4 patch)

**Status:** Accepted (v1.0.4 — back-fill per advanced elicitation round)
**Context:** PRD audit identified gap #4 — B1.13 Brief feature "Devanagari invoice/receipt with shopkeeper signature" had no home in the SAD. The question was whether invoice generation should live in a Cloud Function (server-side rendering, canonical output, network-dependent) or on the client (Dart-native rendering, offline-capable, zero Cloud Function cost). Advanced elicitation stakeholder round table (finding F13) flagged this as a 🟠 material gap.
**Decision:** Invoice generation is client-side in the shopkeeper ops app, using the `pdf` Dart package with a Devanagari-aware template. The template lives in `packages/lib_core/lib/src/invoice/invoice_template.dart` and consumes an `InvoicePayload` Freezed class derived from `Project`, `LineItem`, `Shop`, `Customer`, and an optional `shopkeeperSignatureImageUrl`. The fonts (Tiro Devanagari Hindi + Mukta + Fraunces + DM Mono) are the same subset-loaded set already in the client binary from ADR-008 — zero extra payload. The rendered PDF is saved to local device storage and optionally shared via a platform share sheet (WhatsApp, email, print). **No Cloud Function.** No server-side template. No network dependency. Works fully offline.
**Consequences:** The B1.13 PRD story has a clean architectural home. Invoice generation adds no Cloud Function invocations to the §10 forecast. The Devanagari-font-subset work already done for the customer app is reused. The shopkeeper signature is captured once (as an image) and stored in the Shop document; subsequent invoices reference it without re-capture. The trade-off: client-side rendering means each ops-app build must include the `pdf` package, adding ~500 KB to the APK. Acceptable given the ops app is shopkeeper-side and the shopkeeper's device is typically a reasonable Android (not the Tier-3 cheap handset the customer app targets).
**Alternatives considered:**
- *Cloud Function that generates PDFs server-side:* rejected — adds Cloud Function cost, fails offline, adds Devanagari-font management on the server side (a new surface)
- *HTML receipt rendered to PDF via headless Chrome in a Cloud Function:* rejected — same problems plus ~3s latency
- *Text-only receipt via WhatsApp message (no PDF):* rejected — shopkeeper's downstream use cases (accounting, tax filing, customer dispute resolution) need a retained PDF artifact
**Decided by:** Winston, back-filled via v1.0.4 advanced elicitation round
**Date:** 2026-04-11

---

## §12 — Open Architectural Questions for Alok

> **STATUS: All four questions LOCKED on 2026-04-11 per Alok's "go with your recommendation" directive.** Winston's recommended answers are now binding architectural decisions and the implementation must conform to them. Original question framings preserved below for context, with each marked **🔒 LOCKED** and the recommended answer formally adopted.

### Q1 — FCM token storage strategy 🔒 LOCKED

The customer app needs to store the FCM device token somewhere so the `sendUdhaarReminder` Cloud Function can find it. Two options:
- (a) Store on the `Customer` document. Simple, one read to find. But: requires the customer to be authenticated (anonymous or phone-verified) before we can store the token.
- (b) Store on a separate `fcmTokens` collection keyed by device ID. Allows pre-auth notification subscription. But: extra collection, extra read, extra security rule.

**My lean: (a)**. Anonymous Auth happens immediately on app launch, so the token can always be associated with a Customer document. (b) adds complexity for a benefit (pre-auth notifications) we don't need.

**🔒 LOCKED — Decision: Option (a). FCM token is stored as a field on the Customer document at `shops/{shopId}/customers/{customerUid}.fcmToken`.** Updated whenever the token rotates (the FCM SDK exposes a token-refresh callback). The `sendUdhaarReminder` function reads it via the customer document. The Firestore schema in §5 already shows this field on the Customer entity. Implementation note for Amelia: handle the token-refresh listener in `lib_core/src/persistence/fcm_token_manager.dart`.

### Q2 — Voice note storage path structure 🔒 LOCKED

Voice notes go to Cloud Storage (per ADR-006). Two path conventions:
- (a) Flat: `voice_notes/{voiceNoteId}.m4a` — simple, easy to query
- (b) Shop-scoped: `shops/{shopId}/voice_notes/{voiceNoteId}.m4a` — matches Firestore structure, cleaner cleanup if a shop is deleted

**My lean: (b)**. The structure parallels Firestore which makes cross-system reasoning easier, and shop-scoped cleanup is non-trivial without it.

**🔒 LOCKED — Decision: Option (b). Voice notes live at `gs://yugma-dukaan-{env}.appspot.com/shops/{shopId}/voice_notes/{voiceNoteId}.m4a`** in Cloud Storage. The path mirrors the Firestore sub-collection structure. Storage security rules enforce shop-scoped read/write the same way Firestore rules do. Shop deactivation (R16) becomes a single recursive delete on `shops/{shopId}/`. Implementation note for Amelia: storage rules live in `storage.rules` and follow the same `shopId` scoping pattern as `firestore.rules`.

### Q3 — When to capture the customer's `displayName` 🔒 LOCKED

The `Customer` document has a `displayName` field that's "TBD" while anonymous and ideally captured at some point. Three options:
- (a) Ask explicitly during phone verification ("क्या नाम लिखें?")
- (b) Capture from the UPI VPA at first payment (the VPA often contains a name fragment, e.g., `sunita.devi@oksbi`)
- (c) Never ask; let the shopkeeper fill it in via their customer_memory layer

**My lean: (c)**. Asking the customer for their name in the app is the kind of friction the brief explicitly avoids. The shopkeeper already knows the customer (via WhatsApp, phone call, or in-person visit) and will fill in the name in his ops app's customer_memory section.

**🔒 LOCKED — Decision: Option (c). The customer app NEVER asks for `displayName` directly.** It is captured by the shopkeeper in his ops app via the customer_memory layer. The Customer document keeps `displayName` nullable, with a derivation fallback chain for any UI that needs to show "who is this": (1) `customer_memory.notes` parsed for a name fragment if shopkeeper has written one, (2) UPI VPA local-part if available (e.g., `sunita.devi@oksbi` → "Sunita Devi"), (3) generic "Customer" placeholder if neither. PRD acceptance criterion for John: no user story shall include "the customer enters their name." Honors the brief's "show, don't sutra" friction discipline.

### Q4 — Marketing site per-shop content storage 🔒 LOCKED

The Astro marketing site needs per-shop content (shop name, tagline, voice note URL, etc.). Two options:
- (a) Build-time fetch from Firestore (Astro reads Firestore via admin SDK at `npm run build` time and bakes content into static HTML)
- (b) Author per-shop content in JSON files in the monorepo (`sites/marketing/src/content/shops/{shopId}.json`)

**My lean: (a)**. Build-time fetch lets the shopkeeper update his tagline in the ops app and have it appear on the marketing site after the next deploy. (b) requires a code commit for any shop content change.

Note: option (a) requires the marketing CI workflow to have read-only Firebase admin credentials. This is an extra security surface but a small one.

**🔒 LOCKED — Decision: Option (a). The Astro marketing site fetches per-shop content from Firestore at `npm run build` time** via a read-only Firebase admin SDK service account. The build script lives at `sites/marketing/scripts/fetch_shop_content.ts` and runs before `astro build`. The CI workflow `ci-marketing.yml` has the read-only credential as a GitHub Actions secret. Trigger paths: (1) automatic rebuild when shopkeeper updates `theme/current` document via the ops app, via a Firestore trigger Cloud Function that calls a GitHub Actions workflow_dispatch hook; (2) nightly rebuild as a safety net; (3) manual trigger via gh CLI. Implementation note for Amelia: the Firebase admin credential must be scoped read-only to `shops/*/theme/current` AND `shops/*/voice_notes/{voiceNoteId}` (for the greeting voice note URL only) — nothing else, to minimize blast radius.

---

## §13 — Honest Brief Fragility Assessment

Beyond the two positions already taken (ADR-011, ADR-012), the SAD writing surfaced four additional concerns about the brief that Mary should consider revising.

### Fragility #1 — The brief assumes the shopkeeper has 1 phone for ops

The brief's persona descriptions imply the shopkeeper uses one device for the ops app. But the operator architecture (bhaiya + beta + munshi) implies three concurrent users on potentially three devices. Firestore handles concurrent writes fine, but the brief should explicitly note that the shopkeeper ops app supports multiple operators on multiple devices simultaneously, and that role-based access (currently deferred to v1.5 per brief §7) might need to come forward to v1 if the shopkeeper actually has a son/nephew using the app from a separate phone.

**Recommendation:** Update §5 (operator persona) and §7 (v1 scope) to explicitly include "ops app supports concurrent multi-operator access from day one." Role-based permissions don't need to be deferred; they're cheap to implement at the security rule layer.

### Fragility #2 — The brief doesn't specify what happens to the customer's data when a shop deactivates

Brief §11 vision describes onboarding 50–200 shops. Implicit in that is that some shops will eventually deactivate (shopkeeper retires, business closes, etc.). The brief is silent on what happens to customer data, project history, voice notes, and chat threads when a shop is deactivated. RBI/personal-data laws (DPDP Act 2023) have notification requirements for data retention and deletion.

**Recommendation:** Add to §9 risks (or as a new R16): "Shop deactivation data lifecycle is undefined. DPDP Act 2023 requires explicit notification and retention/deletion policies. Mitigation: define a `shop_lifecycle.md` runbook before launch."

### Fragility #3 — The brief's "Hindi-first" assumption may not survive Devanagari rendering on cheap Android

Pre-mortem #9 raised this. ADR-008 mitigates it via font subsetting and budget Android QA. But the brief should make explicit that Devanagari rendering is a release-blocking acceptance criterion, not a polish item. Specific cheap-Android devices to test on (Realme C-series, Redmi 9, Tecno Spark, etc.) should be listed.

**Recommendation:** Update §6 success criteria to add: "Devanagari rendering verified on at least 5 distinct cheap-Android device models before any release. List of devices in Appendix B."

### Fragility #4 — The brief implies live chat is a v1 must-have, but the cost forecast at scale suggests Firestore real-time becomes the second-largest cost driver

Brief §3 specifies Firestore real-time chat as the default for the Ramesh-bhaiya Ka Kamra thread. The §10 cost forecast in this SAD shows Firestore reads driven by real-time listeners are a significant cost vector at shop #20+. The CommsChannel adapter (ADR-005) provides a swap path, but the brief should acknowledge that the swap may be needed earlier than expected.

**Recommendation:** Update R13 (WhatsApp gravitational competitor) to also note that "Firestore real-time chat costs scale faster than other Firestore usage; the CommsChannel swap to WhatsApp may be triggered by cost pressure as well as user behavior." This is not a new risk, just an additional reason the existing risk matters.

---

## §14 — Handoff Notes for John (Product Manager)

John, when you write the PRD next, here is what you need to know from the architecture phase.

### Auth-flow-sensitive user stories

Any user story that involves "the customer signs in" or "the customer is recognized" needs to account for the layered auth model. Specifically:

- Customer can browse, join Decision Circle, and chat **without ever signing in** (Tier 0 Anonymous)
- Customer must verify phone with OTP **only when committing to a purchase** (Tier 1 Phone)
- Returning customers **never see the OTP again** unless they uninstall (refresh token persistence)
- The OTP step itself may be deferred or skipped per Remote Config (R12 mitigation)
- The shopkeeper signs in via Google **once per device, persistent across sessions** (Tier 2 Google)

User stories should not assume the customer "has an account" or "logs in" — they should assume the customer has a stable identity that may or may not be phone-verified at any given moment.

### Features that depend on which adapter

| Feature | Adapter | If adapter changes |
|---|---|---|
| Phone OTP commit ceremony | AuthProvider | If swapped to UPI-only, the OTP screen disappears entirely |
| Ramesh-bhaiya Ka Kamra chat | CommsChannel | If swapped to WhatsApp, the in-app chat screen redirects to a `wa.me` link |
| Catalog image rendering | MediaStore | If swapped to R2, image URLs change format but rendering is identical |

User stories should be written against the *capability* (commit verification, customer-shopkeeper conversation, image display), not against the *implementation* (OTP, in-app chat thread, Cloudinary URL).

### Features that must be feature-flagged from day one

- **Decision Circle / Guest Mode** (`decisionCircleEnabled`, `guestModeEnabled`) — R11 mitigation
- **Phone OTP at commit** (`otpAtCommitEnabled`) — R12 mitigation
- **In-app chat vs WhatsApp** (`whatsappPrimaryChatEnabled`) — R13 mitigation
- **Voice search** (`voiceSearchEnabled`) — v1.5+
- **AR placement** (`arPlacementEnabled`) — v2+

User stories for any of these features must include "feature flag check" in the acceptance criteria. The PM should expect that any of these can be toggled off in production without breaking the app.

### Cost-aware feature design discipline

Every feature must pass the "≤30 reads per session" budget check. When writing user stories, John should add a Firestore-read budget line to each story:

> **Example:** "As a customer, I want to see Ramesh-bhaiya's curated shortlist for weddings."
> **Acceptance criteria:** ...
> **Firestore-read budget:** 1 read for the shortlist document + 12 reads for the SKUs in the shortlist = 13 reads total.

This forces awareness of the cost model at story-writing time, not at code-review time.

### Cross-tenant integrity tests

Any user story that adds a new Firestore collection or modifies an existing one must include a cross-tenant integrity test as part of its acceptance criteria. The test must attempt the new operation as a `shop_1` user against `shop_0` data and assert it fails. This is non-negotiable per ADR-012.

### What to NOT put in the PRD

- Implementation details (those live in Amelia's stories)
- Architecture decisions (those live here)
- Business model decisions (founder-owned per brief Constraint 14)
- Specific Firestore schema (lives in this SAD §5)
- Specific Cloud Function code (lives in this SAD §7)

The PRD should focus on user stories, acceptance criteria, success metrics per story, and edge cases. The PRD should reference this SAD by section number where architectural context is needed.

---

## End of Solution Architecture Document

**Document version:** v1.0.4 (advanced-elicitation back-fill patch: 2026-04-11)
**Total length:** ~19,500 words
**Status:** v1.0.4 patch applied — Advanced Elicitation + Party Mode back-fill round completed against the full SAD. Three new ADRs (013–015), two new Cloud Functions (7 `mediaCostMonitor`, 8 `shopDeactivationSweep`), Cloud Functions inventory now 8 functions. Schema strengthened for Triple Zero testability (`amountReceivedByShop` invariant), DPDP compliance (`shopLifecycle` state machine), NPS + burnout telemetry (`feedback` sub-collection), and repeat-customer tracking (`previousProjectIds`). RBI-defensive reminder guardrails added to Function 3 reinforcing ADR-010. Offline conflict-resolution policy made concrete via Project field-partition table (§9). Kill-switch real-time propagation invariant documented in ADR-007 clarification. Constraint 15 English-first fallback architecturally validated in ADR-008 clarification. Ready for Phase 2 PRD Advanced Elicitation round.

**Inputs read in full (v1.0.4 back-fill):**
- product-brief.md v1.4
- prd.md v1.0.4 (key sections)
- .claude/skills/bmad-advanced-elicitation/methods.csv
- .claude/skills/bmad-advanced-elicitation/SKILL.md

**Architectural output produced:**
- 14 sections covering all of Mary's required deliverables
- 15 ADRs (12 original + 3 from v1.0.4 back-fill: ADR-013 shop lifecycle, ADR-014 media cost monitor, ADR-015 client-side invoice)
- 8 Cloud Functions (was 6)
- 4 open questions for Alok (all LOCKED)
- 4 brief fragility findings for Mary's revision
- 14 handoff notes for John

---

## v1.0.4 PATCH NOTE — Advanced Elicitation + Party Mode back-fill

**Date:** 2026-04-11
**Trigger:** Founder caught that the BMAD planning chain skipped Advanced Elicitation and Party Mode acceptance gates on 5 of 6 planning artifacts. This is Phase 1 of the back-fill: Solution Architecture Document. The PRD AE round (Phase 2) follows and depends on this patch.

**Methods applied (from bmad-advanced-elicitation/methods.csv):**
1. **#34 Pre-mortem Analysis** (risk/failure-mode) — imagine SAD fails at Month 6, trace causes backward
2. **#17 Red Team vs Blue Team** (adversarial) — hostile attack on architectural integrity
3. **#27 What If Scenarios** (scale/stress) — what breaks at 10× and 100× scale
4. **#26 Reverse Engineering** (inversion) — what would the opposite architecture reveal
5. **#1 Stakeholder Round Table** (role perspective) — Mary / John / Amelia / RBI-lawyer critique

**Findings that landed as patches (party-mode majority vote ✅):**

| # | Finding | Sev | Where patched |
|---|---|---|---|
| F1 | Shop deactivation lifecycle undefined (R16, DPDP, audit gap #2) | 🔴 | §5 Shop schema (`shopLifecycle` + fields), §6 `shopIsWritable` helper, §7 Function 8 `shopDeactivationSweep`, ADR-013 |
| F2 | No programmatic Cloudinary cost monitor (R3, audit gap #3) | 🔴 | §7 Function 7 `mediaCostMonitor`, ADR-014 |
| F3 | Zero-commission math not schema-testable (Differentiator #1, audit gap #9) | 🔴 | §5 Project schema `amountReceivedByShop` invariant |
| F4 | wa.me link Project context clarity (audit gap #6, P2.9) | 🟠 | §7 Function 2 clarification paragraph |
| F7 | `multiTenantAuditJob` scale cost at 100× | 🟠 | §7 Function 4 rotating-sample patch |
| F8 | Offline conflict resolution abstract (audit gap #8, I6.12) | 🟠 | §9 Project field-partition table + offline replay invariants |
| F9 | Kill-switch Remote Config cache vs real-time propagation | 🟠 | ADR-007 clarification paragraph |
| F11 | Udhaar reminder RBI guardrails (R10 reinforcement) | 🔴 | §7 Function 3 three-part guardrail patch + §5 `UdhaarLedger` fields |
| F12 | Locale architecture Constraint 15 fallback support | 🟠 | ADR-008 clarification + §5 `FeatureFlags.defaultLocale` |
| F13 | Invoice generation no architectural home (B1.13, audit gap #4) | 🟠 | ADR-015 client-side PDF generation |
| F14 | `feedback` collection missing (S4.17) | 🟠 | §5 `feedback` sub-collection + document shape + §6 rule |
| F15 | `previousProjectIds` missing (S4.18, audit gap #7) | 🟠 | §5 Customer schema capped array |

**Findings dropped via party-mode vote (minority or out of scope):**
- F5 (operator privilege exposure) — dropped, accepted scope
- F10 (melos vs alternatives) — dropped, SAD already justified
- F16 (Riverpod 3 pinning) — dropped, too granular for SAD
- F17 (HMAC secret rotation runbook) — dropped, tracked as ops runbook work not SAD content

**Audit finding cross-check (Phase 1 → Phase 2 handoff):**

| Audit gap | Severity | Addressed by SAD patch? |
|---|---|---|
| #1 Hindi design capacity gate (I6.11) | 🔴 | YES — ADR-008 clarification + `defaultLocale` flag (no code change required for fallback) |
| #2 Shop deactivation notification + deletion (C3.12) | 🔴 | YES — ADR-013 + §5 `shopLifecycle` + §7 Function 8 + §6 `shopIsWritable` helper |
| #3 Cloudinary cost telemetry (S4.16) | 🔴 | YES — ADR-014 + §7 Function 7 `mediaCostMonitor` |
| #4 Devanagari invoice/receipt (B1.13) | 🟠 | YES — ADR-015 client-side generation |
| #5 NPS survey + burnout monitoring (S4.17) | 🟠 | YES — §5 `feedback` sub-collection + §6 rule |
| #6 wa.me one-tap fallback carries Project context (P2.9) | 🟠 | YES — §7 Function 2 clarification (already satisfied, now explicit) |
| #7 Repeat-customer event tracking (S4.18) | 🟠 | YES — §5 Customer `previousProjectIds` capped array |
| #8 Offline sync conflict resolution (I6.12) | 🟠 | YES — §9 field-partition table + offline replay invariants |
| #9 Zero-commission math validation (Differentiator #1) | 🔴 | YES — §5 Project `amountReceivedByShop` invariant |

**Phase 2 PRD AE handoff notes:**

1. **Three new Cloud Functions need PRD stories.** §7 Functions 7 (`mediaCostMonitor`) and 8 (`shopDeactivationSweep`) need corresponding stories in Epic E6 or a new Epic E7 (lifecycle). Function 3 (`sendUdhaarReminder`) needs story updates to include the three RBI guardrails.

2. **Schema fields need story touchpoints.** `amountReceivedByShop` should appear as an acceptance criterion on C3.4 (commit Project) and C3.5 (UPI payment). `shopLifecycle` should drive a new S4.x story for shopkeeper-initiated deactivation. `previousProjectIds` should drive a new analytics story. `feedback` collection drives new S4.17 and potentially a customer-side NPS story in E1.

3. **Offline partition discipline is a coding-standard, not a feature.** The PRD should codify "a repository method cannot construct a patch that touches the wrong partition" as a Standing Rule (to be added as Rule 11). Amelia enforces it via Freezed sealed unions.

4. **Kill-switch real-time propagation.** I6.7 Feature Flag story needs an acceptance criterion that flags driving billable resources are consumed via Firestore real-time listener, not Remote Config polling. This affects the adapter consumers (AuthProvider, MediaStore, CommsChannel).

5. **Constraint 15 fallback is a runtime flip, not a rewrite.** PRD I6.11 (new story for the Hindi-design capacity verification gate) can specify the fallback as "flip `defaultLocale` to `en`" without requiring any code change. The story is a governance + launch-gate check, not an engineering effort.

**What did NOT change:** The locked stack (Flutter/Riverpod 3/GoRouter/Freezed 3/Material 3/Tiro Devanagari Hindi/Mukta/Fraunces/Astro/Firebase Blaze/$1 budget cap/Triple Zero). The two pillars. The 15 constraints. The 6-sprint plan. The Walking Skeleton story list. The monorepo structure. ADRs 001–012. §2 system context diagram. §4 auth flows (1–5). §8 theming. §10 cost forecast math.

**What Phase 2 PRD AE should NOT re-litigate:** Anything in ADRs 001–012. The adapter pattern. The synthetic `shop_0` discipline. The locale source-of-truth posture. The Triple Zero budget envelope. The marketing-site-is-Astro decision.

**Next step recommendation:** Proceed to Phase 2 PRD Advanced Elicitation. John adds the 9 audit-gap stories and the AE-found touchpoints above. The SAD is now cleanly downstream-ready and every PRD story has architectural scaffolding to hang on.

— Winston, System Architect
2026-04-11 (v1.0.4 back-fill)

---

## Phase 3 patch note (2026-04-30 → 2026-05-01)

The `amountReceivedByShop` field semantics tightened in Phase 3:

- Set **only** inside `applyOperatorMarkPaidPatch` (operator typed patch). Customer-driven paths (`applyCustomerCommitPatch`, `applyCustomerPaymentPatch`, `applyCustomerCodPatch`, `applyCustomerBankTransferPatch`) leave it at `0`.
- Triple Zero invariant (`amountReceivedByShop == totalAmount`) asserted at the rule layer for any transition into `state ∈ {paid, closed}`. Earlier states allow transient mismatch.
- Customer rules cannot write `state ∈ {paid, delivering, closed}` or mutate `amountReceivedByShop` / `paidAt` — closes the REST-bypass attack vector noted in §15.1.B (now resolved).

Any v1.0.x SAD passage that frames the field as written by the customer commit patch (e.g., setting it on the commit transition, or describing the Triple Zero invariant as a client-side commit-time guarantee) predates Phase 3 and is contradicted by `firestore.rules` + `packages/lib_core/lib/src/repositories/project_repo.dart:applyOperatorMarkPaidPatch`. Update on next SAD revision (v1.0.5 candidate).

