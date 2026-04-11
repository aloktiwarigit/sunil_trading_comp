---
project_name: 'Almira-Project (Yugma Dukaan)'
flagship_shop: 'Sunil Trading Company (सुनील ट्रेडिंग कंपनी)'
shop_id: 'sunil-trading-company'
user_name: 'Alok'
author: 'BMAD Implementation Readiness Check'
facilitator: 'John (BMAD Product Manager)'
date: '2026-04-11'
version: 'v1.2'
status: 'Phase 6 IR Check re-validation complete. 7 original criteria + 4 new back-fill criteria evaluated against the patched 6-artifact bundle. 66↔67 arithmetic flag resolved (PRD headline patched 66→67 per canonical per-epic sum). 11 surgical cross-document patches applied. 🟢 READY FOR PHASE 7 (Amelia resumes Sprint 1). One 🟡 finding remains for Mary (Brief §4.3 stale font ref); not a Sprint 1 blocker.'
inputs_validated:
  - product-brief.md (v1.4 — unchanged during back-fill)
  - solution-architecture.md (v1.0.4 — Phase 1 AE + Phase 6 IR font/naming patches)
  - prd.md (v1.0.5 — Phase 2 AE + Phase 6 IR 66→67 + I6.9 font + handoff count patches)
  - epics-and-stories.md (v1.2 — Phase 3 re-derive + Phase 6 IR 66→67 propagation)
  - ux-spec.md (v1.1 — Phase 4 AE + Phase 6 IR §5.5/§7.6 count patches + §8.19 I6.10 note)
  - frontend-design-bundle/ (v1.1 — Phase 5 AE; no Phase 6 patches needed)
supporting_context:
  - product-brief-elicitation-01.md
  - party-mode-session-01-synthesis-v2.md
  - sprint-0-i6-11-checklist.md (v1.0 — Sprint 0 I6.11 governance gate)
  - shopkeeper-onboarding-playbook.md (v1.0)
criteria_evaluated: 11 (7 original + 4 back-fill)
patches_applied: 11
---

# Implementation Readiness Report — Yugma Dukaan v1 — Phase 6 Re-validation

**Pre-flight check before Amelia (Developer) resumes Sprint 1 after the 6-phase BMAD back-fill round.**

---

## §1 — Executive Verdict

**🟢 READY FOR PHASE 7 (Amelia resumes Sprint 1) — with 11 surgical Phase 6 patches applied.**

The 6-phase BMAD back-fill has successfully converged the planning chain through Advanced Elicitation gates that were skipped in the original planning round. Phases 1–5 produced a substantively stronger bundle than v1.0 — 8 new PRD stories closing 9 brief→PRD audit gaps, 3 new SAD ADRs (013–015), 2 new Cloud Functions (7 `mediaCostMonitor`, 8 `shopDeactivationSweep`), 6 new UX interaction patterns, 20 new Hindi voice & tone strings, 8 new bundle widgets + 1 widget extension + 1 new file (`invoice_template.dart`), and 6 new visual mockups in `walking-skeleton.html`.

This Phase 6 IR check found:
- **One substantive arithmetic flag resolved.** The 66↔67 story-count drift logged in Epics List v1.2 §1 was investigated by mechanical enumeration of PRD v1.0.5 story headers. The canonical correct total is **67** (E6:12 + E1:13 + E2:8 + E3:12 + E4:17 + E5:5 = 67). The PRD v1.0.5 patch note's "58 → 66" arithmetic used the v1.0 baseline (58) instead of the v1.1 baseline (59, post-S4.13) — the 8 new v1.0.5 stories against the correct baseline yield 59 + 8 = **67**, not 66. Patched PRD headline (5 occurrences) and propagated through Epics List v1.2 (4 occurrences) and a dependent cross-tenant count ("53 of 66" → "52 of 67").
- **Three stale font-stack references corrected** in PRD I6.9 AC #4 and edge cases #1 and #3, and two SAD §5 schema examples — all still referenced the rejected "Noto Sans Devanagari" instead of the Brief v1.4 Constraint 4 locked stack (Tiro Devanagari Hindi + Mukta + Fraunces + EB Garamond + DM Mono). UX Spec and Design Bundle had already corrected theirs in Phase 4 and Phase 5; the PRD and SAD had drifted.
- **One sealed-union naming drift corrected** in SAD §9. The SAD §9 v1.0.4 field-partition paragraph used `CustomerProjectPatch` / `OperatorProjectPatch` while the downstream canonical naming (PRD Standing Rule 11, Epics List §11 item 11, I6.12, bundle code comments) uses `ProjectCustomerPatch` / `ProjectOperatorPatch` / `ProjectSystemPatch`. The downstream naming also includes the `System` variant (Cloud-Function-owned writes) which SAD §9 had implicit but un-named. Patched SAD §9 to match the downstream canonical.
- **Three stale count-drift fixes** in the PRD "Handoff Notes for Amelia" ("17 stories above" → "19", "10 rules" → "11") and UX Spec §5.5 heading ("45 grounded examples" → "50") and §7.6 item 6 ("30 example strings" → "50").
- **One UX Spec Walking Skeleton coverage gap patched** — §8 claimed 19 strategic notes but covered 18 (I6.10 had no dedicated §8 entry, only an implicit mention). Added §8.19 for I6.10 Crashlytics + Analytics + Performance + App Check to honor the 19-story promise.
- **One 🟡 finding left open for Mary** — Product Brief §4.3 line 422 still states "Typography: Noto Sans Devanagari / Mukta as primary; Inter or Roboto as English secondary." This contradicts the Brief's own v1.4 §8 Constraint 4 update (line 305), which correctly specifies the Tiro Devanagari Hindi + Mukta + Fraunces + EB Garamond + DM Mono stack. The v1.4 patch note at line 573 already calls this out but the §4.3 design-direction bullet was missed. Brief is outside Phase 6's surgical-edit permission envelope (Mary owns the brief); left as a 🟡 recommendation for a 30-second patch by Mary.
- **No substantive rework needed.** All 11 criteria pass at ✅ or ⚠️-with-patch-applied; no criterion hit ❌. The Sprint 1 4-story plan (I6.1, I6.4, I6.10, I6.12) is feasible given the small-team constraint with one important caveat analyzed in §12 below.

**Sprint 1 readiness:** ✅ Green light. Amelia can resume Sprint 1 today. Sprint 0 (I6.11 Hindi design capacity verification gate) must close first — the `sprint-0-i6-11-checklist.md` is executable and requires Alok's answer within 1–2 weeks.

**Total expected remaining work before "hands on keyboard" for Amelia:**
1. Alok closes Sprint 0 I6.11 governance gate via `sprint-0-i6-11-checklist.md` (an END STATE A — Hindi capacity secured — or END STATE B — Constraint 4 scope reduction accepted)
2. Alok answers D1/D2/D3/D5 from the bundle README (D4 still open; not Sprint 1 load-bearing)
3. Mary applies the one 🟡 Brief §4.3 font-stack patch
4. Amelia re-reads the patched bundle and starts Sprint 1

Estimated critical-path delay to Sprint 1 Day 1: **Sprint 0 Hindi capacity gate, 1–2 weeks**. Nothing else blocks.

---

## §2 — Document Inventory

| # | Artifact | Version | Length | Last Modified | Phase | Status |
|---|---|---|---|---|---|---|
| 1 | `product-brief.md` | **v1.4** | ~13,500 words / 581 lines | 2026-04-11 | baseline | ✅ Final (1 🟡 — Brief §4.3 stale font ref, Mary's to patch) |
| 2 | `solution-architecture.md` | **v1.0.4** | ~19,500 words / 3,191 lines | 2026-04-11 (Phase 1 AE + Phase 6 IR patches) | 1 + 6 | ✅ Final after Phase 6 patches |
| 3 | `prd.md` | **v1.0.5** | ~14,500 words / 2,464 lines | 2026-04-11 (Phase 2 AE + Phase 6 IR patches) | 2 + 6 | ✅ Final after Phase 6 patches |
| 4 | `epics-and-stories.md` | **v1.2** | ~13,000 words / 713 lines | 2026-04-11 (Phase 3 re-derive + Phase 6 IR patches) | 3 + 6 | ✅ Final after Phase 6 patches |
| 5 | `ux-spec.md` | **v1.1** | ~30,000 words / 1,942 lines | 2026-04-11 (Phase 4 AE + Phase 6 IR patches) | 4 + 6 | ✅ Final after Phase 6 patches |
| 6 | `frontend-design-bundle/README.md` | **v1.1** | ~10,500 words / 559 lines doc + ~4,700 lines code + 3,865 lines HTML mockups | 2026-04-11 (Phase 5 AE) | 5 | ✅ Final; no Phase 6 patches needed |
| — | `sprint-0-i6-11-checklist.md` (supporting) | v1.0 | ~5,000 words / 252 lines | 2026-04-11 | — | ✅ Final (Amelia-drafted) |
| — | `shopkeeper-onboarding-playbook.md` (supporting) | v1.0 | ~11,000 words | 2026-04-11 | — | ✅ Final |
| — | `implementation-readiness-report.md` | **v1.2** | ~6,500 words | 2026-04-11 (Phase 6 IR Check) | 6 | ✅ This document (overwrites v1.1) |

**Total planning output:** ~108,000 words + ~4,700 lines of design system Dart + 3,865 lines of HTML mockup + the 252-line Sprint 0 checklist and the 11,000-word onboarding playbook. Dense, structured, citation-clean.

**Phase 5 v1.1 bundle delta summary (for context):** the design bundle added 8 new widgets and 1 widget extension to `components_library.dart` (1,469 → 3,075 lines), a new `invoice_template.dart` file (807 lines), and 1,067 new lines of mockup HTML. The 3 token files (`tokens.dart` / `shop_theme_tokens.dart` / `yugma_theme_extension.dart`) are **unchanged** — token discipline held.

---

## §3 — Alignment Matrix (11 criteria)

### Criterion 1 — Cross-document positioning alignment (original)

**Rating:** ✅

**Evidence:**
- Brief §1 positioning ("Yugma Dukaan = Hindi-first Tier-3 storefront for Sunil Trading Company") matches SAD §1 Executive Architecture Summary, matches PRD §1 Vision Compression, matches Epics List §1 Backlog Summary, matches UX Spec §1 UX Vision, matches Design Bundle README Aesthetic.
- The two pillars (Bharosa + Pariwar) are referenced consistently across all 6 documents.
- The 15 constraints from Brief §8 are referenced by constraint number in SAD ADRs, PRD Standing Rules, UX Spec §1.2 principles, and Bundle README Cross-checks.
- The 16 risks from Brief §9 map cleanly to SAD risk-mitigation adapters (R3 MediaStore, R8 AuthProvider, R13 CommsChannel) and to PRD standing rules (R10 udhaar vocabulary, R12 OTP fallback, R16 shop deactivation).
- The new v1.0.5 audit-gap-closure stories all trace cleanly from Brief section references to PRD story references to SAD ADR references to Bundle widget references.

**Gaps found:** None. Alignment across 6 artifacts is the strongest dimension of this planning bundle.

---

### Criterion 2 — Story-to-architecture traceability (original)

**Rating:** ✅

**Evidence:** Every PRD story has explicit `Refs:` field citing Brief section + SAD section/ADR. Spot-checked 8 new v1.0.5 stories:
- **I6.11** → Brief Constraint 15 + Brief §12 Step 0.6 + SAD ADR-008 + audit gap #1
- **I6.12** → SAD v1.0.4 §9 field-partition table + ADR-004 + Standing Rule 11 + audit gap #8
- **B1.13** → Brief §3 Bharosa "plain dignified invoices" + SAD v1.0.4 ADR-015 + Brief Constraint 4 + audit gap #4
- **C3.12** → Brief §9 R16 + SAD v1.0.4 ADR-013 + SAD §5 Shop lifecycle fields + SAD §7 Function 8 + DPDP Act 2023 + audit gap #2
- **S4.16** → Brief §9 R3 + SAD v1.0.4 ADR-014 + SAD §7 Function 7 + Brief §6 Month 9 gate + audit gap #3
- **S4.17** → Brief §6 Month 6 success gate + Brief §9 R1 burnout kill-gate + SAD v1.0.4 §5 `feedback` sub-collection + SAD §6 feedback rule + audit gap #5
- **S4.18** → Brief §6 Month 9 gate + SAD v1.0.4 §5 `Customer.previousProjectIds` capped array + Standing Rule 11 (`ProjectSystemPatch` Cloud Function) + audit gap #7
- **S4.19** → SAD v1.0.4 ADR-013 + SAD §5 Shop lifecycle fields + SAD §7 Function 8 `shopDeactivationSweep` + Brief §9 R16

Every new story has a corresponding Dart widget in the bundle (cross-ref table in Bundle README §"Verdict for Phase 6" item 1, verified):
- B1.13 → `InvoiceTemplate` in `invoice_template.dart`
- C3.12 → `ShopDeactivationBanner` + `ShopDeactivationFaqScreen`
- S4.17 → `NpsCard`
- S4.19 → `ShopDeactivationTap1Page` + `ShopDeactivationTap2ReasonPicker` + `showShopDeactivationConfirmDialog` + `ShopReversibilityCard`
- S4.16 → `MediaUsageTile`
- S4.10 (updated) → `UdhaarLedgerCard` extended in-place
- I6.11 → governance artifact (no widget; documented in `sprint-0-i6-11-checklist.md`)
- I6.12 → foundational infrastructure (Freezed sealed unions; no widget; documented in PRD Standing Rule 11 + Epics List §11 item 11)
- S4.18 → no dedicated widget (dashboard tile extension of S4.11; `previousProjectIds` `arrayUnion` via `ProjectSystemPatch` Cloud Function trigger on commit)

**Gaps found:** None. Every new story traces end-to-end across SAD / PRD / Epics List / UX Spec / Bundle.

---

### Criterion 3 — Feature flag completeness (both states documented) (original)

**Rating:** ✅

**Evidence:** The feature flag surface grew from 6 to **8** in v1.0.5:
1. `decisionCircleEnabled` — 4 stories (P2.1, P2.2, P2.7, implicit fallback in P2.8)
2. `guestModeEnabled` — 2 stories (P2.2, P2.3)
3. `otpAtCommitEnabled` — 2 stories (I6.2, C3.4)
4. `commsChannelStrategy` — 4 stories (I6.5, P2.4, P2.5, S4.8)
5. `authProviderStrategy` — 1 story (I6.1)
6. `mediaStoreStrategy` — 2 stories (I6.6, S4.16)
7. **`defaultLocale`** *(v1.0.5 add)* — 1 story (I6.11) — governance-gate fallback flag
8. **`cloudinary_uploads_blocked`** *(v1.0.5 add)* — 1 story (S4.16) — real-time kill-switch via Firestore `onSnapshot`

For each flag, the on-state and off-state are documented in the PRD acceptance criteria, the UX Spec §6 state catalog (expanded from 29 to 67 states in v1.1), and the bundle's component fallback notes. Spot-checked `defaultLocale` — I6.11 AC #5 describes the fallback path ("flip `defaultLocale` Remote Config `"hi"` → `"en"`, log Crashlytics `constraint_15_fallback_triggered`"), Sprint 0 checklist §2 END STATE B describes the operational actions, bundle has no new visual treatment (it's a locale switch that reuses existing `strings_en.dart` tree).

Spot-checked `cloudinary_uploads_blocked` — S4.16 AC #5 describes real-time propagation via Firestore `onSnapshot` per I6.7 AC #7, Function 7 `mediaCostMonitor` writes the flag when Cloudinary hits hard cap, MediaStore adapter contract per ADR-014 subscribes to the flag, `MediaUsageTile` in bundle renders the red-alt `Cloudinary खत्म — R2 चालू` state.

**Gaps found:** None.

---

### Criterion 4 — Cross-tenant integrity coverage (original)

**Rating:** ✅

**Evidence:** SAD ADR-012 + synthetic `shop_0` discipline + PRD standing rule #5 + Epics List §11 rule #3 + cross-tenant integrity test in CI. **Still the strongest alignment in the bundle (5 documents converged).** Post-patch count: **52 of 67 stories** require cross-tenant integrity test (corrected in this IR check from stale "53 of 66"; the exclusion list was always 15 items, not 13).

I6.12 (new v1.0.5 Sprint 1 foundation story) explicitly ADDS new cross-tenant test cases: partition-crossing compile-time checks + security-rule replay checks. This strengthens the discipline rather than weakening it.

Spot-checked the 8 new v1.0.5 stories for cross-tenant ACs:
- I6.11: N — governance artifact, 1 Remote Config write, no user data
- I6.12: Y — adds new cross-tenant test cases
- B1.13: Y — invoice render is read-only but the `InvoiceData` construction from the Project doc must honor the tenant boundary
- C3.12: Y — banner state read from Shop.shopLifecycle (tenant-scoped)
- S4.16: Y — counter writes to `system/media_usage_counter/{shopId}` (explicitly per-shop-scoped)
- S4.17: Y — feedback writes to `shops/{shopId}/feedback/{feedbackId}` (tenant-scoped by path)
- S4.18: Y — previousProjectIds arrayUnion via ProjectSystemPatch Cloud Function (server-side, tenant-scoped via path)
- S4.19: Y — Shop.shopLifecycle writes scoped to this shop only

**Gaps found:** None.

---

### Criterion 5 — Hindi-first traceability (Devanagari source-of-truth) (original)

**Rating:** ⚠️ → ✅ **after Phase 6 patches**

**Evidence pre-patch:** Brief v1.4 Constraint 4 (§8 line 305) correctly specifies the Tiro Devanagari Hindi + Mukta + Fraunces + EB Garamond + DM Mono stack. The Brief v1.4 patch note at line 573 flags this. UX Spec v1.1 and the Design Bundle v1.1 are fully aligned to the Constraint 4 font stack.

**Evidence pre-patch gaps:**
- Brief §4.3 line 422 stale: "Typography: Noto Sans Devanagari / Mukta as primary; Inter or Roboto as English secondary"
- PRD I6.9 AC #4 stale: "Noto Sans Devanagari and Mukta fonts subset-built"
- PRD I6.9 edge case #1 stale: "fallback to system Noto Sans Devanagari" (correct as runtime fallback semantics but worded ambiguously)
- PRD I6.9 edge case #3 stale: "Noto Sans Devanagari subset corrupts during build"
- SAD §1 line 59 stale: "Typography: Noto Sans Devanagari / Mukta primary, Inter or Roboto secondary"
- SAD §3 line 317 stale: `devanagari.css  # Subset-loaded Noto Sans Devanagari`
- SAD §5 line 1117 stale: `fontFamilyDevanagari: "Noto Sans Devanagari"` in ShopThemeTokens schema example
- SAD §8 line 2438 stale: same as above in the duplicate schema example

**Phase 6 patches applied:**
- SAD §1 line 59 — rewritten to Brief v1.4 Constraint 4 stack with IR Check v1.2 provenance note
- SAD §3 line 317 — rewritten to `Tiro Devanagari Hindi + Mukta` with provenance note
- SAD §5 line 1117 and §8 line 2438 — `ShopThemeTokens` schema examples rewritten to expand the stale `fontFamilyDevanagari` / `fontFamilyEnglish` pair into the full 5-field Constraint 4 set (`fontFamilyDevanagariDisplay`, `fontFamilyDevanagariBody`, `fontFamilyEnglishDisplay`, `fontFamilyEnglishBody`, `fontFamilyMono`) with provenance
- PRD I6.9 AC #4 and edge cases #1 + #3 — rewritten to the Constraint 4 stack; edge case #1 clarified to distinguish the Crashlytics-logged runtime fallback (system-bundled Noto Sans Devanagari on cheap Android) from the ships-with-the-app primary stack (Tiro Devanagari Hindi + Mukta, Constraint 4)

**Remaining 🟡 finding:** Brief §4.3 line 422 is outside Phase 6's surgical-edit permission envelope. Flagged for Mary — 30-second patch. Not a Sprint 1 blocker because Amelia will read Brief §8 Constraint 4 (which is correct) and the patched downstream artifacts. The Brief §4.3 line is a "design direction" soft statement, not a normative requirement; the normative source is §8 Constraint 4.

**Rating after patches:** ✅

---

### Criterion 6 — Walking Skeleton coverage (original)

**Rating:** ⚠️ → ✅ **after Phase 6 §8.19 patch**

**Evidence:** 19 Walking Skeleton stories are asserted in PRD v1.0.5 §Walking Skeleton, Epics List v1.2 §2, and UX Spec v1.1 §8 header. Pre-patch, UX Spec §8 had 18 strategic notes (8.1 through 8.17 + 8.18) but missed I6.10. IR Check v1.1 accepted this as "(n/a — infra) / ✅ implicit" but v1.2 demands explicit coverage to honor the 19 assertion.

**Phase 6 patch applied:** Added UX Spec §8.19 — I6.10 — Crashlytics + Analytics + Performance + App Check strategic note (documented as not-user-visible infra with specific "must not happen" events and cross-references to §7 accessibility + font-fallback Crashlytics pipeline).

**Full 19-story coverage table in §4 below.**

**Rating after patch:** ✅

---

### Criterion 7 — Sprint 1 unblockedness (original)

**Rating:** ✅

**Evidence:** Sprint 1 per Epics List v1.2 §2 now has 4 stories (was 3 in v1.1): I6.1 + I6.4 + I6.10 + I6.12. All 4 are dependency-consistent per the E6 dependency graph:
- **I6.1:** no dependencies (foundation)
- **I6.4:** depends only on I6.1 (same sprint — can be worked in parallel behind I6.1 interface)
- **I6.10:** depends on I6.1 + I6.4 + I6.7 (I6.7 is in Sprint 1 per a note but actually scheduled for Sprint 2; this is a dependency-order timing concern — see §12 feasibility analysis. In practice I6.10 Crashlytics/Analytics/App Check can be scaffolded against a minimal Remote Config client that polls once at boot without the full I6.7 real-time listener wire-up.)
- **I6.12:** depends on I6.1 + I6.4 (same sprint — repository-layer work adjacent to I6.4's multi-tenant scoping, same engineer-week)

All 4 stories have explicit Dart code scaffolding in the Design Bundle (`tokens.dart`, `shop_theme_tokens.dart`, `yugma_theme_extension.dart`, and code comments in `components_library.dart` about partition discipline).

All 4 stories have SAD §4 (auth flows) / §5 (schema) / §6 (security rules) / §7 (functions) / §9 (offline sync) coverage.

All 4 stories have UX Spec §8 strategic notes (§8.1 I6.1, §8.4 I6.4, §8.19 I6.10 *(new Phase 6 patch)*, §8.18 I6.12).

**Caveat on feasibility:** the 4-story Sprint 1 with one XL (I6.12) + one XL (I6.1) + one XL (I6.4) + one M (I6.10) is a heavy week for a small team (2–3 engineers per Brief Constraint 13). See §12 for the detailed feasibility analysis.

**Gaps found:** None for unblockedness. See §12 for feasibility concern.

---

### Criterion 8 — Audit-gap closure traceability (new for v1.2)

**Rating:** ✅

**Evidence:** All 9 brief→PRD audit gaps are closed at every downstream layer they touch. Full trace table in §9 below. Summary:

| Gap | Closed by |
|---|---|
| #1 Hindi capacity gate | ADR-008 v1.0.4 clarification + PRD I6.11 + UX §8.0 + Sprint 0 checklist |
| #2 DPDP shop deactivation | ADR-013 + §5 lifecycle fields + §7 Function 8 + PRD C3.12 + S4.19 + UX §4.12/§6.7 + Bundle ShopDeactivationBanner/FaqScreen |
| #3 Cloudinary cost telemetry | ADR-014 + §7 Function 7 + PRD S4.16 + UX §4.15/§6.10 + Bundle MediaUsageTile |
| #4 Devanagari invoice | ADR-015 + PRD B1.13 + UX §4.11/§6.6 + Bundle invoice_template.dart |
| #5 NPS + burnout | §5 feedback collection + PRD S4.17 + UX §4.13/§6.8 + Bundle NpsCard |
| #6 wa.me Project context | SAD §7 Function 2 v1.0.4 clarification (closed at SAD layer, no new PRD story needed) |
| #7 Repeat customer | §5 Customer.previousProjectIds + PRD S4.18 |
| #8 Offline conflict resolution | SAD §9 field-partition table + PRD I6.12 + Standing Rule 11 + UX §8.18 + Bundle partition comments |
| #9 Zero-commission math | §5 Project.amountReceivedByShop + PRD C3.4 AC #4 + C3.5 AC #8 |

**Gaps found:** None. Every audit gap is closed at every layer it touches.

---

### Criterion 9 — AE patches survived end-to-end (new for v1.2)

**Rating:** ✅

**Evidence:** Spot-checked representative Phase 1/2/4/5 AE findings for downstream reflection:

**Phase 1 SAD AE patches (12 landed per SAD v1.0.4 patch note table):**
- F1 (Shop deactivation lifecycle) → closed by §5 Shop schema + §6 `shopIsWritable` + §7 Function 8 + ADR-013 → **reflected in PRD** as C3.12 + S4.19 ✅
- F2 (Cloudinary cost monitor) → §7 Function 7 + ADR-014 → **reflected in PRD** as S4.16 ✅
- F3 (Zero-commission math) → §5 Project `amountReceivedByShop` → **reflected in PRD** as C3.4 AC #4 + C3.5 AC #8 ✅
- F8 (Offline conflict resolution) → §9 field-partition + invariants → **reflected in PRD** as I6.12 + Standing Rule 11 ✅
- F9 (Kill-switch real-time propagation) → ADR-007 clarification → **reflected in PRD** as I6.7 AC #7 + AC #8 ✅
- F11 (RBI guardrails) → §7 Function 3 three-part guardrail + §5 UdhaarLedger fields → **reflected in PRD** as S4.10 AC #7/#8/#9 ✅
- F12 (Constraint 15 fallback) → ADR-008 clarification + §5 `FeatureFlags.defaultLocale` → **reflected in PRD** as I6.11 ✅
- F13 (Invoice no architectural home) → ADR-015 → **reflected in PRD** as B1.13 ✅
- F14 (feedback collection missing) → §5 feedback sub-collection + §6 rule → **reflected in PRD** as S4.17 ✅
- F15 (previousProjectIds missing) → §5 Customer capped array → **reflected in PRD** as S4.18 ✅

**Phase 2 PRD AE patches (beyond Winston's handoff):**
- F-P1 (shopkeeper deactivation needs udhaar reassurance) → S4.19 edge cases ✅
- F-P2 (customer C3.12 banner needs data-export CTA) → C3.12 AC #7 ✅ → reflected in Bundle (`ShopDeactivationFaqScreen` data-export sticky CTA) ✅
- F-P3 (NPS wording too formal) → S4.17 AC #1 revised ✅ → reflected in UX Spec §5.5 string 41 "कितना उपयोगी लगा?" (casual) ✅ → reflected in Bundle (`NpsCard` headline uses #41 verbatim) ✅
- F-PM3 (S4.19 accidental destruction) → 24-hour reversibility window ✅ → reflected in Bundle (`ShopReversibilityCard`) + UX Spec §5.5 string 45 + §7.5 AE F15 device-test patch for elder+large-text combined mode ✅

**Phase 4 UX Spec AE patches (14 findings):**
- F11 (विश्वास "trust" reads temple-adjacent) → cleared by §5.6 permitted-everyday-warmth-words ✅ → re-verified in Bundle AE A4 (cleared by Sally's documented §5.6 clearance, no patch needed) ✅
- F12 (NPS dot row anchor labels) → §4.13 + §5.5 strings 41–43 ✅ → reflected in Bundle (`NpsCard` 10-dot row with `1 = बिल्कुल नहीं` / `10 = बहुत ज़्यादा`) ✅
- F14 (C3.12 elder-tier banner short-copy variant) → §4.12 + §6.7 ✅ → reflected in Bundle (`ShopDeactivationBanner` elder-tier short-copy variant) ✅
- F15 (S4.19 reversibility footer elder+large-text combined mode) → §7.5 device test + §4.14 ✅ → reflected in Bundle AE A6 patch (`ShopDeactivationConfirmDialog` footer uses `YugmaLineHeights.snug` + natural wrap) ✅

**Phase 5 Bundle AE patches (7 applied):** No downstream layer to check. Cross-verified that none violates any upstream constraint:
- A1 warmer-amber derivation is still inside palette (verified via Bundle README §"Cross-checks")
- A3 `NpsCard` Switch activeTrackColor — Material 3 compliance, no constraint violation
- A5 `ShopDeactivationFaqScreen` section titles locked per UX §4.12 — upstream-documented
- A6 footer line-height — accessibility requirement from UX §7.3
- A7 `NpsCard` 10-dot spaceBetween + 30dp — within WCAG minimum per UX §7.3
- A12 elder-tier preview consolidation — consistent with UX §4.6 systematic transform
- A14 invoice filename host-responsibility — consistent with Brief Constraint 15 Android 8+ minSdk per SAD §4

**Gaps found:** None. All AE patches survived end-to-end without contradiction.

---

### Criterion 10 — Compliance gate enforcement at every layer (new for v1.2)

**Rating:** ⚠️ → ✅ **after Phase 6 font patches** (with one 🟡 Brief §4.3 for Mary)

**The 5 compliance gates:**

**Gate 1 — Constraint 4 (font stack):** Tiro Devanagari Hindi + Mukta + Fraunces + EB Garamond + DM Mono.

| Layer | Pre-patch | Post-patch | Notes |
|---|---|---|---|
| Brief §8 Constraint 4 | ✅ Correct (v1.4) | ✅ | Normative source |
| Brief §4.3 line 422 | ❌ Stale "Noto Sans Devanagari / Mukta / Inter / Roboto" | 🟡 (unchanged) | **Outside Phase 6 permission envelope; Mary to patch in 30s** |
| SAD §1 line 59 | ❌ Stale | ✅ | Patched |
| SAD §3 line 317 | ❌ Stale CSS comment | ✅ | Patched |
| SAD §5 line 1117 schema | ❌ Stale | ✅ | Patched (full 5-field expansion) |
| SAD §8 line 2438 schema | ❌ Stale | ✅ | Patched (full 5-field expansion) |
| SAD ADR-008 | ✅ Correct (v1.0.4 clarification) | ✅ | |
| PRD I6.9 AC #4 | ❌ Stale | ✅ | Patched |
| PRD I6.9 edge case #1 | ❌ Ambiguous runtime-vs-bundled | ✅ | Patched with explicit runtime-fallback semantics |
| PRD I6.9 edge case #3 | ❌ Stale | ✅ | Patched |
| Epics List | ✅ No font references | ✅ | |
| UX Spec v1.1 | ✅ Already patched in Phase 4 | ✅ | |
| Bundle v1.1 | ✅ Already enforced token discipline in Phase 5 | ✅ | |

**Gate 2 — Constraint 10 ("show don't sutra"):** No mythic/sanskritized vocabulary (शुभ, मंगल, मंदिर, etc.).

| Layer | Status |
|---|---|
| Brief §8 Constraint 10 | ✅ Correct |
| SAD | ✅ No UI copy in SAD; forbidden-list referenced in ADR-010 |
| PRD | ✅ All story example strings use permitted vocabulary; forbidden list enforced at standing rule layer |
| Epics List | ✅ No UI copy |
| UX Spec §5.6 | ✅ Forbidden vocabulary list codified + extended v1.1 with mythic/sanskritized forbidden list (शुभ, मंगल, मंदिर, धर्म, पूज्य, आशीर्वाद, तीर्थ, स्वागतम्, उत्पाद, गुणवत्ता, श्रेष्ठ, सर्वोत्तम) |
| Bundle v1.1 | ✅ Cross-check in README §"Cross-checks" — zero uses of forbidden mythic words; only permitted everyday warmth (धन्यवाद, विश्वास, स्वागत without म्, आपका); verified AE A4 cleared विश्वास |

**Gate 3 — R10 (forbidden udhaar vocabulary):** ब्याज, देय तिथि, क़िस्त, etc.

| Layer | Status |
|---|---|
| Brief §9 R10 | ✅ Correct |
| SAD ADR-010 | ✅ Forbidden-field-names enforced at security rule layer |
| PRD Standing Rule 9 | ✅ Enforces udhaar vocabulary discipline |
| Epics List §11 rule 9 | ✅ Codified |
| UX Spec §5.6 | ✅ Forbidden list enforced on copy (both Hindi and English) |
| Bundle v1.1 | ✅ README §"Cross-checks" — zero forbidden words in S4.10 affordances (क्या मैं इस ग्राहक को याद दिलाऊँ? / याद दिलाया गया / कितने दिन बाद) or B1.13 (बाकी is the only permitted form) |

**Gate 4 — I6.12 partition discipline:** Freezed sealed unions enforce the SAD §9 field-partition.

| Layer | Status |
|---|---|
| SAD §9 | ⚠️ → ✅ Pre-patch used stale `CustomerProjectPatch` / `OperatorProjectPatch` naming + missing System variant. Patched to canonical `ProjectCustomerPatch` / `ProjectOperatorPatch` / `ProjectSystemPatch` with extension to ChatThread and UdhaarLedger acknowledged. |
| PRD Standing Rule 11 | ✅ Correct naming |
| PRD I6.12 | ✅ Correct naming |
| PRD C3.4 AC #8 | ✅ References Standing Rule 11 compliance |
| PRD S4.18 AC #1 + #7 | ✅ References `ProjectSystemPatch` Cloud Function trigger |
| Epics List §11 item 11 | ✅ Correct naming |
| UX Spec §8.18 | ✅ References `ProjectCustomerPatch` / `ProjectOperatorPatch` / `ProjectSystemPatch` |
| Bundle `components_library.dart` line 727 comment | ✅ References `ProjectCustomerPatch` discipline (UdhaarLedgerCard's operator-owned fields stay out of customer-authored writes) |
| Bundle README §"Cross-checks" I6.12 | ✅ Partition posture documented per new widget |

**Gate 5 — Triple Zero (`amountReceivedByShop == totalAmount`):** No commission, no fees, no reduction.

| Layer | Status |
|---|---|
| Brief §3 + §8 | ✅ Triple Zero as operational discipline |
| SAD §5 Project schema (v1.0.4 F3 patch) | ✅ `amountReceivedByShop` field added as invariant-enforceable |
| PRD C3.4 AC #4 | ✅ Triple Zero invariant: `amountReceivedByShop == totalAmount` enforced in commit transaction |
| PRD C3.5 AC #8 | ✅ Triple Zero UPI URI invariant: `am=` equals `totalAmount`, `pa=` equals `shop.upiVpa`, no commission/fee/MDR parameter |
| Epics List §6 C3.4 row | ✅ Refs `SAD v1.0.4 §5 finding F3` |
| UX Spec §4.9 commit flow | ✅ No commission UX affordance |
| Bundle | ✅ No commission UI; `UpiPayButton` (v1.0 existing) uses `am={totalAmount}` literally per I6.6 AC contract |

**Gaps found:** 1 🟡 (Brief §4.3 line 422, Mary to patch). All other layers now enforce all 5 compliance gates consistently post-Phase-6 patches.

**Rating after patches:** ✅

---

### Criterion 11 — Sprint sequencing feasibility (new for v1.2)

**Rating:** ⚠️ (feasible with caveat — see §12 below for full analysis)

**Summary:** Sprint 1 now has 4 stories totaling 3 × XL + 1 × M of complexity (I6.1, I6.4, I6.12, I6.10). The Epics List v1.2 §2 says "I6.12 lands in Sprint 1 alongside I6.4 — it's a same-week engineering task for the repository layer." That is technically correct because I6.12 is a repository-layer refactor building on top of I6.4's multi-tenant scoping. But the combined surface area for a 2–3 engineer team in 2 weeks is heavy.

See §12 for the detailed feasibility analysis with three remediation options.

**Rating:** ⚠️ (not a blocker — see remediation options in §12)

---

## §4 — Walking Skeleton Coverage Audit (19 stories × 5 coverage points)

Verified each of the 19 Walking Skeleton stories against all 5 coverage points: (a) PRD entry, (b) Epics List sprint slot, (c) UX Spec §8 strategic note, (d) Mockup in `walking-skeleton.html`, (e) Design Bundle component reference.

| # | Story | PRD | Epics | UX §8 | Mockup | Bundle | Sprint |
|---|---|:---:|:---:|:---:|:---:|:---:|:---:|
| 1 | **I6.1** — AuthProvider adapter scaffolding | ✅ L103 | ✅ §3 | ✅ §8.1 | n/a (infra) | ✅ `auth_provider.dart` ref in tokens README | **1** |
| 2 | **I6.2** — Anonymous → Phone Auth UID merger | ✅ L132 | ✅ §3 | ✅ §8.2 | n/a (infra) | ✅ flow note in bundle | 2 |
| 3 | **I6.3** — Refresh-token session persistence | ✅ L163 | ✅ §3 | ✅ §8.3 | n/a (infra) | ✅ session persistence doc | 2 |
| 4 | **I6.4** — Multi-tenant shopId scoping | ✅ L192 | ✅ §3 | ✅ §8.4 | n/a (infra) | ✅ `shop_theme_tokens.dart` synthetic shop_0 | **1** |
| 5 | **I6.10** — Crashlytics + Analytics + App Check | ✅ L388 | ✅ §3 | ✅ §8.19 *(Phase 6 IR v1.2 patch — was missing pre-patch)* | n/a (infra) | ✅ instrumentation ref | **1** |
| 6 | **I6.12** — Offline field-partition discipline *(v1.0.5)* | ✅ L451 | ✅ §3 | ✅ §8.18 | n/a (infra) | ✅ comment line 727 in components_library.dart | **1** |
| 7 | **B1.1** — First-time customer onboarding | ✅ L492 | ✅ §4 | ✅ §8.5 | ✅ #s1 splash + #s2 landing | ✅ `BharosaLanding` widget | 2 |
| 8 | **B1.2** — Anonymous landing with face | ✅ L524 | ✅ §4 | ✅ §8.6 | ✅ #s2 | ✅ `_BharosaHero` + Presence Dock | 2 |
| 9 | **B1.3** — Greeting voice note auto-play | ✅ L555 | ✅ §4 | ✅ §8.7 | ✅ #s3 | ✅ `_GreetingCard` widget | 3 |
| 10 | **B1.4** — Curated shortlists (finite) | ✅ L588 | ✅ §4 | ✅ §8.8 | ✅ #s4 | ✅ `CuratedShortlistCard` | 3 |
| 11 | **B1.5** — SKU detail with Golden Hour | ✅ L620 | ✅ §4 | ✅ §8.9 | ✅ #s5 | ✅ `GoldenHourPhotoView` | 3 |
| 12 | **C3.1** — Create Project draft | ✅ L1169 | ✅ §6 | ✅ §8.10 | ✅ #s6 | ✅ Project draft view | 4 |
| 13 | **C3.4** *(v1.0.5 updated)* — Commit + Phone OTP | ✅ L1257 | ✅ §6 | ✅ §8.11 | ✅ #s9 | ✅ commit-screen styles | 5 |
| 14 | **C3.5** *(v1.0.5 updated)* — UPI payment intent | ✅ L1293 | ✅ §6 | ✅ §8.12 | ✅ #s10 | ✅ `UpiPayButton` | 5 |
| 15 | **P2.4** — Sunil-bhaiya Ka Kamra chat thread | ✅ L1009 | ✅ §5 | ✅ §8.13 | ✅ #s7 | ✅ `ChatBubble` (balance scale) | 4 |
| 16 | **P2.5** — Customer sends text message | ✅ L1044 | ✅ §5 | ✅ §8.14 | ✅ #s8 | ✅ `HindiTextField` | 4 |
| 17 | **S4.1** — Shopkeeper Google sign-in | ✅ L1560 | ✅ §7 | ✅ §8.15 | ✅ #s12 | ✅ ops-signin styles | 3 |
| 18 | **S4.3** — Inventory create new SKU | ✅ L1622 | ✅ §7 | ✅ §8.16 | ✅ #s13 | ✅ form-screen styles | 4 |
| 19 | **S4.5** — Golden Hour photo capture | ✅ L1688 | ✅ §7 | ✅ §8.17 | ✅ #s14 | ✅ camera styles | 5 |

**Coverage verdict:** 19 of 19 Walking Skeleton stories have full 5-coverage across PRD / Epics / UX Spec / mockup (where user-visible) / bundle. Infrastructure stories (I6.1, I6.2, I6.3, I6.4, I6.10, I6.12 — 6 of 19) correctly have `n/a` in the mockup column because they have no visual surface.

**v1.1 → v1.2 delta:** I6.10 moved from `✅ implicit` to `✅ §8.19` via the Phase 6 patch.

---

## §5 — Cross-Document Inconsistencies Found & Patches Applied

Eleven patches were applied in this Phase 6 IR check. Each is documented here with location, the contradiction, the resolution, and provenance.

### Patch 1 — PRD headline "66" → "67" arithmetic correction

**Where:**
- PRD frontmatter line 9 (status string)
- PRD §Preamble line 35 ("Total v1 story count is 66")
- PRD §v1.0.5 patch note line 2424 ("58 → 66")
- PRD footer line 2433 ("Total stories: 66 unique")
- Epics List §1 line 30 (the arithmetic flag itself)
- Epics List v1.2 patch note line 647 ("59 → 66")
- Epics List end-of-file line 706 ("66 unique stories")
- Epics List frontmatter status (line 9)
- Epics List §1 cross-tenant line 73 ("53 of 66 stories")

**The contradiction:** PRD v1.0.5 patch note said "58 → 66" but the v1.1 baseline was **59** (post-S4.13 added in v1.0.4), not 58. 59 + 8 new stories = **67**, not 66. The per-epic mechanical count (E6:12 + E1:13 + E2:8 + E3:12 + E4:17 + E5:5) resolves to 67. Epics List v1.2 explicitly flagged this ("the per-epic breakdown is 67, not 66; the drift comes from PRD v1.0.5's '58 → 66' patch note taking the v1.0 baseline instead of the v1.1 baseline; the correct total is 67").

**Investigation method:** Enumerated all PRD v1.0.5 story headers via regex `^### \*\*(I6|B1|P2|C3|S4|M5)\.[0-9]+`. Results:
- E6: I6.1, I6.2, I6.3, I6.4, I6.5, I6.6, I6.7, I6.8, I6.9, I6.10, I6.11, I6.12 → **12** ✅
- E1: B1.1 through B1.13 → **13** ✅
- E2: P2.1 through P2.8 → **8** ✅
- E3: C3.1 through C3.12 → **12** ✅
- E4: S4.1, S4.2, S4.3, S4.4, S4.5, S4.6, S4.7, S4.8, S4.9, S4.10, S4.11, S4.12, S4.13, S4.16, S4.17, S4.18, S4.19 (S4.14 v1.5-deferred, S4.15 reserved) → **17** ✅
- E5: M5.1 through M5.5 → **5** ✅
- **Total: 12 + 13 + 8 + 12 + 17 + 5 = 67**

**Resolution:** Patched PRD (5 locations) from 66 to 67 with provenance notes. Patched Epics List (4 locations) from 66 to 67 with provenance notes. Patched the dependent count "53 of 66 stories" → "52 of 67 stories" (the cross-tenant exclusion list was always 15 items, not 13 — another arithmetic drift). All patches cite Phase 6 IR Check v1.2 as provenance.

**Severity:** Minor (number drift; no architectural or scope impact). But substantively important because the arithmetic flag was explicit in Epics List v1.2 and demanded resolution.

### Patch 2 — PRD I6.9 AC #4 stale "Noto Sans Devanagari and Mukta fonts"

**Where:** PRD line 373 (I6.9 AC #4).

**The contradiction:** Brief v1.4 §8 Constraint 4 (line 305) specifies the Tiro Devanagari Hindi + Mukta + Fraunces + EB Garamond + DM Mono stack. The PRD I6.9 acceptance criterion still said "Noto Sans Devanagari and Mukta" which is the v1.0 stack, rejected in Brief v1.4 per the v1.4 patch note.

**Resolution:** Rewritten AC #4 to the Constraint 4 stack with explicit payload budgets (≤100 KB Devanagari pair + ≤60 KB English pair) matching UX Spec §7.2 item 1.

### Patch 3 — PRD I6.9 edge case #1 runtime-fallback semantics

**Where:** PRD line 380 (I6.9 edge case #1).

**The contradiction:** Original wording ("falls back to system Noto Sans Devanagari (slower load, but renders)") was ambiguous — it could be read as "we ship Noto Sans Devanagari as a bundled asset" which contradicts Constraint 4. UX Spec §7.2 item 5 clarifies this is a RUNTIME fallback only (cheap Android phones bundle Noto Sans Devanagari as the system face; Flutter's glyph-missing detection falls back to the system font at runtime; the app never ships with Noto as a bundled asset).

**Resolution:** Rewritten edge case #1 with explicit runtime-fallback-only semantics matching UX Spec §7.2 item 5. Added the `font_fallback_triggered` Crashlytics event (which UX Spec §7.2 already mandates) to the PRD layer.

### Patch 4 — PRD I6.9 edge case #3 stale font reference

**Where:** PRD line 382 (I6.9 edge case #3 "Noto Sans Devanagari subset corrupts during build").

**Resolution:** "Noto Sans Devanagari" → "Tiro Devanagari Hindi or Mukta".

### Patch 5 — PRD "Handoff Notes for Amelia" stale counts

**Where:** PRD lines 2363–2364 ("17 stories above" and "10 rules in the preamble").

**The contradiction:** The v1.0.3 patch added I6.10 (17 → 18), the v1.0.5 patch added I6.12 (18 → 19) and Standing Rule 11 (10 → 11), but the Handoff Notes section was never updated.

**Resolution:** 17 → 19 (with v1.0.5 provenance) and 10 → 11 (with v1.0.5 provenance).

### Patch 6 — Epics List §11 item 5 "10 PRD standing rules" → "11"

**Where:** Epics List line 602.

**The contradiction:** v1.2 patch note correctly adds Standing Rule 11, the §11 list correctly includes item 11 as the new rule, but the intro text at item 5 still references "10 PRD standing rules."

**Resolution:** "10" → "11" with v1.2 provenance.

### Patch 7 — SAD §1 line 59 Typography bullet stale font stack

**Where:** SAD line 59 (Locked Stack bullet).

**The contradiction:** Same root cause as Patch 2 — the SAD §1 Typography bullet is the very top-of-document summary of the stack and was not updated in Phase 1 AE v1.0.4.

**Resolution:** Rewritten to Brief v1.4 Constraint 4 stack with Phase 6 IR Check v1.2 provenance.

### Patch 8 — SAD §3 line 317 CSS comment stale

**Where:** SAD line 317 (in the `marketing-site/assets/devanagari.css` comment block).

**Resolution:** "Subset-loaded Noto Sans Devanagari" → "Subset-loaded Tiro Devanagari Hindi + Mukta".

### Patch 9 — SAD §5 + §8 schema examples stale `fontFamilyDevanagari`/`fontFamilyEnglish`

**Where:** SAD line 1117 (§5 `ShopThemeTokens` schema) and line 2438 (§8 `ShopThemeTokens` annotated duplicate).

**The contradiction:** Both schema examples used the old 2-field form (`fontFamilyDevanagari: "Noto Sans Devanagari"` + `fontFamilyEnglish: "Inter"`) while the Brief Constraint 4 / UX Spec / Design Bundle all use the new 5-field form (`fontFamilyDevanagariDisplay` + `fontFamilyDevanagariBody` + `fontFamilyEnglishDisplay` + `fontFamilyEnglishBody` + `fontFamilyMono`).

**Resolution:** Both schema examples rewritten to the 5-field form with provenance. This also brings the SAD into structural agreement with the bundle's actual `ShopThemeTokens` Freezed class.

### Patch 10 — SAD §9 sealed-union naming drift

**Where:** SAD §9 line 2646 (paragraph after the field-partition table).

**The contradiction:** SAD §9 v1.0.4 AE patch wrote `CustomerProjectPatch` / `OperatorProjectPatch` (2 variants) but the downstream canonical naming used by PRD Standing Rule 11, PRD I6.12, PRD C3.4 AC #8, PRD S4.18 AC #1 + #7, Epics List §11 item 11, UX Spec §8.18, and Bundle `components_library.dart` line 727 is `ProjectCustomerPatch` / `ProjectOperatorPatch` / `ProjectSystemPatch` (3 variants, noun-adjective-patch pattern with explicit System variant).

**Investigation method:** Grep for `ProjectCustomerPatch|ProjectOperatorPatch|ProjectSystemPatch|CustomerProjectPatch|OperatorProjectPatch|SystemProjectPatch` across all planning artifacts. SAD was the only document still using the old naming. All downstream layers had already converged on the canonical naming.

**Resolution:** SAD §9 paragraph rewritten to use the canonical downstream naming + explicitly add the `System` variant + acknowledge the extension to `ChatThread` and `UdhaarLedger` per PRD Standing Rule 11. Provenance cited.

### Patch 11 — UX Spec §5.5 heading "45 grounded examples" → "50" and §7.6 item 6 "30 example strings" → "50"

**Where:** UX Spec line 1176 (§5.5 heading) and line 1569 (§7.6 item 6).

**The contradiction:** §5.5 heading says "45 grounded examples" but the table underneath actually contains strings #1 through #50 (verified by enumeration of row numbers in the table). The v1.1 patch note at line 1178 correctly states "extended from 30 to 45 strings" — but that arithmetic is also stale (it should be 50 per the actual table). §7.6 item 6 still references "all 30 example strings" from the v1.0 baseline.

**Resolution:** §5.5 heading 45 → 50 with Phase 6 IR Check provenance. §7.6 item 6 30 → 50 with Phase 6 IR Check provenance. Both point at the actual table which is canonical.

### Patch 12 — UX Spec §8.19 I6.10 strategic note added

**Where:** UX Spec §8 added as new §8.19.

**The contradiction:** §8 header promises "19 Walking Skeleton Screens — Strategic Notes" but the body had 18 notes (8.1 through 8.17 + 8.18 I6.12). I6.10 (Crashlytics + Analytics + App Check) had no dedicated §8 entry. IR Check v1.1 had accepted this as "✅ implicit" but Criterion 6 in v1.2 demands explicit coverage.

**Resolution:** Appended §8.19 — I6.10 — Crashlytics + Analytics + Performance + App Check strategic note covering the "not user-visible" posture, "the one thing that must not happen" for each of the 4 sub-systems (Crashlytics, Analytics, App Check, Performance), and cross-references to §7.5 device testing matrix + §7.2 item 5 font-fallback Crashlytics event pipeline.

### Patches NOT applied (deliberately)

- **Brief §4.3 line 422 stale Typography bullet** — flagged as 🟡 for Mary. Outside Phase 6's surgical-edit permission envelope (Brief is Mary's).
- **The "I6.7 feature flag load" vs Sprint 1 dependency timing note** — left as a feasibility observation in §12, not patched here because the Epics List v1.2 Sprint 1 plan explicitly names I6.10 in Sprint 1 and the practical resolution is for Amelia to scaffold Crashlytics / Analytics / App Check without a full I6.7 real-time wire-up.
- **`v1.0.5` patch note line 2424 residual "58 → 66" phrasing** was rewritten to "59 → 67" as part of Patch 1 above.

---

## §6 — Open Questions Still Outstanding

These are known-and-parked. NOT blockers, but Amelia should be aware of them.

### From Sally's UX Spec Q1–Q9 *(v1.1 extended from Q1–Q7)*

| # | Question | Status |
|---|---|---|
| Q1 | Finite vs paginated curated shortlists | **CLOSED** — patched in PRD v1.0.2 |
| Q2 | Where does the English toggle live? | **CLOSED** — patched in PRD v1.0.3 B1.2 AC #9 (top-right EN/हिं switch, landing + profile only) |
| Q3 | Large-text + DC interaction | Sally has clear recommended answer; Alok has not explicitly approved |
| Q4 | Missing-away-voice-note elder tier | Sally has clear recommended answer; Alok has not explicitly approved |
| Q5 | `commsChannelStrategy = whatsapp` redirect vs CTA | Sally recommends CTA; Alok has not explicitly approved |
| Q6 | Shopkeeper SMS quota monitor alert | Sally recommends yes (positive framing); Alok has not explicitly approved |
| Q7 | `awaiting_verification` customer-side banner | Sally has clear recommended answer; Alok has not explicitly approved |
| **Q8** *(v1.1)* | B1.13 Mukta-italic signature — fallback "handwritten" enough? | **OPEN** — Sally recommends in-app Mukta-italic is sufficient for v1; v1.5 can add captured-signature-image path if B1.13 customer feedback demands it |
| **Q9** *(v1.1)* | S4.17 NPS card — only bhaiya, or beta / munshi quarterly variant too? | **OPEN** — Sally recommends bhaiya-only for v1 (one NPS source of truth); revisit post-Month 6 |

### From Frontend Design Bundle Open Decisions D1–D5

| # | Question | Status |
|---|---|---|
| D1 | Shopkeeper Presence Dock — top or bottom anchored? | **LOCKED** (bottom) per v1.1 |
| D2 | Greeting voice note auto-play vs tap-to-play? | **LOCKED** (auto-play with mute toggle) per v1.1 |
| D3 | Marketing site map — Static Maps vs placeholder? | **LOCKED** (static placeholder for v1) per v1.1 |
| D4 | Real photo of Sunil-bhaiya vs illustration? | **OPEN BLOCKER for Sprint 3** — consent to be confirmed before Sprint 3 (B1.2 / B1.3) ships. Sprint 1 + 2 are unaffected. |
| D5 | Brand name hyphenation? | **LOCKED** (no hyphenation, A/B test in real usage) per v1.1 |

### From brief / SAD / PRD planning chain

| # | Question | Status |
|---|---|---|
| Q-A through Q-E | All 5 PQs | **LOCKED** in PRD v1.0.2 per Alok's "lock all" directive |
| **Step 0.1** | **Shopkeeper LOI signed** | **OPEN — load-bearing for Sprint 4+** (real customer data against flagship shop). Sprint 1 + 2 + 3 can run against synthetic `shop_0`. |
| Step 0.6 | **Hindi-native design capacity verification** | **OPEN — load-bearing for Sprint 1 kickoff** via Sprint 0 I6.11 gate. See `sprint-0-i6-11-checklist.md`. END STATE A or END STATE B must close before Sprint 1 Day 1. |
| Step 0.7 | Firebase phone auth billing screenshot | OPEN, deferred; R8 swappable adapter unblocks |
| Step 0.9 | RBI legal review of udhaar khaata | OPEN, deferred to pre-launch; ADR-010 defensive design unblocks |

---

## §7 — Sprint 1 Pre-Flight Checklist (4 stories, re-validated from v1.1)

Updated for the 4-story Sprint 1 (I6.1, I6.4, I6.10, I6.12 per Epics List v1.2 §2) + Sprint 0 precondition.

### Sprint 0 precondition (v1.2 NEW)

- [ ] **I6.11 Hindi-native design capacity verification** — END STATE A (capacity secured + verification artifact signed at `docs/runbook/hindi_design_capacity_verification.md`) **OR** END STATE B (Constraint 4 scope reduction + `defaultLocale` Remote Config flipped `"hi"` → `"en"` + Crashlytics `constraint_15_fallback_triggered` logged + Sunil-bhaiya verbally notified). Execute via `sprint-0-i6-11-checklist.md`.

### Infrastructure setup (unchanged from v1.1)

- [ ] Three Firebase projects created: `yugma-dukaan-dev`, `-staging`, `-prod` (ADR-001 + ADR-007)
- [ ] Each project upgraded to Blaze plan
- [ ] Each project has Cloud Billing budget configured at $1/month with email + SMS alerts at $0.10, $0.50, $1.00 (ADR-007)
- [ ] Each project has Pub/Sub topic `budget-alerts` subscribed (SAD §7 Function 1)
- [ ] App Check enabled with Play Integrity (Android) + DeviceCheck (iOS) (SAD §1 + I6.10)
- [ ] Firebase service account credentials for marketing site read-only Firestore fetch (locked Q4 + `fetch_shop_content.ts`)
- [ ] Cloudinary account with free tier (25 credits/month) + signed upload preset (ADR-006)
- [ ] Domain `yugmalabs.ai` + subdomain `sunil-trading-company.yugmalabs.ai`

### Repo setup (unchanged from v1.1)

- [ ] Monorepo initialized with `melos.yaml`
- [ ] `packages/lib_core` + `apps/customer_app` + `apps/shopkeeper_app` + `sites/marketing` + `functions/` per SAD §3
- [ ] `pubspec.yaml` with Riverpod 3, GoRouter, Freezed 3, Material 3, intl, firebase_core, cloud_firestore, firebase_auth, firebase_storage, firebase_app_check, firebase_messaging, firebase_analytics, firebase_crashlytics, firebase_remote_config, google_sign_in
- [ ] `analysis_options.yaml` with BMAD recommended lints + cross-tenant custom lint (ADR-012)
- [ ] GitHub Actions: `ci-flutter.yml`, `ci-marketing.yml`, `ci-cloud-functions.yml`, `ci-cross-tenant-test.yml`, `deploy-staging.yml`

### Design system pre-flight (updated for v1.0.5 / v1.1 bundle)

- [ ] Font files downloaded: **Tiro Devanagari Hindi, Mukta (3 weights), Fraunces (italic), EB Garamond (regular + italic), DM Mono (regular + 500)** *(per Brief v1.4 Constraint 4 / Phase 6 IR patches — NOT Noto Sans Devanagari)*
- [ ] `tools/generate_devanagari_subset.sh` built
- [ ] Initial subset run completed (≤100 KB Devanagari + ≤60 KB English)
- [ ] `packages/lib_core/lib/src/theme/` populated with `tokens.dart`, `shop_theme_tokens.dart`, `yugma_theme_extension.dart` from the v1.1 bundle *(tokens unchanged in v1.1 per design discipline)*
- [ ] `packages/lib_core/lib/src/components/` populated with `bharosa_landing.dart`, the extended `components_library.dart` (17 widgets including 8 new v1.1 widgets), and **new `invoice_template.dart` (807 lines)** *(v1.1 add)*
- [ ] Freezed code generation run (`dart run build_runner build`)

### Firestore setup (updated for SAD v1.0.4 schema additions)

- [ ] Firestore enabled in all 3 projects (native mode)
- [ ] `firestore.rules` copied from SAD v1.0.4 §6 (includes `shopIsWritable` helper + `feedback` sub-collection rule + existing rules)
- [ ] `firestore.indexes.json` from SAD v1.0.4 §5 index spec
- [ ] **Synthetic `shop_0` tenant seeded** via `tools/seed_synthetic_shop_0.ts` — must include the new v1.0.4 schema fields: `shopLifecycle: "active"`, `dpdpRetentionUntil: null`, `previousProjectIds` (empty array on customer docs), `amountReceivedByShop` (on test project docs), `feedback` sub-collection (empty)
- [ ] **Cross-tenant integrity test** at `packages/lib_core/test/cross_tenant_integrity_test.dart` — **extended to include I6.12 partition-crossing compile-time checks** *(v1.2 add — Freezed sealed union negative-compile tests in `test/fails_to_compile/`)*
- [ ] **`media_usage_counter/{shopId}` counter document seed** (SAD §7 Function 7 dependency — the MediaStore adapter will increment this; seed with `cloudinary_{yyyy-mm}: 0`, `storage_{yyyy-mm}: 0`)

### Cloud Functions setup (updated for 8-function inventory)

- [ ] `functions/` package initialized with TypeScript + firebase-functions v2 + firebase-admin
- [ ] **8 Cloud Functions scaffolded** per SAD v1.0.4 §7: `killSwitchOnBudgetAlert`, `generateWaMeLink`, `sendUdhaarReminder` (with RBI guardrails), `multiTenantAuditJob`, `firebasePhoneAuthQuotaMonitor`, `joinDecisionCircle`, **`mediaCostMonitor` (v1.0.4 new, audit gap #3)**, **`shopDeactivationSweep` (v1.0.4 new, audit gap #2)**
- [ ] **`triggerMarketingRebuild`** Cloud Function scaffolded per locked Q4
- [ ] **`sendUdhaarReminder` RBI-guardrail enforcement:** function reads `reminderOptInByBhaiya`, `reminderCountLifetime`, `reminderCadenceDays` per SAD v1.0.4 Function 3 + PRD S4.10 AC #7/#8/#9

### Pre-flight items needing Alok's input

- [ ] **Sprint 0 I6.11 — Hindi capacity gate closure** (NEW for v1.2; load-bearing for Sprint 1 kickoff)
- [ ] **D4 — Real Sunil-bhaiya consent for face photo** on customer app + marketing site (load-bearing for Sprint 3)
- [ ] **Step 0.1 — Shopkeeper LOI** signed (load-bearing for Sprint 4+ real customer data)
- [ ] **D1, D2, D3, D5 locked as "yes"** from Bundle README (Alok's explicit confirmation — all already recommended defaults)
- [ ] **Mary's patch of Brief §4.3 stale font reference** (one-line fix; 30 seconds) — 🟡 only, not a blocker

---

## §8 — Recommendation to Alok

**Single decisive recommendation: hand off to Amelia for Phase 7 (Sprint 1 resume) after two pre-flight actions close, both owned by Alok personally.**

The 6-phase BMAD back-fill has produced a substantially stronger planning bundle than v1.0. Three AE-gated personas (Winston, John, Sally) plus the frontend-design plugin have all run Advanced Elicitation + Party Mode on their respective artifacts, closing 9 brief→PRD audit gaps, adding 8 new PRD stories, 3 new SAD ADRs, 2 new Cloud Functions, 6 new UX interaction patterns, 20 new Hindi strings, 8 new bundle widgets plus a new file, and 6 new mockups. The 11 surgical patches I applied in this Phase 6 IR check close the remaining drift without re-litigating any load-bearing decision.

**Pre-flight actions needed from Alok before Amelia starts Sprint 1:**

1. **Close Sprint 0 I6.11 Hindi capacity gate.** Execute `sprint-0-i6-11-checklist.md` to END STATE A (Hindi capacity secured + signed verification artifact) or END STATE B (Constraint 4 scope reduction accepted + Remote Config flag flipped + Sunil-bhaiya notified). Estimated wall-clock time: 1–2 weeks if END STATE A via Option B (contracted reviewer) or Option C (copywriter); same day if END STATE B. **This is the critical-path blocker for Sprint 1 Day 1.** The team cannot write UX-touching code until this closes, and per I6.11 AC #5 I will halt Sprint 1 and escalate if it has not closed by Sprint 1 Day 1.
2. **Lock D4 (Sunil-bhaiya face photo consent)** before Sprint 3 B1.2 implementation. Has 2–4 weeks of slack; is NOT Sprint 1 blocking. Answer can be: (a) "yes, real face with written consent" or (b) "no, use the Devanagari-initial-circle fallback the bundle already supports" or (c) "ask again later." Any of the three unblocks downstream work.

**Parallel action needed from Mary (30-second patch):**

3. **Patch Brief §4.3 line 422** stale "Typography: Noto Sans Devanagari / Mukta as primary; Inter or Roboto as English secondary" to match Brief v1.4 §8 Constraint 4. This is the one 🟡 finding of this IR check. Brief is outside Phase 6's surgical-edit permission envelope so I did not touch it. Mary can patch in under 60 seconds. Not a Sprint 1 blocker because Amelia will read §8 Constraint 4 (which is the normative source) and the patched SAD / PRD / UX Spec / bundle.

**Suggested next-action sequence:**

1. **Now (5 min):** Alok reads this IR report v1.2 executive verdict + §12 Sprint 1 feasibility analysis and decides on the Sprint 1 sequencing option.
2. **Now (10 min):** Mary applies the Brief §4.3 patch (or accepts the residual 🟡).
3. **Now → 2 weeks:** Alok executes Sprint 0 I6.11 checklist to END STATE A or B. Use `sprint-0-i6-11-checklist.md`.
4. **After Sprint 0 closes:** Amelia re-reads the patched bundle (PRD v1.0.5, SAD v1.0.4, Epics List v1.2, UX Spec v1.1, Bundle v1.1, this IR report v1.2) and begins Sprint 1 implementation.
5. **During Sprint 1–2:** Alok finalizes D4 consent decision.

**What I am NOT recommending:**
- ❌ Another AE round on any artifact — the 6-phase back-fill has exhausted AE's marginal value on these documents
- ❌ A v1.6 PRD / v1.0.5 SAD / v1.3 Epics List / v1.2 UX Spec / v1.2 Bundle revision — no substantive gaps found
- ❌ Waiting for the LOI before Sprint 1 — Sprint 1 + 2 + 3 run against synthetic `shop_0` by design
- ❌ Splitting Sprint 1 pre-emptively — §12 below recommends a specific mitigation that preserves the 2-week boundary

The planning bundle is in the cleanest state it has ever been in. Time to ship.

---

## §9 — Audit-Gap Closure Trace (NEW for v1.2)

Full trace table for the 9 brief→PRD audit gaps at every downstream layer they touch.

| Gap | Severity | Brief ref | SAD | PRD | Epics List | UX Spec | Bundle | Status |
|---|---|---|---|---|---|---|---|---|
| **#1** Hindi capacity gate | 🔴 | Constraint 15 + §12 Step 0.6 | ADR-008 v1.0.4 clarification + `FeatureFlags.defaultLocale` | **I6.11** (S) | §3 E6 + §2 Sprint 0 | §8.0 | Sprint 0 checklist `sprint-0-i6-11-checklist.md` (operational) | ✅ CLOSED at every layer |
| **#2** DPDP shop deactivation | 🔴 | §9 R16 + Constraint 13 DPDP | ADR-013 + §5 Shop `shopLifecycle` state machine + §6 `shopIsWritable` helper + §7 Function 8 `shopDeactivationSweep` | **C3.12** (M) + **S4.19** (S) paired | §6 E3 + §7 E4 + §2 Sprint 6 paired | §4.12 + §4.14 + §6.7 + §6.9 | `ShopDeactivationBanner` + `ShopDeactivationFaqScreen` + `ShopDeactivationTap1Page` + `ShopDeactivationTap2ReasonPicker` + `showShopDeactivationConfirmDialog` + `ShopReversibilityCard` + mockups `#s19` + `#s21` + `#s21b` | ✅ CLOSED at every layer |
| **#3** Cloudinary cost telemetry | 🔴 | §9 R3 + §6 Month 9 gate | ADR-014 + §7 Function 7 `mediaCostMonitor` | **S4.16** (L) | §7 E4 + §2 Sprint 5 | §4.15 + §6.10 | `MediaUsageTile` + mockup `#s22` | ✅ CLOSED at every layer |
| **#4** Devanagari invoice | 🟠 | §3 Bharosa "plain dignified invoices" + Constraint 4 | ADR-015 client-side PDF | **B1.13** (M) | §4 E1 + §2 Sprint 5 | §4.11 + §6.6 | `invoice_template.dart` (807 lines) — `InvoiceTemplate` + `InvoiceTextOnlyFallback` + 7 state variants + mockups `#s18` + `#s18b` | ✅ CLOSED at every layer |
| **#5** NPS + burnout | 🟠 | §6 Month 6 success gate + §9 R1 burnout kill-gate | §5 `feedback` sub-collection + §6 feedback rule | **S4.17** (M) | §7 E4 + §2 Sprint 5 | §4.13 + §6.8 | `NpsCard` + mockup `#s20` | ✅ CLOSED at every layer |
| **#6** wa.me Project context | 🟠 | §3 chat in WhatsApp channel | §7 Function 2 `generateWaMeLink` v1.0.4 clarification paragraph | (no new PRD story — existing P2 stories suffice) | (existing E2 coverage) | (existing §4.7 coverage) | (existing CommsChannel adapter) | ✅ CLOSED at SAD layer; downstream unaffected |
| **#7** Repeat customer | 🟠 | §6 Month 9 gate "repeat customer rate observable" | §5 Customer.previousProjectIds capped array | **S4.18** (M) | §7 E4 + §2 Sprint 5 | (analytics plumbing; no UX surface beyond S4.11 dashboard tile) | (no new widget; dashboard tile extension) | ✅ CLOSED at every layer |
| **#8** Offline conflict resolution | 🟠 | §9 R-implicit (tier-3 offline) | §9 field-partition table + offline replay invariants + ADR-004 | **I6.12** (XL) + **Standing Rule 11** | §3 E6 + §2 Sprint 1 + §9 cross-epic graph edge to E2/E3/E4 + §11 rule 11 | §8.18 | `components_library.dart` line 727 comment + UdhaarLedgerCard partition posture doc | ✅ CLOSED at every layer |
| **#9** Zero-commission math | 🔴 | §3 Triple Zero + Differentiator #1 | §5 Project.amountReceivedByShop invariant | **C3.4 AC #4** (`amountReceivedByShop == totalAmount`) + **C3.5 AC #8** (UPI URI invariant) | §6 E3 C3.4 + C3.5 rows with SAD F3 refs | §4.9 commit flow (no commission UX affordance) | `UpiPayButton` uses `am={totalAmount}` literally per adapter contract | ✅ CLOSED at every layer |

**Verdict:** 9 of 9 audit gaps closed at every layer they touch. No downstream gap.

---

## §10 — AE Patch Trace (NEW for v1.2)

Verified that every Phase 1–5 AE finding that landed as a patch survived end-to-end without contradiction. Spot-checked representative findings; full per-finding trace is in §3 Criterion 9 above.

**Summary by phase:**

| Phase | Artifact | AE findings landed | Findings verified in downstream | Status |
|---|---|---|---|---|
| Phase 1 | SAD v1.0.4 | 12 (F1, F2, F3, F4, F7, F8, F9, F11, F12, F13, F14, F15) | 10 reflected in PRD v1.0.5 (F1→C3.12+S4.19, F2→S4.16, F3→C3.4 AC#4 + C3.5 AC#8, F8→I6.12 + SR11, F9→I6.7 AC#7, F11→S4.10 AC#7-#9, F12→I6.11, F13→B1.13, F14→S4.17, F15→S4.18); F4 + F7 were SAD-internal clarifications not requiring PRD stories | ✅ All landed |
| Phase 2 | PRD v1.0.5 | 11 beyond Winston handoff (F-P1, F-P2, F-P3, F-PM1, F-PM2, F-PM3, F-CC1, F-CC2, F-CR1, F-CR2, F-CR3, F-WI1, F-WI2, F-WI3) | All 11 visible in PRD story AC revisions; 4 specifically reflected in UX Spec v1.1 + Bundle v1.1 (F-P3→NPS casual copy, F-P2→FAQ export CTA, F-PM3→S4.19 reversibility, F-CR3→S4.18 churn threshold) | ✅ All landed |
| Phase 3 | Epics List v1.2 | Not an AE round (pure re-derivation) | N/A | ✅ |
| Phase 4 | UX Spec v1.1 | 14 findings (F1–F15 per v1.1 patch note table) | All 14 documented in §4 / §5 / §6 / §8 per UX Spec v1.1 patch note + 4 of them (F11, F12, F14, F15) specifically reflected in Bundle v1.1 | ✅ All landed |
| Phase 5 | Bundle v1.1 | 15 AE findings (A1–A15 per README v1.1 patch note table) | 7 patched in code (A1, A3, A5, A6, A7, A12, A14), 8 confirmed no-patch-needed (A2, A4, A8, A9, A10, A11, A13, A15). Token discipline held — zero new tokens added. | ✅ All landed; no downstream layer |

**Cross-phase contradictions found:** **None.** Every downstream layer reflects every upstream AE patch that it should.

**Gaps found:** None.

---

## §11 — Compliance Gate Enforcement (NEW for v1.2)

See §3 Criterion 10 above for the full 5-gate table. Summary:

- **Gate 1 — Constraint 4 (font stack):** ⚠️ → ✅ after 9 Phase 6 patches (1 🟡 Brief §4.3 left open for Mary)
- **Gate 2 — Constraint 10 ("show don't sutra"):** ✅ every layer
- **Gate 3 — R10 (forbidden udhaar vocabulary):** ✅ every layer
- **Gate 4 — I6.12 partition discipline:** ⚠️ → ✅ after SAD §9 naming drift patch
- **Gate 5 — Triple Zero (`amountReceivedByShop == totalAmount`):** ✅ every layer

Post-Phase-6, 4 of 5 gates are at ✅ every layer. Gate 1 has one 🟡 at the Brief layer only, which Mary can patch in 60 seconds.

---

## §12 — Sprint 1 Feasibility Analysis (NEW for v1.2)

**The question:** Given Brief Constraint 13 (small team: 2–3 engineers + 1 designer, contracted in-house) and the Epics List v1.2 §2 Sprint 1 plan of 4 stories (I6.1 XL + I6.4 XL + I6.10 M + I6.12 XL), is Sprint 1 shippable in 2 weeks?

**Raw complexity sum:** 3 × XL + 1 × M. Epics List v1.2 §1 complexity definitions:
- XL = 10+ days, foundational, blocks others, requires team coordination
- M = 2–5 days, multi-screen or non-trivial logic

Naive arithmetic: 3 × 10+ days + 3 days = **33+ engineer-days of work in a 2-week (≈10 engineer-days per engineer × 3 engineers = 30 engineer-days) sprint**.

**The good news — why this is actually achievable:**

1. **I6.1 and I6.4 are interface-scaffold stories, not feature implementations.** Their "XL" rating is about the design-and-coordination load, not the lines of code. I6.1 scaffolds an abstract `AuthProvider` interface with one Firebase implementation; I6.4 scaffolds the multi-tenant path structure + synthetic `shop_0` seed + cross-tenant CI test. Both are 3–5 days of focused work, not 10+.

2. **I6.12 is a same-engineer-week extension of I6.4.** The Epics List v1.2 §3 explicitly notes: "I6.12 Offline-first field-partition discipline — Repository-layer refactor alongside I6.4 — same engineer-week." The sealed-union Freezed classes are generated code; the repository methods are simple wrappers around Firestore calls with type-safe patches. The actual engineering work is: define 3 sealed classes per entity (Project, ChatThread, UdhaarLedger) = 9 sealed union types + 9 repository methods + negative-compilation tests in `test/fails_to_compile/`. That's 3–4 days of one engineer's focused work, not an independent 10-day XL.

3. **I6.10 is plumbing — SDK initialization, config files, CI wiring.** 2–3 days max for one engineer who already knows Firebase.

4. **The work parallelizes cleanly across 3 engineers.**
   - **Engineer A (lead):** I6.1 + integration glue. 6–8 days.
   - **Engineer B (repository):** I6.4 foundation → I6.12 sealed unions. 7–9 days.
   - **Engineer C (platform):** I6.10 Firebase SDK wiring + CI setup + cross-tenant test scaffolding. 5–6 days.
   - **Designer (contracted):** writes `tokens.dart` integration tests, verifies the Bundle's token files compile and the theme extension materializes on a blank screen. 4–5 days.

5. **The Bundle design system is already complete.** Amelia doesn't have to write `tokens.dart` / `shop_theme_tokens.dart` / `yugma_theme_extension.dart` from scratch — she copies from `frontend-design-bundle/lib_core/theme/` and runs build_runner. That saves 2–3 engineer-days.

**The bad news — why this is risky:**

1. **Sprint 1 has no user-visible deliverable.** At the end of 2 weeks, the founder sees... an AuthProvider interface that compiles, a multi-tenant path structure with CI tests passing, Crashlytics connected, and Freezed sealed unions that reject cross-partition patches at compile time. No screen. No UI. **This is a psychological risk for a small team working for a flagship shopkeeper client who expects visible progress.** Mitigation: Sprint 1 Day 1 stand-up should explicitly set this expectation.

2. **I6.12 is new in v1.0.5 and has no existing implementation precedent in the codebase.** Amelia is writing the sealed union pattern for the first time. There's a learning-curve cost. Mitigation: Epics List §3 I6.12 row cites the SAD v1.0.4 §9 field-partition table as authoritative; the PRD Standing Rule 11 explicitly names every field in each partition; the UX Spec §8.18 names the user moment being protected. Amelia has unusually complete scaffolding for a "new pattern" story.

3. **I6.10 depends on I6.7 for Remote Config wire-up, but I6.7 is technically scheduled for Sprint 2 per the Epics List graph.** This is a subtle dependency-order concern. **Practical resolution:** I6.10 can scaffold Crashlytics + Analytics + App Check without the real-time Firestore kill-switch listener wire-up. The real-time listener is part of I6.7 and lives in Sprint 2; I6.10 in Sprint 1 uses a minimal Remote Config client that polls once at boot (standard Firebase Remote Config posture, no real-time listener). Amelia should note this in the Sprint 1 implementation plan.

4. **Sprint 0 I6.11 is a real gating event.** If Alok cannot close Sprint 0 in 1–2 weeks, Sprint 1 does not start. This is not a Sprint 1 feasibility concern per se, but it is a calendar-wall risk that compounds.

**Three remediation options (ranked):**

**Option 1 — RECOMMENDED — Ship Sprint 1 as 4 stories, with an explicit "I6.10 scaffolds without I6.7 real-time listener" note in the Sprint 1 Day 1 plan.**

- Engineers A/B/C parallelize per the allocation above.
- Designer contracts (or in-house designer) writes the theme integration tests.
- I6.10 implementation uses minimal Remote Config polling; the real-time Firestore listener wire-up is deferred to I6.7 in Sprint 2 without any Sprint 1 rework.
- Sprint 1 exit criteria remain as stated in Epics List v1.2 §2: "AuthProvider interface compiles. Synthetic shop_0 tenant exists. Cross-tenant integrity test runs and passes. Freezed sealed unions for Project/ChatThread/UdhaarLedger field-partition compile and reject cross-partition patches at compile time. Negative-compilation test cases in `test/fails_to_compile/` pass. CI is green."
- Risk: tight but achievable. Requires all 3 engineers + designer ready on Day 1.

**Option 2 — CONSERVATIVE — Split Sprint 1 into 1a (I6.1 + I6.4 + I6.10) and 1b (I6.12).**

- 1a ships in 2 weeks, standard 3-story sprint.
- 1b ships in 1 additional week (5–6 engineer-days for the sealed union work).
- Total: 3 weeks to reach the current Sprint 1 exit criteria.
- Month 3 gate timeline slips by 1 week per Brief §6 (not catastrophic if buffered).

**Option 3 — AGGRESSIVE — Move I6.10 to Sprint 2 alongside I6.7 so both Remote Config + real-time listener ship together; Sprint 1 keeps I6.1 + I6.4 + I6.12 as a tight 3-XL sprint.**

- Sprint 1 has zero telemetry on Day 1 of the build. First real Crashlytics event fires 2 weeks later.
- Risk: if Sprint 1 has a crash or a silent regression, we have no Crashlytics coverage.
- Not recommended for a production-track engagement.

**My recommendation: Option 1.** Ship Sprint 1 as the 4-story plan with the I6.10-without-I6.7-realtime note. The Bundle design system + the exceptionally complete scaffolding (PRD Standing Rule 11 naming every partition field, UX Spec §8.18 + §8.19 explaining the UX implications, SAD §9 field-partition table) makes I6.12 more achievable than its "XL" rating suggests. The risk is manageable if Amelia front-loads the engineer allocation decision on Sprint 1 Day 1.

**Rating for Criterion 11 (Sprint sequencing feasibility):** ⚠️ (feasible with caveats; remediation options documented; not a blocker for handoff to Phase 7).

---

## §13 — 66↔67 Reconciliation (required task for this IR check)

**Investigation method:** Enumerated all PRD v1.0.5 story headers via regex `^### \*\*(I6|B1|P2|C3|S4|M5)\.[0-9]+` and counted by epic:

- **E6:** I6.1, I6.2, I6.3, I6.4, I6.5, I6.6, I6.7, I6.8, I6.9, I6.10, I6.11, I6.12 → **12 stories**
- **E1:** B1.1, B1.2, B1.3, B1.4, B1.5, B1.6, B1.7, B1.8, B1.9, B1.10, B1.11, B1.12, B1.13 → **13 stories**
- **E2:** P2.1, P2.2, P2.3, P2.4, P2.5, P2.6, P2.7, P2.8 → **8 stories**
- **E3:** C3.1, C3.2, C3.3, C3.4, C3.5, C3.6, C3.7, C3.8, C3.9, C3.10, C3.11, C3.12 → **12 stories**
- **E4:** S4.1, S4.2, S4.3, S4.4, S4.5, S4.6, S4.7, S4.8, S4.9, S4.10, S4.11, S4.12, S4.13, S4.16, S4.17, S4.18, S4.19 → **17 stories** (S4.14 is v1.5-deferred, S4.15 is reserved/unused in v1)
- **E5:** M5.1, M5.2, M5.3, M5.4, M5.5 → **5 stories**

**Sum: 12 + 13 + 8 + 12 + 17 + 5 = 67**

**The canonical correct total is 67.**

**Root cause of the drift:** PRD v1.0.5 patch note stated "Total: 58 → 66" using the v1.0 baseline (58) instead of the v1.1 baseline (59 post-S4.13 added in v1.0.4). Against the correct baseline: 59 + 8 new v1.0.5 stories = **67**, not 66.

**Decision:** Canonical correct total is 67. PRD headline (all 5 occurrences) and dependent Epics List references (4 occurrences) + the cross-tenant count ("53 of 66 stories" → "52 of 67 stories", exclusion list was always 15 not 13) patched from 66 to 67 with Phase 6 IR Check v1.2 provenance notes.

**Artifacts patched:**
- `prd.md` frontmatter line 9, preamble line 35, patch note line 2424, footer line 2433 (4 locations — 5th was a duplicate consolidated in patch note)
- `epics-and-stories.md` frontmatter line 9, §1 backlog summary line 30, §1 cross-tenant count line 73, v1.2 patch note line 647, end-of-file line 706 (5 locations)

Total: 9 locations patched to resolve the arithmetic drift.

**Verification:** Post-patch `grep "\b66\b"` on PRD and Epics List returns only matches inside phrases like "corrected from stale 66" or the historical `v1.0.1 footer corrected from 47` reference — no remaining canonical claim of 66.

---

## §14 — Verdict for Phase 7 (Amelia resumes Sprint 1)

**🟢 GREEN LIGHT — proceed to Phase 7 once Sprint 0 I6.11 closes.**

The 6-artifact planning bundle is aligned, traceable, compliance-gated, and executable. The 11 Phase 6 patches close the minor drift the back-fill introduced without re-litigating any decision. The 19-story Walking Skeleton has full 5-coverage end-to-end. The 9 brief→PRD audit gaps are closed at every layer. The AE patches from Phases 1/2/4/5 survived end-to-end without contradiction. Sprint 1 is feasible with the Option 1 remediation and a small-team-of-3 parallel allocation.

**Amelia's pre-Sprint-1 reading list (in order):**

1. This IR report v1.2 (15 min — executive verdict + §4 Walking Skeleton coverage + §7 pre-flight checklist + §12 feasibility analysis)
2. `sprint-0-i6-11-checklist.md` (10 min — understand the Sprint 0 gate closure posture)
3. PRD v1.0.5 Standing Rules (5 min — 11 rules, especially Rule 11 field-partition)
4. PRD v1.0.5 §Walking Skeleton (5 min — 19 stories with coverage)
5. SAD v1.0.4 §3 (monorepo structure), §4 (auth flows 1–5 including Decision Circle join), §5 (Firestore schema — especially Shop lifecycle fields, Project.amountReceivedByShop, Customer.previousProjectIds, feedback sub-collection), §6 (security rules including shopIsWritable), §7 (all 8 Cloud Functions), §9 (field-partition table + offline replay invariants) — 45 min
6. Epics List v1.2 §2 (Sprint Plan — 15 min)
7. UX Spec v1.1 §7 (accessibility, especially §7.5 device testing matrix including new v1.1 additions for B1.13/C3.12/S4.17/S4.19/S4.16/S4.10 states) — 10 min
8. Bundle README v1.1 (20 min — especially §"v1.1 patch note" file-by-file delta + cross-checks + verdict for Phase 6)
9. Bundle `lib_core/theme/tokens.dart` + `shop_theme_tokens.dart` + `yugma_theme_extension.dart` (10 min — read to understand the token system; these files are unchanged from v1.0)
10. Bundle `lib_core/components/invoice_template.dart` header comment + `components_library.dart` new widget header comments (15 min) — understand the partition discipline comments

**Estimated total pre-Sprint-1 reading time: ~2.5 hours.** After this, Amelia has complete context to start Sprint 1 implementation.

**Handoff complete. Phase 7 unblocked pending Sprint 0 I6.11 closure.**

---

**End of Implementation Readiness Report v1.2 — Phase 6 re-validation.**

**Total length:** ~7,100 words
**Verdict:** 🟢 READY FOR PHASE 7 (Amelia resumes Sprint 1) after Sprint 0 I6.11 closure + Mary's Brief §4.3 🟡 patch
**Patches applied during this IR check:** 11 surgical (1 × arithmetic reconciliation across 9 locations + 4 × PRD/SAD font-stack corrections + 1 × SAD sealed-union naming drift + 3 × stale count drift + 1 × UX Spec §8.19 coverage gap + 1 × cross-tenant count propagation)
**Blocking issues:** 0
**Open questions awaiting Alok:** 11 (Q3–Q7, Q8–Q9 from Sally; D4 from bundle; Step 0.1, Step 0.6, Step 0.7, Step 0.9 from Brief)
**Sprint 0 precondition:** I6.11 Hindi capacity gate (execute `sprint-0-i6-11-checklist.md`)
**Sprint 1 unblockedness:** ✅ all 4 stories (I6.1, I6.4, I6.10, I6.12) can ship with Option 1 allocation per §12

— BMAD Implementation Readiness Check v1.2, facilitated by John (PM), 2026-04-11 (Phase 6 BMAD back-fill re-validation)
