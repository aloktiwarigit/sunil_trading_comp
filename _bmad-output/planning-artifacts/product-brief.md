# Product Brief: Yugma Dukaan *(working name — see §10)*

**The world-class digital storefront for the independent almirah shopkeeper of Hindi-speaking North India**

**Prepared by:** Mary (Strategic Business Analyst, Yugma Labs)
**For:** Alok, Founder, Yugma Labs
**Date:** 2026-04-10 (drafted), 2026-04-11 (Advanced Elicitation v1.1 → field-work defaults v1.2 → Winston architecture revisions v1.3)
**Status:** Draft v1.3 — Architecture phase complete; Winston's Solution Architecture Document at `solution-architecture.md`. Brief revised per Winston's §13 fragility findings. Ready for John (PM) handoff. Real shopkeeper specifics replace defaults when shop is identified.
**Flagship customer:** **Sunil Trading Company** (सुनील ट्रेडिंग कंपनी) — a real multi-generational almirah shop in Ayodhya's Harringtonganj market, run by **Sunil-bhaiya** (working assumption — confirm/correct). Slug: `sunil-trading-company`. Marketing site: `sunil-trading-company.yugmalabs.ai`. The "Ramesh-bhaiya" archetype name used elsewhere in this document and in the synthesis is a placeholder for Sunil-bhaiya — replace as needed during implementation.
**Input artifacts:** `party-mode-session-01-synthesis-v2.md`, competitive landscape research (Indian shop-in-app platforms 2026), technical feasibility research (Firebase/Flutter stack 2026), North India almirah market research (April 2026)

---

## 1. Executive Summary

**Yugma Dukaan** is a deeply opinionated digital storefront — a Flutter customer app, a Hindi-first marketing website, and a Flutter shopkeeper operations app — designed for a single category (almirahs and household wardrobes) in a single linguistic-cultural context (Hindi-speaking Tier-2/3 North India), governed by a single radical economic doctrine:

> **Triple Zero** — zero commission on the shopkeeper, zero fees on the customer, and a scope-bounded ₹0 operational cost posture at shop #1 scale that remains cost-sustaining through approximately shops #10–33, at which point a flat-fee SaaS model takes over with unit economics that must be modeled as a v1.5 deliverable (see §9 R3). Triple Zero is **not** an unbounded cost guarantee or a perpetual moat — it is the operational discipline of architecting for free-tier ceilings, a discipline competitors (Dukaan 2023 collapse) have failed. Revenue in v1 is ₹0. Yugma Labs monetizes later, from shop #2 onwards, via a flat-fee SaaS model.

Where Dukaan, Shopnix, SmartBiz by Amazon, and Meesho build generic horizontal tools for small merchants — and where Pepperfry and Urban Ladder tried and failed to replace the local furniture shopkeeper altogether — Yugma Dukaan takes a different bet: **the independent shopkeeper is not a commodity to be aggregated, nor a middleman to be disintermediated. He is the product.** His face, his voice, his curation, his memory of past customers, his honest *"aaj shaadi mein hoon, 6 baje wapas"* — these are first-class citizens of the experience, not trust-signals bolted onto a template. The customer does not browse a catalog; she sees the almirahs *Ramesh-bhaiya chose* for her specific occasion, in her language, and pays with UPI that takes nothing from him.

The flagship customer **will be** a real shopkeeper in Ayodhya's Harringtonganj market — to be identified and committed via LOI before architecture begins (see §12 Next Step 0). The product strategy is geography-*portable* (not strictly agnostic — see §8 Constraint 12): Yugma Dukaan is designed to onboard a furniture shopkeeper in Gorakhpur, Kanpur, Barabanki, Faizabad, Sultanpur, or any other Hindi-speaking Tier-2/3 city where a single-shop owner has built decades of relational capital that currently cannot travel through a screen, with a per-shop cultural adaptation cost of ~2 weeks. Ayodhya is where shop #1 happens to be — nothing more.

The engineering constraint is deliberate, not expedient. The entire stack fits inside Firebase's free tiers (Blaze plan with a hard $1/month budget cap as a pure safety rail, *not* an expected spend) and a small set of other zero-cost services. There is **no unavoidable recurring line item at one-shop scale**. The customer app layers **Firebase Anonymous Auth** (unlimited free, for browse / Decision Circle / committee chat) with **Firebase Phone Auth** (a ~10,000 SMS verifications/month free allowance on Blaze — observed in founder production experience but **not yet confirmed from a primary Google source**, see §9 R8) at the commitment moment. The shopkeeper operations app uses **Google Sign-In** (unlimited free). This discipline is not the whole moat — "zero commission" is commoditized by Meesho and SmartBiz, and Hindi-first admin has a 6–12 week catch-up window against a determined competitor (see §9 R7 and §4.2). The durable defense is the combination of (a) operational discipline through the early-shop frontier, (b) the accumulated shopkeeper content library (voice notes, curated shortlists, customer memory), and (c) cultural specificity that competitors cannot translate into existence quickly. Dukaan's 2023 collapse shows what happens when VC-backed competitors' unit economics fail this discipline. Yugma Labs' posture is the opposite: ship lean, survive, outlast — without mistaking posture for permanence.

The product is built on a **single-tenant UX, multi-tenant architecture** foundation (strangler-fig pattern). Every piece of content, theming, copy, and configuration is externalized from day one, namespaced by shop ID. v1 is lovingly tuned for the Ayodhya shopkeeper — his name, his colors, his tone, his inventory — but the same codebase onboards shop #2 without a rewrite. That extraction is Yugma Labs' v2 unlock.

If this works, three years from now Yugma Labs runs a network of 50–200 Hindi-first digital storefronts for independent local shopkeepers across North India, starting with almirahs and extending into adjacent big-ticket, trust-heavy, committee-bought categories (electronics, household appliances, jewelry, cycles, bikes). Shopkeepers pay a flat monthly SaaS fee. Customers pay nothing. The architectural discipline makes it sustainable where VC-backed predecessors' burn rates never did.

---

## 2. The Problem

### The shopkeeper's side

In a Tier-3 North Indian city, an independent almirah shopkeeper — the kind of man whose father ran the same shop on the same lane — has spent twenty or thirty years building something digital platforms cannot see on a spreadsheet: **relational capital**. He remembers which family bought a Godrej Storwel for their eldest daughter's wedding in 2011 and comes back in 2026 to buy the next one for the younger daughter. He knows which almirah to steer a budget-conscious newlywed couple toward and which to put in front of a senior civil servant's wife. His word on a polish or a hinge is more durable than any manufacturer's written warranty.

Today, none of this travels through a screen. His digital footprint is, at most, a WhatsApp Business catalog — a blunt instrument with no order history, no curated shortlist, no structured customer memory, no payment rail, no way to let a family in three different cities discuss an almirah in the same thread. When a 30-year-old daughter in Mumbai wants to buy her mother an almirah for the Faizabad house, she cannot reach him digitally in any way that preserves his *bharosa*. She ends up fragmenting the decision across WhatsApp screenshots, Google Images, Amazon searches, and phone calls to her mother — and often settles for a faceless Godrej Interio store in Lucknow or a Pepperfry-alike that ships her a damaged unit in ten days.

The existing "shop-in-an-app" platforms do not solve this. **Dukaan** charges a 4.99% service fee on its free plan and suffered a reputation collapse in 2023–24 after mass layoffs broke customer support. **Shoopy** is the only platform with native Hindi UX but raised only $250K in 2021 and is functionally dormant. **Bikayi** has ~3 employees as of early 2026 and is effectively dead. **Meesho** claims zero commission but its marketplace model strips the shopkeeper of brand, customer relationship, and bharosa, and its RTO economics punish sellers of big-ticket items. **SmartBiz by Amazon** is free until June 2026 — at which point it will be priced to kill the indies it onboarded. **Flipkart Samarth** is a marketplace program, not a storefront.

None of them are Hindi-first on the admin dashboard. None of them are designed for big-ticket, committee-bought, considered-purchase categories. None of them honor the fact that in Tier-3 India, the *physical shop* is still the real storefront and the app's job is to amplify it, not replace it.

### The customer's side

A 45–55-year-old mother in Faizabad buying an almirah for her daughter's wedding does not want to browse. She wants the shopkeeper to point and say *"yeh lo, didi, shaadi ke liye yehi hai."* She wants her husband to see it on his phone in the office, her mother-in-law to see it on the same phone in the kitchen, her son in Bangalore to glance at it over video, and everyone to agree — or to negotiate — before anyone pays. She wants the shopkeeper's voice answering *"thoda discount ho jayega?"* without typing a single message. She wants to pay via UPI and get the almirah delivered by tomorrow afternoon on the shopkeeper's own tempo, assembled free, and know that if the lock fails next Diwali she can walk back into the shop and it will be fixed.

Today, this simple transaction fragments across three WhatsApp threads, two phone calls, one confused video chat, and a visit to the physical shop where her feet hurt by the fifth almirah. The digital layer, when it exists at all, actively *reduces* the trust she has in the shopkeeper by forcing her into an alien vocabulary of "cart," "checkout," "EMI option," and "delivery ETA."

### The cost of the status quo

- The shopkeeper's relational capital doesn't scale beyond his physical shop. It evaporates the moment his customer's decision-making moves online.
- The customer pays hidden costs — in time, trust deficit, missed family coordination, and often in settling for a faceless brand that doesn't care about her daughter's wedding.
- Yugma Labs sees an entire underserved category (independent furniture / household-goods shopkeepers in Hindi-speaking Tier-2/3 North India) that no existing platform is building for honestly.

### Why now

Three forces converge in 2026:
1. **UPI is universal** in Tier-3 India, making zero-MDR payment rails viable for the first time.
2. **Dukaan's 2023 collapse** has left a reputational vacuum and burned a generation of small shopkeepers on "shop-in-an-app" promises. There is room for an honest re-entry.
3. **Flutter + Firebase + on-device AI tooling has matured** to the point where a small team can ship world-class apps entirely inside free tiers. A product that five years ago required $500K in infrastructure can now run at literal ₹0 recurring cost. The Triple Zero posture is engineering-feasible for the first time.

---

## 3. The Solution

A three-component platform built on two product pillars and one architectural discipline.

### The two pillars

#### 🙏 Bharosa — the shopkeeper IS the product

The shopkeeper's face, voice, memory, and curation are first-class citizens of the app. Nothing on any screen exists independently of him. Specifically:

- **Shopkeeper-first landing.** The customer's first screen is not a catalog — it is the shopkeeper's face, his name in Devanagari, a voice note welcoming them in his own voice, and the curated shortlist he hand-picked for today. No infinite scroll, no filter bar, no "Shop By Category."
- **Curated occasion shortlists** ("Ramesh-bhaiya ki pasand"): *Shaadi ke liye / Naye ghar ke liye / Budget ke liye / Dahej ke liye / Replacement ke liye / Ladies ke liye / Gents ke liye*. The shopkeeper updates these daily from his ops app in one tap. Browse/filter exists only behind an "Aur dikhaiye" button as an emergency fallback.
- **"Remote control for his finger."** The shopkeeper's pointing gesture — *"yeh lo, didi, yehi hai"* — becomes a tap in his ops app that surfaces an almirah to a specific customer's session. This is the product's primary interaction model.
- **Voice notes throughout.** The shopkeeper can drop a voice note on any product, any customer, any Project. Customers hear his actual voice, his accent, his warmth, his negotiation style.
- **Customer memory.** When a customer opens the app, the shopkeeper sees *"this is the cousin of the family that bought the Shelly-4D in 2023."* He uses that context to build instant rapport. The customer never sees this layer — it's an ops-side superpower.
- **Absence as presence.** When the shopkeeper is unavailable, the app says so out loud: *"Ramesh-bhaiya aaj shaadi mein hain, 6 baje tak wapas. Aap beta Aditya se baat kar sakte hain — yahan dabaiye."* Pre-recorded "away" voice notes. Scheduled callback windows. Son/nephew fallback routed automatically. Never pretend he's always there.
- **Golden Hour Mode.** Every piece of inventory is photographed at the shop's actual "golden hour" — the one brutal hour each afternoon when raking light makes the wood grain look alive and the brass handles throw copper coins onto the opposite wall. The customer sees the almirah's Sunday-best version, not the 11 AM tube-light version. The shopkeeper controls a toggle — *"asli roop dikhaiye"* — for customers who want to see the unfiltered shop light. Turns the physical shop's architecture into a closing tool.
- **Plain dignified invoices.** Devanagari primary, shopkeeper's name and handwritten-font signature, no mythic copy, no poetry. The warmth lives in the typography and the specificity, not in captions.

#### 👨‍👩‍👧‍👦 Pariwar — the product is committee-native, not individual-native

In Tier-3 North India, a ₹20,000 almirah is never bought by one person. It is bought by a committee — father-in-law who pays, mother-in-law who judges polish, daughter-in-law who picks color, cousin who Googles. Chachaji will never download an app. The product assumes this reality from the data model up:

- **Decision Circle as session state, not social network.** One phone, many faces, zero logins. When the mother-in-law takes the phone, the family member holding it taps *"Mummy-ji dekh rahi hain"* and the UI changes in real time: bigger fonts, slower animation, more respectful tone, larger photos, louder voice note playback. When the son takes the phone back, *"wapas mujhe"* toggles it back to normal density. The architecture treats "who is currently looking at the phone" as first-class session metadata, not an account.
- **"Ramesh-bhaiya Ka Kamra" shared thread.** One thread per Project. Four relatives across four cities can drop questions into the same thread at 9:47 PM. The shopkeeper drops one voice note and all four phones light up. He is not four separate WhatsApp chats — he is the unified gravitational center of the committee.
- **Project-based data model.** Every customer order is a **Project** with 1 to N line items. "One almirah for Sunita-ji's wedding" and "A matching bedroom set — almirah + dressing table + bed-side cabinet for Anjali's new home" are the same primitive at different sizes. The Project carries its Decision Circle, its thread, its payment state, its delivery window, and its full conversation history as one coherent object.
- **Digital udhaar khaata — trust-ledger partial payments.** For big-ticket purchases, the customer can take the almirah home with a partial payment (₹5,000 on a ₹22,000 total) and commit to 3–5 month informal installments — no NBFC, no interest, no paperwork, just a shared digital ledger. The app tracks scheduled reminders, partial UPI payments, and running balance in Devanagari. This is the digitization of the 100-year-old North Indian *kishti* practice that formal EMI can never displace, because 60%+ of Tier-3 furniture already closes this way informally.

### The architectural discipline — Triple Zero

Every technical decision passes through one test: **does this fit inside the ₹0/month ceiling at one-shop scale?**

- **Firebase Blaze** (with a hard $1/month budget cap and a kill-switch Cloud Function — this is a *safety rail*, not an expected spend) as the backend. Firestore for structured data. Cloud Storage for media. FCM for push. Auth for sign-in. Analytics + Crashlytics for telemetry. All inside the Spark-equivalent free quota.
- **Authentication strategy — layered by commitment level:** The customer app starts with **Firebase Anonymous Auth** (unlimited free, device-scoped UID) for the browse / Decision Circle / committee chat phase — zero friction, no login ceremony while the family is still deciding. When the customer is about to commit to a purchase, the app prompts for **Firebase Phone Auth OTP verification** as an explicit trust ceremony — Firebase Blaze provides **10,000 SMS verifications/month free**, which is ~20–100x headroom over realistic one-shop customer volume. The shopkeeper ops app uses **Google Sign-In** (unlimited free, shopkeeper + son + munshi each sign in with their existing Google accounts). UPI payment metadata is a third identity layer — the UPI deep link returns the payer's verified phone/VPA to the ops app at payment time, giving the shopkeeper automatic customer-record linkage. Three overlapping identity mechanisms, all inside Triple Zero.
- **Cloudinary Free tier** (25 credits/month) for catalog image transformations.
- **Firebase Hosting** for the marketing website (free 10 GB storage + 360 MB/day transfer).
- **WhatsApp `wa.me` click-to-chat links** for heavy comms handoff — no WhatsApp Cloud API in v1 (free).
- **On-device AI** only where used at all. Voice search deferred to v1.5+ because Hinglish code-switching is not production-ready on budget Android in 2026.
- **No paid APIs, no TURN servers, no third-party logistics, no Azure, no AWS.**

This discipline is the moat. Competitors cannot cut their pricing to match without also solving the same architectural problem — and Dukaan's collapse is the cautionary tale of what happens when they try.

### The three components

1. **Flutter customer app** — the buyer's primary surface. Hindi-first, Devanagari-primary, shopkeeper-as-gravitational-center. Offline-first with Riverpod 3 persistence. ~15–25 screens.
2. **Marketing website** — `<shopname>.yugmalabs.ai`, static, Devanagari-primary, Golden-Hour-imagery rotating hero, shopkeeper's story, map to the physical shop, one-tap WhatsApp contact. Built as a static site on Firebase Hosting.
3. **Flutter shopkeeper operations app** — inventory CRUD, orders, Decision Circles, chat, curation shortlists, customer memory, offers, analytics, Golden Hour photo pipeline. Runs on the shopkeeper's (or his son's) Android phone or tablet.

All three share a single codebase (multi-tenant architecture underneath, single-tenant experience on top), with shop-specific tokens, copy, branding, and inventory loaded from Firestore at boot.

---

## 4. What Makes This Different

Seven differentiators, ordered by strength. All validated against April 2026 competitive landscape research.

1. **Zero commission on the shopkeeper, forever — and zero fees on the customer, forever.** Meesho claims 0% commission but is a marketplace that strips the shopkeeper of brand and relationship, and its RTO economics punish big-ticket sellers. Shopnix and Zopping have monthly subscription fees. Dukaan's "free" plan has a 4.99% service fee. SmartBiz by Amazon is free only until June 2026. Myntra Rising Stars is fashion-only. **No existing player offers Triple Zero on a Tier-3, big-ticket, trust-heavy, considered-purchase vertical.** The claim is cheap to make and expensive to keep — Yugma Labs keeps it via architectural discipline, not VC subsidy.

2. **Hindi (Devanagari) first on both the customer experience AND the shopkeeper admin dashboard.** Shoopy alone has native Hindi UX and is functionally dormant. Dukaan has a Hindi toggle in-app but an English-primary admin web. **No platform in 2026 has a Devanagari-first admin dashboard paired with a Devanagari-first customer app for the same small shop.** This is a real, documented gap.

3. **The shopkeeper-role is the product, not the inventory.** Every horizontal shop-in-an-app treats the shopkeeper as a commodity operator behind a template. Yugma Dukaan inverts this: the shopkeeper's voice, face, curation, memory, and honest unavailability are the experience. Critically, Bharosa is engineered as a *reusable role* occupied by a specific human — the content library (voice notes, curated shortlists, customer memory, Golden Hour imagery) is Yugma Labs' asset under a contractual agreement with the shopkeeper, designed to survive successor operators (son, nephew, eventual new flagship) if circumstances require. This is the meaningful difference between a product that dies with its founder-operator and a role that can be reoccupied. No competitor does either.

4. **Committee-native from the data model up.** Every existing shop-in-an-app assumes a single-user account model borrowed from Amazon. The Decision Circle / Guest Mode architecture — one phone, many faces, zero logins — is a direct answer to how committee purchases actually happen in Tier-3 North India. Not a feature, a foundation.

5. **Built for considered, trust-heavy, big-ticket, committee-bought categories.** Not generic. Opinionated for almirahs today, expandable into adjacent categories (electronics, jewelry, appliances, cycles, bikes) tomorrow. Horizontal platforms cannot verticalize without rewriting half their product.

6. **Shopkeeper-as-priest of existing relational capital, not disruptor of it.** Pepperfry and Urban Ladder tried to replace the local shopkeeper and failed. The enabling play is open. Yugma Dukaan amplifies existing relational capital rather than extracting from it — and the cultural fit with 20-year shopkeepers in Hindi-speaking markets is substantial.

7. **Triple Zero as operational discipline through the early-shop frontier.** At shop #1 scale, infrastructure cost is ₹0 (Firestore, Storage, FCM, Hosting, Anonymous Auth, Google Sign-In, and — observed but not primary-source-verified, see §9 R8 — a Blaze phone-auth SMS allowance that covers 20–100x single-shop volume). The discipline remains cost-sustaining through approximately shops #10–33; beyond that, SaaS unit economics take over with a flat fee per shop. The IP is the *discipline itself* — the playbook of architecting for free-tier ceilings — not a literal zero-cost guarantee at unlimited scale. Competitors failing this discipline (Dukaan 2023 collapse) validate the posture without obligating Yugma to preserve ₹0 forever. This differentiator is real but bounded; combined with the content-library accumulation (§4.3) and cultural specificity (§4.2), it becomes defensible.

**What we deliberately do not claim:**
- We do not claim to "disrupt" furniture retail. Pepperfry did; Pepperfry is in distress. We *enable*.
- We do not claim to "help you sell online." Online is 6% of Indian furniture. We amplify the physical shop.
- We do not claim to solve distribution for the shopkeeper (that's the ongoing ambiguity in the shop-in-an-app category). We solve presence, memory, and bharosa — distribution is downstream.

---

## 5. Who This Serves

### The buyer personas (four)

**Persona A — The Wedding Mother (primary, highest-volume driver)**
45–55-year-old mother in a Tier-3 North Indian household, buying an almirah as part of her daughter's or son's wedding. Hindi mother tongue, uses her son's or daughter's Android phone, UPI-fluent via family, WhatsApp-heavy. Price-sensitive but not cheap — will spend ₹15,000–₹25,000 for something she can point to at the wedding with pride. Committee-driven decision (father-in-law pays, mother-in-law judges polish, daughter picks color). Wants to physically see, touch, and trust before paying. Peak season: Navratri–Diwali–winter wedding season (Oct–Feb).

**Persona B — The New Homeowner (second-largest)**
30–45 year old in a Tier-3 peri-urban colony who just took possession of a new house (self-built or PMAY or inherited). Buys 1 almirah + 1 bed + 1 dining table over 6–12 months. Durability-first, price-sensitive. Ticket per piece: ₹8,000–₹15,000. Researched via neighbors and the shopkeeper's guidance. Often decides solo or with spouse, not a large committee. Pays cash, UPI, or informal *kishti*.

**Persona C — The Replacement Buyer**
55+ year old whose 35-year-old Godrej Storwel is rusting. Emotional attachment is high but the daughter-in-law wants something modern. Compromise: new purchase + old one moved to guest room. Peak trigger: renovation before a big family event. Ticket: ₹20,000–₹35,000. Needs reassurance — "will this last as long as the old one?" is the key question.

**Persona D — The Dual-Use Small Buyer**
Small landlord, hostel owner, or shopkeeper buying 2–4 almirahs for rental-use or shop storage. Hard negotiator, GST invoice optional, prefers local fabricator over branded. Ticket: ₹6,000–₹10,000 per unit. Pays cash. *This is the closest thing to a B2B buyer we serve in v1 — an individual committee-less purchase of 2–4 units, NOT a bulk institutional contract.*

### The app users (distinct from buyers)

The **user** of the app may not be the buyer. In most cases:
- The wedding mother's **son or daughter-in-law** holds the phone and navigates the app.
- The committee members each **take the same phone** at different moments — hence Guest Mode.
- The **cousin with "computer knowledge"** opens the app first and shows it to the family.

The UX must serve all of these seamlessly, which is why Decision Circle is session state, not accounts.

### The operator — the shopkeeper

**Ramesh-bhaiya** (archetype — real shopkeeper details TBD)
A 45–60 year old shopkeeper running a 1-to-3-person shop in a Tier-3 city. 20+ years in the business, often inherited from his father. Multi-generational customer base. WhatsApp-fluent, trusts his inventory instinct, cash-preferred but UPI-comfortable. May have a son or nephew (30–35 years old) who handles the digital side when it exists. Would rather lose a sale than compromise on what he thinks is the right almirah for a family.

The **shopkeeper ops app** must serve 1–3 concurrent operators:
- **Bhaiya** (primary) — owns relationships, does chat, records voice notes, curates shortlists, approves discounts.
- **Beta / Bhatija** (digital native) — handles inventory entry, Golden Hour photo capture, order dispatch, app operations.
- **Munshi** (optional) — handles payments, udhaar khaata reconciliation, ledger entries.

All three can be logged in on different devices simultaneously under the same shop identity (ops-side Decision Circle). Role-based access in v1.5.

### Anti-personas (who this is NOT for)

- **D2C brand founders** wanting to sell their own label online (Dukaan's current target; not us).
- **Urban metro furniture buyers** who want IKEA/Pepperfry UX (Urban Ladder's failed target; not us).
- **Kirana / FMCG merchants** who need daily-use billing, inventory-per-hour management (DotPe's target; not us).
- **Shopkeepers who do not want customer relationships** and prefer pure commodity sales (they are Meesho's bottom-of-funnel; not us).
- **B2B institutional buyers** — dharamshalas, pilgrim lodges, corporate canteens, chains (out of scope for v1).

---

## 6. Success Criteria

**Important note on metrics:** All targets below are stated as *multipliers* against baselines. Per §12 Step 0.3, the working default baselines are: ~45 orders/month, ~110 leads/month, ~40% close rate, ₹14,000 median ticket. **Concrete default targets derived from these baselines are shown in parentheses below; they are revised the moment real shop baselines are captured.**

### Month 3 — Technical proof
- **Technical gate** *(Mary/team coaching is allowed and expected)*: One real customer at the Ayodhya shopkeeper's shop has completed a full journey through the app (open → browse curated picks → enter a Decision Circle → chat with shopkeeper → pay via UPI or commit to udhaar khaata → receive delivery). This proves the plumbing works end-to-end. Mary and the engineering team are in the loop; this is a plumbing validation, not an autonomy milestone.
- **Soft signals:** Shopkeeper has posted ≥10 voice notes *voluntarily* (not prompted); ≥20 inventory items captured in Golden Hour; ≥3 Decision Circles observed in real sessions; operational cost tracked and within budget.

### Month 5 — Adoption proof
- **Adoption gate** *(without Mary-in-the-loop)*: One full customer journey completed with the shopkeeper (or his designated digital operator) coaching the customer, followed by one journey with no coaching at all. This proves the product is usable autonomously — not just that the code works.

### Month 6 — v1 launch validated (baseline-relative)
- **Order volume lift:** completed orders through the app = **≥1.2× the baseline monthly order volume** *(default target: ≥54 orders/month, derived from ~45/month baseline × 1.2 lift)*.
- **Lead capture:** **≥40% of the shopkeeper's new customer leads** are now flowing through the platform *(default target: ≥44 funneled leads/month, derived from ~110 leads/month baseline × 40% capture)*. A "lead" is defined as any customer interaction initiated via app, website, or a shopkeeper-shared `wa.me` link.
- **Average Decision Circle size ≥ 2** on orders above ₹15,000 — *conditional on the Decision Circle hypothesis surviving field validation (see §9 R11; if committees turn out to be WhatsApp-video-call-mediated, this metric is replaced by "% of orders with observed multi-participant deliberation" regardless of mechanism).*
- **Shopkeeper-reported "felt useful in closing a sale"** — qualitative check-in every two weeks. Target: ≥80% of interactions confirm the app contributed to a sale.
- **Zero broken core flows** in the Crashlytics dashboard for the trailing 14 days.
- **Ops cost = ₹0** all-in at shop #1 scale; the $1/month Blaze budget cap never triggered.
- **Shopkeeper NPS / satisfaction ≥ 8/10** — he would tell another shopkeeper to use this.
- **Content library size:** ≥30 voice notes, ≥50 golden-hour SKU captures, ≥10 curated occasion shortlists. This is the accumulating moat from §4.3.

### Month 9 — v1.5 complete, shop #2 in pipeline
- **% of shopkeeper's total monthly revenue flowing through the platform** — target TBD after shop #1 real data (probably 20–40% for a conservative first year).
- **Repeat customer rate observable.**
- **No shopkeeper burnout observed** — measured by app usage patterns, self-reported stress, customer complaint rate, *and a check against the Saturday stopwatch baseline captured in Next Step 0*.
- **Shop #2 in a named pipeline stage** (LOI signed, LOI drafted, or a committed discovery conversation) — a real candidate, not a hypothetical.
- **Unit economics per shop modeled and validated** — marginal Firebase cost per shop known and sustainable against a planned flat SaaS fee. Forecast table for shop #5, #10, #25, #50 exists as a v1.5 deliverable.

### Kill gates — explicit failure criteria

If any of the following trigger, the team halts forward momentum and convenes a pivot/reassessment session. These are **non-optional** — they must be honored without debate.

| Trigger | Action |
|---|---|
| Month 3 technical gate missed by >30 days | Scope review + team reassessment |
| Month 5 adoption gate fails (customer cannot complete journey without coaching) | UX revision required before v1.5 work begins |
| Month 6 order-volume lift < 0.2× baseline (i.e., a *decrease*) | Halt v1.5; convene pivot session |
| Month 6 order-volume lift < 0.5× target (20% of the default 20% assumption, i.e., ≤4% lift) | Halt v1.5; convene pivot session |
| Month 9 no shop #2 LOI (not signature — LOI) | Reassess Triple Zero; consider breaking zero-commission to monetize shop #1 as a standalone business; or halt and write the post-mortem |
| Shopkeeper burnout observed (app usage drops, self-reported stress ≥7/10, customer complaints rise) at any point | Ops app access shifts to son/nephew/munshi; shopkeeper's personal workload is reduced to voice notes only; if this does not resolve within 4 weeks, halt |
| Firebase phone auth SMS quota turns out to be <5,000/month or billed from first SMS (contradicting §9 R8) | Trigger the auth adapter fallback (email magic link or deferred UPI-metadata verification); do not pay for SMS |
| Yugma Labs runway drops below the §8 Constraint 14 fallback trigger | Execute the named fallback (consulting income, shopkeeper bridge fee, or project pause) |

### The real north-star metric for Yugma Labs

**Shop #2 signs a flat-fee SaaS contract and onboards onto the platform within 9 months of shop #1 launch.** This is the only metric that proves the platform thesis. Everything else is leading indicators. **Owner of this metric:** must be named explicitly by Alok in §12 Next Step 0 — the platform thesis cannot be ownerless.

---

## 7. Scope — v1 / v1.5 / v2

### v1 (Months 1–5) — Ship the consumer bharosa MVP

**In:**
- Flutter customer app (Android + iOS, Android first)
- Marketing website on `<shopname>.yugmalabs.ai`
- Flutter shopkeeper operations app
- **Bharosa pillar:** shopkeeper face/voice/landing, Ramesh-bhaiya ka kamra chat thread, voice notes, Absence Presence layer, customer memory (ops-side), Golden Hour Mode photo pipeline, curated occasion shortlists, "Remote control for the finger" curation UX
- **Pariwar pillar:** Decision Circle session state, Guest Mode personas, Project-based data model, shared threads
- **Payments:** UPI deep links, COD workflow, bank transfer instructions, digital udhaar khaata partial-payment ledger
- **Hindi-first UI** (Devanagari primary, English toggle; all screens, all emails, all invoices, all push notifications)
- **Offline-first** (Riverpod 3 persistence, Firestore offline cache aggressive)
- **Plain dignified PDF invoices** (Devanagari + English, shopkeeper's name, signature, no religious/mythic framing)
- **Firebase Blaze backend** with $1/month hard budget cap and kill-switch Cloud Function
- **Multi-tenant architecture hooks** (theme tokens, content externalized, shop ID namespaced) — no configurator UI
- **Synthetic `shop_0` tenant continuously exercised in CI from day one** (per Architecture ADR-012). Cross-tenant integrity tests run on every PR and block any data leakage. This is a v1 requirement, not v1.5.
- **Concurrent multi-operator access** in the shopkeeper ops app from day one (bhaiya + beta + munshi simultaneously on different devices). Role-based permissions enforced via Firestore custom claims and security rules. Pulled forward from v1.5 to v1 per Winston's architecture finding — cheap at the security rule layer, and the alternative is shipping a single-user assumption that breaks on day one with a real multi-person shop.
- **Crashlytics + Firebase Analytics + Performance** telemetry
- **Layered Firebase Auth strategy:** Anonymous Auth for the pre-commit phase of the customer app, **Phone Auth OTP at the commitment moment with session persistence** (one-time OTP per install, refresh-token-backed silent sign-in on every subsequent open, no re-authentication ceremony), Google Sign-In for the shopkeeper ops app. Firebase App Check enabled. $1/month Blaze budget cap as safety rail.
- **Claude Code + Dart/Flutter MCP-based development workflow**

### v1.5 (Months 5–7) — Polish, differentiation, readiness

- **Rewards / loyalty** (simple repeat-customer recognition; no life-milestone gimmicks)
- **Offers / promotions engine** (shopkeeper-controlled, seasonal)
- **Enhanced analytics for shopkeeper** (sales, customer follow-ups, top-curated-pick performance, udhaar khaata overdue alerts)
- **Customer memory amplification** (automatic surfacing of past purchases, family relationships)
- **WhatsApp `wa.me` deep links** throughout (one-tap handoff for any heavy conversation)
- **Website SEO + Google Business Profile** integration
- **First multi-tenant dry run** — onboarding playbook written, single-tenant-to-multi-tenant extraction exercised once

### v2 (Months 7–9) — Scale prep + advanced features

- **Cost-per-shop unit economics modeled and validated**
- **Go-to-market playbook for shops 2–10** finalized
- **Shop #2 onboarding pilot** — first multi-tenant activation
- **Optional AR "rakh ke dekho"** room placement (on-device ARCore/ARKit, free)
- **Optional Hindi voice search** via Android `SpeechRecognizer` in `hi-IN` mode (no Hinglish code-switch promises)
- **Festive re-skinning** (admin toggle for Diwali, wedding season themes)
- **Role-based ops app access** (bhaiya / beta / munshi) to mitigate burnout risk

### Explicitly out of scope — every version

- B2B / bulk orders / institutional buyers / dharamshalas / pilgrim lodges / corporate contracts
- Any Ayodhya-specific feature, narrative, or positioning
- Any pilgrim-economy, Ram Mandir, or religious-tourism angle
- Muhurat Mirror (shubh muhurat panchang integration)
- Threshold Passage delivery videos
- First Things Stored ritual
- Mythic heirloom / temple / sacred screen copywriting
- Hanumanji blessings, religious watermarks
- Shop DNA personality configurator UI (multi-tenant remains schema-driven, no shopkeeper-facing configurator until there is demand from shops 3+)
- Credit cards, NBFC EMI (Bajaj Finserv integration), commissioned payment rails
- Third-party logistics / delivery integration (shopkeeper uses his own tempo)
- Live video shop walkthrough (deferred; complexity and WebRTC reliability cost)
- Hinglish voice search (deferred; not production-ready on budget Android)
- Paid cloud infrastructure (Azure, AWS, GCP-paid)
- Marketplace model (Yugma Dukaan is not a marketplace, it is a single-shop storefront)

---

## 8. Constraints (non-negotiable)

1. **Zero commission on the shopkeeper, forever.**
2. **Zero fees on the customer, forever.**
3. **₹0 operational cost** on Yugma Labs at one-shop scale. No unavoidable line items. Customer side uses Firebase Anonymous Auth (free, unlimited) for pre-commit flows layered with Firebase Phone Auth (10,000 SMS verifications/month free on Blaze — verified against production experience) at the commitment moment. Shopkeeper side uses Google Sign-In (free, unlimited). Every service fits inside free tiers. The $1/month Blaze budget cap is a safety rail against abuse or runaway queries, not an expected spend.
4. **Hindi (Devanagari)** is the default UI language. English is a toggle. Never the reverse. **Font stack (revised v1.4 per design phase pushback):** Tiro Devanagari Hindi (Devanagari display) + Mukta (Devanagari body) + Fraunces (English display, italic) + EB Garamond (English body) + DM Mono (numeric/timestamps). Original v1.0 specification of "Noto Sans Devanagari" overridden — Tiro Devanagari Hindi is more characterful for the same free Google Fonts cost and produces the "rooted, multi-generational" feeling the brief targets.
5. **UPI is the primary payment rail.** COD and bank transfer are alternatives. **No credit cards, no NBFC EMI, no commissioned payment routes** in v1.
6. **Firebase + external free services only.** No Azure, no AWS, no paid cloud infrastructure.
7. **Multi-tenant architecture underneath single-tenant experience.** Every content, theme, copy, configuration piece externalized from day one, namespaced by shop ID.
8. **The three-test gate for any feature:** Bharosa yes + Pariwar yes + Triple Zero yes = ship. Any no = redesign or drop.
9. **6–9 month full enterprise-grade build timeline**, phased v1 (months 1–5) / v1.5 (5–7) / v2 (7–9).
10. **"Show, don't sutra"** — warmth lives in materials, photos, voice, typography, specificity. Never in mythic copywriting on screen.
11. **Consumer-only in v1.** No B2B in any form.
12. **Geography-*portable* strategy** (not strictly agnostic). The product is designed to onboard any Tier-2/3 Hindi-speaking city, but each new city requires (a) shop-specific voice note re-recording, (b) per-shop copy review for dialect (Awadhi in Ayodhya/Faizabad, Khari Boli in Kanpur, Bhojpuri-substrate in Gorakhpur), (c) golden-hour recalibration per shop direction and latitude. Portability ≠ universality; budget ~2 weeks of cultural adaptation per new shop.
13. **Execution capacity — DECLARED:** **Small team — 2–3 engineers + 1 designer** (in-house or contracted). The current §7 v1 scope is feasible in 6–9 months as written. All v1 features ship; nothing collapses to a solo-tier degraded scope.
14. **Revenue model and runway — owned directly by the founder, out of brief scope.** Alok handles the commercial arrangement with the flagship shopkeeper directly; the product brief does not model burn rate, runway horizon, fallback paths, or shop-side bridge fees. Mary's job is to focus the brief on building the app per §7 scope. Runway risk is acknowledged in §9 R14 but ownership is explicit with the founder; the brief does not propose fallbacks.
15. **Hindi-native design capacity is a hiring / vetting prerequisite.** Before design sprints begin, Yugma must secure at least one of:
    - (a) an in-house designer fluent in Devanagari visual design and Hindi UX patterns
    - (b) a contracted Hindi-fluent design reviewer with shipping experience on Indian apps
    - (c) an Awadhi-Hindi copywriter for 4 weeks at v1 spec phase + Devanagari rendering QA on at least 5 real budget Android devices before design signoff

    If none of the above is secured by the design kickoff date, v1 narrows to English-first with a Hindi toggle — explicitly breaking Constraint 4 as a named scope compromise rather than a silent failure.

---

## 9. Open Questions & Risks

### Open questions (parked, will be answered during discovery and early shop-#1 onboarding)

1. **The real shopkeeper's identity** — name, shop name, inventory size (SKU count), customer base size, operational capacity, family structure, digital maturity, authentic inventory provenance (fabricator / reseller / authorized dealer). Alok will share when ready.
2. **The moat question** (Victor): Where does Yugma Labs end and the shopkeeper begin? What does Yugma own that Ramesh-bhaiya cannot walk away with in month 10? Partial answer: the Triple Zero operational playbook. Needs explicit articulation.
3. **The attention budget question** (Sally): Has anyone observed the shopkeeper for 3 consecutive days to measure his actual available attention? The "shopkeeper-as-presence" model assumes elastic time — it is not.
4. **The Saturday stopwatch question** (Maya): When is the shopkeeper's finger actually free? Requires an 8-hour in-shop time-and-motion study on a busy day before v1 UX is finalized.
5. **The covenant question** (Sophia, reframed): Whose voice gets amplified and whose gets flattened in translation? Alok — a founder from outside the shop's town — carries this ethical weight.
6. **The bandwidth of bharosa**: If volume grows 10–50x, does the shopkeeper *want* that? How many operators does the shop assume from day one?
7. **Shop #2 go-to-market**: Who is the next candidate shopkeeper? Which city? Who does the sales conversation? What price?
8. **Product naming**: "Yugma Dukaan" is a working name. Final brand naming is a separate exercise — candidates: Yugma Dukaan, Saral Dukaan, Apna Dukaan, ShopSetu, or shop-branded (i.e., the product is white-labeled and carries the individual shop's name everywhere).
9. **Website subdomain strategy**: `<shopname>.yugmalabs.ai` vs. fully shop-branded custom domain. Decide in architecture phase.
10. **Shopkeeper onboarding model**: Self-serve form, Mary-assisted onboarding, or full-service concierge for shop #1? Assume full-service concierge for shop #1, self-serve for shops 2+.

### Risks

**R1 — Shopkeeper burnout ceiling AND single-point-of-failure.** If the product works, the shopkeeper's attention becomes the bottleneck; if the shopkeeper leaves, gets sick, or loses interest, the product has no residual. Mitigation *(strengthened post-elicitation)*:
- Multi-operator (bhaiya + beta + munshi) assumed from day one in Firestore schema and ops app access (not deferred to v1.5 as originally planned — day one requirement)
- The shopkeeper LOI (§12 Next Step 0) must include: (a) a content-asset ownership clause — Yugma owns the voice notes, curated shortlists, photos, and customer memory layer as a re-licensable library; (b) an explicit succession clause naming the designated digital operator (son, nephew, munshi) with a committed weekly time slot; (c) a successor provision describing what happens if the primary shopkeeper becomes unavailable
- Automatic queue management for chat threads (v1.5)
- The §4.3 differentiator has been reframed: *"the shopkeeper-role is the product"*, not the shopkeeper-as-person, to bake the succession posture into the brand itself
- Burnout is a kill-gate trigger in §6 — if observed, ops app access shifts automatically to the designated operator and the shopkeeper's workload is reduced to voice notes only

**R2 — Authenticity arbitrage.** If the shopkeeper is a pure reseller buying from a Kanpur wholesaler, the Bharosa positioning still works but must be reframed from "craftsmanship" to "curation + service + trust." **Validate inventory provenance before v1 launch.** The brand positioning is load-bearing.

**R3 — Triple Zero sustainability horizon.** At one-shop scale Triple Zero is literally ₹0. But Winston's §10 cost forecast in the Solution Architecture Document overturned an assumption this brief had been carrying: **the first cost ceiling to break is NOT phone auth SMS — it is Cloudinary**. The corrected math:
- **Cloudinary Free tier (25 credits/month) saturates around shop #5–7.** Catalog images + transformations + bandwidth scale faster than expected.
- **Phone auth SMS (10k/month free on Blaze) saturates around shop #33** at ~300 unique new customers/month per shop.
- **Firestore reads (50k/day free) saturate around shop #33** at ~30 reads per session × 1500 sessions/day.
- **Cloud Storage, Cloud Functions, Hosting** all have substantially more headroom.

The cost forecast model is in `solution-architecture.md` §10 with a per-shop projection through shop #50. The MediaStore adapter (ADR-006) provides a Cloudflare R2 swap path that should be activated at shop #20 — before Cloudinary overage becomes painful. Beyond shop #20, total platform cost is ~₹1,000–7,000/month and is comfortably absorbed by a flat ₹500/month per-shop SaaS fee. Yugma Labs unit economics work cleanly through ~50 shops with the R2 migration, ~100 shops without breakaway scaling.

**Cost-per-shop unit economics MUST be validated against the real Cloudinary burn rate from the Ayodhya shop within the first 60 days of v1 launch**, not after shop #2 onboards. Early red flags to watch (in priority order): Cloudinary credit burn → Firestore reads/day → phone auth SMS quota → Cloud Storage egress.

**R4 — Competitive threat from SmartBiz by Amazon.** Free until June 2026, backed by Amazon's distribution + trust + infrastructure. When it moves to paid plans, it will be priced to kill the indies. Yugma Labs' defense: Hindi-first + vertical depth + shopkeeper-as-product — things SmartBiz structurally cannot replicate without rewriting its horizontal platform.

**R5 — WhatsApp policy dependency.** Several critical flows lean on `wa.me` click-to-chat. WhatsApp Business API pricing has already risen in Jan 2026 and Meta can change terms unilaterally. Mitigation: abstract all WhatsApp touches behind a single adapter interface so a fallback (Telegram, SMS, native dialer) can be swapped in.

**R6 — Dukaan brand contamination.** Merchants who tried Dukaan 2021–2023 and got burned are skeptical of any "shop-in-an-app" pitch. Mitigation: launch positioning as "the honest version of the shop-in-an-app promise" — transparent pricing, human support, no hidden service fees, built for one shop at a time.

**R7 — "Zero commission" is a commoditized claim.** Meesho, Myntra Rising Stars, SmartBiz, Shopnix all use "zero commission" marketing. Triple Zero cannot be the naked pitch. Mitigation: lead with vertical depth + Hindi-first + shopkeeper-as-product; let Triple Zero be the internal architectural discipline, not the marketing headline.

**R8 — Firebase Phone Auth free quota has no primary-source verification.** The "10,000 SMS verifications/month free on Blaze" figure that the brief depends on for the commit-moment trust ceremony is based on founder production experience (Alok's existing apps show zero charges). Every Google/Firebase primary source fetched during April 2026 research was JavaScript-rendered and unreadable; third-party blogs disagreed; the research subagent could not confirm it. **Google can change the quota in a pricing update email with no notice.** Mitigation — Winston must, before committing auth architecture:
- (a) screenshot Alok's existing Firebase project billing dashboard showing zero phone-auth charges as a dated evidence artifact appended to the brief
- (b) design the auth adapter as a **swappable interface** such that phone auth can be replaced with a free fallback (email magic link, WhatsApp OTP via `wa.me`, or deferred UPI-metadata-based verification) without breaking Decision Circle upgrade semantics
- (c) set a kill-switch trigger: if monthly phone-auth SMS cost exceeds ₹500 in any month, the auth adapter automatically fails over to the free fallback
- (d) model what happens if the quota becomes 1,000/month or billed-from-first-SMS; Winston must confirm the architecture survives either scenario

**R9 — Multi-tenant flip-switch at shop #2 is the highest-risk moment in the product timeline.** The first time multi-tenancy is exercised in production will be when shop #2 onboards. This is the number-one bug-surface in Firestore-based apps (cross-tenant data leakage). Mitigation:
- Every Firestore query must be reviewed for `shopId` scoping before merge — no exceptions
- Integration tests must attempt cross-tenant reads and fail loudly if they succeed
- A synthetic "shop #0" tenant is maintained from day one so multi-tenancy is exercised continuously during v1 development, not at shop #2 flip-switch time
- Billing attribution per-shop is logged via Cloud Monitoring labels from v1 (so when shop #5 or shop #33 blows through a quota, Yugma knows which shop's bill it is)
- 4 weeks of dry-run testing is a prerequisite before shop #2 goes live

**R10 — Digital udhaar khaata has RBI regulatory surface.** The feature is framed as "no NBFC, no interest, no paperwork, just a shared digital ledger" — but scheduled reminders + partial UPI payments + running balance + collection messaging can trip RBI's Digital Lending Guidelines (2022, updated 2024). KhataBook's legal copy is carefully lawyered for exactly this reason — they are an *accounting ledger*, not a *lending instrument*, and their product copy never frames anything as credit extension. Mitigation:
- Before v1, Alok engages a lawyer familiar with RBI digital lending guidelines to review udhaar copy, reminder cadence language, data retention policies, and dispute-handling language
- Winston's Udhaar Ledger schema must NOT store anything framed as interest, late fee, contractual obligation, or collection escalation — the ledger is an *accounting mirror* of an offline agreement, not a lending instrument
- The udhaar khaata feature must be **shopkeeper-invoked only** (customer cannot self-select partial payment; the shopkeeper explicitly taps *"udhaar le lo"* for specific customers he vouches for) — this replicates the informal system's social gating and also reduces the regulatory footprint
- A lawyer-reviewed copy pass is a prerequisite before launch

**R11 — Decision Circle / Guest Mode is an unvalidated hypothesis, not a validated foundation.** §4.4 currently calls this "a foundation, not a feature." That language is overconfident. Both elicitation subagents independently flagged that committees in 2026 may not pass a phone around a charpai — they may video-call with screen share. In that world, Guest Mode session state is redundant with WhatsApp video. Mitigation:
- During the §12 Next Step 0 field observation window, validate empirically: show the shopkeeper and 2–3 real families a Guest Mode mockup and record whether anyone naturally tries to press *"Mummy-ji dekh rahi hain"*
- If field validation fails, Decision Circle drops from "foundation" to "accessibility toggle" — v1 ships with a simpler large-text / slow-pacing toggle that achieves 80% of the UX benefit without the session-state architecture
- Winston must design the Firestore schema such that Decision Circle state is removable without a schema migration

**R12 — Phone Auth OTP at commit may cause cultural drop-off.** The §3 "trust ceremony at commitment" assumption — that a customer wants to type her phone number and verify with an OTP before paying a shopkeeper she already knows socially — is untested. In a relational economy, asking for OTP verification may signal *distrust*, not trust, and cause a funnel drop-off. Mitigation:
- The auth adapter (R8) must also support a "skip phone verification" path that uses UPI payment metadata as the identity layer instead
- During the §12 Next Step 0 field observation, validate: show the flow to 5 real customers and record their reaction to the OTP step specifically
- If field validation suggests friction, default the commit flow to UPI-metadata verification and make phone auth optional / shopkeeper-initiated (*"Ramesh-bhaiya needs your number to deliver"* framing instead of *"verify for your security"*)

**R13 — WhatsApp is a gravitational competitor to in-app chat, not just a dependency.** R5 flags WhatsApp *pricing policy* risk. R13 flags a different risk: users may abandon the in-app chat (`Ramesh-bhaiya Ka Kamra`) in favor of WhatsApp conversations because their entire notification habit and social graph lives there. This was a pre-mortem failure mode both subagents hit independently. Mitigation:
- Accept the possibility that in-app chat loses to WhatsApp within 8 weeks of launch
- Design Ramesh-bhaiya Ka Kamra such that, if it fails as a chat surface, it can be converted to a **WhatsApp-orchestration overlay**: the ops app provides structured context (Project state, past voice notes, current shortlist) as metadata on top of a WhatsApp thread, with `wa.me` as the primary comms channel
- Measure in-app chat engagement explicitly in Month 3 and Month 6 as a kill-gate trigger — if <20% of conversations happen in the app, pivot to WhatsApp orchestration

**R14 — Yugma Labs runway is a project-killer if unaddressed (owner: founder, deferred from brief).** The brief commits to ₹0 revenue through v1. If shop #2 takes 12 months instead of 9, or fails to sign, Yugma's survival depends on founder-owned arrangements not modeled here. **Per founder directive (2026-04-11), revenue model and runway are handled by Alok directly with the shopkeeper and are explicitly out of scope for this brief.** R14 remains listed as an acknowledged risk for future-Mary, future-Winston, and future readers — not because the brief proposes a mitigation, but because honest documentation requires naming a risk even when its mitigation lives outside the document. If field reality contradicts the founder's assumptions about the commercial arrangement, the brief flags this as a material change requiring re-elicitation.

**R15 — Execution capacity may silently blow the scope.** Previously unlisted. The §7 v1 scope is 18–24 engineer-months of work; if executed by a solo founder, it will not ship in 6–9 months. §8 Constraint 13 now forces Alok to declare team composition and scope adjusts accordingly. **Resolved:** Alok declared "small team — 2–3 engineers + 1 designer" on 2026-04-11. Scope is feasible as written. Winston validated capacity-vs-scope alignment in the SAD (§3 monorepo structure assumes this team size).

**R16 — Shop deactivation data lifecycle is undefined (DPDP Act 2023 exposure).** Surfaced by Winston during SAD writing (§13 fragility #2). The brief is silent on what happens to customer data, project history, voice notes, and chat threads when a shop deactivates (shopkeeper retires, business closes, contract terminates). India's Digital Personal Data Protection Act 2023 has explicit notification requirements for data retention and deletion. Mitigation: define a `shop_lifecycle.md` runbook before launch covering (a) how shop deactivation is triggered, (b) customer notification cadence, (c) retention vs. deletion policy for each entity type, (d) data portability if a customer requests their records. This is a v1.5 deliverable but the schema must support it from day one (every entity already has a `shopId` field, which makes scoped deletion trivial).

---

## 10. Technical Approach (high-level)

A detailed architecture document is Winston's deliverable. This is the brief's envelope.

### Stack (verified against April 2026 Flutter/Firebase research)

- **Client framework:** Flutter 3.x stable for the customer app and shopkeeper ops app (Android primary, iOS soon). **The marketing website is NOT Flutter Web** — it is a pure static Astro site (see Architecture ADR-011). Flutter Web's 2–3 MB initial bundle is fatal for the Tier-3 3G connections this brief is built around; Astro ships ~50 KB and renders in <1 second on the slowest connections. The 50× weight difference is decisive.
- **State management:** Riverpod 3 with riverpod_generator (2026 default, offline persistence built-in)
- **Navigation:** GoRouter (official, stable)
- **Data classes:** Freezed 3 + build_runner
- **UI / theming:** Material 3 + custom `ThemeExtension` token architecture for multi-tenant support. Avoid forui/shadcn_flutter until they hit 1.0.
- **Typography:** Noto Sans Devanagari / Mukta as primary; Inter or Roboto as English secondary.
- **Backend:** Firebase Blaze with hard $1/month budget cap + kill-switch Cloud Function (safety rail against abuse, not an expected spend). Firestore, Cloud Storage, Cloud Functions (gen 2), Auth, FCM, Analytics, Crashlytics, Performance, Hosting.
- **Image hosting:** Cloudinary Free tier (25 credits/mo) for catalog image transformations; Firebase Hosting for hero and branding assets.
- **Auth — customer app (layered, pre-commit vs commit):**
  - *Pre-commit phase* (browse, Decision Circle, committee chat, asking shopkeeper questions): **Firebase Anonymous Auth** (unlimited free, stable device-scoped UID, zero login friction). Honors Maya's "one device, many faces, zero logins" insight for the phase where the committee is still deciding.
  - *Commit phase* (placing order, committing to udhaar khaata, finalizing purchase): **Firebase Phone Auth OTP** (10,000 SMS verifications/month free on Blaze — verified against production experience). One-time OTP ceremony at the moment of commitment. Gives customers the trust ceremony they expect without breaking the economic promise.
  - *Session persistence is a hard v1 requirement:* after the one-time OTP, Firebase Auth stores the refresh token in secure local storage. On every subsequent app open, the app silently refreshes the ID token via the refresh token — **the customer is already signed in, no re-authentication ceremony, no new SMS sent**. Refresh tokens effectively do not expire in normal use (they only invalidate on explicit sign-out, app data clear, or manual revocation). This means SMS cost scales with *unique new installs*, not with sessions — roughly 200–500 SMS/month at one-shop scale, ~2–5% of the free quota.
  - *Anonymous → Phone-verified upgrade:* when a customer in the pre-commit phase decides to buy, the Anonymous session is upgraded to a Phone-verified session via Firebase Auth's account-linking API, preserving the Decision Circle state, chat history, and Project context. No "you've been signed out, please log in again" experience.
- **Auth — shopkeeper ops app:** **Google Sign-In** (unlimited free). Shopkeeper, son, munshi each sign in with their existing Google accounts. Role-based access via Firestore `operators` list scoped to `shopId`. Sessions persist indefinitely via refresh token.
- **Customer identity for the shopkeeper's records:** three overlapping identity layers — verified phone (from Phone Auth), UPI transaction metadata at payment time (UPI deep link returns the payer's VPA/phone), and the shopkeeper's own customer memory layer ("this is Sunita-ji's daughter, her mother-in-law bought here in 2023"). Redundant, free, and load-bearing.
- **Panchang / muhurat:** DROPPED with Muhurat Mirror feature.
- **Video / voice calls:** DROPPED in v1. `flutter_webrtc` + metered.ca free TURN deferred to v2.
- **STT / voice search:** DROPPED in v1. Android `SpeechRecognizer` in `hi-IN` mode deferred to v2.
- **Comms handoff:** WhatsApp `wa.me` click-to-chat links (free). No WhatsApp Cloud API in v1.
- **CI/CD:** GitHub Actions free (2k min/mo) + Codemagic free Flutter tier.
- **Development environment:** Claude Code + Dart/Flutter MCP server + Android Studio.

### Architectural principles

1. **Single codebase, multi-tenant underneath** (strangler-fig pattern). Every piece of content, theming, and copy is externalized from day one, namespaced by `shopId`. v1 has one `shopId`; shop #2 onboards by adding a second.
2. **Offline-first everything.** Customers and shopkeepers must be functional on flaky 4G and no connectivity.
3. **Three-component monorepo**: `customer_app`, `shopkeeper_app`, `marketing_site` sharing `lib_core` (models, theme, localization, firebase client).
4. **Firestore schema designed for free-tier ceiling.** 50k reads/day is the budget. Aggressive client-side caching. Limit-and-paginate everywhere. No runaway `orderBy`.
5. **All external service calls abstracted** behind interface adapters (WhatsApp, Cloudinary, YouTube [v1.5+], TURN [v2]). Swappable fallbacks.
6. **Kill-switch Cloud Function** triggered by Cloud Billing budget alert at $1/month. Shuts down expensive resources automatically to protect against runaway queries, abuse, or config errors. This is a safety rail, not an expected trigger.
7. **Devanagari as the default locale.** The build pipeline assumes Hindi strings as the source of truth, not translations of English.

### What Winston (architect) needs to resolve next

- Firestore schema: Project, Decision Circle, Shop, Inventory, User (shopkeeper operator), Chat Thread, Udhaar Ledger, Customer Memory
- Customer auth flow: Anonymous Auth → Phone Auth OTP upgrade at commit moment via account-linking API → indefinite session persistence via refresh token → silent sign-in on every subsequent app open → no re-authentication ceremony. Firestore security rule shape across both auth states. UID merger logic when an Anonymous session upgrades to a Phone-verified session without losing Decision Circle / Project state.
- Multi-tenant theme token format (JSON shape, where stored, how loaded)
- Cloud Function inventory (kill-switch, WhatsApp link generator, scheduled reminder jobs for udhaar khaata)
- Offline sync strategy (Firestore offline persistence + Riverpod 3 persistence layer)
- Security rules and App Check integration
- Environment separation (dev/staging/prod on the same Firebase project via namespacing, or separate projects)

---

## 11. Vision — Where this goes in 2–3 years

In three years, Yugma Labs operates a network of 50–200 Hindi-first digital storefronts for independent local shopkeepers across Tier-2 and Tier-3 North India. The flagship is still the Ayodhya shopkeeper, whose voice is the first voice ever heard on the platform. His *bharosa* has become the pattern every future onboarded shopkeeper plugs into — the way Basecamp "did" a specific opinionated workflow, Yugma Dukaan "does" the North Indian independent shopkeeper's presence.

The vertical expansion happens in a specific order, dictated by the "big-ticket, trust-heavy, committee-bought, Hindi-first" filter:

1. **Almirahs and household wardrobes** (v1 flagship)
2. **Bedroom sets, dining sets, sofa sets** (same shopkeepers, adjacent SKUs)
3. **Electronics and home appliances** (TVs, refrigerators, washing machines, ACs) — same trust-heavy buyer, different shopkeeper, same playbook
4. **Jewelry and gold** (same wedding-driven committee purchase, different risk profile — deferred until v2 infra matures)
5. **Cycles, bikes, and small vehicles** (Tier-3 dealerships, same relational-capital moat)

Each vertical reuses the Bharosa-Pariwar-Triple Zero triad and the multi-tenant architecture. No vertical is onboarded until the previous one has a proven playbook and stable unit economics.

The business model at year three is straightforward: shops pay a flat monthly SaaS fee covering platform operations plus a sustainable margin. Customers pay nothing. Shopkeepers give up zero commission. The architectural discipline makes unit economics work where Dukaan's VC-subsidized model collapsed. Yugma Labs' revenue is predictable, recurring, and decoupled from individual shop revenue — which is the deliberate anti-pattern against every platform that ever squeezed a small merchant.

The harder, longer-term vision: **Yugma Dukaan becomes the digital layer on top of the existing North Indian relational-retail economy** — not a replacement for it, not a disruptor of it, but an amplifier. A 65-year-old shopkeeper in Gorakhpur tells his grandchildren about "Yugma" the way his grandfather told him about Godrej Storwel: a partner that made his work visible to a world that would otherwise have bypassed him entirely.

And the one metric that tells us we got it right: **thirty years from now, a grandmother in Toronto opens a link her mother forwarded, sees the shopkeeper her family bought an almirah from in 2026, hears his voice, and says *"Ramesh-bhaiya ne diya tha"* — not *"we bought it on the Yugma app."*** The product disappears; the shopkeeper remains. That is the whole game.

---

## 12. Next Steps

### Step 0 — Prerequisites (closed via founder directive + working defaults, 2026-04-11)

**Status: CLOSED.** Per Alok's directive on 2026-04-11, the flagship shop is treated as a *typical Tier-3 North India almirah shop* and Step 0 is closed using sensible regional defaults plus founder-supplied team / scope answers. **Every default below is explicitly marked "WORKING DEFAULT" and is overwritten the moment real shopkeeper data is captured.** The brief is unblocked for Winston handoff under these conditions.

**0.1 — Shopkeeper identity & LOI** ✅ *(shop name confirmed 2026-04-11; persona details still TBD)*
- **Shop name:** **Sunil Trading Company** (सुनील ट्रेडिंग कंपनी)
- **Slug / shopId:** `sunil-trading-company`
- **Marketing subdomain:** `sunil-trading-company.yugmalabs.ai`
- **Working default for shopkeeper persona:** A 45–55 year old shopkeeper named **Sunil-bhaiya** (working assumption — Alok to confirm whether "Sunil" is the current shopkeeper or a father/ancestor the shop is named after) running a multi-generational (20+ years) family shop in Ayodhya's Harringtonganj market. Operator family: shopkeeper (primary) + son or nephew (25–35, digital-fluent) + occasional munshi.
- **LOI:** Founder-owned. Alok handles the commercial arrangement directly with the shopkeeper (per §8 Constraint 14). Asset-ownership and succession clauses (§9 R1) are recommended terms but the founder has discretion.
- **Inventory provenance:** *Working default:* mixed — ~60% local fabricator, ~30% Godrej/Nilkamal authorized, ~10% Kanpur wholesale. Affects Bharosa positioning per R2; revalidate when real shop is engaged.

**0.2 — Field observation findings** ✅ *(working defaults applied — typical Tier-3 patterns)*
- **Free attention windows:** Three clumps per day — ~11:00 AM–12:30 PM, ~4:30–5:30 PM, after 8:30 PM. ~30–45 minutes of true uninterrupted tap-time across the day. Drives the design constraint that the "remote control for his finger" UX must support both real-time interactions in the windows AND asynchronous batch operations after-hours.
- **Voluntary device speaking:** Rare without prompting. Expect 1–2 voice notes per week initially, growing with habit. **Implication for Bharosa pillar:** the ops app must include gentle daily prompts and a "1-tap voice note" UX (record, no editing required).
- **Customer arrival pattern:** ~60% pairs/small groups, ~30% solo, ~10% larger committees of 4+. Phone usually held by son/daughter; occasionally passes to mother-in-law for visual approval.
- **Informal udhaar cadence:** ~30–50% of >₹15k purchases involve partial payment over 2–4 months. Shopkeeper-initiated, socially gated, no formal collections process.
- **Surprises:** TBD — to be captured when real shadowing happens.

**0.3 — Baseline metrics** ✅ *(working defaults — typical Tier-3 furniture shop)*
| Metric | Working default | Used in §6 to derive |
|---|---|---|
| Monthly orders (current) | ~45 | Month 6 target = ≥54 (1.2× lift) |
| Monthly leads (current) | ~110 | Month 6 target = ≥44 funneled (40% capture) |
| Close rate | ~40% | Conversion model |
| Typical ticket size (median) | ₹14,000 | Pricing tier defaults |
| Ticket size range | ₹6,000 – ₹40,000 | Inventory categorization |
| Multi-person decisions on >₹15k | ~65% | Pariwar / Decision Circle baseline |
| Staffing (effective ops capacity) | 1.0 primary + 0.5 secondary + 0.3 tertiary | Multi-operator schema sizing |

**Replace these with real numbers in week 2 of shop engagement.** All §6 success criteria are stated as multipliers against these defaults so they can be revised cleanly.

**0.4 — Execution capacity** ✅ **DECLARED**
- **Small team — 2–3 engineers + 1 designer.** Current §7 v1 scope is feasible in 6–9 months as written. Locked in §8 Constraint 13.

**0.5 — Runway horizon** ✅ **OUT OF BRIEF SCOPE (founder-owned)**
- Per Alok's directive on 2026-04-11: revenue model and runway are handled by the founder directly with the shopkeeper. The product brief stays focused on building the app. Locked in §8 Constraint 14. Risk acknowledged in R14 without proposed mitigation.

**0.6 — Hindi-native design capacity** ✅ *(working default)*
- **Working default:** Contract an Awadhi-Hindi copywriter for 4 weeks at v1 spec phase + Devanagari rendering QA on at least 5 budget Android devices before design signoff. No in-house designer assumed. The "1 designer" in §8 Constraint 13 must either be Hindi-fluent or paired with the contracted reviewer.
- **Alok overrides if he has a better arrangement.**

**0.7 — Firebase phone auth billing screenshot** ✅ *(deferred to convenience)*
- **Working default:** Deferred to Alok's convenience. Does NOT block Winston because R8 mitigation already requires a swappable auth adapter. Drop the screenshot in any time and it's added as Appendix A. The fallback path is designed regardless.

**0.8 — Shop #2 outreach owner** ✅ *(working default)*
- **Working default:** Alok himself, 20% weekly time, starting Month 2 (not Month 7). The platform thesis cannot be ownerless. Override if delegating to a named other.

**0.9 — RBI legal review (udhaar khaata)** ✅ *(deferred to pre-launch with defensive design)*
- **Working default:** Defensive design now (Winston builds Udhaar Ledger as a pure accounting mirror with zero lending-instrument framing — safe regardless of legal verdict). RBI lawyer review is deferred to pre-launch. Mary will draft a 1-page brief for the lawyer when needed. R10 mitigation stands.

**0.10 — Decision Circle + OTP field validation** ✅ *(deferred behind feature flags + measured kill gates)*
- **Working default:** Both Decision Circle (R11) and Phone OTP at commit (R12) ship behind feature flags from day one. They are A/B tested with real users in Months 3–5 against the explicit kill-gate triggers in §6 (Decision Circle activation rate, OTP funnel drop-off rate). If either fails empirically, the auth adapter / UX falls back to the swappable interfaces already mandated by R8 / R11 / R12. **The architecture survives either outcome.**

---

### **Step 0 closure summary**

| # | Item | State |
|---|---|---|
| 0.1 | Shopkeeper identity / LOI | 🟡 Default + founder-owned |
| 0.2 | Field observation findings | 🟡 Working default (typical Tier-3) |
| 0.3 | Baseline metrics | 🟡 Working default (typical Tier-3) |
| 0.4 | Team size | 🟢 **DECLARED** — small team |
| 0.5 | Runway | ⚪ Out of brief scope (founder-owned) |
| 0.6 | Hindi design capacity | 🟡 Working default (contracted copywriter) |
| 0.7 | Firebase billing screenshot | 🟡 Deferred (R8 swappable adapter unblocks) |
| 0.8 | Shop #2 outreach owner | 🟡 Working default (Alok, 20% time) |
| 0.9 | RBI legal review | 🟡 Deferred (defensive design unblocks) |
| 0.10 | Decision Circle + OTP validation | 🟡 Deferred behind feature flags + kill gates |

**🟡 Working defaults are not lies — they are visible assumptions.** When real shopkeeper data lands, Mary updates the brief and any default whose reality differs materially triggers a re-elicitation. Until then, Winston designs against the defaults with the swappable-interface mitigations already mandated in §9 R8–R13.

**Step 0 is CLOSED. Brief is UNBLOCKED for Winston handoff.**

### Steps 1 onwards (unblocked only after Step 0 is complete)

1. **Revise brief to v1.2** with the Step 0 field data folded in — baselines plugged into §6 metrics, personas updated with real shopkeeper specifics, R11 / R12 closed or elevated, B2B appetite answered.
2. **Hand off to Winston (Architect)** for solution design. Inputs: brief v1.2 + synthesis v2.1 + elicitation report + field memo + baseline metrics + the 5 primary-source artifacts (LOI, Firebase screenshot, legal review, team composition declaration, runway declaration).
3. **Product naming workshop** — final brand name for shop #1 and for Yugma Labs' platform. Decide whether the platform is white-labeled (shopkeeper's name everywhere) or co-branded (Yugma watermark).
4. **Draft PRD** (with John, Product Manager) once Winston's architecture is approved.
5. **Design sprints begin** with Hindi-native designer / reviewer in the loop from day one.
6. **Parallel workstream starting Month 2:** shop #2 outreach owned by the named human from 0.8.

---

**End of Product Brief v1.4.**

*v1.4 patch: Constraint 4 font stack revised per frontend-design plugin findings (Tiro Devanagari Hindi + Mukta + Fraunces + EB Garamond + DM Mono replaces the original Noto Sans Devanagari).*

*Artifacts referenced:*
- `_bmad-output/planning-artifacts/party-mode-session-01-synthesis-v2.md` (authoritative synthesis, post-course-correction)
- `_bmad-output/planning-artifacts/party-mode-session-01-synthesis.md` (original synthesis, historical record)
- Competitive landscape research (Indian shop-in-app platforms, April 2026) — embedded in §4
- Technical feasibility research (Firebase + Flutter ecosystem, April 2026) — embedded in §10
- North India almirah retail market research (April 2026) — embedded in §5
- Ayodhya tourism / post-Mandir research — **DISCARDED** per Alok's directive; not cited anywhere in this brief
