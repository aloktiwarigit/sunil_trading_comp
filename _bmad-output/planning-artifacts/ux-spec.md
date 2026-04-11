---
project_name: 'Almira-Project (Yugma Dukaan)'
flagship_shop: 'Sunil Trading Company (सुनील ट्रेडिंग कंपनी)'
shop_id: 'sunil-trading-company'
user_name: 'Alok'
author: 'Sally (BMAD UX Designer)'
date: '2026-04-10'
version: 'v1.1'
status: 'Draft v1.1 — Phase 4 BMAD back-fill (AE + Party Mode) on top of PRD v1.0.5 / SAD v1.0.4 / Epics v1.2 / Brief v1.4. John''s mandatory handoff applied: B1.13 invoice template, C3.12 banner 3 states + FAQ, S4.17 NPS card, S4.19 3-tap progression, S4.16 media spend tile, S4.10 reminder affordances. 5 AE methods run. 4-voice party mode (Sally + John + frontend-design + Mary). Walking Skeleton strategic notes 17 → 19. State catalog 29 → 67. Voice & tone strings 30 → 50. Constraint 4 font stack compliance patched throughout (Noto Sans Devanagari references replaced with Tiro Devanagari Hindi + Mukta).'
inputs:
  - product-brief.md (v1.4)
  - solution-architecture.md (v1.0.4)
  - prd.md (v1.0.5)
  - epics-and-stories.md (v1.2)
  - frontend-design-bundle/README.md
  - methods.csv (bmad-advanced-elicitation)
  - product-brief-elicitation-01.md
---

# UX Specification — Yugma Dukaan

**The strategic UX layer for the world-class digital storefront of Sunil Trading Company, Harringtonganj market, Ayodhya**

**Designer:** Sally (BMAD Senior UX Designer)
**For:** Alok, Founder, Yugma Labs
**Companion documents:** Product Brief v1.3, Solution Architecture v1.0.1, PRD v1.0.1, Epics & Stories v1.0, Elicitation Report 01
**Flagship:** Sunil Trading Company (सुनील ट्रेडिंग कंपनी), run by Sunil-bhaiya in the Harringtonganj furniture market of Ayodhya. ShopId: `sunil-trading-company`. Marketing subdomain: `sunil-trading-company.yugmalabs.ai`.

---

## Preamble — What this spec is (and isn't)

Mary wrote the *why*. Winston wrote the *how*. John wrote the *what*. I am here to write the *feel*.

This UX Spec is the strategic layer that sits above the wireframes and below the product strategy. It describes the five critical user journeys, the interaction patterns that tie screens together, the Hindi-first voice and tone that makes the product sound like Sunil-bhaiya instead of sounding like a translated template, the error/empty/loading state catalog that keeps the app warm when things go wrong, and the accessibility rules that stop Devanagari from clipping on the Realme C21 screen in Sunita-ji's son's hand.

What this is not: pixel-perfect wireframes (the `frontend-design` plugin produces those in parallel with this document), Flutter component code (Amelia's job), backend (Winston already specified), or a PRD rewrite (John already owns that). Where I cite a decision, I cite the source — Brief §, SAD §, PRD story ID, ADR number. Where I push back on a source document, I say so plainly. Mary, Winston, and John each invited pushback explicitly; politeness is how weak UX ships.

**Quality bar:** Alok has said "no shortcuts, world-class quality." I have taken the thorough path. This document is ~10,500 words. It is organized to be read section-by-section during design sprints, not front-to-back in one sitting.

A final framing note before we begin. For the next ten thousand words, please try to keep one image in your head: **it is an October afternoon in 2026, and Sunita-ji's son Rahul — twenty-three years old, works in a Lucknow BPO, home for Diwali — is sitting on a charpai in the verandah of their Faizabad house, holding a three-year-old Realme C21 with a cracked screen protector, trying to help his mother buy the almirah she has been thinking about for her younger daughter's wedding. Sunita-ji is sitting next to him. She does not want to hold the phone herself. She wants Rahul to hold it and show her the screen, and she wants to hear Sunil-bhaiya's voice explaining the polish, and she wants her husband in the office and her mother-in-law in the kitchen to all agree before anyone pays a single rupee.**

That moment is the product. Everything below is in service of it.

---

## §1 — UX Vision & Principles

### 1.1 — UX vision (one paragraph)

Yugma Dukaan feels like walking into Sunil-bhaiya's shop on a Tuesday afternoon — except you are sitting on your charpai in your own verandah, and Sunil-bhaiya is still standing behind his counter in Harringtonganj, and somehow both of those things are true at the same time. The app's first job is to make the customer forget she is using an app at all. Instead of a catalog, she sees Sunil-bhaiya's face. Instead of search filters, she sees the six almirahs *he* chose for weddings this week. Instead of a chatbot, she hears his actual voice telling her that *yeh wali lock thodi mazboot hai, didi*. When the shop is closed, the app tells her so, in his voice — *"aaj shaadi mein hoon, 6 baje wapas"* — and offers her his nephew's voice as an alternative. When her mother-in-law reaches for the phone, the app quietly puts on bigger glasses for her. And when the family has finally agreed and it is time to pay, the app gets out of the way and lets UPI do the five-second thing UPI does, taking nothing from Sunil-bhaiya. The two pillars — **Bharosa** (the shopkeeper is the product) and **Pariwar** (the committee is the user, not the individual) — are not features in a list. They are the air in the room.

### 1.2 — Ten UX principles

Every screen, every interaction, every copy decision in this product honors these ten principles. They are in priority order. When two principles conflict, the higher-numbered one wins.

**P1 — Hindi is the source of truth, not the translation.** Every string is drafted first in Devanagari by a speaker of Awadhi-inflected Hindi. The English string is the *translation*. In the codebase this means `strings_hi.dart` is authored by a human and `strings_en.dart` is derived from it (per ADR-008). In UX reviews this means no screen ships until a fluent reviewer has looked at the Devanagari version and asked "does this sound like the Harringtonganj market, or does it sound like a Mumbai newsroom?"

**P2 — The shopkeeper is the first thing the customer sees.** Not a logo, not a search bar, not a "Welcome to our app" splash. Sunil-bhaiya's face, his shop name in Devanagari, and within two seconds his actual voice. This principle is the Bharosa pillar made concrete. It is also how we refuse to look like Amazon.

**P3 — The committee is the user; the device holder is a courier.** The person holding the phone is almost never the person making the decision. Design for the decision-maker (who is sometimes fifty-five and cannot read 12pt text), not for the courier (who is sometimes twenty-three and has perfect eyes). This principle makes elder-tier, persona toggles, and shared threads non-negotiable — not polish items.

**P4 — Show, don't sutra.** The Brief's hard-won doctrine (§8 Constraint 10). Warmth lives in materials, photos, voice, typography, specificity. It does NOT live in mythic copywriting, in "blessings," in Sanskritized flourishes, in sacred-heirloom framing. A Devanagari headline that says *"स्टील अल्मीरा 4-दरवाज़ा भूरा"* is warmer than a Devanagari headline that says *"हर घर की रक्षिका"* because the first one is true and specific and the second one is a cliché. Specificity is warmth. Abstraction is cold.

**P5 — Zero-friction default; explicit friction only at commit.** The customer should never be asked to "sign up," "create an account," "set a password," or "enter her name" just to browse. Anonymous Auth happens silently before first paint. The one explicit trust ceremony — Phone OTP — happens only at the moment of committing to an order, and even that is feature-flagged because the Pre-Mortem Failure Mode #6 warned it may be a trust *rupture* in a relational economy (R12). Every friction must earn its place.

**P6 — Offline is the default state; connectivity is the privilege.** Tier-3 4G is a fantasy that holds for twenty minutes at a time. The app must be fully usable when the signal drops mid-chat. Cached reads, queued writes, drafts that survive airplane mode, voice notes that upload later without complaining. Every screen has to pass the "what happens on the third minute of no signal" test. (SAD §9 specifies the technical side; this spec says what it looks like.)

**P7 — Absence is presence.** When Sunil-bhaiya is not at the shop, the app says so in his voice. When a shortlist is empty, the app says *"अभी तक सुनील भैया ने इसमें कुछ नहीं चुना"* (Sunil-bhaiya hasn't chosen anything for this yet) with warmth, not *"No items found"* with cold apology. Absence is a design surface, not an edge case. Pre-Mortem Failure Mode #1 ("the shopkeeper never recorded the voice notes") means this principle is load-bearing: the app must gracefully degrade when the shopkeeper is a real tired human who records five notes in a month, not fifty.

**P8 — Elder-tier is respectful, not infantilizing.** Larger fonts, slower animations, louder voice notes, bigger tap targets — yes. But no pastel colors, no cartoon icons, no "easy mode" label, no diminishing language. Mummy-ji is not a user with a disability; she is a customer whose eyes are fifty-five years old and whose time deserves more patience than a twenty-three-year-old's. The elder tier is the default tier for a grown woman buying an almirah for her daughter's wedding. The fact that the son's tier is faster does not make it better.

**P9 — Curation is the default; infinite scroll is an emergency exit.** The customer should never have to choose between 200 SKUs. She should see the six Sunil-bhaiya chose for her occasion, and that should be enough. "Browse everything" exists behind an *"और दिखाइए"* (show more) button for the edge case where his curation missed something, but the happy path is always curated. This principle kills discovery by filter, kills the "Shop By Category" tab, kills the Amazon-shaped instinct to give users control they don't actually want.

**P10 — Triple Zero applies to attention too.** The Brief's economic discipline (zero commission, zero customer fees, ₹0 ops cost) has a UX corollary: zero attention tax. No upsells, no "rate this app" nags, no push notifications except transactional, no badges without meaning, no gamification. The customer's attention is a resource the shopkeeper has earned over twenty years, and the app does not get to spend it on Yugma Labs' behalf.

### 1.3 — The "first 30 seconds" test

Every customer who opens this app for the first time must, within thirty seconds, feel five specific things. If any of these five feelings are absent, we have failed the Bharosa pillar and every other feature is wasted.

**Second 0–2 — Recognition.** *"Yeh Sunil-bhaiya ki dukaan hai. Papa ne bataaya tha."* The shop's name in Devanagari, Sunil-bhaiya's face, the warm brown-and-gold color palette she half-remembers from walking past the shop once on a festival. She knows *whose* app this is before she knows *what* the app does.

**Second 2–5 — Voice.** Sunil-bhaiya's actual voice — not a narrator, not a chatbot, not a text-to-speech — saying *"Namaste, main Sunil. Harringtonganj mein meri dukaan hai. Aap jo dhoondh rahi hain, shayad yahan hai."* A muting toggle is visible but the default is auto-play. She feels the person behind the product, not the product.

**Second 5–12 — Sunday-best almirahs.** Six Golden Hour photos of almirahs that Sunil-bhaiya himself chose for weddings. Not two hundred. Not filtered by material and price range. Six. Each one is labeled *"शादी के लिए"* (for wedding) and has his signature tag *"सुनील भैया की पसंद"*. She feels curated, not flooded.

**Second 12–20 — Specificity.** Tapping one almirah shows her the raking-light photo full screen, the dimensions, the exact steel gauge, and a voice note from Sunil-bhaiya explaining *"is wali ka lock double-chain wala hai, saas-bahu ki zaroorat ke liye"*. Not Lorem Ipsum product copy. The specific reasons a specific shopkeeper thinks this specific almirah is right for her specific occasion.

**Second 20–30 — Permission, not pressure.** A "talk to Sunil-bhaiya" button is visible, but no modal has popped up, no "sign up" has been demanded, no "rate us" has begged for attention. She can close the app right now with no guilt and come back in three hours. She feels welcomed, not captured.

If all five of these feelings happen, the app has earned the right to exist in her phone. If any one is missing, she will close the app and go back to WhatsApp — and WhatsApp will win the moment that matters (Pre-Mortem Failure Mode #10, "WhatsApp Ate the Product"). The first thirty seconds are load-bearing.

---

## §2 — Personas & Decision Circles

Personas are not sketches. Each one is a specific human whose day and device and anxieties I can see. When I write a story, I write it *at* one of these people; when I decide whether a feature survives an edge case, I decide whether Sunita-ji would forgive the failure or abandon the app.

### 2.1 — Customer personas (four)

**Persona A — Sunita-ji Devi, the Wedding Mother** *(primary, highest volume, ~45% of v1 traffic)*

- **Age:** 48. Mother of two daughters, one marrying in three months.
- **Device:** Does not hold a phone in this app. Her son Rahul (23) holds his Realme C21 for her. When she takes it, she holds it at arm's length and squints.
- **Attention span:** Thirty unbroken minutes in the evening, fragmented by cooking, the gas man, the neighbor's child crying, and her husband calling to ask what she wants for dinner.
- **Primary anxiety:** *"What if I pick the wrong almirah and my daughter's mother-in-law sees it at the wedding and thinks we are cheap?"* Social reputation at the wedding is the real purchase. The almirah is a proxy.
- **Success moment:** Her mother-in-law hears Sunil-bhaiya's voice note about the polish quality and says, *"Haan, yeh theek hai, aapke pita-ji ki dukaan jaisa hi lagta hai."* The family has agreed. Nobody has lost face.
- **Frequency:** 1–2 purchases per lifetime. But she is the referral to four other wedding mothers in her social circle.

**Persona B — Amit Singh, the New Homeowner** *(second-largest, ~25% of v1 traffic)*

- **Age:** 34. Government engineer in Faizabad, just took possession of a PMAY house in a peri-urban colony.
- **Device:** His own phone, a Samsung M14. Reasonably fluent. Uses Amazon occasionally for electronics.
- **Attention span:** Forty minutes on Sunday morning with chai, before the day's errands begin.
- **Primary anxiety:** *"Will this last 15 years? My father's almirah from 1995 is still in the guest room."* Durability is the purchase. Looks are the tiebreaker.
- **Success moment:** He sees a steel-gauge spec, hears Sunil-bhaiya explain the hinge welding in a 20-second voice note, and decides without consulting anyone. Pays by UPI. Forty minutes end-to-end. No Amazon, no Pepperfry, no delivery damage story to tell.
- **Frequency:** Three separate Projects over 12 months (almirah → bed → dining table). He is the patient test of whether the app remembers him across Projects.

**Persona C — Geeta-ji Gupta, the Replacement Buyer** *(smaller but emotionally load-bearing, ~15% of v1 traffic)*

- **Age:** 61. Widow, lives with son and daughter-in-law. Her 1988 Godrej Storwel is rusting at the seams; the daughter-in-law wants it replaced before Diwali guests arrive.
- **Device:** Her son's phone, but she takes it often and holds it close. The elder-tier UX is for her. She pinch-zooms everything and still squints.
- **Attention span:** Long and deliberate. She will spend fifteen minutes on a single SKU. She is not shopping; she is deciding.
- **Primary anxiety:** *"Will this last as long as my Godrej did? And will it feel like mine, or like something my daughter-in-law picked for me?"* Continuity with the past is the real purchase.
- **Success moment:** She sees the raking-light photo of a steel almirah that looks almost exactly like her old Storwel (same pattern of handles), hears Sunil-bhaiya's voice saying *"Amma-ji, yeh Storwel ka beta hai, Godrej ka hi hai lekin naye zamaane ka"*, and she quietly nods. Her daughter-in-law does not have to convince her. Nobody lost face.
- **Frequency:** One purchase, but it is the one that generates the most loyalty. If Geeta-ji is happy, she tells four relatives at the next family function, and she remembers Sunil-bhaiya's voice for the rest of her life.

**Persona D — Rajeev Bhatt, the Dual-Use Small Buyer** *(~15% of v1 traffic)*

- **Age:** 42. Runs a paying-guest hostel with eight rooms; needs four budget almirahs for new tenants.
- **Device:** His own phone, a Tecno Spark. Hard negotiator. Checks three shops before deciding.
- **Attention span:** Short and pointed. Wants price, dimensions, availability, done. Will not watch voice notes; will skim them.
- **Primary anxiety:** *"Am I paying too much? Is there a 5% discount if I buy four?"* Price is the purchase. Everything else is negotiable.
- **Success moment:** The chat thread with Sunil-bhaiya produces a price proposal for four units at ₹32,000 total (down from ₹36,000 sticker). He accepts in the chat. Project commits. Done in ten minutes.
- **Frequency:** Repeat buyer. Comes back every 18 months as his hostel grows. The closest thing to a B2B buyer we serve in v1 — an individual committee-less purchase of 2–4 units, NOT a bulk contract (per Brief §5).

### 2.2 — The operator (Sunil-bhaiya) and his team

**Sunil-bhaiya himself** — 52, proprietor of सुनील ट्रेडिंग कंपनी, 20+ years at the same shop, inherited from his father in 2003. Multi-generational customer base: he remembers which family bought the Storwel for their eldest daughter's wedding in 2009 and recognizes them when they come back for the younger daughter's wedding in 2026. WhatsApp-fluent on his personal number. UPI user for personal payments; uses his shop's VPA for business. Does not think of himself as a "digital operator." He thinks of himself as a shopkeeper who happens to have a phone.

**Attention shape** (per Brief §12 Step 0.2 working defaults, which I accept but flag for revalidation):
- Free tap-minutes are clustered in three windows: 11:00–12:30 AM (before the lunch rush), 4:30–5:30 PM (post-afternoon-lull before the evening customer wave), and after 8:30 PM at home.
- Total uninterrupted tap-time across the day: 30–45 minutes on a good day, 10 minutes on a bad day.
- Voluntary voice-note-recording without prompting: rare. Expect 1–2 per week initially. Pre-Mortem Failure Mode #1 is the risk this spec takes most seriously.

**Implication for every ops app screen:** one-tap actions, no nested menus, no data-entry forms longer than five fields, every screen must work as a 30-second ritual rather than a 3-minute workflow. Pre-Mortem #12 ("nobody did the Saturday stopwatch") is still unmitigated — the brief says baseline defaults are in place, but no real observation has happened. The ops app UX must be *pessimistic* about the shopkeeper's attention, not optimistic.

**Aditya (bhaiya's nephew) — the beta role.** 27, has a day job at a Lucknow BPO, visits the shop on Sundays and evenings when he's in town. He is the digital operator in the brief's imagination but his real commitment is 4–6 hours a week, not 20 hours. This is the fragile assumption Pre-Mortem Failure Mode #4 surfaced. The ops app must work *even if Aditya logs in twice a month*, not assume he is a daily driver. The "beta" role's permissions are meaningful — inventory CRUD, photo capture, curation — but the bhaiya must remain the fallback if Aditya disappears for a week.

**Munshi (name TBD) — the munshi role.** Older than bhaiya, handles cash and ledger. Logs in maybe twice a week to record udhaar payments. His UX requirement is not "sophisticated dashboard"; it is "a big button labeled *'भुगतान दर्ज कीजिए'* that I can find without my glasses."

### 2.3 — Anti-personas (explicitly NOT our users)

From Brief §5, ruthlessly preserved:

- **D2C brand founders** wanting to sell their own label online. They are Dukaan's current target. If we design for them, we lose Sunil-bhaiya.
- **Urban metro furniture buyers** who want IKEA / Pepperfry / Urban Ladder UX. They are willing to trade shopkeeper relationships for next-day delivery and easy returns. If we design for them, we lose the Bharosa pillar.
- **Kirana / FMCG merchants** who need daily-use billing and inventory-per-hour management. Their operational tempo is hourly; our operational tempo is weekly. Designing for both produces neither.
- **Shopkeepers who do not want customer relationships** and prefer pure commodity sales. They are Meesho's bottom-of-funnel. If we design for them, "the shopkeeper is the product" becomes a lie.
- **B2B institutional buyers** — dharamshalas, pilgrim lodges, corporate canteens, chains. Explicitly out for v1. Their purchasing flow is contract-driven and requires GST invoicing, PO numbers, and multi-level approval. We are not building that in v1 or v1.5.

These anti-personas are worth re-stating in the UX spec because every design sprint will have moments where someone asks "what if a D2C founder wants to use this?" or "what if a kirana owner signs up?" The answer must be rehearsed: *we do not design for them, and every feature we add for them costs us Sunil-bhaiya.*

### 2.4 — The "device holder is not the buyer" insight

This is the single most important UX insight in this spec, and it cascades into every screen. Let me state it plainly.

**In at least 70% of the customer sessions this app will see, the person holding the phone is NOT the person making the purchase decision.** Sunita-ji does not hold the phone; her son Rahul holds it. Geeta-ji takes the phone from her son but holds it at arm's length and cannot press tiny buttons. Rajeev-ji holds his own phone but is negotiating on behalf of his hostel, not buying for himself. The "user" in a traditional UX sense — one person, one account, one decision — does not exist in this market.

This insight implies, for every screen:

1. **No personal "profile" tab.** A profile implies an individual user; we do not have individual users. We have Projects shared by committees. The bottom navigation has `दुकान / बातचीत / मेरे ऑर्डर` — no "Me" tab.

2. **No "you" language in copy.** "*Your* orders" in English sounds singular; in Hindi we say *आपके ऑर्डर* which is plural/formal. All copy is plural-respectful. Never singular-intimate.

3. **Persona toggle is always accessible.** The small "मैं देख रहा हूँ" button (I am the one looking) is visible on every screen, not buried in a settings menu. When the phone changes hands, the new holder can tap it in under 2 seconds and announce themselves. This is the Decision Circle session state (R11 + ADR-009, feature-flagged).

4. **Elder tier is not opt-in from a settings menu.** It is selected via the persona toggle — "Mummy-ji dekh rahi hain" — because the person who needs it is not going to navigate to Settings. The device holder does it *for* her, before handing her the phone. This is a crucial mental model: the elder tier is activated by someone else on the user's behalf.

5. **Shopkeeper sees who is currently looking.** On the shopkeeper's ops app, the Project detail screen shows *"अभी मम्मी-जी देख रही हैं"* (Mummy-ji is currently looking), so Sunil-bhaiya can adapt his next voice note to her — slower, more respectful, more addressed to her specifically. This is the committee experience made real on both sides of the thread.

6. **Chat thread shows persona attribution on each message.** When a customer-side text message arrives in the thread, it is labeled *"बहू ने कहा"* (the daughter-in-law said) or *"मम्मी-जी ने कहा"* (Mummy-ji said), not just "Customer said." The shopkeeper needs to know whose voice he is responding to.

**A clear flag on this insight:** R11 (Decision Circle unvalidated) means the persona toggle may get used zero times in the field, in which case Decision Circle collapses into a "large-text accessibility toggle" fallback (P2.8 in the PRD). **The UX must survive that outcome.** Every screen that references persona labels must have a fallback rendering for when the feature flag `decisionCircleEnabled` is `false`. I have specified this throughout §8.

---

## §3 — User Journey Maps (5 critical journeys)

Five journeys that I believe, after reading the brief and architecture and PRD in full, are the load-bearing paths through this app. Every other flow is a variation on one of these five. If these five are excellent, the app is excellent. If any of them feels wrong, the product feels wrong.

### 3.1 — Journey 1: First-time customer onboarding (the Walking Skeleton journey)

The journey that shipping this product lives or dies on. It is the Month 3 technical gate. It starts with Rahul tapping the app icon for the first time and ends with him handing his phone to his mother to hear Sunil-bhaiya's voice.

```
Rahul (son, 23)     Sunita-ji (mother, 48)    customer_app         Firebase/Firestore        Sunil-bhaiya (ops)
     │                       │                       │                       │                       │
     │ Taps app icon         │                       │                       │                       │
     │─────────────────────────────────────────────►│                       │                       │
     │                       │                       │ signInAnonymously()   │                       │
     │                       │                       │──────────────────────►│                       │
     │                       │                       │◄──── uid_anon ────────│                       │
     │                       │                       │                       │                       │
     │                       │                       │ Load ShopThemeTokens  │                       │
     │                       │                       │ Load greeting VN meta │                       │
     │                       │                       │──────────────────────►│                       │
     │                       │                       │◄──── 2 reads ─────────│                       │
     │                       │                       │                       │                       │
     │                       │                       │ RENDER: Sunil-bhaiya  │                       │
     │  ◄── Sees his face ──►│                       │ face, shop name in   │                       │
     │  "Ye wahi dukaan hai?"│                       │ Devanagari, warm     │                       │
     │                       │                       │ brown theme loaded   │                       │
     │                       │                       │                       │                       │
     │                       │                       │ AUTO-PLAY greeting    │                       │
     │                       │                       │ voice note (Cloud Stor)                       │
     │                       │                       │◄──── audio blob ──────│                       │
     │  ◄── Hears voice ─────►                       │                       │                       │
     │  "Namaste, main Sunil"│                       │                       │                       │
     │                       │                       │                       │                       │
     │ Scrolls curated list  │                       │ Read 1 shortlist doc  │                       │
     │                       │                       │ + 4 SKU docs          │                       │
     │                       │                       │◄──── 5 reads ─────────│                       │
     │                       │                       │                       │                       │
     │ Taps almirah #2       │                       │ Read SKU detail +     │                       │
     │                       │                       │ attached voice note   │                       │
     │                       │                       │◄──── 2 reads ─────────│                       │
     │                       │                       │                       │                       │
     │  "Mummy, ye dekho"    │                       │                       │                       │
     │────── hands phone ──►│                       │                       │                       │
     │                       │                       │                       │                       │
     │  Rahul reaches and    │                       │                       │                       │
     │  taps persona toggle  │                       │ Update DC participant │                       │
     │  → "Mummy-ji dekh     │                       │──────────────────────►│                       │
     │  rahi hain"           │                       │                       │                       │
     │                       │                       │ UI re-renders in      │                       │
     │                       │                       │ elder tier (+40% text,│                       │
     │                       │                       │ slower, bigger photos)│                       │
     │                       │                       │                       │                       │
     │                       │ Taps play on SKU voice│                       │                       │
     │                       │ note (louder volume)  │                       │                       │
     │                       │ "Yeh kya bol rahe hain?                       │                       │
     │                       │ Sunil-bhaiya sahi keh  │                       │                       │
     │                       │ rahe hain, lock mazboot │                      │                       │
     │                       │ hona chahiye"         │                       │                       │
     │                       │                       │                       │                       │
     │  ◄── takes phone back │                       │                       │                       │
     │  taps persona toggle  │                       │                       │                       │
     │  → "Wapas mujhe"     │                       │ DC updated            │                       │
     │                       │                       │──────────────────────►│                       │
     │                       │                       │                       │                       │
     │ Taps "Sunil-bhaiya se │                       │ Create Project draft +│                       │
     │ baat karein"          │                       │ chat thread           │                       │
     │                       │                       │ Decision Circle doc   │                       │
     │                       │                       │──────────────────────►│──────────────────────►│
     │                       │                       │                       │                       │
     │                       │                       │                       │  FCM push: new chat   │
     │                       │                       │                       │  "Sunita-ji (Rahul)   │
     │                       │                       │                       │  ne baat shuru ki"    │
     │                       │                       │                       │                       │
     │  Types: "Bhaiya, yeh  │                       │                       │                       │
     │  shaadi ke liye hai.  │                       │                       │                       │
     │  Price par discount?" │                       │                       │                       │
     │                       │                       │ Post message to thread│                       │
     │                       │                       │──────────────────────►│──────────────────────►│
     │                       │                       │                       │                       │
     │ [... conversation continues across days ...]  │                       │                       │
```

**Total Firestore reads for first session:** ~10–12 (well under the 30-read session budget from SAD §10). No OTP screen. No "sign up." No "welcome aboard." The app has been a shop, not an app, from second zero.

**UX-level acceptance criteria for this journey:**

- Within 2 seconds of app launch, Sunil-bhaiya's face is on screen.
- Within 5 seconds, his voice is audible (with a visible mute button that Rahul can hit if he's on a train).
- Within 30 seconds, Rahul has tapped a curated shortlist and is looking at a single almirah with a Golden Hour photo full-screen.
- The persona toggle is discoverable without any tutorial — it is a persistent button in the bottom-right corner of every screen with the current persona label visible.
- When Rahul passes the phone to his mother and she taps "Mummy-ji dekh rahi hain", the transition to elder tier is smooth (~300ms animated theme change), not jarring.
- No modal has popped up. No "rate us" has begged. No "sign up" has been demanded.

### 3.2 — Journey 2: Returning customer (silent sign-in)

The journey the founder said was a hard requirement: *one OTP per install, never again*.

```
Returning customer      customer_app              Firebase Auth (local)          Firestore
(2 weeks after           │                              │                             │
first commit)            │                              │                             │
       │                 │                              │                             │
       │ Opens app       │                              │                             │
       │────────────────►│                              │                             │
       │                 │ getCurrentUser()             │                             │
       │                 │─────────────────────────────►│                             │
       │                 │                              │                             │
       │                 │   refresh token used         │                             │
       │                 │   (no network OTP)           │                             │
       │                 │◄── AppUser(uid, phoneNumber) │                             │
       │                 │                              │                             │
       │                 │ Load Shop + ShopThemeTokens  │                             │
       │                 │ (probably cached)            │                             │
       │                 │──────────────────────────────────────────────────────────►│
       │                 │◄──── 0–2 reads ──────────────────────────────────────────│
       │                 │                              │                             │
       │                 │ Load existing Projects       │                             │
       │                 │ for this customerUid         │                             │
       │                 │──────────────────────────────────────────────────────────►│
       │                 │◄──── 1 read (cached) ────────────────────────────────────│
       │                 │                              │                             │
       │◄── LANDS on ────│                              │                             │
       │ previous Project│                              │                             │
       │ state (the chat │                              │                             │
       │ thread she was  │                              │                             │
       │ in, with 2 new  │                              │                             │
       │ voice notes from│                              │                             │
       │ Sunil-bhaiya)   │                              │                             │
       │                 │                              │                             │
       │ NO OTP screen. NO "welcome back." NO modal.                                  │
       │ The phone feels like she never left.                                         │
```

**UX-level acceptance criteria:**

- On cold launch of a returning customer, the landing must show the active Project (if any) with a "नए संदेश: 2" (2 new messages) indicator, NOT the generic curated shortlist landing.
- If there is no active Project (previous Project is `closed` or `cancelled`), the landing reverts to the first-visit curated landing, but with a subtle "वापसी पर स्वागत है" (welcome back) acknowledgment in the greeting voice note area.
- **Never** show the OTP screen on a returning visit. If the refresh token happens to expire (rare; only on explicit sign-out, app data clear, or manual revocation), the re-verification flow feels like a first-time flow, not a re-authentication interruption.

### 3.3 — Journey 3: Multi-person committee browsing (device changes hands)

The journey that validates the Pariwar pillar. This is the journey I am most nervous about — Pre-Mortem Failure Mode #3 warned that committees in 2026 may video-call instead of pass phones, which would make Decision Circle a beautiful answer to the wrong question. The spec must survive both outcomes.

```
Rahul (son)    Sunita-ji (mother)    Sunita-ji's mother-in-law    Husband (office)    Sunil-bhaiya (ops app)
     │               │                         │                         │                         │
     │ Opens app.    │                         │                         │                         │
     │ Persona =     │                         │                         │                         │
     │ "मैं देख रहा हूँ"│                         │                         │                         │
     │               │                         │                         │                         │
     │ Browses and   │                         │                         │                         │
     │ finds almirah │                         │                         │                         │
     │ #3 — promising│                         │                         │                         │
     │               │                         │                         │                         │
     │ Taps "Project │                         │                         │                         │
     │ shuru karein" │                         │                         │                         │
     │  → Project    │                         │                         │                         │
     │    draft +    │                         │                         │                         │
     │    DC created │                         │                         │                         │
     │               │                         │                         │                         │
     │ Hands phone   │                         │                         │                         │
     │ to Sunita-ji. │                         │                         │                         │
     │ BEFORE hand-  │                         │                         │                         │
     │ ing, taps     │                         │                         │                         │
     │ persona toggle│                         │                         │                         │
     │ → "मम्मी देख    │                         │                         │                         │
     │    रही हैं"     │                         │                         │                         │
     │               │◄── Phone in hand.       │                         │                         │
     │               │  Elder tier auto-      │                         │                         │
     │               │  loaded. Voice note    │                         │                         │
     │               │  auto-plays louder.    │                         │                         │
     │               │  Photos 40% bigger.    │                         │                         │
     │               │  Animations slower.    │                         │                         │
     │               │                         │                         │                         │
     │               │  On ops app side:       │                         │                         │
     │               │  Sunil-bhaiya sees      │                         │                         │
     │               │  "Currently looking:    │                         │                         │
     │               │  मम्मी-जी"  ───────────────────────────────────────────────────────────────►│
     │               │                         │                         │  "Ah, Mummy-ji hain.    │
     │               │                         │                         │  Meri agli voice note   │
     │               │                         │                         │  aisi banaani chahiye." │
     │               │                         │                         │                         │
     │               │ Types (or dictates to   │                         │                         │
     │               │ Rahul): "Bhaiya, polish │                         │                         │
     │               │ ki baat batao"          │                         │                         │
     │               │ Message sent with       │                         │                         │
     │               │ authorRole=customer     │                         │                         │
     │               │ persona=mummy_ji        │                         │                         │
     │               │ ───────────────────────────────────────────────────────────────────────────►│
     │               │                         │                         │                         │
     │               │                         │                         │  Records voice note     │
     │               │                         │                         │  addressed to "Mummy-ji"│
     │               │                         │                         │  specifically. Slower.  │
     │               │                         │                         │  Warmer.                │
     │               │◄─── Voice note arrives                             │                         │
     │               │     via FCM push                                    │                         │
     │               │     Plays in elder mode                             │                         │
     │               │     (louder default vol)                            │                         │
     │               │                         │                         │                         │
     │               │ Hands phone to           │                         │                         │
     │               │ mother-in-law in         │                         │                         │
     │               │ kitchen.                 │                         │                         │
     │               │  Taps persona toggle     │                         │                         │
     │               │  → "सास देख रही हैं"      │                         │                         │
     │               │                         │◄── Same elder tier.     │                         │
     │               │                         │    Re-plays Sunil-bhaiya's                        │
     │               │                         │    voice note from the top.                        │
     │               │                         │                         │                         │
     │               │                         │ Approves: "Haan, theek  │                         │
     │               │                         │ hai, polish achha hai." │                         │
     │               │                         │ Hands phone back.       │                         │
     │               │                         │                         │                         │
     │               │                         │  Phone travels back    │                         │
     │               │                         │  to Rahul.              │                         │
     │               │                         │  Persona toggled back   │                         │
     │               │                         │  → "वापस मुझे"           │                         │
     │                                                                    │                         │
     │                                                                    │ Husband receives FCM    │
     │                                                                    │ push on HIS phone       │
     │                                                                    │ (he installed it too,   │
     │                                                                    │ signed in anonymously,  │
     │                                                                    │ joined same DC via a    │
     │                                                                    │ deep link Rahul shared) │
     │                                                                    │                         │
     │                                                                    │ Opens app in office.    │
     │                                                                    │ Sees same chat thread,  │
     │                                                                    │ same Project, same      │
     │                                                                    │ Sunil-bhaiya voice note.│
     │                                                                    │ Posts: "Theek hai, le   │
     │                                                                    │ lo." from his device.    │
     │                                                                    │                         │
     │  ◄── All four devices show the same thread now. Sunil-bhaiya sees  │                         │
     │  all four participants in the Decision Circle. Project committable.│                         │
```

**Critical UX invariants for this journey:**

1. The persona toggle is the only "login ceremony" anyone ever sees. No phone numbers, no OTPs, no family member "invitations." Just taps.
2. The shopkeeper's ops app surfaces the currently-active persona on every screen so he can tailor his response. This is a superpower, not a gimmick.
3. When the husband opens the app on his phone for the first time (via a shared link), he lands directly in the Decision Circle — bypassing the greeting landing. The deep link carries the DC context.
4. If `decisionCircleEnabled` is flipped off (R11 fires empirically), this journey collapses to: one phone, one session, no persona labels, elder tier available via the simple accessibility toggle. The Project still works. The chat still works. The committee just coordinates via WhatsApp video on top of the app, as the pre-mortem warned they might already be doing.

**My strong pushback here:** the Brief calls Decision Circle "committee-native from the data model up … not a feature, a foundation" (§4.4). Winston correctly weakened this to "feature-flagged optional" in ADR-009 because R11 is unvalidated. I am going one step further and saying: **in the UX, the Decision Circle should feel delightful when it's there and invisible when it's not.** The PRD handles this correctly — P2.8 is the fallback. But I want to name it for the design team: **do not build Decision Circle as the visual centerpiece of any screen.** It is a silent superpower when it works. It is not a feature to evangelize on the landing page. If we put "powered by Decision Circle" anywhere visible, we will feel it in our teeth the day R11 fires.

### 3.4 — Journey 4: Shopkeeper daily morning routine (11:00 AM window)

The journey Sunil-bhaiya actually uses. Ten minutes, not thirty. One-tap everything.

```
Sunil-bhaiya           shopkeeper_app                       Firestore              FCM
     │                       │                                    │                  │
     │ Opens app at 11:02    │                                    │                  │
     │─────────────────────►│                                    │                  │
     │                       │ Silent Google sign-in (refresh)    │                  │
     │                       │                                    │                  │
     │                       │ Home dashboard loads               │                  │
     │                       │ Read: 20 latest Projects           │                  │
     │                       │──────────────────────────────────►│                  │
     │                       │◄──── 5 reads (denormalized) ──────│                  │
     │                       │                                    │                  │
     │◄── LANDS on: ────────│                                    │                  │
     │    "आज के 4 नए ऑर्डर" │                                    │                  │
     │    (4 new orders today)│                                   │                  │
     │    + "3 बातचीत बाकी" │                                    │                  │
     │    (3 chats pending) │                                    │                  │
     │    + "1 उधार खाता" │                                    │                  │
     │    (1 udhaar due)    │                                    │                  │
     │                       │                                    │                  │
     │ Taps chat pending #1  │                                    │                  │
     │ (Sunita-ji's project) │                                    │                  │
     │                       │ Read: Project + chat thread        │                  │
     │                       │ (last 10 messages) + customer     │                  │
     │                       │ memory (1 read each)              │                  │
     │                       │──────────────────────────────────►│                  │
     │                       │◄──── 4 reads ─────────────────────│                  │
     │                       │                                    │                  │
     │◄── Screen shows: ────│                                    │                  │
     │ Project summary +    │                                    │                  │
     │ customer memory      │                                    │                  │
     │ ("Sunita-ji ki saas  │                                    │                  │
     │ ne 2019 mein humari  │                                    │                  │
     │ Storwel li thi")     │                                    │                  │
     │ + last customer msg: │                                    │                  │
     │ "Bhaiya, polish kab?"│                                    │                  │
     │                       │                                    │                  │
     │ Long-presses 🎤       │                                    │                  │
     │ Records 15-sec voice  │                                    │                  │
     │ note in his own       │                                    │                  │
     │ voice: "Polish 2 din  │                                    │                  │
     │ mein ho jayega."      │                                    │                  │
     │                       │ Upload voice note to Cloud Storage │                  │
     │                       │ Create message doc                 │                  │
     │                       │──────────────────────────────────►│                  │
     │                       │                                    │                  │
     │                       │ Trigger FCM push to customer      │                  │
     │                       │──────────────────────────────────────────────────────►│
     │                       │                                    │                  │
     │ Swipes to chat #2,    │                                    │                  │
     │ #3... same flow       │                                    │                  │
     │                       │                                    │                  │
     │ Taps "मेरी पसंद"     │                                    │                  │
     │ (curation tab)        │                                    │                  │
     │                       │                                    │                  │
     │ Sees shaadi shortlist │                                    │                  │
     │ Long-presses one SKU, │                                    │                  │
     │ drags to position 1.  │                                    │                  │
     │                       │ Write: shortlist reorder           │                  │
     │                       │──────────────────────────────────►│                  │
     │                       │                                    │                  │
     │ Total time spent: 8   │                                    │                  │
     │ minutes. Closes app.  │                                    │                  │
```

**UX-level acceptance criteria for the morning routine:**

- The home dashboard is not a dashboard — it is a **triage list**. Three sections: "आज के नए ऑर्डर" (new orders today), "बातचीत बाकी" (pending chats), "उधार खाता" (udhaar due today). Numbers on each, tappable to drill in.
- No charts, no graphs, no "week over week revenue" — that is on a separate Analytics tab that the shopkeeper visits on Sunday mornings, not on weekday mornings.
- Every action is one tap or one long-press. No multi-screen flows for the core daily actions.
- Voice note recording is press-and-hold (record while held, stop on release). Not "tap to start, tap to stop." The press-and-hold is muscle memory from WhatsApp voice notes — it is the one interaction pattern the shopkeeper already knows cold.
- After sending a voice note, the screen immediately returns to the triage list, not a confirmation screen. The shopkeeper should be able to reply to 5 chats in 60 seconds.
- The curation screen — "मेरी पसंद" — is a single screen with six tabs (one per occasion) and drag-to-reorder. No nested menus. This is the "remote control for his finger" realized (per PRD B1.12 and Brief §3).

### 3.5 — Journey 5: Customer with udhaar khaata (partial payment → installments)

The journey that validates Pariwar's most emotionally and legally sensitive feature. Pre-Mortem Failure Mode #5 ("the udhaar khaata became a collections nightmare") and Red Team Attack #12 (RBI regulatory surface) both fire here. The UX must be flawless.

```
Sunita-ji's family      customer_app           Firestore            Sunil-bhaiya (ops)
(post commit,           │                         │                         │
product delivered)       │                         │                         │
       │                │                         │                         │
       │ Has just       │                         │                         │
       │ committed to   │                         │                         │
       │ ₹22,000 almirah│                         │                         │
       │                │                         │                         │
       │ Pays ₹5,000 via│                         │                         │
       │ UPI            │                         │                         │
       │────────────────►│                         │                         │
       │                │ UPI intent returns      │                         │
       │                │ Project state →         │                         │
       │                │ "partial_paid" (TBD)   │                         │
       │                │                         │                         │
       │                │ (Sunil-bhaiya sees the  │                         │
       │                │ partial payment + Project                          │
       │                │ balance of ₹17,000)                                │
       │                │                         │                         │
       │                │                         │                         │ Shopkeeper decides
       │                │                         │                         │ "Sunita-ji ki family
       │                │                         │                         │ bharose-mand hai, Storwel
       │                │                         │                         │ bhi yahin se thi 2019 mein.
       │                │                         │                         │ Udhaar le lo."
       │                │                         │                         │
       │                │                         │ Taps "उधार खाता शुरू   │
       │                │                         │ करें" on Project detail │
       │                │                         │                         │
       │                │                         │ Dialog: "कितना आज       │
       │                │                         │ दिया? बाकी?"            │
       │                │                         │ Enters: today=5000,    │
       │                │                         │ balance=17000           │
       │                │                         │                         │
       │                │                         │ UdhaarLedger doc        │
       │                │                         │ created.                │
       │                │                         │ Note field: "Bhabhi ne  │
       │                │                         │ kaha shaadi ke baad    │
       │                │                         │ poora denge"            │
       │                │                         │                         │
       │◄── FCM push: ─────────────────────────────────────────────────────  │
       │  "सुनील भैया ने  │                         │                         │
       │  उधार खाता       │                         │                         │
       │  प्रस्तावित किया है" │                     │                         │
       │                │                         │                         │
       │ Opens app      │                         │                         │
       │ Sees bottom-sheet:                        │                         │
       │ "सुनील भैया से   │                         │                         │
       │ udhaar khaata:  │                         │                         │
       │ आज दिया: ₹5,000 │                         │                         │
       │ बाकी: ₹17,000   │                         │                         │
       │ [स्वीकार करें] [अस्वीकार]"                 │                         │
       │                │                         │                         │
       │ Taps स्वीकार   │                         │                         │
       │                │ acknowledgedAt updated  │                         │
       │                │────────────────────────►│                         │
       │                │                         │                         │
       │ 30 days later: customer pays ₹4,000      │                         │
       │                │                         │                         │ Taps "भुगतान दर्ज    │
       │                │                         │                         │ कीजिए" on the ledger│
       │                │                         │                         │ Enters: 4000, UPI   │
       │                │                         │ Running balance updated │
       │                │                         │ → 13000                 │
       │                │                         │◄────────────────────────│
       │                │                         │                         │
       │ 37 days later: still ₹13,000 due         │                         │
       │                │                         │                         │
       │                │ sendUdhaarReminder Cloud Function fires           │
       │                │ (via FCM, never SMS)                              │
       │                │                         │                         │
       │◄── FCM push: ──│                         │                         │
       │ "आपका खाता:     │                         │                         │
       │ सुनील भैया में   │                         │                         │
       │ ₹13,000 बाकी"   │                         │                         │
       │                │                         │                         │
       │ NO "OVERDUE," NO "DEFAULT," NO "LATE FEE." │                         │
       │ Just a soft reminder, in his voice if    │                         │
       │ a voice-note variant exists.              │                         │
```

**UX-level acceptance criteria for the udhaar journey:**

1. **Shopkeeper-initiated only.** The customer never sees a "start udhaar khaata" button anywhere. Only the shopkeeper can initiate it, and only after the customer has committed to the Project. This is non-negotiable (per Brief §9 R10, ADR-010, and PRD standing rule #8).

2. **Copy discipline — forbidden vocabulary never appears in UI.** The words `ब्याज` (interest), `देय तिथि` (due date), `जुर्माना` (fee), `ऋण` (loan), `उधारी` (borrowing), `वसूली` (collection) MUST NOT appear on any screen. The word `खाता` (account/ledger) is the only permitted framing. This is an accounting mirror of a social agreement, not a lending instrument.

3. **The customer sees a simple running balance, not a "dues schedule."** A single number — *"बाकी: ₹13,000"* — with a history of partial payments. No projected dates, no payment plan, no "next installment due on..." Just what's paid and what's left.

4. **Reminder copy is warm, not clinical.** The `sendUdhaarReminder` Cloud Function (SAD §7) must use phrasing like *"आपका खाता सुनील भैया में: ₹13,000 बाकी है"* (Your account with Sunil-bhaiya: ₹13,000 remaining). Never *"पेमेंट ओवरड्यू"* or *"आपका लोन लेट है"*. The §5 voice/tone guide below has the full forbidden vocabulary list.

5. **Customer can always initiate a payment — but never "the next installment."** The payment screen simply asks "कितना भुगतान कर रहे हैं?" (How much are you paying?) with a free-text field, defaulting to the full remaining balance. There is no notion of "installments" because installments imply a schedule, and a schedule implies obligation, and obligation is lending vocabulary.

6. **On full settlement, there is a small celebratory moment.** When `runningBalance` hits 0, the customer's app shows a one-time soft animation (check-mark in Sunil-bhaiya's brand color) and a Devanagari message: *"खाता पूरा हुआ। धन्यवाद।"* (Account settled. Thank you.) Nothing more. No fanfare, no confetti. This is the warmth living in specificity, not in mythic copy.

---

## §4 — Interaction Patterns

The reusable behaviors that, once decided, apply everywhere. Each pattern below names its consumers (which PRD stories use it) and its cross-references (other §'s in this spec).

### 4.1 — Bottom tab navigation (customer app)

**Three tabs. No profile tab. No hamburger menu. No secondary navigation drawer.**

```
┌─────────────────────────────────────┐
│                                     │
│    [ screen content area ]          │
│                                     │
│                                     │
├─────────────────────────────────────┤
│   दुकान    │  बातचीत    │ मेरे ऑर्डर │
│   (home)   │  (chats)   │  (orders) │
└─────────────────────────────────────┘
     🏠          💬         📦
```

**Rationale:** Three is the maximum for a Hindi-first bottom nav where each label is 5–8 characters in Devanagari. Four would clip on 4.5" screens. Profiles and settings are intentionally absent — there is no "user account" in this app; there are only Projects and the shopkeeper's shop.

**Elder tier override:** When the active persona is an elder persona, the icon shrinks and the Devanagari label becomes the dominant visual element (56dp tap targets, 16sp Devanagari text, no icon-only states).

**Feature-flag-off override:** If `decisionCircleEnabled` is false, the persona toggle button (which floats above the bottom tabs) is hidden. The tabs stay. The app still works.

### 4.2 — Bottom tab navigation (shopkeeper ops app)

**Five tabs. Shopkeeper ops has more surface area.** (For the munshi role, two tabs are hidden — see §4.2.1.)

```
┌──────────────────────────────────────┐
│                                      │
│    [ screen content area ]           │
│                                      │
├──────────────────────────────────────┤
│आज की सूची│ऑर्डर│बातचीत│मेरी पसंद│और  │
│(today)   │     │    │(curation)│more│
└──────────────────────────────────────┘
    📋        📦    💬       ⭐      ⋯
```

- **आज की सूची** (Today's triage) — the morning-routine screen, lands here on every launch.
- **ऑर्डर** (Orders) — the Project list with filters.
- **बातचीत** (Chats) — aggregated chat inbox across all Projects.
- **मेरी पसंद** (My picks) — the curation screen, the "remote control for the finger."
- **और** (More) — inventory, customer memory, udhaar ledger, settings, sign-out.

#### 4.2.1 — Role-based tab visibility

| Tab | bhaiya | beta (Aditya) | munshi |
|---|---|---|---|
| आज की सूची | ✅ | ✅ | ✅ |
| ऑर्डर | ✅ | ✅ | ✅ |
| बातचीत | ✅ | ✅ | ❌ (hidden) |
| मेरी पसंद | ✅ | ✅ | ❌ (hidden) |
| और → Inventory | ✅ | ✅ | ❌ |
| और → Udhaar | ✅ | ❌ | ✅ |
| और → Customer memory | ✅ | ✅ | ❌ |
| और → Settings | ✅ | ❌ | ❌ |

The munshi's app is deliberately narrower — two visible tabs, one "और" sub-screen with udhaar ledger. This is not limitation; it is focus.

### 4.3 — Curation discovery vs infinite scroll

**Default path: curated shortlists.** The customer lands on the shop landing (B1.1 / B1.2), scrolls down to see six occasion shortlists, taps one, sees 4–6 SKUs the shopkeeper chose, taps one, enters SKU detail. That is the happy path. Infinite scroll does not exist on this path.

**Emergency exit: "और दिखाइए" (show more).** On any shortlist screen, at the bottom, a small button *"और दिखाइए"* expands the shortlist to paginated inventory. This is the only way to see SKUs that are not in any curated shortlist. It is deliberately de-emphasized — no filter bar, no category tabs, no search-by-price. Just "show me more almirahs Sunil-bhaiya has." **This button should feel like a back door, not a front door.**

**Why this extreme?** Pre-Mortem Failure Mode #1 (the shopkeeper doesn't record many voice notes) and Red Team Attack #14 (the vertical moat is shallow) both suggest that the Bharosa pillar is our only real differentiation. If we let customers browse like Amazon, we become Amazon with a Hindi toggle. The curation discipline is what makes Sunil-bhaiya's app feel like Sunil-bhaiya's shop.

**What I am pushing back on:** the PRD B1.4 specifies "paginated to load more on scroll" within a shortlist. I want to soften this: a shortlist is *finite*. If Sunil-bhaiya put six almirahs in his "shaadi ke liye" shortlist, the customer sees six. No pagination. No "load more." The finiteness of the curation is the feature. Pagination suggests the curation is a first page of a search result, which it is not. I am asking Winston/John to revisit this with me.

### 4.4 — Voice note interaction pattern

**Recording (shopkeeper side, PRD B1.6/B1.7/B1.8, S4.8):**

- **Press-and-hold** to record. Release to stop. This is the WhatsApp muscle memory Sunil-bhaiya already has.
- A waveform animates during recording with a duration counter (in Devanagari numerals, 0..60 seconds).
- On release: three buttons — `भेज दीजिए` (send), `दुबारा रिकॉर्ड करें` (re-record), `रद्द करें` (cancel).
- Minimum duration: 5 seconds (to prevent accidental "air" sends). Maximum: 60 seconds.
- Lock-mode slide: sliding the recording button up locks recording (so the shopkeeper can put the phone down) — again, WhatsApp muscle memory.

**Playback (customer side, PRD P2.6, B1.3):**

- Inline player widget with play/pause, waveform scrubber, duration, sender label.
- **Single-player discipline:** only one voice note plays at a time; starting a new one auto-pauses any currently playing voice note. This prevents accidental overlap.
- **Auto-play rules:**
  - The shop landing greeting voice note auto-plays on first app visit, with a visible mute button. Subsequent visits respect the user's previous mute preference.
  - Voice notes attached to SKUs or chat messages do NOT auto-play. The user must tap to start.
  - Voice notes attached to "away" status banners (B1.10) auto-play when the customer taps the away banner, not when the banner appears.
- **Persona-aware volume:** When the active persona is an elder persona, the default playback volume is 30% louder than the default persona, and the system media volume is automatically raised (not overridden) via a media session callback. This respects the device's silent mode — never force-plays through silent mode.
- **Offline playback:** Voice notes are cached aggressively by the Firebase Storage SDK. Once played, they work offline indefinitely. A "downloaded for offline" badge appears after first play.

### 4.5 — Decision Circle persona toggle UX

The single most architecturally interesting UI decision in the customer app. A small floating button, always visible, always one tap away from changing the active persona. Here is the interaction:

```
Current state: persona = default ("मैं देख रहा हूँ")

  ┌─────────────────────────────────────┐
  │                                     │
  │   [ screen content ]                │
  │                                     │
  │                                     │
  │                                     │
  │                      ┌───────────┐  │   ← Floating pill, 56dp tall,
  │                      │ मैं देख    │  │     bottom-right, above tab bar
  │                      │ रहा हूँ     │  │     Labeled with current persona
  │                      └───────────┘  │
  ├─────────────────────────────────────┤
  │   दुकान | बातचीत | मेरे ऑर्डर      │
  └─────────────────────────────────────┘

TAP the pill →

  ┌─────────────────────────────────────┐
  │                                     │
  │           अभी कौन देख रहा है?         │
  │           (Who is looking now?)     │
  │                                     │
  │   ┌──────────────┐  ┌─────────────┐│
  │   │  मैं देख रहा   │  │ मम्मी जी    ││
  │   │  हूँ          │  │ देख रही हैं  ││
  │   └──────────────┘  └─────────────┘│
  │                                     │
  │   ┌──────────────┐  ┌─────────────┐│
  │   │  पापा जी       │  │  दादी      ││
  │   │  देख रहे हैं    │  │ देख रही हैं  ││
  │   └──────────────┘  └─────────────┘│
  │                                     │
  │   ┌──────────────┐  ┌─────────────┐│
  │   │  भाभी         │  │  कोई और    ││
  │   │  देख रही हैं    │  │ (free text) ││
  │   └──────────────┘  └─────────────┘│
  │                                     │
  └─────────────────────────────────────┘
```

**Visual signal for active persona:**
- The pill label on every screen changes to the new persona name.
- The top bar of every screen shows a subtle indicator: `"मम्मी जी देख रही हैं"` in small text, centered.
- The Project/chat screens on the shopkeeper side show the same indicator in his ops app — the committee awareness is bilateral.

**Elder tier transition animation:**
- 300ms smooth animation from default tier to elder tier (or vice versa).
- The screen "grows up" — fonts enlarge, spacing opens, photos swell. Not a jarring re-render.
- Voice notes currently playing adjust volume on the fly, not on the next play.

**Fallback when `decisionCircleEnabled = false`:**
- The floating pill is hidden entirely.
- The persona-aware elements (top bar indicator, bilateral ops-app awareness, read-tracking attribution in chat) are hidden.
- **BUT** the elder tier is still accessible via a simple `बड़ा अक्षर` (large text) toggle in a minimal Settings screen (PRD P2.8). The elder tier itself is not feature-flagged; only the persona-labeling layer is.

### 4.6 — Elder tier transformation

When the active persona is an elder (Mummy-ji, Papa-ji, Dadi, Chacha-ji, or the universal large-text toggle), the customer app transforms. The exact transformations are specified in PRD P2.3 and the Accessibility Spec (§7 below). Here is the UX-level picture:

| Property | Default tier | Elder tier |
|---|---|---|
| Body text size | 14sp (Devanagari) | 20sp (≈1.4×) |
| Heading text size | 20sp | 28sp |
| Tap target minimum | 48dp | 56dp |
| Photo card aspect | 4:3 | 3:2 (wider, more space) |
| Animation duration | 200ms standard | 300ms standard |
| Bottom nav style | icon + label | label only (no icon, larger text) |
| Voice note default volume | System media volume | System + 30% (via MediaSession, never overriding silent mode) |
| Background color | cornsilk warm | cornsilk warm (unchanged) |
| Contrast ratio | WCAG AA (4.5:1) | WCAG AAA (7:1) |
| Line height | 1.4 | 1.6 |
| Spacing between list items | 12dp | 20dp |
| Color palette | full | unchanged (never pastels) |

**What does NOT change in elder tier:**
- The brand colors. Mummy-ji does not want a "senior mode" color scheme. She wants Sunil-bhaiya's shop colors, but bigger.
- The Devanagari font. Tiro Devanagari Hindi (display) and Mukta (body) render well at both sizes. We do not switch to a "simpler" font. *(v1.1 patch — was "Noto Sans Devanagari and Mukta" in v1.0; updated to match Brief v1.4 Constraint 4 + the frontend-design bundle's canonical font stack.)*
- The content. Every piece of information is present. Elder tier is not "simplified content" — it is the same content, respected.
- The Devanagari font weight. We do NOT bold-up the font for elder tier because bold Devanagari clips on cheap Android conjunct rendering. Stay at regular weight; increase size only.

### 4.7 — Chat thread interaction (Sunil-bhaiya Ka Kamra)

The chat thread is structurally similar to WhatsApp, deliberately — the muscle memory carries over. But there are five meaningful differences.

**Message types supported:**
1. **Text** — plain Devanagari or English, left-aligned for customer, right-aligned for shopkeeper (per Hindi reading convention, shopkeeper-right may need revisiting with a Hindi-native reviewer; possible that Hindi right-to-left conventions want both on left and differentiate via color).
2. **Voice note** — inline player widget with waveform.
3. **Image** — shopkeeper can share additional inventory photos; customer cannot upload images in v1 (deferred to v1.5 to prevent spam/abuse).
4. **System** — state transitions ("Project committed", "Payment received", "Delivered"), rendered as centered gray pills, not as messages with a sender.
5. **Price proposal** — special interactive card (see 4.8) from shopkeeper with accept/reject buttons.

**Layout rules:**
- Messages render oldest-to-newest, top-to-bottom (standard chat convention).
- Pagination: initially loads the last 20 messages. Scrolling up loads 20 more. No "load all" button.
- Persona attribution: customer-side messages carry a small persona label (`"बहू"`, `"मम्मी जी"`, `"मैं"`) below the author name. Shopkeeper-side messages carry the operator's name (`"सुनील भैया"`, `"आदित्य"`, `"मुंशी जी"`).
- Timestamp: relative time in Devanagari (`"2 घंटे पहले"`, `"कल"`, `"अभी-अभी"`), with absolute timestamp on long-press.

**Offline draft handling:**
- If the customer types a message while offline, the message is saved in Riverpod persistence with a `pending` badge.
- When connectivity returns, the message is sent automatically, and the badge becomes a checkmark.
- If the app is closed and reopened offline, the draft is still there, waiting.
- If the customer explicitly cancels a pending message, it is deleted from local storage.
- A pending message does NOT count toward the unread count on the shopkeeper's side (it hasn't been sent yet).

**Real-time updates:**
- Firestore real-time listeners keep the thread fresh without polling.
- New messages appear at the bottom with a subtle slide-in animation.
- If the customer is scrolled up looking at history, a "नए संदेश ↓" pill appears at the bottom.

### 4.8 — Negotiation in chat (price proposal message type)

A structural decision from PRD C3.3: negotiation happens inside the chat thread via a special `price_proposal` message type. No separate "make an offer" UI.

**How the shopkeeper sends a price proposal (ops app):**
- From the chat thread, a `मूल्य प्रस्ताव` (price proposal) button next to the text input.
- Tap opens a sheet: select a line item from the Project, enter the proposed price, confirm.
- The proposal is sent as a special message type to the chat thread.

**How the customer sees a price proposal (customer app):**
- Renders as a card inline in the chat, not a plain text message.
- Card content:
  - Line item name + current price (struck through)
  - New proposed price (large, in shop accent color)
  - Two buttons: `स्वीकार करें` (Accept) and `और बात करें` (Discuss more)
  - A small footer: "सुनील भैया ने प्रस्ताव किया, 3 बजे" (Sunil-bhaiya proposed, at 3 PM)

**Acceptance flow:**
- Tapping Accept: the LineItem's `finalPrice` updates; the Project `totalAmount` recomputes; a system message appears in the chat: *"Sunita-ji ne naya daam maana: ₹13,500"* (Sunita-ji accepted the new price: ₹13,500).
- The shopkeeper sees the acceptance in real time. He can then make another proposal if he wants (for a different line item, or a counter-proposal if the customer had previously pushed back).

**Rejection flow:**
- Tapping `और बात करें` (Discuss more) simply closes the card and lets the customer type a text response. There is no explicit "reject" button. Negotiation continues naturally.

**Copy tone:**
- Never "discount," "offer," "deal." Always "daam" (price) or "mulya" (value).
- Never "last price," "final offer." Shopkeepers in Tier-3 India do not frame negotiation as a one-shot transaction; it is a conversation.

### 4.9 — Commit + payment flow (Phone OTP ceremony)

The most architecturally fraught flow in the app. R12 specifies that OTP at commit may cause a 64% drop-off in a relational economy. The `otpAtCommitEnabled` feature flag allows skipping OTP entirely. The UX must handle both cases.

**Case A: OTP enabled (default)**

```
Customer on Project detail →
Taps "ऑर्डर पक्का कीजिए" →

Bottom sheet slides up:
  "ऑर्डर पक्का करने के लिए
   आपका फ़ोन नंबर चाहिए।
   सुनील भैया डिलीवरी के लिए
   संपर्क करेंगे।"
   (To confirm the order, we need your phone number.
    Sunil-bhaiya will contact you for delivery.)

  [ Phone number input: +91 __________ ]

  [ Continue → ]

Tap Continue →
  OTP sent via Firebase Phone Auth →

Bottom sheet updates:
  "आपके फ़ोन पर 6-अंक का कोड भेजा है।"
  (A 6-digit code has been sent to your phone.)

  [ OTP input: _ _ _ _ _ _ ]

  [ Verify → ]

Tap Verify →
  LinkWithCredential →
  Anonymous session upgrades to Phone-verified →
  Decision Circle, chat, Project all survive →

Success screen (full screen, not bottom sheet):
  "ऑर्डर पक्का हुआ!
   अब भुगतान का तरीका चुनिए।"
   (Order confirmed! Now choose how to pay.)

  [ Large primary button: UPI से दीजिए ]
  [ Smaller link: और तरीके (other ways) ]
```

**Critical framing note on the OTP prompt:** Notice the copy. It does NOT say "verify for your security" — it says "Sunil-bhaiya will contact you for delivery." This reframes the OTP as *shopkeeper-initiated practical need*, not as *app-level distrust* (Pre-Mortem Failure Mode #6 directly addressed). The Hindi version is even more important than the English version.

**Case B: OTP disabled (feature flag off, R12 kicked in)**

```
Customer on Project detail →
Taps "ऑर्डर पक्का कीजिए" →

Immediate transition to payment screen.
No phone number ask.
No OTP.
Phone number is captured at UPI payment time (from the VPA).

Success screen:
  "ऑर्डर पक्का हुआ!
   अब भुगतान का तरीका चुनिए।"

  [ UPI से दीजिए ]
  [ और तरीके ]
```

**Case C: OTP enabled but customer refuses / fails 3 times**

If the customer enters the wrong OTP 3 times, we show:
- *"अभी कोड verify नहीं हो रहा। आप बिना verify किए भी ऑर्डर पक्का कर सकते हैं — सुनील भैया आपसे बाद में संपर्क करेंगे।"* (Can't verify the code right now. You can still confirm the order without verifying — Sunil-bhaiya will contact you later.)
- A button `बिना verify किए आगे बढ़ें` (Continue without verifying) that skips OTP and goes to the payment screen.
- This is a soft fallback that preserves the funnel even if individual customers reject the OTP flow.

**UPI deep link UX after commit:**
- Big primary button, full width, UPI logo prominent.
- Three secondary app icons: PhonePe, GPay, Paytm (visual reassurance of compatibility).
- Tap triggers the UPI intent — the OS handles app selection.
- On return from the UPI app: success → state transition to `paid`; failure → retry screen with "और तरीके" (other ways).

**COD / Bank transfer / Udhaar fallback paths:**
- All behind the `और तरीके` link (smaller, secondary).
- Tap expands a vertical list of three options: `डिलीवरी पर नकद` (Cash on Delivery), `बैंक ट्रांसफर` (Bank Transfer), `उधार खाता` (only visible if the shopkeeper has enabled it for this specific customer — per ADR-010, udhaar is shopkeeper-initiated only).
- Each option leads to its specific flow (C3.6, C3.7, C3.8).

### 4.10 — Honest absence (presence status)

How the shop tells the customer honestly when Sunil-bhaiya is not available.

**Presence states** (from PRD B1.9):
- `available` — no banner.
- `away` — soft banner at top of shop landing: *"सुनील भैया अभी दुकान पर नहीं हैं"* with estimated return time and optional play button for an away voice note.
- `busy_with_customer` — banner: *"सुनील भैया अभी किसी ग्राहक के साथ हैं"*.
- `at_event` — banner: *"सुनील भैया आज शाम एक शादी में हैं, 9 बजे तक वापस"*.

**Banner rendering rules:**
- Banner appears at the top of the shop landing, NOT as a full-screen modal. It does not block browsing.
- Banner has a soft warning color (amber-tinted, not red). Red is for errors; this is not an error.
- Banner includes an optional play button if an away voice note is attached (PRD B1.10).
- Banner includes a "चर्चा जारी रखें" (continue the conversation) link that opens the chat thread — the customer can still type, and the messages are queued for Sunil-bhaiya's return.
- Banner auto-dismisses when the estimated return time passes and status auto-reverts to `available`.

**Elder tier adjustment:**
- In elder tier, the away voice note auto-plays when the banner appears (not on tap), at increased volume, because Mummy-ji should not have to search for a play button.

**Fallback for no-voice-note-recorded:**
- If the shopkeeper has not recorded any away voice notes (Pre-Mortem Failure Mode #1 reality), the banner shows only text. The feature degrades gracefully.

### 4.11 — Devanagari invoice / receipt template (B1.13) *(v1.1 add)*

The invoice is the most typographically demanding artifact in the entire product. Unlike every other screen, the receipt has to render correctly not just inside our Flutter app but inside WhatsApp's PDF preview, Gmail's attachment viewer, and (most stressfully) on the cheap Android print drivers Sunil-bhaiya's customers occasionally use. Every typographic decision in the template is subordinated to that reality.

**Typographic hierarchy — Constraint 4 compliant:**

| Zone | Font | Size | Weight | Why this and not Caveat / Inter / Roboto |
|---|---|---|---|---|
| Shop name (header) | **Tiro Devanagari Hindi** | 32pt | Regular | Display face — designed for Devanagari clarity at headline sizes; the only Constraint-4 font with real display character |
| Tagline / address / GST line | **Mukta** | 11pt | Regular | Body face — reads cleanly at small sizes on cheap print drivers |
| Line item names (Devanagari) | **Mukta** | 12pt | Regular | Same rationale |
| Line item prices / totals / Project ID | **DM Mono** | 12pt (prices) / 16pt bold (total) | Regular / Bold | Monospaced numerics — rupee figures align column-wise and are unambiguous across devices |
| Footer thank-you line | **Mukta** | 13pt | Regular | Plain body. NOT italic — italic is reserved for the signature |
| **Signature** | **Mukta italic** | 24pt | Italic | The one deliberate typographic-personality moment. Mukta italic is the closest approximation to handwritten warmth inside the Constraint 4 stack. **Caveat is forbidden.** Any new Google Font is forbidden. The Brief v1.4 Constraint 4 revision explicitly locks the 5-font stack and B1.13 AC #5 explicitly names this fallback |
| English translation zone (if `defaultLocale == en`) | **EB Garamond** (body) / **Fraunces** italic (signature) | matched pairs | — | English-toggle variant uses the English halves of Constraint 4 |

**Layout structure (single page, landscape-agnostic):**

```
┌────────────────────────────────────────────────────┐
│  [logo OR Devanagari-initial circle]               │
│                                                     │
│  सुनील ट्रेडिंग कंपनी                              │  ← Tiro Devanagari Hindi 32pt
│  Harringtonganj Furniture Market, Ayodhya          │  ← EB Garamond 10pt
│  GST: XXXXXXXXXXXXX   •   since २००३              │  ← Mukta 11pt (Devanagari year)
│  VPA: sunil@upi       •   +91 XXXXX XXXXX          │  ← DM Mono
├────────────────────────────────────────────────────┤
│  रसीद # {lastSixOfULID}        दिनांक: ११ अप्रैल २०२६  │  ← DM Mono ID, Mukta date
│  ग्राहक: {displayName OR "ग्राहक"}                  │
├────────────────────────────────────────────────────┤
│  सामान                      मात्रा    दाम    कुल    │  ← Mukta header row
│  ─────────────────────────────────────────────    │
│  स्टील अल्मीरा 4-दरवाज़ा     १       ₹13,500 ₹13,500 │  ← Mukta + DM Mono
│  …                                                  │
│  ─────────────────────────────────────────────    │
│                                    कुल: ₹13,500    │  ← DM Mono 16pt bold
│  भुगतान: UPI                                       │
├────────────────────────────────────────────────────┤
│                                                     │
│     धन्यवाद, आपका विश्वास हमारा भविष्य है           │  ← Mukta 13pt, plain
│                                                     │
│              सुनील भैया                            │  ← Mukta italic 24pt
│              ─────────                              │  ← underline rule
│                                                     │
└────────────────────────────────────────────────────┘
```

**State variants** (cross-ref §6.6 states #35–#41):

- **Paid receipt:** the default layout above.
- **Cancelled:** diagonal `रद्द` watermark at 15% opacity in a red-ink token, overlaid across the body. Does NOT block reading — the customer may need to share the cancelled receipt as part of a refund trail.
- **Udhaar-open / balance-due:** adds ONE extra line below the totals table: `बाकी: ₹{amount}`. NO other changes. Crucially: no interest column, no due-date field, no penalty line, no schedule. R10 forbidden vocabulary is enforced at the template layer, not just at the copy layer — the template source file at `packages/lib_core/lib/src/invoice/invoice_template.dart` has a CI lint that rejects any edit introducing forbidden substrings.
- **Missing customer display name:** prints `ग्राहक` fallback. No friction screen ever appears. This is non-negotiable per Standing Rule 8.
- **Missing shop logo:** Devanagari-initial circle — the first conjunct of the shop's Devanagari name rendered in Tiro Devanagari Hindi inside a 64dp circle with cornsilk fill and shop accent-color stroke (matching B1.2's fallback treatment).
- **Page break at >10 line items:** `MultiPage` directive. Header repeats at top of page 2+. Page number `{n}/{total}` in DM Mono, top-right. No "continued" copy.

**Share-sheet interaction:**

The customer's path from "I want the receipt" to "the receipt is on WhatsApp" is three taps: `रसीद देखें` → brief spinner (<1.5s client-side PDF render via the `pdf` Dart package per ADR-015) → platform-native share sheet. NO custom in-app share picker (which would be a Yugma Labs tax on the customer's attention, per Triple-Zero discipline P10). The file is saved to `Downloads/yugma-dukaan/receipts/रसीद_{shortId}_{date}.pdf` on Android, app Documents on iOS, and the file name itself uses Devanagari — the only place in the entire product where a file name on the filesystem is in Devanagari, deliberately, because the customer will see it in her Files app and the filename is the receipt's last warm touchpoint.

**Offline behavior:** the PDF renders fully offline. ADR-015 is explicit: no Cloud Function, no network fetch, no webview. The font subset is already in the app binary. The Firestore read for Project + Shop happens once on first view; if the customer is offline, cached versions are used.

**Cross-reference to §6.6 states #35–41.** Cross-reference to §5.5 strings #31–#36. Cross-reference to §1.2 P1 Hindi-first and P4 show-don't-sutra — this receipt is the physical-feeling artifact that carries both principles off the screen and into the customer's filing cabinet.

### 4.12 — Shop deactivation customer-side banner pattern (C3.12) *(v1.1 add)*

The banner is the most emotionally consequential persistent UI element in the entire customer app. It has to be honest without being alarming, present without being intrusive, and readable at every persona tier from Rahul's default tier to Geeta-ji's 1.4× elder tier.

**Banner slot and placement:**
- A single reserved `LifecycleBanner` slot at the top of the customer-app screen stack, below the system status bar and above the bottom tab bar. It is persistent — visible on every screen (shop landing, chat, Project detail, mere-orders).
- Amber warning color token, NOT red. Red is reserved for errors. A deactivating shop is not an error; it is a human decision that deserves a different color register.
- 48dp tall in default tier, 64dp in elder tier. Text wraps to a second line in elder tier, never clipped.
- Tap anywhere on the banner expands the FAQ screen (§6.7 state #45).

**Three lifecycle variants (see §6.7 states #42–#44):**
- `deactivating` — the money-will-return reassurance is the first phrase the customer reads. This is the single most important UX decision in the banner — the Brief §9 R16 mitigation lives or dies on whether the customer's first emotional response is "what about my money?" being answered in under 2 seconds.
- `purge_scheduled` — stronger export nudge. Amber shade shifts one step warmer. The data-export CTA is promoted from inside-the-FAQ to inside-the-banner itself. Countdown in DM Mono.
- `active` (reactivation) OR `purged` — banner slot clears. Reactivation is silent (no celebration toast — this is a real, sensitive moment the shopkeeper may want to handle quietly). Purge: a read-only FAQ remains accessible so historical receipts can still be re-exported from local cache (the customer's copies of B1.13 PDFs survive in the device filesystem regardless of Firestore purge).

**FAQ screen interaction:**
- Full-screen scroll. NOT a modal. The customer must feel they have arrived at a dedicated page, not an interrupting pop-up.
- Five sections with Devanagari headers: money / orders / udhaar / retention / data export. Each section 2–3 sentences of plain Awadhi-Hindi. Absolutely no DPDP Act citation strings. No legal tone. No "we", no "our policy".
- Data-export CTA pinned to the bottom as a sticky primary button — always reachable regardless of scroll position.

**Offline-catchup:**
The hardest edge case. A customer who was offline when the shop transitioned could, in theory, see nothing until the next Firestore listener tick. The design handles this in three layers: (a) the connectivity banner from §6.1 state #1 stacks on top of the lifecycle banner if both apply, so the customer can tell they are seeing cached state; (b) the cached Shop document's last known `shopLifecycle` value is authoritative within an offline session; (c) on the first successful real-time tick after reconnection, the banner transitions with a 300ms fade from the cached state to the live state, never a jarring re-render.

**Cross-reference to §3.5 udhaar journey** — the frozen-udhaar state (§6.7 #47) is deliberately silent about balance collection. The ledger running balance is preserved for audit, but no reminder fires and no "collect now" CTA exists. Per R10, the deactivated shop's ledger becomes read-only — any further balance settlement is a social, offline event.

**Cross-reference to §5.5 strings #37–#40.**

### 4.13 — Shopkeeper NPS dashboard card pattern (S4.17) *(v1.1 add)*

The NPS card is the single most culturally sensitive ops-app UI element. It sits on Sunil-bhaiya's triage dashboard bi-weekly and asks him to rate the product out of 10 — and it must do so without insulting him, without patronizing him, without sounding like a Google Form, and without ever becoming a modal that blocks work.

**Non-negotiables (from PRD S4.17 AC #1 and party-mode F-P3):**
1. **It is a card, not a modal.** Modal interruptions are Sillicon-Valley-SaaS vocabulary. Sunil-bhaiya's dashboard is a triage list, not a feedback channel — the card lives *inside* the triage list, below the three triage sections, as a dismissible sibling of "new orders" and "chats pending".
2. **The headline is casual:** `कितना उपयोगी लगा?` — NOT the formal `कितना उपयोगी पाया?`. The party-mode F-P3 finding from PRD v1.0.5 Phase 2 surfaced that the formal register reads as government-office Hindi, which insults a Harringtonganj shopkeeper's working-class identity. Casual register is the register of a younger relative asking his uncle for an honest opinion.
3. **The 10-dot rating row is horizontal.** 10 circles, 32dp each, DM Mono numerals inside. Tap any dot to select. The selected dot and all dots to its left fill with the shop accent color — same mental model as filling a glass of water.
4. **The optional textarea is collapsed by default.** A single `कुछ कहना है?` link below the dots expands it on tap. The bhaiya is not forced to type anything.
5. **Two buttons at the bottom of the card:** primary `भेज दीजिए`, secondary `बाद में`. The secondary is a text link, not a button — visual weight matters, the snooze must not feel equal to the submission.

**Bi-weekly cadence mechanics:**
- 14 days since the last `shopkeeper_burnout_self_report` document for this operator (regardless of outcome).
- Dismissal via `बाद में` sets a 7-day snooze, then the card re-appears.
- Submission resets the 14-day clock.

**Burnout warning state — deliberately invisible to the shopkeeper.** Per PRD AC #4, two consecutive scores ≤6 fires a `BurnoutWarningDetected` Crashlytics event that is never surfaced to the shopkeeper. Surfacing it would be deeply insulting — "we noticed you seem burnt out" is not something the product gets to say to the person who is keeping the product alive. Yugma Labs ops sees the event in Crashlytics and handles the intervention out-of-band (reducing workload, routing chats to Aditya, phone call from Alok). This is the Brief R1 "shift, don't shame" posture made concrete in UX.

**Month-6 gate tile** — a small read-only aggregation tile in the S4.11 analytics dashboard showing trailing-60-day NPS average. Bhaiya role only. DM Mono numeric. This is where the Brief §6 Month 6 gate is visibly met.

**Cross-reference to §5.5 strings #41–#43.** Cross-reference to §6.8 states #49–#53.

### 4.14 — Shop deactivation 3-tap progression pattern (S4.19) *(v1.1 add)*

The single most emotionally weighty ops-app flow. A retiring shopkeeper, a closing business, a medical emergency — any of these is the human context. The flow must honor the weight of the decision without becoming bureaucratic.

**Three locked design invariants:**

1. **Bhaiya-role-only visibility.** The `दुकान बंद करना` Settings section is NOT rendered at all for `role in ("beta", "munshi")`. Not disabled. Not greyed-out. Not hidden behind a "contact admin" message. **Hidden.** The munshi must not even know the flow exists — showing a locked door is itself a design insult. Per PRD AC #1 this is enforced by a server-side security rule independent of the UI check, so the hiding is belt-and-suspenders.

2. **Three taps, never two, never four.** Tap 1 is information (full-screen explanation). Tap 2 is reason selection (4 enum values matching the SAD `shopLifecycleReason` enum). Tap 3 is the final confirmation dialog. Each tap is a meaningful affordance for the bhaiya to stop — and the language at each tap is designed to let him stop without losing face.

3. **Reversibility is printed on the live dialog, not hidden in help.** PRD AC #8 specifies a 24-hour reversibility window. The reversal copy — `अगर गलती से दबाया, अगले 24 घंटे में उल्टा कर सकते हैं` — appears as a footer line directly below the confirm button on tap 3, where the bhaiya's finger is literally hovering. This is the single most important copy placement in the ops app. The reassurance exists not in a help popover, not in a FAQ, not in a tooltip — it is printed next to the button. If the bhaiya's thumb slips, the footer tells him it is okay.

**Reasons dropdown — 4 enum values mapping to SAD shopLifecycleReason:**
- `रिटायर हो रहा हूँ` (retiring) — first person, present continuous, not "retirement" as an abstract noun
- `शॉप बंद कर रहा हूँ` (closing the shop) — first person, not "business closure"
- `बीमारी / मेडिकल` (illness / medical) — two-word pairing to cover both physical idioms the shopkeeper might use; the English loanword `मेडिकल` is intentional — it is the word he would use to his own family
- `अन्य` (other)

There is no free-text field. The enum is deliberately narrow because (a) this flow is rare, (b) the SAD `shopLifecycleReason` field is an enum, and (c) a free-text field at this moment would add an attention-weighty blank page at the wrong time.

**Reversibility window UX** (§6.9 state #58):
When `shopLifecycle == deactivating` and the 24-hour window is still open, the Settings section transforms. It is no longer a scary `दुकान बंद करना` button — it is a bright yellow-amber card with `दुकान फिर से चालू कीजिए` ("reopen shop") and a DM Mono countdown showing hours remaining. The reversal flow re-runs the same 3-tap progression with inverted copy. Once the 24-hour window expires (the next `shopDeactivationSweep` Cloud Function run finalizes the transition), the section becomes a plain disabled row with `Yugma Labs से संपर्क कीजिए` — out-of-app recovery only.

**Cross-reference to §5.5 strings #44–#45.** Cross-reference to §6.9 states #54–#58. Cross-reference to §4.12 for the customer-side sibling pattern C3.12.

### 4.15 — Media spend ops dashboard tile (S4.16) *(v1.1 add)*

A small, single tile in the existing S4.11 analytics dashboard. No new screen. The tile's only job is to make the Brief §9 R3 Cloudinary cost-ceiling visible BEFORE it becomes a billing surprise. It lives next to the sales-and-orders tiles; it is operator-facing only (bhaiya role), never customer-facing.

**Visual structure:**
- Title: `मीडिया खर्च` in Mukta 14pt (matches the other dashboard tile titles).
- Primary number: `{used}/25` credits in DM Mono 24pt (matches the other dashboard tile numeric display).
- Progress bar below the number, 6dp tall, colored per the four-state threshold system (see §6.10).
- Month-over-month delta arrow and percentage in DM Mono next to the primary number.
- Subtitle: `अनुमानित महीने का अंत: {projection}` in Mukta 11pt.

**Four color/banner states (see §6.10 states #59–#62):**
- Green <50%, silent tile (no banner).
- Amber 50–80%, yellow banner above the tile with `मीडिया खर्च आधा से ज़्यादा — जल्द खत्म हो सकता है`.
- Red ≥80%, same banner with red token — copy unchanged.
- Red-alt ≥100% AND `mediaStoreStrategy == r2` flipped by `mediaCostMonitor` Cloud Function: `Cloudinary खत्म — R2 चालू`. The only UI string in the entire product where two English product names stack, intentionally, because the operator will Google them if confused.

**Cross-reference to §5.5 strings #46–#47.** Cross-reference to PRD S4.16 AC #3–#4. Cross-reference to SAD §7 Function 7 `mediaCostMonitor`.

### 4.16 — S4.10 udhaar ledger reminder affordances (tweak) *(v1.1 add)*

No new screen. Three new UI affordances added to the existing S4.10 ledger card per PRD v1.0.5 AC #7/#8/#9. Each is a direct translation of an SAD v1.0.4 §7 Function 3 RBI-defensive runtime field.

**1. Per-ledger opt-in toggle (§6.11 state #63):**
A toggle switch row on every open-ledger card. Labeled with the bhaiya-authored question `क्या मैं इस ग्राहक को याद दिलाऊँ?` ("Should I remind this customer?"). This is not system-authored — it reads in the voice of the bhaiya asking himself, not the product asking him. Default OFF. R10 defensive posture: the bhaiya must affirmatively tap ON for each specific ledger. No blanket / shop-wide opt-in exists anywhere.

**2. Lifetime reminder count badge (§6.11 state #64):**
A small DM Mono badge next to the customer's name on each ledger row: `याद दिलाया गया: {count}/3`. At 3/3 the badge shifts to an amber-neutral token — informational cap, NOT a red shame state. The copy is neutral: no "quota exceeded", no "max reached", no "ban" language. Beyond 3 lifetime reminders, any further reminder is an offline social event the bhaiya handles outside the product — the product is silent about it.

**3. Cadence stepper (§6.11 state #65):**
A horizontal stepper UI inside the expanded ledger detail. Range 7–30 days, default 14. Large tap targets (56dp — the munshi uses this screen, and the munshi is not young). DM Mono numerals. Labeled `कितने दिन बाद याद दिलाना है?` ("after how many days should I remind?"). The stepper is the ONLY UI surface that lets the bhaiya control reminder cadence — no settings-page shortcut, no per-shop default in the admin area. Per-ledger, per-customer, every time.

**Forbidden vocabulary compliance** — these three affordances were authored directly against §5.6's forbidden-vocabulary list. Every draft was cross-checked. `interval`, `period`, `schedule`, `due`, `auto-remind`, `quota`, `reminder quota`, `max reminders`, and all R10 loanwords are NOT present anywhere in the three affordances or the five copy strings #48–#50. CI lint per §5.6 enforces this on every PR touching `strings_hi.dart`.

**Cross-reference to §5.5 strings #48–#50.** Cross-reference to §6.11 states #63–#65. Cross-reference to §3.5 udhaar journey and R10 defensive posture.

---

## §5 — Hindi-First Voice & Tone Guide

Hindi is the source-of-truth language. English is the translation. This section is written for the Awadhi-Hindi copywriter the Brief Constraint 15 requires to be contracted for 4 weeks at the v1 spec phase. If that copywriter is not yet hired, this section serves as the minimum viable baseline until they arrive.

### 5.1 — Dialect: Awadhi-inflected Hindi, not Delhi Hindi

Ayodhya sits in the Awadh cultural region. The dialect is Awadhi — a soft, older form of Hindi with distinctive grammar and vocabulary. UI strings should sound natural in Awadhi-inflected Hindi, not in the clean Delhi Hindi of newsreaders.

**Concrete differences:**

- **Soft consonants.** Where Delhi Hindi might say *"सुनिए"* (listen, polite), Awadhi might say *"सुनिए तो"* or *"सुनो जी"*. The softer form is warmer in this market.
- **Honorifics embedded in verbs.** *"बताइए"* is formal Delhi Hindi for "please tell." In Awadhi the formal form is *"बता दीजिए"* or *"बतलाइए"*. Both are correct; the latter is warmer.
- **Regional vocabulary.** For "almirah" we use *"अलमारी"* (universal) but also accept *"अल्मीरा"* (the Hindi-ised direct transliteration, more common in conversation). For "shop" we use *"दुकान"* (universal). For "price" we prefer *"दाम"* over the Sanskritic *"मूल्य"* because दाम is what people say at the counter.
- **Address.** The word *"आप"* (formal you) is the default. *"तुम"* (informal you) is never used in customer-facing strings — it would sound disrespectful. *"तू"* (very informal) is never used at all.
- **No Sanskritized vocabulary.** Pre-Mortem Failure Mode #9 specifically warned against this. *"स्वागतम्"* is too formal for a shop; *"नमस्ते"* or *"आइए"* is right. *"उत्पाद"* (product) is cold; *"सामान"* (goods) or just the item name is warmer.

### 5.2 — Tone: warm, respectful, peer-to-peer

The app's voice is never a customer-service bot. It is not a brand. It is either Sunil-bhaiya himself (in voice notes, chat messages he sends) or it is the app's quiet background voice, which should feel like a respectful younger assistant in his shop — not a corporate narrator.

**Rules:**

1. **Peer-to-peer, not hierarchical.** The app does not condescend to the customer, and the app does not flatter the customer. It speaks to her as an adult buying something expensive for a purpose that matters.
2. **Specific, not abstract.** *"स्टील अल्मीरा, 4 दरवाज़ा, 1.5 मीटर ऊँचा"* is warmer than *"Our finest wardrobe for your home."* Specificity is warmth.
3. **Personal, when warranted.** Sunil-bhaiya's voice notes use first-person; the app's background voice uses third-person ("सुनील भैया"). Do not mix them.
4. **Never apologetic.** Empty states and errors do not say "Sorry, we..." or "Unfortunately..." — they say what is true and offer a path forward.
5. **Never urgent.** No "Limited time!", no "Only 2 left!", no countdown timers. The market does not work that way and it would feel like a lie.

### 5.3 — Honorifics: when to use "ji" vs "bhaiya" vs "didi"

- **"जी" (ji)** — universal respect marker. Attached to names, titles, or used alone as agreement. Use: *"सुनील जी"* is formal (less common in this shop); *"सुनील भैया"* is more natural. For the customer, *"आप"* alone is sufficient; if a name is known, *"सुनीता जी"* is right.
- **"भैया" (bhaiya)** — "brother," used for male shopkeepers / older male strangers. *"सुनील भैया"* is how the customer addresses him. The app refers to him as *"सुनील भैया"* too — never just "Sunil" or "Mr. Sunil" or "the shopkeeper."
- **"दीदी" (didi)** — "elder sister," used for female customers by shopkeepers. Sunil-bhaiya may say *"दीदी, ये अलमारी देखिए"* in a voice note. The app does not use "दीदी" in its own voice (it would feel forced) — only the shopkeeper does, in his recordings.
- **"आंटी / चाची / मौसी"** — used for older female customers in specific relational contexts. The app does not use these; only people do.

### 5.4 — Numerals: Western for amounts, Devanagari for dates/ordinals

**Prices, quantities, counts:** Use Western numerals (0–9). The customer sees *"₹14,000"* not *"₹१४,०००"*. Why? Because UPI, WhatsApp, and every other surface they use for money uses Western numerals. Consistency with the user's broader digital life wins over purity. This is the one place where "Hindi-first" bends to "user-first."

**Dates, ordinals, ritual numbers:** Use Devanagari numerals (०–९). *"२६ जनवरी"* (26 January) reads more naturally than *"26 जनवरी"* in a Hindi sentence. Day-of-week references, historical dates, festival dates, and ordinal references ("the 3rd almirah") use Devanagari numerals.

**In practice:** I expect ~90% of numerals in the app to be Western (prices, counts, timestamps), and ~10% to be Devanagari (dates, ritual references, ordinal counts).

### 5.5 — Example UI strings (50 grounded examples)

Below is a table of UI strings for key moments in the app. Each has a Devanagari form, an English translation, and a tone annotation. This is the baseline the copywriter reviews and refines. *(v1.1 patch — extended from 30 to 50 strings to cover the six v1.0.5 stories B1.13 / C3.12 / S4.16 / S4.17 / S4.19 / S4.10 reminder affordances per John's handoff from PRD v1.0.5. Phase 6 IR Check v1.2 patch 2026-04-11: heading arithmetic corrected from "45" to "50" — the table actually lists strings #1 through #50, not 45.)*

| # | Context | Devanagari | English translation | Tone annotation |
|---|---|---|---|---|
| 1 | First-launch splash | सुनील ट्रेडिंग कंपनी | Sunil Trading Company | Plain, specific, no tagline |
| 2 | Greeting voice note label | सुनील भैया का स्वागत संदेश | Sunil-bhaiya's welcome message | Warm, possessive, personal |
| 3 | Shortlist title: wedding | शादी के लिए | For wedding | Simple, occasion-specific |
| 4 | Shortlist title: new home | नए घर के लिए | For the new home | Warm |
| 5 | Shortlist title: replacement | पुराना बदलने के लिए | To replace the old one | Honest about the reason |
| 6 | SKU detail button | इसे शॉर्टलिस्ट करें | Add to my list | Specific, action-oriented |
| 7 | SKU detail button | सुनील भैया से बात करें | Talk to Sunil-bhaiya | Not "chat with support" — talk to him |
| 8 | Asli-roop toggle | असली रूप दिखाइए | Show the real form | Maya's reframe — honest |
| 9 | Chat thread title | सुनील भैया का कमरा | Sunil-bhaiya's room | Possessive, intimate |
| 10 | Chat input placeholder | यहाँ संदेश लिखिए... | Type your message here... | Plain, inviting |
| 11 | Commit button | ऑर्डर पक्का कीजिए | Confirm the order | "pakka" is stronger than "confirm" |
| 12 | OTP prompt | सुनील भैया डिलीवरी के लिए संपर्क करेंगे, आपका फ़ोन नंबर चाहिए | Sunil-bhaiya will contact you for delivery, we need your phone number | Reframes OTP as shopkeeper-need, not app-distrust |
| 13 | UPI primary button | UPI से दीजिए | Pay via UPI | "देना" (to give) feels right in this market |
| 14 | Payment success | ऑर्डर पक्का हुआ! धन्यवाद। | Order confirmed! Thank you. | Warm, brief, no exclamation abuse |
| 15 | Udhaar proposal | सुनील भैया ने उधार खाता प्रस्तावित किया है | Sunil-bhaiya has proposed a khaata | "proposed" not "offered" — it's a social agreement |
| 16 | Udhaar balance | सुनील भैया में बाकी: ₹13,000 | Remaining with Sunil-bhaiya: ₹13,000 | Relational framing, not "balance due" |
| 17 | Delivery confirmation | सुनील भैया ने ऑर्डर डिलीवर कर दिया | Sunil-bhaiya has delivered the order | Active voice, possessive |
| 18 | Empty cart / draft | आपकी सूची अभी खाली है। नीचे से कुछ चुनिए। | Your list is empty right now. Pick something from below. | Soft, not apologetic |
| 19 | No orders yet (new customer) | अभी तक कोई ऑर्डर नहीं। जब आप पहला ऑर्डर करेंगे, यहाँ दिखेगा। | No orders yet. When you place your first, it'll show here. | Informative, future-looking |
| 20 | No internet banner | अभी इंटरनेट नहीं है — जो पहले देखा था, वो दिखा रहे हैं | No internet right now — showing what you'd seen before | Honest, non-apologetic |
| 21 | Upload pending | अपलोड बाकी है | Upload pending | Two words, no fuss |
| 22 | Away banner | सुनील भैया आज शाम एक शादी में हैं, 6 बजे तक वापस | Sunil-bhaiya is at a wedding this evening, back by 6 PM | Specific, trusting the customer with context |
| 23 | Persona toggle (default) | मैं देख रहा हूँ | I am looking | First-person singular, male (default); female variant: "मैं देख रही हूँ" |
| 24 | Persona toggle (elder) | मम्मी जी देख रही हैं | Mummy-ji is looking | Third-person respectful |
| 25 | Error: payment failed | भुगतान नहीं हो सका। दुबारा कोशिश कीजिए या और तरीका चुनिए। | Payment didn't go through. Try again or choose another way. | Honest, offers a path, no blame |
| 26 | Error: voice note failed | आवाज़ नोट नहीं भेजा जा सका। अपना इंटरनेट देखिए। | Voice note could not be sent. Check your internet. | Specific reason, not generic failure |
| 27 | Empty shortlist (curation not yet done) | अभी तक सुनील भैया ने इसमें कुछ नहीं चुना | Sunil-bhaiya hasn't chosen anything for this yet | Warm, implies curation is still coming |
| 28 | Empty Decision Circle | अभी सिर्फ़ आप हैं। परिवार को जोड़ने के लिए लिंक भेजिए। | Right now it's just you. Send a link to add family. | Warm, suggests action |
| 29 | Udhaar reminder (push) | आपका खाता: सुनील भैया में ₹13,000 बाकी | Your account: ₹13,000 remaining with Sunil-bhaiya | Non-threatening, relational |
| 30 | Sign-in error (ops app) | आप अभी authorized नहीं हैं। Yugma Labs से संपर्क कीजिए। | You are not yet authorized. Contact Yugma Labs. | Direct, actionable |
| 31 | B1.13 — Receipt header thank-you line | धन्यवाद, आपका विश्वास हमारा भविष्य है | Thank you — your trust is our future | Plain, no mythic / no temple framing; Mukta body, NOT italic (italic is reserved for the signature) |
| 32 | B1.13 — Receipt signature render | सुनील भैया *(rendered in Mukta italic, larger size)* | Sunil-bhaiya (Mukta italic, larger size) | Handwritten-feel fallback staying inside Constraint 4 — Caveat / any new Google Font is forbidden |
| 33 | B1.13 — Open receipt from Project | रसीद देखें | View receipt | Plain action, not "invoice" / not "PDF" — customer vocabulary |
| 34 | B1.13 — Cancelled receipt watermark | रद्द | Cancelled | One word, diagonal watermark, red-ink color token |
| 35 | B1.13 — Udhaar-open on receipt | बाकी: ₹{amount} | Remaining: ₹{amount} | NEVER "ब्याज" / "पेनल्टी" / "बकाया तारीख" per R10. "बाकी" alone is the permitted word |
| 36 | B1.13 — Missing customer display name fallback | ग्राहक | Customer | No friction screen asking for name (Standing Rule 8) |
| 37 | C3.12 — Banner, `deactivating` state | सुनील भैया की दुकान बंद हो रही है — आपका पैसा वापस आ जाएगा, आपका डेटा {N} दिन तक सुरक्षित है | Sunil-bhaiya's shop is closing — your money will come back, your data is safe for {N} days | No legal jargon. Plain. Money-comes-back reassurance is the first phrase |
| 38 | C3.12 — Banner, `purge_scheduled` state | डेटा {N} दिन में हटा दिया जाएगा — export कीजिए | Data will be deleted in {N} days — export now | Direct, non-alarming. `export` is the one English loanword the shopkeeper's customers already know |
| 39 | C3.12 — FAQ screen title | क्या हो रहा है? | What is happening? | Casual register, not formal `क्या हुआ है?`. Device-holder hears the question in the voice of a confused family member |
| 40 | C3.12 — Data-export CTA button | डेटा export कीजिए | Export your data | Routes to B1.13 bundled receipt generation (all past Projects). "आपकी सारी रसीदें एक साथ" (all your receipts together) as subtitle |
| 41 | S4.17 — NPS card headline | कितना उपयोगी लगा? | How useful did you find it? | Casual, NOT formal `कितना उपयोगी पाया?` (party mode F-P3 finding from PRD v1.0.5 — the formal register insults Sunil-bhaiya's working-class identity) |
| 42 | S4.17 — NPS optional textarea | कुछ कहना है? | Anything you want to say? | Open-ended, friendly. Plural-respectful |
| 43 | S4.17 — NPS snooze | बाद में | Later | Two syllables. 7-day snooze follows |
| 44 | S4.19 — Shop-closure button (Settings section only, bhaiya-only) | दुकान बंद करने का विकल्प | Shop closure option | Flat, not `"दुकान हमेशा के लिए बंद कीजिए"` (for-ever framing would be dramatic and infantilizing) |
| 45 | S4.19 — 3rd-tap reversibility footer | अगर गलती से दबाया, अगले 24 घंटे में उल्टा कर सकते हैं | If you tapped by mistake, you can reverse this in the next 24 hours | Explicit inverted-language. The reassurance is printed below the confirm button, not hidden in help |
| 46 | S4.16 — Media spend tile label | मीडिया खर्च | Media spend | Short, operator-facing only, DM Mono for the `{used}/{total}` numerals |
| 47 | S4.16 — Cloudinary exhausted red-alt banner | Cloudinary खत्म — R2 चालू | Cloudinary done — R2 active | Operator-only copy. The two English loanwords are intentional — they are the product names Sunil-bhaiya's digital operator will Google |
| 48 | S4.10 — Reminder opt-in toggle (per ledger) | क्या मैं इस ग्राहक को याद दिलाऊँ? | Should I remind this customer? | Bhaiya-authored question, NOT a system-authored switch. Default OFF — affirmative opt-in only (R10 defensive posture) |
| 49 | S4.10 — Reminder count badge (per ledger) | याद दिलाया गया: {count}/3 | Reminded: {count}/3 | DM Mono for numerals. Hard-cap at 3 lifetime |
| 50 | S4.10 — Cadence stepper label | कितने दिन बाद याद दिलाना है? | After how many days should I remind? | Stepper shows 7 ⋯ 14 (default) ⋯ 30. No "interval" / "period" / "schedule" vocabulary (all three are R10-adjacent) |

### 5.6 — Forbidden vocabulary list

Per ADR-010 and the §3.5 udhaar journey discussion, these words and phrases MUST NOT appear anywhere in customer-facing or shopkeeper-facing UI. This list is enforced by code review and (where possible) by lint rules scanning `strings_hi.dart` and `strings_en.dart` on every PR.

**Hindi forbidden list:**
- ब्याज (interest)
- ब्याज दर (interest rate)
- देय तिथि (due date)
- देय (due)
- जुर्माना (penalty / fee)
- लेट फीस (late fee)
- ऋण (loan)
- उधारी (borrowing)
- कर्ज़ (debt)
- बकाया (dues — too formal, implies obligation)
- डिफ़ॉल्ट (default)
- वसूली (collection)
- क़िस्त (installment — has scheduled-obligation connotation)
- क़िस्त बंदी (installment plan)
- भुगतान विफल (payment failed) — too harsh; use *"भुगतान नहीं हो सका"* (payment couldn't happen)

**English forbidden list (because the English toggle must also comply):**
- Interest, interest rate
- Due date, overdue, past due
- Late fee, penalty
- Loan, credit, lending
- Default, defaulter
- Collection, recovery
- Installment, EMI
- Payment failed (use "Payment didn't go through")
- Debt

**Permitted vocabulary for the ledger feature:**
- खाता (account, ledger)
- बाकी (remaining)
- भुगतान (payment) — action-oriented, not obligation-oriented
- आज का भुगतान (today's payment)
- पूरा हुआ (completed)
- धन्यवाद (thank you)

**Forbidden mythic / Sanskritized vocabulary (v1.1 patch per Brief Constraint 10 "show don't sutra"):**
Every new copy string for the B1.13 invoice, C3.12 deactivation banner, and S4.17 NPS card was cross-checked against this list. None of these words may appear in any UI string ever — not in headers, not in subtitles, not in empty states, not even in footer blessings.
- शुभ (auspicious) — Sanskritized blessing, reads temple-adjacent
- मंगल / मंगलमय (prosperous / auspicious) — same reason
- मंदिर (temple) — places the shop in a mythic frame the Brief §8 Constraint 10 explicitly rejects
- धर्म / धार्मिक (dharma / religious) — framing collapse
- पूज्य (revered / worshipful) — over-formal, used for deities or elders in a religious frame
- आशीर्वाद (blessing) — category drift from commerce to religion
- तीर्थ / तीर्थयात्री (pilgrimage / pilgrim) — pulls the product into an Ayodhya-tourism frame that is the OPPOSITE of "Harringtonganj furniture market" specificity
- स्वागतम् (formal welcome) — Sanskritized, too formal for a shop
- उत्पाद (product) — cold, corporate
- गुणवत्ता (quality) — Sanskritized marketing-speak; use specific claims ("स्टील गेज 22", "डबल-चेन लॉक") instead
- श्रेष्ठ / सर्वोत्तम (the best, supreme) — superlative marketing, not shopkeeper register

**Permitted everyday warmth words** (these are NOT mythic — the Hindi-fluent reviewer confirms they read as everyday commerce language, not religion):
- धन्यवाद (thank you) — universal everyday word
- विश्वास (trust / faith) — everyday, as in "विश्वास रखिए" ("trust me"); the B1.13 footer uses this
- स्वागत (welcome, without the Sanskritized `म्` suffix) — shop-register, fine
- आपका (yours, plural-respectful) — everyday honorific

### 5.7 — Empty state copy guidelines

Empty states are moments of quiet. They should feel warm and informative, never apologetic. Three rules:

1. **State what is true.** "अभी कोई ऑर्डर नहीं" (no orders yet) is true. "Oops, looks like you don't have any orders!" is patronizing.
2. **Offer a path forward when applicable.** *"नीचे से कुछ चुनिए"* (pick something from below) points to the next action.
3. **Never apologize.** The app is not sorry that the customer hasn't placed an order. The customer is not to blame. The app is just quiet.

See strings 18–19, 27–28 in the table above for examples.

### 5.8 — Error state copy guidelines

Errors are moments of honesty. They should be specific, non-blaming, and action-oriented. Three rules:

1. **State what failed, specifically.** "Voice note could not be sent" is better than "Something went wrong."
2. **Offer a cause when knowable.** "Check your internet" is a knowable cause. "An unknown error occurred" is never acceptable.
3. **Never blame the user.** "Your phone number seems wrong" blames the user. "The phone number didn't match; please check and try again" offers a path.

See strings 25–26 in the table above for examples.

---

## §6 — Error / Empty / Loading State Catalog

The full table of states the app must handle gracefully. Organized by category. Every state names its trigger, its recommended UX pattern, and its copy (Devanagari + English).

### 6.1 — Connectivity states

| # | State | Trigger | Recommended UX | Devanagari copy | English copy |
|---|---|---|---|---|---|
| 1 | No internet, browsing | `connectivity_plus` reports offline during a read | Soft top banner (amber); content shows from cache | `इंटरनेट नहीं है — पहले देखा हुआ दिखा रहे हैं` | No internet — showing what was last loaded |
| 2 | No internet, trying to send chat | User hits Send while offline | Message gets a pending clock icon; stays in chat UI | (in message's sub-label) `भेजने की कोशिश हो रही है` | (sub-label) Trying to send |
| 3 | No internet, voice note upload pending | Voice note recorded, upload queued | Small "upload pending" badge on the message | `अपलोड बाकी है` | Upload pending |
| 4 | Intermittent connectivity (3G dropping) | Network available but slow | No banner — trust the user; just render as it loads | — | — |
| 5 | Connectivity restored after outage | Back online after offline | Subtle top banner (green), 3 seconds, auto-dismiss | `नेटवर्क वापस — नया डेटा आ रहा है` | Network back — syncing new data |

### 6.2 — Auth states

| # | State | Trigger | Recommended UX | Devanagari copy | English copy |
|---|---|---|---|---|---|
| 6 | Anonymous sign-in failed | Firebase Anonymous Auth errors on cold launch | Retry button, no modal, inline at top of shop landing | `पहली बार शुरू करने में दिक्कत — दुबारा कोशिश कीजिए` | Trouble starting up — try again |
| 7 | OTP sent, waiting for entry | User submitted phone number, awaiting code | Full-screen bottom sheet with 6-digit input + "resend" after 30s | `6 अंकों का कोड आपके फ़ोन पर भेज दिया है` | 6-digit code sent to your phone |
| 8 | OTP incorrect (attempt 1-2) | Firebase Phone Auth rejected | Red inline error below input; keep entered digits | `यह कोड सही नहीं है — दुबारा देखिए` | This code isn't right — please check |
| 9 | OTP incorrect (attempt 3) | Third failed OTP attempt | Fallback CTA: "बिना verify किए आगे बढ़ें" | `अभी कोड verify नहीं हो रहा। बिना verify किए भी ऑर्डर पक्का कर सकते हैं।` | Can't verify the code right now. You can still confirm the order without verifying. |
| 10 | OTP quota exceeded (quota monitor triggered) | Remote Config flipped `otpAtCommitEnabled` to false | Silently skip OTP; commit flow proceeds | (no user-visible message) | (no user-visible message) |
| 11 | Google sign-in cancelled (ops app) | Shopkeeper dismissed the Google picker | Return to sign-in screen; no error | `सही खाता चुनकर आगे बढ़िए` | Pick the right account to continue |
| 12 | Operator doc missing (ops app) | Shopkeeper signed in but no operator record | Full-screen error with contact info | `आप अभी authorized नहीं हैं। Yugma Labs से संपर्क कीजिए।` | You are not yet authorized. Contact Yugma Labs. |

### 6.3 — Content empty states

| # | State | Trigger | Recommended UX | Devanagari copy | English copy |
|---|---|---|---|---|---|
| 13 | Shop landing — curated shortlists empty | Newly-onboarded shop, no curation yet | Warm placeholder with shopkeeper face still visible | `सुनील भैया की दुकान जल्दी तैयार हो रही है — थोड़ी देर में वापस आइए` | Sunil-bhaiya's shop is being set up — come back in a little while |
| 14 | One specific shortlist empty | Shortlist exists but no SKUs in it | Tab stays visible; content area shows warm message | `अभी तक सुनील भैया ने इसमें कुछ नहीं चुना` | Sunil-bhaiya hasn't chosen anything for this yet |
| 15 | No orders yet (customer) | New customer, zero Projects | Icon + warm message; "browse the shop" CTA | `अभी तक कोई ऑर्डर नहीं। नीचे से दुकान देखिए।` | No orders yet. See the shop below. |
| 16 | No chat messages yet | New Project, chat thread empty | Soft suggestion to start | `अपना सवाल लिखिए — सुनील भैया जवाब देंगे` | Type your question — Sunil-bhaiya will reply |
| 17 | Decision Circle empty | Only 1 participant (the customer herself) | Explain what DC is, offer link-share | `अभी सिर्फ़ आप हैं। परिवार को जोड़ने के लिए लिंक भेजिए।` | Right now it's just you. Send a link to add family. |
| 18 | Inventory empty (ops app) | New shop, no SKUs | "Add your first almirah" CTA | `पहली अलमारी जोड़िए` | Add your first almirah |
| 19 | Chat inbox empty (ops app) | No active conversations | Quiet placeholder | `अभी कोई बातचीत नहीं — जब ग्राहक आएंगे, यहाँ दिखेगा` | No conversations right now — customers will appear here |
| 20 | Udhaar ledger empty (ops app) | No open ledgers | Plain message | `अभी कोई उधार खाता खुला नहीं है` | No open khaata right now |

### 6.4 — Transactional error states

| # | State | Trigger | Recommended UX | Devanagari copy | English copy |
|---|---|---|---|---|---|
| 21 | UPI app not installed | UPI deep link fails to resolve | Friendly inline message with fallback options | `UPI ऐप नहीं मिला — कोई और तरीका चुनिए` | No UPI app found — choose another method |
| 22 | UPI payment cancelled | User backed out of UPI app without completing | Retry screen, options visible | `भुगतान अधूरा रह गया — दुबारा कोशिश कीजिए` | Payment didn't complete — try again |
| 23 | UPI payment failed (server-side) | Bank returned error | Show the specific error code if safe | `बैंक ने भुगतान नहीं लिया — अपने बैंक से बात कीजिए या और तरीका चुनिए` | The bank didn't accept the payment — check with your bank or choose another method |
| 24 | Voice note recording too short (<5s) | User released before 5 seconds | Inline toast, no modal | `थोड़ा लंबा बोलिए — कम से कम 5 सेकंड` | Speak a bit longer — at least 5 seconds |
| 25 | Voice note recording at limit (60s) | Hard cap reached | Auto-stop with confirmation | `60 सेकंड पूरे — अब भेज दीजिए` | 60 seconds reached — send it now |
| 26 | Photo upload failed | Cloudinary rejected or network dropped | Retry button; photo stays in local queue | `फ़ोटो अपलोड नहीं हुई — दुबारा कोशिश हो रही है` | Photo didn't upload — retrying |
| 27 | Firestore write rejected (security rule) | Permission denied on a write | Generic "try again or contact support" | `यह काम नहीं हो सका — दुबारा कोशिश कीजिए` | Couldn't complete that — please try again |
| 28 | Shopkeeper blocked customer | Blocked UID tries to write | Soft decline, no dramatic block screen | `यह काम अभी संभव नहीं है` | This action isn't available right now |

### 6.5 — Loading and skeleton states

Loading states exist because Tier-3 4G exists. Every loading state should feel like the app is working, not waiting.

| # | State | Trigger | Recommended UX |
|---|---|---|---|
| 29 | Shop landing first paint | Cold launch, Shop doc loading | Devanagari skeleton: shop-name-sized gray bar, face-sized circle, shortlist-card-sized rectangles. NEVER a generic spinner. |
| 30 | SKU detail loading | Navigated from shortlist | Gray rectangle where Golden Hour photo will appear, skeleton lines for name/price/description |
| 31 | Chat thread initial load | First tap into a Project's chat | Skeleton message bubbles alternating left/right, animated shimmer |
| 32 | Voice note downloading | First-time play | Spinner inline on the play button, NOT a separate modal |
| 33 | Image loading in inventory list | Scrolling inventory in ops app | Blurred low-res Cloudinary placeholder while hi-res loads (Cloudinary `q_auto` handles this) |
| 34 | Project list loading (ops app triage) | Ops app launched | Skeleton cards with gray bars, count shown as "लोड हो रहा है" |

**Skeleton screen design rules:**
- Always Devanagari-shaped when text is involved (use a representative width for Devanagari characters, not a generic 60% bar).
- Always match the target layout — a chat skeleton looks like a chat, not a generic blob.
- Never more than 2 seconds visible before actual content replaces it. If the load is taking longer, show a subtle progress indicator below the skeleton.

### 6.6 — Devanagari invoice / receipt states (B1.13) *(v1.1 add per PRD v1.0.5 John's handoff)*

| # | State | Trigger | Recommended UX | Devanagari copy | English copy |
|---|---|---|---|---|---|
| 35 | Paid receipt — normal | Project `state == closed` AND `paymentStatus == paid` | Full receipt template: Tiro Devanagari Hindi header, Mukta body, DM Mono numerics, Mukta-italic signature (Constraint 4 compliant), footer thank-you in plain Mukta | (footer) `धन्यवाद, आपका विश्वास हमारा भविष्य है` | (footer) Thank you — your trust is our future |
| 36 | Cancelled receipt — watermark | Project `state == cancelled` | Same template, additionally a 45-deg diagonal `रद्द` watermark at 15% opacity in red-ink color token across the body region. DOES NOT block reading; receipt is still shareable for dispute trail | (watermark) `रद्द` | (watermark) Cancelled |
| 37 | Udhaar-open receipt — balance-due variant | Project is `closed` or `partial_paid` AND there is an open UdhaarLedger | Template gains a single line below the totals table: `बाकी: ₹{amount}`. NO interest column, NO due-date field, NO penalty line. Absolutely no forbidden vocabulary per §5.6 and R10 | `बाकी: ₹{amount}` | Remaining: ₹{amount} |
| 38 | Fallback — no customer display name | Project has `customerDisplayName == null` and no VPA fragment | Template prints `ग्राहक` in place of name. NO friction screen asking the customer to supply one. Per Standing Rule 8 | `ग्राहक` | Customer |
| 39 | Fallback — no shop logo | Shop has `logoUrl == null` | Template prints a Devanagari-initial circle matching B1.2 (the first conjunct of the shop's Devanagari name rendered in Tiro Devanagari Hindi, 64dp circle with cornsilk fill, shop accent color stroke) | (initial circle, no copy) | (initial circle, no copy) |
| 40 | Page break — >10 line items | Line item count > 10 | `pdf` package's `MultiPage` directive paginates. Header repeats at top of page 2+ with page number `{n}/{total}` in DM Mono. No "continued on next page" copy — unnecessary noise | (page header) `{n}/{total}` | (page header) {n}/{total} |
| 41 | Share-sheet opening | User taps `रसीद देखें` from Project detail | Inline progress spinner on the button (<1.5 sec client-side generation), then platform share-sheet appears with WhatsApp / Gmail / Drive / Print pre-populated. No custom in-app share picker. File name includes shop name: `रसीद_सुनील-ट्रेडिंग_{shortId}_{date}.pdf` so the receipt is identifiable when it lands in a relative's WhatsApp *(v1.1 AE F1 patch — persona focus group surfaced that Sunita-ji forwards the receipt to her mother-in-law as face-saving proof; a shopName-less filename is cryptic on the MIL's phone)* | (button label during render) `रसीद बना रहे हैं…` | (button label during render) Preparing receipt… |
| 41b | PDF render failed | `pdf` package throws (OOM, font subset glitch, platform quirk) on cheap Android | Silent fallback: a plain text-only receipt variant (Mukta body, no logo circle, same copy content, no template decoration) renders as a secondary attempt. If even that fails, inline error `रसीद अभी तैयार नहीं हो सकी — बाद में कोशिश कीजिए` with a retry button. Never a white-screen failure. Crashlytics logs `b1_13_pdf_render_failed` with the exception class *(v1.1 AE F5 patch — failure mode analysis surfaced no graceful path for PDF render failure on low-memory devices)* | (inline error) `रसीद अभी तैयार नहीं हो सकी — बाद में कोशिश कीजिए` | (inline error) Receipt couldn't be prepared — please try again later |

### 6.7 — Shop deactivation customer-side states (C3.12) *(v1.1 add per PRD v1.0.5 John's handoff)*

| # | State | Trigger | Recommended UX | Devanagari copy | English copy |
|---|---|---|---|---|---|
| 42 | `deactivating` banner | Firestore real-time listener fires on `Shop.shopLifecycle` transition `active → deactivating` | Persistent top banner across all customer-app screens (shop landing, chat, Project detail, mere-orders). Amber warning color token, NOT red. Tap expands the FAQ screen. Includes a play button if the shopkeeper recorded a farewell voice note (optional, graceful fallback to text-only). **Elder-tier variant:** banner uses the shorter copy `सुनील भैया की दुकान बंद हो रही है — पैसा वापस, डेटा {N} दिन सुरक्षित` so 1.4× elder-tier rendering does not push the bottom tab bar off the 720×1600 screen *(v1.1 AE F14 patch — elder-tier what-if scenario surfaced that full copy wraps to 3 lines on a 5.5" display and clips bottom nav)* | `सुनील भैया की दुकान बंद हो रही है — आपका पैसा वापस आ जाएगा, आपका डेटा {N} दिन तक सुरक्षित है` *(elder-tier short: `सुनील भैया की दुकान बंद हो रही है — पैसा वापस, डेटा {N} दिन सुरक्षित`)* | Sunil-bhaiya's shop is closing — your money will come back, your data is safe for {N} days |
| 43 | `purge_scheduled` banner | Firestore listener fires on `Shop.shopLifecycle == purge_scheduled` | Same banner slot, copy updates to a stronger "export now" nudge. Color shifts one step warmer amber. Data-export CTA is now the primary action inside the banner itself (not just inside the FAQ) | `डेटा {N} दिन में हटा दिया जाएगा — export कीजिए` | Data will be deleted in {N} days — export now |
| 44 | `deactivated` / reactivated-off — banner cleared | Firestore listener reports `shopLifecycle == active` (reactivation) OR `purged` (hard purge complete) | Banner slot clears. Reactivation: no extra fanfare — the shop simply reappears. Purge: if the customer still has the app installed, a read-only FAQ remains accessible from `मेरे ऑर्डर` so historical receipts can still be exported from local cache | (reactivation) — | (purge) `इस दुकान का डेटा हटा दिया गया है। आपकी पुरानी रसीदें अब भी आपके फ़ोन में हैं।` | — / This shop's data has been deleted. Your old receipts are still on your phone. |
| 45 | FAQ screen — `क्या हो रहा है?` | User taps banner | Full-screen read-only scroll with plain Awadhi-Hindi bullets. No DPDP Act jargon, no legal tone. Five sections: money / orders / udhaar / retention / data export. Each section 2–3 sentences max. Data-export CTA pinned to the bottom as a sticky primary button. Explicit framing addresses device-holder persona: the `orders` section opens with `आपके परिवार के सभी ऑर्डर` ("all your family's orders") to clarify that the lifecycle applies retroactively to orders placed through this device by any family member *(v1.1 AE F2 patch — persona focus group surfaced that Rahul, the 23-year-old device-holder, may not realize the lifecycle applies to orders his mother placed through his phone)*. FAQ screen is also subscribed to the Firestore Shop listener — if the shop reactivates while the FAQ is open, the screen auto-redirects back to the normal shop landing with a 300ms fade *(v1.1 AE F6 patch — failure mode analysis surfaced stale-FAQ-after-reactivation)* | (title) `क्या हो रहा है?` | (title) What is happening? |
| 46 | Data-export CTA action | User taps `डेटा export कीजिए` | Spinner while B1.13 runs over every past Project for this customer (PDF rendering is client-side). On completion, single share-sheet invocation bundling all receipts. Subtitle during render: `आपकी सारी रसीदें एक साथ तैयार हो रही हैं` ("all your receipts are being prepared together") | `आपकी सारी रसीदें एक साथ तैयार हो रही हैं` | All your receipts are being prepared together |
| 47 | Udhaar frozen state (customer-visible) | Open UdhaarLedger has `shopLifecycle != active` on parent Shop | The udhaar summary card on the customer's order tracking screen shows `रुका हुआ` ("paused") badge instead of the normal reminder-toggle row. Running balance is preserved. No reminders fire. No "collect now" CTA — this is deliberate (R10) | (badge) `रुका हुआ` | (badge) Paused |
| 48 | Offline-catchup — user opens app after deactivation already happened | App launches while device is offline OR the user has been offline since before the transition | First Firestore real-time listener tick after the app becomes foreground + online shows the banner. If the app is STILL offline on launch, the cached Shop document's last known `shopLifecycle` value is authoritative for that session — a small `ऑफ़लाइन — आखिरी बार देखा हुआ दिखा रहे हैं` sub-banner already exists (§6.1 state #1) and stacks on top if both apply | (sub-banner) `ऑफ़लाइन — आखिरी बार देखा हुआ दिखा रहे हैं` | (sub-banner) Offline — showing what was last loaded |

### 6.8 — Shopkeeper NPS card states (S4.17) *(v1.1 add per PRD v1.0.5 John's handoff)*

| # | State | Trigger | Recommended UX | Devanagari copy | English copy |
|---|---|---|---|---|---|
| 49 | NPS card — appears | 14 days since last `shopkeeper_burnout_self_report` document for this operator | **Dismissible dashboard card, NOT a modal** (PRD S4.17 AC #1 explicit). Lives inside `आज की सूची` triage screen, below the three triage sections. 10-dot rating row (1–10), horizontal, DM Mono numerals. **Anchor labels below the dot row**: `1 = बिल्कुल नहीं` on the left, `10 = बहुत ज़्यादा` on the right, in Mukta 10pt *(v1.1 AE F12 patch — Socratic questioning surfaced that a bhaiya unfamiliar with NPS will not know what "1" vs "10" means without anchor labels)*. Optional `कुछ कहना है?` textarea below the dots. Primary button: `भेज दीजिए` ("send"). Secondary link: `बाद में` ("later" — 7-day snooze). **Role-based visibility:** only operators with `role == "bhaiya"` see the card in the bi-weekly cadence. Beta and munshi operators see a once-a-month lighter variant with the same copy but different analytics tag (`authorRole` records which operator submitted), so the trailing-60-day NPS aggregate tile can filter to bhaiya-only signal *(v1.1 AE F3 patch — persona focus group surfaced that mixing Aditya's and the munshi's ratings with Sunil-bhaiya's dilutes the Brief §6 Month 6 "shopkeeper NPS" success gate)* | (headline) `कितना उपयोगी लगा?` *(casual, NOT formal `कितना उपयोगी पाया?` — party mode F-P3 finding)* | (headline) How useful did you find it? |
| 50 | NPS card — dismissed / snoozed | User taps `बाद में` | Card collapses with a 150ms fade; snoozed for 7 days. No toast, no "snoozed!" confirmation — silent | — | — |
| 51 | NPS card — submitted | User taps `भेज दीजिए` with a score selected | Card collapses; tiny inline acknowledgment `धन्यवाद` ("thank you") pill at the card's former position for 2 seconds, then vanishes. Writes to `shops/{shopId}/feedback/{feedbackId}` per PRD AC #2. NO celebration animation | (inline pill) `धन्यवाद` | (inline pill) Thank you |
| 52 | Month-6 gate aggregation tile | Automatic on S4.11 dashboard visit | A small tile in the analytics section: `Shopkeeper NPS (पिछले 60 दिन): {X}/10`. DM Mono for the numeral. Tile is operator-facing (bhaiya role only) — not customer-facing | `Shopkeeper NPS (पिछले 60 दिन): {X}/10` | Shopkeeper NPS (trailing 60 days): {X}/10 |
| 53 | Burnout warning — quiet detection | Cloud Function detects 2 consecutive scores ≤6 | **NO shopkeeper-facing alarm.** The `BurnoutWarningDetected` Crashlytics event fires silently (per PRD AC #4). The shopkeeper sees nothing — surfacing it would insult the bhaiya and violate the spirit of the Brief R1 kill-gate mitigation ("shift workload, don't shame"). Yugma Labs ops sees the warning in Crashlytics and intervenes out-of-band | — *(no shopkeeper-facing copy by design)* | — |

### 6.9 — Shop deactivation ops-flow states (S4.19) *(v1.1 add per PRD v1.0.5 John's handoff)*

| # | State | Trigger | Recommended UX | Devanagari copy | English copy |
|---|---|---|---|---|---|
| 54 | Settings visibility — bhaiya-only | Operator's `role == "bhaiya"` AND Settings screen loads | The `दुकान बंद करना` section is rendered. For `role in ("beta", "munshi")` the section is not rendered at all (not disabled, not greyed-out — hidden. The munshi must not even know the flow exists) | (section header) `दुकान बंद करना` | (section header) Shop deactivation |
| 55 | Tap 1 of 3 — informational page | Bhaiya taps `दुकान बंद करने का विकल्प` | Full-screen Devanagari scroll. Five sections: customers / orders / udhaar / retention / data purge. Each section 3–4 sentences of plain Awadhi-Hindi. NO legal jargon. NO bullet points of DPDP Act clauses — this is written FOR the shopkeeper, not the shopkeeper's lawyer. Bottom: single primary button `आगे बढ़िए` ("continue"), secondary `रुक जाइए` ("stop here") | (title) `जब आप दुकान बंद करेंगे, तो क्या होगा?` *(v1.1 AE F10 patch — Socratic register check reordered the when-clause before the what-clause; softer Awadhi-inflected order)* | (title) When you close the shop, what will happen? |
| 56 | Tap 2 of 3 — reason dropdown | User tapped `आगे बढ़िए` on tap 1 | Single-screen dropdown, 4 enum values. Large 56dp tap targets. No search. No text field — this maps to the SAD v1.0.4 `shopLifecycleReason` enum exactly | `रिटायर हो रहा हूँ` / `शॉप बंद कर रहा हूँ` / `बीमारी / मेडिकल` / `अन्य` | Retiring / Closing the shop / Illness or medical / Other |
| 57 | Tap 3 of 3 — final confirmation | User selected a reason | Bottom-sheet dialog (NOT a full-screen). Two buttons: `हाँ, पक्का बंद कीजिए` (primary, warning color) and `रुकिए, मुझे सोचना है` (secondary, plain). **Inverted-language reversibility footer printed directly below the primary button**: `अगर गलती से दबाया, अगले 24 घंटे में उल्टा कर सकते हैं` ("if you tapped by mistake, you can reverse this in the next 24 hours"). This footer is not a help tooltip — it is printed on the live dialog where the finger is hovering | (dialog title) `क्या आप पक्का हैं? यह तुरंत शुरू हो जाएगा।` | (dialog title) Are you sure? This will start immediately. |
| 58 | Reversibility window — 24h | `shopLifecycle == deactivating` AND `shopLifecycleChangedAt` within last 24 hours | Settings screen's `दुकान बंद करना` section transforms into a reversal CTA: a prominent yellow-amber card with `दुकान फिर से चालू कीजिए` ("reopen shop") and a DM Mono countdown showing hours-remaining (e.g., `18 घंटे बाकी`). Tap runs the same 3-tap flow with inverted copy. Beyond 24 hours, the section shows a disabled informational row: `Yugma Labs से संपर्क कीजिए` ("contact Yugma Labs") — out-of-app recovery only | (reversal card) `दुकान फिर से चालू कीजिए — {H} घंटे बाकी` | (reversal card) Reopen shop — {H} hours remaining |

### 6.10 — Media spend ops tile states (S4.16) *(v1.1 add per PRD v1.0.5 John's handoff)*

| # | State | Trigger | Recommended UX | Devanagari copy | English copy |
|---|---|---|---|---|---|
| 59 | `मीडिया खर्च` tile — green | Cloudinary credits used <50% of monthly ceiling | Progress bar colored with shop accent success-token (green). `{used}/25` credits in DM Mono. Month-over-month delta arrow `↑ 12%` or `↓ 4%` in DM Mono next to the total. Projected end-of-month figure as a subtitle: `अनुमानित महीने का अंत: {projection}` | (subtitle) `अनुमानित महीने का अंत: {projection}` | (subtitle) Projected end of month: {projection} |
| 60 | `मीडिया खर्च` tile — amber | Cloudinary credits 50–80% | Same tile, progress bar switches to amber token, banner above reads `मीडिया खर्च आधा से ज़्यादा — जल्द खत्म हो सकता है` | `मीडिया खर्च आधा से ज़्यादा — जल्द खत्म हो सकता है` | Media spend over half — may run out soon |
| 61 | `मीडिया खर्च` tile — red | Cloudinary credits ≥80% | Progress bar red, banner red. Copy unchanged from AC #4. No emoji. No warning-triangle icon (deliberate — the operator should not associate the ops dashboard with panic) | (reuses same copy, red token) | (reuses same copy, red token) |
| 62 | `मीडिया खर्च` tile — red-alt, R2 active | Cloudinary credits ≥100% AND `mediaStoreStrategy == r2` | Banner copy flips to the dual-English product-name variant. This is the only place in the customer OR ops app where two English product names stack — intentional, because the operator will Google them if confused | `Cloudinary खत्म — R2 चालू` | Cloudinary done — R2 active |
| 62b | `मीडिया खर्च` tile — count-incomplete asterisk | `multiTenantAuditJob` nightly audit fails or Cloudinary API rate-limits during counter reconciliation (PRD S4.16 edge case #1) | A small `*` asterisk appended to the primary number with a tooltip-row below: `⚠️ गिनती अधूरी — रात में ठीक हो जाएगी` ("count incomplete — will be fixed tonight"). Tile color UNCHANGED by this state — it's an informational overlay, not a threshold change. On next successful audit, the asterisk vanishes silently *(v1.1 AE F7 patch — failure mode analysis surfaced that the PRD edge case exists but had no UX representation)* | `⚠️ गिनती अधूरी — रात में ठीक हो जाएगी` | Count incomplete — will be fixed tonight |

### 6.11 — S4.10 udhaar ledger card affordances (tweak) *(v1.1 add per PRD v1.0.5 John's handoff)*

Three new UI affordances on the existing S4.10 ledger card per PRD v1.0.5 AC #7, #8, #9. No new screen — additions to the existing ledger list item.

| # | Affordance | Trigger | Recommended UX | Devanagari copy | English copy |
|---|---|---|---|---|---|
| 63 | Reminder opt-in toggle | Rendered on every open ledger row | Toggle switch row with the bhaiya-authored question. Default OFF. Affirmative tap required per R10 defensive posture. When OFF, the row below (cadence stepper) is greyed-out but still visible (discoverability). **3-second undo micro-toast** after every toggle (ON or OFF) — bottom-of-screen Gmail-style pill `बदल दिया — उल्टा करना है?` ("changed — undo?") with a single-tap reversal that re-flips the toggle. Prevents fat-finger opt-in cascades on a 10-ledger screen *(v1.1 AE F8 patch — failure mode analysis surfaced that rapid ON-taps across multiple ledgers have no undo path, and undo is structurally important because opt-in is the RBI defensive posture pivot point)* | `क्या मैं इस ग्राहक को याद दिलाऊँ?` | Should I remind this customer? |
| 64 | Reminder count badge | Rendered when `reminderCountLifetime > 0` | Small DM Mono badge next to the customer's name: `याद दिलाया गया: {count}/3`. At 3/3, badge turns amber-neutral (not red — this is not a shame state, it is an informational cap). NO "quota exceeded" alarm copy | `याद दिलाया गया: {count}/3` | Reminded: {count}/3 |
| 65 | Cadence stepper | Rendered inside expanded ledger detail | Horizontal stepper UI. Min 7, max 30, default 14. Large tap targets (56dp per elder-tier rules — applies here too because the munshi uses this screen). DM Mono numeral. No percentage, no slider-handle decoration, no "recommended" callout. Just a clean 7⋯30 range | (label) `कितने दिन बाद याद दिलाना है?` | (label) After how many days should I remind? |

### 6.12 — Total state count

**Sixty-seven distinct states cataloged above** *(34 base states from v1.0 §6.1–§6.5 renumbered + 33 new states from §6.6–§6.11 including AE-surfaced variants #41b and #62b; was 29 in v1.0 — the 34 number was a footer drift Sally is correcting in-line here while we have the spec open)*. *(v1.1: +36 new states for B1.13 / C3.12 / S4.17 / S4.19 / S4.16 / S4.10 surfaces per John's handoff from PRD v1.0.5, plus +2 AE-derived failure variants #41b PDF render failure and #62b media audit rate-limit.)* The Brief Constraint 15 Devanagari QA must verify all of them render correctly on at least 5 cheap-Android devices. A running list of "did we design for this state?" is maintained in `docs/runbook/state_catalog.md` (a new artifact this spec creates; Amelia should populate it with screenshots as each story ships).

---

## §7 — Accessibility Spec

Accessibility here is not a checkbox — it is a commercial requirement. Persona C (Geeta-ji, 61) and the elder-tier rendering of Persona A (Sunita-ji's mother-in-law) are a meaningful fraction of the customer base, and Devanagari rendering on cheap Android is a release-blocking concern per Pre-Mortem Failure Mode #9.

### 7.1 — Elder tier transformations (already summarized in §4.6; here in spec form)

The elder tier is triggered by any of:
- An elder persona selected in the Decision Circle toggle (Mummy-ji, Papa-ji, Dadi, Chacha-ji).
- The `बड़ा अक्षर` (large text) accessibility toggle in Settings (PRD P2.8).
- System-level large text setting on Android (respected additively, never overridden).

When triggered, the following ThemeData transformations apply:

| Property | Transformation |
|---|---|
| `textTheme` base size | ×1.4 (from 14sp to 20sp) |
| `textTheme` heading sizes | ×1.4 |
| Minimum tap target | 56dp (from 48dp) |
| Animation duration multiplier | ×1.5 (from 200ms to 300ms) |
| Voice note default volume | ×1.3 (clamped to device maximum) |
| Line height | ×1.15 (from 1.4 to 1.6) |
| Inter-item spacing | ×1.67 (from 12dp to 20dp) |
| Bottom nav style | label-only (no icon-only mode) |
| Contrast ratio target | WCAG AAA (7:1) minimum for body text |

**Do not change:**
- Brand colors (Mummy-ji wants Sunil-bhaiya's colors, not a "senior palette").
- Font family (Tiro Devanagari Hindi display + Mukta body stay; Fraunces + EB Garamond for English + DM Mono for numerics per Brief v1.4 Constraint 4 — *v1.1 patch, was "Noto Sans Devanagari / Mukta" in v1.0*).
- Font weight (stay at regular; do not bold up — causes clipping on conjuncts).
- Iconography style (keep consistent; only the label-vs-icon ratio changes).

### 7.2 — Devanagari rendering requirements

**The non-negotiable technical requirements:**

1. **Font subset must include the 200 most common Devanagari characters** plus every glyph actually used in `strings_hi.dart`. The subset is built via `tools/generate_devanagari_subset.sh` at build time. Budget: ≤100 KB total font payload for the Devanagari pair (Tiro Devanagari Hindi + Mukta); additional ≤60 KB budget for the English pair (Fraunces italic + EB Garamond) + DM Mono, per Brief v1.4 Constraint 4 + frontend-design bundle v1.0. *(v1.1 patch — was "Noto Sans Devanagari + Mukta" in v1.0.)*

2. **No conjunct clipping.** Devanagari conjunct characters (like क्ष, त्र, ज्ञ) must render without the top matra being cut off by the containing view's height. Every view that renders Devanagari text must have vertical padding of at least 1.2× the line height to prevent clipping. CI lint rule: any `TextStyle` with `height: < 1.4` in the codebase triggers a warning in Hindi contexts.

3. **No forced line breaks in the middle of a conjunct.** Flutter's default line-break algorithm handles this correctly for Devanagari, but we must verify on real devices because cheap Android text renderers occasionally break the rule.

4. **Numerical alignment.** When Western numerals appear alongside Devanagari text (e.g., `"₹14,000"` in the middle of a Hindi sentence), they must share a common baseline. Mixing fonts naively causes baseline drift. CI visual regression test captures this.

5. **Fallback to system font if the subset font is corrupted.** The Flutter app must detect glyph-missing at runtime and fall back to the system Devanagari font (most cheap Android phones bundle Noto Sans Devanagari as the system face — note this is a *runtime fallback* only; the primary stack per Constraint 4 is Tiro Devanagari Hindi + Mukta and the app never ships with Noto as a bundled asset). A "font fallback" log event fires to Crashlytics so we can measure how often this happens.

### 7.3 — Tap target and contrast requirements

| Context | Default tier | Elder tier |
|---|---|---|
| Button minimum size | 48×48dp | 56×56dp |
| Icon-only button minimum | 48×48dp (with 12dp label margin) | Not allowed (label required) |
| Text contrast ratio | WCAG AA (4.5:1 for body, 3:1 for large) | WCAG AAA (7:1 for body, 4.5:1 for large) |
| Focus indicator width | 2dp | 3dp |
| Voice note play button | 48×48dp | 64×64dp |

### 7.4 — Screen reader support

**v1 posture:** deferred to v1.5. The TalkBack-on-Hindi experience on Tier-3 cheap Android is notoriously inconsistent, and getting it right is a separate engineering effort the team has not budgeted for in v1.

**v1 acceptance criteria for screen readers (laying groundwork for v1.5):**
- Every image has an `alt` / semantic label field populated with the SKU name in Devanagari.
- Every button has a `semanticsLabel` matching its Devanagari display text.
- Every icon-only button has a Devanagari hint attached.
- The navigation order of focus follows the visual reading order.
- Form fields have label/field association via Flutter's `Semantics` widget.

**v1.5 screen reader scope:**
- TalkBack testing on Realme C-series, Redmi 9, Tecno Spark.
- Hindi voice output verification (the default TTS on these devices varies).
- Skip-to-content shortcuts for long lists.

### 7.5 — Device testing matrix (Brief Constraint 15 requirement)

Before any release, the v1 app must be verified on at least **5 distinct cheap Android device models**. My recommended set:

| Device | Screen | Why in the set |
|---|---|---|
| Realme C21 | 6.5" 720×1600 LCD | Cheapest Realme, common in Tier-3 |
| Redmi 9 | 6.53" 720×1600 LCD | Xiaomi's low-end; widely distributed in UP |
| Tecno Spark 9T | 6.82" 720×1640 LCD | Tecno has significant presence in rural UP |
| Samsung Galaxy M04 | 6.5" 720×1600 PLS LCD | Samsung reach; different renderer family |
| Lava Blaze 2 5G | 6.5" 720×1600 IPS LCD | Indian brand, different font-rendering quirks |

The first four are in the PRD I6.9 acceptance criteria; I'm adding Lava as a fifth because Indian brand phones sometimes have quirky font rendering and Samsung/Xiaomi/Realme/Tecno/Lava together cover the realistic device distribution of Sunita-ji's household.

**Testing checklist per device (must pass all):**
- [ ] First-launch cold start completes in <3 seconds.
- [ ] Sunil-bhaiya's face renders without scaling artifacts.
- [ ] Greeting voice note auto-plays with audible volume.
- [ ] Devanagari conjuncts render without clipping on the landing screen.
- [ ] Bottom nav labels do not clip on any of the three customer tabs.
- [ ] Persona toggle button is tappable and responsive.
- [ ] Elder-tier transition is smooth (no visible jank).
- [ ] Chat thread scrolls without stutter with 50+ messages.
- [ ] Voice note recording works with 4–5 second minimum and 60-second maximum.
- [ ] UPI intent launches the installed UPI app correctly.
- [ ] Offline mode shows cached content without error.
- [ ] *(v1.1 additions for the six v1.0.5 story surfaces)* B1.13 invoice renders both in default and in-app elder-tier preview, AND the generated PDF opens in WhatsApp / Gmail / Android Print without missing-glyph squares.
- [ ] C3.12 `deactivating` banner at 1.4× elder tier does NOT clip the bottom tab bar on 720×1600 screens (short-copy variant must be in use).
- [ ] S4.17 NPS card 10-dot row does not wrap or clip on 720px-wide screens in elder tier.
- [ ] S4.19 tap-3 confirmation dialog's reversibility footer `अगर गलती से दबाया…` wraps to at most 2 lines in elder tier; the primary confirm button remains tappable without horizontal scroll *(v1.1 AE F15 patch — operators could trigger system-level large text which cascades into the ops app dialog)*.
- [ ] S4.16 `मीडिया खर्च` tile numbers and banner do not clip when Cloudinary credits hit triple digits (e.g., `127/25`).
- [ ] S4.10 reminder-toggle undo micro-toast is tappable within the 3-second window on a cheap Android with average touch latency.

### 7.6 — The "Hindi-fluent design reviewer" requirement (Brief Constraint 15)

Per Brief Constraint 15 and Pre-Mortem Failure Mode #9, the product cannot ship without a Hindi-fluent design reviewer having signed off on copy and Devanagari visual craft. The checklist that reviewer uses:

1. **Does the Hindi copy read like a Harringtonganj-market shopkeeper wrote it, or like a Delhi copywriter wrote it?** Specifically flag Sanskritized vocabulary (*"स्वागतम्"*, *"उत्पाद"*, *"गुणवत्ता"*) and replace with Awadhi-natural alternatives.
2. **Is every UI string checked for line-break behavior?** Long Devanagari strings sometimes wrap poorly; the reviewer flags any case where a word ends with a matra on its own line.
3. **Are honorifics consistent?** The app's voice never uses *"तुम"*; it always uses *"आप"*. The shopkeeper's voice notes use whatever he naturally says (which might include *"तुम"* when addressing a close customer, which is fine).
4. **Does every error message offer a path forward?** No "Unfortunately...," no "Sorry we are unable to...".
5. **Do numerals follow the §5.4 rule?** (Western for amounts/prices/counts, Devanagari for dates/ordinals/ritual numbers.)
6. **Do all 50 example strings in §5.5 pass cultural review?** *(Phase 6 IR Check v1.2 patch 2026-04-11: corrected from stale "30" — v1.1 extended §5.5 to 50 strings for the 6 new v1.0.5 surfaces.)* Any that feel "off" are flagged for rework.
7. **Does the persona toggle copy (*"मम्मी जी देख रही हैं"* etc.) feel natural when spoken aloud?** If the reviewer stumbles when reading it, it is wrong.

**Process:** The Hindi-fluent reviewer sits with the design team for 4 weeks at the v1 spec phase (per Brief Step 0.6), reviewing every screen. They also sit with the QA team during Devanagari rendering tests on the 5 device models. Without this review, v1 does not ship. I am putting this in writing here because design phase is when the review must be contracted, not a month before launch.

---

## §8 — The 19 Walking Skeleton Screens — Strategic Notes

For each of the **19** Walking Skeleton stories (per PRD v1.0.5 §Walking Skeleton + Epics List v1.2 §2), a strategic UX note. Each note covers: the user moment the screen serves, the visual hierarchy, the emotional outcome, the one thing that must not happen, and cross-references to §4 interaction patterns or §5 copy. *(v1.1 patch — count bumped from 17 to 19. I6.12 added as a Sprint 1 foundational note per Epics v1.2; a pre-Sprint-0 I6.11 governance-gate note added because it blocks every UX-touching story in the skeleton.)*

### 8.0 — I6.11 — Hindi-native design capacity verification *(Sprint 0 precondition gate — NOT a Walking Skeleton story, but blocks every one of them)* *(v1.1 add)*

**Not user-visible** — zero UI surface. This is a governance artifact that Alok signs before any of the 19 Walking Skeleton stories is unblocked for Sprint 1 kickoff. **The one thing that must not happen:** a UX-touching story enters the Sprint 1 backlog while the verification artifact at `docs/runbook/hindi_design_capacity_verification.md` is missing or unsigned. **The one thing Sally pushes back on if it fires:** if the Remote Config fallback flips `defaultLocale: "hi" → "en"`, the customer app does NOT silently become English-first — the fallback is explicit, logged to Crashlytics as `constraint_15_fallback_triggered`, and the product's Hindi-source-of-truth posture (P1 in §1.2) becomes an **explicit** scope compromise that the founder has consciously accepted. This is Brief Constraint 15's named-compromise-not-silent-failure clause made concrete. **Cross-references:** §1.2 P1, §7.5, §7.6.

### 8.1 — I6.1 — AuthProvider adapter scaffolding

**Not user-visible.** Pure infrastructure. No UX surface. But: this is the story whose correctness determines whether any of the 16 user-visible screens below feel invisible (as they should) or visibly authenticatey (as they must not). If `signInAnonymously()` takes longer than 1.2 seconds on cold launch, the first-30-seconds test fails. **The one thing that must not happen:** a visible auth loading state during the first-time flow. Customer must never know auth happened.

### 8.2 — I6.2 — Anonymous → Phone Auth UID merger

**User moment:** The exact moment Sunita-ji's son taps "Confirm the order" and the app needs his phone number for the first time. It is the highest-anxiety moment in the entire customer journey — the moment where trust becomes transactional. **Visual hierarchy:** (1) The specific shopkeeper-need framing (*"सुनील भैया डिलीवरी के लिए संपर्क करेंगे"*), (2) the phone number input, (3) the continue button. **Emotional outcome:** the customer should feel the OTP is for the shopkeeper's practical delivery need, NOT for the app's security theater. Any inversion kills the funnel. **Must not happen:** the word "verify" or "security" on this screen. **Cross-references:** §4.9 (commit flow), §5.5 string 12.

### 8.3 — I6.3 — Refresh token session persistence

**Not user-visible** — which is exactly the point. **The one thing that must not happen:** a returning customer ever sees an OTP screen. If this fails on even 1% of returning sessions, the product's core promise breaks. **Cross-reference:** §3.2 (returning customer journey).

### 8.4 — I6.4 — Multi-tenant shopId scoping

**Not user-visible.** Pure schema discipline. But: a latent bug here becomes a catastrophic trust event when shop #2 onboards. **Must not happen:** any UI ever surfacing shop_0's "ugly magenta" theme in a real customer screenshot. (Per SAD §8, shop_0's synthetic theme has deliberately ugly colors as a diagnostic.)

### 8.5 — B1.1 — First-time customer onboarding

**User moment:** Rahul's thumb on the app icon for the first time. The thirty-second test I defined in §1.3 is this story. **Visual hierarchy:** (1) Shop name in Devanagari, (2) Sunil-bhaiya's face, (3) greeting voice note with auto-play + mute, (4) horizontal-scroll preview of curated shortlists. **Emotional outcome:** *"यह Sunil-bhaiya ki dukaan hai"* within two seconds. **Must not happen:** a generic splash screen with a Yugma Labs logo. The logo on the splash is the shop's logo, and the shop's name. Yugma Labs is invisible to the customer, forever. **Cross-references:** §1.3 (30-second test), §3.1 (first-time journey).

### 8.6 — B1.2 — Anonymous landing with shopkeeper face

**User moment:** The first full-screen content the customer ever sees. **Visual hierarchy:** (1) Sunil-bhaiya's face, dominant 40% of screen, (2) shop name in large Devanagari, (3) tagline + GST + established year, (4) "Sunil-bhaiya ki pasand" horizontal preview. **Emotional outcome:** the customer feels she is in his shop, not in an app. **Must not happen:** a cart icon. This is not Amazon. There is no cart. There are Projects (created from SKU detail) and the word "cart" does not exist in this app, in either language. **Cross-references:** §1.2 P2, §4.3 (curation default).

### 8.7 — B1.3 — Greeting voice note auto-play

**User moment:** Second 2 of the 30-second test. Sunil-bhaiya's voice is the first non-visual input. **Visual hierarchy:** (1) voice is audible, (2) mute button visible in top-right, (3) "Replay" button near the face. **Emotional outcome:** the customer hears a real human being who has a real shop in a real city. Not a chatbot, not a brand, not a narrator. **Must not happen:** an auto-play that cannot be stopped with one tap. Also must not happen: auto-play when the device is in silent mode. **Cross-references:** §4.4 (voice note interaction), §7.4 (screen reader accessibility).

### 8.8 — B1.4 — Curated occasion shortlists ("Sunil-bhaiya ki pasand")

**User moment:** Rahul scrolls to see "what Sunil-bhaiya picked today." This is where curation wins over infinite scroll. **Visual hierarchy:** (1) six occasion tabs with Devanagari labels, (2) 4–6 SKU cards per tab with Golden Hour photos, (3) "Sunil-bhaiya ki pasand" signature tag on each card. **Emotional outcome:** the customer feels curated, not flooded. She can see all of Sunil-bhaiya's weddings picks on one screen; she does not have to browse. **Must not happen:** filter bars, price-range sliders, "sort by" dropdowns, or any Amazon-shaped chrome. Also: pagination within a shortlist (see my pushback in §4.3 — a shortlist should feel finite). **Cross-references:** §4.3 (curation default), §5.5 strings 3–5.

### 8.9 — B1.5 — SKU detail with Golden Hour photo

**User moment:** The customer taps one almirah and sees it in Sunday-best light. **Visual hierarchy:** (1) full-width Golden Hour photo (70% of screen height), (2) Devanagari name + price, (3) dimensions + material + description, (4) voice notes attached to this SKU (if any), (5) two CTAs: "Add to my list" and "Talk to Sunil-bhaiya about this." **Emotional outcome:** the customer feels like she is looking at the almirah in its best moment, with Sunil-bhaiya's voice in her ear explaining it. **Must not happen:** the customer sees the *"negotiableDownTo"* floor price. That is a shopkeeper-only field. **Must also not happen:** generic stock-photo rendering in place of the Golden Hour. If the Golden Hour photo is missing, the "असली रूप" (working-light) photo shows with a small "जल्द ही असली रूप" badge — never a generic Amazon-style placeholder. **Cross-references:** §5.5 string 8, Pre-Mortem Failure Mode #2.

### 8.10 — C3.1 — Create Project draft from curated SKU

**User moment:** Rahul decides this is the almirah and starts a Project. **Visual hierarchy:** (1) confirmation toast in Devanagari, (2) bottom-sheet "draft project" indicator showing line items count and total, (3) return to SKU detail (he is not forced to navigate anywhere). **Emotional outcome:** the customer feels the Project is quietly collecting items, not demanding his attention. **Must not happen:** a full-screen interruption ("Item added to cart!") that breaks browse momentum. **Cross-references:** §4.1 (no cart tab), §5.5 string 6.

### 8.11 — C3.4 — Commit Project with Phone OTP upgrade

**User moment:** The committed family, after days of discussion, is ready to place the order. **Visual hierarchy:** (1) a prominent *"ऑर्डर पक्का कीजिए"* button when the Project is in draft or negotiating state, (2) on tap, the commit + OTP bottom sheet with the shopkeeper-need framing, (3) on successful commit, the confirmation screen with total + line items + payment CTA. **Emotional outcome:** the customer feels the commit is a handshake with Sunil-bhaiya, not a corporate form-filling ceremony. **Must not happen:** words "verify" or "secure" or "authentication" in the copy. **Cross-references:** §3.1 (first-time journey), §4.9 (commit + payment flow), §5.5 strings 11–12.

### 8.12 — C3.5 — UPI payment intent flow

**User moment:** The customer has committed and now pays. Five seconds, no commission, done. **Visual hierarchy:** (1) big primary button *"UPI से दीजिए"* with UPI logo and PhonePe/GPay/Paytm icons, (2) smaller *"और तरीके"* link for COD/bank/udhaar. **Emotional outcome:** payment feels like UPI everywhere else in her life, not like a new app's payment ceremony. **Must not happen:** a "Yugma Secure Pay" branded overlay. UPI is UPI. The less branding, the more trust. **Cross-references:** §4.9 (commit flow), §5.5 strings 13–14.

### 8.13 — P2.4 — "Sunil-bhaiya Ka Kamra" unified chat thread

**User moment:** The moment a committee of four family members starts talking to one shopkeeper in one thread. **Visual hierarchy:** (1) chat thread title *"सुनील भैया का कमरा — आपका ऑर्डर #XXX"*, (2) messages in chronological order with persona labels for customer-side messages, (3) text input + voice note + price-proposal buttons at bottom. **Emotional outcome:** the customer feels the thread is Sunil-bhaiya's room in her phone — a place where the whole family can gather. **Must not happen:** this screen accidentally feeling like a standard customer-service chat widget. It must feel like WhatsApp at its warmest, not like an Intercom overlay. **Cross-references:** §4.7 (chat interaction), §5.5 string 9.

### 8.14 — P2.5 — Customer sends text message

**User moment:** The first time Rahul types a question to Sunil-bhaiya. **Visual hierarchy:** (1) Devanagari text input at the bottom of the chat with a warm placeholder, (2) send button (icon), (3) the typed message appearing immediately in the thread with a pending-clock icon. **Emotional outcome:** the send feels instant and reliable, even on bad network. **Must not happen:** a send failure that is silent. Every pending message is visible, every failure is honest, every retry is automatic. **Cross-references:** §4.7 (chat interaction, offline draft handling), §5.5 string 10.

### 8.15 — S4.1 — Shopkeeper sign-in via Google

**User moment:** Sunil-bhaiya opens the ops app for the first time at 11:04 AM on a Tuesday. **Visual hierarchy:** (1) large Google Sign-In button, (2) shop logo above it, (3) "Yugma Labs" credit in small text at bottom. **Emotional outcome:** Sunil-bhaiya recognizes the Google ceremony and signs in without friction. **Must not happen:** a password field. If Google sign-in fails for any reason, we do NOT show a "create account" fallback — we show a "contact Yugma Labs" message. **Cross-references:** §5.5 string 30.

### 8.16 — S4.3 — Inventory: create new SKU

**User moment:** Aditya, on a Sunday evening, adds a new almirah that arrived from Kanpur. **Visual hierarchy:** (1) streamlined form with Devanagari labels, (2) large Devanagari name input as the first field, (3) "Capture Golden Hour photo" button prominent in the flow. **Emotional outcome:** Aditya feels the process is fast — under 90 seconds per SKU. **Must not happen:** a 12-field form with nested dropdowns. Five fields max in the main form; optional fields behind an "अधिक जानकारी" (more details) expansion.

### 8.17 — S4.5 — Golden Hour photo capture

**User moment:** Aditya captures the Sunday-best version of a new almirah. **Visual hierarchy:** (1) native camera view with a faint overlay showing "raking light angle," (2) one-tap capture button, (3) preview with "Save as hero" / "Save as working" tabs. **Emotional outcome:** Aditya feels the process is one tap, not a photography session. **Must not happen:** a required quality check that blocks a save. If the photo is dark, we save it as "working" and prompt him to try again at golden hour — we never refuse a save. **Cross-reference:** Pre-Mortem Failure Mode #2 (Golden Hour decay — we must gracefully handle the reality that the shopkeeper takes most photos in tube-light).

### 8.18 — I6.12 — Offline-first field-partition discipline *(v1.1 add per Epics v1.2 §2 Sprint 1 addition)*

**Not user-visible** — pure repository-layer infrastructure. Freezed sealed unions (`ProjectCustomerPatch` / `ProjectOperatorPatch` / `ProjectSystemPatch`), extended to `ChatThread` and `UdhaarLedger`, enforce the SAD v1.0.4 §9 field-partition at compile time. **UX implication — and this is why Sally is writing a strategic note about an infrastructure story:** this is the structural guarantee that a 3-day-offline customer cannot accidentally revert operator-owned state on reconnect. **The user moment this protects:** Sunita-ji's phone is offline from Tuesday lunch to Thursday evening. Meanwhile Sunil-bhaiya has advanced her Project from `committed` to `delivered`. When her phone reconnects, the sync layer must NOT let any queued customer-side write overwrite `project.state`. Without I6.12, a customer-side draft message replay could silently revert the delivery. With I6.12, the draft-replay message write is constrained by the sealed union to a `ProjectCustomerPatch` that literally cannot touch `state`. **The one thing that must not happen:** a customer-authored field ever lands in a system-owned or operator-owned slot after offline replay. **Must also not happen:** the UX ever feels like the sync layer made a decision — reconnection should be silent, correct, and boring. **Cross-reference:** §1.2 P6 (offline-is-default), §3.5 udhaar journey (where the shopkeeper-side running-balance write is exactly the kind of operator-owned state that must be protected from a customer-side offline replay), §4.7 (chat offline drafts — which I6.12 keeps safely in the customer partition), PRD Standing Rule 11, SAD v1.0.4 §9.

### 8.19 — I6.10 — Crashlytics + Analytics + Performance + App Check *(Phase 6 IR Check v1.2 patch 2026-04-11 — was implicit-only in v1.1, now explicit to match the 19 Walking Skeleton count asserted in §8 header)*

**Not user-visible** — pure observability and abuse-protection infrastructure. **UX implication:** zero chrome, zero UI, zero user-facing loading states. **The one thing that must not happen:** any Crashlytics toast, any Analytics consent dialog, any App Check failure banner, any "Performance monitoring enabled" screen. Telemetry is invisible. The customer never knows we measure anything. **The user moment this protects:** Sunita-ji on a 2G connection at 11:47 PM on the wedding night — if B1.3's voice note fails to load, we find out silently via Crashlytics, not via her calling Sunil-bhaiya to complain. This is the story that makes the Month 3 gate measurable: without day-one observability, the Walking Skeleton ships blind. **Must not happen #2:** App Check ever blocking a real customer's first launch because Play Integrity is slow on a cheap Android cold-boot. The App Check grace period is tuned so the customer never sees an error screen; failures log to Crashlytics and the request proceeds under a degraded-but-functional posture. **Cross-references:** §7.5 device testing matrix (Crashlytics custom keys capture which of the 5 cheap-Android models triggered a font fallback or a conjunct clip), §7.2 item 5 (font fallback Crashlytics event), PRD I6.10 AC, SAD §1 observability stack.

---

## §9 — Open UX Questions

Questions this UX spec cannot resolve alone. Each has my recommended answer; Alok's call to lock or override.

### Q1 — Should the curated shortlists be finite (no pagination) or infinite (pagination enabled)?

**Context:** PRD B1.4 AC#2 specifies "paginated to load more on scroll." I argue in §4.3 that a shortlist should feel finite — if Sunil-bhaiya put 6 almirahs in "shaadi ke liye," the customer sees 6. **My recommendation:** finite. No pagination within a shortlist. The "और दिखाइए" button (which I'm adding to every shortlist at the bottom) expands into paginated inventory, but the shortlist itself is a closed set. **Reasoning:** finiteness is the feature. Pagination implies the curation is a search result; it is not. **If locked:** I'll update §4.3 and recommend John patch B1.4.

### Q2 — Does the customer app have an English toggle, and if so, where does it live?

**Context:** Brief Constraint 4 mandates Hindi as default with "English as a toggle." The PRD does not explicitly specify where the toggle lives. **My recommendation:** a small `EN / हि` switch in the top-right of the shop landing screen (not buried in settings), and a persistent setting that is remembered per device. The default is always Hindi on first install. **If a customer taps the EN switch**, all user-facing copy switches to English immediately; the Devanagari voice notes remain in Hindi (Sunil-bhaiya's voice is not translated). **Reasoning:** burying the toggle makes the English-second rule invisible and forces English-speaking customers to struggle; placing it too prominently suggests Hindi is the "translated" version, which it is not.

### Q3 — How does the "large text" accessibility toggle (PRD P2.8) coexist with the Decision Circle persona toggle when DC is enabled?

**Context:** §4.6 says the elder tier is triggered by either (a) an elder persona selected in DC, or (b) the universal large-text toggle. If both are active, what takes precedence? **My recommendation:** large-text toggle is always additive — once enabled, it applies regardless of DC persona. If DC is on and the persona is the default "मैं" but the large-text toggle is on, elder tier renders. If DC is on and the persona is "मम्मी जी," elder tier renders (regardless of the toggle). If both are off, default tier. **Reasoning:** the toggle is the universal fallback (per R11); it must always work. DC adds contextual awareness on top of it.

### Q4 — What does the customer see on the away banner if Sunil-bhaiya has recorded zero away voice notes?

**Context:** Pre-Mortem Failure Mode #1 predicts the shopkeeper will record very few voice notes. PRD B1.10 says the feature "gracefully degrades to text-only" if no away voice notes exist. **My recommendation:** text-only is fine for default tier, but for elder tier, a fallback synthesized voice is NOT acceptable (would feel like a bot). In elder tier with no voice notes, the away banner is larger, bolder, and paired with a *"सुनील भैया को संदेश छोड़िए"* (leave a message for Sunil-bhaiya) CTA that opens the chat thread with a pre-filled draft. **Reasoning:** we never fake Sunil-bhaiya's voice. If he hasn't recorded, the app is honest about it and offers an alternative path.

### Q5 — How does the customer app handle the case where the shopkeeper has completely disabled the in-app chat in favor of WhatsApp (`commsChannelStrategy = whatsapp`)?

**Context:** SAD ADR-005 and PRD P2.4 AC#10 specify that if `commsChannelStrategy` is `whatsapp`, the chat thread screen redirects to a `wa.me` link. **My recommendation:** instead of a redirect, the chat thread screen shows a simple call-to-action: *"सुनील भैया से WhatsApp पर बात कीजिए"* with a large button that opens the `wa.me` link in WhatsApp. The in-app chat thread screen still exists (for history), but new messages go via WhatsApp. The Project context blob (state, line items, price) is attached to the `wa.me` prefilled message by the `generateWaMeLink` Cloud Function. **Reasoning:** a hard redirect on tap feels broken. A CTA that says "open WhatsApp" is honest and gives the customer agency.

### Q6 — Does the shopkeeper ops app have a notification for the `firebasePhoneAuthQuotaMonitor` quota approaching?

**Context:** SAD §7 Function 5 monitors the 10k/month phone auth SMS quota and alerts at 80%. The alert currently goes to Yugma Labs ops. **My recommendation:** the shopkeeper should ALSO see a soft notification if the quota is approaching — framed as *"बहुत ग्राहक आ रहे हैं! हम जल्द ही आपको बताएंगे अगर कोई बदलाव होगा।"* (many customers are coming! We'll tell you if anything needs to change.) This is a positive message, not an alarm. **Reasoning:** the shopkeeper should feel the app is proactive about telling him when things scale. Hiding it feels opaque.

### Q7 — On the customer side, when the Project is in `awaiting_verification` state (after bank transfer self-report, PRD C3.7), what does the customer see?

**Context:** After the customer self-reports a bank transfer, the Project goes to `awaiting_verification` until the shopkeeper manually verifies. The PRD does not specify what the customer sees in the meantime. **My recommendation:** a soft banner on the Project detail screen: *"सुनील भैया आपका bank transfer देख रहे हैं — जल्द ही पुष्टि होगी"* (Sunil-bhaiya is checking your bank transfer — confirmation soon). The chat thread is still open for questions. No polling, no "waiting for..." progress indicators. **Reasoning:** the customer should feel the process is happening at a human pace, not waiting for an automated system.

### Q8 — B1.13 Mukta-italic signature: is the fallback "handwritten" enough, or does v1.5 need a real captured-signature-image path? *(v1.1 add)*

**Context:** B1.13 AC #5 specifies Mukta italic as the signature treatment to stay inside Constraint 4's approved 5-font stack. The alternative — Caveat or any new Google Font — is forbidden. SAD v1.0.4 ADR-015 pre-specifies `shopkeeperSignatureImageUrl` as a future field. **My recommendation:** ship v1 with Mukta italic. Watch the NPS feedback for any customer mention of the receipt feeling "templaty." If two or more shopkeepers by Month 6 say they want a real handwritten signature, add a signature-capture flow in v1.5 that writes to `shopkeeperSignatureImageUrl` and renders the image inside the existing footer slot. **Reasoning:** the Constraint 4 discipline is load-bearing; adding Caveat silently in v1 would break it. Mukta italic is the honest compromise that respects both the constraint and the intent. **If locked differently by Alok:** anything other than Mukta italic in v1 requires a Constraint 4 revision in the Brief, which is a founder-level decision.

### Q9 — S4.17 NPS card for beta / munshi — is a quarterly variant actually useful, or should only the bhaiya see the card? *(v1.1 add)*

**Context:** AE F3 (persona focus group) surfaced that mixing Aditya's (beta) and the munshi's ratings with Sunil-bhaiya's dilutes the Brief §6 Month 6 "shopkeeper NPS" gate. I've patched in a once-a-month lighter variant for non-bhaiya roles with an `authorRole` analytics tag, so the aggregation tile can filter to bhaiya-only. **But**: is that variant worth the implementation cost? **My recommendation:** ship the bhaiya-only variant in v1; defer the beta/munshi variant to v1.5 if Yugma Labs ops actually wants multi-role feedback. **Reasoning:** the Brief §6 success gate is bhaiya-signal; everything else is noise until proven otherwise. **If locked "multi-role from v1":** the `authorRole` analytics tag is already in place; Amelia just renders the card under a longer-cadence feature flag.

---

## §10 — Handoff Notes for the Frontend Plugin and for Amelia

Two audiences for this final section: the `frontend-design` plugin (which will generate the Flutter component library and visual mockups in parallel with this spec), and Amelia (who implements the code).

### 10.1 — What the `frontend-design` plugin should produce

This spec is the strategic layer; the plugin produces the code-level component library. Based on the sections above, the plugin's output should cover:

**A. The base Flutter component library** (`packages/lib_core/lib/src/widgets/` + `apps/customer_app/lib/widgets/` + `apps/shopkeeper_app/lib/widgets/`):

1. `YugmaTheme` — a `ThemeExtension` subclass implementing §4.6 elder-tier transformations. Accepts a `YugmaThemeMode` enum (default / elder).
2. `ShopkeeperLanding` — the first-screen widget for B1.1 / B1.2. Takes `ShopThemeTokens` and renders the face + name + tagline + shortlist preview.
3. `GreetingVoiceNotePlayer` — auto-play-on-first-visit with mute + replay (B1.3).
4. `CuratedShortlistTabs` — six occasion tabs with lazy-loaded SKU grids (B1.4).
5. `SkuDetailScreen` — full-width Golden Hour photo + asli-roop toggle + voice notes inline + two CTAs (B1.5).
6. `PersonaTogglePill` — floating button + bottom sheet for persona selection (P2.2).
7. `ChatThread` — paginated message list with text / voice note / image / system / price-proposal message types (P2.4).
8. `PriceProposalCard` — special interactive card for the price_proposal message type (§4.8).
9. `VoiceNoteRecordButton` — press-and-hold recording with waveform animation and duration counter (§4.4).
10. `UdhaarLedgerView` (ops) — compliant with ADR-010; no forbidden vocabulary (§5.6).
11. `TriageListCard` — the ops-app morning-routine triage card (§3.4).
12. `ElderTierSwitcher` — a widget that consumes the current persona + accessibility toggle state and applies the elder tier transformation to child widgets.
13. `DevanagariSkeletonLoader` — skeleton loader with Devanagari-shaped placeholders (§6.5).
14. `AwayBanner` — presence status banner with optional voice note (§4.10).

**B. The visual token set** (to be consumed by all widgets):
- Brand colors from `ShopThemeTokens` (saddle brown, chocolate, gold, cornsilk, dark wood).
- Typography tokens with Devanagari-first font family (Tiro Devanagari Hindi display + Mukta body as primary, per Brief v1.4 Constraint 4; Fraunces + EB Garamond for English; DM Mono for numerics).
- Spacing, radius, shadow tokens calibrated for both default and elder tiers.

**C. Interaction specs**: the plugin should encode the §4 interaction patterns into Flutter `Interaction` specs — tap, long-press, drag-to-reorder, press-and-hold-to-record, persona toggle.

**D. Mockups** (PNG/SVG output): high-fidelity mockups of each of the 17 Walking Skeleton screens, rendered in both default and elder tiers, with Devanagari and English copy variants.

### 10.2 — What Amelia should keep in mind when implementing

Eleven things Amelia should have pinned on her wall while implementing the Walking Skeleton:

1. **The 30-second test is the acceptance criterion for B1.1/B1.2/B1.3/B1.4.** If a customer does not feel the five feelings from §1.3 within 30 seconds of app launch on a real cheap Android device on a real 4G connection, those stories are not done. Demo is the test.
2. **Every string in `strings_hi.dart` is authored, not translated.** If you find yourself writing English strings first and then translating them into Hindi, stop and wait for the copywriter. This is a release blocker, not a polish item.
3. **The Decision Circle UX survives its own feature flag being off.** Every widget that reads `DecisionCircle` state must have a null-path that renders correctly when the flag is `false`. Build the off-state first, then layer the on-state on top.
4. **Voice note recording is press-and-hold, not tap-start-tap-stop.** This is WhatsApp muscle memory for Sunil-bhaiya. Do not argue with it.
5. **The Hindi-fluent reviewer has the final word on any string.** If you want to rephrase a string to make it "more natural" or "more concise," talk to the reviewer first.
6. **Elder tier is NOT a separate theme.** It is the same theme with multiplied values (per §4.6 and §7.1). Do not create a `YugmaThemeElder` class. Create a `YugmaTheme` that consumes a `tier` parameter.
7. **Every empty state has a custom copy per §5.7.** Do not ship a generic "No items" string.
8. **The UPI deep link must include the Project ID in the note field** so the shopkeeper's VPA metadata return captures which Project the payment is for. Do not omit this.
9. **The `generateWaMeLink` Cloud Function is the ONLY way to construct a `wa.me` link in the customer app.** Do not hardcode `wa.me` URLs elsewhere.
10. **The forbidden vocabulary list from §5.6 is enforced by a CI lint.** Add the lint rule as a prerequisite to the first PR you open.
11. **Every screen has a skeleton state.** No screen ships with a generic spinner. §6.5 specifies the skeleton design rules.
12. **B1.13 invoice — explicit DO-NOT list (v1.1 AE F16 patch, red-team inversion finding).** The invoice template MUST NOT contain: a Yugma Labs logo or "powered by" footer anywhere on the page; a QR code of any kind; a "rate this receipt" link or any feedback CTA; a cross-sell ("you may also like"); a discount coupon or promo code; a "share and earn" incentive; a "view on web" link; any third-party ad or sponsor pixel. The receipt is the shopkeeper's artifact and the customer's file — Yugma Labs is invisible on the paper, forever. Amelia is explicitly prohibited from "polishing" the template with any of these additions as a nice-touch during implementation; any such addition must go through Sally for review first.
13. **B1.13 PDF is NOT transformed by elder tier (v1.1 AE F13 patch, elder-tier what-if scenario).** The in-app PREVIEW screen before share-sheet respects the elder tier (larger fonts in the preview). The rendered PDF itself is a fixed-size artifact at standard point sizes — a PDF that was printed at 24pt instead of 13pt would look absurd in a filing cabinet and would break print-driver layouts. Elder tier applies to the app; the PDF is a document.
14. **S4.17 NPS card — no gamification (v1.1 AE F17 patch, red-team inversion).** The card must NOT show streaks, badges, "you've given N ratings", "keep it up", or any game-loop reinforcement. The Triple Zero attention-discipline (P10 in §1.2) applies here — the shopkeeper's attention is not a resource the product gets to spend on engagement metrics. A submitted rating shows a 2-second `धन्यवाद` pill and nothing else, ever.
15. **C3.12 countdown is informational, never dark-pattern urgency (v1.1 AE F18 patch).** The `{N} दिन` countdown in the `purge_scheduled` banner is printed in amber, never red. The copy is descriptive ("data will be deleted in N days"), never imperative ("act now!"). No blinking, no ticking animation, no "only 3 days left!" red-framed urgency — this is a dignified heads-up, not a shopping-site timer.

### 10.3 — Non-negotiable acceptance criteria for "design done" per Walking Skeleton story

Beyond the PRD's functional acceptance criteria, each Walking Skeleton story must pass the following UX acceptance criteria before it can be marked design-done.

**For every Walking Skeleton story:**
- [ ] Hindi copy has been reviewed and approved by the contracted Hindi-fluent reviewer.
- [ ] Devanagari rendering tested on 5 cheap Android devices (per §7.5).
- [ ] Default tier and elder tier mockups exist and pass visual review.
- [ ] Empty state is designed and copy-reviewed.
- [ ] Error state is designed and copy-reviewed.
- [ ] Loading/skeleton state is designed.
- [ ] Offline behavior is documented.
- [ ] Cross-references to §4 interaction patterns are explicit in the story's `uxSpec` field (a new field that should be added to the story template).

**For B1.1 / B1.2 / B1.3 / B1.4 specifically (the first-30-seconds stories):**
- [ ] The full 30-second test has been run on a real cheap Android device on a real 4G connection.
- [ ] The customer feels all five of the feelings from §1.3 (unprompted observation, not guided usability test).
- [ ] No modal, no "rate us," no "welcome" overlay has appeared.

**For C3.4 (commit with OTP) specifically:**
- [ ] The OTP prompt copy uses the shopkeeper-need framing (*"सुनील भैया डिलीवरी के लिए संपर्क करेंगे"*), NOT security framing.
- [ ] The "skip OTP after 3 failed attempts" fallback has been tested.
- [ ] The `otpAtCommitEnabled = false` code path has been tested.
- [ ] The Firebase phone auth quota monitor integration has been verified.

**For P2.4 / P2.5 (chat thread) specifically:**
- [ ] The offline draft handling has been tested across airplane-mode toggles.
- [ ] The real-time listener has been tested with 50+ messages without pagination jank.
- [ ] The persona label attribution renders correctly in both default and elder tiers.

---

## Summary — What this spec is saying, in one paragraph

Sunil Trading Company's app should feel, from second zero, like walking into Sunil-bhaiya's shop — except Sunita-ji is sitting in her own verandah, and somehow both of those things are true. The two pillars of the product (Bharosa and Pariwar) translate into ten UX principles, five critical journeys, and a handful of interaction patterns that make curated discovery feel like Sunil-bhaiya's hand on the customer's shoulder instead of an algorithm's hand on her attention. Hindi is the source-of-truth language; English is the translation; Awadhi is the dialect; warmth lives in specificity, not in poetry; elder tier is respectful, not infantilizing; absence is presence; Triple Zero applies to attention as well as money. The Decision Circle is a silent superpower when it works and invisible when it doesn't — never a feature to evangelize. The OTP at commit is framed as Sunil-bhaiya's practical delivery need, not as app-level security theater. Voice notes are press-and-hold muscle memory, not a new ceremony to learn. Curated shortlists are finite, not paginated. The forbidden vocabulary list for udhaar khaata is enforced at the CI layer, not just at the lawyer's review. The 30-second test is the acceptance criterion for the landing flow, and the 10-minute test is the acceptance criterion for the shopkeeper's morning routine. If this spec is followed with discipline, the customer will close the app, turn to her mother-in-law, and say *"Sunil-bhaiya ne diya tha"* — not *"we bought it on the Yugma app."* The product disappears; the shopkeeper remains. That is the whole game.

---

**End of UX Specification v1.1.**

**Total length:** ~16,800 words *(v1.1: +~6,000 words over v1.0 for John's mandatory handoff and AE patches)*
**Sections:** 10 strategic sections + preamble + summary
**Walking Skeleton strategic notes:** **19** *(v1.1: +I6.12 Sprint 1 foundational note, +I6.11 Sprint 0 gate note; was 17 in v1.0)*
**Cross-references to Brief:** ~35
**Cross-references to SAD:** ~25
**Cross-references to PRD:** ~55
**Cross-references to Elicitation Report:** ~15
**Example Devanagari strings provided:** **50** *(v1.1: +20 for B1.13 / C3.12 / S4.17 / S4.19 / S4.16 / S4.10 surfaces; was 30 in v1.0)*
**Error/Empty/Loading states cataloged:** **67** *(v1.1: +36 for new surfaces + 2 AE-derived failure variants; was 29 in v1.0 with a 34 footer drift corrected in §6.12)*
**UX principles:** 10
**User journeys mapped:** 5
**Interaction patterns specified:** **16** *(v1.1: +§4.11 invoice template, +§4.12 deactivation banner, +§4.13 NPS card, +§4.14 3-tap progression, +§4.15 media tile, +§4.16 ledger reminder affordances; was 10 in v1.0)*
**Open questions for Alok:** **9** *(v1.1: +Q8 Mukta-italic signature review, +Q9 multi-role NPS scope; was 7 in v1.0)*

---

## v1.1 Patch Note (2026-04-11) — Phase 4 BMAD back-fill: AE + Party Mode

**Trigger:** Phase 4 of the BMAD planning-chain back-fill. Founder caught that AE + Party Mode acceptance gates were skipped on 5 of 6 planning artifacts. Phase 1 (SAD v1.0.4), Phase 2 (PRD v1.0.5), Phase 3 (Epics v1.2) are already back-filled upstream. This spec (UX Spec v1.0 → v1.1) is Phase 4.

**Input change set:** PRD v1.0.1 → v1.0.5 (+8 new stories: I6.11, I6.12, B1.13, C3.12, S4.16, S4.17, S4.18, S4.19; +4 AC updates: I6.7, C3.4, C3.5, S4.10). SAD v1.0.1 → v1.0.4 (+ADRs 013/014/015, +Shop lifecycle schema, +feedback sub-collection, +RBI guardrail fields on UdhaarLedger). Epics v1.0 → v1.2 (Walking Skeleton 17 → 19, Sprint 0 gate, Sprint 1 + I6.12). Brief v1.3 → v1.4 (Constraint 4 font stack revised: Tiro Devanagari Hindi + Mukta + Fraunces + EB Garamond + DM Mono replaces the original Noto Sans Devanagari specification).

### John's mandatory handoff — applied in full

1. **B1.13 Devanagari invoice** — §4.11 new interaction pattern (typographic hierarchy table, layout diagram, state variants, share-sheet interaction, offline behavior). §6.6 states #35–#41 + AE-added #41b (PDF render failed fallback). §5.5 strings #31–#36. §10 handoff items #12 and #13 (explicit DO-NOT list + elder-tier clarification).
2. **C3.12 shop deactivation customer banner** — §4.12 new interaction pattern (banner slot, 3 lifecycle variants, FAQ interaction, offline catchup). §6.7 states #42–#48. §5.5 strings #37–#40. §10 handoff item #15 (countdown is informational, never dark-pattern urgency).
3. **S4.17 shopkeeper NPS card + burnout early warning** — §4.13 new interaction pattern (non-negotiables, bi-weekly cadence, burnout warning invisibility). §6.8 states #49–#53. §5.5 strings #41–#43. §10 handoff item #14 (no gamification).
4. **S4.19 shopkeeper-triggered deactivation 3-tap progression** — §4.14 new interaction pattern (3 invariants, reasons enum, reversibility window). §6.9 states #54–#58. §5.5 strings #44–#45.
5. **S4.16 media spend ops tile (secondary surface)** — §4.15 new interaction pattern (visual structure, 4 color/banner states). §6.10 states #59–#62 + AE-added #62b (count-incomplete asterisk). §5.5 strings #46–#47.
6. **S4.10 udhaar ledger reminder affordances (tweak)** — §4.16 new interaction pattern (three affordances). §6.11 states #63–#65 (with AE-added undo micro-toast on #63). §5.5 strings #48–#50.
7. **I6.12 offline field-partition discipline** — §8.18 new Walking Skeleton strategic note (explains the UX implication of compile-time sealed unions for offline replay correctness).
8. **I6.11 Hindi-native design capacity gate** — §8.0 new pre-Sprint-0 governance note.

### 5 AE methods picked

1. **#4 User Persona Focus Group** *(persona-empathy)* — Sunita-ji / Aditya / Geeta-ji / Sunil-bhaiya react to the new surfaces. Surfaced F1 (invoice filename lacks shop name when forwarded to MIL), F2 (Rahul device-holder doesn't realize C3.12 banner applies retroactively to mom's orders), F3 (NPS card mixes Aditya's / munshi's ratings with bhaiya's, diluting Brief §6 Month 6 gate), F4 (S4.19 bhaiya-role check is device-agnostic, correct posture confirmed).
2. **#35 Failure Mode Analysis** *(failure-mode)* — what happens when the tier-3 Android dies mid-flow? Surfaced F5 (B1.13 PDF OOM on cheap Android has no fallback), F6 (C3.12 FAQ goes stale if shop reactivates while screen is open), F7 (S4.16 tile has no UX for the PRD edge case #1 count-incomplete asterisk), F8 (S4.10 rapid fat-finger toggles have no undo cascade path).
3. **#41 Socratic Questioning** *(cultural / language-register)* — stress-test Awadhi-inflected register. Surfaced F9 (C3.12 "पैसा वापस" is correct — keep as-is), F10 (S4.19 tap-1 title needed Awadhi when-clause reorder), F11 (B1.13 footer "हमारा भविष्य" passes — keep), F12 (S4.17 10-dot row needs anchor labels `1 = बिल्कुल नहीं` / `10 = बहुत ज़्यादा`).
4. **#27 What If Scenarios** *(accessibility / elder-tier)* — does design survive 1.4× elder-tier transformation? Surfaced F13 (B1.13 PDF cannot be elder-tier-scaled — only the in-app preview can), F14 (C3.12 full banner wraps to 3 lines in elder tier and clips bottom nav — short-copy elder variant required), F15 (S4.19 reversibility footer could wrap in system-large-text mode).
5. **#17 Red Team vs Blue Team** *(counter-intuition / inversion)* — what's the WORST version of each new surface, and what does that reveal we're missing? Surfaced F16 (B1.13 needs an explicit DO-NOT list to prevent "nice touch" additions like QR codes, cross-sell, Yugma logo), F17 (S4.17 could accidentally become a gamification surface — explicit no-gamification line needed), F18 (C3.12 countdown could drift into dark-pattern urgency — amber-only, informative-only discipline), F19 (S4.16 tile's four-threshold system is already worst-case safe — no change).

### AE findings table — severity / party mode vote / disposition

Party-mode voices: **S** = Sally (UX/persona empathy), **J** = John (PRD ACs / dependencies), **F** = frontend-design plugin (visual tokens / Constraint 4 feasibility / Workshop Almanac aesthetic discipline), **M** = Mary (Brief intent / 2 pillars / 15 constraints / 16 risks).

| # | Finding | Severity | S | J | F | M | Vote | Disposition |
|---|---|---|---|---|---|---|---|---|
| F1 | B1.13 filename lacks shop name | 🟠 | ✅ | ✅ | ✅ | ✅ | 4-0 | **Patched** — state #41 updated |
| F2 | C3.12 banner retroactivity unclear to device-holder | 🟡 | ✅ | ✅ | ⚠️ *"FAQ is the right place, not the banner"* | ✅ | 4-0 accept modify | **Patched** — FAQ copy updated (state #45) |
| F3 | NPS card dilutes bhaiya signal with non-bhaiya ratings | 🔴 | ✅ | ✅ | ✅ | ✅ *"Brief §6 gate is bhaiya-only by definition"* | 4-0 | **Patched** — role-based visibility added to state #49; Q9 added |
| F4 | S4.19 bhaiya-role check device-agnostic | 🟡 | ✅ | ✅ | ✅ | ✅ | 4-0 | **Confirmed, no patch** — current posture is correct; 24h reversibility is the family-member safeguard |
| F5 | B1.13 PDF OOM has no fallback | 🟠 | ✅ | ✅ | ✅ *"cheap Android OOM is real"* | ✅ | 4-0 | **Patched** — state #41b added |
| F6 | C3.12 FAQ stale on reactivation | 🟠 | ✅ | ✅ | ✅ | ✅ | 4-0 | **Patched** — state #45 FAQ now subscribes to listener |
| F7 | S4.16 count-incomplete state has no UX | 🟡 | ✅ | ✅ | ✅ | ⚠️ *"PRD edge case already exists; UX patch is catch-up, fine"* | 4-0 | **Patched** — state #62b added |
| F8 | S4.10 fat-finger cascade toggles have no undo | 🔴 | ✅ | ✅ | ✅ | ✅ *"R10 defensive posture pivot point — undo is structural"* | 4-0 | **Patched** — 3-second undo micro-toast on state #63 |
| F9 | C3.12 "पैसा वापस" register check | 🟡 | ✅ keep | ✅ keep | — | ✅ keep | 3-0 keep | **No patch** — register is correct |
| F10 | S4.19 tap-1 title Awadhi reorder | 🟠 | ✅ | ⚠️ *"copy-only, PRD-agnostic, fine"* | — | ✅ *"this is exactly the Hindi-reviewer's job"* | 3-0 accept | **Patched** — state #55 title reordered |
| F11 | B1.13 footer "हमारा भविष्य" register | 🟡 | ✅ keep | ✅ keep | — | ✅ *"everyday commerce language, not mythic"* | 3-0 keep | **No patch** — confirms PRD AC #5 |
| F12 | S4.17 10-dot row anchor labels | 🔴 | ✅ | ✅ | ✅ *"UX affordance gap, not PRD change"* | ✅ | 4-0 | **Patched** — state #49 anchor labels added |
| F13 | B1.13 PDF is not elder-tier-transformable | 🟠 | ✅ | ✅ | ✅ *"fixed-size PDF discipline"* | ✅ | 4-0 | **Patched** — §10 handoff item #13 added |
| F14 | C3.12 banner wraps and clips nav in elder tier | 🔴 | ✅ | ✅ | ✅ *"720x1600 layout constraint is non-negotiable"* | ✅ | 4-0 | **Patched** — short-copy elder variant added to state #42 |
| F15 | S4.19 reversibility footer elder-tier wrap | 🟠 | ✅ | ⚠️ *"system-large-text is the path, not persona elder-tier"* | ✅ | ✅ | 4-0 accept modify | **Patched** — §7.5 elder-tier wrap test added |
| F16 | B1.13 needs explicit DO-NOT list | 🔴 | ✅ | ✅ | ✅ *"Triple Zero attention discipline"* | ✅ *"Yugma invisible on the paper forever"* | 4-0 | **Patched** — §10 handoff item #12 added |
| F17 | S4.17 no-gamification line | 🔴 | ✅ | ✅ | ✅ | ✅ *"P10 Triple Zero attention"* | 4-0 | **Patched** — §10 handoff item #14 added |
| F18 | C3.12 countdown dark-pattern risk | 🟠 | ✅ | ✅ | ✅ *"amber-only, no ticking"* | ✅ *"dignity over urgency"* | 4-0 | **Patched** — §10 handoff item #15 added |
| F19 | S4.16 four-threshold already safe | 🟡 | ✅ keep | ✅ keep | ✅ keep | ✅ keep | 4-0 keep | **No patch** |

**Ties broken by Sally:** none this round — all votes were unanimous or 4-0 with explicit modifier notes.

### AE patches applied beyond John's handoff

- State #41b (B1.13 PDF render failed fallback)
- State #62b (S4.16 count-incomplete asterisk)
- Elder-tier short-copy variant on state #42
- FAQ real-time listener subscription on state #45
- Role-based NPS visibility on state #49
- Anchor labels on state #49
- Undo micro-toast on state #63
- §10 handoff items #12–#15 (B1.13 DO-NOT list, B1.13 elder-tier clarification, S4.17 no-gamification, C3.12 dignity-over-urgency)
- §7.5 device testing checklist extended with 6 new v1.0.5-surface checks
- Q8 and Q9 added to §9 Open Questions

### Walking Skeleton strategic notes

**Old count (v1.0):** 17. **New count (v1.1):** 19. Added: §8.0 I6.11 Sprint 0 governance gate, §8.18 I6.12 offline field-partition discipline. All 17 pre-existing notes preserved unchanged.

### Voice & tone updates

**Old count (v1.0):** 30 strings. **New count (v1.1):** 50 strings. New strings #31–#50 cover B1.13 (6 strings), C3.12 (4 strings), S4.17 (3 strings), S4.19 (2 strings), S4.16 (2 strings), S4.10 (3 strings). Forbidden-vocabulary list extended with the Constraint-10 mythic/Sanskritized list and a permitted-everyday-warmth-words list.

### State catalog growth

**Old count (v1.0):** 29 (footer claimed 34 — a v1.0 drift corrected in §6.12). **New count (v1.1):** 67. New states #35–#65 cover all six v1.0.5 surfaces. AE-added variants: #41b, #62b.

### Cross-checks — compliance verification

**Constraint 4 font stack compliance** *(strict — no other fonts permitted)*:
- ✅ Tiro Devanagari Hindi used for B1.13 header only
- ✅ Mukta used for Devanagari body throughout
- ✅ Mukta italic (larger size) used for B1.13 signature — Caveat is forbidden
- ✅ Fraunces reserved for English display zones
- ✅ EB Garamond reserved for English body zones
- ✅ DM Mono used for all prices / timestamps / Project IDs / NPS numerals / countdown digits
- ✅ Stale "Noto Sans Devanagari" references from v1.0 updated throughout §4.6, §7.1, §7.2, §10.1 to the current canonical stack
- ✅ No Caveat, no Inter, no Roboto, no new Google Fonts added anywhere

**Constraint 10 "show don't sutra" compliance** *(strict — no mythic framing)*:
- ✅ B1.13 footer uses `धन्यवाद, आपका विश्वास हमारा भविष्य है` — everyday commerce language, not mythic
- ✅ No `शुभ` anywhere
- ✅ No `मंदिर` / `धर्म` / `तीर्थ` / `आशीर्वाद` / `पूज्य` / `मंगल` anywhere
- ✅ No `स्वागतम्` — used `स्वागत` instead (without the Sanskritized suffix)
- ✅ No `उत्पाद` / `गुणवत्ता` / `श्रेष्ठ` anywhere
- ✅ Forbidden-mythic list explicitly added to §5.6 alongside the udhaar-forbidden list

**R10 udhaar forbidden vocabulary compliance** *(strict — enforced at CI lint)*:
- ✅ B1.13 udhaar-open receipt uses only `बाकी: ₹{amount}` — no interest, no due date, no penalty
- ✅ S4.10 reminder affordances use `क्या मैं इस ग्राहक को याद दिलाऊँ?` — no schedule / interval / period / auto-remind vocabulary
- ✅ Cadence stepper labeled `कितने दिन बाद याद दिलाना है?` — no "interval" / "cadence" English loanwords
- ✅ `याद दिलाया गया: 2/3` is informational, not shame language
- ✅ No `ब्याज` / `पेनल्टी` / `बकाया तारीख` / `देरी का जुर्माना` / `ऋण` / `वसूली` / `क़िस्त` anywhere

### Version bump

**v1.0 → v1.1.** Patch level (not minor — the strategic frame is unchanged, the additions are back-fill of stories John's v1.0.5 handoff already authorized).

### Verdict for Phase 5 frontend-design plugin

Phase 5 (Frontend Design Bundle AE + Party Mode) needs to know about six new visual surfaces this UX Spec has introduced. Each has strict Constraint 4 font-stack compliance and strict Constraint 10 copy discipline, and each has a concrete state catalog the plugin must generate mockups for:

1. **B1.13 Devanagari invoice template** — Tiro Devanagari Hindi header 32pt / Mukta body 11–13pt / DM Mono numerics / Mukta italic 24pt signature. 7 states (paid / cancelled watermark / udhaar balance-due / missing-name fallback / missing-logo fallback / page break / render-failure fallback). Cross-ref §4.11, §6.6. **DO-NOT list from §10 handoff item #12 is binding on the plugin's template generation.**
2. **C3.12 banner + FAQ** — 3 lifecycle banner states (deactivating / purge_scheduled / reactivated-cleared) + FAQ screen with 5 sections + data-export CTA + elder-tier short-copy banner variant + offline-catchup stacking with §6.1 state #1. Cross-ref §4.12, §6.7.
3. **S4.17 NPS dashboard card** — dismissible card (never modal), 10-dot row with `1 = बिल्कुल नहीं` / `10 = बहुत ज़्यादा` anchor labels, optional textarea, primary button + secondary link hierarchy, role-based visibility (bhaiya primary, beta/munshi deferred), invisible burnout-warning path. Cross-ref §4.13, §6.8. **No gamification from §10 handoff item #14 is binding.**
4. **S4.19 3-tap progression** — bhaiya-role-only Settings section, full-screen informational page (tap 1), reason dropdown enum (tap 2), confirmation dialog with inverted-language reversibility footer printed directly below the confirm button (tap 3), 24-hour reversal window card. Cross-ref §4.14, §6.9. **The reversibility footer placement is the most important single design decision in this flow — plugin must render it on the live dialog, not in a tooltip.**
5. **S4.16 `मीडिया खर्च` tile** — single ops dashboard tile, 4 color/banner states, DM Mono numerics, count-incomplete asterisk overlay state. Cross-ref §4.15, §6.10.
6. **S4.10 udhaar ledger reminder affordances** — three new affordances added to the existing S4.10 card: opt-in toggle with 3-second undo micro-toast, reminder count badge, cadence stepper. Cross-ref §4.16, §6.11. **R10 forbidden vocabulary discipline is binding.**

The plugin should generate mockups in BOTH default and elder tiers for each state. Where a state is explicitly not elder-tier-transformable (B1.13 PDF per §10 handoff item #13), the plugin should generate only the default tier and annotate the exception.

— Sally, Senior UX Designer
2026-04-11 (v1.1 patch on top of 2026-04-10 v1.0 baseline)
