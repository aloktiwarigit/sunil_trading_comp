# Product Brief Elicitation 01 — Pre-mortem + Red Team + Triage

**Target document:** `_bmad-output/planning-artifacts/product-brief.md` (v1.0, ~9,000 words after iterative edits)
**Techniques applied:** Pre-mortem Analysis (method #34), Red Team vs Blue Team (method #17), Mary's synthesis
**Date:** 2026-04-11
**Facilitator:** Mary (Strategic Business Analyst)
**Executed by:** Two parallel Opus-powered subagents, each reading the brief + synthesis-v2 independently
**Input files:**
- `product-brief.md` (12-section brief)
- `party-mode-session-01-synthesis-v2.md` (working notes)

---

## 1. Pre-Mortem — "It is December 2026 and the project has failed"

*Subagent produced this analysis after reading both files in full. Verbatim below.*

### Framing

It is December 2026. Yugma Dukaan launched in August 2026, the Ayodhya flagship went live to real customers in July, and by late November Alok has privately accepted what the team has been circling for weeks: the product did not merely underperform, it collapsed under the weight of its own assumptions. The shopkeeper has stopped opening the ops app. Total completed orders through the app sit at 11, not 50. There is no shop #2 conversation in any meaningful stage. The $1/month Blaze budget cap has held, which is the only metric the brief predicted correctly. Alok is writing a post-mortem so he doesn't repeat these mistakes on vertical #2.

### The 12 Failure Modes

**#1 — The Shopkeeper Never Recorded the Voice Notes** *(CATCHABLE)*
By September, the ops app had exactly 4 shopkeeper voice notes in production — three recorded during onboarding with Alok physically present, one recorded two weeks later after prompting. The "shopkeeper drops voice notes on any product, any customer, any Project" vision from §3 produced a landing screen where the greeting voice note was the same clip heard by every customer for 14 weeks. The Absence Presence layer was never populated because populating it required the shopkeeper to sit down and record 8–12 audio clips in a quiet room — not a thing that happens between 9am and 9pm. **Root cause:** §3 Bharosa assumes the shopkeeper is a willing, prolific, self-motivated content producer. The brief never identifies when in his day he records, who prompts him, or what the fallback is if he records zero for three weeks. §5 describes him as "20+ years in the business, trusts his inventory instinct" — a man who sells with his hands and face, not a man who records audio. **Counterfactual:** Require 5 days of in-shop shadowing before design. Count how many times he voluntarily speaks into any device. If zero, Bharosa rebuilds around written shopkeeper micro-copy curated by the beta/nephew.

**#2 — Golden Hour Mode Was Photographed Once and Decayed** *(CATCHABLE)*
During onboarding week, Alok and the nephew photographed 47 almirahs in golden-hour light over three afternoons. By October, 22 of those SKUs were gone, and 18 new pieces were photographed by the nephew at 8:47 PM with his phone's flash because "golden hour chali gayi thi." The customer app showed a schizophrenic catalog — half Sunday-best raking light, half flash-blown tube-light. **Root cause:** §3 calls Golden Hour Mode "one capture per SKU, lifetime asset." The word "lifetime" is the lie. Furniture inventory is not a lifetime asset; it is rotating stock. The brief has no maintenance cadence and no degradation policy. **Counterfactual:** Two photo tiers — hero (curated) and working (any lighting). Ship with the shopkeeper-controlled *"asli roop"* toggle as DEFAULT and golden-hour as a progressively-populated veneer.

**#3 — Decision Circle Was Used Zero Times** *(CATCHABLE)*
By October, Firestore analytics showed 96% of sessions had the Guest Mode persona toggle untouched. Users said: "yeh kya hai?" and "mummy ne phone nahi liya, main hi dikha raha tha video call pe." Committees in 2026 don't pass a phone around a charpai — they video-call. Mother-in-law in the kitchen, daughter-in-law at her desk in Bangalore, husband in Lucknow — all on WhatsApp video looking at one screen. One phone, one user, three faces on video, **zero need for session personas**. The committee-native architecture was a beautiful answer to the wrong question. **Root cause:** §3 Pariwar never asked the concrete question: in 2026, when a committee makes a decision across cities, what is actually happening on the phones? The answer (WhatsApp video with screen share) makes Decision Circle session state redundant. **Counterfactual:** Validate the one-phone-many-faces hypothesis with 10 field observations. If committees are video-call-mediated, rebuild Pariwar around screen-share-friendly rendering (huge fonts default, voice-first, no small UI elements that get lossy over video compression) instead of persona toggles.

**#4 — The Son/Nephew Was Never Really Onboard** *(CAUGHT)*
The nephew — who the brief repeatedly casts as the digital operator — turned out to be a 29-year-old with a Lucknow BPO day job who visits his uncle's shop on Sundays. The shopkeeper's actual son is 19, studying, and uninterested in the furniture trade. By week 6, inventory CRUD was stale, curation shortlists unchanged for 23 days, customer memory empty beyond Alok's bulk import. The multi-operator model collapsed into Alok-as-shadow-operator. **Root cause:** §5 names three operator roles as if reliably present in every Tier-3 almirah shop. The brief never checks. §9 Q1 parks "family structure" as unknown; R1 flags burnout. The team documented the risk and shipped anyway. **Counterfactual:** Do not write a line of ops-app code until the real shop's staffing is known AND at least one non-shopkeeper operator has committed to a defined weekly time slot.

**#5 — The Udhaar Khaata Became a Collections Nightmare** *(CATCHABLE)*
By November, 9 of 11 completed orders had taken the udhaar partial-payment route. Of those 9, 4 were on schedule, 3 were one installment overdue, 2 had stopped responding. The shopkeeper — who has extended informal credit for 20 years without drama — was suddenly drowning in it because the app made udhaar frictionless at commit but not at collection. The shopkeeper had no stomach for sending digital dunning messages to people he knows socially. **Root cause:** §3 Pariwar frames the feature as digitization of existing practice but ignores *why* informal udhaar works — it is gated by the shopkeeper's social judgment at the counter. The app removes that gate and offers no replacement. **Counterfactual:** Ship udhaar khaata as a shopkeeper-invoked workflow only — the customer cannot self-select it; the shopkeeper taps "udhaar le lo" for specific customers he vouches for.

**#6 — Phone Auth OTP at Commit Killed Conversion** *(CATCHABLE)*
Funnel analytics showed a 64% drop-off at the OTP verification prompt. Users browsed, chatted, entered Decision Circles, reached commit — then refused to type their phone number. **The cultural pattern:** in Tier-3 India, the phone number is considered private. The customer's mental model is "I've been talking to Ramesh-bhaiya, he already has my number from WhatsApp, why is this app asking again?" The "explicit trust ceremony at the moment of commitment" turned out to be a trust *rupture*. **Root cause:** §3 and §10 present layered Anonymous → Phone Auth upgrade as obviously good UX: "gives customers the trust ceremony they expect." The brief never validates that customers *expect* a trust ceremony. In a relational economy, trust already exists in the shopkeeper relationship; layering OTP signals *distrust*. **Counterfactual:** Make phone verification shopkeeper-initiated ("Ramesh-bhaiya needs your number to deliver"), not app-initiated. Or skip Phone Auth entirely at v1 and let UPI payment metadata capture the phone via VPA — which §10 already lists as a redundant identity layer.

**#7 — "Shop #2 in 9 Months" Was a Cold-Start Problem Nobody Owned** *(CAUGHT)*
By November, shop #2 conversations had happened with two furniture shopkeepers — both polite, non-committal. *Nobody at Yugma Labs was doing sales full-time.* Alok was building. Mary was planning. The "go-to-market playbook for shops 2–10" listed in §7 v2 was a document that did not exist because nobody wrote it. The platform thesis — the only north-star metric per §6 — had no owner. **Root cause:** §6 states the north-star metric. §9 Q7 parks "Shop #2 go-to-market: who, what price?" The brief documents the gap and ships anyway. §12 Next Steps allocates no person-time to shop #2. **Counterfactual:** Treat shop #2 outreach as a parallel workstream starting in Month 2. Allocate 20% of one person's time to shopkeeper interviews every week. Measure shop #2 pipeline, not just product metrics.

**#8 — The 6–9 Month Timeline Assumed Alok Had 160 Hours/Week** *(CATCHABLE)*
By Month 5 (v1 ship date), customer app was in testing with major gaps: Guest Mode personas stubbed, offline sync had conflict-resolution bugs, Golden Hour capture tool was a prototype, marketing website had no content. Ship slipped to Month 7. v1.5 features folded into v1 to save time, blowing scope discipline. By Month 9, team was still debugging Firestore security rules for Anonymous-to-Phone Auth upgrade. Winston flagged the UID merger as a 3–4 week problem in Week 2; by Month 8 it was still not finalized. **Root cause:** §7 proposes a "6–9 month full enterprise-grade build" for THREE apps + Firestore schema + multi-tenant + Decision Circle + Golden Hour + udhaar + offline sync + account linking + Devanagari-first i18n + Crashlytics — with a team whose size the brief never specifies. This is a 4-engineer-year project compressed into a one-founder timeline. **Counterfactual:** Cut v1 scope to ONE app (customer) + a minimal shopkeeper WhatsApp-based operator flow + a one-page website. Defer the ops app to v1.5. Defer multi-tenant to v2.

**#9 — Devanagari-First UI Had Unresolved Typography and Copy Debt** *(CATCHABLE)*
Post-launch feedback: Hindi copy read like "textbook Hindi" with Sanskritized vocabulary nobody in Harringtonganj uses. Devanagari rendering on cheap Android had unresolved glyph-clipping issues with conjuncts. The promise of warmth living "in the typography and the specificity" became warmth *missing* from typography. **Root cause:** §8 Constraint 4 mandates Devanagari-first and §10 specifies Noto/Mukta, but the brief has zero budget for a Hindi copywriter, zero process for copy review by Awadhi-inflected Hindi speakers, zero plan for glyph QA on budget Android. Hindi-first is treated as a *language flag*, not an editorial discipline. **Counterfactual:** Hire or commit one fluent Awadhi-Hindi copywriter for 4 weeks at v1 spec phase. QA Devanagari rendering on 5 real budget Android devices before design signoff.

**#10 — WhatsApp Ate the Product** *(CATCHABLE)*
By October, the shopkeeper had quietly moved 80% of customer conversations back to WhatsApp — latency on Firestore real-time was bad, audio quality was compressed, and the in-app notifications were ignored because they weren't WhatsApp notifications. The `wa.me` handoff listed in v1.5 became the DEFAULT path in 8 weeks. The committee experience moved back to WhatsApp groups — exactly what Reframe 2 said to avoid. **Root cause:** §3 specifies real-time chat via Firestore with WhatsApp as handoff. For a user whose entire social graph lives in WhatsApp, a second chat channel is not "shopkeeper-owned" — it's friction. R5 flags WhatsApp pricing policy risk but not WhatsApp as a *gravitational competitor*. **Counterfactual:** Abandon in-app chat entirely. Build Ramesh-bhaiya Ka Kamra as a WhatsApp Business API thread orchestrated by the ops app, with the app providing structured context (Project state, voice notes, shortlist) as an overlay. Stop competing with WhatsApp; use it as plumbing.

**#11 — The Multi-Tenant Architecture Tax Delayed v1 Without Paying Off** *(CATCHABLE)*
Winston spent 6 weeks in Months 2–3 building ThemeExtension tokens, namespaced Firestore schema, shopId scoping, content externalization. None was user-visible in v1. By Month 9, shop #2 was not onboarded. The strangler-fig architecture cost 6+ engineering weeks and served a customer that did not exist. **Root cause:** §10 Architectural Principle 1 declares multi-tenant from day one. §7 v1 lists "multi-tenant hooks" as in-scope. The brief treats extensibility as free. It isn't. **Counterfactual:** Single-tenant v1 with content externalized via simple config files as the only concession. Extract architecture when shop #2 is actually signed, not speculatively.

**#12 — Nobody Did the Saturday Stopwatch and the UX Was Built on Fiction** *(CAUGHT)*
The in-shop time-and-motion study that §12 Next Step 3 promised "before v1 design sprints begin" never happened. Design sprints proceeded on the assumption that the shopkeeper had 40 free tap-minutes distributed across the afternoon. Actual observed behavior: his free attention came in two clumps — 11:30 AM to 12:30 PM and after 8:30 PM at home. "Remote control for his finger" interactions were happening at 9:40 PM, not real-time, killing the core UX premise. **Root cause:** §9 Q2 and Q4 explicitly flag this. §12 Next Step 3 commits to scheduling the shadow. The team documented the risk, wrote it down, and then did not do it because it was inconvenient. **Counterfactual:** Make the field study a BLOCKING prerequisite for design kickoff. No design without data.

### Pattern Analysis

**Five of twelve failure modes are CAUGHT or CAUGHT-adjacent.** The brief is *more self-aware than it is self-correcting*. §9 Open Questions and Risks operate as an intellectual pressure valve: naming the risk creates the sensation of having addressed it without actually changing the plan. **Documentation of a risk is being treated as a substitute for mitigation of a risk.** Mary writes it down, Alok acknowledges it, the brief moves on, the risk ships.

**Second pattern:** the brief repeatedly confuses *architectural sophistication* with *product validation*. Multi-tenant strangler-fig, Anonymous→Phone Auth account linking, Golden Hour photo pipeline, Decision Circle session state — these are technical achievements masquerading as product decisions. Each one rests on an unvalidated user-behavior assumption.

**Third pattern:** the brief is written from the *shopkeeper's imagined best self* and the *customer's imagined best self*, not from real observed humans. Ramesh-bhaiya is an archetype on whose behalf the product is being designed. **Building a 6–9 month enterprise-grade platform for an archetype is the definitional blunder.**

### Top 3 — If Alok can only fix three things before writing a line of code

1. **Do the Saturday Stopwatch and the 5-day shadow FIRST.** Every decision in the brief is downstream of this data.
2. **Kill the OTP-at-commit ceremony and kill the in-app chat; use WhatsApp as plumbing.** These are the two largest preventable UX wounds.
3. **Allocate a named human to shop #2 outreach from Month 2.** Treat shop #2 as a product of its own with its own owner.

**Catchability distribution:** 3 CAUGHT, 9 CATCHABLE, 0 SURPRISE. That the pre-mortem found zero surprises is itself a finding: December 2026's post-mortem is sitting inside the April 2026 brief, fully drafted, waiting to be read by someone willing to act on it.

---

## 2. Red Team — Adversarial Investor Review

*Subagent produced this analysis as a cynical former-operator investor who saw Dukaan implode. Verbatim below.*

### Opening Salvo

I've been pitched "empower the small shopkeeper" fifty-seven times. Forty-one died in month 9. Three made it to Series A and died in month 22. Dukaan — which the brief correctly cites as a cautionary tale — started with a better distribution hypothesis than this brief does, and still imploded.

**Three reasons I'd pass at first read:**

1. **The entire product is predicated on a shopkeeper whose name is TBD.** §9 Open Question 1, §5 "archetype — real shopkeeper details TBD," cover note "shop identity TBD." You are writing a 9,000-word opinionated product spec for a human being you have not yet met, interviewed, or signed an LOI with. This is not a flagship. It's a stock photo with a moustache.

2. **Triple Zero is a costed-for-today doctrine being sold as a durable moat.** §4.7 literally calls ₹0 cost "architectural IP" and "Yugma Labs' long-term defensible asset." It is not. It is a temporary property of a specific Firebase pricing page Alok himself had to correct twice mid-session because neither research subagents nor fetched primary sources could verify it. A moat your own team couldn't document from primary sources is not a moat — it's an undocumented oral tradition you're one Google Cloud pricing update away from losing.

3. **The brief confuses specificity with validation.** Voice notes, Golden Hour, *"Mummy-ji dekh rahi hain"*, *"aaj shaadi mein hoon 6 baje wapas"* — beautifully observed prose. But §9 Open Questions 3 and 4 admit nobody has spent three days behind the counter or run the Saturday stopwatch. You're writing ethnography backward.

### The 16 Attacks

**#1 — Triple Zero is a marketing doctrine masquerading as architectural IP** [**CRITICAL**]
§4.7 calls ₹0 cost "Yugma Labs' long-term defensible asset." Three scales break it: SMS quota saturates around shop #33, Firestore 50k reads/day will burn through fast with committee-chat threads, Cloudinary 25 credits is a *lifetime asset assumption* for a rotating catalog. "₹0" is true at shop #1 on day 1. By month 6 of shop #1 with growing catalog, you're watching the meter. **Fix:** Rewrite §4.7 and §8 Constraint 3. Drop "architectural IP / long-term defensible asset" language entirely. Replace: "Triple Zero is a survival posture at shop #1 scale and a cost-discipline discipline through shop #10. Beyond shop #10, a flat-fee SaaS whose unit economics must be modeled as a v1.5 deliverable." Add an explicit marginal cost table in §6 Month 9 criteria showing expected Firebase spend at shop #10, #25, #50.

**#2 — The 10,000 SMS/month free quota has no cited primary source** [**CRITICAL**]
The entire auth story rests on this quota. Synthesis v2.1 explicitly states: "neither the research subagent nor the primary Firebase pricing pages could confirm this." §4.7 claims "verified against real production evidence" — that's founder memory, not a cited T&C. Google can change this in a pricing update email next Tuesday. **Fix:** Add §9 R8 "Phone Auth free quota is verified only by founder production experience." Mitigation: before committing architecture, Winston must (a) confirm via Firebase Console billing history for an existing Alok project, (b) screenshot the pricing page as dated evidence, (c) design the auth adapter such that phone auth can be swapped to a free fallback (email magic link, WhatsApp OTP via wa.me, deferred-verification) without breaking Decision Circle semantics.

**#3 — The flagship shopkeeper is a TBD and the brief is written as if he said yes** [**CRITICAL**]
Three scenarios the brief cannot distinguish: shopkeeper says no (5 months orphaned); says yes but uses it twice a week (Bharosa dies silently); says yes but is pure reseller (§9 R2 authenticity arbitrage). **Fix:** Downgrade §1 and §3 throughout — s/the shopkeeper is.../the shopkeeper will be.../ — and add a new §12 Next Step 0 *blocking* every subsequent step: "Before architecture, before design, before PRD: a signed 3-way LOI between Yugma Labs, the shopkeeper, and the shopkeeper's designated digital operator. The LOI must commit him to (a) 3 consecutive days of shadow observation, (b) the Saturday stopwatch study, (c) Golden Hour photography of minimum 20 SKUs, (d) 30-minute daily app usage for months 1–3. If no LOI by week 4, pivot to candidate shop #2 or halt."

**#4 — Bharosa is a person, not a product — and the brief never reckons with that** [**CRITICAL**]
§3 and §4.3 say "the shopkeeper IS the product." Every differentiator leans on a single human's continued participation. §9 R1 flags burnout but mitigates with "role-based access in v1.5" — a deferred feature for a day-one vulnerability. The brief never names what happens if he's hospitalized, loses interest, dies, or closes his shop. **Fix:** Add §9 R1 sub-fix: "Bharosa must be engineered as a *role*, not a person. v1 requires (a) a content library of voice notes + shortlists that Yugma owns and can re-license to a successor, (b) explicit succession clause in the shopkeeper's LOI, (c) 'son/nephew as equal voice' architecture in v1 not v1.5, (d) contractual asset-ownership agreement on recorded audio, photos, curated decisions." Rewrite §4.3: "the shopkeeper *role* is the product."

**#5 — Pariwar's Decision Circle has never been observed in a real kitchen** [**CRITICAL**]
§4.4 calls Guest Mode "committee-native from the data model up… not a feature, a foundation." The difference between "Family Circle invite" (killed) and "Guest Mode session state" is architectural, not empirical. Both are still guesses made in a room without grandmothers in it. Most likely reality: son hands phone to mother, she looks 40 seconds, hands back, says "*koi bhi le lo beta.*" Feature collapses into an ops-app toggle nobody uses. **Fix:** Add to §9 Open Questions: "Has any real family been shown a Guest Mode mockup and asked whether they would press *'Mummy-ji dekh rahi hain'*?" If no, Guest Mode drops to v1.5 and v1 ships with a simpler "large-text accessibility toggle" achieving 80% of the UX win without the session-state architecture.

**#6 — The 50+ orders / 80% funnel numbers are wishes wearing KPI clothing** [**MATERIAL**]
§6 Month 6: "50+ completed orders" and "80% of new leads funnel through the platform." Neither number is derived from anywhere. Brief doesn't state shopkeeper's current order volume, lead volume, or close rate. "80% of leads" is non-actionable — a shopkeeper with 6 leads/month hits 80% with 5 leads, validating nothing. **Fix:** Replace §6 Month 6 with: "Baseline measurement: in week 2 of shop #1 engagement, record actual current monthly order volume and lead volume. Month 6 targets as *multiplier* against baselines, not absolute numbers. Default assumption: 20% lift in closed orders, 40% of new leads flowing through app. Revise after baseline."

**#7 — The Hindi-first-admin moat is 6 weeks wide against a determined competitor** [**MATERIAL**]
§4.2: "No platform in 2026 has a Devanagari-first admin dashboard." But nothing explains why Amazon cannot ship Hindi admin in 6 weeks — Amazon already operates in Hindi for seller apps in other categories, and AWS Translate infrastructure is industrial-grade. "Real, documented gap" ≠ "defensible." **Fix:** §4.2 rewrite: "Hindi-first admin is a 6–12 week catch-up moat against SmartBiz. The durable defense is the cultural specificity of the copy, the shopkeeper-authored voice notes (cannot be translated into existence), and the accumulated content library. Language is the door; content is the room." §9 R4 add: "If SmartBiz ships Hindi admin before Month 6, the moat is Bharosa content, not UX chrome. Measure voice-note library size and curated-shortlist depth as the real defensibility metric."

**#8 — Team size and Alok's solo capacity are nowhere in the brief** [**CRITICAL**]
§7 sets a 6–9 month enterprise scope: 3 apps (~30+ screens total), Firestore, Cloud Functions, multi-tenant theme tokens, Hindi content authoring, Golden Hour pipeline, Decision Circle session state, voice note infrastructure, udhaar ledger, UPI, offline sync, multi-tenant dry-run. The brief **never states how many humans are building this**. At 2 engineers it's 12 months on a good day. At 1 engineer (solo Alok + Claude Code MCP) it's 24 months that never ships v1.5 or v2. **Fix:** Add §8 Constraint 13: "Execution capacity: [N] engineers + [N] designers + Alok. If solo, scope collapses to v1-minus: Bharosa only, Pariwar deferred to v1.5, no Decision Circle session state, no Golden Hour pipeline (manual photos), no udhaar khaata. v1 ship target slips to month 9 not month 5." Name the choice.

**#9 — The ₹0 revenue runway is never costed against Yugma Labs' survival** [**CRITICAL**]
§1, §8, and §11 commit to ₹0 revenue in v1, monetization at shop #2. §9 Q7 acknowledges "Shop #2 go-to-market" is unknown. Nowhere does the brief state Yugma Labs' runway, burn rate, or survival horizon. Alok's own salary and living costs are not mentioned. If shop #2 takes 12 months instead of 9, Yugma has 3 extra months of ₹0. If shop #2 fails, add 3–6 more. **Fix:** Add §8 Constraint 14 or §11.5: "Yugma Labs runway assumption: [N] months of ₹0 revenue before shop #2 signs. If shop #2 does not sign by month M, fallback is [X]: (i) Alok accepts consulting income, (ii) Yugma takes shopkeeper-side bridge fee (breaking Triple Zero), (iii) project pauses. Pick one fallback." Tie §6 Month 9 criteria to Yugma survival, not just platform validation.

**#10 — Geography-agnostic strategy vs. Ayodhya-specific evidence is a quiet contradiction** [**MATERIAL**]
§8 Constraint 12: "Geography-agnostic." But §2, §5 personas, Harringtonganj specificity, Avadh-regional references are all drawn from Ayodhya observation. Golden Hour Mode explicitly requires per-shop calibration. *"aaj shaadi mein hoon"* is Awadhi-inflected Hindi that reads differently in Gorakhpur vs Kanpur vs Jaipur. **Fix:** §8 Constraint 12 rewrite: "Geography-*portable*, not geography-*agnostic*. Each new city requires (a) shop-specific voice note re-recording, (b) per-shop copy review for dialect, (c) golden-hour recalibration. Portability ≠ universality." §11 vertical expansion must state new-city onboarding carries a ~2 week per-shop cultural adaptation cost.

**#11 — "Multi-tenant architecture underneath single-tenant experience" has no tenant isolation plan** [**MATERIAL**]
§3, §8 Constraint 7, §10 Principle 1 all commit to multi-tenant-underneath. §10 mentions "namespaced by shopId" but never discusses: tenant data isolation in Firestore, tenant-specific billing accountability (if shop #5 blows the shared 10k SMS quota, whose bill is it?), tenant-specific App Check secrets, analytics segregation, schema upgrade paths. §7 v2 has "Shop #2 onboarding pilot — first multi-tenant activation" — meaning the first time multi-tenancy is exercised is in production with a paying customer. **Fix:** §10 add "Multi-tenant verification strategy": (a) every Firestore query reviewed for shopId scoping before merge, (b) integration tests must attempt cross-tenant reads and fail loudly, (c) a synthetic "shop #0" tenant maintained from day one, (d) billing attribution per-shop logged via Cloud Monitoring labels from v1. Add §9 R9: "Multi-tenant flip-switch at shop #2 is the highest-risk moment and must be preceded by 4 weeks of dry-run testing."

**#12 — Udhaar khaata is a regulated financial product, not a Firestore doc** [**MATERIAL**]
§3 describes digital udhaar khaata with scheduled reminders, partial UPI payments, running balance — without engaging with RBI's 2022/2024 digital lending guidelines. KhataBook operates as a ledger (not a lender) for this reason; their copy is carefully lawyered. Failure modes: regulator calls it unregulated lending and issues cease-and-desist; customer disputes, Yugma becomes witness in civil court; collection messaging triggers fair-practices concerns. **Fix:** Add §9 R10 "Informal credit legal surface." Mitigation: before v1, Alok engages lawyer familiar with RBI digital lending guidelines to review copy, reminder cadence, data retention. §10 Winston TODO: "Udhaar Ledger schema must NOT store anything framed as interest, late fee, or contractual obligation — it is an accounting mirror of an offline agreement, not a lending instrument. Copy review required."

**#13 — The Month 3 hard gate depends on a UPI-fluent customer the brief hasn't characterized** [**MATERIAL**]
§6 Month 3: "One real customer completed full journey, no Mary-in-the-loop." §5 describes Persona A as "UPI-fluent via family" — she doesn't use UPI herself. The Month 3 gate is a technical happy path requiring shopkeeper trained, customer installed and fluent, payment rail succeeds first attempt. In practice, Mary will demo it. "No Mary-in-the-loop at month 3" is fantasy. **Fix:** §6 Month 3 split: (a) *technical* gate — one end-to-end with Mary coaching, proving plumbing; (b) *adoption* gate — deferred to Month 5, one with shopkeeper coaching, one with nobody. "No Mary-in-the-loop" is a month 5 milestone, not month 3.

**#14 — The brief celebrates dropped features without costing what that means for the pitch** [**MATERIAL**]
After dropping Muhurat Mirror, Threshold Passage, First Things Stored, Hanumanji framing — the brief's *vertical-ness* is thin. Golden Hour Mode is the only almirah-specific feature; everything else is generic "small trusted shop" UX. §4.5 claims "opinionated for almirahs" as durable differentiator. Remove Hindi UI and you have Etsy + WhatsApp Business + KhataBook in a trench coat. **Fix:** §4.5 must explicitly list almirah-specific design decisions making the product non-portable to a kirana store. If the list is short (Golden Hour + curation by occasion), §4 must acknowledge the vertical moat is shallow and reposition §11 vertical expansion as "easier than expected" rather than "proprietary playbook." Alternatively, §3 must add 2–3 more almirah-specific features (SKU-level material provenance, polish/hardware traceability, delivery-and-assembly choreography) to re-earn the vertical claim.

**#15 — "Show, don't sutra" is a promise by a team whose Hindi-native design capacity is undeclared** [**MATERIAL**]
§8 Constraint 10 promises visual Hindi-first craft. §10 specifies Noto/Mukta. But the brief doesn't state whether Yugma has a designer fluent in Hindi visual design or whether designs will be drafted in English-brain and translated. The most common failure mode for Hindi-first Indian apps: Devanagari clips, wrong line heights, unnatural voiceover cadence, icon labels don't fit. **Fix:** Add §8 Constraint 15: "Hindi-native design capacity is a hiring/vetting prerequisite. Before design sprints begin, Yugma must either (a) hire a Devanagari-native designer, (b) contract a Hindi-fluent design reviewer with shipping experience, or (c) narrow v1 to a scope a non-Hindi-native designer can execute safely (English-first with Hindi toggle, explicitly breaking Constraint 4)." Name the choice.

**#16 — Success criteria contain no failure criteria** [**MATERIAL**]
§6 lists targets to hit. Nowhere does it list failure thresholds. "50+ orders by Month 6" — what happens at 30? At 10? At 2? "Shop #2 signs within 9 months" — what happens at LOI stage but not signed? No kill gate, no pivot trigger. **Fix:** §6 add "Kill gates": "If Month 3 hard gate missed by >30 days → review scope and team. If Month 6 orders <10 (20% target) → halt v1.5 and convene pivot session. If Month 9 has no shop #2 LOI (not signature, LOI) → Yugma reassesses Triple Zero and considers breaking zero-commission to monetize shop #1 as a single-shop business."

### Severity Tally

- **CRITICAL: 7** (Attacks #1, #2, #3, #4, #5, #8, #9)
- **MATERIAL: 9** (Attacks #6, #7, #10, #11, #12, #13, #14, #15, #16)
- **MINOR: 0**

**Red-team verdict: With 7 CRITICAL attacks, this brief is NOT ready for handoff to Winston.** The rule was "more than 3 CRITICALs = not ready." This brief is structurally not ready — the product spec is running ahead of the shopkeeper LOI, the team size, the runway, and the moat's own documentation. Those are founder-capacity and due-diligence blockers, not Winston blockers. Fix the CRITICALs before architecture.

### The Charitable Close

What is genuinely right about this brief and must be preserved: The diagnosis of the problem (§2) is excellent. The decision to kill the mythic/Mandir layer shows real discipline. "Show, don't sutra" is a correct and hard-won design doctrine. The anti-personas section is ruthless in a useful way. Golden Hour Mode is a genuinely original insight. And the refusal to build a marketplace / refusal to take commission / refusal to charge customers — while the framing is overconfident, the posture is correct. Fix the CRITICALs, tighten the MATERIALs, and the brief that emerges could still be one of the more honest entries in this category in 2026. Just not this draft.

---

## 3. Mary's Triage Synthesis

Both subagents converged on many of the same issues from different angles. Below is my cross-referenced synthesis into three buckets.

### 🔴 BLOCKERS — Must fix before Winston handoff (7)

| # | Issue | Source | Fix location |
|---|---|---|---|
| **B1** | Shopkeeper LOI is prerequisite #0, not a future step | PM#4 + RT#3 | §12 new "Next Step 0" (blocking), §5 persona downgrades, §1 cover note |
| **B2** | Saturday stopwatch + 3-day shadow must happen BEFORE design sprints | PM#12 + RT#3 | §12 Next Step 0 includes this; §9 Q2/Q4 promoted from "parked" to "blocking prerequisite" |
| **B3** | Team size / execution capacity must be declared explicitly | RT#8 | New §8 Constraint 13; scope adjustment per declared capacity |
| **B4** | Triple Zero must be reframed as scope-bounded posture, not durable IP | RT#1 | §1, §3, §4.7, §8 Constraint 3 rewrites |
| **B5** | Phone auth 10k/mo quota needs primary source verification + fallback | RT#2 + PM#6 | New §9 R8; §10 auth adapter must allow swap to free fallback |
| **B6** | Bharosa must be a role, not a person — content library + succession | RT#4 + PM#1 | §4.3 rewrite; §9 R1 mitigation strengthened; LOI includes content-asset clauses |
| **B7** | Yugma Labs runway + shop #2 ownership must be named | RT#9 + PM#7 | New §8 Constraint 14; §12 allocates person-time to shop #2 from Month 2 |

### 🟡 MATERIAL RISKS — Must be acknowledged in §9 but don't block handoff (11)

| # | Issue | Source |
|---|---|---|
| M1 | OTP-at-commit may kill conversion (cultural reject, 64% drop-off scenario) | PM#6 + RT#5 edge |
| M2 | WhatsApp will likely eat the in-app chat (substitution, not just dependency) | PM#10 |
| M3 | Decision Circle / Guest Mode is an unvalidated hypothesis, not a foundation | PM#3 + RT#5 |
| M4 | Udhaar khaata has regulatory surface (RBI digital lending guidelines) | RT#12 |
| M5 | Udhaar khaata collection ops may collapse without shopkeeper-initiated gating | PM#5 |
| M6 | Golden Hour Mode photo decay (rotating stock, not lifetime asset) | PM#2 |
| M7 | Multi-tenant flip-switch at shop #2 is highest-risk moment; needs dry-run | RT#11 |
| M8 | Hindi-first moat is 6–12 weeks wide; real moat is content, not UX chrome | RT#7 |
| M9 | Hindi-native design capacity is a hiring prerequisite, not an aspiration | PM#9 + RT#15 |
| M10 | Geography-agnostic is really geography-portable (per-shop cultural adaptation) | RT#10 |
| M11 | Success criteria need kill gates / failure thresholds, not just targets | RT#16 |
| M12 | Vertical moat is thin after mandir drops; add features or acknowledge | RT#14 |
| M13 | Month 3 hard gate ("no Mary-in-the-loop") is unrealistic; split into tech vs adoption | RT#13 |
| M14 | Success criteria numbers (50+ orders, 80% funnel) are wishes, not baselines | RT#6 |

### 🟢 OPEN QUESTIONS FOR THE REAL SHOPKEEPER — Cannot be resolved from our chair (9)

| # | Question |
|---|---|
| Q-A | Real shop identity, name, inventory size, customer base, staffing |
| Q-B | Shopkeeper's actual inventory provenance (fabricator / reseller / authorized dealer) |
| Q-C | Will the shopkeeper voluntarily record voice notes as an ongoing behavior? |
| Q-D | Who is the designated digital operator (son / nephew / munshi) and what is their real commitment? |
| Q-E | What is the shopkeeper's actual monthly order volume, lead volume, close rate? |
| Q-F | What is his Saturday attention pattern (hand-free two-second windows)? |
| Q-G | Does his committee actually pass phones or video-call? (Field observation required) |
| Q-H | What is his current informal udhaar pattern and collection cadence? |
| Q-I | Does he want B2B / bulk customers, or does he actively avoid them? |

---

## 4. Specific Brief Edits for Blockers

These are the ~7 edits that, if applied, close the CRITICALs and make the brief safe to hand off to Winston.

### Edit 1 — §1 Executive Summary (B1, B4, B6)

Current claim: "The flagship customer is a real shopkeeper…" and "Triple Zero is the product's real moat."

Rewrite: "The flagship customer will be a real shopkeeper in Ayodhya's Harringtonganj market, to be identified and committed via LOI before architecture begins (see §12 Next Step 0). Triple Zero is a survival posture at shop #1 scale and a cost-discipline discipline through approximately shop #10–33, beyond which a flat-fee SaaS model takes over with unit economics modeled as a v1.5 deliverable (see §9 R3)."

### Edit 2 — §4.3 differentiator

Change: "**Shopkeeper-as-priest of existing relational capital**" with "the shopkeeper IS the product"
To: "**The shopkeeper-role is the product.**" Expand: "Bharosa is engineered as a reusable role occupied by a specific human. The content library (voice notes, curated shortlists, customer memory, Golden Hour imagery) is Yugma Labs' asset under a contractual agreement with the shopkeeper, designed to survive successor operators within the same shop or onboarding of a new flagship shop if circumstances require."

### Edit 3 — §4.7 differentiator

Current: "**₹0 operational cost as architectural IP.** Yugma Labs' long-term defensible asset, transferable to future shops and future verticals."

Rewrite: "**Triple Zero as operational discipline through the early-shop frontier.** At shop #1 scale, infrastructure cost is ₹0. The discipline remains cost-sustaining through approximately shop #10–33, at which point SaaS unit economics take over. The IP is the *discipline itself* — the playbook of architecting for free-tier ceilings — not a literal zero-cost guarantee. Competitors failing this discipline (Dukaan 2023 collapse) validate the posture without obligating Yugma to preserve ₹0 at unlimited scale."

### Edit 4 — §8 add Constraint 13, 14, 15

**Constraint 13 — Execution capacity (mandatory to declare):**
> "Yugma Labs execution capacity for v1: **[ALOK MUST NAME THIS BEFORE WINSTON HANDOFF]**. Options:
> - **Solo (Alok only + AI tooling):** v1 scope narrows to customer app + static website + minimum shopkeeper WhatsApp-based operator flow. Multi-tenant, Decision Circle session state, Golden Hour pipeline, udhaar khaata deferred to v1.5. Ship target: Month 9.
> - **Small team (2–3 engineers + 1 designer):** current §7 v1 scope is feasible in 6–9 months.
> - **Funded team (5+):** current scope is comfortable; v1.5 and v2 features can parallelize."

**Constraint 14 — Runway horizon:**
> "Yugma Labs must declare a runway assumption of at least [N] months of ₹0 revenue before shop #2 signs. Fallback if shop #2 does not sign by month 9 is one of: (i) Alok accepts consulting income, (ii) Yugma offers the flagship shopkeeper a voluntary support fee breaking ₹0 but preserving zero commission, (iii) project pauses. Alok must pick and commit to one fallback."

**Constraint 15 — Hindi-native design capacity:**
> "Hindi-native design capacity is a hiring/vetting prerequisite. Before design sprints begin, Yugma must secure at least one of: (a) an in-house Devanagari-native designer, (b) a contracted Hindi-fluent design reviewer with shipping experience, or (c) an Awadhi-Hindi copywriter for 4 weeks at v1 spec phase + Devanagari QA on 5 real budget Android devices before design signoff. If none available, v1 narrows to English-first with Hindi toggle, explicitly breaking Constraint 4."

### Edit 5 — §9 add R8, R9, R10; strengthen R1 and R3

**New R8 — Phone Auth free quota unverified from primary sources:**
> "The 10,000 SMS/month Blaze free quota for phone auth in India is observed in founder production experience but could not be confirmed from any Google/Firebase primary source during April 2026 research (all pricing pages JavaScript-rendered and unfetchable). Mitigation: before committing architecture, Winston must (a) screenshot Firebase billing dashboard for an existing Alok project showing zero phone-auth charges, (b) design the auth adapter as a swappable interface so phone auth can be replaced with email magic link, WhatsApp OTP via `wa.me`, or deferred-verification (UPI-metadata-based) without breaking Decision Circle upgrade semantics, (c) set a kill-switch trigger if monthly SMS cost exceeds ₹500 in any month."

**New R9 — Multi-tenant flip-switch at shop #2:**
> "The first time multi-tenancy is exercised in production will be at shop #2 onboarding. Mitigation: (a) every Firestore query reviewed for `shopId` scoping before merge, (b) integration tests must attempt cross-tenant reads and fail loudly, (c) a synthetic 'shop #0' tenant maintained from day one so multi-tenancy is exercised continuously, (d) billing attribution per-shop logged via Cloud Monitoring labels, (e) 4 weeks of dry-run testing before shop #2 goes live."

**New R10 — Informal credit regulatory surface:**
> "The digital udhaar khaata feature has potential exposure to RBI's Digital Lending Guidelines (2022, updated 2024) if framed as lending rather than accounting. Mitigation: before v1, Alok engages a lawyer familiar with RBI guidelines to review udhaar copy, reminder cadence language, and data retention policies. Winston's Udhaar Ledger schema must not store interest, late-fee, or contractual-obligation framing — the ledger is an accounting mirror of an offline agreement, not a lending instrument."

**Strengthen R1 (burnout):** Mitigation must include "shopkeeper-role succession clause in LOI, content-asset ownership by Yugma Labs, multi-operator architecture day one (not v1.5 deferred)."

**Strengthen R3 (Triple Zero horizon):** Add explicit marginal-cost forecast table for shop #5, #10, #25, #50 — even as placeholder numbers to be validated.

### Edit 6 — §12 add Next Step 0 (BLOCKING)

**New Next Step 0 — Prerequisite before all other steps:**
> "Before architecture, design sprints, PRD drafting, or any code: Alok must complete ALL of the following as blocking prerequisites:
> 1. **Shopkeeper LOI signed** — a 3-way letter of intent between Yugma Labs, the flagship shopkeeper, and his designated digital operator (son/nephew/munshi). The LOI must commit him to (a) 3 consecutive days of shadow observation, (b) Saturday stopwatch / time-and-motion study, (c) Golden Hour photography session of ≥20 SKUs, (d) 30-minute daily app usage commitment for months 1–3, (e) content-asset ownership by Yugma Labs, (f) shopkeeper-role succession clause.
> 2. **Field observation complete** — the 3-day shadow + Saturday stopwatch data recorded and written up as a memo.
> 3. **Baseline metrics captured** — shopkeeper's actual current monthly order volume, lead volume, close rate, committee-decision frequency, typical ticket size, inventory size, informal udhaar cadence.
> 4. **Execution capacity declared** — §8 Constraint 13 completed with a named team composition.
> 5. **Runway horizon declared** — §8 Constraint 14 completed with a committed fallback.
> 6. **Primary-source verification of Firebase phone auth free quota** — screenshots of Alok's existing Firebase billing dashboard attached to the brief as an appendix.
>
> If any prerequisite is not completed within 4 weeks of project kickoff, halt and reassess."

### Edit 7 — §6 Success Criteria overhaul

- Replace absolute numbers with baseline-relative multipliers
- Split Month 3 gate into "technical" (with Mary coaching) and "adoption" (Month 5, without)
- Add "Kill Gates" subsection with concrete pivot/halt triggers:
  - Month 3 tech gate missed by >30 days → scope review
  - Month 6 orders metric <20% of target → halt v1.5, convene pivot
  - Month 9 no shop #2 LOI → reassess Triple Zero, consider monetizing shop #1 as single-shop business

---

## 5. Overall Verdict & Next Steps

**The brief is NOT YET READY for Winston handoff.** Seven CRITICAL red-team findings and twelve CATCHABLE pre-mortem failure modes make this a rework, not a polish. **But this is not a full rewrite** — the diagnosis in §2, the positioning philosophy, the "show don't sutra" discipline, the competitive framing, the two-pillar structure, and the multi-tenant strangler-fig concept are all sound. The damage is in the execution layer: the brief is running ahead of the shopkeeper, ahead of the team, ahead of the runway, and ahead of the field data.

The **meta-failure** both subagents identified independently: *documentation of a risk is being treated as a substitute for mitigation*. §9's Open Questions and Risks list has been doing double duty as a conscience release valve. Closing the Blockers is largely about converting "we know this is a risk" into "we have a blocking prerequisite or a named owner or a mitigation with teeth."

**Recommended path forward:**

1. **Alok reads this elicitation report in full** (it's saved to disk; full verbatim, not a summary). The red team is unflattering but fair. Don't skim.
2. **Mary applies the 7 Blocker edits to `product-brief.md`** and bumps it to v1.1. This is ~2 hours of focused editing work, not a rewrite.
3. **Alok commits answers** to the TBD fields: team size, runway horizon, execution capacity, and the go/no-go on Next Step 0 (shopkeeper LOI prerequisite).
4. **Field work executes** — the LOI, the 3-day shadow, the Saturday stopwatch, the baseline metric capture. This is weeks, not months, and cannot be skipped.
5. **Brief goes to v1.2** with the field data folded in, Material Risks added to §9, and Open Questions for the Shopkeeper closed.
6. **Only then** hand off to Winston for architecture.

**Estimated calendar time from here to Winston handoff: 3–5 weeks** if the field work is prioritized. Longer if shop #1 LOI takes more than one candidate.

**What I am NOT recommending:** a full brief rewrite, scrapping the two-pillar structure, dropping Triple Zero as a doctrine, or abandoning the Ayodhya flagship. Those are all sound — they just need tightening.

---

**Elicitation session complete.**
**Pre-mortem failure modes documented: 12.** 3 CAUGHT, 9 CATCHABLE, 0 SURPRISE.
**Red team attacks documented: 16.** 7 CRITICAL, 9 MATERIAL, 0 MINOR.
**Blockers identified: 7.**
**Material risks identified: 14.**
**Open questions for the shopkeeper: 9.**
