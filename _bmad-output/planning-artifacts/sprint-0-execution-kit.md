---
artifact: Sprint 0 Execution Kit — Hindi-Capacity Gate
audience: Alok — executable in ~1 hour of actual hands-on work
purpose: Convert the abstract Constraint 15 checklist into concrete outreach messages, scope of work, vetting script, and decision rules you can actually use
version: v1.0
date: 2026-04-11
status: Ready to execute
companion_to: sprint-0-i6-11-checklist.md (the governance framework)
---

# Sprint 0 Execution Kit — Hindi-Capacity Gate

> The checklist tells you WHAT to decide. This kit tells you HOW to execute.
>
> Amelia's recommendation: **pick Option B (contracted Hindi-fluent design reviewer)**, do ~30 minutes of outreach today, ~30 minutes of vetting calls this week. If no candidate passes by the Sprint 0 deadline, fall back cleanly to END STATE B (flip `defaultLocale` to `"en"`). Both paths unblock Sprint 2 B1.1 + B1.2 within 2 weeks maximum.

---

## §1 — Why Option B over A and C

Quick decision rationale before you execute. Each option, cost, time-to-first-value, and why B wins at the current project state.

### Option A — in-house designer fluent in Devanagari

- **Cost:** ₹0 incremental (existing 1 designer on team per Constraint 13)
- **Time:** same-day verification OR same-day disqualification
- **Pros:** zero friction, already in team cadence
- **Cons:** unlikely. If your current designer was Hindi-native you'd already know. Running the vetting protocol on them just to confirm is worth doing *before* outreach — it's free — but don't wait on the result.
- **Verdict:** Run the §3 vetting protocol on your existing designer **today**. If they pass, skip Options B and C entirely. If they don't, move to B without further delay.

### Option B — contracted Hindi-fluent design reviewer (4-week intensive)

- **Cost:** ₹8,000–₹25,000 for the initial 4-week intensive, ~₹2,000/week on-call retainer thereafter
- **Time to first value:** 1–2 weeks of outreach + 3–5 days of vetting + contract = **~2 weeks wall-clock**
- **Pros:** lowest total cost, highest quality match, minimally disruptive to team cadence. Reviewer sits outside the build loop and only reads screens before ship. Durable asset — can continue as on-call reviewer through v1.5 and v2.
- **Cons:** depends on finding the right person. The right person exists but not in obvious places (not on LinkedIn, not on Upwork). You have to ask around in tier-2 / tier-3 editorial and design circles.
- **Verdict:** **This is the recommendation.** Highest quality-to-cost ratio. Sit down with this kit for 30 minutes today and send the outreach template to 4 places.

### Option C — Awadhi-Hindi copywriter (4-week intensive, writes from scratch)

- **Cost:** ₹15,000–₹40,000 for the 4-week intensive
- **Time to first value:** 1–2 weeks of outreach + 1 week trial + 4 weeks main engagement = **~7 weeks wall-clock**
- **Pros:** produces the most durable asset — a Hindi voice library Sunil-bhaiya's team can extend later without involving you
- **Cons:** slowest path, highest cost, most output-risky (a copywriter's voice may be beautiful but culturally tone-deaf to a tier-3 wedding mother). The 50 UX strings already exist in UX Spec v1.1 §5.5, so much of the "writing from scratch" value is already captured.
- **Verdict:** **Don't start here.** If Option B fails *and* you decide not to accept END STATE B, come back to this. But B is cheaper and faster.

### END STATE B — flip `defaultLocale` to `"en"` (Constraint 4 fallback)

- **Cost:** 5 minutes of Alok's time + one in-person conversation with Sunil-bhaiya
- **Time to first value:** same day
- **Pros:** immediate unblock, zero hiring friction, Sprint 2 B1.1 + B1.2 can ship this week
- **Cons:** explicitly breaks Constraint 4. The 4 personas (Sunita-ji, Amit-ji, Geeta-ji, Rajeev-ji) get an English-first experience instead of Hindi-first. This is a real product degradation — not a cosmetic one. The Bharosa pillar gets weaker.
- **Verdict:** **Acceptable as a fallback, not as a first choice.** Run Option B for 2 weeks. If nothing lands, flip the flag **with full conviction + in-person Sunil-bhaiya notification**. The Brief permits this and it's not dishonest.

### Decision rule

```
Day 0 (today)          →  Run Option A vetting on existing designer (30 min, free)
                          Simultaneously: start Option B outreach (30 min)
Day 3 (if no Option A) →  First Option B vetting calls scheduled
Day 7                  →  Decision point — who has responded, who to vet
Day 10–14              →  Option B candidate chosen, contract drafted, work starts
Day 14 (no B)          →  Flip to END STATE B. Notify Sunil-bhaiya in person.
                          Sprint 2 B1.1 + B1.2 unblocked either way.
```

---

## §2 — Where to search for Option B candidates

Concrete search targets. Ordered by expected signal-to-noise ratio.

### 2.1 Tier-1 targets (try first — 2-hour total effort)

**1. Your personal network.** Anyone in your circle from Lucknow, Allahabad, Banaras, Ayodhya, Varanasi, or eastern UP whose first language is Hindi AND who has any design or editorial background. Send each person the outreach template (§4) and ask "do you know anyone like this?" The answer will almost always be yes within 2 degrees of separation. **Expected response: 3–5 candidates within 48 hours.**

**2. NID Ahmedabad — UP-origin alumni.** National Institute of Design has a Faculty of Visual Communication program with many alumni from UP. Email alumni@nid.edu with the outreach template. Ask specifically for alumni from Hindi-belt states who are doing freelance design review work. **Expected response: 1–3 candidate names in 3–5 days.**

**3. Banaras Hindu University — Faculty of Visual Arts.** Faculty and final-year students at BHU's FVA program are trained in both visual design AND written Hindi at a level that makes them ideal. Contact the department head (find via the university site). The department's career placement cell is often happy to refer. **Expected response: 1–2 names in a week.**

**4. Ambedkar University Delhi — School of Design.** AUD has a strong Devanagari typography research cluster. Their School of Design faculty often freelances on the side. **Expected response: 1–2 names in a week.**

### 2.2 Tier-2 targets (if Tier-1 doesn't produce a match in a week)

**5. Hindi newspaper city-edition editors.** Dainik Jagran, Amar Ujala, Hindustan — specifically the Lucknow, Kanpur, Allahabad, or Varanasi city desks. Desk editors see dozens of Hindi manuscripts per week and have an editorial eye. Many take side projects. Email the city desk directly; the department head will forward internally if they don't have capacity themselves. **Expected response: 1 candidate in 1–2 weeks.**

**6. Advertising copy-cum-design freelancers in Lucknow / Kanpur / Patna.** Search Instagram + LinkedIn for "Hindi copywriter Lucknow" or "Hindi creative director [city]." The good ones are under-represented on Upwork/Fiverr and over-represented on Instagram where they post their work samples. Cold-DM them with the outreach template. **Response rate is lower but quality is high.**

**7. Tier-2 design consultancies in North India.** Small studios in Lucknow / Chandigarh / Jaipur that work with Hindi-publishing clients. A brief scope contract is often attractive to them between bigger projects. Search "design studio [city] hindi" on Google.

### 2.3 What NOT to do

- **Upwork / Fiverr** — optimized for tier-1 English tech work, nearly zero signal for Awadhi-Hindi design review
- **LinkedIn Premium InMail** — slow, expensive, and the good candidates are under-represented on LinkedIn
- **Generic translation services** — translators flatten voice. You need someone who writes Hindi *in* Hindi, not someone who translates English *to* Hindi
- **Delhi / Mumbai ad agencies** — they do great Hindi work but they charge 5–10× the tier-2 rate and their register is structurally formal ("sahib Hindi") in ways that hurt Brief §3's warmth requirement

---

## §3 — Vetting protocol (30-minute call per candidate)

Already detailed in `sprint-0-i6-11-checklist.md` §3, reformatted here as a conversational script you can follow on a Zoom / WhatsApp call without having to flip between documents.

### Opening (2 min)

> "नमस्ते, मेरा नाम आलोक है। मैं एक app बना रहा हूँ एक अलमारी की दुकान के लिए Ayodhya में। App पूरी तरह से हिंदी में है, और मुझे एक Hindi native reviewer चाहिए जो screens देखे ship होने से पहले। आपका time ~30 मिनट के लिए — क्या यह काम करेगा?"

Listen for:
- Does their Hindi sound fluent-conversational, or did they switch to English immediately?
- Did they understand "native reviewer" without me explaining?

### Test 1 — Reading (3 min)

> "मैं आपको दो Devanagari strings भेजता हूँ। कृपया उन्हें जोर से पढ़िए जैसे आप पहली बार देख रहे हों।"

Send them in WhatsApp:
1. `धन्यवाद, आपका विश्वास हमारा भविष्य है`
2. `सुनील भैया की दुकान बंद हो रही है — आपका पैसा वापस आ जाएगा, आपका डेटा {N} दिन तक सुरक्षित है`

**Pass criterion:** they read both aloud at natural conversational speed with no hesitation on `विश्वास`, `सुरक्षित`, or `भविष्य`. If you hear them subvocalize or sound out syllables, that's a fluent-but-not-native signal — polite thank-you and move on.

### Test 2 — Register (10 min)

> "मैं आपको एक sentence दिखाऊँगा, दो versions में। मुझे बताइए कौन सा एक real Lucknow की wedding mother के जैसा लगता है।"

Send:
- Version 1: `मुझे नई अलमारी की आवश्यकता है, जो उच्च गुणवत्ता की हो`
- Version 2: `मुझे एक नई अलमारी चाहिए, अच्छी वाली`

**Pass criterion:** they say Version 2 **immediately** and explain Version 1 sounds like a Hindi textbook. If they hesitate, explain, or pick Version 1, **they are not the right person.** This test kills 70% of candidates and that is by design.

### Test 3 — Voice match (10 min)

> "हमारी दुकान की एक tagline है: 'Sunil-bhaiya सिर्फ अलमारी नहीं बेचते — वो अपने customers के बच्चों की शादियों का हिस्सा हैं।' अगर आपको इसे 5-7 शब्दों में एक in-app सावधान note के लिए compress करना हो, आप कैसे लिखेंगे? कोई temple / shubh / mangal जैसे शब्द मत use करना — बस everyday trust वाली भाषा।"

**Pass answer pattern:**
- `भैया की दुकान, आपके परिवार का हिस्सा।`
- `हर खुशी में, आपके साथ।`
- `हमारा काम — आपका विश्वास।`

**Fail patterns (red flags):**
- `शुभ अवसर का पार्टनर` (uses `शुभ`, explicitly forbidden)
- `सर्वोत्तम अलमारी का चयन` (formal + "quality" framing, violates Constraint 10)
- `आपके मंगल के लिए` (mythic, forbidden)

### Test 4 — Forbidden vocabulary (5 min)

> "एक last test। हमारे app में एक udhaar khaata screen है — जहाँ shopkeeper याद रखता है कितना पैसा customer से आना है। मुझे बताइए — इस screen पर कौन से words कभी नहीं आने चाहिए, और क्यों?"

**Pass answer:** names `ब्याज` (interest), `ऋण` (loan), `पेनल्टी` (penalty), `बकाया तारीख` (due date), `वसूली` (collection). Explains that udhaar is a relationship instrument, not a lending instrument; using lending vocabulary triggers RBI exposure and damages Sunil-bhaiya's relationship with the customer.

**If they don't know why:** walk them through it once. If they still don't understand after explanation, they'll accidentally introduce one of these words later. **Don't hire.**

### Close (5 min)

If all 4 tests passed:
> "आप ठीक वो इंसान हैं जिसकी मुझे ज़रूरत है। मैं आपको एक 4-week scope भेजूँगा। Rate क्या सोच रहे हैं?"

If 1–2 tests failed:
> "आपके time के लिए धन्यवाद। हम कुछ और candidates से भी मिल रहे हैं; आपको अगले हफ्ते update करूँगा।"

No hurt feelings, no false promises.

---

## §4 — Outreach templates

Three templates for three audiences. Copy-paste ready. Bilingual (Hindi + English) because your target candidates are all fluently bilingual and prefer to read in Hindi but often reply in English.

### 4.1 Personal network referral ask (shortest)

**Send via WhatsApp to 10–15 people in your tier-2 UP personal network:**

```
नमस्ते [Name]-ji,

मैं एक app बना रहा हूँ Ayodhya की एक अलमारी shop के लिए। पूरा app हिंदी में है।

मुझे एक Hindi-native design reviewer चाहिए जो screens देखे ship होने से पहले — 4 week का छोटा contract, ~₹15-20k। Person को Awadhi / पूर्वांचली Hindi में natural feel चाहिए।

क्या आप किसी को जानते हैं — designer, journalist, copywriter, कोई भी? 30-minute वाला work है initially।

Thanks,
Alok
```

### 4.2 Institutional outreach (NID / BHU / AUD)

**Send via email to department contacts:**

```
Subject: Contract opportunity — Hindi-native design reviewer, 4 weeks

Respected [Dr. X / Prof. Y],

I am Alok Tiwari, founder of Yugma Labs. We are building a Hindi-first
digital storefront for an almirah shop in Ayodhya called Sunil Trading
Company — सुनील ट्रेडिंग कंपनी. The app is in Devanagari throughout,
targeted at the 45-55 year old wedding-planning mother in tier-3 North
India.

Our design and engineering team has the technical side covered, but
we need a Hindi-native design reviewer who can look at our screens
before they ship and catch anything that reads as "English translated
to Hindi" rather than "written in Hindi." The target voice register
is Awadhi / पूर्वांचली — plain, warm, everyday — not the formal
"sahib Hindi" that most urban agencies produce.

The engagement:
- Duration: 4-week intensive + on-call through v1 launch
- Workload: ~3-5 hours per week, mostly async screen reviews
- Compensation: ₹15,000-25,000 for the 4-week block (negotiable)
- Remote-friendly — all work happens over WhatsApp + video calls

I was hoping your department might know faculty members, recent
alumni, or current students who would be a good fit. The ideal
candidate has both a visual design sensibility AND native Hindi
writing capacity. Design background, editorial background, or
advertising-copy background all work equally well.

If you can point me at 1-2 names I would be grateful. I'm happy
to elaborate over a 15-minute call at your convenience.

धन्यवाद,

Alok Tiwari
Founder, Yugma Labs
[your phone number]
[your email]
```

### 4.3 Cold DM to Instagram / LinkedIn freelancer

**Send as a DM, keep it short:**

```
नमस्ते [Name],

आपका Hindi design work देखा — बहुत अच्छा लगा। एक छोटा contract
opportunity है: Ayodhya की एक almirah shop का Hindi-first app
बना रहे हैं, और एक Hindi-native reviewer चाहिए 4-week के लिए।
~₹15-25k, remote work, ~3-5 hours/week।

क्या आप interested हैं? अगर हाँ तो मैं details भेजता हूँ।

— Alok (Yugma Labs)
```

---

## §5 — Scope of work (one-pager to send candidates once they express interest)

**After a candidate responds "yes interested, send details" — send this one-pager:**

```markdown
# Yugma Dukaan — Hindi-Native Design Reviewer Scope of Work

## About the project

Yugma Dukaan is a Hindi-first mobile app for Sunil Trading Company
(सुनील ट्रेडिंग कंपनी), an almirah shop in Ayodhya's Harringtonganj
market. The customer app is used by wedding-planning mothers across
tier-3 North India to browse almirahs, consult Sunil-bhaiya, and
commit to purchases.

The entire app is in Devanagari primary, with an English toggle.
The voice should feel warm, plain, and rooted in everyday Awadhi /
पूर्वांचली Hindi — NOT Delhi / Mumbai sahib Hindi, and definitely
not English-translated-to-Hindi.

## The engagement

**Duration:** 4-week intensive starting [date], with on-call review
through v1 launch (approximately 3-4 months total).

**Commitment:** ~3-5 hours per week, flexible within the week.

**Format:** Asynchronous over WhatsApp + shared Google Drive, with
a 30-minute weekly Zoom check-in.

**Compensation:** ₹[NEGOTIATED] for the 4-week block, + ₹[NEGOTIATED]
per hour for on-call review after that. Paid via UPI / bank transfer
at the end of each 2-week block.

## What the reviewer will do

1. **Screen review (primary work)** — I'll send 5-10 screens per week
   as we build them, either as static mockups or as short videos. Your
   job is to read everything on the screen aloud in your head and tell
   me whether the Hindi feels natural. Flag anything that sounds like:
   - Formal textbook Hindi (सर्वोत्तम, उच्च गुणवत्ता, आवश्यकता)
   - Translated English (e.g., literal translations of "please," "tap
     here," "you can")
   - Mythic / religious framing (शुभ, मंगल, आशीर्वाद, मंदिर — NONE
     of these words should appear anywhere in our app)

2. **String rewrites (secondary)** — when you flag a string, also
   suggest a replacement. Short — 3-10 words. Natural. Example
   rewrites we've already done:
   - ❌ "मुझे नई अलमारी की आवश्यकता है, जो उच्च गुणवत्ता की हो"
   - ✅ "मुझे एक नई अलमारी चाहिए, अच्छी वाली"

3. **Voice drift audit (weekly)** — read the full set of UI strings
   we've accumulated (currently ~50, will grow to ~150 by v1 launch)
   and flag any two strings that sound like they were written by
   different people. Consistency matters.

4. **Forbidden vocabulary watch (standing rule)** — never allow these
   words to appear anywhere in the app's UI (not screens, not error
   messages, not notifications):
   - On the udhaar khaata screen: ब्याज, पेनल्टी, बकाया तारीख, ऋण,
     वसूली, क़िस्त, डिफ़ॉल्ट, देरी का जुर्माना
   - Anywhere: शुभ, मंगल, आशीर्वाद, मंदिर, तीर्थ, धर्म, श्रेष्ठ

5. **Optional — cultural context notes.** When you flag a string,
   a one-sentence note on WHY (e.g., "Lucknow shopkeepers don't
   say गुणवत्ता, they say 'अच्छी वाली'") is more valuable than the
   rewrite alone. The notes build a voice library that stays in the
   project after you.

## What the reviewer will NOT do

- Write new copy from scratch — we already have 50 strings and a
  voice guide. You're reviewing, not writing.
- Touch code or visual design — we have engineers and a designer.
  You only see the Hindi text.
- Work on English copy — English is the secondary toggle. Focus
  entirely on Devanagari.
- Participate in product decisions beyond Hindi voice. Scope is
  tight on purpose.

## Deliverables

- Weekly: reviewed screen set, with flags + rewrites in a shared
  Google Doc
- Weekly: 30-minute Zoom check-in
- End of 4 weeks: a "voice lessons learned" one-pager summarizing
  the 5-10 patterns you saw most often

## Success criteria

At the end of 4 weeks, when I send you any Hindi string from the
app, you can tell me in < 10 seconds whether it fits the voice or
not. If you can do that, the engagement is a success and we move
to on-call mode.

## Next steps

If this scope looks right to you, reply with:
1. Your rate for the 4-week intensive (or tell me you'd like me to
   suggest one)
2. Your start date availability
3. Any questions

I'll send a simple 1-page work-for-hire agreement and UPI details.

Looking forward to working with you.

— Alok
```

---

## §6 — 2-week decision deadline + fallback

If you've sent the outreach to the Tier-1 targets on Day 0 and nothing has clicked by Day 14, fall back to **END STATE B** cleanly:

1. **Don't keep waiting** beyond Day 14. Every day of delay costs Sprint 2 and blocks 5 Walking Skeleton stories.
2. **Execute the END STATE B sequence** from `sprint-0-i6-11-checklist.md §4`:
   - Flip `defaultLocale` Remote Config flag `"hi" → "en"` in all 3 Firebase projects (I can walk you through the CLI command when you're ready)
   - Write the one-line decision note at `_bmad-output/planning-artifacts/constraint-15-fallback-decision.md`
   - Visit Sunil-bhaiya in person (NOT WhatsApp, NOT phone) with the Hindi script from the checklist — get his explicit "ठीक है" before any Sprint 2 user-visible screen ships
3. **Keep Option B search running in the background.** END STATE B is reversible — when you eventually find a Hindi-native reviewer, flip the flag back to `"hi"` and re-validate the 50 strings. Constraint 4 is restored without a code change.

---

## §7 — What Amelia can do to support you through Sprint 0

Any time during these 2 weeks, if you want:

1. **I can draft follow-up outreach messages** if Tier-1 targets don't respond
2. **I can help with the 4-week work-for-hire agreement template** (1-page PDF, work-for-hire clause, UPI payment terms, IP assignment to Yugma Labs, kill clause)
3. **I can write the Sunil-bhaiya in-person notification Hindi script** in more polished form if END STATE B fires (the checklist has a draft but it can be tightened)
4. **I can pre-stage the `defaultLocale` CLI flip command** so it's ready to execute when you decide
5. **I can draft a 30-minute onboarding pack** for the chosen reviewer once you hire — a ZIP they can review in one sitting containing: the 50 existing strings, the 34 state catalog entries from UX Spec, the forbidden vocabulary list, and 3 sample screens
6. **I can continue Sprint 2 / Sprint 3 work that is NOT Sprint 0 blocked** in parallel. Specifically: the non-UI parts of S4.1 (shopkeeper Google sign-in operator-role bootstrap + custom claim helper) which only need a "Sign in with Google" button label as the single Devanagari string. This could ship in English for now with a `// TODO: swap to Hindi after Sprint 0` note.

---

## §8 — Companion files

- `sprint-0-i6-11-checklist.md` — the governance framework (WHAT to decide)
- `ux-spec.md v1.1 §5.5` — the 50 strings the reviewer will audit
- `product-brief.md v1.4 §8 Constraint 15` — the normative source for the 3 hiring options
- `product-brief.md v1.4 §8 Constraint 4` — the font stack that locks the typographic side
- `solution-architecture.md v1.0.4 §5 FeatureFlags` — where `defaultLocale` lives in Remote Config
- `solution-architecture.md v1.0.4 ADR-008 v1.0.4 clarification` — the architectural support for the fallback

---

## End of kit

When you're ready to start:
1. **Today (30 min):** run the Option A vetting on your existing designer + send the three outreach templates to 4+ places
2. **Day 3–7:** run the 30-min vetting calls as candidates surface
3. **Day 10–14:** pick your winner, send the scope, sign contract, start work
4. **Day 14 (fallback):** if nothing landed, execute END STATE B

Sprint 2 completion is waiting on this. Every other phase of the project is in green state. This is the one bottleneck.

— Amelia, Senior Software Engineer, 2026-04-11
