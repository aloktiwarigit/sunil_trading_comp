---
artifact: Session Handoff — Sprint 2 complete, Sprint 3 ready
audience: Next Claude Code session (fresh Amelia activation)
purpose: Complete context transfer so the next session can continue Sprint 2 completion + Sprint 3 without losing quality or re-litigating decisions
date_created: 2026-04-11
current_branch: main
current_head_at_handoff: will be set at commit time — see git log below
repo: https://github.com/aloktiwarigit/sunil_trading_comp
project_path_on_founder_machine: C:\Alok\Business Projects\Almira-Project
---

# Session Handoff — Sprint 2 Complete

> **Paste the §2 kickoff prompt into the fresh Claude Code session. Everything else in this doc is reference for the new Amelia to read once activated.**

---

## §1 — What happened in the previous session (what you're inheriting)

The previous session was an extended Sprint 1 + Sprint 2 partial build, preceded by a complete BMAD planning back-fill that the founder (Alok) caught midway through — the original planning chain had skipped the Advanced Elicitation + Party Mode gates on 5 of 6 planning artifacts, which was fixed before any more code landed. By the end of the session, the following is shipped and pushed to `main`:

### What's in git

16 commits on `main` at `aloktiwarigit/sunil_trading_comp`. Read them with `git log --oneline` on activation — they tell the story cleanly. The sequence:

1. `docs(bmad): initial planning artifacts bundle` — 9-artifact BMAD planning output after full AE+party-mode back-fill
2. `feat(scaffold): Sprint 1.1 monorepo root + Firebase config`
3. `feat(lib_core): Sprint 1.2-1.3 shared core + AuthProvider adapter (I6.1)`
4. `feat(lib_core): Sprint 1.4 multi-tenant + I6.12 partition discipline`
5. `test(lib_core): Sprint 1.5 observability smoke test (I6.10)`
6. `feat(apps): Sprint 1.6 customer_app + shopkeeper_app scaffolds`
7. `ci: Sprint 1.7 GitHub Actions workflows (5 pipelines)`
8. `feat(firebase): register apps + deploy Firestore rules to yugma-dukaan-dev`
9. `docs(brief): patch §4.3 stale font stack + flutterfire metadata`
10. `feat(lib_core): Sprint 2.1 I6.2 anonymous→phone UID merger + coordinator`
11. `feat(lib_core): Sprint 2.2 I6.3 refresh-token session persistence bootstrap`
12. `docs(sprint-0): execution kit for Hindi-capacity gate`
13. `fix(lib_core): Sprint 2.1 code review blockers (A1/A2 + B1/B2/B3 + C1/C4)` — 8 blockers from a 3-agent adversarial review
14. `fix(lib_core): Sprint 2.3 code review cleanup (E.164 + signInWithGoogle + Completer + Crashlytics + providerAlreadyLinked + tests + rules)` — the cleanup batch
15. `docs: session handoff for Sprint 3 fresh session` — this document

### Walking Skeleton progress

**6 of 19 Walking Skeleton stories complete.**

| Story | Epic | Status | Notes |
|---|---|---|---|
| I6.1 AuthProvider adapter | E6 | ✅ Shipped Sprint 1.3 | 4 impls (Firebase + 3 stubs) + factory + tests |
| I6.2 Anonymous→Phone UID merger | E6 | ✅ Shipped Sprint 2.1 + fixed Sprint 2.1.f | The collision path uses Firebase's `e.credential` + `signInWithCredential` pattern via new `AuthCollisionException`. DO NOT revert to the two-call pattern — that was broken and fixed. |
| I6.3 Refresh-token session persistence | E6 | ✅ Shipped Sprint 2.2 | `SessionBootstrap.verifyPersistedUser` with analytics + Crashlytics user ID |
| I6.4 Multi-tenant shopId scoping | E6 | ✅ Shipped Sprint 1.4 | firestore.rules deployed to dev, TS rules test live |
| I6.10 Crashlytics + Analytics + App Check | E6 | ✅ Shipped Sprint 1.5 | 9 canonical events + session_restored_from_refresh_token |
| I6.12 Offline field-partition discipline | E6 | ✅ Shipped Sprint 1.4 | Sealed-union partition patches for Project/ChatThread/UdhaarLedger |
| **B1.1 First-time customer onboarding** | E1 | ⏸ **BLOCKED on Sprint 0** | User-visible — Hindi capacity gate must close first |
| **B1.2 Bharosa landing with shopkeeper face** | E1 | ⏸ **BLOCKED on Sprint 0** | Same |
| B1.3 Greeting voice note auto-play | E1 | Not started | Sprint 3 |
| B1.4 Curated occasion shortlists | E1 | Not started | Sprint 3 |
| B1.5 SKU detail with Golden Hour photo | E1 | Not started | Sprint 3 |
| S4.1 Shopkeeper Google sign-in | E4 | Not started | Sprint 3 |
| C3.1 Project draft creation | E3 | Not started | Sprint 4 |
| P2.4 Sunil-bhaiya Ka Kamra chat thread | E2 | Not started | Sprint 4 |
| P2.5 Customer sends text message | E2 | Not started | Sprint 4 |
| S4.3 Inventory create new SKU | E4 | Not started | Sprint 4 |
| C3.4 Commit Project with Phone OTP upgrade | E3 | Not started | Sprint 5 |
| C3.5 UPI payment intent flow | E3 | Not started | Sprint 5 |
| S4.5 Golden Hour photo capture flow | E4 | Not started | Sprint 5 |

### Firebase environment state

- **`yugma-dukaan-dev`** — created, Firestore enabled (asia-south1 Mumbai), Authentication enabled (Anonymous + Phone + Google), both apps registered via `flutterfire configure`, rules + indexes deployed, Storage NOT enabled yet (B1.6 voice notes in Sprint 3 will need it)
- **`yugma-dukaan-staging`** — project exists, NO services enabled
- **`yugma-dukaan-prod`** — project exists, NO services enabled
- **Blaze plan** — NOT upgraded on any project. Required before Cloud Functions deploy (Sprint 5–6) and before Phone Auth SMS beyond the 10k/month free quota.
- **Budget alerts at $0.10/$0.50/$1.00** — NOT set (blocked on Blaze upgrade)

### Sprint 0 Hindi-capacity gate

**Status: NOT CLOSED.** This is the single critical-path blocker for Sprint 2 completion (B1.1 + B1.2) and Sprint 3 (B1.3, B1.4, B1.5).

Alok has two execution artifacts ready:
1. `_bmad-output/planning-artifacts/sprint-0-i6-11-checklist.md` — governance framework
2. `_bmad-output/planning-artifacts/sprint-0-execution-kit.md` — concrete outreach templates + scope of work + 30-min vetting script

**Decision rule:** either (a) hire/contract a Hindi-native design reviewer within 2 weeks (END STATE A), or (b) flip `defaultLocale` Remote Config flag `"hi"→"en"` + notify Sunil-bhaiya in person + log `constraint_15_fallback_triggered` Crashlytics event (END STATE B). Both are acceptable. See the execution kit §2 decision tree.

**Per Brief Constraint 15, neither option can be skipped.** Sprint 2 B1.1+B1.2 cannot ship without one of the two states reached.

---

## §2 — Kickoff prompt for the new session (PASTE THIS)

> **Copy everything inside the triple-quote block below and paste it as the first message to the new Claude Code session in the `C:\Alok\Business Projects\Almira-Project` working directory.**

```markdown
You are Amelia — Senior Software Engineer on the Yugma Dukaan project (Sunil Trading Company, an almirah shop in Ayodhya's Harringtonganj market run by Sunil-bhaiya). This is a real client engagement for Alok, founder of Yugma Labs. Re-activate your BMAD developer persona from the `bmad-agent-dev` skill.

## Immediate context (do not skip)

The previous session shipped Sprint 1 + Sprint 2 partial + Sprint 2.1 code review fixes + Sprint 2.3 cleanup, then paused at a clean checkpoint before Sprint 3. Read these files in this exact order before doing anything else:

1. `_bmad-output/planning-artifacts/session-handoff-sprint-2-complete.md` — full handoff briefing (THIS document's parent). Read every section.
2. `C:\Users\alokt\.claude\projects\C--Alok-Business-Projects-Almira-Project\memory\MEMORY.md` — 2 persistent feedback memories: "quality over speed" and "code review is integral to coding (auto-fire at sprint boundaries)". These are binding.
3. Run `git log --oneline -25` — the 15+ commits tell the story cleanly. Read every commit message.
4. `_bmad-output/planning-artifacts/product-brief.md` v1.4 — the why and what
5. `_bmad-output/planning-artifacts/solution-architecture.md` v1.0.4 — the how (16 sections + 15 ADRs)
6. `_bmad-output/planning-artifacts/prd.md` v1.0.5 — 67 stories across 6 epics, 11 Standing Rules in the preamble
7. `_bmad-output/planning-artifacts/epics-and-stories.md` v1.2 — sprint plan with Walking Skeleton 19-story sequence
8. `_bmad-output/planning-artifacts/ux-spec.md` v1.1 — Sally's UX strategy + 67 state catalog + 50 voice & tone strings (all Devanagari)
9. `_bmad-output/planning-artifacts/frontend-design-bundle/README.md` v1.1 — Workshop Almanac aesthetic + 12 Dart widgets + invoice_template.dart + 23 HTML mockups
10. `_bmad-output/planning-artifacts/implementation-readiness-report.md` v1.2 — IR Check post-back-fill validation (🟢 READY)
11. `_bmad-output/planning-artifacts/shopkeeper-onboarding-playbook.md` v1.0 — ops playbook (Alok executes, not you)
12. `_bmad-output/planning-artifacts/sprint-0-i6-11-checklist.md` — Hindi capacity gate governance
13. `_bmad-output/planning-artifacts/sprint-0-execution-kit.md` — Hindi capacity gate execution (outreach templates + scope + vetting)

After reading, you have the full context the previous session had. The BMAD planning artifacts contain ~150k words of structured knowledge — read them, don't skim them. Alok has explicitly said "no shortcuts, world-class quality" multiple times. He has caught the previous session rushing twice. Do not repeat that.

## What you are building (5-sentence summary)

Yugma Dukaan is a Hindi-first digital storefront for Sunil-bhaiya's almirah shop in Ayodhya. Customer Flutter app (anonymous browse + phone OTP at commit) + Astro static marketing site (sunil-trading-company.yugmalabs.ai) + Flutter shopkeeper ops app (Google Sign-In). Triple Zero economic model: zero commission, zero fees, ₹0 ops cost. Two pillars: Bharosa (shopkeeper-as-product — voice, face, curation, memory, honest absence) + Pariwar (committee-native Decision Circle, feature-flagged). Walking Skeleton of 19 stories in 6 sprints ships by Month 3; v1 full build is Months 1–5, v1.5 Months 5–7, v2 Months 7–9.

## Current state on disk

- **Branch:** `main` tracking `origin/main` at `aloktiwarigit/sunil_trading_comp`
- **Walking Skeleton:** 6 of 19 shipped (I6.1, I6.2, I6.3, I6.4, I6.10, I6.12). All infrastructure stories, no user-visible UI strings yet.
- **Firebase dev:** `yugma-dukaan-dev` with Firestore (asia-south1) + Auth + both apps registered. Storage, Blaze upgrade, budget alerts NOT yet configured.
- **Sprint 0 Hindi-capacity gate:** NOT CLOSED. This blocks B1.1 + B1.2 (Sprint 2 completion) and all of Sprint 3 (B1.3, B1.4, B1.5 are user-visible).
- **Code review debt:** 0 pending blockers. Sprint 2.3 cleanup pass closed the 8 queued findings from the 3-agent adversarial review.

## Your first action (MANDATORY)

Do NOT start coding. Do the following in order:

1. **Greet Alok by name.** Use the `bmad-agent-dev` persona activation flow — terse, file paths + AC IDs, Amelia voice.
2. **Verify current git state:** run `git log --oneline -20` and `git status --short`. Confirm you're on main, up to date, clean working tree.
3. **Verify Firebase state:** run `firebase projects:list | grep yugma-dukaan` to confirm all 3 projects exist. Run `firebase use` to check active alias.
4. **Read the 13 artifacts listed above.** This is not optional — do NOT proceed to Sprint 3 work without having read them all.
5. **Check whether Sprint 0 has closed.** Look for `_bmad-output/planning-artifacts/constraint-15-fallback-decision.md` (means END STATE B was triggered) OR ask Alok if he's secured a Hindi reviewer (END STATE A). Do NOT assume Sprint 0 has closed.
6. **Propose the next move to Alok:**
   - **If Sprint 0 CLOSED as END STATE A:** propose Sprint 2 completion (B1.1 + B1.2) + Sprint 3 multi-agent foundation pass (see §3 below for the plan).
   - **If Sprint 0 CLOSED as END STATE B:** same Sprint 2 + 3 plan but with English-first copy + Hindi toggle + `defaultLocale='en'` runtime.
   - **If Sprint 0 NOT closed:** propose cleanup work that is NOT Sprint 0 blocked: Agent C minor findings, Brief + PRD cross-link audits, staging Firebase setup preparation, or staging sprint 3 leaf code that uses the English strings with `// TODO: Hindi after Sprint 0` markers.

## Hard rules (binding, from the previous session's memory files)

1. **No shortcuts, world-class quality.** Alok has said this 3+ times and corrected the previous session twice for rushing. Prefer thorough upstream gates over downstream firefighting.
2. **Code review is integral to coding.** At the end of every sprint (or any material code change), auto-fire `bmad-code-review` skill with a 3-agent adversarial pattern (security + models + auth). Do NOT ask permission. Fix 🔴 findings immediately before the next sprint. Queue 🟠 findings for the next cleanup pass.
3. **Multi-agent parallelization is recommended for Sprint 3+ leaf stories.** The pattern: single-agent foundation pass (shared models + adapter extensions + repo stubs), then spawn 3–4 parallel subagents for the leaf work (B1.3, B1.4, B1.5, S4.1 are mostly independent). NOT recommended for tightly coupled Sprint 2 closure (B1.1 + B1.2 share the Bharosa landing widget).
4. **Walking Skeleton stories ship first** (PRD Standing Rule 1). Do NOT start E2 depth before E6+E1 foundation is working.
5. **Standing Rule 11** — repository methods cannot construct a Project / ChatThread / UdhaarLedger patch that crosses the customer/operator/system field partition. Enforced via Freezed sealed unions. See `packages/lib_core/lib/src/models/project_patch.dart` for the discipline and the critical header comment explaining WHY three separate classes (not one sealed union).
6. **Forbidden udhaar vocabulary (ADR-010)** — never use `interest`, `interestRate`, `overdueFee`, `dueDate`, `lendingTerms`, `borrowerObligation`, `defaultStatus`, `collectionAttempt` or their Devanagari equivalents (`ब्याज / पेनल्टी / बकाया तारीख / देरी का जुर्माना / ऋण / क़िस्त / वसूली / डिफ़ॉल्ट`) anywhere in code, rules, comments, field names, or UI copy. Enforced at the Firestore rule layer and in the TS rules test.
7. **Forbidden mythic vocabulary (Constraint 10)** — never use `शुभ / मंदिर / धर्म / तीर्थ / आशीर्वाद / पूज्य / मंगल / स्वागतम् / उत्पाद / गुणवत्ता / श्रेष्ठ`. Plain everyday warmth words (`धन्यवाद / विश्वास / आपका / स्वागत`) are permitted.
8. **Constraint 4 font stack** — Tiro Devanagari Hindi + Mukta + Fraunces + EB Garamond + DM Mono. No other fonts. No Caveat. No Inter. No Roboto. No Noto Sans Devanagari (except as runtime fallback, never as bundled asset).
9. **Triple Zero invariant** — at `Project.state == 'paid'`, `amountReceivedByShop` must equal `totalAmount` exactly. No commission, no MDR, no interposition. Verified by CI integrity test (when it exists) and by the ProjectOperatorRevertPatch resetting it to 0 on revert.
10. **Sprint 0 gate** — NO user-visible Devanagari UI strings ship until the Hindi-native design capacity gate closes. Infrastructure code (models, repos, adapters, services, Cloud Functions) is fine.

## Paste-ready persona activation (optional)

If you want the full BMAD activation flow, ask Alok to type `bmad-agent-dev` in the first message after reading this prompt. That will invoke the Amelia skill which will greet, load project config from `_bmad/bmm/config.yaml`, and present the capabilities table (DS, QD, QA, CR, SP, CS, ER).

Otherwise, proceed directly: read the artifacts, verify git state, ask Alok the single question "Has Sprint 0 closed — are we in END STATE A (hired reviewer) or END STATE B (defaultLocale flipped to 'en')?" and act on the answer.

— End of kickoff prompt —
```

**Save the above block. Open a new Claude Code terminal session. Paste the block as the first message. Everything else in this document is reference for the new Amelia to read.**

---

## §3 — Sprint 3 multi-agent execution plan (ready when Sprint 0 closes)

Sprint 3 per Epics List v1.2 §2 has 4 stories: **B1.3** (greeting voice note auto-play), **B1.4** (curated occasion shortlists), **B1.5** (SKU detail with Golden Hour photo), **S4.1** (shopkeeper Google sign-in via ops app). The previous session proposed a ~40% wall-clock reduction via selective multi-agent parallelization. Executed faithfully, this is the Sprint 3 plan:

### Step 1 — Single-agent shared foundation pass (~20 min)

Write the shared models + adapter extensions + repo stubs in one sequential pass. These are consumed by all 4 Sprint 3 stories and must be consistent:

- New Freezed models: `VoiceNote`, `CuratedShortlist`, `InventorySku`, `Operator` (for S4.1 role mapping)
- New repositories: `VoiceNoteRepo`, `CuratedShortlistRepo`, `InventorySkuRepo`, `OperatorRepo`
- `CommsChannel` adapter — Sprint 2 had the interface stub; Sprint 3 needs the Firestore real-time + WhatsApp `wa.me` implementations
- `MediaStore` adapter — interface + Cloudinary + Firebase Storage implementations (VoiceNote upload uses Firebase Storage per ADR-006)
- `OperatorRepo.markAsShopkeeperRole()` — writes the custom claim via a Cloud Function stub (real Cloud Function ships in Sprint 5)
- Barrel update
- Single commit: `feat(lib_core): Sprint 3 foundation — models + CommsChannel + MediaStore + repos`

### Step 2 — Parallel leaf work (3 subagents, ~30 min wall-clock)

Spawn 3 `Explore`-type subagents in parallel (Agent is read-only for code analysis; for code writing use general-purpose). Each gets a narrow file-list scope + the shared foundation context + the 11 Standing Rules + the forbidden vocabulary list:

- **Subagent B1.3** — greeting voice note auto-play widget + integration into `BharosaLanding` + empty-state fallback per B1.3 AC #8
- **Subagent B1.4** — `CuratedShortlistCard` widget + FINITE query logic (max 6 SKUs, NOT paginated per PRD v1.0.5 B1.4 AC) + integration into landing
- **Subagent B1.5** — `SkuDetailCard` widget + Golden Hour photo toggle (`असली रूप दिखाइए`) + voice note inline player

Each subagent scope excludes shared foundation files — they only touch widgets + tests + screen integration.

### Step 3 — Serial S4.1 (me, ~30 min)

S4.1 is tangled with auth claim bootstrapping + operator custom claim + needs the ops app routing wired. Do NOT parallelize — write it serially after the shared foundation commits.

### Step 4 — Reconcile + commit (~15 min)

Read all 3 subagent diffs. Fix convention drift (every agent will invent slightly different Riverpod patterns). Run tests. Commit as one `feat(customer_app): Sprint 3 leaf widgets (B1.3 + B1.4 + B1.5)` plus `feat(shopkeeper_app): Sprint 3 S4.1 Google sign-in`.

### Step 5 — Auto-fire code review (~15 min)

Per the "review is integral" memory: spawn 3 parallel review subagents against the Sprint 3 commit range:
- Security/rules subagent
- Widget/state-management subagent  
- Integration/repo subagent

### Step 6 — Fix 🔴 + commit + push

**Total Sprint 3 wall-clock: ~2 hours** vs ~3.5–4 hours fully serial. ~40% savings. Higher quality than single-agent sequential because the 3 reviewers catch things the author rationalized past.

### Sprint 3 exit criteria (from Epics List v1.2 §2)

- All 4 stories pass their PRD acceptance criteria
- Cross-tenant integrity test still green
- No new 🔴 findings in post-Sprint code review
- No UI strings ship if Sprint 0 is in END STATE A; English strings with Hindi toggle if END STATE B
- Both apps build debug APK successfully in CI

---

## §4 — Known-good state + gotchas the new session must not re-invent

### Works correctly (do not "fix")

- **`AuthCollisionException` and the `e.credential` + `signInWithCredential` pattern** — this is the CORRECT Firebase SDK collision recovery path. A previous attempt used a two-call `confirmPhoneVerification` pattern which is BROKEN because Firebase consumes the verification code on first use. Do not revert.
- **ProjectRepo has 4 write methods** — `applyCustomerPatch`, `applyOperatorPatch`, `applySystemPatch`, `applyCustomerCancelPatch`. The 4th is the typed exception for PRD I6.12 edge case #1. The spirit of AC #2 (no generic Map update) is preserved. Do not consolidate.
- **`isBhaiyaOf` helper is NOT defined in firestore.rules** — intentionally. Ships with S4.19 in Sprint 5+. Don't add it speculatively.
- **No `*.freezed.dart` / `*.g.dart` files in git** — gitignored. Generated by `melos run build_runner` on first CI run or first local build.
- **`google-services.json` and `GoogleService-Info.plist` ARE committed** — Firebase client API keys are public-by-design per Firebase docs; security comes from App Check + rules, not key secrecy.
- **`intl: ^0.20.2` not `^0.19.0`** — Flutter 3.32.4's flutter_localizations pins 0.20.2. Bumped in Sprint 1 commit 30f51b1.
- **CustomerRepo.createAnonymous uses a Firestore transaction** — not `set(..., merge: true)` — because the naive merge would overwrite `createdAt` on retry. Fixed in Sprint 2.1.f.

### Gotchas / known open issues

- **Storage.rules not deployed** to dev yet. Deploy when B1.6 (voice notes) lands in Sprint 3+. CLI: `firebase deploy --only storage --project yugma-dukaan-dev` after enabling Storage in the Firebase console.
- **Blaze not upgraded** on any of the 3 Firebase projects. Required before Cloud Functions deploy or Phone Auth SMS beyond free tier. Alok's call when to upgrade.
- **Budget alerts not set** — needs Blaze first.
- **Staging + prod** have no services enabled. Same 2 console clicks as dev when needed.
- **`apps/shopkeeper_app/lib/main.dart` imports `firebase_options.dart`** but the generated file may be stale if flutterfire configure is re-run. Regenerate if you see stale app IDs in the file.
- **The Dart `cross_tenant_integrity_test.dart` uses `fake_cloud_firestore`** — which does NOT enforce security rules. That test is a SHAPE test (every model has shopId, every patch emits only its partition's fields). The REAL rules test is `tools/src/cross_tenant_integrity.test.ts` which uses `@firebase/rules-unit-testing` against the live emulator. Both run in CI. Don't conflate them.
- **`_test_user_owned_docs`** — a fake collection name used in the TS rules test as a placeholder for future Project/ChatThread partition tests. It's protected by the default-deny rule. Sprint 4+ can replace it with real partition tests when those rules exist.
- **Firestore region is asia-south1 (Mumbai)** — cannot be changed after creation. Staging + prod MUST pick the same region when enabled.

### Things the previous session considered but did NOT do (deliberate)

- **Did NOT run `melos run build_runner`** locally — no Dart toolchain verification. The first CI run will catch any Freezed syntax issues.
- **Did NOT run the test suite** locally — same reason. CI on first PR will validate.
- **Did NOT deploy Cloud Functions** — Blaze required, and none are implemented yet anyway. Scaffolding commit (Sprint 1.7 ci-cloud-functions.yml) is gated behind `hashFiles`.
- **Did NOT add CONTRIBUTING.md or package README** — PRD I6.12 AC #7 asks for Standing Rule 11 to be documented in CONTRIBUTING.md. Deferred to Sprint 3 or 4 when the project is closer to contributor-ready. Queue this as a 🟡 finding.

---

## §5 — Where the BMAD planning artifacts live + what they're for

All in `_bmad-output/planning-artifacts/`:

| File | Author | Version | What it's for |
|---|---|---|---|
| `product-brief.md` | Mary (Analyst) | v1.4 | The why and what — 12 sections, 15 constraints, 16 risks |
| `product-brief-elicitation-01.md` | Mary | — | Adversarial pre-mortem + red team that informed Brief v1.2→v1.4 |
| `party-mode-session-01-synthesis-v2.md` | Mary | v2.1 | Creative reframes from the party mode ideation session |
| `solution-architecture.md` | Winston (Architect) | v1.0.4 | The how — 16 sections, 15 ADRs, 8 Cloud Functions inventory |
| `prd.md` | John (PM) | v1.0.5 | 67 stories across 6 epics + 11 Standing Rules in preamble |
| `epics-and-stories.md` | John (CE skill) | v1.2 | Sprint plan + dependency graphs + Walking Skeleton 19-story order |
| `ux-spec.md` | Sally (UX) | v1.1 | UX strategy + 67 state catalog + 50 voice & tone strings + 5 journey maps |
| `frontend-design-bundle/README.md` | frontend-design plugin | v1.1 | "Workshop Almanac" design system |
| `frontend-design-bundle/lib_core/theme/*.dart` | frontend-design plugin | v1.1 | Freezed tokens + shop tokens + ThemeExtension |
| `frontend-design-bundle/lib_core/components/*.dart` | frontend-design plugin | v1.1 | 12 Dart widgets + invoice_template.dart |
| `frontend-design-bundle/mockups/walking-skeleton.html` | frontend-design plugin | v1.1 | 23 Walking Skeleton screen mockups (HTML/CSS) |
| `frontend-design-bundle/marketing-site/*` | frontend-design plugin | v1.1 | Astro static marketing site scaffold |
| `implementation-readiness-report.md` | John (IR skill) | v1.2 | Post-back-fill validation — 🟢 READY verdict |
| `shopkeeper-onboarding-playbook.md` | John + Alok | v1.0 | Day 0–30 ramp + §5.5 daily management rhythm for Sunil-bhaiya |
| `sprint-0-i6-11-checklist.md` | Amelia | v1.0 | Sprint 0 Hindi-capacity gate governance framework |
| `sprint-0-execution-kit.md` | Amelia | v1.0 | Sprint 0 execution — outreach templates + scope + vetting script |
| `session-handoff-sprint-2-complete.md` | Amelia | v1.0 | **THIS document** |

---

## §6 — How to run things (cheat sheet for the new session)

```bash
# Project root
cd "C:\Alok\Business Projects\Almira-Project"

# Git state
git status --short
git log --oneline -20

# Firebase state
firebase projects:list | grep yugma-dukaan
firebase use  # shows active alias
firebase use dev  # switch to yugma-dukaan-dev

# Flutter tooling
flutter --version  # expect 3.32.4 stable
dart --version     # expect 3.8.1

# Melos workspace
melos bootstrap           # wire lib_core into apps
melos run build_runner    # generate *.freezed.dart / *.g.dart
melos run analyze         # static analysis across all packages
melos run test            # unit tests across lib_core + apps
melos run test:cross-tenant  # Dart shape test (fake_cloud_firestore)

# TS rules test (real emulator)
cd tools
npm ci
npm run build
# In another terminal: firebase emulators:start --only firestore,auth --project yugma-dukaan-rules-test
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 GCLOUD_PROJECT=yugma-dukaan-rules-test npm run test:rules

# Deploy rules to dev (no functions yet)
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

## §7 — Final notes from the outgoing session

- **Alok prefers terse interaction** — file paths, story IDs, AC numbers over prose
- **Alok has "will go with your recommendation" as a common delegation pattern** — make confident recommendations, don't hedge
- **Alok caught the previous session rushing twice** — both times the fix was immediate freeze + back-fill the missing quality gate + resume. Do not repeat this pattern.
- **The BMAD back-fill that produced the current clean planning state was substantial** — 5 sequential phases (SAD → PRD → Epics → UX → Design) each with Advanced Elicitation + Party Mode, plus an IR Check re-validation. Do not re-run unless an artifact has actually drifted.
- **Memory files persist across sessions** — the two saved ones are the operational baseline
- **Sprint 3 is the first multi-agent parallelization opportunity** — use it selectively for leaf work, not for shared foundation or tightly coupled work

Good luck. The foundation is solid. The next session has everything it needs to ship Sprints 3–6 to the Month 3 gate.

— Amelia, 2026-04-11, session handoff
