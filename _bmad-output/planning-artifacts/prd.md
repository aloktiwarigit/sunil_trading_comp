---
project_name: 'Almira-Project (Yugma Dukaan)'
flagship_shop: 'Sunil Trading Company (सुनील ट्रेडिंग कंपनी)'
shop_id: 'sunil-trading-company'
user_name: 'Alok'
author: 'John (BMAD Product Manager)'
date: '2026-04-11'
version: 'v1.0.5'
status: 'Draft v1.0.5 — Advanced Elicitation + Party Mode + audit-finding back-fill Phase 2. Applied Winston SAD v1.0.4 mandatory handoff: 8 new stories (I6.11, I6.12, B1.13, C3.12, S4.16, S4.17, S4.18, S4.19), 4 existing-story updates (I6.7, C3.4, C3.5, S4.10), new Standing Rule 11 (Project field-partition discipline). Ran 5 AE methods (Persona Focus Group, Pre-mortem, Critical Perspective, Critique and Refine, What If Scenarios) + 4-voice party mode (John/Mary/Winston/Sally). Total stories: 67 (E6: 12, E1: 13, E2: 8, E3: 12, E4: 17, E5: 5). Walking Skeleton: 19 (+I6.12). Standing rules: 11 (+Rule 11). All 9 brief→PRD audit gaps closed at PRD layer. Ready for Phase 3 (Epics List re-derive). [Phase 6 IR Check v1.2 patch 2026-04-11: headline 66→67 arithmetic correction; v1.1 baseline was 59 post-S4.13 not 58, so 59+8=67. Per-epic sum was always canonical.]'
inputs:
  - product-brief.md (v1.4)
  - solution-architecture.md (v1.0.4 — advanced elicitation back-fill with ADRs 013/014/015, Functions 7/8, §9 field-partition table, `feedback` sub-collection, `shopLifecycle` state machine, `amountReceivedByShop` invariant, `previousProjectIds`, `defaultLocale` flag)
  - product-brief-elicitation-01.md
  - party-mode-session-01-synthesis-v2.md
  - epics-and-stories.md (v1.1 — read for sprint context, not patched in Phase 2)
---

# Product Requirements Document — Yugma Dukaan

**Flagship customer:** Sunil Trading Company, Harringtonganj market, Ayodhya
**For:** Alok, Founder, Yugma Labs
**By:** John (BMAD Product Manager)
**Date:** 2026-04-11 (v1.0.5 back-fill)
**Version:** v1.0.5
**Companion documents:** Product Brief v1.4 (`product-brief.md`), Solution Architecture v1.0.4 (`solution-architecture.md`), Elicitation Report 01, Synthesis v2.1, Epics & Stories v1.1 (read-only input, to be re-derived in Phase 3)

---

## Preamble

### What this PRD is for

This document translates Mary's Product Brief (the *why* and *what*) and Winston's Solution Architecture (the *how*) into a backlog of user stories that Amelia (developer) can implement against. It does not redesign the brief, the architecture, or the business model. It does not write code. It writes stories the team can build.

The PRD is structured around six epics, each containing 5–17 user stories. Total v1 story count is **67** (v1.0.5 post-Winston-handoff: was 59 in v1.1 post-S4.13, +8 new stories = 67). *(Phase 6 IR Check v1.2 patch 2026-04-11: corrected from "66 (was 58)" arithmetic drift — v1.1 had 59 not 58, so 59+8=67. Per-epic sum (E6:12 + E1:13 + E2:8 + E3:12 + E4:17 + E5:5) was always canonically 67.)* Of these, **19 are marked with a 🦴 Walking Skeleton marker** *(v1.0.5: was 18; I6.12 added as foundational offline field-partition infrastructure per SAD v1.0.4 §9)* — these form the Month 3 technical-gate deliverable per the brief's success criteria, and they collectively touch every architectural component once at zero feature depth. Everything else adds depth to capabilities the skeleton has already proven.

### Vision compression (one paragraph)

Yugma Dukaan is a Flutter customer app, an Astro static marketing site, and a Flutter shopkeeper operations app — built for a single independent almirah shopkeeper (Sunil Trading Company in Ayodhya's Harringtonganj market) and architected for shop #2 onwards under a Yugma Labs SaaS umbrella. Bharosa (the shopkeeper-as-product) and Pariwar (committee-native browse + commit) are the two product pillars. Triple Zero (zero commission to shopkeeper, zero fees to customer, ₹0 ops cost at one-shop scale through ~shop #33) is the operational discipline. Three swappable adapters — AuthProvider, CommsChannel, MediaStore — protect against the most fragile assumptions identified in elicitation. The customer never re-authenticates after one OTP per install. The shopkeeper's voice and curation are first-class citizens of every screen. The udhaar ledger is an accounting mirror, not a lending instrument. The marketing site loads in <1 second on Tier-3 3G.

### Personas (terse — full personas in Brief §5)

**Customer-side personas (4):**
- **Persona A — Sunita-ji, the Wedding Mother** (primary, highest volume): 45–55, Hindi-first, son or daughter holds the phone, committee decision, ₹15–25k ticket, peak Oct–Feb
- **Persona B — Amit-ji, the New Homeowner**: 30–45, durability-first, ₹8–15k per piece, decides solo or with spouse
- **Persona C — Geeta-ji, the Replacement Buyer**: 55+, replacing 35-year-old Godrej, ₹20–35k, needs reassurance
- **Persona D — Rajeev-ji, the Dual-Use Small Buyer**: 30–50, hostel/landlord, 2–4 units, ₹6–10k each, hard negotiator

**App users (distinct from buyers):** the user holding the phone is usually the buyer's son, daughter-in-law, or "computer-knowledge cousin." The Decision Circle / Guest Mode flow exists because the *decision-maker* and the *device-holder* are usually different humans.

**Operator persona (1):** **Sunil-bhaiya** (working assumption), shopkeeper of Sunil Trading Company, 45–60, 20+ years in business, multi-generational family shop, WhatsApp-fluent, cash-preferred but UPI-comfortable. Multi-operator from day one: bhaiya (primary, owns relationships), beta/bhatija (digital native, ops + photos), munshi (payments + ledger).

**Anti-personas (out of scope for v1):** D2C brand founders, urban metro buyers, kirana/FMCG merchants, shopkeepers who don't want customer relationships, B2B institutional buyers (dharamshalas, hotels, corporate canteens — explicitly out per Brief §7).

### Standing rules — apply to every story unless explicitly overridden

These rules are PRD-wide. They are non-negotiable acceptance criteria on every relevant story without restating them story-by-story.

1. **Firestore-read budget.** Every story has a `firestoreReadBudget` field counting expected reads per typical execution. Stories must justify any budget >5 reads. Total customer-session budget is ≤30 reads (per SAD §5 and §10).
2. **Auth tier explicit.** Every story states the customer's required auth tier: `anonymous`, `phoneVerified`, `eitherCustomer`, `googleOperator`, or `noAuth`.
3. **Adapter dependency named.** Stories that touch auth, comms, or media name the adapter (`AuthProvider` / `CommsChannel` / `MediaStore`) and describe the swap-fallback behavior.
4. **Feature flag named.** Stories controlled by Remote Config name the flag and describe the default-off behavior.
5. **Cross-tenant integrity test required.** Multi-tenant-relevant stories include "cross-tenant integrity test passes against synthetic shop_0" as an acceptance criterion (per ADR-012).
6. **Hindi-first strings.** All UI string examples in the PRD are written in Hindi (Devanagari) first; English translations follow in parentheses for non-Hindi-fluent reviewers. Hindi is the source-of-truth string locale per Brief Constraint 4 and ADR-008.
7. **Cloud Storage paths shop-scoped.** Stories that touch Cloud Storage use paths of the form `gs://yugma-dukaan-{env}.appspot.com/shops/{shopId}/...` per locked Q2.
8. **Customer never asked for name.** Stories never include "the customer enters their name." Display name comes from shopkeeper customer_memory layer or UPI VPA fragment per locked Q3.
9. **Udhaar vocabulary discipline.** Stories that touch UdhaarLedger use only allowed field names (`recordedAmount`, `acknowledgedAt`, `partialPaymentReferences`, `runningBalance`, `closedAt`, `notes`). Forbidden vocabulary (`interest`, `dueDate`, `lendingTerms`, etc.) is enforced at the security rule layer per ADR-010.
10. **Cloud Function references.** Stories that depend on a Cloud Function name the function from SAD §7 (one of: `killSwitchOnBudgetAlert`, `generateWaMeLink`, `sendUdhaarReminder`, `multiTenantAuditJob`, `firebasePhoneAuthQuotaMonitor`, `joinDecisionCircle`, `mediaCostMonitor`, `shopDeactivationSweep`). *(v1.0.5 patch — inventory extended to 8 functions per SAD v1.0.4 §7.)*
11. **Project field-partition discipline (v1.0.5 patch per SAD §9 field-partition table).** Repository methods cannot construct a `Project` patch that crosses the customer/operator/system field partition defined in SAD §9. Enforced at compile time via Freezed sealed unions: `ProjectCustomerPatch` touches only customer-owned fields (`occasion`, `unreadCountForCustomer`), `ProjectOperatorPatch` touches only operator-owned fields (`state`, `totalAmount`, `amountReceivedByShop`, `lineItems[]`, `committedAt`/`paidAt`/`deliveredAt`/`closedAt`, `customerDisplayName`, `customerPhone`, `customerVpa`, `decisionCircleId`, `udhaarLedgerId`, `unreadCountForShopkeeper`), `ProjectSystemPatch` is written by Cloud Functions only (`lastMessagePreview`, `lastMessageAt`, `updatedAt` server timestamp). Cross-partition mutations must compose multiple typed patches at a higher layer. Cross-tenant integrity test asserts that no customer-app code path emits an `OperatorPatch` and vice versa. This rule gates any story whose AC writes to a `Project` document.

### How to read this PRD

Each story is presented as a structured block:

```
**[ID]** — [Title]              [🦴 if in Walking Skeleton]
*As a [persona], I want [capability], so that [outcome].*

| Field | Value |
|---|---|
| Auth tier | ... |
| Adapter | ... or none |
| Feature flag | ... or none |
| Firestore reads | ... |
| Cross-tenant test | Y / N |
| Refs | Brief §, SAD §, ADR |

**Acceptance criteria:** numbered list
**Edge cases:** numbered list
**Dependencies:** comma-separated story IDs
```

Walking Skeleton stories (🦴) are the Month 3 technical-gate deliverable. They must ship first; everything else adds depth to capabilities the skeleton has proven.

---

## Epic E6 — Cross-Cutting Infrastructure

*Foundation. Everything else sits on this. Build first.*

This epic implements the Three Adapters, the auth flow with session persistence, the multi-tenant shopId scoping, the kill-switch, the feature flag system, and the Hindi locale + Devanagari typography pipeline. **Without E6, no other epic can ship.** It is built first by the platform engineer; E1 and E4 begin in parallel as soon as the AuthProvider and Firestore basics are working.

### **I6.1** — AuthProvider adapter scaffolding 🦴

*As a Yugma Labs engineer, I want a swappable AuthProvider interface with a Firebase implementation, so that the customer app and shopkeeper app can authenticate against Firebase today and against any other provider tomorrow without rewriting screens.*

| Field | Value |
|---|---|
| Auth tier | N/A (this is the auth implementation) |
| Adapter | **AuthProvider** (this story creates it) |
| Feature flag | `auth_provider_strategy` (default: `firebase`) |
| Firestore reads | 0 (no Firestore IO in adapter scaffolding) |
| Cross-tenant test | N |
| Refs | Brief §10, SAD §4, ADR-002, R8 |

**Acceptance criteria:**
1. `AuthProvider` interface defined in `lib_core/src/adapters/auth_provider.dart` with the methods specified in SAD §4
2. `AuthProviderFirebase` concrete implementation wraps `firebase_auth` SDK and supports anonymous, phone, and Google sign-in
3. Three stub implementations exist with `UnimplementedError` markers: `AuthProviderMsg91`, `AuthProviderEmailMagicLink`, `AuthProviderUpiOnly`
4. Runtime selection happens via `RemoteConfig.getString('auth_provider_strategy')`
5. Stream-based `authStateChanges` reactively notifies all consumers when the user changes
6. Unit tests cover all 4 implementations with `firebase_auth_mocks` package

**Edge cases:**
1. Remote Config returns an unknown strategy → fall back to `firebase` and log a warning to Crashlytics
2. Network unavailable on first launch → Anonymous Auth succeeds offline (Firebase SDK supports this); other tiers retry on connectivity restore

**Dependencies:** None (foundation story)

---

### **I6.2** — Anonymous → Phone Auth UID merger logic 🦴

*As Sunita-ji's son (the device holder), I want my anonymous browse session to be preserved when I commit to a purchase and verify my phone, so that my Decision Circle, chat history, and draft Project don't disappear at the moment of trust.*

| Field | Value |
|---|---|
| Auth tier | `anonymous` → `phoneVerified` (upgrade flow) |
| Adapter | AuthProvider |
| Feature flag | `otpAtCommitEnabled` (R12) |
| Firestore reads | 1 (read existing customer doc if conflict) |
| Cross-tenant test | N |
| Refs | SAD §4 Flow 1, SAD §4 Flow 4, ADR-002, R12 |

**Acceptance criteria:**
1. `AuthProviderFirebase.upgradeToPhone(verificationId, otp)` calls `linkWithCredential` on the current anonymous user
2. On success, the Firebase user's UID is unchanged; the user now has both `isAnonymous: false` and `phoneNumber: <verified>`
3. The Customer Firestore document is updated in the same transaction with `phoneVerifiedAt: serverTimestamp()` and `phoneNumber: <e164>`
4. On `credential-already-in-use` error, the merger logic per SAD §4 Flow 4 executes: sign in to the existing UID, migrate Decision Circle / Project draft state via a one-shot Cloud Function call, mark the orphaned anonymous Customer document for cleanup
5. The Decision Circle session state, chat thread membership, and Project draft survive the upgrade transparently
6. Integration test: create anonymous session → join Decision Circle → create Project draft → upgrade to Phone → assert all 3 still exist with the same IDs

**Edge cases:**
1. OTP entered incorrectly: standard Firebase error surface; user retries with new OTP
2. Phone number entered already belongs to a different (existing) UID: merger logic in AC #4
3. Network drops mid-upgrade: Firebase SDK queues the operation; retry on reconnect
4. Customer enters phone number with country code "+91" prefix vs without: input is normalized to E164 before submission

**Dependencies:** I6.1, I6.3

---

### **I6.3** — Refresh-token session persistence with silent sign-in 🦴

*As a returning customer, I want the app to remember me from my last session, so that I never see an OTP screen on a return visit.*

| Field | Value |
|---|---|
| Auth tier | `phoneVerified` (returning) or `anonymous` (returning) |
| Adapter | AuthProvider |
| Feature flag | None |
| Firestore reads | 0 (Firebase Auth handles silent refresh internally) |
| Cross-tenant test | N |
| Refs | SAD §4 Flow 2, founder requirement (2026-04-11) |

**Acceptance criteria:**
1. On app launch, `FirebaseAuth.instance.currentUser` returns the previously authenticated user without any UI step
2. Refresh token is automatically refreshed by the SDK; the customer never sees an OTP screen unless they explicitly sign out, clear app data, or uninstall
3. The returning customer lands directly on the previous app state (e.g., the Project they last viewed)
4. SMS verifications consume from the 10k/month Blaze quota *only* on first install per device, not on every session
5. Integration test: complete a phone-verified flow → kill the app → relaunch → assert no OTP screen appears

**Edge cases:**
1. Refresh token expires (rare in normal use, only after explicit revocation): app gracefully falls through to a "verify your phone again" prompt with the same flow as I6.2
2. User clears app data: same as above; app behaves as a fresh install
3. Customer signs in on a new device with the same phone number: AC #4 of I6.2 (UID merger via existing-credential path) applies

**Dependencies:** I6.1, I6.2

---

### **I6.4** — Multi-tenant shopId scoping foundation 🦴

*As a Yugma Labs platform engineer, I want every Firestore document, every security rule, and every storage path scoped by shopId, so that shop #2 can onboard without rewriting code.*

| Field | Value |
|---|---|
| Auth tier | N/A (infrastructure) |
| Adapter | None |
| Feature flag | None |
| Firestore reads | 0 (this is the schema discipline itself) |
| Cross-tenant test | **Y — this story creates the test** |
| Refs | SAD §5, SAD §6, ADR-003, ADR-012, R9 |

**Acceptance criteria:**
1. Every Firestore document in every collection (per SAD §5) carries a `shopId` field
2. Every Firestore security rule (per SAD §6) checks `request.auth.token.shopId == resource.data.shopId` OR uses sub-collection scoping under `/shops/{shopId}/`
3. The synthetic `shop_0` tenant is seeded by `tools/seed_synthetic_shop_0.ts` and contains one document of every entity type
4. The cross-tenant integrity test (`packages/lib_core/test/cross_tenant_integrity_test.dart`) is added to `.github/workflows/ci-cross-tenant-test.yml` and runs on every PR
5. The test attempts cross-tenant reads as a `shop_1` operator targeting `shop_0` documents and asserts every read fails with `permission-denied`
6. The test attempts cross-tenant writes and asserts every write fails
7. The test asserts that Udhaar Ledger forbidden field names (`interest`, `interestRate`, `overdueFee`, etc.) are rejected at the rule layer
8. The CI build is blocked if any test case fails

**Edge cases:**
1. A new Firestore collection added without `shopId` → cross-tenant test catches it via the integrity check
2. A new security rule added without shopId scoping → test catches it
3. A future engineer accidentally adds `interest` field to UdhaarLedger → test catches it before merge

**Dependencies:** I6.1

---

### **I6.5** — CommsChannel adapter scaffolding

*As a Yugma Labs engineer, I want a swappable CommsChannel interface with a Firestore real-time chat default and a WhatsApp wa.me fallback, so that if real-time chat dies under WhatsApp competition (R13), the architecture survives a swap without rewriting Project state.*

| Field | Value |
|---|---|
| Auth tier | N/A (infrastructure) |
| Adapter | **CommsChannel** (this story creates it) |
| Feature flag | `commsChannelStrategy` (default: `firestore`) |
| Firestore reads | 0 (scaffolding only) |
| Cross-tenant test | N |
| Refs | SAD §1, SAD ADR-005, R5, R13 |

**Acceptance criteria:**
1. `CommsChannel` interface defined in `lib_core/src/adapters/comms_channel.dart`
2. `CommsChannelFirestore` implementation reads/writes the chat thread sub-collection (per SAD §5 schema)
3. `CommsChannelWhatsApp` implementation generates `wa.me` deep links via the `generateWaMeLink` Cloud Function (SAD §7 Function 2) and attaches a Project context blob
4. Runtime selection via `RemoteConfig.getString('commsChannelStrategy')`
5. The adapter exposes `openConversation(projectId)`, `sendVoiceNote(blob)`, `sendText(msg)`, `observeMessages(projectId)` methods
6. Both implementations are testable with mock Firestore and a mock HTTPS callable

**Edge cases:**
1. Strategy is `whatsapp` but the customer doesn't have WhatsApp installed → graceful fallback to in-app chat with a "WhatsApp not detected" notice
2. Strategy switches mid-session → existing message stream completes naturally; new messages route via the new strategy
3. WhatsApp policy change blocks `wa.me` links → operator manually flips strategy back to `firestore` via Settings

**Dependencies:** I6.1, I6.4

---

### **I6.6** — MediaStore adapter scaffolding

*As a Yugma Labs engineer, I want a swappable MediaStore interface with Cloudinary as the default for catalog images and Firebase Storage for voice notes, so that when Cloudinary credit overage hits at shop #5–7, the team can swap to Cloudflare R2 without rewriting image-rendering code.*

| Field | Value |
|---|---|
| Auth tier | N/A |
| Adapter | **MediaStore** (this story creates it) |
| Feature flag | `mediaStoreStrategy` (default: `cloudinary`) |
| Firestore reads | 0 |
| Cross-tenant test | N |
| Refs | SAD §1, SAD ADR-006, R3 |

**Acceptance criteria:**
1. `MediaStore` interface defined in `lib_core/src/adapters/media_store.dart`
2. `MediaStoreCloudinary` implementation handles catalog image upload + transformation URLs
3. `MediaStoreFirebase` implementation handles voice note upload + Cloud Storage signed URLs
4. `MediaStoreR2` stub implementation exists with `UnimplementedError` markers (activated at shop #20+)
5. Method signatures: `uploadCatalogImage(bytes, metadata)`, `getCatalogUrl(publicId, transform)`, `uploadVoiceNote(bytes, shopId, voiceNoteId)`, `getVoiceNoteUrl(shopId, voiceNoteId)`
6. Voice note uploads use the shop-scoped path `gs://yugma-dukaan-{env}.appspot.com/shops/{shopId}/voice_notes/{voiceNoteId}.m4a` per Q2
7. Cloudinary uploads use a signed upload preset; the signing happens via a small Cloud Function (added to SAD §7 inventory if not already present)

**Edge cases:**
1. Cloudinary credits exhausted mid-upload → automatic retry, then escalation alert via `firebasePhoneAuthQuotaMonitor`-style monitor function (TBD as a follow-up story)
2. Cloud Storage upload fails → exponential backoff retry, then surfaces error to the calling screen
3. Strategy switches mid-app-run → previously uploaded URLs continue to resolve from their original provider

**Dependencies:** I6.1, I6.4

---

### **I6.7** — Feature flag system via Remote Config

*As a Yugma Labs engineer, I want all feature flags loaded from Firebase Remote Config at app boot, so that Decision Circle, OTP-at-commit, in-app chat, and any future feature can be toggled in production without an app rebuild.*

| Field | Value |
|---|---|
| Auth tier | N/A |
| Adapter | None |
| Feature flag | (this story creates the system) |
| Firestore reads | 0 (Remote Config is separate from Firestore) |
| Cross-tenant test | N |
| Refs | SAD §1, SAD §5 FeatureFlags entity, ADR-009, R11, R12, R13 |

**Acceptance criteria:**
1. Remote Config initialized at app launch with cached defaults bundled with the app binary
2. Flag fetch on every cold launch with a 12-hour cache lifetime
3. The following flags are defined with default values:
   - `decisionCircleEnabled` (default: `true`)
   - `guestModeEnabled` (default: `true`)
   - `otpAtCommitEnabled` (default: `true`)
   - `commsChannelStrategy` (default: `firestore`)
   - `authProviderStrategy` (default: `firebase`)
   - `mediaStoreStrategy` (default: `cloudinary`)
   - `voiceSearchEnabled` (default: `false`)
   - `arPlacementEnabled` (default: `false`)
4. Per-shop overrides supported via the `/shops/{shopId}/feature_flags/runtime` Firestore document (read on shop boot)
5. A `FeatureFlags` Riverpod provider exposes the flag values reactively to all screens
6. Flag changes during a session do not break running screens (graceful re-render)
7. **Kill-switch flag split (v1.0.5 patch per SAD ADR-007 v1.0.4 clarification + finding F9).** Flags that gate *billable* resources MUST be consumed via Firestore real-time `onSnapshot` listener on `/shops/{shopId}/feature_flags/runtime`, NOT via Remote Config polling. The canonical list of real-time kill-switch flags: `kill_switch_active`, `cloudinary_uploads_blocked`, `firestore_writes_blocked`, `authProviderStrategy`, `mediaStoreStrategy`, `otpAtCommitEnabled`. Propagation from server flip → client behavior change MUST be <5 seconds end-to-end. Remote Config holds ONLY slow-changing cosmetic flags: `decisionCircleEnabled`, `guestModeEnabled`, `voiceSearchEnabled`, `arPlacementEnabled`, `defaultLocale`. Integration test: flip `mediaStoreStrategy` in Firestore, assert an already-mounted customer_app reflects the change in under 5 seconds without restart.
8. **Adapter consumer discipline.** `AuthProvider`, `CommsChannel`, and `MediaStore` adapter consumers MUST subscribe to the runtime flag document on mount and rebuild on change. Unit tests verify that the adapters do not cache Remote Config values for billable flags.

**Edge cases:**
1. Remote Config fetch fails: fall back to bundled defaults, log to Crashlytics
2. Per-shop override conflicts with Remote Config: per-shop override wins
3. A flag is referenced in code but not defined in Remote Config: bundled default applies

**Dependencies:** I6.4

---

### **I6.8** — Kill-switch Cloud Function + budget alerts

*As Yugma Labs (the platform owner), I want a kill-switch Cloud Function that automatically disables expensive features when the $1/month Blaze budget cap is approached, so that an SMS pumping attack or runaway query can't burn unexpected charges.*

| Field | Value |
|---|---|
| Auth tier | N/A |
| Adapter | None |
| Feature flag | All flags from I6.7 are touched by this function |
| Firestore reads | 0 (function reads system collection only) |
| Cross-tenant test | N |
| Refs | SAD §7 Function 1, ADR-007 |

**Acceptance criteria:**
1. `killSwitchOnBudgetAlert` Cloud Function deployed to all three Firebase projects (dev/staging/prod)
2. Subscribes to `budget-alerts` Pub/Sub topic configured by Cloud Billing
3. Cloud Billing budgets configured at $0.10, $0.50, $1.00 thresholds
4. At 50% threshold: function logs to `system/budget_alerts/history` and sends FCM notification to operators
5. At 100% threshold: function flips `otpAtCommitEnabled` to `false` and `authProviderStrategy` to `upi_only` for all shops
6. Function is idempotent — multiple alert deliveries do not double-flip flags
7. Manual override: an operator can re-enable flags via the ops app Settings screen after investigation

**Edge cases:**
1. False positive (legitimate spike trips the cap): operator sees alert, investigates, manually re-enables flags
2. Multiple alerts arrive simultaneously: idempotency check prevents double-flip
3. Cloud Function itself fails: Firestore document `system/budget_alerts/history` shows the failed invocation; Crashlytics surfaces it; operator manually intervenes

**Dependencies:** I6.7

---

### **I6.9** — Hindi locale + Devanagari font subsetting

*As Sunita-ji (a Hindi-first user), I want every screen, every message, every error, and every notification to render in proper Devanagari with no clipping, so that the app feels like it was built in my language, not translated into it.*

| Field | Value |
|---|---|
| Auth tier | N/A |
| Adapter | None |
| Feature flag | None |
| Firestore reads | 0 |
| Cross-tenant test | N |
| Refs | Brief Constraint 4, Brief Constraint 15, ADR-008, R9 fragility (SAD §13) |

**Acceptance criteria:**
1. All UI strings live in `lib_core/src/locale/strings_hi.dart` as the source of truth
2. `lib_core/src/locale/strings_en.dart` mirrors strings_hi.dart with English translations (for the toggle)
3. ICU MessageFormat support via the `intl` package for plurals, gender, and parameter substitution
4. **Tiro Devanagari Hindi** (Devanagari display) + **Mukta** (Devanagari body) + **Fraunces** (English display, italic) + **EB Garamond** (English body) + **DM Mono** (numerals) fonts subset-built via `tools/generate_devanagari_subset.sh` to ≤100 KB total Devanagari-pair payload + ≤60 KB English-pair payload *(Phase 6 IR Check v1.2 patch 2026-04-11: corrected from stale "Noto Sans Devanagari and Mukta" to the Brief v1.4 Constraint 4 font stack)*
5. Font subsetting includes only the glyphs actually used by `strings_hi.dart` plus 200 most common Devanagari characters as a buffer
6. Devanagari rendering verified on at least 5 cheap-Android device models (Realme C-series, Redmi 9, Tecno Spark, plus 2 more) before any release
7. The "Hindi-native QA" checklist is published in `docs/runbook/hindi_qa_checklist.md`
8. A copywriter fluent in Awadhi-inflected Hindi reviews all customer-facing strings before v1 launch (per Brief Constraint 15)

**Edge cases:**
1. A Devanagari conjunct character is not in the subsetted Tiro Devanagari Hindi + Mukta payload: Flutter's runtime glyph-missing detection falls back to the device's bundled system Devanagari face (typically Noto Sans Devanagari on cheap Android — note this is a *runtime fallback only*; the app never ships with Noto as a bundled asset per Constraint 4); a `font_fallback_triggered` Crashlytics event fires so we can measure fallback frequency. CI lint warns when new strings introduce uncommon glyphs. *(Phase 6 IR Check v1.2 patch 2026-04-11: clarified runtime-fallback semantics; aligns with UX Spec §7.2 item 5.)*
2. A user toggles to English mid-session: theme rebuilds, all strings re-render, no app restart
3. Tiro Devanagari Hindi or Mukta subset corrupts during build: CI test renders sample strings and asserts visual hash matches *(Phase 6 IR Check v1.2 patch 2026-04-11: corrected from stale "Noto Sans Devanagari")*

**Dependencies:** I6.4

---

### **I6.10** — Crashlytics + Analytics + App Check enabled across both apps

*As Yugma Labs, I want crash reports, performance traces, custom analytics events, and App Check abuse protection live on day one, so that we have visibility into the app's health from the first user.*

| Field | Value |
|---|---|
| Auth tier | N/A |
| Adapter | None |
| Feature flag | None |
| Firestore reads | 0 |
| Cross-tenant test | N |
| Refs | Brief §10, SAD §1, R8 (App Check is part of R8 mitigation) |

**Acceptance criteria:**
1. Firebase Crashlytics SDK integrated in both customer_app and shopkeeper_app
2. Firebase Analytics integrated; key events defined: `auth_anonymous_signed_in`, `auth_phone_otp_requested`, `auth_phone_verified`, `project_created`, `project_committed`, `decision_circle_persona_switched`, `voice_note_recorded`, `udhaar_recorded`, `feature_flag_swap_triggered`
3. Firebase Performance integrated; auto traces enabled
4. App Check enabled with Play Integrity (Android) and DeviceCheck (iOS); enforced on Firestore + Cloud Functions
5. App Check violations are logged to Crashlytics
6. Debug builds use App Check debug providers so devs aren't locked out
7. A staging-environment dashboard displays the key metrics

**Edge cases:**
1. App Check token rotation fails: standard Firebase SDK handling; logs warning
2. Crashlytics SDK upload throttled by network: queue locally, retry
3. Analytics event sent before Anonymous Auth completes: event is buffered and sent after auth

**Dependencies:** I6.1, I6.4, I6.7

---

### **I6.11** — Hindi-native design capacity verification gate *(v1.0.5 add per Winston's SAD v1.0.4 handoff, Brief Constraint 15)*

*As the Yugma Labs founder, I want a pre-design-kickoff verification that Hindi-native design capacity has been secured (or explicitly broken per Constraint 15), so that Amelia and Sally never begin implementation on Devanagari screens without a qualified reviewer in the loop, AND so that the fallback to "English-first with Hindi toggle" is a deliberate runtime flip rather than a silent failure.*

| Field | Value |
|---|---|
| Auth tier | `noAuth` (operational / governance gate, not user-facing) |
| Adapter | None |
| Feature flag | **`defaultLocale`** (Remote Config, SAD v1.0.4 §5 FeatureFlags, default: `"hi"`) |
| Firestore reads | 0 (documentation artifact + one Remote Config write on fallback trigger) |
| Cross-tenant test | N |
| Refs | Brief §8 Constraint 15, Brief §12 Step 0.6, SAD v1.0.4 ADR-008 clarification, SAD §5 FeatureFlags |

**Acceptance criteria:**
1. A dated verification artifact lives at `docs/runbook/hindi_design_capacity_verification.md` signed off by Alok before the design kickoff date. The artifact MUST confirm one of the three Constraint 15 options is in place: (a) in-house Hindi-fluent designer, (b) contracted Hindi-fluent design reviewer with shipping experience on Indian apps, (c) Awadhi-Hindi copywriter contracted for 4 weeks + Devanagari rendering QA on ≥5 real budget Android devices.
2. If NONE of the three options is met by the design kickoff date, the fallback path executes: `defaultLocale` Remote Config flag is flipped from `"hi"` to `"en"` in all three Firebase projects (dev/staging/prod). The customer app then boots in English with a visible Hindi toggle in the top-right corner (per B1.2 AC #7 — already implemented). The shopkeeper ops app still ships Devanagari strings for customer-facing output (voice notes, shortlist titles, invoices) but the operator UI defaults to English.
3. On fallback trigger, a Crashlytics custom event `constraint_15_fallback_triggered` is logged with `{triggeredAt, triggeredBy, reason}` payload so the decision is visible in the ops dashboard forever.
4. The decision (met OR broken) is recorded in the project context file `docs/project-context.md` so Amelia's story-implementation agent sees the current locale posture before writing any locale-sensitive code.
5. This story is a **precondition for Sprint 1** — no E1 or E2 UX story begins until I6.11 is complete. If the verification artifact is missing by the Sprint 1 kickoff, John halts the sprint and escalates to Alok.
6. A README note in `docs/adr/adr-008-hindi-first.md` (or the Brief §8 Constraint 15 runbook, wherever lives) is updated to reflect whichever option was taken.

**Edge cases:**
1. Designer is secured mid-sprint after fallback has been triggered: the Remote Config flag is flipped back to `"hi"`, no code change required, existing customers see the Hindi-default UI on next Remote Config fetch (~12 hours) or on next cold launch.
2. Designer quits after verification passes: a new verification artifact is required before the next release. A calendar reminder in the Yugma Labs ops runbook re-checks this every 90 days.
3. Fallback is triggered but the copywriter arrives 2 weeks later: story does NOT re-open; the ops team flips the flag and logs a second Crashlytics event `constraint_15_fallback_reversed`.

**Dependencies:** None (this is a precondition gate; it blocks stories, it doesn't wait on any)

**Walking Skeleton?** No — this is a governance gate, not an implementation story. However it MUST complete before the Walking Skeleton's first UX-touching story (B1.1) begins. Sprint-plan implication: Phase 3 (Epics List re-derive) should treat I6.11 as a "Sprint 0" blocker.

---

### **I6.12** — Offline-first sync conflict resolution per SAD §9 field-partition *(v1.0.5 add per Winston's SAD v1.0.4 handoff, audit gap #8)* 🦴

*As Yugma Labs platform engineering, I want the repository layer to enforce the SAD §9 customer/operator/system field partition on every Project write via compile-time Freezed sealed unions, so that a customer offline for 3 days replaying stale writes cannot inadvertently revert operator state — and vice versa — and the app's offline-first promise is implementable by a PRD author without re-reading the SAD every time.*

| Field | Value |
|---|---|
| Auth tier | `anonymous` + `phoneVerified` + `googleOperator` (cross-tier infrastructure) |
| Adapter | None (Riverpod 3 + Firestore offline cache + repository sealed unions) |
| Feature flag | None |
| Firestore reads | 0 (infrastructure; no direct Firestore IO) |
| Cross-tenant test | **Y — new test case in `cross_tenant_integrity_test.dart` asserts partition enforcement** |
| Refs | SAD v1.0.4 §9 field-partition table, SAD §9 offline replay invariants, ADR-004, audit gap #8, Standing Rule 11 |

**Acceptance criteria:**
1. Three sealed Freezed unions are defined in `packages/lib_core/lib/src/models/project_patch.dart`:
   - `ProjectCustomerPatch` — fields: `occasion?`, `unreadCountForCustomer?`
   - `ProjectOperatorPatch` — fields: `state?`, `totalAmount?`, `amountReceivedByShop?`, `lineItems[]?`, `committedAt?`, `paidAt?`, `deliveredAt?`, `closedAt?`, `customerDisplayName?`, `customerPhone?`, `customerVpa?`, `decisionCircleId?`, `udhaarLedgerId?`, `unreadCountForShopkeeper?`
   - `ProjectSystemPatch` — fields: `lastMessagePreview?`, `lastMessageAt?`, `updatedAt?` (all written by Cloud Functions only)
2. `ProjectRepo` exposes exactly three write methods: `applyCustomerPatch(projectId, ProjectCustomerPatch)`, `applyOperatorPatch(projectId, ProjectOperatorPatch)`, `applySystemPatch(projectId, ProjectSystemPatch)`. There is no generic `updateProject(Map<String, dynamic>)` method. Static analysis (the custom lint rule added in the same story) flags any direct `Firestore.doc(...).update({...})` call against a `projects` path.
3. The customer_app repository layer imports ONLY `ProjectCustomerPatch`; the shopkeeper_app imports ONLY `ProjectOperatorPatch`; Cloud Functions import ONLY `ProjectSystemPatch`. Cross-imports fail at compile time via a `// ignore_for_file: implementation_imports` lint + a CI import-audit script at `tools/audit_project_patch_imports.sh`.
4. Similar partitioning extends to `ChatThread` (owner vs participant vs system) and `UdhaarLedger` (operator-only write, customer read-only) in the same story — Freezed unions `ChatThreadOperatorPatch` / `ChatThreadParticipantPatch` / `ChatThreadSystemPatch` and `UdhaarLedgerOperatorPatch`.
5. The cross-tenant integrity test gains three new test cases: (a) customer_app code path cannot construct an `OperatorPatch` (compile-time check via a negative compilation test in `test/fails_to_compile/*.dart`), (b) a Firestore transaction attempting to write `state: "committed"` from a customer-app runtime fails the security rule unless it is the special-cased `draft → committed` transition with `request.auth.uid == resource.data.customerUid`, (c) an operator offline-replayed write of `unreadCountForCustomer` is rejected at the rule layer.
6. Multi-day offline replay invariants documented in SAD v1.0.4 §9 are verified: (a) 3-day-offline customer cannot revert operator state, (b) 3-day-offline operator cannot overwrite customer unread counts or chat messages, (c) `lastMessageAt` advances monotonically via Cloud Function + transactional get, (d) `amountReceivedByShop` cannot be written by customer at all.
7. The PRD Standing Rule 11 (added v1.0.5) is referenced in the repo's `CONTRIBUTING.md` and in the `README` of `packages/lib_core/src/models/`.

**Edge cases:**
1. Customer cancels a draft Project (`state: draft → cancelled`) — this is the one cross-partition mutation by customer. Allowed via a special `ProjectCustomerCancelPatch` variant, gated on `resource.data.state == "draft"` in the security rules.
2. Operator rejects a commit (`state: committed → draft`) — allowed via `ProjectOperatorRevertPatch` with an audit-log entry written to `shops/{shopId}/audit/{eventId}`.
3. A future field is added to Project (e.g., `shippingCarrierName`) — the story's `CONTRIBUTING.md` note requires that every new field is explicitly classified under customer/operator/system partition in the same PR, otherwise the CI lint fails.
4. Simultaneous customer and operator writes on `unreadCountForCustomer` and `unreadCountForShopkeeper` respectively — both succeed because they touch disjoint fields and Firestore merge semantics handle it cleanly.

**Dependencies:** I6.4 (multi-tenant scoping), I6.1 (adapter foundation). **Blocks:** every story that writes to `Project`, `ChatThread`, or `UdhaarLedger` — which is 30+ stories. This must land in Sprint 1 or Sprint 2.

**Walking Skeleton?** **🦴 YES.** This is foundational infrastructure for any offline-capable use case and must be in place before C3.1 (create draft), C3.4 (commit), P2.5 (send message), or any other write-path story. Walking Skeleton count increments from 18 → 19.

---

## Epic E1 — Bharosa Foundation

*The shopkeeper-as-product layer. Sunil-bhaiya's voice, face, curation, memory, and honest absence are the experience. The almirahs are background.*

### **B1.1** — First-time customer onboarding 🦴

*As Sunita-ji's son (the device holder, first-time visitor), I want to land in the app and immediately see who Sunil-bhaiya is and what he sells, so that I don't waste a single second wondering "is this a real shop?"*

| Field | Value |
|---|---|
| Auth tier | `anonymous` (signed in silently before first paint) |
| Adapter | AuthProvider |
| Feature flag | None |
| Firestore reads | 3 (Shop doc + ShopThemeTokens + greeting voice note metadata) |
| Cross-tenant test | Y |
| Refs | Brief §1 first-impression principle, Brief §3 Bharosa, locked PQ2 |

**Acceptance criteria:**
1. App icon labeled `सुनील ट्रेडिंग कंपनी` (Sunil Trading Company) with the shop logo
2. First launch: splash screen shows the shop logo + "रमेश से नहीं — सुनील भैया से" *(translated for non-Hindi reviewers: "Not from a stranger — from Sunil-bhaiya")* — using the shop's actual tagline from `ShopThemeTokens.taglineDevanagari`
3. Anonymous Auth completes silently before the splash screen finishes (no UI step)
4. ShopThemeTokens loaded; the entire app's theme is reskinned to Sunil Trading Company's colors (saddle brown / chocolate / gold / cornsilk)
5. Within 2 seconds of cold launch, the customer sees Sunil-bhaiya's photo, his shop name in Devanagari, and an auto-playing greeting voice note (with a mute toggle for the auto-play)
6. The first interactive screen is the curated shortlist landing (B1.4), not a generic browse grid
7. No OTP screen, no "create account" screen, no "welcome aboard" screen — the first screen IS the shopkeeper

**Edge cases:**
1. ShopThemeTokens not yet cached: show a Devanagari skeleton screen (not a generic loading spinner) while fetching
2. Greeting voice note not yet downloaded: play after download completes, do not block the screen
3. Customer arrives via `wa.me` deep link from Sunil-bhaiya himself (sharing a specific Project): bypass the landing and go directly to the Project view (per locked PQ2)
4. Customer arrives via a marketing-site CTA (`sunil-trading-company.yugmalabs.ai`): bypass landing if a Project context blob is in the deep link

**Dependencies:** I6.1, I6.4, I6.10, B1.2, B1.3

---

### **B1.2** — Anonymous landing with shopkeeper face 🦴

*As Sunita-ji's son, I want the first screen to be Sunil-bhaiya's face and name in Devanagari, not a catalog grid, so that I instantly know I'm in his shop, not on Amazon.*

| Field | Value |
|---|---|
| Auth tier | `anonymous` |
| Adapter | MediaStore (for face image) |
| Feature flag | None |
| Firestore reads | (covered by B1.1's 3 reads — no additional) |
| Cross-tenant test | Y |
| Refs | Brief §3 Bharosa, Brief §4.3, ADR-006 |

**Acceptance criteria:**
1. Landing screen shows Sunil-bhaiya's face photo as the dominant visual element (top 40% of screen)
2. Below the photo: shop name in large Devanagari (`सुनील ट्रेडिंग कंपनी`), tagline in slightly smaller Devanagari, GST registration number in small text, "since 2003" or actual establishment year
3. The face photo loads via the MediaStore adapter from Cloudinary with `q_auto,f_auto` transformations
4. Below the name block: a horizontal scroll of "What Sunil-bhaiya picked for you today" — this is the curated shortlist preview (links to B1.4)
5. **Top-anchored Shopkeeper Presence Dock** (NOT bottom-tab navigation — v1.0.2 patch per frontend-design plugin pushback). The Dock persists on EVERY customer-facing screen and contains: Sunil-bhaiya's avatar (44dp circular face frame), his name in Devanagari, his current presence status (`● दुकान पर हैं` / `शाadi mein hain` / etc.), and a quick voice-note play button. Navigation between sections (Shop / Chats / Orders) happens contextually via in-content CTAs and gesture-based back navigation, NOT via fixed bottom tabs. The Dock makes Sunil-bhaiya structurally inescapable on every screen — visually embodying the Brief §3 + §4.3 claim that "the shopkeeper IS the product." The complete Dock design lives in `frontend-design-bundle/lib_core/components/bharosa_landing.dart` as `_ShopkeeperPresenceDock`.
6. Pull-to-refresh updates the shop document and theme tokens
7. **English / Hindi locale toggle (v1.0.3 patch — addresses Sally's UX Spec Q2 + IR check Inconsistency #4):** A small two-state language toggle labeled `EN / हिं` is visible in the **top-right corner** of the landing screen ONLY (not on every screen — to avoid clutter while remaining discoverable). Tapping it switches the entire app's locale between Hindi (default) and English via the `intl` package. The choice persists across sessions in shared preferences. Devanagari toggle is the active state by default for every new install. The toggle is also accessible from a customer profile / settings menu (deferred to v1.5).

**Edge cases:**
1. Face photo URL returns 404: fall back to a Devanagari-styled placeholder with the shop name initial
2. The shopkeeper updates his face photo via the ops app: customer app sees the new photo on the next pull-to-refresh or app restart (Cloudinary CDN edge cache invalidation)
3. Customer is in offline mode: cached face photo + cached shop document render normally

**Dependencies:** I6.6, B1.1

---

### **B1.3** — Greeting voice note auto-play 🦴

*As Sunita-ji, I want to hear Sunil-bhaiya welcome me in his actual voice when the app opens, so that I trust this is a real human, not a chatbot.*

| Field | Value |
|---|---|
| Auth tier | `anonymous` |
| Adapter | MediaStore (for voice note audio) |
| Feature flag | None |
| Firestore reads | 1 (greeting voice note metadata, fetched as part of B1.1's 3) |
| Cross-tenant test | N |
| Refs | Brief §3 Bharosa, B1.10 (Absence Presence pairs with this), Q1 locked |

**Acceptance criteria:**
1. The greeting voice note is referenced by `ShopThemeTokens.greetingVoiceNoteId`
2. Audio file is fetched from Cloud Storage via the MediaStore adapter at `shops/sunil-trading-company/voice_notes/{voiceNoteId}.m4a`
3. Auto-play starts as soon as the audio is buffered (target: <2 seconds on 4G)
4. A small mute icon in the top-right corner allows immediate silencing
5. A "Replay" button lets the customer hear it again
6. Auto-play setting is remembered: if the customer mutes the greeting on first visit, subsequent visits do not auto-play
7. The voice note's display name shows in Devanagari: `सुनील भैया का स्वागत संदेश` ("Sunil-bhaiya's welcome message")
8. **Empty state — if greeting voice note has not yet been recorded** (newly-onboarded shop OR per pre-mortem failure mode #1 where the shopkeeper has never voluntarily recorded one): the landing screen renders the shopkeeper face frame WITHOUT the auto-play prompt, WITHOUT the play button, and WITHOUT the Devanagari "स्वागत संदेश" label below the face. The screen looks intentional, not broken. The Sunil-bhaiya face + name + tagline still anchor the landing per B1.2; only the voice-note card is suppressed. (Per Sally's UX Spec §5 + §8.7 + pre-mortem failure mode #1 — patch v1.0.3.)

**Edge cases:**
1. Audio file fails to load: silently skip; do not show an error
2. Customer is in a quiet context (silent mode detected): do not auto-play; show a "play welcome" button instead
3. Voice note is updated by the shopkeeper: customer hears the new version on next visit
4. Browser-blocked autoplay (web context, future): show a "tap to hear Sunil-bhaiya" CTA

**Dependencies:** I6.6, B1.2

---

### **B1.4** — Curated occasion shortlists ("Sunil-bhaiya ki pasand") 🦴

*As Sunita-ji's son, I want to see what Sunil-bhaiya specifically picks for weddings, new homes, dahej, replacements, and budget needs, so that I don't have to browse 200 SKUs — I see the 6 he thinks are right for me.*

| Field | Value |
|---|---|
| Auth tier | `anonymous` |
| Adapter | MediaStore (for SKU thumbnails) |
| Feature flag | None |
| Firestore reads | 5 (1 shortlist doc + 4 SKUs paginated by `limit(4)` initially) |
| Cross-tenant test | Y |
| Refs | Brief §3 "Remote control for the finger", SAD §5 CuratedShortlist, locked PQ5 |

**Acceptance criteria:**
1. The customer can browse 6 named shortlists by occasion: `शादी के लिए / नए घर के लिए / दहेज के लिए / पुराना बदलने के लिए / बजट के अनुसार / लेडीज के लिए` (For wedding / For new home / For dowry / Replacement / Budget-friendly / Ladies)
2. **Tapping a shortlist opens a vertical scroll of EXACTLY 6 SKU cards** — finite, NOT paginated (v1.0.2 patch per Sally's UX Spec §4.3 + frontend-design plugin pushback). The finiteness IS the feature: these are Sunil-bhaiya's 6 chosen picks for the occasion, not the first page of a search result. An "और दिखाइए" ("Show more") link at the bottom is the ONLY pagination escape hatch, and tapping it reveals the broader inventory browse fallback (which has its own infinite scroll for users who explicitly request it). Default behavior: 6 cards, no scroll fatigue, no "load more" CTA.
3. Each SKU card shows: Golden Hour photo (B1.5), Devanagari name, price in ₹ (with negotiable indicator), 1-line description in Hindi
4. SKU order within a shortlist is shopkeeper-curated (per locked PQ5) — drag-to-reorder happens in the ops app, customer sees the order as Sunil-bhaiya intended
5. A small "Sunil-bhaiya ki pasand" tag appears on each card (visual ownership)
6. Tapping a card opens the SKU detail screen (B1.5)
7. If a shortlist is empty (shopkeeper hasn't curated it yet), show a friendly "Sunil-bhaiya ne abhi tak nahi chuna" message

**Edge cases:**
1. Customer scrolls to bottom of shortlist: pagination loads next 4 SKUs (Firestore `startAfterDocument`)
2. Shortlist is updated mid-session by the shopkeeper: customer sees the update via Firestore real-time listener
3. SKU is removed from inventory but still in the shortlist: filter out at read time
4. All 6 shortlists are empty (e.g., shop just onboarded): show a "Sunil-bhaiya ki dukan jaldi tayyar ho rahi hai" placeholder

**Dependencies:** I6.4, I6.6, B1.2

---

### **B1.5** — SKU detail page with Golden Hour photo 🦴

*As Sunita-ji, I want to see the almirah in its Sunday-best lighting (the way Sunil-bhaiya saw it himself at 2:47 PM), so that I can judge whether it's worth visiting the shop in person.*

| Field | Value |
|---|---|
| Auth tier | `anonymous` |
| Adapter | MediaStore |
| Feature flag | None |
| Firestore reads | 2 (1 SKU doc + 1 voice note metadata if attached) |
| Cross-tenant test | Y |
| Refs | Brief §3 Golden Hour Mode, SAD §5 GoldenHourPhoto, ADR-006 |

**Acceptance criteria:**
1. Top of screen: a high-quality Golden Hour photo of the almirah (full width, ~70% of screen height)
2. Below: SKU name in Devanagari, full description, price with negotiable indicator, dimensions (height × width × depth in cm), material (steel / wood / etc.)
3. A toggle labeled `असली रूप दिखाइए` ("show real form"): tapping it switches to the working-light photo (per Maya's reframe in synthesis)
4. Below the photo: voice notes attached to this SKU play inline ("Sunil-bhaiya is is almirah ke baare mein kya kehte hain")
5. Below voice notes: 2 buttons — `इसे शॉर्टलिस्ट करें` ("Add to shortlist", which adds to a Project draft) and `सुनील भैया से बात करें` ("Talk to Sunil-bhaiya about this", which opens the chat thread with this SKU pinned as context)
6. If the SKU has multiple Golden Hour photos, swipe-able gallery
7. The "negotiable down to" floor is NOT shown to the customer (that's a shopkeeper-only field)

**Edge cases:**
1. SKU has no Golden Hour photo (newly added inventory not yet captured): show working-light photo with a small "जल्द ही असली रूप" ("real form coming soon") badge
2. Voice note audio file unavailable: silently skip; show only the SKU details
3. SKU is out of stock: show a "अभी उपलब्ध नहीं" ("not available now") banner; the chat button still works so customer can ask Sunil-bhaiya for an estimate

**Dependencies:** I6.6, B1.4

---

### **B1.6** — Voice note recording (shopkeeper-side, attached to SKU)

*As Sunil-bhaiya (in the ops app), I want to record a one-tap voice note about a specific almirah, so that customers hear me explain it in my actual voice.*

| Field | Value |
|---|---|
| Auth tier | `googleOperator` |
| Adapter | MediaStore (Firebase Storage path) |
| Feature flag | None |
| Firestore reads | 1 (load SKU to attach to) |
| Cross-tenant test | Y |
| Refs | Brief §3 Bharosa, SAD §5 VoiceNote, locked PQ4 |

**Acceptance criteria:**
1. From any SKU detail screen in the ops app, a prominent "🎤 आवाज़ नोट" ("voice note") button starts recording on press, stops on release
2. Recording duration: 5 seconds minimum, 60 seconds maximum
3. After recording: 3 buttons — `भेज दीजिए` (send), `दुबारा रिकॉर्ड करें` (re-record), `रद्द करें` (cancel)
4. On send: audio file uploaded to `gs://yugma-dukaan-{env}.appspot.com/shops/sunil-trading-company/voice_notes/{voiceNoteId}.m4a` via MediaStore adapter
5. Firestore VoiceNote document created with `attachedTo: {type: "sku", refId: <skuId>}`
6. The SKU's customer-facing detail page (B1.5) refreshes to show the new voice note inline via Firestore real-time listener
7. Recording UI shows a waveform during recording and a duration counter
8. No transcription in v1 (deferred to v1.5)

**Edge cases:**
1. Microphone permission not granted: prompt with explanation in Hindi
2. Network unavailable during upload: queue locally, retry on reconnect; show a "अपलोड बाकी है" ("upload pending") badge until success
3. Recording exceeds 60 seconds: auto-stop and show "60 seconds reached"
4. Voice note already exists for this SKU: append (multiple voice notes per SKU allowed)

**Dependencies:** S4.1, S4.3 *(v1.0.1 patch — was S4.4; B1.6 needs inventory to exist, not edit capability)*

---

### **B1.7** — Voice note attached to Project (shopkeeper response in chat)

*As Sunil-bhaiya, I want to drop a voice note in a customer's Project chat thread, so that I can answer her question about polish or delivery date in my actual voice — not by typing.*

| Field | Value |
|---|---|
| Auth tier | `googleOperator` |
| Adapter | MediaStore + CommsChannel |
| Feature flag | None |
| Firestore reads | 1 (load Project to attach voice note metadata) |
| Cross-tenant test | Y |
| Refs | SAD §5 VoiceNote, ADR-005 |

**Acceptance criteria:**
1. In the Project chat detail screen of the ops app, a "🎤" button is always visible
2. Same recording flow as B1.6 (press to record, release to stop)
3. Voice note uploads to `shops/sunil-trading-company/voice_notes/{voiceNoteId}.m4a`
4. A new Message document is created in `shops/sunil-trading-company/chat_threads/{projectId}/messages/{messageId}` with `type: "voice_note"` and `voiceNoteId: <id>`
5. The customer's chat screen refreshes via Firestore real-time listener; the voice note appears with a play button and Sunil-bhaiya's name + timestamp
6. The Project document's `lastMessagePreview` is updated to `🎤 आवाज़ नोट` with `lastMessageAt: serverTimestamp()`
7. FCM push notification sent to the customer's device

**Edge cases:**
1. Customer is currently viewing the chat: skip the FCM push (in-app render is sufficient)
2. Voice note > 60 seconds: hard cap, auto-stop
3. Customer's device doesn't support audio playback: rare, but show a download fallback

**Dependencies:** I6.5, I6.6, S4.9

---

### **B1.8** — Shop landing voice note (welcome greeting management)

*As Sunil-bhaiya, I want to update the welcome voice note that every customer hears when they open my app, so that I can change my greeting for festivals, sales, or just because I want to.*

| Field | Value |
|---|---|
| Auth tier | `googleOperator` (bhaiya role only) |
| Adapter | MediaStore |
| Feature flag | None |
| Firestore reads | 1 (load current ShopThemeTokens) |
| Cross-tenant test | Y |
| Refs | Brief §3 Bharosa landing, B1.3 |

**Acceptance criteria:**
1. In ops app Settings, a "स्वागत संदेश" ("welcome message") section shows the current greeting voice note with play + replace controls
2. Tapping "Replace": same recording flow as B1.6, but on send the `ShopThemeTokens.greetingVoiceNoteId` field is updated to the new voice note ID
3. The version field on `ShopThemeTokens` is bumped, which invalidates the customer app's cached theme on next open
4. Old greeting voice note is NOT deleted (kept in storage as a historical record)
5. Only the bhaiya role can update the greeting (beta and munshi cannot)
6. A preview button lets the shopkeeper hear how the new greeting will sound to the customer before committing
7. A "Reset to default" button restores the previous greeting

**Edge cases:**
1. Shopkeeper records a greeting in a noisy environment: no automated quality check, but a "अगली बार ज़्यादा शांत जगह में करें" ("try a quieter spot next time") tip shows after recording if amplitude variance suggests background noise
2. Multiple shopkeepers (bhaiya + son) try to update simultaneously: last write wins, both see a confirmation toast
3. Old voice note storage accumulates: a future cleanup function (v1.5) deletes greeting versions older than 6 months

**Dependencies:** I6.6, S4.14

---

### **B1.9** — Absence Presence status (shopkeeper unavailable banner)

*As Sunita-ji, I want the app to tell me honestly when Sunil-bhaiya isn't available right now — at a wedding, asleep, or with another customer — so that I don't think I'm being ignored.*

| Field | Value |
|---|---|
| Auth tier | `anonymous` (customer-side read) / `googleOperator` (shopkeeper-side write) |
| Adapter | None |
| Feature flag | None |
| Firestore reads | 1 (Shop document carries presence status field) |
| Cross-tenant test | Y |
| Refs | Brief §3 Absence Presence, SAD §5 Shop entity |

**Acceptance criteria:**
1. The Shop document has a `presenceStatus` field with values: `available` / `away` / `busy_with_customer` / `at_event`
2. Each status has an associated message: e.g., `away` → `सुनील भैया अभी दुकान पर नहीं हैं — 6 बजे तक वापस आएंगे` ("Sunil-bhaiya is not at the shop right now — back by 6 PM")
3. The shopkeeper updates the status from a quick-toggle in the ops app (a single screen, 4 buttons, no nesting)
4. When status is `away` or `at_event`, the Shop landing screen shows a soft banner at the top with the message + an estimated return time
5. The banner does NOT prevent the customer from browsing or chatting — it just sets expectations
6. Auto-revert: if status is `away` and the estimated return time passes, status auto-reverts to `available` (via a small Cloud Function or scheduled Firestore update)

**Edge cases:**
1. Shopkeeper forgets to update status: banner stays stale; the auto-revert handles the most common case
2. Multiple operators (bhaiya + son) update status simultaneously: last write wins
3. Customer arrives during `at_event`: still allowed to chat; messages are queued and Sunil-bhaiya sees them on his return

**Dependencies:** S4.1, S4.14

---

### **B1.10** — Pre-recorded "away" voice note fallback

*As Sunita-ji, I want to hear Sunil-bhaiya's actual voice explaining why he's away and offering an alternative ("talk to my son Aditya"), so that the absence still feels personal.*

| Field | Value |
|---|---|
| Auth tier | `anonymous` |
| Adapter | MediaStore |
| Feature flag | None |
| Firestore reads | 1 (presence status carries voice note ref) |
| Cross-tenant test | N |
| Refs | Brief §3 Bharosa Absence-as-Presence |

**Acceptance criteria:**
1. The Shop document's presence status carries an optional `awayVoiceNoteId` field
2. When status is `away` or `at_event`, the customer-side banner has a small play button next to the text
3. Tapping the play button plays Sunil-bhaiya's pre-recorded voice note: e.g., *"Main aaj shaadi mein hoon, par aap mere bete Aditya se baat kar sakte hain — wo aapki madad karega."*
4. The shopkeeper records the voice note via ops app Settings (re-uses B1.8's recording flow)
5. Multiple "away" voice notes can be saved for different scenarios (wedding, festival, sleep, sick), and the shopkeeper picks one when setting status
6. If no voice note is set, the banner shows only the text

**Edge cases:**
1. Voice note audio fails to load: text banner alone is sufficient
2. Customer plays the voice note multiple times: standard audio player behavior
3. Shopkeeper never records any away voice notes: the feature gracefully degrades to text-only

**Dependencies:** B1.6 (recording flow), B1.9 (status field)

---

### **B1.11** — Customer memory layer (shopkeeper-side notes about a customer)

*As Sunil-bhaiya, I want to write private notes about each customer ("Sunita-ji ki saas ne 2019 mein humari Storwel li thi, bahut khush"), so that when she or her family returns to the app, I can pick up the relationship from where it left off.*

| Field | Value |
|---|---|
| Auth tier | `googleOperator` (read + write) |
| Adapter | None |
| Feature flag | None |
| Firestore reads | 1 (load CustomerMemory document) |
| Cross-tenant test | **Y — critical: customer must NEVER see this** |
| Refs | SAD §5 CustomerMemory entity, SAD §6 security rules (operator-only access) |

**Acceptance criteria:**
1. CustomerMemory document at `shops/sunil-trading-company/customer_memory/{customerUid}` is operator-write, operator-read only — customer must NOT have read access
2. Security rule integration test asserts the customer's own `customerUid` cannot read their own memory document
3. Ops app Customer detail screen shows the memory notes prominently when a known customer is interacting
4. Free-text notes field with a 500-character limit
5. Structured fields: `relationshipNotes` (relations to other customers), `preferredOccasions` (multi-select), `preferredPriceRange` (min/max), `firstSeenAt`, `lastSeenAt`, `totalProjectsLifetime`
6. The shopkeeper can quickly link a customer to another customer ("this is Sunita-ji's daughter" → tap to connect)
7. Customer memory notes are displayed in the ops app whenever the operator opens a chat thread or Project from this customer

**Edge cases:**
1. Customer's anonymous UID changes (rare — clear app data): the memory is orphaned; a future v1.5 reconciliation flow attempts to merge based on phone number or relationship hints
2. Memory document is empty for a new customer: ops app shows "नया ग्राहक — पहली बार" ("new customer — first time") instead
3. Customer never phone-verifies: memory is keyed by anonymous UID; if the device is replaced, memory is orphaned

**Dependencies:** I6.4, S4.11

---

### **B1.12** — "Remote control for the finger" curation UX (shopkeeper-side)

*As Sunil-bhaiya, I want a single screen in the ops app where I can see all 6 occasion shortlists at a glance and one-tap promote / demote / reorder SKUs in each, so that updating my curation is a 30-second daily ritual, not a chore.*

| Field | Value |
|---|---|
| Auth tier | `googleOperator` |
| Adapter | None |
| Feature flag | None |
| Firestore reads | 7 (6 shortlists + inventory list pagination) |
| Cross-tenant test | Y |
| Refs | Brief §3 "Remote control for the finger" reframe, locked PQ5 |

**Acceptance criteria:**
1. Single screen titled `मेरी पसंद` ("My picks") in the ops app
2. Six tabs: `शादी / नए घर / दहेज / बदलने के लिए / बजट / लेडीज` (the 6 occasion shortlists)
3. Each tab shows: current shortlist as a vertical drag-to-reorder list of SKU cards
4. Below the current shortlist: "Add from inventory" — a horizontal scroll of all SKUs not yet in this shortlist, tap-to-add
5. Long-press on a SKU in the shortlist removes it
6. Drag-handle on each card lets the operator reorder
7. Save is automatic — no "Save" button; every change writes immediately to Firestore
8. A small badge on each tab shows how many SKUs are in that shortlist (0–N)

**Edge cases:**
1. Operator drags a SKU mid-network-failure: write is queued, optimistic UI updates immediately, syncs on reconnect
2. Two operators editing the same shortlist: last write wins; the UI smoothly updates the second operator's view via Firestore real-time listener
3. Inventory has 200+ SKUs: the "add from inventory" scroll is paginated and searchable in Hindi

**Dependencies:** S4.1, S4.3 *(v1.0.1 patch — was S4.4; B1.12 reads inventory but does not edit SKUs)*

---

### **B1.13** — Devanagari invoice / receipt with shopkeeper signature *(v1.0.5 add per Winston's SAD v1.0.4 handoff, Brief §3 Bharosa, audit gap #4)*

*As Sunita-ji (after her order is delivered), I want a dignified Devanagari invoice with Sunil-bhaiya's shop name, my order details, the total, and his handwritten-style signature in the footer — savable as a PDF — so that I have a physical-looking record of my purchase that honors the shopkeeper's identity instead of a generic SaaS receipt.*

| Field | Value |
|---|---|
| Auth tier | `phoneVerified` |
| Adapter | None (client-side PDF generation per SAD v1.0.4 ADR-015) |
| Feature flag | None |
| Firestore reads | 3 (Project + Shop + optional Customer for display name) |
| Cross-tenant test | Y |
| Refs | Brief §3 Bharosa "plain dignified invoices", SAD v1.0.4 ADR-015 client-side PDF, Brief §8 Constraint 4 font stack |

**Acceptance criteria:**
1. From any `closed` or `delivered` Project in the customer app, an `रसीद देखें` ("View receipt") button opens the invoice rendering screen. Same button available from the shopkeeper ops app Project detail view (for shopkeeper's own records / WhatsApp-sharing back to customer).
2. Invoice is generated client-side via the `pdf` Dart package using the template at `packages/lib_core/lib/src/invoice/invoice_template.dart`. No Cloud Function. Works fully offline (per ADR-015).
3. **Header:** shop logo (top-left), shop name in large Tiro Devanagari Hindi (`सुनील ट्रेडिंग कंपनी`), address, GST number, "since 2003" (established year from Shop doc), shop's phone number and UPI VPA — all pulled from `ShopThemeTokens`.
4. **Body:** Project ID (last 6 chars of ULID, big), date in Devanagari format (`11 अप्रैल 2026`), customer display name (fallback chain per locked PQ3), line items table with Devanagari names + quantities + unit price + line total, subtotal, total (bold, larger), payment method (UPI / COD / bank / udhaar) in Devanagari.
5. **Footer:** the Hindi line `धन्यवाद, आपका विश्वास हमारा भविष्य है` ("Thank you — your trust is our future") — no mythic, no religious, no poetic copy beyond this one line. Below it, the shopkeeper's handwritten-style signature rendered in **Mukta italic at a larger size** as an approximation of a handwritten signature — this is a deliberate Constraint 4 compliance choice to stay inside the approved 5-font stack (Tiro Devanagari Hindi + Mukta + Fraunces + EB Garamond + DM Mono) rather than add Caveat or any new Google Font. If a future release adds a real captured-signature-image option, it lives on the Shop document as `shopkeeperSignatureImageUrl` (already specified in SAD v1.0.4 ADR-015 `InvoicePayload`) and replaces the Mukta italic fallback.
6. **Numerics** (prices, totals, project ID) render in DM Mono per Constraint 4 font stack so Rupee figures are unambiguous across devices.
7. The rendered PDF is saved to the device's local storage (Android: `Downloads/yugma-dukaan/receipts/`; iOS: app Documents directory) and a platform-native share sheet opens with WhatsApp, Gmail, Drive, and Print options pre-populated.
8. File name convention: `रसीद_{shortProjectId}_{date}.pdf`.
9. The PDF embeds the same subset-loaded Devanagari font faces already in the customer app binary — no additional payload, no network fetch for fonts, per ADR-015 consequence analysis.
10. Cross-tenant integrity test: an invoice for a Project in `shop_1` cannot be generated by a customer authenticated against `shop_0` (the Firestore read for the Project fails first, but the template also guards on `shop.shopId == project.shopId`).

**Edge cases:**
1. Project has no `customerDisplayName` and no UPI VPA fragment: receipt shows "ग्राहक" ("Customer") as a placeholder. No friction screen asking the customer to enter their name (per PRD Standing Rule 8).
2. Udhaar khaata is open: the receipt body shows `बकाया: ₹X` ("balance due: ₹X") clearly but NEVER the words "interest", "EMI", "due date" or any forbidden vocabulary per ADR-010 / Standing Rule 9.
3. Project has >10 line items: template paginates onto a second page with `pageBreak` directive.
4. Shop has no uploaded logo: Devanagari shop-name initial renders in a circle as a Bharosa-style fallback (matching B1.2 AC #1 treatment).
5. Invoice generated for a `cancelled` Project: the template renders but prints a watermark `रद्द` ("cancelled") diagonally across the page.
6. Customer attempts to generate an invoice for a Project that isn't theirs: Firestore security rule blocks the read; app shows "यह ऑर्डर नहीं मिला" ("order not found").

**Dependencies:** I6.4 (multi-tenant), I6.9 (Devanagari font subset), C3.4 (Project must be committed), S4.12 (Shop branding must be set for header)

**Walking Skeleton?** No — depth story on top of the commit flow. Ships in Sprint 4 or 5 per Phase 3 sequencing.

---

## Epic E2 — Pariwar / Decision Circle

*Committee-native browse + chat. The committee is the unit of decision-making; the device is shared, the personas rotate, the shopkeeper is the gravitational center.*

### **P2.1** — Decision Circle session creation (feature-flagged)

*As Sunita-ji (the buyer-of-record, even though her son holds the phone), I want my family's decision-making to be tracked as a single thread that all of us can see, so that nobody has to repeat themselves.*

| Field | Value |
|---|---|
| Auth tier | `anonymous` |
| Adapter | None |
| Feature flag | **`decisionCircleEnabled`** (default: `true`) |
| Firestore reads | 1 (load DecisionCircle if exists) |
| Cross-tenant test | Y |
| Refs | Brief §3 Pariwar, SAD §5 DecisionCircle (optional schema), ADR-009, R11 |

**Acceptance criteria:**
1. When the customer creates a Project draft (C3.1), a DecisionCircle document is auto-created at `shops/sunil-trading-company/decision_circles/{projectId}` with the customer's anonymous UID as the first participant
2. The DecisionCircle document has a `participants` array with `{sessionId, personaLabel, deviceId, lastSeenAt}` for each session
3. If `decisionCircleEnabled` is `false`, the DecisionCircle document is NOT created and the customer experience falls back to a simpler single-user flow
4. Cross-tenant test: a `shop_1` customer cannot read or write `shop_0/decision_circles/*`
5. The DecisionCircle is removable: deleting the document does not affect the Project (per ADR-009)

**Edge cases:**
1. Feature flag flips from `true` to `false` mid-session: existing DecisionCircle documents remain readable but no new ones are created
2. Feature flag flips from `false` to `true`: new Projects start creating DC documents from that point forward
3. The DecisionCircle document is deleted while a Project is active: the Project continues to function (DC is optional)

**Dependencies:** I6.4, I6.7, C3.1

---

### **P2.2** — Guest Mode persona toggle ("Mummy-ji dekh rahi hain")

*As the device-holder (Sunita-ji's son), I want to toggle the UI to "Mummy-ji is looking" before I hand the phone to my mother, so that she sees larger fonts, slower animations, and a more respectful tone without me having to teach her the app.*

| Field | Value |
|---|---|
| Auth tier | `anonymous` |
| Adapter | None |
| Feature flag | **`guestModeEnabled`** (default: `true`, sub-feature of decisionCircleEnabled) |
| Firestore reads | 0 (session state lives in Riverpod persistence, not Firestore) |
| Cross-tenant test | N |
| Refs | Brief §3 Pariwar Guest Mode, ADR-009 |

**Acceptance criteria:**
1. A persistent button in the bottom-right corner of every customer-app screen labeled with the current persona: `मैं देख रहा हूँ` (default — "I am looking") → tap to switch
2. Tapping opens a sheet with persona options: `मैं / मम्मी जी / पापा जी / भाभी / दादी / चाचा जी / कोई और` (Me / Mummy-ji / Papa-ji / Bhabhi / Dadi / Chacha-ji / Someone else)
3. Selecting a persona changes the UI tier:
   - Default ("मैं"): standard density
   - Elder personas (Mummy-ji, Papa-ji, Dadi, Chacha-ji): larger fonts (~140%), slower transitions, larger photos, louder voice note default volume, simpler navigation
4. The current persona is displayed in the top bar of every screen so the device-holder always knows which persona is active
5. The persona selection is stored in Riverpod persistence and survives app restarts
6. The DecisionCircle Firestore document is updated with `currentActivePersona: <label>` so the shopkeeper sees who is currently looking
7. If `guestModeEnabled` is `false`, the toggle button is hidden and the UI is always at the default tier

**Edge cases:**
1. Persona toggle while a voice note is playing: voice note volume adjusts on the fly to match the new persona's preferred volume
2. Persona "Someone else" lets the user enter a custom label (free text, max 20 chars) — useful for cousins or unusual relations
3. Multiple personas in rapid succession (passing the phone fast): each toggle is independent; the most recent one applies
4. Feature flag is off: button hidden, but stored persona state is preserved for when the flag flips back on

**Dependencies:** I6.7, P2.1

---

### **P2.3** — UI tier rendering for elder persona

*As Mummy-ji (looking at the phone her son just handed me), I want the screen to be readable, slow, and respectful, so that I don't feel lost in a fast app made for young people.*

| Field | Value |
|---|---|
| Auth tier | `anonymous` |
| Adapter | None |
| Feature flag | `guestModeEnabled` |
| Firestore reads | 0 |
| Cross-tenant test | N |
| Refs | Brief §3 Pariwar Guest Mode |

**Acceptance criteria:**
1. When `currentActivePersona` is an elder persona, the customer app's `ThemeData` is rebuilt with:
   - Text size: 1.4× base
   - Animation duration: 1.5× standard
   - Photo aspect ratio in cards: increased to give more visual space
   - Voice note default playback volume: louder
   - Tap target sizes: minimum 48dp → 56dp
   - Navigation: bottom tabs become labeled buttons, no icon-only states
2. The transition from default to elder tier is smooth (animated theme change, ~300ms)
3. Returning to default persona reverses the changes
4. The Devanagari font weight stays consistent (no bold escalation, which would clip on cheap Android)

**Edge cases:**
1. Elder tier on a small-screen device (4.5"): scrollable layouts; nothing clips
2. User toggles persona during a chat thread: chat messages re-render at the new size in place
3. Elder tier respects system accessibility settings (does not override OS-level large text if enabled)

**Dependencies:** I6.9, P2.2

---

### **P2.4** — "Sunil-bhaiya Ka Kamra" unified chat thread 🦴

*As Sunita-ji's son, I want a single chat thread per Project where Sunil-bhaiya talks to all of us — not five separate WhatsApp groups — so that the conversation has a clear timeline and Sunil-bhaiya doesn't have to repeat himself.*

| Field | Value |
|---|---|
| Auth tier | `anonymous` (eitherCustomer for read; auth-tier-agnostic for posting if flag allows) |
| Adapter | **CommsChannel** |
| Feature flag | `commsChannelStrategy` (default: `firestore`) |
| Firestore reads | 1 (chat thread doc) + 10 (initial 10 messages, paginated) = 11 |
| Cross-tenant test | Y |
| Refs | Brief §3 "Ramesh-bhaiya Ka Kamra" (renamed for Sunil), SAD §5 ChatThread + Message, ADR-005 |

**Acceptance criteria:**
1. Each Project has exactly one ChatThread at `shops/sunil-trading-company/chat_threads/{projectId}` (1:1 with Project)
2. Messages live in the sub-sub-collection `shops/sunil-trading-company/chat_threads/{projectId}/messages/{messageId}`
3. Customer-side: opening a Project shows a "Sunil-bhaiya से बात करें" button; tapping opens the chat thread screen
4. Chat thread screen shows messages oldest-to-newest, paginated by `limit(20)` initially with infinite scroll for older messages
5. The thread title is `सुनील भैया का कमरा — आपका ऑर्डर #<projectId-suffix>` ("Sunil-bhaiya's room — your order #X")
6. Each message shows: sender label (`आप` for the current customer or `सुनील भैया` for the shopkeeper), timestamp in Hindi-formatted relative time (e.g., "2 ghante pehle"), message body
7. Message types supported: text, voice note (with inline player), image (for shopkeeper to share inventory photos), system (state transitions like "Project committed")
8. Real-time updates via Firestore listener; new messages appear without refresh
9. Unread badge on the bottom navigation tab when there are unread messages
10. If `commsChannelStrategy` is `whatsapp`, this screen redirects to a `wa.me` link with the Project context blob (via `generateWaMeLink` Cloud Function)

**Edge cases:**
1. Customer opens chat while offline: cached messages load from Firestore offline cache; new messages typed are queued and sent on reconnect
2. Shopkeeper sends a voice note: customer's screen plays a sound notification (if not in silent mode) and the new message appears at the bottom
3. Multiple customer participants on the same Project (Decision Circle scenario): all see the same messages; the persona label is shown next to each customer-side message
4. Message arrives while the customer is in elder persona tier: rendering uses the elder font size automatically

**Dependencies:** I6.4, I6.5, C3.1, P2.1

---

### **P2.5** — Customer sends text message in chat 🦴

*As Sunita-ji's son, I want to type a question in Hindi and send it to Sunil-bhaiya, so that I can ask about polish, delivery, or price without making a phone call.*

| Field | Value |
|---|---|
| Auth tier | `anonymous` (eitherCustomer) |
| Adapter | CommsChannel |
| Feature flag | `commsChannelStrategy` |
| Firestore reads | 0 (this is a write) |
| Cross-tenant test | Y |
| Refs | SAD §5 Message, ADR-005 |

**Acceptance criteria:**
1. Chat thread screen has a text input at the bottom with a Devanagari placeholder: `यहाँ संदेश लिखिए...` ("Type your message here...")
2. Indic keyboard support (Hindi input method on Android) — typing in Devanagari works natively
3. A "Send" button (icon) sends the message to Firestore
4. The message appears immediately in the thread (optimistic UI) with a small clock icon while pending; checkmark when delivered
5. Message is written to `shops/sunil-trading-company/chat_threads/{projectId}/messages/{messageId}` with `type: "text"`, `authorUid: <anonymous-uid>`, `authorRole: "customer"`, `textBody: <input>`, `sentAt: serverTimestamp()`
6. The Project document's `lastMessagePreview` and `lastMessageAt` and `unreadCountForShopkeeper` are updated atomically
7. FCM push notification sent to shopkeeper's device

**Edge cases:**
1. Customer types and goes offline before sending: the message is stored in Riverpod draft state, sent on reconnect
2. Empty message: send button disabled
3. Message > 1000 characters: truncated with a warning
4. Profanity / spam: not filtered in v1 (deferred); shopkeeper has a "block this customer" option in ops app

**Dependencies:** P2.4

---

### **P2.6** — Voice message rendering in chat (customer-side view of shopkeeper voice notes)

*As Sunita-ji, I want to play Sunil-bhaiya's voice notes inline in the chat without leaving the screen, so that the conversation feels seamless.*

| Field | Value |
|---|---|
| Auth tier | `anonymous` |
| Adapter | MediaStore (for audio file fetch) |
| Feature flag | None |
| Firestore reads | 0 (voice note ref is in the message doc) |
| Cross-tenant test | N |
| Refs | B1.7 (companion: shopkeeper-side recording) |

**Acceptance criteria:**
1. Messages with `type: "voice_note"` render as an audio player widget inline in the chat
2. Player shows: play/pause button, waveform or duration bar, total duration, current playback position, sender label (`सुनील भैया`)
3. Tapping play fetches the audio from Cloud Storage (signed URL) and starts playback
4. Multiple voice notes in a thread: only one plays at a time (auto-pause when another starts)
5. Audio file is cached locally after first play (Firebase Storage SDK handles this)
6. Playback survives screen rotation and bottom-tab switches

**Edge cases:**
1. Voice note file fails to load: show "अभी प्ले नहीं हो रहा — पुनः प्रयास करें" ("not playing right now — try again") with a retry button
2. Customer is on a metered connection: prompt before downloading large voice notes (>500 KB)
3. Voice note is corrupted: graceful failure with the same retry message

**Dependencies:** I6.6, P2.4

---

### **P2.7** — Multi-participant message read tracking

*As the device-holder, I want to know which family members have already seen which messages, so that I don't have to ask "Did Mummy-ji see Sunil-bhaiya's reply yet?"*

| Field | Value |
|---|---|
| Auth tier | `anonymous` |
| Adapter | None |
| Feature flag | `decisionCircleEnabled` (read tracking is part of Decision Circle) |
| Firestore reads | 0 (write only) |
| Cross-tenant test | N |
| Refs | SAD §5 Message.readByUids, P2.1 |

**Acceptance criteria:**
1. Each Message document has a `readByUids` array
2. When a customer views a message in their chat thread, the message is marked as read by adding the current persona's session ID to `readByUids`
3. Messages show a small "देखा गया" ("seen") indicator with persona labels: e.g., `मम्मी जी ने देखा, पापा जी ने नहीं` ("Mummy-ji saw it, Papa-ji didn't")
4. The shopkeeper's ops app sees the same read status from the customer's side
5. If `decisionCircleEnabled` is `false`, read tracking still works at the per-customer-device level, just without persona attribution

**Edge cases:**
1. Customer opens a long chat thread: only currently-visible messages are marked read (not the entire thread)
2. Persona switches while a message is on screen: read attribution goes to whichever persona was active when the message scrolled into view
3. The customer doesn't have Decision Circle enabled: read indicator simply shows "देखा गया" without persona label

**Dependencies:** P2.1, P2.4

---

### **P2.8** — Decision Circle off-state fallback (large-text accessibility toggle)

*As Sunita-ji, I want the larger text and slower pacing even if Decision Circle isn't running on this Project, because my eyes are 52 years old.*

| Field | Value |
|---|---|
| Auth tier | `anonymous` |
| Adapter | None |
| Feature flag | None (this is the universal fallback) |
| Firestore reads | 0 (stored in device prefs) |
| Cross-tenant test | N |
| Refs | R11 fallback strategy from Mary's elicitation |

**Acceptance criteria:**
1. In the customer app Settings (or accessible from any screen via a small ⚙️ button), a single toggle: `बड़ा अक्षर` ("large text")
2. When toggled on, the customer app applies the elder UI tier (per P2.3) regardless of Decision Circle state
3. The toggle is stored in shared preferences and survives app restarts
4. This toggle works even if `decisionCircleEnabled` is `false` (Decision Circle has been killed)
5. Accessible without needing to be in a Decision Circle session
6. If the customer is in a Decision Circle session AND the toggle is on, the elder tier renders (no conflict)

**Edge cases:**
1. Customer toggles on, then opens a Decision Circle session as a non-elder persona: elder tier still applies (toggle wins)
2. System accessibility settings already enable large text: app respects both
3. Toggle is the *only* mechanism for accessibility if R11 fires and Decision Circle is permanently disabled

**Dependencies:** I6.9, P2.3

---

## Epic E3 — Commerce & Project Flow

*The actual buying. Project creation, line items, negotiation via chat, commit with Phone OTP, UPI/COD/bank/udhaar payment, delivery tracking. The integration epic — touches every other epic.*

### **C3.1** — Create Project draft from a curated SKU 🦴

*As Sunita-ji's son, I want to start an order for a specific almirah Sunil-bhaiya recommended, so that I can show it to my family before deciding.*

| Field | Value |
|---|---|
| Auth tier | `anonymous` |
| Adapter | None |
| Feature flag | None |
| Firestore reads | 1 (load SKU snapshot) |
| Cross-tenant test | Y |
| Refs | SAD §5 Project, Brief §3 Bharosa flow |

**Acceptance criteria:**
1. From any SKU detail screen (B1.5), a button `इसे शॉर्टलिस्ट करें` ("Add to my list") creates a new Project draft if none exists, or adds the SKU to the existing draft
2. Project document is created at `shops/sunil-trading-company/projects/{projectId}` with `state: "draft"`, `customerUid: <anonymous-uid>`, `lineItemsCount: 1`, embedded LineItem with the SKU snapshot
3. The customer is shown a confirmation toast: `रमेश-बहन (or whichever SKU) आपकी सूची में जोड़ी गयी` ("Added to your list")
4. A bottom-sheet "draft project" indicator appears showing line items count and total
5. If `decisionCircleEnabled`, a DecisionCircle document is auto-created (P2.1)

**Edge cases:**
1. Customer adds the same SKU twice: increments quantity instead of adding a duplicate line item
2. Customer creates a draft and abandons the app: draft persists in Firestore for 30 days, then a cleanup function deletes orphaned drafts
3. Customer creates a draft on Phone A, then opens the app on Phone B: drafts are device-scoped (anonymous UID is per-device); cross-device drafts are not supported in v1

**Dependencies:** I6.4, B1.5

---

### **C3.2** — Add / edit / remove line items in a draft Project

*As Sunita-ji's son, I want to add a dressing table along with the almirah, change the quantity, or remove an item I changed my mind about, before showing the family the final list.*

| Field | Value |
|---|---|
| Auth tier | `anonymous` |
| Adapter | None |
| Feature flag | None |
| Firestore reads | 0 (writes only on the existing Project) |
| Cross-tenant test | Y |
| Refs | SAD §5 Project + LineItem |

**Acceptance criteria:**
1. From the draft Project view, a customer can add more SKUs by tapping any "Add to list" button on a SKU detail screen
2. From the Project detail view, each line item has + / − quantity controls and a "remove" swipe action
3. Editing line items updates the embedded array on the Project document and recomputes `lineItemsCount` and `totalAmount` denormalized fields
4. Line items have a snapshot of the SKU at the time of addition (per SAD §5 LineItem definition)
5. Removing the last line item from a draft Project deletes the entire Project document

**Edge cases:**
1. Network unavailable during edit: optimistic UI; sync on reconnect
2. SKU is removed from inventory after being added to a Project draft: snapshot preserves the price and details; warning shown to customer
3. Quantity > 10 of a single SKU: confirmation prompt (unusual for almirahs)

**Dependencies:** C3.1

---

### **C3.3** — Negotiation flow via chat

*As Sunita-ji's son, I want to ask Sunil-bhaiya for a discount in the chat thread and have his counter-offer recorded directly against this Project, so that I don't have to remember it later.*

| Field | Value |
|---|---|
| Auth tier | `anonymous` |
| Adapter | CommsChannel (the chat thread) |
| Feature flag | None |
| Firestore reads | 0 (chat messages, no extra reads beyond P2.5) |
| Cross-tenant test | Y |
| Refs | Brief §5 Persona D negotiation culture, P2.5 |

**Acceptance criteria:**
1. The chat thread (P2.4) is the negotiation surface — there is no separate "make an offer" UI in v1
2. The shopkeeper can send a special message type: `type: "price_proposal"` with `proposedPrice: <amount>` and `lineItemId: <id>`
3. Customer-side, this message renders with an "Accept" button that updates the LineItem's `finalPrice` field
4. Multiple counter-proposals are allowed; only the most recent accepted one is applied
5. The Project's `totalAmount` updates atomically when an accepted proposal changes a line item price
6. A history of price proposals is preserved in the chat thread for auditability

**Edge cases:**
1. Shopkeeper proposes a price below his `negotiableDownTo` floor: ops app warns him but allows it (his call)
2. Customer accepts a stale proposal that the shopkeeper already retracted: server-side validation rejects; a Cloud Function call would be cleaner here, but for v1 it's a Firestore transaction with version checks
3. Multiple line items each with their own proposals: each tracked independently

**Dependencies:** C3.2, P2.5

---

### **C3.4** — Commit Project (state transition draft → committed) 🦴

*As Sunita-ji's son, I want to "place the order" once the family has agreed, so that Sunil-bhaiya knows we are serious and the delivery clock starts.*

| Field | Value |
|---|---|
| Auth tier | `anonymous` → `phoneVerified` (upgrade flow at this step if `otpAtCommitEnabled`) |
| Adapter | AuthProvider |
| Feature flag | **`otpAtCommitEnabled`** (default: `true`, R12) |
| Firestore reads | 1 (load latest Project state for transaction) |
| Cross-tenant test | Y |
| Refs | SAD §4 Flow 1, ADR-002, ADR-009, R12 |

**Acceptance criteria:**
1. From the Project detail view, a prominent button `ऑर्डर पक्का कीजिए` ("Confirm the order") is visible when the Project state is `draft` or `negotiating`
2. Tapping the button:
   - If `otpAtCommitEnabled` is `true` AND the customer is `anonymous`: triggers the Phone Auth OTP upgrade flow (per I6.2). On successful upgrade, the Project state transitions to `committed` via a Firestore transaction.
   - If `otpAtCommitEnabled` is `false`: skips OTP entirely; transitions Project state directly to `committed`
3. The Firestore transaction sets `state: "committed"`, `committedAt: serverTimestamp()`, and prevents double-commit by asserting `state in ['draft', 'negotiating']` before the write
4. **Triple Zero invariant (v1.0.5 patch per SAD v1.0.4 §5 Project schema + finding F3).** The same commit transaction MUST set `amountReceivedByShop == totalAmount` — no commission, no platform fee, no interception. This is not a display field; it is an architectural invariant on every closed Project. The cross-tenant integrity test enforces this on every CI build: for any Project where `state in ['committed', 'paid', 'delivering', 'closed']`, the test asserts `amountReceivedByShop == totalAmount`. An acceptance-level unit test in `project_repo_test.dart` must assert the invariant at commit-time, not just display-time. If the math ever diverges, CI fails loudly. This makes the zero-commission promise machine-verifiable rather than a marketing claim.
5. After commit, the customer sees a confirmation screen with the Project ID, total amount, line items, and "Now choose how to pay" CTA leading to C3.5
6. FCM push to shopkeeper: `नया ऑर्डर — Sunita-ji से ₹22,000` ("New order — from Sunita-ji for ₹22,000")
7. The shopkeeper's ops app dashboard lights up with the new committed Project
8. **Standing Rule 11 compliance (v1.0.5 patch).** The commit transaction is the canonical example of a Project state transition and MUST be written as a `ProjectOperatorPatch` (from the customer app this is a special-cased "promote-to-operator-patch" path that the security rules allow only for the `state: draft → committed` transition when `request.auth.uid == resource.data.customerUid`). No `ProjectCustomerPatch` may mutate `state`, `committedAt`, `amountReceivedByShop`, or `totalAmount` outside this one transition.

**Edge cases:**
1. OTP upgrade fails: customer stays on the Project draft view; error message in Devanagari; can retry
2. OTP upgrade succeeds but the Firestore transaction to commit fails: the customer is now phone-verified but the Project is still draft; retry the commit (idempotent)
3. Network drops mid-commit: transaction either succeeds or fully fails; no half-state
4. **Elder-tier soft confirmation (v1.0.3 patch — clarifies gating per Sally's UX Spec inconsistency #4):** if the customer's UI is currently in elder tier — triggered by EITHER (a) a Decision Circle persona of `mummyJi` / `papaJi` / `dadi` / `chachaJi`, OR (b) the universal accessibility large-text toggle from P2.8 — the commit button shows a soft confirmation dialog: `क्या आप पक्की तरह से ऑर्डर पुष्टि करना चाहती हैं?` ("Are you sure you want to confirm the order?"). This is a UX safety net for elder users and applies regardless of which mechanism activated the elder tier. The dialog has two buttons: `हाँ, पक्का करें` ("Yes, confirm") and `थोड़ा रुकिए` ("Wait a moment"). The "wait" option keeps the Project in `committed` state but does not trigger the OTP flow yet.
5. `otpAtCommitEnabled` is flipped to `false` mid-session: the next commit attempt skips OTP

**Dependencies:** I6.2, I6.7, C3.1, C3.2

---

### **C3.5** — UPI payment intent flow 🦴

*As Sunita-ji's son, I want to pay via PhonePe / GPay / Paytm with one tap, so that the money reaches Sunil-bhaiya in 5 seconds with no commission.*

| Field | Value |
|---|---|
| Auth tier | `phoneVerified` (after C3.4 commit) |
| Adapter | None (UPI deep links are URL schemes) |
| Feature flag | None |
| Firestore reads | 1 (load Shop's UPI VPA) |
| Cross-tenant test | Y |
| Refs | Brief §3 UPI-first, SAD §10 cost forecast, locked PQ3 |

**Acceptance criteria:**
1. After commit (C3.4), the payment screen shows three primary CTAs in vertical order:
   - **Big primary button:** `UPI से दीजिए` ("Pay via UPI") — full width, branded with UPI logo + PhonePe/GPay/Paytm icons
   - **Smaller secondary text link:** `और तरीके` ("Other ways") → expands to show COD, Bank Transfer, Udhaar Khaata options
2. Tapping the UPI button constructs a UPI deep link of the form `upi://pay?pa={shop.upiVpa}&pn={shop.brandName}&am={totalAmount}&tn=Order%20{projectId}&cu=INR`
3. The deep link opens the user's preferred UPI app (system handles app selection)
4. After payment completion, the UPI app returns the user to Yugma Dukaan via the return URL with the transaction status
5. On success, the Project state transitions to `paid` via a Firestore transaction; the payer's VPA is captured to `Customer.vpaFromUpi` for shopkeeper-side display
6. On failure or cancellation, the customer is shown a friendly retry screen with "try another way" options
7. The `totalAmount` is in rupees (not paise — UPI deep links use rupees)
8. **Triple Zero UPI invariant (v1.0.5 patch per SAD v1.0.4 §5 Project schema + finding F3).** The `am=` parameter in the UPI deep link MUST equal `totalAmount` EXACTLY — no service fee, no convenience charge, no rounding, no platform margin interposed. The `pa=` parameter MUST equal `shop.upiVpa` directly (the shopkeeper's VPA), never a Yugma-Labs-owned intermediate account. Unit test: parse the generated UPI URI and assert (a) `am=` integer equals `project.totalAmount`, (b) `pa=` equals `shop.upiVpa`, (c) no other numeric `fee` / `charge` / `mdr` parameter exists in the URI. The same `amountReceivedByShop == totalAmount` invariant from C3.4 is re-verified at the transition `committed → paid`: the Firestore transaction that writes `state: "paid"` MUST also assert `amountReceivedByShop == totalAmount` and fail the transition if violated. Cross-tenant integrity test covers the invariant post-transition.

**Edge cases:**
1. No UPI app installed on the device: deep link fails silently; show "UPI ऐप नहीं मिला — कोई और तरीका चुनिए" ("No UPI app found — choose another method")
2. Payment partially successful (rare): manual reconciliation by shopkeeper via ops app
3. Customer cancels mid-flow: Project stays `committed`, payment screen reappears
4. Shopkeeper VPA is invalid: ops app should warn during onboarding; UPI deep link returns error
5. Shop has no `upiVpa` configured: payment screen hides UPI option; falls through to COD/Bank/Udhaar

**Dependencies:** C3.4

---

### **C3.6** — COD workflow (Cash on Delivery)

*As Geeta-ji (Persona C, the Replacement Buyer), I want to pay cash when the almirah arrives, so that I see what I'm paying for first.*

| Field | Value |
|---|---|
| Auth tier | `phoneVerified` |
| Adapter | None |
| Feature flag | None |
| Firestore reads | 0 (write only) |
| Cross-tenant test | Y |
| Refs | Brief §3 COD as alternative, Brief §5 Persona C |

**Acceptance criteria:**
1. From the payment screen (C3.5 expanded "other ways"), a "COD" option labeled `डिलीवरी पर नकद` ("Cash on delivery")
2. Selecting COD: shows a confirmation dialog with the total amount and a note "Sunil-bhaiya will collect this when he delivers"
3. On confirmation: Project state transitions to `delivering` (skipping `paid` state) with a `paymentMethod: "cod"` field
4. FCM push to shopkeeper: `नया COD ऑर्डर — Sunita-ji से ₹22,000` ("New COD order — from Sunita-ji for ₹22,000")
5. Shopkeeper marks the order as `paid` after collecting cash via the ops app (S4.10 or similar)

**Edge cases:**
1. Customer changes mind after selecting COD: can reset to draft via "go back" until shopkeeper acknowledges
2. Shopkeeper accepts COD but customer doesn't pay on delivery: separate dispute resolution flow (manual, no v1 automation)
3. Multi-installment COD: not supported; that's the udhaar khaata flow

**Dependencies:** C3.4

---

### **C3.7** — Bank transfer instructions

*As Amit-ji (Persona B, the New Homeowner), I want to pay via direct bank transfer if my UPI limit is exhausted, so that I have a fallback.*

| Field | Value |
|---|---|
| Auth tier | `phoneVerified` |
| Adapter | None |
| Feature flag | None |
| Firestore reads | 0 |
| Cross-tenant test | Y |
| Refs | Brief §3 bank transfer as alternative |

**Acceptance criteria:**
1. From the "other ways" expansion, a "Bank Transfer" option labeled `बैंक से सीधे भेजिए` ("Send directly from bank")
2. Selecting it shows the shop's bank details: account number, IFSC, account holder name, branch — plus the shop's UPI VPA as a secondary option for the bank's UPI feature
3. A "Mark as paid" button lets the customer self-report the transfer, which transitions Project state to `awaiting_verification`
4. The shopkeeper sees an alert in the ops app: `Sunita-ji ने bank transfer के बारे में बताया है — बैंक चेक कीजिए` ("Sunita-ji says she paid by bank — check the account")
5. Shopkeeper manually verifies by checking their bank app, then transitions Project state to `paid`

**Edge cases:**
1. Customer marks paid but didn't actually transfer: shopkeeper flags as fraud, blocks customer
2. Bank details copy-paste: long-press to copy each field individually
3. Shop has no bank details configured: option is hidden

**Dependencies:** C3.4

---

### **C3.8** — Digital udhaar khaata setup (shopkeeper-initiated only)

*As Sunil-bhaiya, I want to extend partial-payment udhaar to a customer I trust (Sunita-ji's family), so that she can take the almirah home today and pay the rest in 3 monthly installments — without interest, without paperwork.*

| Field | Value |
|---|---|
| Auth tier | `googleOperator` (initiation), `phoneVerified` (customer accepts) |
| Adapter | None |
| Feature flag | None |
| Firestore reads | 1 (load Project) |
| Cross-tenant test | Y (critical: forbidden vocabulary check) |
| Refs | Brief §3 udhaar khaata, ADR-010, R10 |

**Acceptance criteria:**
1. Udhaar khaata is **shopkeeper-initiated only** (per ADR-010 and PRD standing rule #8)
2. From a committed Project in the ops app, the shopkeeper taps `उधार खाता शुरू करें` ("Start udhaar khaata")
3. A dialog asks: "How much will the customer pay today?" and "How much will be the running balance?"
4. The shopkeeper enters the values and confirms
5. A new UdhaarLedger document is created at `shops/sunil-trading-company/udhaar_ledger/{ledgerId}` with `recordedAmount`, `runningBalance`, `partialPaymentReferences: []`, `acknowledgedAt: null` (pending customer ack)
6. The Project's `udhaarLedgerId` field is set
7. The customer sees a notification: `सुनील भैया ने उधार खाता प्रस्तावित किया है` ("Sunil-bhaiya has proposed an udhaar khaata")
8. The customer reviews the terms (recorded amount, today's payment, balance) and taps "Accept" → `acknowledgedAt: serverTimestamp()`
9. **Forbidden field check at security rule layer:** the create operation rejects any document with `interest`, `interestRate`, `overdueFee`, `dueDate`, `lendingTerms`, `borrowerObligation`, `defaultStatus`, or `collectionAttempt` fields (per ADR-010)
10. Cross-tenant test: ledger creation under wrong shopId fails; forbidden field test asserts rejection

**Edge cases:**
1. Customer declines: udhaar ledger is deleted; Project returns to normal payment flow
2. Customer accepts but later disputes: the ledger is preserved as evidence; shopkeeper handles via existing relationship channels
3. Shopkeeper accidentally enters wrong amount: edit-before-acknowledgment is allowed; after acknowledgment is locked
4. Attempt to add `interest: 100` to the document via the SDK → security rule rejects → Crashlytics logs the attempt → engineer is alerted

**Dependencies:** C3.4, S4.12

---

### **C3.9** — Record udhaar partial payment (shopkeeper-side)

*As Sunil-bhaiya, I want to record each installment Sunita-ji's family pays, so that the running balance updates and she sees how much is left.*

| Field | Value |
|---|---|
| Auth tier | `googleOperator` |
| Adapter | None |
| Feature flag | None |
| Firestore reads | 1 (load UdhaarLedger) |
| Cross-tenant test | Y |
| Refs | SAD §5 UdhaarLedger.partialPaymentReferences, ADR-010 |

**Acceptance criteria:**
1. From the ops app's UdhaarLedger view, a "Record payment" button
2. Dialog asks: amount paid, payment method (cash / UPI / bank), notes (free text)
3. On submit: a new entry is appended to `partialPaymentReferences[]` with `paymentId`, `amount`, `recordedAt`, `method`
4. The `runningBalance` is decremented atomically via a Firestore transaction
5. If `runningBalance` reaches 0, `closedAt: serverTimestamp()` is set
6. The customer sees the updated balance on next app open (or via push if `runningBalance` reaches 0)
7. No "interest" field, no "fee" field, no "default" field — only `notes` for the shopkeeper's free-text observation

**Edge cases:**
1. Overpayment (balance would go negative): rejected; warn the shopkeeper
2. Multiple operators record the same payment: race condition handled by Firestore transaction
3. Customer pays in cash but shopkeeper forgets to record: a v1.5 reminder feature can nudge

**Dependencies:** C3.8

---

### **C3.10** — Order tracking screen (state transitions visible to customer)

*As Sunita-ji's son, I want to see exactly where my order is in the process — committed, polish in progress, dispatched, delivered — without calling Sunil-bhaiya to check.*

| Field | Value |
|---|---|
| Auth tier | `phoneVerified` (or `eitherCustomer`) |
| Adapter | None |
| Feature flag | None |
| Firestore reads | 1 (Project doc) |
| Cross-tenant test | Y |
| Refs | SAD §5 Project.state |

**Acceptance criteria:**
1. From `मेरे ऑर्डर` ("My orders") tab, a list of all this customer's Projects (filtered by `customerUid == currentUid`)
2. Each Project card shows: state badge in Devanagari, total amount, last updated time, line items count, last message preview
3. Tapping opens a detail view with a vertical state timeline:
   - `पुष्टि की गयी` (committed)
   - `भुगतान हुआ` (paid) OR `उधार खाता शुरू` (udhaar started)
   - `तैयार हो रहा है` (being prepared)
   - `पॉलिश में है` (in polish)
   - `रवाना हुआ` (dispatched)
   - `डिलीवर हुआ` (delivered)
   - `बंद हुआ` (closed)
4. Each state transition shows the timestamp and any associated note
5. Customer can tap any past state to see a chat-thread snippet from that time

**Edge cases:**
1. State skips (e.g., committed → paid → dispatched without polish): only the visited states show
2. Project is cancelled mid-flow: state shows `रद्द` ("cancelled") with the cancellation reason
3. Customer has 50+ Projects: paginated list, sorted by `updatedAt` desc

**Dependencies:** C3.4

---

### **C3.11** — Delivery confirmation by shopkeeper

*As Sunil-bhaiya, I want to mark an order as delivered with a one-tap action and (optionally) attach a delivery photo, so that the customer's app updates and the trust loop closes.*

| Field | Value |
|---|---|
| Auth tier | `googleOperator` |
| Adapter | MediaStore (for delivery photo) |
| Feature flag | None |
| Firestore reads | 1 (load Project) |
| Cross-tenant test | Y |
| Refs | SAD §5 Project.deliveredAt |

**Acceptance criteria:**
1. From an in-progress Project in the ops app, a `डिलीवर हो गया` ("Delivered") button
2. Tapping it: optional photo capture (if the shopkeeper wants), then state transition to `closed` (or `delivered` if there's a separate close step)
3. Project document updates: `deliveredAt: serverTimestamp()`, optional `deliveryPhotoUrl`, transition to next state
4. Customer sees the update via Firestore listener; FCM push: `सुनील भैया ने ऑर्डर डिलीवर कर दिया` ("Sunil-bhaiya has delivered the order")
5. If udhaar khaata is open, the customer sees a reminder of their running balance
6. Customer can leave a 1-tap satisfaction reaction (👍 / 👎) inline on the chat thread, no review form

**Edge cases:**
1. Delivery photo upload fails: state still transitions; photo retries in background
2. Customer disputes delivery: opens chat with a `कुछ गलत है?` ("something wrong?") quick-message
3. Re-delivery (return + redeliver): not supported in v1; manual workaround

**Dependencies:** I6.6, S4.8

---

### **C3.12** — Shop deactivation customer notification + lifecycle workflow *(v1.0.5 add per Winston's SAD v1.0.4 handoff, Brief §9 R16, DPDP Act 2023, audit gap #2)*

*As Sunita-ji (a customer of Sunil Trading Company), I want to be honestly and clearly notified in Devanagari when Sunil-bhaiya's shop is closing — with my active orders paused, my udhaar ledger frozen, my data retained per DPDP Act rules — so that I am never left wondering what happened to my pending order or my running balance.*

| Field | Value |
|---|---|
| Auth tier | `phoneVerified` |
| Adapter | None |
| Feature flag | None |
| Firestore reads | 2 (Shop document for lifecycle state + current customer's Project list) |
| Cross-tenant test | Y |
| Refs | Brief §9 R16 DPDP exposure, Brief §7 v1.5 scope (pulled to v1), SAD v1.0.4 ADR-013 shop lifecycle state machine, SAD v1.0.4 §5 Shop lifecycle fields, SAD v1.0.4 §7 Function 8 `shopDeactivationSweep`, SAD §6 `shopIsWritable` helper |

**Acceptance criteria:**
1. The customer app subscribes to the `Shop` document in real time (already done for branding hot-reload). When `shopLifecycle` transitions from `"active"` to `"deactivating"` or `"deactivated"`, the next screen refresh renders a persistent **top banner in Devanagari** above all other content: `सुनील भैया की दुकान बंद हो रही है — आपका पैसा वापस आ जाएगा, आपका डेटा {N} दिन तक सुरक्षित है` ("Sunil-bhaiya's shop is closing — your money will come back, your data is safe for {N} days") where `{N}` is `(dpdpRetentionUntil - now)` in days.
2. When `shopLifecycle == "deactivating"`, ALL the current customer's `Project` documents with `state in ['draft', 'negotiating', 'committed']` automatically transition to `state: "paused"` via a Cloud-Function-written `ProjectSystemPatch` (owned by `shopDeactivationSweep`). The customer cannot commit new orders; existing committed orders either complete (if shopkeeper ships before purge window) or refund via offline channels.
3. Any open `UdhaarLedger` documents for this customer freeze — `sendUdhaarReminder` skips any ledger where the parent shop's `shopLifecycle != "active"` (cross-reference with §7 Function 3 guardrails). Running balance is preserved for audit. The customer's view of the ledger shows `रुका हुआ` ("paused") instead of the remind toggle.
4. An in-app push notification (FCM) is fired once per customer on the `active → deactivating` transition: title `महत्वपूर्ण सूचना`, body equal to the banner text in AC #1. Per DPDP Act 2023, the notification must land within 7 days — `shopDeactivationSweep` runs daily so this is automatically met.
5. In-app Devanagari FAQ screen accessible from the banner: `क्या हो रहा है?` ("What's happening?") with bullets covering: why the shop is closing, what happens to money/orders/udhaar, how long data is retained, how to export their own data. No legal jargon; plain Awadhi-inflected Hindi.
6. The banner, the paused-project-state, and the frozen-udhaar rendering are visible to the customer for the full DPDP retention window. When `shopDeactivationSweep` transitions the shop to `purge_scheduled`, the banner text updates: `डेटा {30 - days_elapsed} दिन में हटा दिया जाएगा — export कीजिए`.
7. A `डेटा export कीजिए` ("export your data") button on the FAQ screen triggers B1.13 receipt generation for every past Project the customer has with this shop, bundled into a single share-sheet invocation (so the customer gets all receipts at once).
8. Audit trail: every banner impression logs a `dpdp_notification_seen` analytics event tagged `{shopId, customerUid, lifecycleState, daysRemaining}` for Yugma Labs' legal-posture telemetry.
9. Cross-tenant integrity test: the customer cannot read Shop lifecycle fields from `shop_0` while authenticated against `shop_1`; the banner logic is scoped only to the current shopId context.

**Edge cases:**
1. Customer is offline when `shopDeactivationSweep` runs: the banner appears on next connectivity (Firestore real-time listener catches up). The 7-day DPDP notification window absorbs up to 7 days of customer offline time; anything beyond that is a bad-faith-but-unavoidable edge case.
2. Customer has an active Project mid-payment at the `active → deactivating` moment: the UPI deep link still works (the client already has the intent URL). If the UPI transaction completes, `shopDeactivationSweep` on its next run detects the new payment and pauses the Project AFTER the payment, with the payment preserved. The customer is notified via the banner that their order is paused pending shopkeeper action.
3. Shop re-activates (lifecycle reverts `deactivating → active`, e.g., shopkeeper changes mind): the banner disappears on next Firestore listener fire; paused Projects transition back to their prior state via an audit-logged `ProjectSystemPatch`. This path is rare and ops-triggered only.
4. Customer uninstalls during the retention window: retention timer on the server side continues regardless. When the 180-day window expires, purge executes. No change to customer behavior.
5. DPDP retention window changes mid-lifecycle (Yugma Labs legal tightens from 180 to 90 days): `dpdpRetentionUntil` is editable per shop and the banner text auto-updates on next real-time listener fire.

**Dependencies:** I6.4, I6.7 (feature flags), B1.13 (receipt export reuse), paired with **S4.19** (ops side).

**Walking Skeleton?** No — v1 mandatory but not Sprint-1-critical. Ships in Sprint 5 or 6. Would land earlier only if an actual shop deactivation event during the flagship pilot forces it, which is extremely unlikely.

---

## Epic E4 — Shopkeeper Operations

*The ops app — Sunil-bhaiya's command center. Multi-operator from day one. Inventory, orders, chat reply, curation, customer memory, udhaar, settings.*

### **S4.1** — Shopkeeper sign-in via Google 🦴

*As Sunil-bhaiya, I want to sign into the ops app with my Gmail account (which I already have for Play Store), so that I don't have to remember a new password.*

| Field | Value |
|---|---|
| Auth tier | `googleOperator` |
| Adapter | AuthProvider |
| Feature flag | None |
| Firestore reads | 1 (load Operator doc) |
| Cross-tenant test | Y |
| Refs | SAD §4 Flow 3, ADR-002 |

**Acceptance criteria:**
1. First launch of ops app: full-screen sign-in with Google button
2. After successful sign-in: load `shops/sunil-trading-company/operators/{googleUid}` document
3. If operator document exists with valid role: grant scoped access; load home dashboard
4. If operator document does not exist: show "आप अभी authorized नहीं हैं — Yugma Labs से संपर्क कीजिए" ("You are not yet authorized — contact Yugma Labs")
5. Session persists indefinitely via refresh token (silent sign-in on next launch)
6. Sign-out option available in settings; clears local storage

**Edge cases:**
1. Network unavailable on sign-in: cached operator doc allows offline access to read-only ops; writes queue
2. Operator doc deleted while user is signed in: next Firestore read fails with `permission-denied`; app shows "अब आप authorized नहीं हैं" message
3. Multiple Google accounts on the device: standard Google account picker

**Dependencies:** I6.1

---

### **S4.2** — Multi-operator concurrent access with role-based permissions

*As Aditya (Sunil-bhaiya's nephew, the digital operator), I want my own ops app login that respects my role (`beta`), so that I can update inventory and reply to chats but can't accidentally delete an operator account.*

| Field | Value |
|---|---|
| Auth tier | `googleOperator` |
| Adapter | None |
| Feature flag | None |
| Firestore reads | 1 (operator doc on every screen mount) |
| Cross-tenant test | Y |
| Refs | SAD §5 Operator, SAD §6 security rules, Brief §5 multi-operator persona |

**Acceptance criteria:**
1. Operator document at `shops/sunil-trading-company/operators/{googleUid}` carries `role: "bhaiya" | "beta" | "munshi"` and a `permissions` map
2. UI is rendered conditionally based on the role:
   - **bhaiya**: full access including operator management, theme tokens, feature flags
   - **beta**: inventory CRUD, orders, chat, voice notes, curation; cannot delete operators or change theme
   - **munshi**: orders read-only, udhaar ledger CRUD, payment recording; cannot edit inventory or chat
3. Two operators can be signed in simultaneously on different devices; both see real-time updates
4. The bhaiya can add/remove operators from a settings screen (S4.14)
5. Cross-tenant test verifies an operator from another shop cannot access this shop's operators collection

**Edge cases:**
1. Bhaiya tries to delete himself: blocked with a clear error
2. Two operators edit the same SKU simultaneously: last write wins, both see the updated value via real-time listener
3. Operator role changes mid-session: app refreshes the permission map on next screen mount

**Dependencies:** S4.1

---

### **S4.3** — Inventory: create new SKU 🦴

*As Aditya, I want to add a new almirah to the catalog — name, price, dimensions, photo — in under 90 seconds, so that updating inventory doesn't feel like data entry.*

| Field | Value |
|---|---|
| Auth tier | `googleOperator` (bhaiya or beta) |
| Adapter | MediaStore |
| Feature flag | None |
| Firestore reads | 0 (write only) |
| Cross-tenant test | Y |
| Refs | SAD §5 InventorySku |

**Acceptance criteria:**
1. From inventory tab, a `+` button opens a streamlined creation form with these fields:
   - Name in Devanagari (required)
   - Name in English (optional)
   - Category (dropdown: steel almirah / wooden wardrobe / modular / dressing / side cabinet)
   - Material (dropdown)
   - Dimensions (3 number fields: H × W × D in cm)
   - Base price (₹)
   - Negotiable down to (₹) — internal floor, not customer-visible
   - In stock (toggle)
   - Stock count (optional)
   - Description in Devanagari (textarea)
2. A "Capture Golden Hour photo" button leads to S4.5
3. On save: SKU document created at `shops/sunil-trading-company/inventory/{skuId}` with all fields
4. Customer-facing screens see the new SKU on next refresh (via real-time listener)

**Edge cases:**
1. Devanagari input not configured on the device: prompt to enable Hindi keyboard
2. Photo capture fails: SKU is created with photo deferred; "add photo later" indicator
3. Duplicate SKU name: warning; allow duplicate (real shops have variations)

**Dependencies:** S4.1, S4.5

---

### **S4.4** — Inventory: edit existing SKU

*As Aditya, I want to update an SKU's price or stock count when reality changes, without re-entering everything else.*

| Field | Value |
|---|---|
| Auth tier | `googleOperator` (bhaiya or beta) |
| Adapter | None |
| Feature flag | None |
| Firestore reads | 1 (load SKU) |
| Cross-tenant test | Y |
| Refs | SAD §5 InventorySku |

**Acceptance criteria:**
1. From inventory tab, tapping a SKU opens its detail view with all fields editable
2. Changes are saved on a "Save" tap (or auto-save with explicit confirmation)
3. Edit history is NOT tracked in v1 (deferred)
4. Stock count can be quickly adjusted via +/− buttons without opening the full edit form

**Edge cases:**
1. SKU is in an active Project draft when edited: the draft's snapshot preserves the old price; the new price applies to future drafts
2. SKU is deleted while in drafts: drafts retain the snapshot; inventory list filters it out
3. Operator without bhaiya role tries to delete: blocked

**Dependencies:** S4.3

---

### **S4.5** — Golden Hour photo capture flow 🦴

*As Aditya, I want to photograph a new almirah during the shop's golden hour with a one-tap capture that auto-uploads to Cloudinary, so that the customer-facing catalog has the right image without me having to think about it.*

| Field | Value |
|---|---|
| Auth tier | `googleOperator` |
| Adapter | MediaStore (Cloudinary) |
| Feature flag | None |
| Firestore reads | 0 (write only) |
| Cross-tenant test | Y |
| Refs | Brief §3 Golden Hour Mode, SAD §5 GoldenHourPhoto, ADR-006 |

**Acceptance criteria:**
1. From a SKU detail view, a `📸 Golden Hour फोटो` button opens the device camera
2. Camera UI overlays a faint "raking light" guide showing the optimal sun angle for the current shop's golden hour
3. After capture: a preview screen with "Save as hero" / "Save as working" tabs (per ADR-006 two-tier photo system)
4. On save: photo uploaded to Cloudinary with metadata `{shopId, skuId, tier, capturedAt, lightCondition}`
5. GoldenHourPhoto Firestore document created with the Cloudinary URLs
6. The SKU's `goldenHourPhotoIds` array is appended
7. Customer-facing SKU detail screens (B1.5) load the new photo on next view

**Edge cases:**
1. Photo too dark / too bright: no automated quality check in v1, but a future v1.5 check could warn
2. Multiple photos captured for the same SKU: all preserved; the most recent hero photo is the default in customer view
3. Photo upload fails: queued, retried; SKU shows an "अपलोड बाकी" badge until success

**Dependencies:** I6.6, S4.3

---

### **S4.6** — Order/Project list with state filter

*As Sunil-bhaiya, I want to see all my active Projects at a glance, filterable by state (committed / paid / delivering / closed), so that I know what to do today.*

| Field | Value |
|---|---|
| Auth tier | `googleOperator` |
| Adapter | None |
| Feature flag | None |
| Firestore reads | 5 (paginated list of 20 projects, denormalized fields means no extra reads per project) |
| Cross-tenant test | Y |
| Refs | SAD §5 Project, SAD §5 indexes |

**Acceptance criteria:**
1. Orders tab shows a vertical list of Projects, sorted by `updatedAt` desc, paginated by 20
2. Each card shows: customer display name (from customer_memory or VPA fragment), Devanagari state badge, total amount, line items count, last message preview, time since last update
3. Filter chips at top: `सब / पुष्टि की / भुगतान बाकी / डिलीवरी में / बंद` (All / Committed / Pending payment / Delivering / Closed)
4. Tapping a card opens the Project detail view (S4.7)
5. A search bar allows finding by customer phone, customer display name, or amount
6. Real-time updates via Firestore listener — new orders appear at the top instantly

**Edge cases:**
1. Pagination loads next 20 on scroll
2. Search is case-insensitive and ignores Devanagari diacritics
3. Empty list for a brand new shop: friendly "जल्द ही पहला ऑर्डर आएगा" ("first order coming soon") placeholder

**Dependencies:** S4.1

---

### **S4.7** — Open Project detail with chat thread access

*As Sunil-bhaiya, I want to see everything about a customer's order on one screen — line items, prices, customer memory, chat history, payment status — so that I never have to swipe between five screens.*

| Field | Value |
|---|---|
| Auth tier | `googleOperator` |
| Adapter | None |
| Feature flag | None |
| Firestore reads | 4 (Project + ChatThread metadata + last 10 messages + customer memory) |
| Cross-tenant test | Y |
| Refs | SAD §5 Project + ChatThread + CustomerMemory |

**Acceptance criteria:**
1. Project detail screen shows in a single scroll:
   - Project state badge + total amount + payment status
   - Line items list with prices
   - Customer info card (display name, phone, VPA, customer memory snippet)
   - Chat thread preview (last 10 messages, expandable to full thread)
   - Action buttons: `संदेश भेजिए` (send message), `आवाज़ नोट` (voice note), `डिलीवर` (mark delivered), `उधार खाता` (start udhaar), `रद्द करें` (cancel)
2. Customer memory section is editable inline
3. Quick state transition buttons appear contextually based on current state
4. The chat thread expand-to-full opens P2.4 from the shopkeeper side

**Edge cases:**
1. Customer has no memory yet: show "नया ग्राहक" ("new customer") placeholder
2. Project has 50+ chat messages: pagination on expand
3. Operator without permission tries an action: button is disabled with tooltip explanation

**Dependencies:** S4.6, B1.11

---

### **S4.8** — Reply to customer chat from ops app

*As Sunil-bhaiya, I want to reply to Sunita-ji's question about polish (text or voice note), so that she gets an answer in 5 minutes.*

| Field | Value |
|---|---|
| Auth tier | `googleOperator` |
| Adapter | CommsChannel + MediaStore |
| Feature flag | `commsChannelStrategy` |
| Firestore reads | 0 (write only) |
| Cross-tenant test | Y |
| Refs | P2.4, P2.5, B1.7 |

**Acceptance criteria:**
1. From a Project detail (S4.7) or the chats tab, the chat thread screen has a text input + voice note button
2. Sending a text message: same flow as P2.5 but `authorRole: "bhaiya"` (or beta/munshi)
3. Sending a voice note: same flow as B1.7
4. Sending a price proposal (special message type): a separate UI flow lets the shopkeeper propose a discounted price for a specific line item; appears in customer's chat as an interactive accept/reject card
5. The operator's name (per Operator doc displayName) appears next to each message they send

**Edge cases:**
1. Customer is offline: messages queue locally + on the customer's device when they reconnect
2. Multiple operators reply simultaneously: both messages appear; chat is collaborative
3. Long voice notes: capped at 60 seconds

**Dependencies:** I6.5, P2.4, S4.7

---

### **S4.9** — Customer memory editing inline

*As Sunil-bhaiya, I want to quickly add a note about Sunita-ji's family ("Sunita ki bahen Geeta bhi hamari customer hai") while I'm chatting with her, so that the relationship context is captured before I forget.*

| Field | Value |
|---|---|
| Auth tier | `googleOperator` |
| Adapter | None |
| Feature flag | None |
| Firestore reads | 0 (write only, on existing memory doc) |
| Cross-tenant test | **Y — customer must NEVER read this** |
| Refs | B1.11 |

**Acceptance criteria:**
1. From the Project detail (S4.7) customer info card, a "Edit memory" button opens a quick edit sheet
2. The sheet shows the existing memory notes, relationship notes, preferred occasions, preferred price range
3. Edits save immediately (auto-save)
4. Cross-tenant integrity test asserts the customer cannot read their own memory document

**Edge cases:**
1. Memory doc doesn't exist yet: created on first edit
2. Two operators edit simultaneously: last write wins (rare; typically one operator handles relationships)
3. Memory becomes stale: no automated cleanup; this is intentional (memory is a long-lived asset)

**Dependencies:** B1.11, S4.7

---

### **S4.10** — Udhaar ledger view + record payment

*As Sunil-bhaiya (or the munshi role), I want to see all open udhaar ledgers across customers and record incoming payments quickly, so that the running balances stay accurate.*

| Field | Value |
|---|---|
| Auth tier | `googleOperator` (bhaiya or munshi) |
| Adapter | None |
| Feature flag | None |
| Firestore reads | 5 (paginated list of 10 ledgers; denormalized customer name on each) |
| Cross-tenant test | Y |
| Refs | SAD §5 UdhaarLedger, ADR-010, C3.9 |

**Acceptance criteria:**
1. Udhaar tab in ops app shows a list of all open ledgers (where `closedAt == null` and `runningBalance > 0`)
2. Each card shows: customer display name, recorded amount, running balance, last payment date, days since opening
3. Tapping a card opens the ledger detail with the full payment history
4. From the detail, a `भुगतान दर्ज कीजिए` ("Record payment") button opens C3.9's flow
5. Closed ledgers (where `closedAt != null` OR `runningBalance == 0`) are filterable separately
6. NO field labeled "interest", "fee", "due date", "default", or any other lending vocabulary appears anywhere in the UI
7. **Reminder opt-in per ledger (v1.0.5 patch per SAD v1.0.4 §7 Function 3 RBI guardrail finding F11).** Each UdhaarLedger document carries a `reminderOptInByBhaiya: bool` field (default `false`). The `sendUdhaarReminder` Cloud Function SKIPS any ledger where this flag is `false` or missing. The ops app UI has an explicit toggle labeled `क्या मैं इस ग्राहक को याद दिलाऊँ?` ("Should I remind this customer?") on each open ledger card — the bhaiya must affirmatively tap it for that specific ledger. No blanket or shop-wide opt-in exists. Acceptance test: ledger with `reminderOptInByBhaiya: false` does NOT receive a reminder on any scheduled function run.
8. **Lifetime reminder cap (v1.0.5 patch).** Each UdhaarLedger carries a `reminderCountLifetime: int` (default 0), incremented atomically by `sendUdhaarReminder`. The function constant `REMINDER_MAX_LIFETIME = 3` hard-caps total reminders per ledger entry. After 3 reminders, any further reminders require offline shopkeeper action outside the app. The ops app UI shows a small badge `याद दिलाया गया: 2/3` ("reminded 2/3") on each ledger. Acceptance test: a ledger with `reminderCountLifetime: 3` never receives a 4th reminder even if `reminderOptInByBhaiya: true`.
9. **Shopkeeper-controlled cadence (v1.0.5 patch).** Each UdhaarLedger carries a `reminderCadenceDays: int` with default 14, minimum 7, maximum 30. The cadence is set by the shopkeeper from the ledger detail screen via a stepper UI. `sendUdhaarReminder` compares `lastReminderSentAt` against `now - reminderCadenceDays * 1 day` and skips if the cadence floor has not been reached. Acceptance test: ledger with `reminderCadenceDays: 30` receives a reminder at day 30, never at day 14, even if opt-in and cap allow it. These three fields together constitute the RBI-defensive runtime posture that complements the schema-level forbidden-vocabulary defense (ADR-010).

**Edge cases:**
1. 50+ open ledgers: paginated, sorted by `runningBalance` desc
2. Customer has multiple open ledgers: each shown separately (one per Project)
3. Operator without permission (e.g., beta role): tab is hidden

**Dependencies:** C3.9

---

### **S4.11** — Sales analytics dashboard

*As Sunil-bhaiya, I want a single screen that tells me how many orders I closed this month, how much revenue, and how many active customers — so that I can see if the app is helping me.*

| Field | Value |
|---|---|
| Auth tier | `googleOperator` |
| Adapter | None |
| Feature flag | None |
| Firestore reads | 6 (aggregations done client-side from cached project list) |
| Cross-tenant test | Y |
| Refs | Brief §6 success metrics, SAD §5 Project denormalized fields |

**Acceptance criteria:**
1. A "Dashboard" tab shows for the current month:
   - Total committed orders count
   - Total revenue (sum of `totalAmount` where `state in ['paid', 'closed']`)
   - Open orders awaiting action
   - Open udhaar balances total
   - New unique customers this month
2. Comparisons to previous month (delta arrows)
3. A simple bar chart of last 7 days' orders
4. Tapping any number drills down to the relevant filtered list

**Edge cases:**
1. New shop with no data: show friendly empty state
2. Aggregations are computed client-side from the Projects list pagination — does not require expensive Firestore queries
3. Stale data when offline: timestamp shows "अद्यतन: 2 ghante pehle" ("updated 2 hours ago")

**Dependencies:** S4.6

---

### **S4.12** — Settings: theme tokens, feature flags, premium toggles

*As Sunil-bhaiya (bhaiya role only), I want to update my shop's tagline, photo, primary color, and feature flag overrides from a single settings screen, so that I don't need to call Yugma Labs to make small changes.*

| Field | Value |
|---|---|
| Auth tier | `googleOperator` (bhaiya only) |
| Adapter | None |
| Feature flag | (this is the meta-feature-flag UI) |
| Firestore reads | 2 (ShopThemeTokens + FeatureFlags) |
| Cross-tenant test | Y |
| Refs | SAD §5 ShopThemeTokens + FeatureFlags, SAD §8 multi-tenant theming |

**Acceptance criteria:**
1. Settings tab (visible only to bhaiya role) with 4 sections:
   - **Shop profile**: name in Devanagari + English, tagline, GST number, established year, WhatsApp number, UPI VPA, geo location
   - **Branding**: face photo upload, logo upload, primary/secondary/accent/background/text colors (with color picker), greeting voice note (B1.8)
   - **Feature flags**: toggles for each flag from I6.7 with tooltips explaining what each does
   - **Operators**: list of current operators with role badges; add/remove buttons
2. Saving any change updates the relevant Firestore document and bumps its `version` field
3. Customer-facing app sees the changes via real-time listener (theme hot-reloads via P2.3-style ThemeData rebuild)
4. Bhaiya role check enforced at the security rule layer
5. A "Reset to default" button per section restores original values

**Edge cases:**
1. Color picker shows live preview of how the theme will look on a sample customer screen
2. Beta/munshi opens settings: tab is hidden entirely
3. Theme update fails Firestore write (security rule rejection): clear error message in Devanagari

**Dependencies:** S4.1, B1.8, I6.7

---

### **S4.13** — "Today's task" daily prompt screen *(v1.0.4 add per Shopkeeper Onboarding Playbook §11)*

*As Sunil-bhaiya, I want a single screen on the ops app home dashboard that tells me ONE specific thing to do today (add 5 more SKUs / record one voice note / review my शादी shortlist), so that I always know how to use the app without having to think about it or remember what comes next.*

| Field | Value |
|---|---|
| Auth tier | `googleOperator` |
| Adapter | None |
| Feature flag | None |
| Firestore reads | 1 (load today's task state document) |
| Cross-tenant test | Y |
| Refs | Shopkeeper Onboarding Playbook §5 + §11; Brief §9 R1 (burnout mitigation); pre-mortem failure mode #1 (shopkeeper never voluntarily records voice notes) |

**Acceptance criteria:**
1. The ops app home dashboard has a prominent card titled `आज का काम` ("Today's task") at the top of the screen, above the orders list and inventory tab
2. The card shows ONE task per day, drawn from a pre-populated 30-day ramp sequence:
   - Days 1–7: foundation tasks (add SKUs, record first voice notes, populate first shortlist)
   - Days 8–14: catalog build-out (add 8 SKUs/day with daily push, record more voice notes)
   - Days 15–21: depth tasks (add 8 SKUs/day, refine shortlists, capture more Golden Hour photos)
   - Days 22–28: polish (add 4 SKUs/day, Day-22 milestone celebration, customer memory entries)
   - Days 29–30: catalog completion + first real customer journey readiness check
3. Each task has: a Devanagari title, an English subtitle, an estimated time (e.g., "10 मिनट" / "20 मिनट"), and a "हो गया" ("done") button
4. Tapping "हो गया" marks the task complete in Firestore (`shops/{shopId}/operators/{operatorUid}/today_tasks/{date}.completedAt: serverTimestamp()`) and reveals tomorrow's task
5. Tasks are fetched from a static seed (shipped with the app) for Day 1–30, then transition to a "weekly habit" rotation after Day 30
6. The card is dismissible — long-press → "छुपा दीजिए" ("hide"). Hidden state persists per operator. Reappears if the operator hasn't opened the app for 7 consecutive days.
7. **No push notifications.** The card waits patiently. Sunil-bhaiya checks the app on his own rhythm.
8. The Day 30 task celebrates the catalog completion and unlocks a one-time "first real customer test" walkthrough
9. After Day 30, the card transitions to a weekly habit prompt rotation: "Record one voice note this week" / "Photograph any new arrivals during golden hour" / "Review your shortlists" — repeating monthly

**Edge cases:**
1. Operator skips a day: today's task carries forward; the day counter advances normally
2. Multiple operators (bhaiya + beta) each see independent task progress: tasks are per-operator, not per-shop
3. Operator dismisses the card permanently: stored as `dismissedAt` on the operator document; reappears after 7 days of inactivity as a re-engagement nudge
4. Day-30 milestone celebration coincides with a real customer order: prioritize the customer order, defer the celebration to Day 31

**Dependencies:** S4.1, S4.3 *(needs basic ops app + inventory creation working before "today's task: add 5 SKUs" is meaningful)*

**Sprint:** v1 Sprint 2 (small add, ~2 days for Amelia)

---

### **S4.16** — MediaStore adapter cost-monitoring contract + ops dashboard *(v1.0.5 add per Winston's SAD v1.0.4 handoff, Brief §6 Month 9 gate, Brief §9 R3, audit gap #3)*

*As Yugma Labs platform engineering, I want every successful MediaStore upload to increment a per-shop Firestore counter and the ops dashboard to visualize monthly burn against the Cloudinary 25-credit ceiling, so that the `mediaCostMonitor` Cloud Function has real data to make swap decisions on, and so that the shopkeeper (and Yugma ops) see the burn rate BEFORE it becomes a billing surprise.*

| Field | Value |
|---|---|
| Auth tier | `googleOperator` (bhaiya only for dashboard) |
| Adapter | **MediaStore** (this story extends the adapter contract) |
| Feature flag | **`cloudinary_uploads_blocked`** (SAD v1.0.4 §5 FeatureFlags; real-time kill-switch per I6.7 AC #7) |
| Firestore reads | 2 (current month counter + month-1 counter for comparison on dashboard load) |
| Cross-tenant test | Y |
| Refs | Brief §9 R3, SAD v1.0.4 ADR-014, SAD v1.0.4 §7 Function 7 `mediaCostMonitor`, Brief §6 Month 9 unit-economics gate |

**Acceptance criteria:**
1. **Adapter contract extension (v1.0.5 — extends ADR-006).** The `MediaStore` interface in `packages/lib_core/lib/src/adapters/media_store.dart` adds a mandatory post-upload side effect: on every successful `uploadCatalogImage` or `uploadVoiceNote` (or any future method), the adapter increments `/system/media_usage_counter/{shopId}.cloudinary_{YYYY-MM}` or `.storage_{YYYY-MM}` (respective to which backend was used) via `FieldValue.increment(1)` for Cloudinary credits or `FieldValue.increment(sizeBytes)` for Cloud Storage bytes. The increment is atomic, queued offline, and replays on reconnect.
2. **Contract enforcement.** A unit test in `packages/lib_core/test/adapters/media_store_counter_contract_test.dart` verifies that every implementation (`MediaStoreCloudinary`, `MediaStoreFirebase`, `MediaStoreR2` stub) emits the counter increment on every successful upload path. A new MediaStore implementation without the counter emission fails CI.
3. **Ops dashboard widget.** On the S4.11 sales analytics dashboard, add a new section `मीडिया खर्च` ("Media spend") showing: (a) current month Cloudinary credits used / 25, (b) current month Cloud Storage bytes used / 5 GB, (c) a horizontal progress bar colored green <50%, amber 50–80%, red >80%, (d) a month-over-month delta arrow, (e) a projected end-of-month credits figure extrapolated linearly from day-of-month.
4. **Warning threshold alert (v1.0.5, gates the Brief §6 Month 9 unit-economics milestone).** When current month Cloudinary credits ≥50%, the ops dashboard shows a yellow warning banner `मीडिया खर्च आधा से ज़्यादा — जल्द खत्म हो सकता है` ("Media spend over half — may run out soon"). When ≥80%, the banner goes red. When ≥100%, the `mediaCostMonitor` function has already flipped `mediaStoreStrategy: "r2"` real-time (per I6.7 AC #7) and a red banner reads `Cloudinary खत्म — R2 चालू` ("Cloudinary done — R2 active").
5. **Kill-switch real-time consumption (v1.0.5 AC tying to I6.7 AC #7).** The MediaStore adapter subscribes to `/shops/{shopId}/feature_flags/runtime.mediaStoreStrategy` via `onSnapshot`, not Remote Config. When the field flips, subsequent uploads route to the new backend within <5 seconds. Integration test: write `"r2"` to the flag doc, assert the next `uploadCatalogImage` call hits the R2 stub.
6. **Cross-tenant test.** The counter document path `/system/media_usage_counter/{shopId}` is in the top-level `system` namespace (accessible only via admin SDK for the Cloud Function), but writes from the client are constrained to the authenticated user's `shopId` via a security rule. Test asserts a `shop_1` client cannot increment `shop_0`'s counter.
7. **Telemetry event.** Every upload emits an Analytics event `media_upload_counted` with `{shopId, backend, sizeBytes, monthBucket}` so Yugma Labs can correlate the counter against the `multiTenantAuditJob` and `mediaCostMonitor` alerts.

**Edge cases:**
1. Upload succeeds but counter increment fails (e.g., security rule misconfiguration): the upload is NOT rolled back; Crashlytics logs the counter failure; the ops dashboard shows a `⚠️ गिनती अधूरी` ("count incomplete") asterisk. Self-healing: `multiTenantAuditJob` re-counts nightly by listing Cloudinary catalog images and recomputes the month bucket.
2. Retroactive counter rebuild: a `tools/rebuild_media_counter.ts` script recomputes the counter from Cloudinary's API at any time. Used once on v1.0.5 ship to seed the counter from whatever Cloudinary already has.
3. Multiple operators uploading simultaneously: `FieldValue.increment` is atomic at Firestore, no race condition.
4. Month rollover at midnight IST: the month bucket is derived client-side from `DateTime.now().toUtc()` with IST offset. Uploads exactly at midnight may land in either month; the `mediaCostMonitor` function tolerates a 1-credit drift.

**Dependencies:** I6.6 (MediaStore adapter scaffolding), I6.7 (feature flag real-time consumption), S4.11 (analytics dashboard widget host). This story is the *adapter contract* + *ops UI* — the `mediaCostMonitor` cron function itself was already added in SAD v1.0.4 §7 Function 7.

**Walking Skeleton?** No — observability depth on top of the scaffolded adapter. Ships in Sprint 4 or 5.

---

### **S4.17** — Shopkeeper NPS survey + burnout early warning *(v1.0.5 add per Winston's SAD v1.0.4 handoff, Brief §6 Month 6 success gate)*

*As Yugma Labs platform engineering, I want a bi-weekly in-app NPS prompt in Devanagari for Sunil-bhaiya (and his operators) that writes to the SAD §5 `feedback` sub-collection, and an automatic Crashlytics alert if two consecutive scores ≤6, so that the Brief §6 "NPS ≥ 8/10" success gate is measurable AND the Brief R1 shopkeeper-burnout kill-gate is detected before the bhaiya quietly abandons the product.*

| Field | Value |
|---|---|
| Auth tier | `googleOperator` |
| Adapter | None |
| Feature flag | None |
| Firestore reads | 1 (load most recent feedback doc to compute "time since last prompt") |
| Cross-tenant test | Y |
| Refs | Brief §6 Month 6 success gate "shopkeeper NPS ≥ 8/10", Brief §9 R1 burnout kill-gate, SAD v1.0.4 §5 `feedback` sub-collection, SAD v1.0.4 §6 feedback security rule |

**Acceptance criteria:**
1. Every 14 days of active operator use (measured as any ops-app write within the period), the ops app home dashboard shows a non-intrusive Devanagari card: `कितना उपयोगी लगा? 1–10` ("How useful was it? 1-10") with a 10-dot rating row and an optional textarea `कुछ कहना है?` ("anything to say?"). NOT a modal — a dismissible dashboard card that does not block work.
2. On submit, the app writes a new document to `shops/{shopId}/feedback/{feedbackId}` with `type: "shopkeeper_burnout_self_report"` (per SAD v1.0.4 §5 feedback type enum), `score: <1-10>`, `textBody: <optional>`, `authorUid: <operator-google-uid>`, `authorRole: "bhaiya"|"beta"|"munshi"`, `sampledAt: serverTimestamp()`. The `feedback` security rule (per SAD v1.0.4 §6 patch) allows operators to create their own `shopkeeper_*` documents; updates and deletes are forbidden.
3. The card is dismissible via `बाद में` ("later") — dismissal sets a 7-day snooze. After 7 days, it re-appears.
4. **Burnout early warning trigger (v1.0.5 — Brief R1 kill-gate telemetry).** A Cloud Function trigger on `feedback` document creates (or a scheduled nightly sweep, whichever is cheaper) evaluates the most recent TWO `shopkeeper_burnout_self_report` documents for a given `shopId + authorUid`. If BOTH have `score <= 6`, a Crashlytics custom key `burnout_warning_{shopId}_{operatorUid}` is set and a non-fatal `BurnoutWarningDetected` event is logged with payload `{shopId, operatorUid, lastTwoScores, trailingWindow}`. Yugma Labs ops sees this in the Crashlytics dashboard and can intervene per Brief R1 mitigation (shift ops app access to son/nephew, reduce workload to voice notes only).
5. **Passive usage-sample emission.** In addition to self-report, every operator session emits a `shopkeeper_usage_sample` feedback document on logout or 30-minute inactivity timeout, with `metadata: {sessionMinutes, chatMessagesAnswered, voiceNotesRecorded, projectsTouched}`. Used by Yugma ops to correlate self-reported NPS against actual usage — a shopkeeper who reports NPS 9 but whose sessionMinutes is dropping toward zero is the *real* burnout signal.
6. **Customer-side NPS** (companion, different type). A customer can ALSO submit a `customer_nps` feedback after a Project transitions to `closed` via a similar 1-tap rating card on the Project tracking screen (C3.10). Same `feedback` sub-collection, `authorRole: "customer"`, `relatedProjectId: <projectId>`. Security rule per SAD v1.0.4 §6 allows this.
7. **Month 6 success gate report.** An ops dashboard section aggregates `type: "shopkeeper_burnout_self_report"` over the trailing 60 days and displays the average score as "Shopkeeper NPS (trailing 60d): X/10". If X ≥ 8, the Brief §6 Month 6 gate is visibly met.
8. Cross-tenant integrity test: operator in `shop_1` cannot read `shop_0` feedback documents.

**Edge cases:**
1. First 14-day window has no data: card does not appear until the operator has actually been active for 14 days.
2. Operator uses multiple devices (phone + tablet): card appears on whichever device is used first in the new cycle; submission dismisses across all devices via Firestore real-time listener.
3. Operator gives 10 every time without reading: still valuable as a pulse check. If usage-sample metadata simultaneously shows declining session minutes, the correlation flags it as a false positive; Yugma ops investigates.
4. Burnout warning fires but the operator has no `fcmToken`: Crashlytics event still logs; ops runbook handles out-of-band contact.

**Dependencies:** S4.1 (ops auth), S4.6 (ops dashboard host), SAD v1.0.4 `feedback` sub-collection (already in schema).

**Walking Skeleton?** No. Ships in Sprint 5 or 6 as a success-gate telemetry story.

---

### **S4.18** — Repeat-customer event tracking + retention dashboard *(v1.0.5 add per Winston's SAD v1.0.4 handoff, Brief §6 Month 9 success gate, audit gap #7)*

*As Yugma Labs platform engineering, I want every new Project creation for a customer with `previousProjectIds.length ≥ 1` to fire a `customer_returned_for_repeat_purchase` analytics event, and a monthly-repeat-percentage dashboard tile to render on the ops analytics screen, so that the Brief §6 Month 9 "repeat customer rate observable" gate is met AND an automatic warning fires if monthly repeat rate drops below 5%.*

> **Scoping decision (v1.0.5 AE judgment call).** Winston's handoff notes that S4.18 is "MOSTLY analytics — verify whether it's a separate story or an AC on existing S4.11 (analytics dashboard)." **Decision: make it a separate story, not an AC addition on S4.11.** Rationale: (a) the `previousProjectIds` array mutation is a state-transition concern that lives in the Project-creation Cloud Function or repository method, NOT in the dashboard code; (b) the monthly repeat % aggregation has non-trivial query logic that warrants its own acceptance criteria; (c) the Crashlytics churn-warning trigger is a distinct observability concern from the S4.11 dashboard's sales aggregations; (d) keeping it separate lets Amelia size it independently for sprint planning. S4.11 receives only a small AC addition to host the repeat-rate tile on its existing dashboard layout — NOT the full analytics logic. Party-mode majority vote: ✅ (John, Winston, Sally), ⚠️ Mary would have preferred consolidation but bowed to the state-transition argument.

| Field | Value |
|---|---|
| Auth tier | `googleOperator` |
| Adapter | None |
| Feature flag | None |
| Firestore reads | 2 (previous customer document read + aggregation query for dashboard) |
| Cross-tenant test | Y |
| Refs | Brief §6 Month 9 "repeat customer rate observable", SAD v1.0.4 §5 Customer.previousProjectIds capped array, audit gap #7 |

**Acceptance criteria:**
1. **State-transition write (the foundational mechanism).** When a `Project` document is created with `state: "committed"` (C3.4) — NOT at draft creation — the `ProjectSystemPatch` path (Cloud-Function-owned, per Standing Rule 11) also updates the customer's document: `Customer.previousProjectIds = arrayUnion(<newProjectId>)` capped at the most recent 10 (older entries dropped). The `previousProjectIds` field is already in the SAD v1.0.4 §5 Customer schema as a capped last-10 array.
2. **Repeat event fires.** If `customer.previousProjectIds.length >= 1` at the moment a NEW Project is created (i.e., there was already at least one prior committed Project), an Analytics event `customer_returned_for_repeat_purchase` is fired with payload `{shopId, customerUid, previousProjectCount, newProjectId, daysSinceLastProject}`. The event fires exactly once per new Project; idempotent on retry.
3. **Repeat-rate aggregation.** The ops dashboard (S4.11) gains a new tile `दोबारा आने वाले ग्राहक` ("Repeat customers") showing: (a) current month repeat % = (unique customerUids with ≥1 repeat Project this month) / (unique customerUids with any Project this month), (b) month-over-month delta, (c) a small badge `X नए repeat` ("X new repeats") counting how many customers became repeat this month.
4. **Churn-warning threshold (v1.0.5 — Brief §6 Month 9 gate).** If the trailing 60-day repeat % drops below **5%**, a non-fatal Crashlytics custom event `churn_warning_{shopId}` is logged. Yugma Labs ops investigates per runbook (is the product adding value? is the shopkeeper disengaged? is there a competitor taking repeat business?). The 5% threshold is a working default; revisit after real data lands.
5. **Backfill on v1.0.5 ship.** A one-shot admin script `tools/backfill_previous_project_ids.ts` walks every shop's `projects` collection, groups by `customerUid`, and writes `previousProjectIds` on each Customer document in chronological order. This ensures the repeat-rate math is correct from day one, not only from the moment S4.18 ships.
6. **Cross-tenant integrity test.** (a) `previousProjectIds` for a `shop_0` customer can only be mutated by Cloud-Function code paths authenticated against `shop_0`; a `shop_1` client cannot touch it. (b) The Analytics event cannot be fired with a `shopId` the operator is not authorized for.
7. **Standing Rule 11 compliance.** The `previousProjectIds` update is exclusively a `ProjectSystemPatch` on the Project-side → customer-side mutation, written by a Cloud Function trigger on Project creation (NOT by the customer app or ops app directly). Rationale: keeps the field's integrity centralized, avoids race conditions on the capped-array eviction, and makes the repeat-event firing a single source of truth.

**Edge cases:**
1. Customer creates 11+ projects in total: `previousProjectIds` stays capped at 10 most recent; the 11th pushes the oldest out. The event still fires correctly because the length is always ≥1 after the first repeat.
2. Customer cancels a Project (draft → cancelled): no write to `previousProjectIds` (the append happens on commit, not creation).
3. Customer creates one project, deletes the app, reinstalls (new anonymous UID): treated as a NEW customer, not a repeat. This is acceptable — the v1.5 "customer memory reconciliation via phone number" flow (deferred) handles UID continuity.
4. Shopkeeper creates a test Project on their own customerUid: would inflate the metric. Test-tenant `shop_0` customer IDs are excluded from the aggregation.
5. Churn warning fires but then next day a big repeat purchase tips the metric back above 5%: Crashlytics event does not auto-clear; ops investigates regardless (transient signals are still signals worth seeing).

**Dependencies:** C3.4 (commit Project, where the arrayUnion write happens), S4.11 (analytics dashboard — receives the new tile as a small AC addition), I6.10 (Analytics SDK).

**Walking Skeleton?** No. Ships in Sprint 5 or 6 with S4.17.

---

### **S4.19** — Shopkeeper-triggered shop deactivation flow (ops side of C3.12) *(v1.0.5 add per Winston's SAD v1.0.4 handoff, SAD ADR-013)*

*As Sunil-bhaiya (bhaiya role only, nobody else), I want a dignified 3-tap confirmation flow in the ops app Settings to initiate shop deactivation — with a reason, a retention date, and a clear explanation of what will happen to my customers — so that if I ever retire, close the shop, or want to offboard from Yugma, the process is explicit, auditable, and DPDP-compliant.*

| Field | Value |
|---|---|
| Auth tier | `googleOperator` (**bhaiya role only** — not beta, not munshi) |
| Adapter | None |
| Feature flag | None |
| Firestore reads | 1 (load current Shop document lifecycle state) |
| Cross-tenant test | Y |
| Refs | SAD v1.0.4 ADR-013 shop lifecycle state machine, SAD v1.0.4 §5 Shop lifecycle fields, SAD v1.0.4 §7 Function 8 `shopDeactivationSweep`, paired with C3.12 (customer side), Brief §9 R16 |

**Acceptance criteria:**
1. In the ops app Settings screen (S4.12), a new section `दुकान बंद करना` ("Shop deactivation") is visible ONLY to operators whose `role == "bhaiya"`. Beta and munshi operators cannot see this section at all — not even disabled. Security rule enforces this server-side regardless of UI.
2. The section shows a single button `दुकान बंद करने का विकल्प` ("Shop closure option"). Tap 1 of 3 opens a full-screen informational page in Devanagari explaining: what will happen to customers, what will happen to orders, what will happen to udhaar, retention period (default 180 days), purge period (30 days after retention), how the DPDP Act 2023 protects customer data, how to change mind.
3. Tap 2 of 3 requires selecting a reason from a dropdown: `दुकानदार रिटायर हो रहे हैं` ("shopkeeper retiring") | `व्यवसाय बंद हो रहा है` ("business closing") | `अनुबंध समाप्त` ("contract terminated") | `डेटा हटाने का अनुरोध` ("data deletion request"). This maps to the SAD v1.0.4 §5 `Shop.shopLifecycleReason` enum.
4. Tap 3 of 3 is a final confirmation dialog `क्या आप पक्का हैं? यह तुरंत शुरू हो जाएगा।` ("Are you sure? This will start immediately") with buttons `हाँ, पक्का बंद कीजिए` ("Yes, close for sure") and `रुकिए, मुझे सोचना है` ("Wait, let me think").
5. On final confirmation, the ops app writes to the `Shop` document via a `ShopLifecyclePatch` (bhaiya-only security rule guards this):
   ```
   shopLifecycle: "deactivating"
   shopLifecycleChangedAt: serverTimestamp()
   shopLifecycleReason: <selected reason>
   dpdpRetentionUntil: <now + 180 days ISO timestamp>
   ```
6. Writing these fields triggers the next overnight run of `shopDeactivationSweep` (SAD v1.0.4 §7 Function 8), which then owns ALL subsequent state transitions and customer notifications (C3.12 customer side). The ops app does NOT directly notify customers — the Cloud Function does it, so the notification cadence is server-controlled and DPDP-compliant.
7. **Audit trail (v1.0.5).** A write to `shops/{shopId}/audit/{eventId}` records `{event: "shop_deactivation_triggered", triggeredByUid, triggeredAt, reason, dpdpRetentionUntil}`. The audit log is retained beyond the shop's lifecycle per SAD v1.0.4 §7 Function 8 design.
8. **Reversibility during the deactivating window.** Between `active → deactivating` and `deactivating → deactivated` (next overnight sweep), the bhaiya can UNDO via the same Settings screen. The flow re-shows the same 3-tap confirmation with inverted language (`दुकान फिर से चालू कीजिए` "Reopen shop") and writes `shopLifecycle: "active"`. Outside this window (once sweep has transitioned to `deactivated`), reversal requires Yugma Labs ops intervention (a manual admin-SDK write with legal review — not an in-app flow).
9. **Security rule enforcement (v1.0.5 AC).** Firestore security rule for `/shops/{shopId}` requires `isBhaiyaOf(shopId)` for any write that touches `shopLifecycle` or related fields. The rule also guards: once `shopLifecycle != "active"`, the only client-side write allowed on these fields is the `deactivating → active` reversal within the first 24 hours. All other lifecycle transitions are Cloud-Function-owned (admin SDK bypasses security rules).
10. Cross-tenant integrity test: a bhaiya of `shop_1` cannot write `shopLifecycle` on `shop_0`; a beta of `shop_1` cannot write it on `shop_1`.

**Edge cases:**
1. Bhaiya accidentally taps through: the 3-tap flow + large text + the reversibility window (until next sweep) is the mitigation. Additionally, the confirmation dialog text explicitly says `यह तुरंत शुरू हो जाएगा` to reduce false triggers.
2. Multiple bhaiyas exist (rare, but the schema supports it): whichever bhaiya triggers first wins; the audit log captures the triggering UID. A second bhaiya seeing the deactivating state gets the reversal flow instead of the original flow.
3. Shop has active orders when deactivation triggers: the overnight sweep handles those per C3.12 AC #2 — they transition to `paused`. Customers are notified per DPDP within 7 days. The ops flow does NOT block on open orders; that's intentional — the shopkeeper's choice to close is not gated on order status.
4. Shop has open udhaar ledgers: same — sweeps freeze them. The bhaiya still has up to 180 days (retention window) to settle them offline; the data is preserved for the full retention window.
5. DPDP lawyer later demands a shorter retention window for a specific shop: Yugma ops manually tightens `dpdpRetentionUntil` via admin SDK; the banner on customer side (C3.12) auto-updates.

**Dependencies:** S4.12 (Settings screen host), SAD v1.0.4 §5 Shop lifecycle fields (already in schema), SAD v1.0.4 §7 Function 8 (already implemented). Paired with C3.12 (customer side).

**Walking Skeleton?** No. Ships in Sprint 5 or 6 paired with C3.12.

---

## Epic E5 — Marketing Surface

*The Astro static site at `sunil-trading-company.yugmalabs.ai`. The first impression. Loads in <1 second on Tier-3 3G. Pulls per-shop content from Firestore at build time.*

### **M5.1** — Marketing site landing page

*As a first-time visitor (someone who Googled "almirah Ayodhya" or got a wa.me link from a friend), I want the page to load instantly and show me Sunil-bhaiya's face, his shop name, and a way to talk to him, so that I trust this is real.*

| Field | Value |
|---|---|
| Auth tier | `noAuth` |
| Adapter | None (build-time fetch) |
| Feature flag | None |
| Firestore reads | 0 at runtime (build-time only) |
| Cross-tenant test | N |
| Refs | ADR-011, locked PQ4 |

**Acceptance criteria:**
1. Page is built with Astro and served as pure static HTML+CSS+minimal JS from Firebase Hosting
2. Initial bundle size <100 KB including subset Devanagari font
3. Time to first paint <1 second on a 3G connection (verified via Lighthouse)
4. Hero section: Sunil-bhaiya's face photo + shop name in Devanagari + tagline + GST number + established year
5. Primary CTA: `Sunil-bhaiya से अभी बात कीजिए` ("Talk to Sunil-bhaiya now") → opens `wa.me/91XXXXXXXXXX` with a prefilled greeting
6. Secondary CTA: `दुकान खोलिए` ("Open the shop") → deep links into the customer app (Play Store fallback if not installed)
7. Below hero: 2 curated SKU previews from the most recent shortlist (just photo + name + price, no interaction)
8. Footer: address, hours, map link

**Edge cases:**
1. Visitor on a desktop browser: same content, responsive layout
2. Visitor with JavaScript disabled: HTML + CSS still render fully (Astro generates pure static)
3. Devanagari font fails to load: fallback to system Devanagari font

**Dependencies:** M5.5 (build pipeline)

---

### **M5.2** — Auto-play greeting voice note on the marketing site landing

*As a first-time visitor, I want to hear Sunil-bhaiya's voice on the marketing site (with a mute button), so that the trust ceremony starts before I even download the app.*

| Field | Value |
|---|---|
| Auth tier | `noAuth` |
| Adapter | None |
| Feature flag | None |
| Firestore reads | 0 |
| Cross-tenant test | N |
| Refs | B1.3 (in-app companion) |

**Acceptance criteria:**
1. The greeting voice note URL is fetched at build time and embedded in the page as a `<audio>` element
2. Auto-play attempted on page load (with a small mute button visible)
3. Browser-blocked autoplay: a "tap to hear Sunil-bhaiya" CTA appears in place of the auto-play
4. Voice note file is hosted on the same Cloudinary or Firebase Storage as the in-app version (single source of truth)

**Edge cases:**
1. Voice note file is large (>500 KB): Lighthouse warning; consider lazy-loading on first interaction
2. Voice note unavailable: silent fallback, no error

**Dependencies:** M5.1, B1.8

---

### **M5.3** — Curated catalog preview (top 6 SKUs)

*As a visitor, I want to see what Sunil-bhaiya sells without downloading an app, so that I can decide if it's worth visiting or downloading.*

| Field | Value |
|---|---|
| Auth tier | `noAuth` |
| Adapter | None (build-time) |
| Feature flag | None |
| Firestore reads | 0 at runtime |
| Cross-tenant test | N |
| Refs | M5.1, B1.4 |

**Acceptance criteria:**
1. The top 6 SKUs from the most recent curated shortlist are baked into the page at build time
2. Each preview shows: Golden Hour photo (loaded from Cloudinary CDN), Devanagari name, price
3. Tapping a preview opens a modal with full details (still no interaction; this is read-only)
4. A `पूरा कैटलॉग देखिए` ("See full catalog") CTA links into the customer app

**Edge cases:**
1. Shopkeeper has no curated shortlist: show a placeholder "जल्द ही" ("coming soon")
2. SKUs change between builds: page is rebuilt nightly + on theme update (M5.5)
3. Photo CDN is slow: skeleton placeholders while loading

**Dependencies:** M5.1, M5.5

---

### **M5.4** — Visit / contact page (map, hours, WhatsApp CTA)

*As a visitor in Ayodhya, I want to see where the shop is and how to get there, so that I can visit in person.*

| Field | Value |
|---|---|
| Auth tier | `noAuth` |
| Adapter | None |
| Feature flag | None |
| Firestore reads | 0 |
| Cross-tenant test | N |
| Refs | SAD §5 Shop.geoPoint |

**Acceptance criteria:**
1. A `दुकान आइए` ("Visit the shop") page with:
   - Embedded static map image (no live JS map; just an image with a Google Maps link)
   - Address in Devanagari and English
   - Hours of operation
   - Phone number (tap-to-call)
   - WhatsApp button (`wa.me` link)
2. The map image is fetched at build time from Google Static Maps API and cached as a static asset (one-time cost)

**Edge cases:**
1. Static map image fails to fetch at build time: build still succeeds with a "map unavailable" placeholder
2. Shopkeeper updates address: rebuild triggered (M5.5)

**Dependencies:** M5.1

---

### **M5.5** — Build trigger automation (Firestore update → CI rebuild)

*As Sunil-bhaiya, I want the marketing site to update automatically when I change my tagline or upload a new photo, so that I don't need to ask Yugma Labs to deploy.*

| Field | Value |
|---|---|
| Auth tier | N/A (background service) |
| Adapter | None |
| Feature flag | None |
| Firestore reads | 1 (theme tokens at build time) |
| Cross-tenant test | N |
| Refs | locked PQ4 |

**Acceptance criteria:**
1. A Cloud Function `triggerMarketingRebuild` (added to SAD §7 inventory as a 6th function) is triggered by writes to `shops/{shopId}/theme/current`
2. The function calls a GitHub Actions `workflow_dispatch` hook to start `ci-marketing.yml`
3. The CI workflow runs the Astro build for the affected shop only
4. Build duration <2 minutes
5. Deployment to Firebase Hosting happens automatically on successful build
6. A nightly cron also rebuilds (safety net)
7. Failed builds notify Yugma Labs ops via email

**Edge cases:**
1. Multiple theme updates within 60 seconds: debounce; only one rebuild per minute
2. Build fails: previous version stays deployed; alert sent
3. Firestore admin credentials in CI rotated: requires manual update

**Dependencies:** I6.4, S4.12

---

## Walking Skeleton — Month 3 Technical Gate

The following **19 stories** form the **Walking Skeleton** — the minimum viable end-to-end flow that proves every architectural component works. They must all ship before the Month 3 gate per Brief §6. *(v1.0.5 patch: I6.12 added — the SAD §9 field-partition repository discipline is foundational for every subsequent Project/ChatThread/UdhaarLedger write; skipping it leaves every commit-path story structurally unsafe for offline replay.)*

| # | Story | Epic | What it proves |
|---|---|---|---|
| 1 | I6.1 — AuthProvider adapter scaffolding 🦴 | E6 | Auth interface + Firebase implementation work |
| 2 | I6.2 — Anonymous → Phone Auth UID merger 🦴 | E6 | Layered auth + UID merger work |
| 3 | I6.3 — Refresh-token session persistence 🦴 | E6 | Customer never re-authenticates |
| 4 | I6.4 — Multi-tenant shopId scoping 🦴 | E6 | Cross-tenant isolation works in CI |
| 5 | I6.10 — Crashlytics + Analytics + Performance + App Check 🦴 | E6 | Day-one observability + abuse protection |
| 6 | **I6.12 — Offline-first field-partition discipline 🦴** *(v1.0.5 add)* | E6 | Customer/operator/system Project partitions enforced at compile time; offline replay is safe |
| 7 | B1.1 — First-time customer onboarding 🦴 | E1 | Shopkeeper-as-product landing works |
| 8 | B1.2 — Anonymous landing with shopkeeper face 🦴 | E1 | Bharosa pillar visible end-to-end |
| 9 | B1.3 — Greeting voice note auto-play 🦴 | E1 | MediaStore adapter + Cloud Storage work |
| 10 | B1.4 — Curated shortlists 🦴 | E1 | Read-budget discipline holds |
| 11 | B1.5 — SKU detail with Golden Hour 🦴 | E1 | Catalog rendering works |
| 12 | C3.1 — Create Project draft 🦴 | E3 | Project entity write works |
| 13 | C3.4 — Commit Project with Phone OTP upgrade 🦴 | E3 | Auth upgrade at commit works |
| 14 | C3.5 — UPI payment intent flow 🦴 | E3 | UPI deep link + state transition work |
| 15 | P2.4 — Sunil-bhaiya Ka Kamra chat thread 🦴 | E2 | Real-time chat works |
| 16 | P2.5 — Customer sends text message 🦴 | E2 | Chat write path works |
| 17 | S4.1 — Shopkeeper sign-in via Google 🦴 | E4 | Ops app auth works |
| 18 | S4.3 — Inventory create new SKU 🦴 | E4 | Ops app write path works |
| 19 | S4.5 — Golden Hour photo capture 🦴 | E4 | Ops app + MediaStore + Cloudinary integration works |

**19 stories** (v1.0.5) that collectively touch every architectural component once at zero feature depth, sequenced into 6 sprints per the Epics & Stories Listing §2 plan. Shipping them by Month 3 proves the foundation works. **Sprint-plan impact:** I6.12 lands in Sprint 1 alongside I6.4 — it's a same-week engineering task for the repository layer, not a multi-sprint effort, and it is a PRECONDITION for C3.1 (Sprint 2/3). Phase 3 (Epics List re-derive) must reflect this.

**Precondition gate (not a Walking Skeleton story):** **I6.11** (Hindi-native design capacity verification) must complete BEFORE Sprint 1 kickoff. It is a governance artifact, not an implementation story, and it blocks every UX-touching story.

Everything outside this list adds depth to capabilities the skeleton has already proven. v1's remaining stories all parallelize on top of the validated foundation.

---

## PRD Open Questions for Alok (5) — 🔒 ALL LOCKED 2026-04-11

> **STATUS: All 5 questions LOCKED on 2026-04-11 per Alok's "go with your recommendation" directive.** John's recommended defaults are now binding PRD decisions. Original framings preserved below for context, with each marked **🔒 LOCKED** and the recommended answer formally adopted.

### PQ-A — How does the customer cancel a Project?

The brief and SAD don't explicitly cover Project cancellation. I propose: customer can cancel a `draft` Project at any time (deletes it); cancelling a `committed` Project requires shopkeeper acknowledgment (no automatic refund logic in v1 since payments haven't been made yet). Customer-initiated cancellation of a `paid` Project is out of scope for v1 (handled offline between customer and shopkeeper). **Default: ship the v1 minimal cancellation per above.**

### PQ-B — Is there a "shopkeeper rating" or feedback flow for the customer post-delivery?

The brief mentions a 1-tap satisfaction reaction (👍/👎) inline on the chat thread. Is that the entire feedback surface, or do you want a more structured "rate Sunil-bhaiya" flow? **Default: 1-tap reaction only in v1; no separate rating screen.**

### PQ-C — How are operator additions/removals handled in v1?

The bhaiya can add/remove operators via Settings (S4.12). But who creates the *first* operator (the bhaiya himself)? Yugma Labs ops needs to manually create the first Operator document during shop onboarding. **Default: Yugma Labs ops creates the first Operator doc as part of shop onboarding; subsequent operators self-managed by bhaiya via Settings.**

### PQ-D — What happens when a SKU is deleted from inventory?

Deleted from inventory but still referenced in: active Projects (snapshot preserved per SAD §5), customer chat threads (text reference), curated shortlists (filtered out at read time). **Default: soft delete via `isActive: false` flag; never hard-delete in v1.**

### PQ-E — Is there a "block customer" flow for the shopkeeper?

If a customer is abusive, fraudulent, or spammy, can the shopkeeper block them from the ops app? The brief is silent. **Default: yes — a "block this customer" button on the customer detail screen sets a flag that prevents future writes from that anonymous UID. v1 minimal implementation; refined in v1.5.**

If you say "lock all" again, all 5 default to my recommendations.

---

## Handoff Notes for Sally (UX Designer) and Amelia (Developer)

### For Sally (if a UX phase is run before code)

The PRD describes user stories at the *capability* level, not at the *pixel* level. Sally's job is to wireframe the screens these stories describe and produce a UX Spec that Amelia can implement against. Key constraints:

1. **Devanagari first** — every wireframe must show Devanagari strings as the primary content, English as secondary
2. **Tier-3 cheap-Android device targets** — wireframes must work on 4.5" screens with cheap LCDs; no hairline borders, no <12sp text
3. **Elder-tier rendering** — every screen must have an "elder mode" wireframe that shows the larger-text version
4. **Bharosa is visual** — every screen must have a visible reminder of Sunil-bhaiya (face on landing, name in header, voice note inline)
5. **Curation is the default** — no infinite scroll; the customer always sees Sunil-bhaiya's picks first
6. **Loading states matter** — design skeleton screens for the slow-3G first paint
7. **Error states in Hindi** — every error message has a Devanagari version that doesn't sound like a translation

If you skip the UX phase and go directly to Amelia, the implementation team will need to make UI decisions on the fly. That's risky for a Hindi-first product. **My strong recommendation: invoke Sally for a UX Spec phase before Amelia begins.**

### For Amelia (the developer)

When you start implementation:

1. **Start with the Walking Skeleton (19 stories above).** Ship them in order. Don't start E2 until E6 + E1 + early E3 are working. *(v1.0.5 patch — was 17; added I6.10 in v1.0.3 and I6.12 in v1.0.5.)*
2. **Honor the standing rules** (11 rules in the preamble). Every PR that violates a standing rule is rejected at code review. *(v1.0.5 patch — was 10; added Standing Rule 11 field-partition discipline.)*
3. **The cross-tenant integrity test in CI is non-negotiable.** Every PR that touches Firestore must pass it.
4. **Read Winston's SAD §3 (monorepo structure)** before you make a single file. Use melos. Use the exact folder layout.
5. **Use Claude Code with the Dart/Flutter MCP server** as your primary dev environment per the brief and SAD.
6. **Hindi strings live in `lib_core/src/locale/strings_hi.dart` first.** English follows. Never the reverse.
7. **Every feature-flagged story has an off-state behavior described.** Implement both states.
8. **The forbidden vocabulary list for UdhaarLedger is enforced at the security rule layer.** Your code that writes to UdhaarLedger should also have a Dart-side assert as a defense-in-depth measure.
9. **Voice notes are 5–60 seconds.** Enforce the limits at the recording UI layer, not just at the storage layer.
10. **Cross-reference every story to the brief section, SAD section, and ADR.** When in doubt, trust the SAD's architectural decisions over your own instinct.

---

## Out of scope for v1 (re-stated for clarity)

- Implementation code (Amelia's job)
- Architecture decisions (Winston's SAD)
- Brief-level positioning (Mary's brief)
- Business model / pricing / runway (founder-owned)
- UX wireframes (Sally's UX Spec, if invoked)
- Any feature in the brief's §7 v1.5 or v2 section
- B2B / institutional buyers
- Pilgrim / mandir / religious framing
- Live video / WebRTC
- AR placement
- Voice search
- Premium features layer (deferred to v1.5+)
- WhatsApp Business Cloud API
- Custom domain support beyond `<shopname>.yugmalabs.ai`

---

**End of Product Requirements Document v1.0.5.**

*v1.0.5 patches (Advanced Elicitation + Party Mode + audit-finding back-fill — Phase 2 of the back-fill round):*

*(1) **Winston's SAD v1.0.4 handoff applied — 8 new stories + 4 existing updates + 1 new Standing Rule.**
  - **New stories:** I6.11 (Hindi design capacity verification gate), I6.12 (offline field-partition infrastructure, new Walking Skeleton story), B1.13 (Devanagari invoice with Mukta-italic signature, Constraint 4 compliant), C3.12 (customer-side shop deactivation notification per DPDP Act 2023), S4.16 (MediaStore adapter cost-monitoring contract + ops dashboard), S4.17 (shopkeeper NPS + burnout early warning via SAD `feedback` sub-collection), S4.18 (repeat-customer analytics event + churn warning), S4.19 (ops-side shopkeeper-triggered shop deactivation).
  - **Updated stories:** I6.7 (AC #7 kill-switch flag split Firestore-real-time vs Remote Config per SAD ADR-007 v1.0.4 clarification; AC #8 adapter consumer discipline), C3.4 (AC #4 Triple Zero `amountReceivedByShop == totalAmount` invariant — Phase 3, 2026-04-30 patch: the field is NOT set at commit; it stays 0 until the operator runs `applyOperatorMarkPaidPatch`. The invariant is asserted at the rule layer for any transition into `paid|closed`. AC #8 Standing Rule 11 compliance note), C3.5 (AC #8 UPI URI invariant — `am=` equals `totalAmount`, `pa=` equals `shop.upiVpa`, no commission. Phase 3 patch: the customer's "I paid" tap parks the project at `awaiting_verification`; operator runs `applyOperatorMarkPaidPatch` to advance to `paid`), S4.10 (AC #7/#8/#9 RBI guardrails: `reminderOptInByBhaiya`, `reminderCountLifetime` capped at 3, `reminderCadenceDays` 7-30 shopkeeper-controlled).
  - **New Standing Rule 11** (Project field-partition discipline): repository methods cannot construct a Project patch that crosses the customer/operator/system partition defined in SAD §9. Enforced via Freezed sealed unions `ProjectCustomerPatch` / `ProjectOperatorPatch` / `ProjectSystemPatch`. Also extended to `ChatThread` and `UdhaarLedger`. Standing rule count: 10 → 11.*

*(2) **5 AE methods applied to the patched PRD:***
  - *#4 User Persona Focus Group — Sunita-ji, Aditya, Geeta-ji, Sunil-bhaiya react to the 8 new story flows. Surfaced F-P1 (shopkeeper-side deactivation flow needs a "what about my open udhaars" reassurance) → folded into S4.19 edge cases. Surfaced F-P2 (customer C3.12 banner needs a "export your data" CTA, not just a notification) → folded into C3.12 AC #7. Surfaced F-P3 (NPS card wording too formal for Sunil-bhaiya's register) → S4.17 AC #1 revised from formal to casual Devanagari.*
  - *#34 Pre-mortem Analysis — imagine each new story fails at Month 6. F-PM1: "S4.16 counter drift over months corrupts burn rate math" → AC #7 (retroactive rebuild script + `multiTenantAuditJob` nightly recount safety net). F-PM2: "B1.13 signature in Mukta italic fails cheap-Android Devanagari rendering" → AC clarified that existing Constraint 4 QA on 5 budget devices covers invoice rendering. F-PM3: "S4.19 accidental triggers destroy a live shop" → reinforced with the 24-hour reversibility window in AC #8.*
  - *#36 Challenge from Critical Perspective — play devil's advocate. F-CC1: "Is Standing Rule 11 just ceremony?" — countered by the offline replay invariant evidence in SAD v1.0.4 §9 (a 3-day-offline customer CAN revert operator state without it). Rule stays. F-CC2: "Why is S4.18 a separate story instead of an S4.11 AC?" — answered inline in the S4.18 scoping decision block; it's a state-transition concern, not a dashboard concern.*
  - *#42 Critique and Refine — systematic review of the 8 new stories for ACs that aren't testable. F-CR1: C3.12 AC #6 "the banner updates" needed a trigger mechanism → added "via Firestore real-time listener fire". F-CR2: S4.17 "burnout early warning" needed a specific numeric threshold → added "2 consecutive scores ≤6". F-CR3: S4.18 "churn warning" needed a specific repeat-rate threshold → added "<5% trailing 60 days".*
  - *#27 What If Scenarios — stress-test the 8 new stories at 10× scale. F-WI1: at shop #10, I6.11 verification artifact management becomes a bottleneck → accepted (ops runbook will handle via a 90-day recurring calendar check). F-WI2: at shop #25, S4.16 counter read on every dashboard load is 25 reads per load → AC #3 clarified to cache the counter client-side. F-WI3: at shop #50, S4.18 backfill script runtime is hours → backfill is a one-time script, not a per-release event.*

*(3) **Party-mode dispositions:** John / Mary / Winston / Sally voted on each AE finding. All F-* findings above landed by ≥3/4 vote. Three additional findings were REJECTED: (a) "split I6.12 into three stories by entity type" (❌ 4/4 — would fragment foundation infra), (b) "add a customer-side cancellation flow for committed Projects" (❌ 3/1 — out of brief scope per PQ-A), (c) "add an in-app NPS prompt for the customer too" (⚠️ 2/2, John broke tie — folded into S4.17 AC #6 as companion mechanism, not separate story).*

*(4) **Brief→PRD coverage audit cross-check (9 gaps, now closed at PRD layer):***
  - *Gap 1 (Constraint 15 Hindi capacity gate) → closed by **I6.11***
  - *Gap 2 (shop deactivation + DPDP) → closed by **C3.12 + S4.19***
  - *Gap 3 (Cloudinary cost telemetry) → closed by **S4.16***
  - *Gap 4 (Devanagari invoice) → closed by **B1.13***
  - *Gap 5 (NPS + burnout) → closed by **S4.17***
  - *Gap 6 (wa.me Project context fallback) → already closed at SAD v1.0.4 §7 Function 2; existing P2 stories suffice*
  - *Gap 7 (repeat-customer tracking) → closed by **S4.18***
  - *Gap 8 (offline conflict resolution) → closed by **I6.12 + Standing Rule 11***
  - *Gap 9 (zero-commission math invariant) → closed by **C3.4 + operator mark-paid (Phase 3, 2026-04-30)**: `amountReceivedByShop` stays 0 through commit, flips to `totalAmount` only inside `applyOperatorMarkPaidPatch`; rule layer asserts equality at every transition into `paid|closed`. Tested in CI (`cross_tenant_integrity.test.ts` Phase 3 describe block, 30 tests).*

*(5) **Story count updates:** v1.0.5 adds 8 new stories. Total: 59 → 67. Epic distribution: E6: 10→12 (I6.11, I6.12), E1: 12→13 (B1.13), E2: 8, E3: 11→12 (C3.12), E4: 13→17 (S4.16, S4.17, S4.18, S4.19; S4.14 remains v1.5-deferred, S4.15 reserved), E5: 5. Walking Skeleton: 18 → 19 (I6.12 added, the only new story with foundational Walking Skeleton characteristics). Standing rules: 10 → 11. *(Phase 6 IR Check v1.2 patch 2026-04-11: corrected from "58 → 66"; the v1.1 baseline was 59 post-S4.13, not the v1.0 baseline 58. Per-epic sum was always canonically 67.)**

*(6) **What did NOT change (deliberately):** All v1.0.1–v1.0.4 locked decisions remain. The 10 original standing rules. The 6-epic structure. The 6-sprint sequencing baseline (Phase 3 will re-derive on top of this). The five locked PQs. ADR references throughout. The font stack (Constraint 4 — Mukta italic for signature preserves compliance). The Walking Skeleton selection discipline (only add a story if it's foundational, not just valuable).*

*v1.0.3 patches (post-IR-check): Walking Skeleton table updated to 18 stories (I6.10 added). B1.3 AC #8 added (empty state when no greeting voice note). C3.4 AC #4 clarified (elder confirmation gating covers both Decision Circle elder personas AND universal accessibility toggle from P2.8). B1.2 AC #7 added (English/Hindi toggle in top-right corner).*

*v1.0.2 patches: B1.2 acceptance criterion #5 replaced bottom-tab nav with Shopkeeper Presence Dock (per frontend-design plugin pushback). B1.4 acceptance criterion #2 replaced "paginated" with "exactly 6, finite, with 'और दिखाइए' as the only escape hatch" (per Sally's UX Spec §4.3 + frontend-design plugin convergent finding). v1.0.1 patches: footer story count corrected from 47 to 58, B1.6 + B1.12 dependencies fixed.*

**Total length:** ~14,500 words
**Total stories:** **67 unique** *(v1.0.5: 59 → 67, +8 Winston handoff stories; Phase 6 IR Check v1.2 arithmetic correction 2026-04-11 — v1.1 baseline was 59 post-S4.13, not 58)* (E6: 12, E1: 13, E2: 8, E3: 12, E4: 17, E5: 5).
**Walking Skeleton stories:** **19** *(v1.0.5: 18 → 19, +I6.12)*
**Open questions:** 5 (all locked)
**Cross-references to brief:** ~70 *(+10 in v1.0.5 patches)*
**Cross-references to SAD:** ~75 *(+25 in v1.0.5 patches — tied to SAD v1.0.4's new schema fields, ADRs 013/014/015, Functions 7/8)*
**Cross-references to ADRs:** ~45 *(+15 in v1.0.5 patches)*
**Standing rules:** **11** *(v1.0.5: 10 → 11, +Rule 11 field-partition discipline)*
**Personas referenced:** 5 (4 customer + 1 operator)

**Phase 3 handoff note (for the Epics List re-derive):**

Phase 3 (Epics List re-derive) must consume this PRD v1.0.5 and produce an updated `epics-and-stories.md` v1.2 that:

1. Accommodates the 8 new stories in their epic homes with updated counts.
2. Folds I6.12 into Sprint 1 (same sprint as I6.4, since they're both repository-layer foundation).
3. Treats I6.11 as a Sprint 0 / pre-sprint gate, NOT a Sprint 1 story.
4. Places C3.12 + S4.19 as a paired Sprint 5 or 6 story cluster.
5. Places S4.16 + S4.17 + S4.18 as Sprint 4 or 5 depth/telemetry cluster.
6. Places B1.13 as a Sprint 4 or 5 Bharosa depth story.
7. Updates complexity sizing: I6.12 is **XL** (new foundational), I6.11 is **S** (governance artifact), B1.13 is **M**, C3.12 is **M**, S4.16 is **L**, S4.17 is **M**, S4.18 is **M**, S4.19 is **S**.
8. Updates the "stories per auth tier" table: noAuth 5→6 (I6.11), anonymous 14, phoneVerified 11→13 (B1.13, C3.12), googleOperator 27→31 (S4.16–S4.19), N/A 1→2 (I6.12 is cross-tier infra).
9. Updates the "stories per adapter dependency" table: MediaStore 11→12 (S4.16 extends the contract).
10. Updates the Walking Skeleton sprint plan in §2 to 19 stories.
11. Does NOT touch SAD, Brief, or UX Spec — those are handled in other phases.

— John, Product Manager
2026-04-11 (v1.0.5 back-fill)
