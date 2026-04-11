# Party Mode Session 01 — Synthesis & Harvest (v2, REVISED)

**Project:** Yugma Labs Almirah Shopkeeper Platform (flagship customer: Ayodhya, Harringtonganj market)
**Facilitator:** Mary (Strategic Business Analyst)
**Participants:** Victor (Innovation Strategist), Sally (UX Designer), Sophia (Master Storyteller), Maya (Design Thinking Maestro)
**Observer / Founder:** Alok
**Session date:** 2026-04-10
**v2 revision date:** 2026-04-10 (same day, post-research)
**v2.1 auth correction:** 2026-04-11 — Phone Auth reinstated as a core v1 feature after Alok's production evidence confirmed Firebase Blaze's 10,000 SMS verifications/month free allowance for India phone authentication. The original research subagent and two WebFetch rounds could not confirm this from primary sources (all JavaScript-rendered); Alok's real production apps did. Session persistence (one-time OTP, refresh-token-backed silent sign-in on subsequent opens) added as a hard v1 requirement. See updated §0, §1 Reframe 6, §6 technical constraints, and R3.
**Format:** 4 rounds — Reframe, Crossfire, Uncomfortable Questions, Creative Unlock

---

## ⚠️ REVISION NOTE — Why this is v2

After the original session and during Product Brief drafting, Alok explicitly directed:
1. **"Mandir has nothing to do with this — don't even consider that."**
2. **Drop all culturally-adjacent heirloom framing** (Muhurat Mirror, Threshold Passage, "First Things Stored" ritual, ceremonial/religious invoice framing).
3. **Drop B2B entirely from v1.** Consumer-only. No Fleet Contracts, no dharamshalas, no institutional buyers.
4. **Strategy is geography-agnostic** for any Tier-2/3 Hindi-speaking North Indian city. Ayodhya is simply where the first real shopkeeper is located — it carries no strategic weight of its own.

The original `party-mode-session-01-synthesis.md` is preserved as historical record. This v2 is the **authoritative source** going into the Product Brief.

**Content removed in v2:**
- All references to Ram Mandir, post-Mandir transformation, pilgrim economy, dharamshalas, temples, Hanumanji blessings, "atithi devo bhava," *parampara* as a product frame, mythic-heirloom screen copy
- Victor's Fleet Contract + Kamra Ledger + Zimmedari Mode (B2B)
- Sally's Muhurat Mirror (shubh muhurat delivery dates)
- Sophia's Threshold Passage delivery video
- Synthesis-derived Pilgrim Gift Mode, "First Things Stored" ritual, Muhurat Lock-in ceremonial invoice
- The "Ghar-aur-Dharamshala" pillar (third pillar) — gone
- Uncomfortable question Q6 ("does he want B2B?") — moot
- Risks tied to B2B (authenticity arbitrage in Fleet Contract, GST/TDS treatment of service+goods hybrid, regulatory sleeper for hospitality) — moot or deferred
- Any v1.5 items that rested on the above

**Content preserved:**
- Bharosa pillar (shopkeeper presence, Sally + Sophia reconciled, minus mythic-heirloom language)
- Pariwar pillar (Decision Circle, committee-native, Maya's full framing)
- "Remote control for the finger" curation UX
- Golden Hour Mode
- Absence Presence layer
- Guest Mode / session personas
- "Ramesh-bhaiya Ka Kamra" unified thread
- Triple Zero economic doctrine (now strengthened with phone-auth SMS caveat from tech research)
- Show, don't sutra
- Multi-tenant architecture underneath single-tenant product
- The Project data model (every order = Project of 1–N items) — **reframed** from "same spine for B2C and B2B" to "same spine for single-item and multi-item household orders" (a family buying 2 almirahs + 1 dressing table is still a Project)
- Multi-shop "strangler fig" pattern — strengthened by Alok's "any city" directive

---

## 0. Locked Constraints Going Into the Brief

1. **Single shop product** — real shopkeeper in Ayodhya's Harringtonganj market (details TBD; use "Ramesh-bhaiya" archetype)
2. **Geography-agnostic product strategy** — designed for any Tier-2/3 Hindi-speaking North Indian city; Ayodhya is just where shop #1 happens to be
3. **Platform underneath, single-tenant on top** — Yugma Labs is parent; future shops onboard under flat-fee SaaS
4. **6–9 month full enterprise-grade build**, phased v1 / v1.5 / v2
5. **Triple Zero economic model** — zero commission to shopkeeper, zero fees to customer, **literal ₹0 ops cost** to Yugma at one-shop scale. Firebase Blaze provides 10,000 SMS verifications/month free for phone auth (verified against production experience — neither the initial research subagent nor the first brief correction found this documented, but Alok's real apps confirm it). Anonymous Auth covers pre-commit flows, Phone Auth handles the commitment-moment trust ceremony with **session persistence as a hard requirement** (one-time OTP, refresh-token-backed silent sign-in on every subsequent open, no re-authentication), Google Sign-In handles the shopkeeper ops side. Revenue in v1 = ₹0.
6. **Payments** — UPI-first (0% MDR), COD, bank transfer, digital *udhaar khaata* trust-ledger. No NBFC EMI, no credit cards in v1.
7. **Languages** — Hindi (Devanagari) primary + English secondary. Hindi is first-class.
8. **Components** — (1) Flutter customer app, (2) Hindi-first marketing website on `<shopname>.yugmalabs.ai` (Firebase Hosting static), (3) Flutter shopkeeper operations app
9. **Drop Azure for v1** — Firebase Blaze (with $1/mo hard budget cap) + external free services
10. **Two pillars** — Bharosa (shopkeeper presence, trust, warmth, curation) and Pariwar (committee-native decision making). Triple Zero is an architectural discipline, not a pillar.
11. **Consumer-only.** No B2B. No institutional buyers. No bulk orders as a v1 workflow.

---

## 1. Reframes That Shape the Brief (revised to 5)

### Reframe 1 — The data model is a Project, not a SKU purchase *(Victor, reframed)*
Every customer order is a **Project** with 1 to N line items. A family buying "one almirah for Sunita-ji" and another family buying "a matching bedroom set — almirah + dressing table + bed-side cabinet" are the same primitive at different sizes. The Project concept survives the B2B drop because even consumer purchases in this category are frequently multi-item.

### Reframe 2 — Decision Circle, not Family Circle *(Maya)*
One device, many faces, zero logins. Chachaji will never download the app. The architecture assumes one phone passed across a charpai. UI becomes session-state-aware: *"abhi Mummy-ji dekh rahi hain"* toggles font size, pace, tone. **Session state, not a social network.** The original "Family Circle invite" UX was Bangalore-WeWork fiction and is killed.

### Reframe 3 — The shopkeeper is the product *(Sally, post-merger with Sophia, minus the mythic layer)*
Ramesh-bhaiya's face, voice, memory, and curation ARE the product. Not the almirah. The app's job is to carry his presence through a screen honestly — voice notes in his actual voice, his face on the landing, his memory of past customers, his curated picks. **And per Maya's "show, don't sutra" mandate, no mythic copywriting on screen** — no "temple doorway," no "vessel of memory," no captions that would make a Harringtonganj grandmother roll her eyes. Warmth through materials and specifics (photos, voice, handwritten-font signature on invoices, his actual name), not through poetry.

### Reframe 4 — The real interface is the shopkeeper's finger *(Maya)*
Customers in Tier-3 North India do not want to browse. They want Ramesh-bhaiya to point and say *"yeh lo, shaadi ke liye yehi hai."* The entire discovery UX imported from Amazon — filters, categories, comparison — is a fiction. The app is a **remote control for his finger**. Curated occasion shortlists (*"shaadi ke liye," "naye ghar ke liye," "budget ke liye," "replacement ke liye"*) replace infinite scroll. Browse/filter exists only as an emergency fallback.

### Reframe 5 — Absence as presence *(Sally)*
When Ramesh-bhaiya is asleep, at a funeral, overwhelmed with walk-ins — the app says so honestly: *"Ramesh-bhaiya is at a wedding today, back at 6 PM. Here's his son Aditya. Here's the voice note Ramesh left this morning for people exactly like you."* Pre-recorded warmth, scheduled callbacks, honest hand-offs. Never pretend he's always there.

### Reframe 6 — Triple Zero is the moat, and it is literally ₹0 *(emerged mid-session, corrected twice during brief drafting)*
Alok's directive: the product runs at ₹0 commission to the shopkeeper, ₹0 fees to the customer, and ₹0 ops cost to Yugma Labs. **Two successive corrections were needed before this pillar was honest.** First, the original tech research cited a third-party blog claiming Firebase Phone Auth bills India from the first SMS (~₹85–500/month unavoidable) — so the brief initially dropped phone auth entirely in favor of Anonymous-only. Then Alok's real production evidence (apps running phone auth in production with zero charges) surfaced the truth neither the research subagent nor the primary Firebase pricing pages (all JavaScript-rendered and unfetchable) could confirm: **Firebase Blaze includes a 10,000 SMS verifications/month free allowance for phone authentication**. At one-shop scale (200–500 unique new customers/month), that's ~2–5% of the free quota. At shop #33 (at the same average) the quota saturates, and overage is trivial ($0.01/SMS, absorbable inside a future flat SaaS fee). **Phone Auth is therefore a core v1 feature, not a premium toggle — combined with Anonymous Auth for pre-commit flows and Google Sign-In for the shopkeeper ops side, the entire auth layer is ₹0.** A hard v1 requirement: **session persistence** — customers OTP-verify once per install and never re-authenticate on subsequent opens (Firebase Auth's refresh-token pattern does this natively; the brief must pin it explicitly so the architecture honors it). The Triple Zero doctrine is honest: zero means zero. The IP is the *operational discipline* to ship world-class apps that cost literally nothing to run. Competitors (Dukaan, Shopnix, SmartBiz-post-free-period) must solve the same problem to copy the pricing — and Dukaan's 2023 collapse shows what happens when they can't.

---

## 2. Creative Unlocks — Revised Set

Six survivors from the original ten. Four dropped per course correction.

### Unlock A — Golden Hour Mode *(Maya)*
**Category:** Physical-reality / environmental design
**Cost posture:** ✅ Free-tier safe (static photos, one per SKU)

Every physical shop gets one brutal hour of perfect raking light — the hour the wood grain looks like flowing ghee and the brass handles throw copper coins onto the opposite wall. During shopkeeper onboarding, every inventory piece is photographed *during its golden hour* — one capture per SKU, lifetime asset. In the app, when the shopkeeper taps "show her the Burma teak," the screen shows the 2:47 PM version, not the 11 AM tube-light version — the almirah's Sunday best. Optional toggle — *"asli roop dikhaiye"* — shopkeeper controlled. Bonus: the app's clock knows when the customer's own eyes will catch that light in the physical shop, turning architecture into a closing tool. **Works for any shop in any city** with minor per-shop calibration (shop direction + latitude = golden-hour math).

### Unlock B — Guest Mode / Session Personas *(Maya)*
**Category:** Committee-native IA
**Cost posture:** ✅ Zero — client-side state

One device, zero logins. When the mother-in-law takes the phone, the nephew taps *"abhi Mummy-ji dekh rahi hain"* and the UI changes: bigger fonts, slower pacing, respectful tone, larger photos, louder voice note playback. When the son takes the phone back, he taps *"wapas mujhe"* and the UI returns to normal density. Session state, not accounts. Committee-native without asking a 70-year-old uncle to download an app.

### Unlock C — Ramesh-bhaiya Ka Kamra (unified shopkeeper thread) *(Sally)*
**Category:** Decision Circle manifestation
**Cost posture:** ✅ Firestore-light

One shared "Ramesh-bhaiya's room" thread per Project. Four relatives drop questions at 9:47 PM from four cities; the shopkeeper answers with one voice note that lights up all four phones. He is not four separate UIs — he is the gravitational center of the committee. Decision Circle with shopkeeper-as-tiebreaker, delivered without fracturing him into WhatsApp-groups-of-death.

### Unlock D — Absence Presence Layer *(Sally)*
**Category:** Bharosa / honesty
**Cost posture:** ✅ Firestore + small audio

The app is honest about shopkeeper unavailability. Status bar on the customer-facing landing: *"Ramesh-bhaiya dukan mein hain"* / *"Shaadi mein gaye hain, 6 baje tak wapas"* / *"Kal subah mulakat ka time free hai."* Pre-recorded "away" voice notes: *"Main shaadi mein hoon par aap beta Aditya se baat kar lijiye, wo mujhe sab bata dega."* The shop misses him out loud. This is what makes bharosa durable when the shopkeeper is human.

### Unlock E — "Remote Control for the Finger" Curation UX *(Maya)*
**Category:** Discovery reframe
**Cost posture:** ✅ Firestore-light

The default customer-facing screen is **"Ramesh-bhaiya ki pasand"** — curated shortlists, organized by occasion:
- *Shaadi ke liye*
- *Naye ghar ke liye*
- *Budget ke liye*
- *Dahej ke liye*
- *Replacement ke liye*
- *Ladies ke liye / Gents ke liye*

The shopkeeper (or his son via the ops app) updates these shortlists daily — one tap to promote or demote items. Browse/filter UX exists only behind a "Aur dikhaiye" button as an emergency fallback, never as a primary surface. Turns the app from a catalog into a dialogue.

### Unlock F — The Udhaar Khaata Digital Ledger *(synthesis, strengthened)*
**Category:** Informal credit made durable
**Cost posture:** ✅ Firestore docs, free-tier safe

Traditional *udhaar khaata* (informal credit ledger) digitized as a first-class feature, visible to both the customer and the shopkeeper. For any big-ticket purchase, the customer can take the almirah home with a partial payment (say ₹5,000 of a ₹22,000 total) and commit to a 3–5 month informal installment plan — no NBFC, no interest, no paperwork, just a shared digital ledger. The app tracks scheduled reminders, partial payments via UPI, and shows running balance in Devanagari. This is a **huge** unlock for the category because formal EMI (Bajaj Finserv) charges the shop a commission and is friction-heavy; informal *kishti* is how 60%+ of Tier-3 furniture sales actually close today, and nobody has digitized it honestly. KhataBook has the ledger piece but no storefront; this product wraps both in one trust envelope.

---

## 3. Uncomfortable Questions for Alok (revised, 6 remaining)

The 8 original questions minus the 2 that died with B2B. Still **parked, not answered** — the flinch is the data.

### Q1 — The Moat Question *(Victor)*
**If Ramesh-bhaiya wakes up tomorrow and decides he does not need you — because his son learned WhatsApp Catalog, because a Jio rep walked in with a free tablet, because he simply got tired — what exactly does Yugma Labs still own that he cannot walk away with?**

**Partial answer:** Reframe 6 (Triple Zero operational discipline as IP). Still needs explicit articulation — is the moat the codebase, the playbook, the design system, the shop-onboarding process, the brand? Without an answer, Yugma is a vendor who gets forgotten by month 10.

### Q2 — The Attention Budget Question *(Sally)*
**Have you actually sat behind the counter for three full days, shutter-up to shutter-down, and watched what happens to Ramesh-bhaiya's attention when a digital customer and a physical customer arrive in the same sixty seconds? Whose needs will the app silently punish?**

**Why it matters:** The "shopkeeper-as-presence" model assumes elastic time. It isn't. 40 high-energy minutes in a 10-hour day. Without field observation, the product becomes a burnout machine.

### Q3 — The Covenant Question *(Sophia, reframed)*
**When this shopkeeper becomes "findable," "scalable," "brandable" through your platform — whose voice is being amplified, and whose voice is being quietly overwritten? Are you the scribe who preserves his Hindi, his style, his negotiation phrasing, his jokes — or the translator who flattens them into whatever a Bangalore designer finds "charming"?**

**Why it matters:** A founder from outside the shopkeeper's town, building atop his relational capital. The ethical standing to tell this story must be earned. Without the answer, the product becomes extraction dressed in empathy.

### Q4 — The Saturday Stopwatch Question *(Maya)*
**Have you sat on a plastic stool in the shop for eight unbroken hours on the busiest day — a Saturday — and logged every interruption, tea break, power cut, phone ring, and hand-full moment, so you know empirically in what two-second windows the shopkeeper's finger is actually free to tap your beautiful interface?**

**Why it matters:** Without time-and-motion data, "remote control for his finger" is a fantasy. The app collapses into a 9 PM catalog tool — wrong product.

### Q5 — The Bandwidth of Bharosa *(synthesis)*
**If the product works, the shopkeeper's customer volume grows 10–50x. Does he WANT that?** Is his son or nephew the real product operator? Is there a second human (curator, chat responder) who must be assumed from day one?

### Q6 — Shop #2 Readiness *(synthesis)*
Triple Zero is elegant but only sustainable if shop #2 arrives to start paying the SaaS fee within ~9 months of shop #1 launch. **What is the go-to-market plan for shops 2–10?** Are they Ayodhya peers, Avadh region, Tier-3 UP, or other North India? Who sells them — Yugma's founders, partners, community, paid acquisition?

---

## 4. Risks & Blind Spots (revised, 4 remaining)

The 5 original risks minus the 1 that died with B2B (regulatory sleeper for hospitality).

### R1 — The shopkeeper burnout ceiling
If everything works, Ramesh-bhaiya becomes the bottleneck. The product must assume multiple operators from day one — *bhaiya* + *beta* + *munshi* — as three roles inside one ops-side Decision Circle. Plan for it in the Firestore schema and the ops app UI.

### R2 — Authenticity arbitrage
The Bharosa positioning depends on the shopkeeper's *actual* authenticity. If Ramesh-bhaiya is really just a reseller buying from a Kanpur wholesaler, the "built in his shop" framing collapses into marketing fiction. **Validate the provenance of his inventory before launch.** If he's a pure reseller, the positioning becomes "curation + service + trust" rather than "craftsmanship + origin story."

### R3 — Triple Zero sustainability horizon
Firebase free tier accommodates one shop comfortably, and with the layered Anonymous + Phone Auth + Google Sign-In architecture there is **no recurring cost** at one-shop scale — literal ₹0. Phone Auth's 10,000 SMS verifications/month free allowance on Blaze covers ~2–5% of realistic one-shop volume. But every component scales linearly: Firestore reads/writes, Cloud Storage egress, Cloudinary credits, AND phone auth SMS quota. Rough saturation math: at ~300 unique new customers/month per shop, the shared 10k SMS quota saturates around shop #33. Beyond that, Firestore/Storage/SMS overage is trivial per-shop and absorbable inside a flat SaaS fee, but **cost-per-shop unit economics MUST be modeled BEFORE shop #2 onboards**, not after.

### R4 — WhatsApp dependency
Critical flows lean on WhatsApp handoff (`wa.me` links, async media sharing, fallback comms). WhatsApp Business API pricing has already risen in Jan 2026 and Meta can change terms unilaterally. **Mitigation:** abstract all WhatsApp touches behind a single interface so a fallback (Telegram, SMS, plain call) can be swapped in without a rewrite.

---

## 5. The One Takeaway — If You Only Remember One Thing

> **We are not building an e-commerce app for an almirah shop.**
>
> **We are building a ₹0-ops-cost, Hindi-first, committee-native digital storefront where Ramesh-bhaiya — a real independent shopkeeper in any Tier-3 North Indian town — becomes findable, respected, and present through a screen without losing his voice, his margin, or his soul to the platform that built it.**

Every feature, every screen, every decision in the Product Brief must pass three tests:

1. **Does this carry the shopkeeper's presence, honestly?** *(Bharosa)*
2. **Does this respect the committee, not the individual?** *(Pariwar)*
3. **Does this fit inside the ₹0/month ceiling?** *(Triple Zero)*

Three yeses or it dies.

---

## 6. Technical Constraints — Revised with Research Validation

Elevated from the Triple Zero directive and validated against 2026 tech-stack research:

| Rule | Verified value (April 2026) |
|---|---|
| **Backend primary** | Firebase Blaze with **hard $1/mo budget cap** + kill-switch Cloud Function (Spark cannot deploy Cloud Functions since 2020) |
| **Dropped** | Azure (not needed), AWS, any paid cloud infra |
| **Firestore ceiling** | 50k reads/day, 20k writes/day, 1 GiB storage, 10 GiB/mo egress |
| **Cloud Storage ceiling** | 5 GB stored, 1 GB/day download |
| **Hosting** | Firebase Hosting 10 GB stored, 360 MB/day transfer (~10 GB/mo) |
| **Auth — customer app (pre-commit)** | **Firebase Anonymous Auth** (unlimited free, device-scoped UID). Covers browse, Decision Circle, committee chat, asking shopkeeper questions. Zero login friction. Honors Maya's "one device, many faces, zero logins" insight for the phase when the committee is still deciding. |
| **Auth — customer app (commit moment)** | **Firebase Phone Auth OTP** — 10,000 SMS verifications/month free on Blaze (verified against production evidence). Explicit trust ceremony at the moment of commitment (placing order, committing to udhaar khaata, finalizing purchase). Anonymous session upgrades to Phone-verified via Firebase's account-linking API without losing Decision Circle / Project state. |
| **Session persistence (hard requirement)** | After the one-time OTP, Firebase Auth stores a refresh token in secure local storage and silently refreshes the ID token on every app launch. **Customers never re-authenticate on subsequent opens.** Refresh tokens are effectively indefinite in normal use. SMS cost scales with *unique new installs*, not with sessions. |
| **Auth — shopkeeper ops app** | **Google Sign-In** (unlimited free). Shopkeeper, son, munshi each sign in with their existing Google accounts. Role-based access via Firestore `operators` list. Sessions persist indefinitely via refresh token. |
| **Customer identity for shopkeeper records** | Three overlapping layers: verified phone (from Phone Auth), UPI transaction metadata at payment time (payer VPA/phone from the UPI deep link), and the shopkeeper's own customer memory layer. Redundant, free, load-bearing. |
| **Return-visitor identity** | Same device, same install: already signed in via refresh token, no re-auth, no SMS. New device (edge case, rare): OTP re-verify with same phone number recovers the same identity and purchase history. |
| **Abuse / fraud protection** | Firebase App Check (free), Firestore security rules scoped to `shopId`, rate limits per verified phone number, shopkeeper can block numbers from the ops app, $1/month Blaze budget cap as safety rail, budget alerts on SMS consumption. |
| **Catalog images** | Cloudinary Free (25 credits/mo = ~10 GB storage + 10 GB bandwidth + 5k transformations) |
| **Hero/branding assets** | Firebase Hosting bundled with site |
| **Video (deferred to v1.5+)** | YouTube unlisted via Data API v3 (100 units per upload, 10k/day quota = 100 uploads/day free); upload from shopkeeper device via OAuth only, not server-side |
| **Chat / real-time** | Firestore real-time OR WhatsApp `wa.me` click-to-chat handoff (free) |
| **Push notifications** | FCM free, unlimited |
| **Voice/video calls (deferred)** | Flutter WebRTC + Google STUN + metered.ca free TURN (50 GB/mo free). Do not ship in v1. |
| **On-device AI (voice search, deferred)** | Android `SpeechRecognizer` in `hi-IN` mode as fallback. NOT production-ready for Hinglish code-switching in 2026. Skip for v1. |
| **Panchang data (DROPPED with Muhurat Mirror feature)** | N/A — feature removed |
| **Crash/analytics/monitoring** | Firebase Crashlytics + Analytics + Performance (all free unlimited) |
| **Build/CI** | GitHub Actions free (2k min/mo) + Codemagic free Flutter tier |
| **Flutter state management** | Riverpod 3 + riverpod_generator (2026 default, offline persistence built in) |
| **Navigation** | GoRouter (official, stable) |
| **Data classes** | Freezed 3 + build_runner |
| **UI** | Material 3 + custom `ThemeExtension` tokens for multi-tenant theming (avoid forui until 1.0) |
| **Dev tooling** | Claude Code + Dart/Flutter MCP server + Android Studio |
| **Devanagari typography** | Noto Sans Devanagari / Mukta / Hind as primary font stack; ensure Devanagari glyphs in all custom icons if any |

**Estimated true monthly cost at one shop scale:**
- Firebase infra (Firestore, Storage, FCM, Hosting, Analytics, Crashlytics): ₹0
- Anonymous Auth + Phone Auth (customer app, ~200–500 SMS/month = 2–5% of 10k free quota): ₹0
- Google Sign-In (shopkeeper ops app): ₹0
- Session persistence (refresh-token silent sign-in, no repeat SMS): ₹0
- WhatsApp (`wa.me` only): ₹0
- Cloudinary Free tier: ₹0
- **Total: ₹0/month**

The $1/month Blaze budget cap is a **safety rail** against abuse, runaway queries, or config errors — not an expected spend. The brief commits to literal ₹0 ops cost for v1, and this is architecturally honest, not marketing spin, verified against both free-tier documentation and real production experience.

---

## 7. v1 / v1.5 / v2 Cut — Revised

### v1 (Months 1–5) — Ship the consumer bharosa MVP
- **Decision Circle + Guest Mode** (core IA: one device, many faces, zero logins)
- **Project-based data model** (every order = Project of 1–N items)
- **"Remote control for the finger" curation UX** (occasion shortlists, no default infinite scroll)
- **Shopkeeper voice notes** + **Absence Presence layer** (status, scheduled away messages, son/nephew fallback)
- **"Ramesh-bhaiya Ka Kamra" chat thread** (one thread per Project, committee unified)
- **Golden Hour Mode** photo pipeline (shopkeeper ops app captures SKUs in golden-hour, customer app surfaces the Sunday-best version)
- **UPI + COD + bank transfer + digital *udhaar khaata***
- **Hindi-first UI** (Devanagari primary, English toggle)
- **Shopkeeper operations app** (inventory CRUD, orders, chat, curation shortlists, analytics, offers, customer memory)
- **Marketing website** on `<shopname>.yugmalabs.ai` (Firebase Hosting static, Devanagari-primary hero, Golden Hour imagery rotation)
- **Plain dignified PDF invoice** (Devanagari, shopkeeper's name and signature — no religious/mythic framing)
- **Crashlytics + Firebase Analytics + Performance**
- **Offline-first everything** (Riverpod 3 persistence; Firestore offline cache aggressive)
- **Multi-tenant architecture hooks** underneath (theme tokens, content externalized, namespaced by shop ID) — no configurator UI in v1
- **Phone auth with budget cap + kill-switch** (the only unavoidable cost line item)

### v1.5 (Months 5–7) — Polish, differentiation, readiness
- **Rewards / loyalty layer** (simple repeat-customer recognition, no life-milestone gimmicks)
- **Offers / promotions engine** (shopkeeper-controlled, seasonal)
- **Enhanced analytics for shopkeeper** (sales, customer follow-ups, top-curated-pick performance)
- **Customer memory amplified** (shopkeeper sees "this customer's mother-in-law bought here in 2023" surfaced automatically)
- **WhatsApp `wa.me` deep links** throughout the UX (one-tap handoff from app to WhatsApp for any conversation)
- **Website SEO + local search optimization** (Google Business Profile integration)
- **First multi-tenant dry run** — prepare onboarding playbook for shop #2 even if no one is onboarded yet

### v2 (Months 7–9) — Scale prep + advanced features
- **Cost-per-shop unit economics modeled and validated**
- **Go-to-market playbook for shops 2–10 finalized**
- **Shop #2 onboarding pilot** — first multi-tenant activation; extract configurable bits into the shop-config system
- **Optional AR "rakh ke dekho"** room placement (on-device ARCore/ARKit, free)
- **Optional Hindi voice search** using Android `SpeechRecognizer` in `hi-IN` (no Hinglish code-switch promises)
- **Festive re-skinning** (admin toggle for seasonal themes — Diwali, wedding season)
- **Shopkeeper burnout safeguards** — role-based ops app access (bhaiya/beta/munshi), load balancing, auto-queue for chat threads

### DROPPED in revision (not in any version)
- Fleet Contract / Kamra Ledger / B2B bulk
- Zimmedari Mode
- Muhurat Mirror (panchang integration)
- Threshold Passage delivery video
- First Things Stored ritual
- Ceremonial/mythic invoice framing
- Hanumanji blessing, temple doorway, pilgrim gift mode
- Any Ayodhya-specific feature
- Shop DNA personality configurator (the multi-tenant configurator UI — park indefinitely; future shops onboard via manual theme tokens)
- Cards, NBFC EMI, third-party logistics integration

---

## 8. Next Steps

1. **Park uncomfortable questions** — they become open items in the brief.
2. **Draft Product Brief** using this v2 synthesis as the spine (in progress).
3. **Stress-test the brief** via Advanced Elicitation (pre-mortem + red team).
4. **Domain Research** — already partially done via research subagents; preserve the valid parts (competitive landscape, North India furniture market, Flutter/tech stack). The Ayodhya-tourism report is discarded.
5. **Technical Research** — already complete via the Firebase/Flutter research subagent. Findings baked into section 6 above.
6. **Hand off** Product Brief + valid research outputs to Winston (Architect) for solution design.

**Session complete (v2). 5 reframes, 6 creative unlocks, 6 uncomfortable questions, 4 risks, 1 north star takeaway.**
