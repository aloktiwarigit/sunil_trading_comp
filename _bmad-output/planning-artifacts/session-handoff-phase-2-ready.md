---
artifact: Session Handoff — Phase 1 + Phase 2.0 Wave 1 + I6.8 deployed
audience: Next Claude Code session (fresh Amelia activation)
purpose: Complete context transfer so the next session can pick up where Phase 1 + 2.0 Wave 1 ended without losing quality or re-litigating decisions
version: v1.2
date_created: 2026-04-11
date_updated: 2026-04-12
outgoing_head: see `git log` (latest commit on main)
repo: https://github.com/aloktiwarigit/sunil_trading_comp
project_path_on_founder_machine: C:\Alok\Business Projects\Almira-Project
sprint_0_status: CLOSED — END STATE A (Alok is Hindi reviewer, 2026-04-12)
d4_consent: SECURED (Sunil-bhaiya face photo, 2026-04-12)
phase_1_status: COMPLETE (all sub-phases 1.1 through 1.9 shipped)
phase_2_0_wave_1_status: COMPLETE (theme foundation port)
phase_2_x_i6_8_status: DEPLOYED + LIVE (asia-south1, audit writes verified clean)
phase_2_y_region_migration_status: COMPLETE (dev Firestore migrated nam5 → asia-south1)
phase_2_1_status: READY TO START — Sprint 0 closed, all blockers removed
---

## §0 — POST-HANDOFF UPDATE (2026-04-12)

**This doc is v1.0 dated 2026-04-11. After it was written, the same session continued and completed two more pieces of work. Read this §0 first; the rest of the doc still describes the original starting state at v1.0.**

### What changed since v1.0
1. **I6.8 deployed successfully to `yugma-dukaan-dev`.** Cloud Build IAM was fixed via the gcloud CLI (Alok installed gcloud mid-session). After two propagation-race retries (one runtime token-cache stale state required forcing a fresh instance via a source hash bump), `killSwitchOnBudgetAlert` is live in `asia-south1`, subscribed to the `budget-alerts` Pub/Sub topic, and audit writes to `/system/budget_alerts/history` are confirmed working end-to-end.
2. **Cloud Billing budget → Pub/Sub topic wired** via `gcloud billing budgets update` — the existing $1 cap budget now publishes to `budget-alerts` (not just email). Real Cloud Billing pings observed in function logs.
3. **dev Firestore region migrated `nam5` → `asia-south1`** to match SAD §1 region requirement and Firestore-region constraint with the function. Database deleted + recreated (tombstone wait honored), rules + indexes redeployed, I6.8 sanity-tested clean against the new database.
4. **Triple Zero intact at $0.00/mo** — verified cost math: Cloud Functions 2M invocations + 400k GB-s free tier vs. expected 0–5 invocations/mo from this function. Customer pays nothing.

### What is still pending
- ~~Sprint 0 / I6.11 Hindi-capacity gate~~ **CLOSED 2026-04-12.** END STATE A: Alok is the Hindi reviewer. No external hire needed.
- ~~D4 Sunil-bhaiya face photo consent~~ **SECURED 2026-04-12.** B1.2 can use real photo as primary path.
- **Phase 1.10** — fix 10 pre-existing `phone_upgrade_coordinator_test.dart` failures (queued, non-blocking).
- **Cloud Storage enable on `yugma-dukaan-dev`** — 1 console click, needed before B1.6 voice notes can land.
- **Phase 2.1 Sprint 2/3 widget port** — **UNBLOCKED.** Ready to start immediately. See §3 for the multi-agent execution plan.

### Where to look
- `functions/src/kill_switch.ts` header comment has the full deploy history (2026-04-11 fail → rollback → 2026-04-12 redeploy → IAM token refresh → region migration).
- `docs/runbook/staging-setup.md` already documents the asia-south1 region requirement, the Cloud Build IAM pre-fix steps, and the kill-switch deploy + verify flow. No region drift in any committed file.
- `_bmad-output/implementation-artifacts/sprint-status.yaml` still shows I6.8 as `ready-for-dev` — **update this on next session start** to `done` once you've verified the deploy is still live (`firebase functions:list --project yugma-dukaan-dev`).

---

# Session Handoff — Phase 1 complete + Phase 2.0 Wave 1 + I6.8 ready

> **Paste the §2 kickoff prompt into the new Claude Code session. Everything else in this doc is reference for the new Amelia to read once activated.**

---

## §1 — What the outgoing session (2026-04-11) accomplished

The previous session was a marathon execution window that shipped every non-Sprint-0-blocked piece of infrastructure. By the end of the session the following is shipped and pushed to `main` at `aloktiwarigit/sunil_trading_comp`:

### What's in git

**10 new commits on `main`** (the pre-session baseline was `d7b54da`). Read them with `git log --oneline -15` on activation — they tell the story cleanly. The sequence:

```
05ba69c  docs(runbook): I6.8 deploy rollback + Cloud Build IAM prep
5d9f940  feat(functions): Phase 2.x I6.8 / killSwitchOnBudgetAlert Cloud Function
b3071bb  feat(lib_core): Phase 2.0 Wave 1 / theme foundation + sprint-status bootstrap
651ed48  fix(lib_core): Phase 1.9 code review cleanup (A1/A3/A4 + B3 + C1/C2/C5)
c70ee56  docs: Phase 1.7 + 1.8 / CONTRIBUTING + lib_core README + staging runbook
d700174  feat(lib_core): Phase 1.5 / Sprint 3 shared models + repos
0ad1d68  feat(lib_core): Phase 1.4 / I6.9 Devanagari locale scaffold + font pipeline
9c04f29  feat(lib_core): Phase 1.3 / I6.7 real-time kill-switch listener
8eafa13  feat(lib_core): Phase 1.2 / I6.5 CommsChannel adapter + Message model
810498e  feat(lib_core): Phase 1.1 / I6.6 MediaStore adapter implementation
d7b54da  fix(lib_core): Sprint 2.3 cleanup + session handoff for Sprint 3   ← pre-session baseline
```

### What the 10 commits collectively deliver

**Phase 1 — Non-blocked infrastructure while Sprint 0 executes:**

| Phase | Story | What shipped |
|---|---|---|
| 1.1 | I6.6 MediaStore adapter | Interface + Cloudinary catalog URL builder + Firebase Storage voice notes + R2 stub + factory + 25 tests. Catalog upload throws `notYetWired` until Sprint 2 Cloud Function lands; voice note upload works end-to-end. |
| 1.2 | I6.5 CommsChannel adapter + Message model | Interface + `ConversationHandle` sealed union + Firestore real-time chat default + wa.me launcher fallback (duplicates SAD §7 Function 2 Hindi body client-side) + Message Freezed model with `bhaiya/beta/munshi` domain enum + 36 tests |
| 1.3 | I6.7 real-time kill-switch listener | `KillSwitchListener` Firestore onSnapshot watcher on `/shops/{shopId}/featureFlags/runtime` + `RuntimeFeatureFlags` Freezed model + `lastSnapshotAt` staleness timestamp + 11 tests |
| 1.4 | I6.9 Devanagari locale scaffold + font subset script | `AppStrings` interface with 50 methods (from UX Spec v1.1 §5.5) + `AppStringsHi` + `AppStringsEn` + `LocaleResolver` (Remote Config driven) + `tools/generate_devanagari_subset.sh` + `docs/runbook/font-subset-build.md` + 18 tests including forbidden-vocab scan |
| 1.5 | Sprint 3 shared models + repos | `Operator` + `InventorySku` + `CuratedShortlist` + `VoiceNote` Freezed models (all with `@JsonValue` canonical naming — `bhaiya/beta/munshi`, `shaadi/naya_ghar/dahej/...`) + 4 repositories with shop-scoping + 39 tests + `build.yaml` with `explicit_to_json: true` |
| 1.6 | Field-partition extension | NO CODE — verified pre-existing from Sprint 2.3. Phase 1.9 added missing ChatThread + UdhaarLedger negative compilation tests. |
| 1.7 | CONTRIBUTING.md + lib_core README | Root CONTRIBUTING.md with Standing Rule 11 + forbidden vocab + free-features-only + code review triage legend + workflow commands. packages/lib_core/README.md with full src/ tree + adapter table + partition discipline summary |
| 1.8 | Staging Firebase setup runbook | `docs/runbook/staging-setup.md` with 9 steps including Blaze upgrade + budget alerts + Pub/Sub + function deploy + IAM pre-fix |
| 1.9 | 3-agent adversarial code review | 3 parallel Explore agents (security/rules, models/repos, adapters/tests) → 9 real findings re-triaged → all addressed in commit `651ed48`. 3 false alarms identified and dismissed with defensive tests added. |

**Phase 2.0 Wave 1 — Theme foundation port (Option C scope):**

| Phase | What shipped |
|---|---|
| 2.0 Wave 1 | `packages/lib_core/lib/src/theme/tokens.dart` (YugmaColors / YugmaFonts / YugmaTypeScale / YugmaSpacing / YugmaRadius / YugmaShadows / YugmaMotion / YugmaTapTargets) + `shop_theme_tokens.dart` Freezed + `yugma_theme_extension.dart` ThemeExtension + 27 tests. **Sprint 0 discipline fix:** the Sally-authored tagline in `sunilTradingCompanyDefault()` was stripped to empty strings — populated at runtime from Firestore post-Sprint-0. |
| 2.0 Wave 2/3/4 | **DEFERRED** per Option C decision — widget port, reconciliation, and adversarial review wait until Sprint 0 closes and resolves the Hindi-first vs English-first locale direction. Re-opens as Phase 2.1. |
| 1.11 | sprint-status.yaml bootstrap via `bmad-sprint-planning` skill — canonical BMAD tracker at `_bmad-output/implementation-artifacts/sprint-status.yaml` with all 67 stories serialized |

**Phase 2.x — I6.8 Kill-switch Cloud Function (code ready, deploy blocked):**

| Phase | What shipped |
|---|---|
| 2.x I6.8 | `functions/` TypeScript workspace complete: `package.json` + `tsconfig.json` + `jest.config.js` + `eslint.config.js` (flat v9) + `.gitignore` + `src/index.ts` barrel + `src/kill_switch.ts` (the function — 200 lines) + `test/kill_switch.test.ts` (10 jest tests) + `firebase.json` already wired to `functions/` source path from Sprint 1.7. Function deploys to `asia-south1`, subscribes to `budget-alerts` Pub/Sub topic, flips kill-switch flags on 100% threshold. |
| 2.x I6.8 deploy | **ATTEMPTED AND ROLLED BACK** on 2026-04-11. Cloud Build failed with "missing permission on the build service account" — a known first-deploy IAM gotcha on fresh Blaze projects under Google's 2024 org policy tightening. Zombie function deleted via `firebase functions:delete`. Clean state restored. Deploy unblocked by adding 4 IAM roles to the `{project-number}-compute@developer.gserviceaccount.com` default service account — documented in `docs/runbook/staging-setup.md` §6.4. |

### Test + quality metrics

```
Tests added this session:     ~175 passing
Pre-existing regressions:     0 introduced (the 10 phone_upgrade_coordinator failures are unchanged)
New production code:          ~5,500 lines Dart + TypeScript
New test code:                ~2,000 lines
New docs:                     CONTRIBUTING + 2 READMEs + 2 runbooks + this handoff
Code review blockers found:   9 (all addressed in Phase 1.9)
Firebase cost accrued:        $0.00 (Triple Zero intact)
Commits on origin/main:       10 pushed
Commits local only:           0
```

### Walking Skeleton progress

**6 of 19 Walking Skeleton stories complete** (unchanged count from prior handoff — Phase 1 shipped non-WS infrastructure; the 13 remaining WS stories are user-visible and Sprint-0-blocked).

| Story | Epic | Status | Notes |
|---|---|---|---|
| I6.1 AuthProvider adapter | E6 | ✅ Sprint 1.3 | 4 impls (Firebase + 3 stubs) + factory + tests |
| I6.2 Anonymous→Phone UID merger | E6 | ✅ Sprint 2.1 | Correct Firebase `e.credential` + `signInWithCredential` pattern |
| I6.3 Refresh-token session persistence | E6 | ✅ Sprint 2.2 | `SessionBootstrap.verifyPersistedUser` |
| I6.4 Multi-tenant shopId scoping | E6 | ✅ Sprint 1.4 | `firestore.rules` deployed to dev, cross-tenant integrity test live |
| I6.10 Crashlytics + Analytics + App Check | E6 | ✅ Sprint 1.5 | 9 canonical events |
| I6.12 Offline field-partition discipline | E6 | ✅ Sprint 1.4 + 2.1 + 2.3 + 1.9 | Freezed sealed partitions; negative compile tests cover all 3 entities (Project/ChatThread/UdhaarLedger) after Phase 1.9 |
| **B1.1 First-time customer onboarding** | E1 | ⏸ Sprint-0-blocked | |
| **B1.2 Bharosa landing with shopkeeper face** | E1 | ⏸ Sprint-0-blocked | D4 consent still pending — fallback is the default path |
| **B1.3 Greeting voice note auto-play** | E1 | ⏸ Sprint-0-blocked | |
| **B1.4 Curated occasion shortlists** | E1 | ⏸ Sprint-0-blocked | Read budget discipline held |
| **B1.5 SKU detail with Golden Hour photo** | E1 | ⏸ Sprint-0-blocked | |
| **C3.1 Project draft creation** | E3 | ⏸ Sprint 4+ | |
| **C3.4 Commit Project with Phone OTP upgrade** | E3 | ⏸ Sprint 5 | |
| **C3.5 UPI payment intent flow** | E3 | ⏸ Sprint 5 | |
| **P2.4 Sunil-bhaiya Ka Kamra chat thread** | E2 | ⏸ Sprint 4 | |
| **P2.5 Customer sends text message** | E2 | ⏸ Sprint 4 | |
| **S4.1 Shopkeeper Google sign-in** | E4 | ⏸ Sprint-0-blocked | |
| **S4.3 Inventory create new SKU** | E4 | ⏸ Sprint 4 | |
| **S4.5 Golden Hour photo capture flow** | E4 | ⏸ Sprint 5 | |

**Non-Walking-Skeleton E6 stories status (new this session):**

| Story | Status | Notes |
|---|---|---|
| I6.5 CommsChannel adapter | ✅ Phase 1.2 | NOT a Walking Skeleton story; shipped as non-blocked prep |
| I6.6 MediaStore adapter | ✅ Phase 1.1 | NOT a Walking Skeleton story; shipped as non-blocked prep |
| I6.7 Feature flag system (Remote Config + real-time kill-switch split) | ✅ Phase 1.3 | PRD I6.7 AC #7 split contract honored |
| I6.8 Kill-switch Cloud Function | 🟠 Ready-for-dev | Code shipped, deploy blocked on Cloud Build IAM |
| I6.9 Devanagari locale + font pipeline | ✅ Phase 1.4 | 50 strings, ready for Sprint 0 reviewer |
| I6.11 Hindi-native design capacity gate | 🔴 In-progress | **Alok's outreach clock** — the hard blocker |

### Firebase environment state

- **`yugma-dukaan-dev`** (`934939527575`):
  - **Blaze plan enabled** ✅
  - **Budget alerts at $0.10 / $0.50 / $1.00** with email + Pub/Sub to `aloktiwari49@gmail.com` ✅
  - **Pub/Sub topic `budget-alerts`** ✅ created (auto-created by function deploy, wired to Cloud Billing budget via `gcloud billing budgets update`)
  - **`killSwitchOnBudgetAlert` function** ✅ **deployed and live** in asia-south1 (rev `killswitchonbudgetalert-00002-pos`). Audit writes confirmed working.
  - **Firestore** ✅ `(default)` database in **asia-south1** (Mumbai) — migrated from nam5 on 2026-04-12. Rules + indexes deployed.
  - **Auth + both apps** remain in their Sprint 1 state (anonymous + phone + Google enabled)
  - **Cloud Storage** NOT enabled yet (console click — needed for Sprint 3 B1.3 voice notes)
  - **Cloud Build IAM** ✅ All required roles granted to compute default SA

- **`yugma-dukaan-staging`** (`939619699554`): unchanged — project exists, no services enabled

- **`yugma-dukaan-prod`** (`1066843618613`): unchanged — project exists, no services enabled

- **Firebase CLI logged in as**: `aloktiwari49@gmail.com` (confirmed via `firebase login:list`)

- **gcloud CLI**: ✅ installed at `C:\Users\alokt\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\` (installed 2026-04-12). Needs `PATH` export in bash: `export PATH="/c/Users/alokt/AppData/Local/Google/Cloud SDK/google-cloud-sdk/bin:$PATH"`.

### Sprint 0 Hindi-capacity gate

**Status: STILL NOT CLOSED.** Unchanged from prior handoff. Alok executing outreach on his own clock per `_bmad-output/planning-artifacts/sprint-0-execution-kit.md`.

**Decision rule:** either (a) hire/contract a Hindi-native design reviewer via Option B outreach (NID/BHU/personal network + §3 30-minute vetting protocol) — END STATE A — or (b) flip `defaultLocale` Remote Config flag `"hi"→"en"` across all 3 Firebase projects + notify Sunil-bhaiya in person + log `constraint_15_fallback_triggered` Crashlytics event — END STATE B. Both acceptable.

**End state markers to look for on next session startup:**
- END STATE A: `docs/runbook/hindi_design_capacity_verification.md` exists and is signed
- END STATE B: `_bmad-output/planning-artifacts/constraint-15-fallback-decision.md` exists

If neither exists on next session start, Sprint 0 is still open. Ask Alok for status.

---

## §2 — Kickoff prompt for the new session (PASTE THIS)

> **Copy everything inside the triple-quote block below and paste it as the first message to the new Claude Code session in `C:\Alok\Business Projects\Almira-Project`.**

```markdown
You are Amelia — Senior Software Engineer on the Yugma Dukaan project (Sunil Trading Company, an almirah shop in Ayodhya's Harringtonganj market run by Sunil-bhaiya). This is a real client engagement for Alok, founder of Yugma Labs. Re-activate your BMAD developer persona via the `bmad-agent-dev` skill.

## Immediate context (do NOT skip)

Previous sessions (2026-04-11 through 2026-04-12) shipped ALL infrastructure + Sprint 0 is CLOSED. Everything is unblocked. Read these files before doing anything:

1. `_bmad-output/planning-artifacts/session-handoff-phase-2-ready.md` — **full handoff briefing. Read §0 first (latest updates), then §1 (what was built), §3 (Phase 2.1 multi-agent plan), §4 (gotchas).**
2. `C:\Users\alokt\.claude\projects\C--Alok-Business-Projects-Almira-Project\memory\MEMORY.md` — 6 binding memory files (quality over speed, code review integral, best UI/UX, domain-aware, free features only, autonomous commits)
3. Run `git log --oneline -15` + `git status --short` — verify clean working tree on `main`, in sync with `origin/main`
4. `_bmad-output/implementation-artifacts/sprint-status.yaml` — canonical BMAD tracker (67 stories, 12 done, E6 complete)
5. `_bmad-output/planning-artifacts/product-brief.md` v1.4
6. `_bmad-output/planning-artifacts/solution-architecture.md` v1.0.4 (16 sections + 15 ADRs)
7. `_bmad-output/planning-artifacts/prd.md` v1.0.5 (67 stories + 11 Standing Rules preamble)
8. `_bmad-output/planning-artifacts/epics-and-stories.md` v1.2
9. `_bmad-output/planning-artifacts/ux-spec.md` v1.1
10. `_bmad-output/planning-artifacts/frontend-design-bundle/README.md` v1.1
11. `_bmad-output/planning-artifacts/implementation-readiness-report.md` v1.2
12. `CONTRIBUTING.md` — Standing Rule 11 + forbidden vocabulary + free-features-only
13. `packages/lib_core/README.md` — library tree + adapter table + partition discipline
14. `docs/runbook/staging-setup.md` — 9-step staging bring-up runbook
15. `docs/runbook/hindi_design_capacity_verification.md` — **Sprint 0 closure doc (END STATE A)**

This is ~160k words of structured planning knowledge + ~5,500 lines of Phase 1 code + ~2,000 lines of tests. Read it, don't skim.

## What you are building (5 sentences)

Yugma Dukaan is a Hindi-first digital storefront for Sunil-bhaiya's almirah shop in Ayodhya. Customer Flutter app (anonymous browse + phone OTP at commit) + Astro static marketing site + Flutter shopkeeper ops app (Google Sign-In). Triple Zero: zero commission, zero fees, ₹0 ops cost (verified $0.00/month at one-shop scale). Two pillars: Bharosa (shopkeeper-as-product — voice, face, curation, memory, honest absence) + Pariwar (committee-native Decision Circle, feature-flagged). 19-story Walking Skeleton in 6 sprints to the Month 3 gate; full v1 Months 1–5, v1.5 5–7, v2 7–9.

## Current state (top-line summary)

- **Branch:** `main`, pushed to `origin/main` at `aloktiwarigit/sunil_trading_comp`
- **Sprint 0:** CLOSED. END STATE A — Alok is the Hindi reviewer. D4 face photo consent secured.
- **Epic E6 (infrastructure):** DONE — all 12 stories complete
- **Walking Skeleton:** 6 of 19 shipped (E6 infrastructure). 13 user-visible stories now UNBLOCKED.
- **Phase 1:** COMPLETE (1.1 through 1.9 + 1.11)
- **Phase 2.0 Wave 1:** COMPLETE (theme foundation)
- **Phase 2.x I6.8:** DEPLOYED AND LIVE (`killSwitchOnBudgetAlert` in asia-south1, audit writes verified)
- **Phase 2.y:** COMPLETE (Firestore migrated nam5 → asia-south1)
- **Phase 2.1 (widget port + Sprint 2/3):** READY TO START — this is what you're here to build
- **Firebase dev:** Blaze, Firestore in asia-south1, kill-switch live, budget → Pub/Sub wired, gcloud CLI installed
- **Pre-existing test debt:** 10 failures in `phone_upgrade_coordinator_test.dart` — Phase 1.10, non-blocking
- **Triple Zero:** $0.00/mo confirmed

## Your mission this session

**Build the Walking Skeleton UI.** Sprint 0 is closed, all infrastructure is shipped. The next move is Phase 2.1:

1. **Wave 0 (mandatory):** Read the 3 design-bundle source files end-to-end and produce the Devanagari→English mapping table. See handoff §3 for details.
2. **Sprint 2 completion:** B1.1 (first-time customer onboarding) + B1.2 (Bharosa landing with Sunil-bhaiya's real face photo — D4 consent secured). Serial, not parallel — they share the BharosaLanding widget.
3. **Sprint 3:** B1.3 + B1.4 + B1.5 + S4.1 + S4.13 via multi-agent pattern (see handoff §3).
4. **Code review** at each sprint boundary — 3-agent adversarial review, auto-fire, no permission needed.

## First action (MANDATORY)

1. **Greet Alok by name.** Amelia voice — terse, file paths + AC IDs.
2. **Verify git state:** `git log --oneline -15` + `git status --short`.
3. **Verify Firebase:** `firebase functions:list --project yugma-dukaan-dev` (expect `killSwitchOnBudgetAlert` in asia-south1)
4. **Verify Sprint 0 closure:** confirm `docs/runbook/hindi_design_capacity_verification.md` exists.
5. **Read all listed artifacts.**
6. **Start Wave 0** — read the design-bundle files, produce the mapping table, present to Alok for review before launching agents.

## Binding rules (do NOT negotiate)

1. **No shortcuts, world-class quality.**
2. **Code review is integral** — auto-fire `bmad-code-review` at every sprint boundary. 3-agent parallel. No permission needed.
3. **Best UI/UX for the client** — `frontend-design-bundle` Workshop Almanac aesthetic is canonical. Port, don't redesign.
4. **Domain-aware and grounded** — `bhaiya/beta/munshi`, `shaadi/naya_ghar/dahej`, `udhaar/baaki/pakka`.
5. **Free features only** — Blaze free tier IS free. Never propose paid services.
6. **Autonomous commits at phase boundaries** — commit ≠ push. Ask before destructive git ops.
7. **Walking Skeleton ships first** (PRD Standing Rule 1).
8. **Standing Rule 11 partition discipline** — sealed Freezed patches for Project/ChatThread/UdhaarLedger.
9. **Forbidden udhaar vocabulary (ADR-010)** — never `interest / interestRate / overdueFee / dueDate / lendingTerms / borrowerObligation / defaultStatus / collectionAttempt`.
10. **Forbidden mythic vocabulary (Constraint 10)** — never `शुभ / मंदिर / धर्म / तीर्थ / आशीर्वाद / पूज्य / मंगल / स्वागतम् / उत्पाद / गुणवत्ता / श्रेष्ठ`.
11. **Constraint 4 font stack** — Tiro Devanagari Hindi + Mukta + Fraunces + EB Garamond + DM Mono ONLY.
12. **Triple Zero invariant** — `amountReceivedByShop == totalAmount` exactly at `Project.state == 'paid'`.
13. **Alok reviews Hindi strings** — he is the Hindi reviewer (END STATE A). Devanagari strings in UX are now allowed but must be reviewed by Alok in PR diffs.
14. **Always deploy Cloud Functions with `--force`** flag.

## Things previous sessions already decided — do NOT re-invent

See §4 of the handoff doc. Key items:

- `AuthCollisionException` recovery uses `e.credential` + `signInWithCredential`.
- `*.freezed.dart` / `*.g.dart` gitignored. `google-services.json` + `GoogleService-Info.plist` ARE committed.
- Canonical Firestore collections: **camelCase** (`chatThreads`, `featureFlags`, `udhaarLedger`, `customerMemory`, etc.)
- **Operator role canonical:** `bhaiya/beta/munshi`. DO NOT revert to `shopkeeper/son/munshi`.
- `build.yaml` with `explicit_to_json: true` for nested Freezed classes.
- ShopThemeTokens taglines = empty strings pending Alok-approved copy. Can now be populated.
- Kill-switch flips 7 fields (defense in depth beyond SAD §7 Function 1).
- Firestore region is asia-south1 (Mumbai). Staging/prod MUST match.
- gcloud CLI at `C:\Users\alokt\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\`.
- B1.2 uses Sunil-bhaiya's real face photo (D4 consent secured). Devanagari-initial fallback circle is the graceful degradation path.

## Persona activation

Invoke `bmad-agent-dev` skill. Verify state, read artifacts, start Wave 0. No code until design-bundle mapping is reviewed.

— End of kickoff prompt —
```

**Save the above block. Open a new Claude Code terminal session. Paste the block as the first message.**

---

## §3 — Phase 2.1 Sprint 2 + Sprint 3 execution plan (ready when Sprint 0 closes)

When Sprint 0 closes (END STATE A or B), Phase 2.1 runs the multi-agent pattern originally proposed in the outgoing session. **Theme foundation is already shipped** (Phase 2.0 Wave 1 in commit `b3071bb`) so Wave 1 is skipped. Execution shape:

### Wave 0 (NEW — mandatory) — Audit the 3 source widget files BEFORE launching agents

The outgoing session identified that launching parallel agents against the design-bundle source without first reading it was drift-prone. **Do NOT skip this audit step.**

**Files to read end-to-end (each, yourself — no subagent delegation):**

```
_bmad-output/planning-artifacts/frontend-design-bundle/lib_core/components/bharosa_landing.dart       766 lines
_bmad-output/planning-artifacts/frontend-design-bundle/lib_core/components/components_library.dart   3075 lines
_bmad-output/planning-artifacts/frontend-design-bundle/lib_core/components/invoice_template.dart      807 lines
```

**For each file, produce a mapping table:**

| Devanagari source string | English target + AppStrings key | PRD story | Notes |
|---|---|---|---|
| e.g., `'सुनील भैया का स्वागत संदेश'` | `'Sunil-bhaiya welcome message'` → `AppStrings.greetingVoiceNoteLabel` | B1.3 | Already in Phase 1.4 `strings_hi.dart` / `strings_en.dart` |

The mapping table becomes the instruction payload for Wave 2 agents. **Without it, agents will invent substitutions and drift.**

Estimated wall-clock: 45-60 min of reading + mapping.

### Wave 2 — 4 parallel widget-port agents (after Wave 0 audit)

Spawn 4 `Explore`-type subagents in parallel (or `general-purpose` if Explore is insufficient for write operations — check capability first). Each gets:

1. **Narrow file-list scope** — explicit "you touch ONLY these files" list, no overlap with sibling agents, no edits to shared files (router.dart, lib_core.dart, pubspec.yaml)
2. **The Wave 0 mapping table** as the instruction payload — agents apply substitutions from the table, not from their own invention
3. **Phase 1 commit context** — what adapters/repos/models/locale/theme exist + how to import them
4. **Strict English-only rule** — "You MUST NOT write any Devanagari glyph in any .dart file you create. Use English placeholder strings with `// TODO(sprint-0): swap to context.appStrings.xxx after I6.11 closes` markers when the AppStrings key doesn't exist yet."
5. **Forbidden vocabulary list** — ADR-010 udhaar + Constraint 10 mythic. Any leak = immediate 🔴 in Wave 4 review.
6. **Expected output format** — terse summary + files created + any design questions

**Agent scopes:**

| Agent | File scope | Stories |
|---|---|---|
| **α Bharosa** | `apps/customer_app/lib/features/bharosa_landing/` — BharosaLanding + ShopkeeperPresenceDock + D4 Devanagari-initial fallback widget + greeting voice note autoplay | B1.1, B1.2, B1.3 |
| **β Browse** | `apps/customer_app/lib/features/browse/` — CuratedShortlistCard + SkuDetailCard + GoldenHourPhotoView + VoiceNotePlayer | B1.4, B1.5 |
| **γ Chat shells** | `apps/customer_app/lib/features/chat/` — ChatBubble + HindiTextField + PersonaToggle shell (feature-flagged off) | P2.4, P2.5 scaffold |
| **δ Ops app** | `apps/shopkeeper_app/lib/features/` — auth (S4.1 Google sign-in) + todays_task (S4.13) + inventory_create shell (S4.3) | S4.1, S4.13, S4.3 |

### Wave 3 — Reconciliation (me, serial, ~45 min)

1. Read all 4 agent diffs
2. Fix convention drift (Riverpod provider patterns, import style, naming)
3. **Devanagari leak scan** (deterministic post-check): `Grep` with pattern `[\x{0900}-\x{097F}]` across `apps/customer_app/lib/features apps/shopkeeper_app/lib/features` — any hit = immediate fix before commit
4. Update `apps/customer_app/lib/routes/router.dart` with new routes behind feature flags (default keeps showing `_BootSplashScreen` until explicit flip)
5. Update `apps/shopkeeper_app/lib/routes/router.dart` similarly
6. Run `flutter analyze apps/customer_app/lib apps/shopkeeper_app/lib packages/lib_core/lib` — 0 errors
7. Run `flutter test` across all affected directories

### Wave 4 — 3-agent adversarial code review (parallel, ~40 min)

Same pattern as Phase 1.9. Three review agents:

- **Widget + state management** — Riverpod correctness, rebuild efficiency, null safety, const discipline
- **Domain grounding + forbidden vocabulary** — SAD/PRD canonical naming, zero Devanagari in widget files, zero forbidden vocab
- **Integration + theme** — widgets consume `context.yugmaTheme`, D4 fallback is the default path, no real Firestore calls in widget builds (all mocked or feature-flagged off)

### Sprint 2 completion (B1.1 + B1.2 serial)

These two stories share the `BharosaLanding` widget — **DO NOT parallelize**. B1.2 is the landing widget itself; B1.1 is the first-time-onboarding flow that consumes it. Serial execution:

1. B1.2 first — implement BharosaLanding with the D4 fallback as default (Devanagari-initial circle per the design bundle)
2. B1.1 second — wire B1.2 into the `/` route, stitch in greeting voice note autoplay (from Wave 2 agent α output), handle cold-start race conditions

Post-Sprint-2 completion — fire 3-agent code review, fix 🔴 findings, commit.

### Sprint 3 (B1.3, B1.4, B1.5, S4.1, S4.13)

With Wave 0-4 already shipping the widget scaffolds, Sprint 3 becomes:
1. Wire `routing` — route `/sku/:id` to SkuDetailCard, `/shortlist/:occasion` to CuratedShortlistCard, etc.
2. Integration tests against `fake_cloud_firestore` with real flows
3. Emulator smoke test on an Android device + verify Devanagari renders correctly
4. Post-Sprint-3 code review

---

## §4 — Known-good state + gotchas (updated)

### §4.1 — Works correctly (do NOT "fix")

All prior session's known-good items PLUS:

- **`KillSwitchListener` fail-open posture on transient errors** — deliberately does NOT fail-closed on Firestore `onSnapshot` errors. The `lastSnapshotAt` timestamp exposes cached-state age so future refinements can add a staleness check. See class doc comment in `kill_switch_listener.dart` for the 3-point rationale.

- **`ProjectRepo.applyCustomerCancelPatch` uses a Firestore transaction** — not a direct set. This verifies `state == 'draft'` server-side to prevent offline-replay past-draft cancellation.

- **`CuratedShortlistRepo.reorderSkus` rejects duplicates** — Phase 1.9 added this. Drag-to-reorder UIs can misfire and produce dupes; the repo catches it.

- **`InventorySkuRepo.getById/getByIds` returns soft-deleted SKUs by design** — dual-use contract. `customer_app` filters `.where((s) => s.isActive)` at render time per PRD B1.4 edge case #3. `shopkeeper_app` typically does not filter (needs visibility for restore/audit).

- **`VoiceNoteRepo.create` enforces duration [5, 60]** — PRD B1.6 AC #2. Defense in depth above the security rule.

- **`CommsChannelWhatsApp` rejects empty shopId AND empty projectId separately** — Phase 1.9 A4 fix. Parity with CommsChannelFirestore validation.

- **`ShopThemeTokens.sunilTradingCompanyDefault()` has EMPTY STRING taglines** — `taglineDevanagari: ''`, `taglineEnglish: ''`. **Do NOT populate these with the Sally-authored tagline** — that's app copy subject to Sprint 0 Hindi-native review. Runtime Firestore document at `/shops/sunil-trading-company/theme/current` populates them after Sprint 0 closes. The test `'sunilTradingCompanyDefault tagline is empty string pending Sprint 0 review'` in `theme_test.dart` enforces this invariant.

- **Devanagari in shop_theme_tokens defaults ARE allowed for `brandName` + `ownerName`** — these are the shop's legal identity (already in production via Sprint 1.6 `_BootSplashScreen`). NOT subject to Sprint 0 review.

- **`firestore.rules` line 50-52 now uses `bhaiya/beta/munshi`** — Phase 1.9 Agent A finding #3. Fixed the drift from `shopkeeper/son/munshi`.

- **`functions/eslint.config.js` uses ESLint v9 flat config format** (not `.eslintrc.js`). Required because ESLint 9.x dropped legacy config support.

- **`functions/package.json` requires `@eslint/js@^9.0.0`** (not `@eslint/js@10` which requires ESLint 10).

- **`build.yaml` at `packages/lib_core/` sets `explicit_to_json: true`** for json_serializable. Without this, nested Freezed classes (OperatorPermissions, SkuDimensions) pass through as raw Dart objects and fake_cloud_firestore rejects them at document validation.

- **`test/fails_to_compile/customer_app_constructs_udhaar_operator_patch.dart` does NOT import `udhaar_ledger_patch.dart`** — the absence of the import is the enforcement. An earlier version tried `show;` (empty show clause) which is invalid Dart syntax; the fix is to not import at all.

- **ChatThread + UdhaarLedger negative compilation tests shipped in Phase 1.9** — `test/fails_to_compile/customer_app_constructs_chat_thread_operator_patch.dart` + `customer_app_constructs_udhaar_operator_patch.dart`. Mirror the existing Project variant.

### §4.2 — Gotchas / open issues

- **Pre-existing 10 test failures in `test/services/phone_upgrade_coordinator_test.dart`** (Timestamp vs DateTime assertions + 1 firebase_auth_mocks assertion). Verified pre-existing via `git stash` before Phase 1.2. NOT a Phase 1 regression. Queued as Phase 1.10, multi-root-cause, 1-2 hour investigation when Alok asks for it.

- **`functions/` workspace — no `firebase-functions@latest` upgrade.** Deploy log warned: *"package.json indicates an outdated version of firebase-functions. Please upgrade using npm install --save firebase-functions@latest in your functions directory."* The current version `^6.1.0` works but a future session should consider upgrading. Breaking changes noted.

- **`functions/package-lock.json` is gitignored** (per `functions/.gitignore`) — `npm install` regenerates it on fresh checkouts. CI caches based on `functions/package.json` hash.

- **Storage not deployed to dev yet.** When B1.6 (voice notes) lands in Sprint 3, deploy `storage.rules` via `firebase deploy --only storage --project yugma-dukaan-dev` AFTER enabling Storage in Firebase Console.

- **Blaze on dev, NOT on staging or prod.** Staging + prod remain on Spark, no services enabled. See `docs/runbook/staging-setup.md` for the full bring-up procedure when Sprint 5-6 needs them.

- **Cloud Build IAM gotcha for first deploy on a fresh Blaze project.** Documented in `docs/runbook/staging-setup.md` §6.4. 4 roles needed on `{project-number}-compute@developer.gserviceaccount.com`:
  - `Cloud Build Service Account`
  - `Artifact Registry Writer`
  - `Storage Object Viewer`
  - `Logs Writer`
  - Fix via Cloud Console IAM UI OR gcloud CLI. Apply BEFORE retrying `firebase deploy --only functions`.

- **Font subset files not built yet.** `tools/generate_devanagari_subset.sh` is ready. Needs `pip install fonttools brotli zopfli` on dev env + one run. Output goes to `assets/fonts/subset/*.woff2`. Then register in `apps/*/pubspec.yaml` per `docs/runbook/font-subset-build.md`. This is Phase 1.4.1 follow-up, not urgent, needed before Sprint 2 B1.2 renders real Devanagari on-screen.

- **The Dart `cross_tenant_integrity_test.dart` uses `fake_cloud_firestore`** — which does NOT enforce security rules. That test is a SHAPE test. The REAL rules test is `tools/src/cross_tenant_integrity.test.ts` which uses `@firebase/rules-unit-testing` against the live emulator. Both run in CI. Don't conflate them.

- **Firestore region is `asia-south1` (Mumbai)** — cannot be changed after creation. Staging + prod MUST pick the same region when enabled.

- **gcloud CLI NOT installed on Alok's machine.** All gcloud-requiring operations need either a one-time gcloud install (~5 min Google Cloud SDK installer on Windows) OR Cloud Console UI clicks from Alok. Firebase CLI handles everything firebase-specific including function deploys.

- **10 commits on `origin/main` do not trigger staging deploy.** The `deploy-staging.yml` workflow is manual-trigger-only per SAD §3. Merging to main runs lint + build + test via CI but does NOT deploy to Firebase.

### §4.3 — Things the outgoing session considered but did NOT do (deliberate)

- **Did NOT push to staging or prod.** Dev is the only deploy target that's been touched.
- **Did NOT deploy Cloud Functions successfully.** First deploy attempt hit IAM wall; rolled back cleanly.
- **Did NOT install gcloud CLI.** Would have been a dev-environment modification without explicit authorization.
- **Did NOT run `melos run build_runner` as a top-level workspace command.** Did run `flutter pub run build_runner build` inside `packages/lib_core/`. Melos workspace-level build_runner would also work but wasn't exercised.
- **Did NOT fix the 10 pre-existing phone_upgrade_coordinator test failures.** Abandoned mid-investigation when Alok pivoted to "what's pending on me".
- **Did NOT port the 4,600 lines of design-bundle widgets** (bharosa_landing.dart, components_library.dart, invoice_template.dart). Phase 2.0 Wave 2-4 deferred per Option C decision.
- **Did NOT build the Devanagari font subset files.** Script is ready; needs `pip install fonttools` on dev env first.
- **Did NOT wire the Cloud Functions factories (MediaStore, CommsChannel) to consume the KillSwitchListener probes.** Adapters still default to `() => false` stubs. Wire-up happens at app bootstrap in a future sprint.

---

## §5 — Where the BMAD planning artifacts + session docs live (updated)

All in `_bmad-output/` or project root:

| File | Author | Version | What it's for |
|---|---|---|---|
| `_bmad-output/planning-artifacts/product-brief.md` | Mary (Analyst) | v1.4 | The why and what |
| `_bmad-output/planning-artifacts/solution-architecture.md` | Winston (Architect) | v1.0.4 | The how — 16 sections, 15 ADRs, 8 Cloud Functions |
| `_bmad-output/planning-artifacts/prd.md` | John (PM) | v1.0.5 | 67 stories + 11 Standing Rules |
| `_bmad-output/planning-artifacts/epics-and-stories.md` | John (CE skill) | v1.2 | Sprint plan + dependency graphs |
| `_bmad-output/planning-artifacts/ux-spec.md` | Sally (UX) | v1.1 | UX strategy + 67 state catalog + 50 voice & tone strings |
| `_bmad-output/planning-artifacts/frontend-design-bundle/README.md` | frontend-design plugin | v1.1 | Workshop Almanac design system |
| `_bmad-output/planning-artifacts/frontend-design-bundle/lib_core/theme/*.dart` | frontend-design plugin | v1.1 | Source theme files — PORTED into `packages/lib_core/lib/src/theme/` in Phase 2.0 Wave 1 |
| `_bmad-output/planning-artifacts/frontend-design-bundle/lib_core/components/*.dart` | frontend-design plugin | v1.1 | 12 widgets + invoice_template — NOT YET ported (Phase 2.1 scope) |
| `_bmad-output/planning-artifacts/implementation-readiness-report.md` | John (IR skill) | v1.2 | Post-back-fill validation |
| `_bmad-output/planning-artifacts/shopkeeper-onboarding-playbook.md` | John + Alok | v1.0 | Day 0–30 ramp |
| `_bmad-output/planning-artifacts/sprint-0-i6-11-checklist.md` | Amelia | v1.0 | Hindi-capacity gate governance |
| `_bmad-output/planning-artifacts/sprint-0-execution-kit.md` | Amelia | v1.0 | Outreach templates + vetting protocol |
| `_bmad-output/planning-artifacts/session-handoff-sprint-2-complete.md` | Amelia | v1.0 | PRIOR session handoff (historical reference) |
| `_bmad-output/planning-artifacts/session-handoff-phase-2-ready.md` | Amelia | v1.0 | **THIS document** |
| `_bmad-output/implementation-artifacts/sprint-status.yaml` | Amelia via bmad-sprint-planning skill | v1.0 | Canonical BMAD tracker — 67 stories with current status |
| `CONTRIBUTING.md` | Amelia | v1.0 | Project root — Standing Rule 11 + forbidden vocab + free-features + monorepo workflow |
| `packages/lib_core/README.md` | Amelia | v1.0 | Library structure + Three Adapters table + partition discipline summary |
| `docs/runbook/staging-setup.md` | Amelia | v1.1 (post-I6.8 rollback) | 9-step staging bring-up + Cloud Build IAM pre-fix §6.4 |
| `docs/runbook/font-subset-build.md` | Amelia | v1.0 | Devanagari font subset pipeline + one-time setup |

---

## §6 — How to run things (cheat sheet for the new session)

```bash
# Project root
cd "C:\Alok\Business Projects\Almira-Project"

# Git state
git status --short
git log --oneline -15

# Firebase state
firebase projects:list | grep yugma-dukaan
firebase use  # shows active alias
firebase use dev  # switch to yugma-dukaan-dev
firebase functions:list --project yugma-dukaan-dev  # expect: No functions found

# Flutter tooling
flutter --version  # expect 3.32.4 stable
dart --version     # expect 3.8.1

# Melos workspace (Dart side)
melos bootstrap           # wire lib_core into apps
melos run build_runner    # generate *.freezed.dart / *.g.dart
melos run analyze         # static analysis across all packages
melos run test            # unit tests across lib_core + apps
melos run test:cross-tenant  # Dart shape test

# OR run build_runner directly on lib_core
cd packages/lib_core
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test

# Cloud Functions workspace
cd functions
npm install
npm run lint   # eslint flat v9 config
npm run build  # tsc → lib/
npm test       # jest (10 kill_switch tests)

# Deploy Cloud Functions (AFTER Cloud Build IAM fix per staging-setup.md §6.4)
cd "C:\Alok\Business Projects\Almira-Project"
firebase deploy --only functions --force --project yugma-dukaan-dev

# Rollback a function if needed
firebase functions:delete killSwitchOnBudgetAlert \
  --project yugma-dukaan-dev --region asia-south1 --force

# Sanity test kill-switch function (AFTER deploy + Pub/Sub topic creation)
# Note: requires gcloud CLI which is NOT installed on Alok's machine
# Alternative: publish via Cloud Console UI at
#   https://console.cloud.google.com/cloudpubsub/topic/list?project=yugma-dukaan-dev
gcloud pubsub topics publish budget-alerts \
  --project=yugma-dukaan-dev \
  --message='{"budgetDisplayName":"sanity-test","costAmount":0.3,"budgetAmount":1.0,"currencyCode":"USD"}'

# Check function logs
firebase functions:log --project yugma-dukaan-dev --only killSwitchOnBudgetAlert

# TS rules test (real emulator)
cd tools
npm ci
npm run build
# In another terminal: firebase emulators:start --only firestore,auth --project yugma-dukaan-rules-test
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 GCLOUD_PROJECT=yugma-dukaan-rules-test npm run test:rules

# Deploy rules to dev (already done in Sprint 1.4, only needed on rule changes)
cd "C:\Alok\Business Projects\Almira-Project"
firebase deploy --only firestore:rules,firestore:indexes --project yugma-dukaan-dev

# Run customer app against dev Firebase
cd apps/customer_app
flutter run

# Run shopkeeper app against dev Firebase
cd ../shopkeeper_app
flutter run
```

---

## §7 — Pending on Alok (the "what's pending on me" list)

In priority order:

### 🔴 Hard blockers

1. **Sprint 0 I6.11 Hindi-capacity gate.** Still open. Execute Option B outreach per `sprint-0-execution-kit.md` §2 Tier-1 (NID alumni with UP roots, BHU Faculty of Visual Arts, Banaras Hindu University, Dainik Jagran Lucknow desk, personal network from eastern UP), OR flip `defaultLocale` to `"en"` across all 3 Firebase projects for END STATE B + notify Sunil-bhaiya in person. **This is the ONLY thing standing between Alok and Phase 2.1 widget port.**

### 🟠 Deploy-retry blockers

2. **Cloud Build IAM fix on `yugma-dukaan-dev`.** Per `docs/runbook/staging-setup.md` §6.4. Either:
   - Cloud Console IAM UI — add 4 roles to `{project-number}-compute@developer.gserviceaccount.com`: Cloud Build Service Account, Artifact Registry Writer, Storage Object Viewer, Logs Writer
   - OR install gcloud CLI and the next session automates it
   - Then: tell the next Amelia "retry I6.8 deploy" and she runs `firebase deploy --only functions --force --project yugma-dukaan-dev`

3. **D4 face photo consent.** Soft blocker for Sprint 3 B1.2. You already answered "defer, block only B1.2" — B1.2 ships with Devanagari-initial fallback. Before Sprint 3 closes, decide: real photo + written consent OR fallback forever.

### 🟡 Future-sprint horizon

4. **Cloud Storage enable on `yugma-dukaan-dev`.** Single Firebase console click. Needed before B1.3 voice note playback in Sprint 3. See staging-setup §5.

5. **Staging + prod Blaze upgrades + services.** Sprint 5-6 horizon. Full runbook in `docs/runbook/staging-setup.md` §1-8.

6. **Shop #2 outreach.** Month 2 calendar item per Brief §12 Step 0.8. You own it, 20% weekly time.

### 🟡 Pending me (standby work for Alok-idle windows)

- **Phase 1.10 — fix 10 pre-existing `phone_upgrade_coordinator_test` failures.** Multi-root-cause, 1-2 hour investigation. Pre-existing debt, NOT a Phase 1 regression.
- **Phase 2.x Cloud Functions cluster** (if I6.8 deploy is unblocked):
  - `generateWaMeLink` (SAD §7 Function 2, companion to I6.5)
  - `multiTenantAuditJob` (SAD §7 Function 4, R9 sentinel, daily schedule)
  - `firebasePhoneAuthQuotaMonitor` (SAD §7 Function 5, R8)
  - `sendUdhaarReminder` (SAD §7 Function 3, Sprint 5 with RBI guardrails)
  - `joinDecisionCircle` (SAD §7 Function 6, Sprint 4)
  - `mediaCostMonitor` (SAD §7 Function 7, Sprint 5 S4.16)
  - `shopDeactivationSweep` (SAD §7 Function 8, Sprint 6 DPDP)
- **Phase 2.1 Wave 0 audit** (if Sprint 0 is close to closing) — read the 3 source widget files and produce the mapping table so Phase 2.1 can launch Wave 2 agents immediately on Sprint 0 close.

---

## §8 — Final notes from the outgoing session

- **Alok prefers terse interaction** — file paths, story IDs, AC numbers over prose.
- **Alok has "will go with your recommendation" as a common delegation pattern** — make confident recommendations, don't hedge. But BE HONEST about trade-offs; a glossed trade-off earned a "did you check the trade-off" challenge this session.
- **Alok caught the outgoing session twice for rushing + once for glossing trade-offs.** Quality over speed, domain-aware, free features only, best UI/UX — these are non-negotiable.
- **Autonomous commits at phase boundaries** — don't ask for per-phase approval. Commit ≠ push. Push requires explicit authorization.
- **Alok moved dev project to Blaze + set email budget alerts in this session** — a real forward-motion step on the infrastructure side. The killSwitchOnBudgetAlert function code is ready to deploy as soon as the Cloud Build IAM fix lands.
- **The 6 memory files now encode Alok's full collaboration profile** — quality over speed, review is integral, best UI/UX, domain-aware, free features only, autonomous commits. Every future decision passes through these 6 lenses.
- **Cost concern from this session is intact:** Triple Zero means `$0.00/month at one-shop scale`, not "free tier with usage fees". I was imprecise earlier saying "billed if used" — the accurate framing is "at realistic usage, we never exceed free tier, so $0.00." Lead with that framing going forward.
- **The I6.8 deploy failure is a valuable learning** — it documented the Cloud Build IAM gotcha in the runbook. Staging + prod deploys will skip the debugging step because of this.
- **Sprint 0 is still the hard blocker.** The outgoing session resisted every temptation to start Phase 2.1 without it. Maintain that discipline.

Good luck. The foundation is solid + tested + reviewed + documented + cost-verified. The next session has everything it needs to ship Sprint 2 completion + Sprint 3 widget port the moment Sprint 0 closes.

— Amelia, 2026-04-11 (Phase 1 + Phase 2.0 Wave 1 + I6.8 code complete)
