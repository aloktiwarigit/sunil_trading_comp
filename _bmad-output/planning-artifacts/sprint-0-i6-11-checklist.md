---
artifact: Sprint 0 — I6.11 Hindi-Native Design Capacity Verification Checklist
audience: Alok (founder, Yugma Labs) — owner of this checklist
purpose: Single decision document for executing the I6.11 governance gate before Sprint 1 Day 1
version: v1.0
date: 2026-04-11
status: Action required — must close before Sprint 1 Day 1 OR before any UX-touching code lands
inputs:
  - Brief v1.4 §8 Constraint 15
  - Brief v1.4 §12 Step 0.6
  - PRD v1.0.5 I6.11
  - SAD v1.0.4 ADR-008 (v1.0.4 clarification paragraph)
  - SAD v1.0.4 §5 FeatureFlags `defaultLocale`
---

# Sprint 0 — I6.11 Hindi-Native Design Capacity Verification

> **TL;DR** — Before Sprint 1 begins, you must either secure Hindi-native design capacity OR explicitly accept a Constraint 4 scope reduction by flipping a Remote Config flag. There are exactly two acceptable end states. Anything else blocks Sprint 1 from starting.

---

## Why this exists

Brief Constraint 4 commits the customer app and shopkeeper app to **Hindi (Devanagari) primary, English secondary** with a specific font stack: Tiro Devanagari Hindi + Mukta + Fraunces + EB Garamond + DM Mono. Brief Constraint 15 acknowledges that this is **only honest if someone on the team can actually read, write, and judge Hindi** at a near-native level. If no one can, the team will silently drift to "English with Hindi labels," which is structurally worse for the 4 personas (Sunita-ji, Aditya, Geeta-ji, Rajeev) than picking English-first deliberately and saying so.

The Brief therefore says: *"If none of the three Hindi-capacity options is secured by the design kickoff date, v1 narrows to English-first with a Hindi toggle — explicitly breaking Constraint 4."*

PRD I6.11 turns that into a binding gate: **Sprint 1 cannot start until one of the two end states below is reached.**

---

## The two acceptable end states

### END STATE A — Hindi capacity secured

**Definition:** at least one of the three options below has been confirmed in writing with a named person and a specific scope, and that person has passed the vetting protocol in §3.

**Effect:** Sprint 1 begins normally. Constraint 4 stands. The Devanagari font stack ships as designed. Sally and the frontend-design plugin's existing UX Spec v1.1 + Frontend Design Bundle remain canonical without modification.

### END STATE B — Constraint 4 scope reduction accepted

**Definition:** none of the three options can be secured in time, AND you have explicitly accepted the consequence by:
1. Flipping the Remote Config flag `defaultLocale` from `"hi"` to `"en"` in the dev/staging/prod Firebase consoles
2. Writing a one-line note in the project context file (`_bmad-output/planning-artifacts/`) recording the date, the reason, and the named person who decided
3. Logging the Crashlytics event `constraint_15_fallback_triggered` so the team has telemetry that the fallback is active
4. Notifying Sunil-bhaiya in person (NOT WhatsApp, NOT phone) that the customer app will launch with English-first text and a Hindi toggle, not the reverse, and getting his explicit "ठीक है" before Sprint 2 ships any user-visible screen.

**Effect:** Sprint 1 begins normally. Constraint 4 is documented as broken. The customer app default locale is English. The Hindi toggle is still wired up (because the localization architecture supports it cleanly per ADR-008 v1.0.4) — the team just doesn't claim it's Hindi-first. The 4 personas get a worse experience but the team isn't lying about it.

**This is not a failure end state.** It is a deliberate tradeoff acknowledged in writing. The Brief explicitly permits it.

---

## §1 — The three Hindi capacity options (pick at least one)

These are from Brief Constraint 15 verbatim, expanded with realistic vetting and effort details for the Yugma Labs scale (one person hiring, no recruiting budget).

### Option A — In-house designer fluent in Devanagari visual design

**What it looks like:** the existing designer on the small team (1 designer per Constraint 13) is themselves Hindi-native or near-native, can read Devanagari without subvocalization, can write Devanagari naturally, can judge whether a Mukta italic actually looks like a signature or like a font bug, and has visual taste for Devanagari typography (kerning, line height, vowel mark spacing).

**How to verify:**
- They produce one screen of original Devanagari layout in Tiro Devanagari Hindi at body size, using only the Brief Constraint 4 font stack, and you (or the vetting partner in §3) confirm it reads naturally to a Hindi-native eye
- They explain in Hindi (spoken or written) what `मात्रा` and `अनुस्वार` are and why they affect line height
- They flag at least one issue with the existing Frontend Design Bundle's Devanagari rendering that you didn't notice before

**Realistic time to confirm:** same week if the existing designer fits; never if they don't (you cannot retrain).

**Cost:** zero incremental cost — they're already on the team.

**Risk:** the existing designer says "yes I can do Hindi" out of politeness and then can't. Mitigate by making them do the verification screen FIRST, not after they've been told this matters.

### Option B — Contracted Hindi-fluent design reviewer

**What it looks like:** an external reviewer (freelancer, consultant, friend of the founder, design school faculty) who is paid per-review to inspect screens before they ship and call out anything that reads as English-translated-to-Hindi rather than written-in-Hindi.

**Profile to look for:**
- Native Hindi speaker (NOT just "fluent in Hindi")
- Comfortable in Devanagari at reading and writing speed equal to English
- Has design or editorial background (NOT a translator — translators flatten voice)
- Available for a 4-week intensive (Sprint 1 + Sprint 2 = the highest-risk window) and then on-call for spot reviews thereafter
- Geographic preference: Lucknow, Allahabad, Varanasi, Ayodhya (Awadhi-Hindi register matches the customer base; Delhi/Mumbai Hindi is structurally formal in ways that hurt the warmth Brief §3 calls for)

**Where to find them:**
1. **Design schools in tier-2/3 cities** — NID Ahmedabad has UP-origin alumni; Banaras Hindu University (BHU) has a Faculty of Visual Arts; Lucknow University runs design programs. Reach out to faculty for student/alumni names.
2. **Bilingual journalists** — Hindi newspaper journalists (Dainik Jagran, Amar Ujala, Hindustan) at the city-edition level often have an editorial eye and side-project bandwidth. They write Hindi for a North-Indian audience daily.
3. **Hindi advertising copywriters** — agencies in Lucknow / Kanpur / Allahabad. The good ones are expensive but you don't need a long contract.
4. **Your existing personal network** — anyone in your circle from Lucknow, Allahabad, Banaras, or eastern UP whose first language is Hindi and who has a design/editorial sensibility. The personal-network path is faster and cheaper than the formal channels.

**Realistic time to confirm:** 1–2 weeks of outreach + a paid trial review of 5 screens.

**Cost rough estimate:** ₹8,000–₹25,000 for a 4-week intensive at typical UP-tier-2 freelance rates, depending on background. Less if you find a friend-of-friend; more if you go via an agency.

**Risk:** the reviewer is competent but slow, blocking design sprints. Mitigate by setting a turnaround SLA in the contract (24-hour review window) and a fallback reviewer.

### Option C — Awadhi-Hindi copywriter for 4 weeks

**What it looks like:** you hire a copywriter (NOT a designer, NOT a reviewer) for a 4-week sprint to write all the user-facing strings for v1 in Awadhi-flavored Hindi from scratch — not translate them from English. The 50 strings in UX Spec v1.1 §5.5 become their working brief. They produce:
1. Hindi for the existing 50 strings (validated against the Workshop Almanac voice)
2. ~30 additional strings for Sprint 2–6 stories that don't have copy yet
3. A short "voice & tone primer" written in Hindi explaining how Sunil-bhaiya talks vs how a corporate brand talks, so future strings stay in voice

**Profile:** same as Option B but skewed copywriter-not-designer. A Hindi journalist with creative-writing chops is the ideal candidate.

**Realistic time to confirm:** 1–2 weeks outreach + 1 week trial output + 4 weeks main engagement = 6–7 weeks total. This is the **longest** option but produces the **most durable** asset (a Hindi voice library Sunil's team can extend later without you involved).

**Cost rough estimate:** ₹15,000–₹40,000 for the 4-week intensive.

**Risk:** the copywriter delivers a beautiful Hindi voice that's culturally tone-deaf to a Tier-3 wedding mother. Mitigate by having them write 5 sample strings BEFORE you hire and showing those samples to a real shopkeeper or wedding mother for the gut-check. If a real Sunita-ji says "हाँ, ऐसे ही बात होती है" (yes, this is how people talk), hire. If she says "क्यों इतना formal?" (why so formal), pass.

---

## §2 — The decision tree

```
START
  │
  ├─→ Is your existing designer Hindi-native? 
  │      ├─→ YES → run the verification screen (Option A vetting)
  │      │         ├─→ passes → END STATE A (in-house) ✅
  │      │         └─→ fails  → continue
  │      └─→ NO  → continue
  │
  ├─→ Do you have 1–2 weeks before Sprint 1 Day 1 to do outreach?
  │      ├─→ YES → run Option B outreach in parallel with Option C
  │      │         ├─→ Option B candidate passes vetting → END STATE A (contractor) ✅
  │      │         ├─→ Option C candidate passes vetting → END STATE A (copywriter) ✅
  │      │         └─→ neither passes by Day 1 → END STATE B (fallback) ✅
  │      └─→ NO  → END STATE B (fallback) ✅
  │
  └─→ END STATE A or B
        └─→ either way, Sprint 1 unblocked
```

**Key insight:** END STATE B is not a failure. It is one of two acceptable end states. The only failure mode is **silently drifting toward broken Constraint 4 without anyone noticing or owning the decision.** This checklist exists to make sure that doesn't happen.

---

## §3 — Vetting protocol (apply to any candidate, all 3 options)

A 30-minute conversation that surfaces whether the candidate is actually Hindi-native or just claims to be. Run it for every candidate before any contract or commitment.

### Step 1 — The reading test (5 minutes)

Hand the candidate the existing UX Spec v1.1 §5.5 strings #31 and #37:

> #31 — `धन्यवाद, आपका विश्वास हमारा भविष्य है`
>
> #37 — `सुनील भैया की दुकान बंद हो रही है — आपका पैसा वापस आ जाएगा, आपका डेटा {N} दिन तक सुरक्षित है`

Ask them to **read aloud** without preparation. Watch for:
- ✅ Natural, fluent reading at conversational pace
- ⚠️ Subvocalization, finger-tracing, slow word-by-word — fluent reader but not native
- ❌ Hesitation on `विश्वास` or `सुरक्षित` — not fluent enough for the role

### Step 2 — The register test (10 minutes)

Show them this sentence in two versions and ask which sounds more like how a real Lucknow / Ayodhya wedding mother would talk in person:

> Version 1: `मुझे नई अलमारी की आवश्यकता है, जो उच्च गुणवत्ता की हो`
>
> Version 2: `मुझे एक नई अलमारी चाहिए, अच्छी वाली`

A native Hindi speaker from UP will say Version 2 immediately and explain Version 1 sounds like a Hindi exam textbook. If they say Version 1 or hesitate, **they are not the right person** — they will write English-translated-to-Hindi for the entire app.

### Step 3 — The voice match test (10 minutes)

Show them this Brief §3 quote about the Bharosa pillar:

> *"Sunil-bhaiya is not curating a brand, he's curating his customers' children's weddings."*

Ask them to write **one sentence in Hindi** that captures the same idea, in a voice Sunil-bhaiya himself might use to a wedding mother. No prep, no looking things up.

A right answer sounds like everyday warmth: `हम सिर्फ अलमारी नहीं बेचते — हम आपके बच्चों की शादी की पहली खुशी का हिस्सा हैं` (we don't just sell almirahs — we are part of the first joy of your children's wedding). Note: zero `शुभ`, zero `मंगल`, zero formal Hindi, no temple framing.

A wrong answer sounds like advertising or temple language. Common red flags: `शुभ अवसर`, `मंगलमय`, `सर्वोत्तम गुणवत्ता`, `विशेष क्षण`.

### Step 4 — The forbidden vocabulary test (5 minutes)

Show them the udhaar khaata UX Spec entry. Ask: **what words should NEVER appear on this screen?**

A right answer names: `ब्याज` (interest), `पेनल्टी` (penalty), `बकाया तारीख` (due date), `देरी का जुर्माना` (late fee), `ऋण` (loan), `वसूली` (collection). They should also explain WHY without prompting: an udhaar khaata is a relationship instrument, not a lending instrument; the moment you use lending vocabulary, you trigger RBI exposure and you damage Sunil-bhaiya's relationship with the customer.

If they don't immediately understand the distinction, walk them through it once. If they still don't get it after the explanation, **they are not the right person** — they will accidentally introduce one of these words later.

### Step 5 — The verdict

Pass criteria:
- Step 1: ✅ natural reading
- Step 2: ✅ picks Version 2 immediately
- Step 3: ✅ no forbidden mythic vocabulary, sounds like a real person not an ad
- Step 4: ✅ knows the forbidden vocabulary or learns it in one explanation

If all 4 pass: **hire**. If any fail: **pass** and try the next candidate. Better to delay than to hire wrong.

---

## §4 — What to do if no candidate passes by Sprint 1 Day 1

This is **END STATE B — Constraint 4 scope reduction.** Steps:

1. **Open the dev Firebase console** for `yugma-dukaan-dev`. Navigate to Remote Config. Find the parameter `defaultLocale`. Change its default value from `"hi"` to `"en"`. Publish the change.
2. **Repeat for `yugma-dukaan-staging` and `yugma-dukaan-prod`.** All three must agree.
3. **Write a short note** at `_bmad-output/planning-artifacts/constraint-15-fallback-decision.md` with this template:

   ```markdown
   # Constraint 15 Fallback — Triggered

   **Date:** YYYY-MM-DD
   **Decided by:** Alok
   **Reason:** [one line — couldn't secure Hindi capacity in time / candidates didn't pass vetting / etc.]
   **Reversal plan:** when Hindi capacity is secured (post-Sprint-1), flip `defaultLocale` back to `"hi"` and re-validate the 50 strings in UX Spec §5.5 against the new reviewer.
   ```

4. **Verify the Crashlytics event** `constraint_15_fallback_triggered` fires on next app launch. (This requires I6.10 to be live, so the verification happens after Sprint 1 Day 5 not Day 1 — note this in the fallback file.)
5. **Visit Sunil-bhaiya in person** (NOT phone, NOT WhatsApp). Explain in Hindi:
   > `भैया, एक बात बतानी थी। हमने सोचा था कि app में पहले हिंदी होगी और फिर English option होगा। लेकिन अभी हमारे पास हिंदी की proper team नहीं है, तो हम पहले English में launch कर रहे हैं और हिंदी option दे रहे हैं। जब हिंदी team मिल जाएगी तो हम वापस हिंदी first कर देंगे। आपको ठीक है?`
   >
   > (Brother, I needed to tell you one thing. We had planned that the app would be Hindi-first with an English option. But right now we don't have a proper Hindi team, so we're launching with English first and giving a Hindi option. Once we find a Hindi team, we'll switch back to Hindi-first. Is that okay with you?)

   Get his explicit "ठीक है" before any user-visible screen ships in Sprint 2. If he says no, **pause Sprint 2 user-visible work and re-run Options A/B/C with more time.** This is the one place where the systematic-back-fill discipline must yield to the customer's actual voice.

---

## §5 — Definition of done for I6.11

- [ ] One of the two end states (A or B) is reached and documented in `_bmad-output/planning-artifacts/`
- [ ] If END STATE A: vetting protocol §3 was applied to the chosen candidate and they passed all 4 steps
- [ ] If END STATE B: `defaultLocale` Remote Config flag is `"en"` in all 3 environments AND `constraint-15-fallback-decision.md` exists AND Sunil-bhaiya has been notified in person AND has said "ठीक है"
- [ ] Decision is filed in the project context for Amelia's awareness on Sprint 1 Day 1
- [ ] Crashlytics monitoring is in place (or scheduled to come online with I6.10) so the team has telemetry on which mode the app is running in
- [ ] (If END STATE A) the chosen candidate has read this document and understood the forbidden vocabulary list (UX Spec v1.1 §5.5)

When all 5 boxes are checked, **I6.11 is closed**, and Sprint 1 can begin.

---

## §6 — What this checklist does NOT cover

- **Post-Sprint-1 design capacity scaling.** This checklist gets you through v1. v1.5 and v2 may need a different conversation as the team grows.
- **Translation of marketing copy.** The marketing site (sunil-trading-company.yugmalabs.ai) is a separate Astro project per ADR-011; its copy is fetched at build time from Firestore. The same Hindi capacity person who passes vetting can also review the marketing strings — but the work is sequenced separately.
- **Compensation negotiation.** The cost ranges in §1 are realistic estimates for UP tier-2 freelance rates as of 2026; actual rates depend on the candidate's profile and your relationship to them. Not in scope here.
- **Legal contracts.** If you go with Option B or C, get a one-page work-for-hire agreement so the strings produced are owned by Yugma Labs. Not in scope here.
- **Long-term Hindi voice library.** Option C is the closest thing to this but a real voice library is a v1.5 deliverable.

---

## End of checklist

This is a one-shot document. Do not modify it without recording the change. When I6.11 is closed (either end state), file the decision in `_bmad-output/planning-artifacts/` and update the PRD I6.11 story status.

— Amelia, drafted on behalf of Sprint 1 readiness, 2026-04-11
