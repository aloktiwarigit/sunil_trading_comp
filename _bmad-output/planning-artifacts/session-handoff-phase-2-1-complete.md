---
artifact: Session Handoff — Phase 2.1 Walking Skeleton UI (Sprints 2-4)
audience: Next Claude Code session (fresh Amelia activation)
purpose: Complete context transfer so the next session can ship Sprint 5 (C3.4 + C3.5) and close the Walking Skeleton
version: v1.0
date_created: 2026-04-12
outgoing_head: c9d6aea
repo: https://github.com/aloktiwarigit/sunil_trading_comp
project_path: C:\Alok\Business Projects\Almira-Project
sprint_0_status: CLOSED — END STATE A (Alok is Hindi reviewer)
d4_consent: SECURED (Sunil-bhaiya face photo)
phase_2_1_status: Sprints 2-4 COMPLETE. Sprint 5 (C3.4 + C3.5) READY TO START.
walking_skeleton: 17/19 done. 2 remaining.
---

# Session Handoff — Phase 2.1 Sprints 2-4 Complete

## §0 — What this session (2026-04-12) accomplished

**7 commits on `origin/main`** from `6082d6d` → `c9d6aea`. The session shipped the Walking Skeleton UI from 6/19 to 17/19 stories.

```
c9d6aea  feat: Phase 2.1 Sprint 4 / C3.1 + P2.4 + P2.5 + S4.3 (WS 17/19)
a404c94  docs(sprint-status): update tracker — 13/19 WS done
23a10b0  fix(lib_core): Phase 1.10 — fix phone_upgrade_coordinator test debt
6619851  feat: Phase 2.1 Sprint 3 / B1.3 + B1.4 + B1.5 + S4.1 + S4.13
2f5c993  fix(sprint-2): code review — 2 blockers + 1 should-fix
bfeb4d3  feat(customer_app): Phase 2.1 B1.1 / first-time customer onboarding
34e8cce  feat(lib_core): Phase 2.1 B1.2 / BharosaLanding widget + D4 fallback
```

### Session metrics

| Metric | Value |
|---|---|
| Walking Skeleton stories shipped | 11 (B1.1-B1.5, C3.1, P2.4, P2.5, S4.1, S4.3, S4.13) |
| Walking Skeleton progress | 6/19 → 17/19 |
| New production files | ~40 |
| New AppStrings keys | 49 (9 + 1 + 12 + 28 across 4 sprints) |
| Tests passing (lib_core) | 90 |
| Test debt cleared | Phase 1.10 (2 root causes fixed, 0 failures remaining) |
| Code reviews | 2 (Sprint 2: 2🔴 fixed; Sprint 3: ✅ clean) |
| Lines added | ~10,000+ |
| Devanagari leak scans | Clean (all 4 sprints) |
| Forbidden vocab scans | Clean (all 4 sprints) |
| Triple Zero | $0.00/mo confirmed |

---

## §1 — What was built

### Sprint 2 (B1.1 + B1.2) — Customer onboarding + BharosaLanding

**lib_core components:**
- `ShopkeeperFaceFrame` — D4 Devanagari-initial fallback (default path), real face photo via Image.network
- `BharosaLanding` — hero (40% screen), meta bar, greeting card, shortlist preview, presence dock, locale toggle (EN/हिं), pull-to-refresh
- `ShopkeeperPresenceDock` — replaces bottom-tab nav, 44dp face frame + status dot

**customer_app:**
- `SplashScreen` — Devanagari-branded boot splash with compile-time defaults
- `OnboardingController` — silent anonymous auth → ShopThemeTokens fetch → locale resolution
- `GoRouter` — auth-gated splash → /landing with redirect guards

### Sprint 3 (B1.3 + B1.4 + B1.5 + S4.1 + S4.13) — Browse + Ops foundation

**lib_core components:**
- `VoiceNotePlayerWidget` — waveform inline player (14-bar, play/pause)
- `CuratedShortlistCard` — SKU card with "Sunil-bhaiya ki pasand" badge
- `ShortlistScreen` — finite vertical scroll (not paginated per UX §4.3)
- `GoldenHourPhotoView` — full-width photo with "asli roop" toggle
- `SkuDetailCard` — 70% hero, negotiableDownTo hidden (AC #7)

**shopkeeper_app:**
- `AuthController` — Google sign-in → operator doc → role-based access
- `SignInScreen` — full-screen Google sign-in, Workshop Almanac aesthetic
- `TodaysTaskCard` — 30-day ramp seed + weekly rotation
- `HomeDashboard` — task card + operator greeting + sign-out

### Sprint 4 (C3.1 + P2.4 + P2.5 + S4.3) — Commerce + Chat + Inventory

**lib_core components:**
- `ChatBubble` — balance-scale layout (customer LEFT, shopkeeper RIGHT)
- `ChatScreen` — message list + Devanagari input bar, infinite scroll

**customer_app:**
- `DraftController` — project draft creation, line item CRUD, Standing Rule 11 partition
- `DraftListScreen` — "My List" with quantity controls
- `ChatController` — real-time Firestore listener, optimistic UI send
- `CustomerChatScreen` — wires ChatScreen with customer-specific logic

**shopkeeper_app:**
- `CreateSkuController` — form state machine, Firestore write
- `CreateSkuScreen` — streamlined creation form (Devanagari name, category, dimensions, price)
- `InventoryListScreen` — real-time SKU stream with + FAB

### Phase 1.10 — Test debt cleared

- Happy path: replaced broken `MockFirebaseAuth.linkWithCredential` with clean `_HappyPathAuthProvider`
- Timestamp: `DateTime` → `Timestamp.fromDate()` for fake_cloud_firestore round-trip
- 0 test failures remaining across entire repo

---

## §2 — What's left for Walking Skeleton closure (Sprint 5)

**2 stories remaining:**

| Story | What | Deps met? |
|---|---|---|
| **C3.4** — Commit project with phone OTP upgrade | Customer finalizes draft → phone OTP ceremony → Project.state="committed" | C3.1 ✅, I6.2 ✅ |
| **C3.5** — UPI payment intent flow | Customer pays via UPI intent → Project.state="paid" + Triple Zero invariant | C3.4 (serial) |

**C3.4 is the most complex remaining story** (XL per epics listing):
- Consumes `PhoneUpgradeCoordinator` (already built + tested in Sprint 2.1)
- The anonymous → phone-verified upgrade preserves UID via `linkWithCredential`
- `AuthCollisionException` recovery path already implemented + tested
- OTP framing copy: "सुनील भैया डिलीवरी के लिए संपर्क करेंगे, आपका फ़ोन नंबर चाहिए" (already in AppStrings as `otpPromptBhaiyaNeedsIt`)

**C3.5 enforces the Triple Zero invariant:**
- `amountReceivedByShop == totalAmount` at `Project.state == 'paid'`
- UPI intent via Android Intent (no payment gateway — free)
- COD / bank transfer / udhaar are secondary paths (separate depth stories)

**Estimated effort:** 1 session for both (serial: C3.4 first, then C3.5).

---

## §3 — Kickoff prompt for Sprint 5

```markdown
You are Amelia — Senior Software Engineer on the Yugma Dukaan project. Re-activate via `bmad-agent-dev` skill.

Previous session shipped Sprints 2-4 (WS 17/19). Read:
1. `_bmad-output/planning-artifacts/session-handoff-phase-2-1-complete.md` — this doc
2. `_bmad-output/implementation-artifacts/sprint-status.yaml` — canonical tracker
3. Run `git log --oneline -10` + `git status --short` — verify at c9d6aea

Mission: Ship Sprint 5 (C3.4 + C3.5) to close the Walking Skeleton at 19/19.

C3.4 first (commit with phone OTP), then C3.5 (UPI payment intent). Serial.
Code review at sprint boundary. Then update sprint-status.yaml.

All binding rules from prior sessions apply. 6 memory files are canonical.
```

---

## §4 — Known-good state + gotchas

### Works correctly (do NOT "fix")
- Everything from the prior handoff §4.1 PLUS:
- `_HappyPathAuthProvider` mock in phone_upgrade_coordinator_test.dart — intentionally bypasses `firebase_auth_mocks` broken `linkWithCredential`. Do NOT revert to `AuthProviderFirebase` + `MockFirebaseAuth`.
- `app.dart _buildDefaultTheme()` registers a default `YugmaThemeExtension` — Sprint 2 code review blocker #1 fix. Ensures `context.yugmaTheme` never crashes during splash.
- Router redirect guards `/landing` during loading — Sprint 2 code review blocker #2 fix.
- `ShopThemeTokens.sunilTradingCompanyDefault()` taglines are STILL empty strings — now can be populated with Alok-approved copy.
- ChatBubble uses `shopAccent`/`shopAccentGlow` for brass thread — NEVER `shopCommit` (oxblood reserved for payment).
- `DraftController` uses `ProjectCustomerCancelPatch` for draft cancel — Standing Rule 11 compliant.
- `InventorySkuRepo.getById` returns soft-deleted SKUs by design (dual-use contract per prior handoff).

### Gotchas
- **Font subsets not built yet.** `tools/generate_devanagari_subset.sh` needs `pip install fonttools brotli zopfli`. Needed before real device Devanagari test.
- **Phase 1.4.1 follow-up:** register subset fonts in `apps/*/pubspec.yaml` per `docs/runbook/font-subset-build.md`.
- **Cloud Storage not enabled on dev.** 1 console click. Needed for voice note playback (B1.3 full wiring).
- **`functions/` npm packages:** firebase-functions `^6.1.0` works but deploy log warns about upgrade.
- **Pre-existing info-level lint warnings:** `always_use_package_imports` + `sort_constructors_first` across codebase. Cosmetic, not blocking.
- **Worktree branches may still exist:** `worktree-agent-*` branches from Sprint 3+4 parallel agents. Safe to delete: `git branch -D worktree-agent-a9e9109c worktree-agent-ac9ae3f4 worktree-agent-a3fa32c4 worktree-agent-afe93df2`.

### Sprint 5 specific notes
- C3.4 needs the `PhoneUpgradeCoordinator` wired into the customer_app commit flow. The coordinator is in lib_core `src/services/phone_upgrade_coordinator.dart` — fully tested (7/7).
- C3.5 UPI intent: Android-only in v1. Uses `android_intent_plus` or `url_launcher` with `upi://pay?...` scheme. No payment gateway SDK needed (free path per Triple Zero).
- The `commitButtonPakka` and `upiPayButton` AppStrings keys already exist from Phase 1.4.
- `paymentSuccessPakka` also already exists.
- The oxblood `shopCommit` color is ONLY used for the commit button + payment success state. C3.4 and C3.5 are the first stories that legitimately use it.

---

## §5 — File locations

Same as prior handoff §5, plus:

| File | What |
|---|---|
| `packages/lib_core/lib/src/components/bharosa_landing/` | BharosaLanding + FaceFrame + PresenceDock (Sprint 2) |
| `packages/lib_core/lib/src/components/voice_note_player.dart` | VoiceNotePlayer (Sprint 3) |
| `packages/lib_core/lib/src/components/browse/` | ShortlistCard + ShortlistScreen + GoldenHourPhotoView + SkuDetailCard (Sprint 3) |
| `packages/lib_core/lib/src/components/chat/` | ChatBubble + ChatScreen (Sprint 4) |
| `apps/customer_app/lib/features/onboarding/` | SplashScreen + OnboardingController (Sprint 2) |
| `apps/customer_app/lib/features/project/` | DraftController + DraftListScreen (Sprint 4) |
| `apps/customer_app/lib/features/chat/` | ChatController + CustomerChatScreen (Sprint 4) |
| `apps/shopkeeper_app/lib/features/auth/` | AuthController + SignInScreen (Sprint 3) |
| `apps/shopkeeper_app/lib/features/dashboard/` | HomeDashboard + TodaysTaskCard + TodaysTaskSeed (Sprint 3) |
| `apps/shopkeeper_app/lib/features/inventory/` | CreateSkuController + CreateSkuScreen + InventoryListScreen (Sprint 4) |
| `_bmad-output/planning-artifacts/session-handoff-phase-2-1-complete.md` | **THIS document** |

---

## §6 — Pending on Alok

### 🟢 No hard blockers

Sprint 5 (C3.4 + C3.5) has zero dependencies on Alok. Everything is unblocked.

### 🟡 Future-sprint horizon

1. **Hindi string review pass.** 49 new AppStrings keys added this session. Alok should scan `strings_hi.dart` §1b through §18 in a PR diff before any customer-facing deploy.
2. **Font subsets.** `pip install fonttools brotli zopfli` + run `tools/generate_devanagari_subset.sh`. One-time dev env setup.
3. **Cloud Storage enable on dev.** Firebase Console click. Needed for B1.3 voice note full wiring.
4. **ShopThemeTokens taglines.** Can now be populated with Alok-approved Devanagari copy. Currently empty strings.
5. **Worktree branch cleanup.** 4 stale branches from parallel agents.

---

— Amelia, 2026-04-12 (Phase 2.1 Sprints 2-4 complete, WS 17/19)
