---
project_name: 'Almira-Project (Yugma Dukaan)'
flagship_shop: 'Sunil Trading Company (सुनील ट्रेडिंग कंपनी)'
shopkeeper_persona: 'Sunil-bhaiya'
shop_id: 'sunil-trading-company'
user_name: 'Alok'
author: 'John (BMAD PM, with Mary strategic lens)'
date: '2026-04-11'
version: 'v1.0'
status: 'Draft — operational runbook for Sunil-bhaiya onboarding'
companion_documents:
  - product-brief.md (v1.4)
  - solution-architecture.md (v1.0.3)
  - prd.md (v1.0.3)
  - epics-and-stories.md (v1.0)
  - ux-spec.md
  - frontend-design-bundle/
  - implementation-readiness-report.md (v1.1)
---

# Shopkeeper Onboarding Playbook — Sunil Trading Company

**The operational runbook for getting Sunil-bhaiya from "never heard of Yugma" to "uses the app every day" in 30 days**

---

## Why this playbook exists

The 7 BMAD planning artifacts produced by Mary, Winston, John, Sally, and the frontend-design plugin describe a beautiful Hindi-first storefront for Sunil Trading Company. They describe what the customer sees, how the architecture works, what the design system looks like, and how the 18 Walking Skeleton stories ship in 6 sprints. **None of them describe how a 50-year-old North Indian shopkeeper actually loads his 150+ existing almirahs into the app, photographs them at golden hour, and starts using the system on a Saturday afternoon between four walk-in customers and a chai break.**

Alok caught this gap in a single sharp question on 2026-04-11. The IR check missed it. The pre-mortem flagged the symptom (failure mode #1: shopkeeper never voluntarily records voice notes) but no document built the operational plan to prevent it. This playbook closes that gap.

This is **not a brief, not a PRD, not a SAD, not a UX spec.** It is an **operational runbook** — the kind of document Alok takes into the first meeting with Sunil-bhaiya printed on paper, marked up with notes, and uses to drive the first 30 days of the engagement. It is a doing-document, not a thinking-document.

---

## §1 — First-meeting checklist (the day Alok meets Sunil-bhaiya)

The first meeting determines whether everything else happens. If the shopkeeper says "haan haan, baad mein baat karte hain" and the meeting ends, the project quietly dies. The first meeting must produce a tangible commitment, not just goodwill.

### What Alok brings to the first meeting

| Item | Why |
|---|---|
| **A laptop with the customer app demo running on a real device** (Android phone, ideally cheap — Realme C-series) loaded with synthetic shop_0 data | Sunil-bhaiya needs to SEE what his shop will look like in the app. Static screenshots will not work. He needs to tap the screen. |
| **A printed Hindi value-prop card (1 page, A4, big text)** | "₹0 commission. आपकी दुकान, आपका नाम, आपका ब्रांड. हमेशा के लिए free." Must be in Devanagari, must be tap-on-the-table simple. Spec in §8. |
| **The Letter of Intent (LOI)** — printed, in Hindi, ready to sign | The LOI is the deliverable of the first meeting. Don't leave without it signed or with a clear next-step date. |
| **A second phone or tablet for the demo** | So Sunil-bhaiya can hold one device while Alok holds another, simulating the customer-shopkeeper interaction. |
| **A plain notebook + pen** | For notes ABOUT the conversation. Not a tablet — a real notebook. Tier-3 shopkeepers respect paper notes; tablet typing reads as distraction. |
| **₹500 in cash** | For chai, snacks, paying for any inconvenience. Don't accept hospitality without offering something in return. |
| **A printed list of his existing inventory** *(if Alok can get it ahead of time via WhatsApp)* | So the conversation can immediately move from "imagine your shop in this app" to "okay, let me load your real almirahs right now". |

### Meeting agenda (90 minutes)

| Time | Topic | Outcome |
|---|---|---|
| 0:00–0:10 | Chai. Family questions. Establish rapport. | Sunil-bhaiya feels respected, not pitched. |
| 0:10–0:20 | "I want to show you something" — show the demo on the synthetic shop_0 data | He sees the app in action. Lets him interrupt and ask questions. |
| 0:20–0:35 | Show his shop name in the app: "Imagine this is **सुनील ट्रेडिंग कंपनी**" — pre-loaded as a mockup | He sees HIS shop, not a generic template. |
| 0:35–0:50 | Walk through the customer-side flow once: browse → chat → commit → pay. **Use his real shop name throughout.** | He understands the customer experience. |
| 0:50–1:05 | The pitch: "₹0 commission, ₹0 fees, you keep your brand and your customer relationships. We just give you the app." Hand him the value-prop card. | He knows the deal. |
| 1:05–1:20 | Address his concerns. **Listen more than talk.** Common concerns: "मेरे ग्राहक app नहीं चलाते" / "मेरे पास इतना time नहीं" / "मेरा बेटा/बहन ऐसी चीज़ें करता है" | He feels heard. Alok takes notes. |
| 1:20–1:30 | The ask: sign the LOI. Schedule the next meeting (the inventory load session). | LOI signed OR firm next-step date. |

### Red flags during the first meeting

Watch for these. They're the early warning signs the project will fail:

- **"Theek hai, aap baad mein aaiye"** ("Okay, come back later") without a specific date → he's politely declining. Don't accept this. Get a date or get a no.
- **He doesn't pick up the demo phone** → he's not interested. Hand it to him directly. If he still doesn't engage, the project is in trouble.
- **He mentions a competitor or another vendor** → understand the competitor. Don't badmouth. Just be clear about why Yugma is different (zero commission, his brand, his name).
- **He tries to negotiate a fee for using the app** → he doesn't believe ₹0 is real. Repeat: "हमेशा के लिए free, सच में."
- **His son / nephew is not mentioned at any point** → the multi-operator assumption may be wrong. Probe: "आपकी दुकान में और कौन कौन काम करता है?"
- **He says "हाँ हाँ" (yes yes) without asking questions** → he's being polite. He doesn't actually understand. Slow down and re-explain with the demo phone in his hand.

### What "first meeting succeeded" looks like

- **LOI signed** OR firm signed-by date within 7 days
- **Next meeting scheduled** (the inventory load session)
- **Sunil-bhaiya has touched the demo phone for at least 5 minutes**
- **Alok knows the names of the people who will help with the digital side** (son / nephew / munshi by name)
- **Alok has a list of 10–20 of Sunil-bhaiya's most important SKUs** (even if just from a WhatsApp photo of his existing inventory list)

---

## §2 — Inventory bulk-load — pick ONE of these four options before the next meeting

The single biggest operational risk is that Sunil-bhaiya has 150–300 existing almirahs and the ops app's PRD S4.3 only supports adding them one at a time at ~90 seconds each. **At one SKU per 90 seconds, 200 SKUs = 5 hours of pure typing.** No 50-year-old shopkeeper does 5 hours of typing on a Saturday.

Pick ONE of these four options based on what you learn in the first meeting. **Do not try to do all four.** Pick the one that fits Sunil-bhaiya's actual situation.

### Option A — Yugma Labs concierge load (recommended for v1)

**What it is:** Alok (or a hired helper) sits next to Sunil-bhaiya for 2 days at the shop with a laptop. Sunil-bhaiya points at almirahs and reads out names + prices. Alok types them into the ops app via S4.3. They photograph each piece together during the golden hour (§3 below).

**Pros:** No engineering work needed. The shopkeeper feels the relationship. Yugma learns the inventory firsthand. Builds trust.

**Cons:** Costs ~16 hours of Alok's time (or a hired helper's time) per shop. Not scalable to shop #5+.

**Realistic time budget:**
- Day 1 morning (3 hours): walk through the shop, photograph the top 30 SKUs in golden hour, type names and prices
- Day 1 afternoon (3 hours): finish the next 30 SKUs, capture remaining photos
- Day 2 morning (3 hours): finish the bulk of inventory (~70 more SKUs)
- Day 2 afternoon (3 hours): handle the long tail (rare items, seasonal stock), set up curated shortlists, walk Sunil-bhaiya through the ops app
- Total: ~12 hours over 2 days, ~150 SKUs loaded

**Recommended for the Ayodhya flagship.** It's slow but it works. The relationship value is also load-bearing.

### Option B — CSV bulk import (engineering add to v1)

**What it is:** Add a one-time bulk import flow to the ops app. Sunil-bhaiya (or someone) creates a CSV / Google Sheet of his inventory. The app has a "import from CSV" button that uploads the file, validates it, and creates SKU documents in batch.

**Engineering scope:** New PRD story (call it **S4.13** — Bulk SKU import via CSV). ~3 days of work for Amelia. CSV columns: name (Devanagari), name (English), category, material, height, width, depth, base_price, negotiable_floor, in_stock, stock_count, description.

**Pros:** Reusable for shop #2, #3, #N. One-time engineering cost.

**Cons:** Requires Sunil-bhaiya (or his nephew) to create a CSV — not a thing 50-year-old North Indian shopkeepers do natively. Photos are still a separate problem.

**Recommended for v1.5+**, when shop #2 is being onboarded and the CSV path becomes a real lever. **Add the story to the v1 backlog with status "v1.5 deferred" so it's tracked.**

### Option C — WhatsApp paste (quick and dirty)

**What it is:** Sunil-bhaiya sends Alok a WhatsApp message listing his inventory (or photos of his existing paper register). Alok types it into the ops app from his desk. Photos handled separately during a dedicated session (§3).

**Pros:** Sunil-bhaiya doesn't have to learn a new tool. Alok can do it from anywhere.

**Cons:** Slow for Alok (~5 hours of typing). No photo capture during typing.

**Recommended as a fallback** if Option A's 2-day visit isn't possible due to scheduling.

### Option D — Photo-first, label-later

**What it is:** Spend the first 1–2 days photographing every almirah in golden hour with a lightweight camera app or the ops app's S4.5 capture flow. The photos are saved with placeholder names like `sku_001`, `sku_002`. Then over the next week, Alok or the nephew adds names + prices retroactively by reviewing the photo gallery in the ops app.

**Pros:** Front-loads the visual asset capture (the harder part). Easier to work in batches. Photos are the differentiator — getting them done right matters more than typing speed.

**Cons:** Requires the ops app to support "create SKU from existing photo" — a small but real feature addition. The catalog is incomplete during the 1-week labeling window.

**Recommended for hybrid use with Option A**: photograph everything in 2 days (Option D), type names from notes during the photo session and over the following week (Option A's typing component).

### My recommendation: **Hybrid Option A + Option D**

- **Day 1 (4–5 hours, golden hour focused):** Alok and Sunil-bhaiya's nephew photograph 60–80 SKUs during the shop's golden hour (~2:00–3:30 PM in Ayodhya), each with the ops app's S4.5 capture flow. Names typed live as they shoot.
- **Day 2 (4–5 hours, evening shift):** Photograph the remaining 70–120 SKUs after the golden hour using "working light" mode (B1.5's `असली रूप दिखाइए` toggle). Type names and prices in parallel.
- **Days 3–7 (background):** Sunil-bhaiya and his nephew refine the catalog incrementally as they encounter each SKU during normal shop operations. Alok checks in via WhatsApp daily.
- **Day 7 milestone:** ~150 SKUs loaded with photos. App is "alive." Curated shortlists populated.

**Architectural implication:** Add **PRD S4.13 — Bulk SKU import via CSV** as a v1.5 story for the post-flagship shops. Don't build it for shop #1 — Hybrid A+D is enough.

---

## §3 — Initial Golden Hour photo session — calendar block

Per Maya's reframe in the party-mode session and PRD B1.5, every SKU should ideally have a Golden Hour photo (the "Sunday best" version of the almirah, captured during the shop's one hour of perfect raking light). For a 150-SKU catalog, this is **5+ days of dedicated photo work** if approached naively.

### The realistic photo session plan

| Day | Activity | SKUs photographed | Time of day |
|---|---|---|---|
| 1 | First photo session — top 30 best-selling SKUs | 30 hero photos (golden hour) | 2:00–3:30 PM |
| 2 | Second photo session — next 30 SKUs | 30 hero photos (golden hour) | 2:00–3:30 PM |
| 3 | Working-light session — long tail SKUs | ~50 working photos | Any time |
| 4 | Working-light session — remaining inventory | ~40 working photos | Any time |
| 5 | Retakes + shortlist curation | ~10–15 SKUs re-photographed | Mixed |

### Equipment

- **One mid-range Android phone** (Realme C-series, Redmi 9, or whatever Sunil-bhaiya's nephew already has). The ops app's camera UX is built into S4.5 — no separate camera app needed.
- **A simple cloth backdrop** (white or cream) — optional but improves photo consistency. ₹200 from a local cloth shop.
- **A small LED ring light** — optional, ~₹500 — for working-light photos when natural light is poor.
- **No tripod needed** — handheld is fine for product shots at this scale.

### Who actually shoots

- **Primary photographer: Sunil-bhaiya's nephew (the "beta")** — younger, comfortable with phone cameras, present at the shop on Sundays.
- **Secondary: Alok** — for the first 2 days, then handed off entirely to the nephew.
- **NOT Sunil-bhaiya himself** — he's 45–55 years old, doesn't naturally handle smartphone cameras for product photography. He can review and approve, not shoot.

### Scheduling the photo session

- **Block 5 days on the calendar** with Sunil-bhaiya and his nephew at first meeting time. Not "sometime next week" — actual dates.
- **Rain backup plan:** if it's raining during the golden hour, the working-light session shifts to that day. The hero photos defer to the next clear afternoon.
- **Festival / wedding season backup plan:** if the shop is too busy during golden hour to photograph (peak Oct–Feb), shift the photo session to a Tuesday morning when foot traffic is lowest. Accept that some hero photos will be re-shot in the next quiet week.

---

## §4 — Day-1 ops app checklist

The very first time Sunil-bhaiya opens the ops app on his own (not during the demo, but for real), here's the exact sequence of things that should happen. This becomes a printed checklist Alok hands him on Day 1.

### Day 1, Morning (with Alok present)

- [ ] Open the ops app → Google Sign-In with Sunil-bhaiya's existing Gmail account
- [ ] Verify the operator role lookup succeeds (Yugma Labs has pre-created the operator document with `role: bhaiya`)
- [ ] Walk through the home dashboard — show the orders tab (empty), inventory tab (empty), chat tab (empty), settings tab
- [ ] **Upload Sunil-bhaiya's face photo** via Settings → Branding → Face photo. *(Conditional on D4 consent — see Brief design decisions. If he declines, skip this step and the app uses the typographic fallback.)*
- [ ] **Record the welcome voice note** via Settings → Branding → Welcome message → 🎤. Sample script in Hindi: *"नमस्ते जी, मैं सुनील। आइए, बताइए क्या ज़रूरत है — शादी, नया घर, या कुछ और? मैं हाज़िर हूँ।"* (Sunil-bhaiya speaks naturally, not from a script. The script is just a starter.)
- [ ] **Set business hours** via Settings → Profile → Hours: 9 AM – 9 PM, daily
- [ ] **Verify the shop's UPI VPA** is configured correctly via Settings → Payments
- [ ] **Add the second operator (the nephew)** via Settings → Operators → Add → enter the nephew's Gmail address → assign role `beta`
- [ ] **Confirm the nephew can sign in on his own phone** with his Google account and see the same shop data

### Day 1, Afternoon (Alok present, photo + load session)

- [ ] Photograph the first 6 SKUs in golden hour using S4.5 capture flow
- [ ] Type the names + prices for each as you go
- [ ] **Create the first curated shortlist** ("शादी के लिए") via S4.12 → "मेरी पसंद" tab → drag the 6 newly-loaded SKUs into the शादी shortlist in priority order
- [ ] **Verify the customer app's landing screen** shows: Sunil-bhaiya's face, his name, the welcome voice note (auto-plays), and the शादी shortlist preview. **This is the moment the app comes alive.**

### Day 1, Evening (Alok hands off)

- [ ] Print the Day 2 checklist (§5 below) and leave it with Sunil-bhaiya
- [ ] Print the troubleshooting card (§8 below) and leave it taped to the wall behind the counter
- [ ] Schedule the Day 7 check-in call

### Day 1 success criteria

- Sunil-bhaiya has signed in successfully ✅
- His face + welcome voice note are live ✅
- 6 SKUs are loaded with Golden Hour photos ✅
- 1 curated shortlist (शादी) is populated ✅
- Customer app landing renders correctly when Alok demos it on his phone ✅
- Sunil-bhaiya can answer "How do I add a new almirah?" in his own words ✅

---

## §5 — Day 1 to Day 30 ramp — the inventory build-out

The app is "alive" after Day 1 but only has 6 SKUs. The remaining 144 need to land over the next 30 days. Here's the daily rhythm.

| Day | Daily task (10–20 minutes max) | Cumulative SKUs |
|---|---|---|
| 1 | Initial 6 SKUs loaded with Alok | 6 |
| 2 | "Add 5 more almirahs" prompt — focus on bestsellers | 11 |
| 3 | "Today's task: photograph 5 wooden wardrobes" | 16 |
| 4 | "Add 5 more SKUs — focus on dahej-grade pieces" | 21 |
| 5 | "Record one voice note for any SKU you're proud of" | 21 + 1 voice |
| 6 | "Add 5 more SKUs" | 26 |
| 7 | **Day 7 check-in call with Alok** — review progress, troubleshoot | 26 |
| 8 | "Add 8 SKUs today — feeling confident yet?" | 34 |
| 9 | "Add 8 more" | 42 |
| 10 | "Add 8 more — half-way to the catalog" | 50 |
| 11 | "Today's task: review your शादी shortlist and reorder if needed" | 50 |
| 12 | "Add 10 SKUs" | 60 |
| 13 | "Add 10 SKUs" | 70 |
| 14 | **Day 14 check-in call with Alok** — milestone celebration | 70 |
| 15–21 | "Add 8 SKUs/day" with daily push reminders | 70 → 126 |
| 22–28 | "Add 4 SKUs/day, polish photos, refine shortlists" | 126 → 154 |
| 29 | "Review the entire catalog. Anything missing?" | 154 |
| 30 | **Day 30 milestone:** full catalog live, 5 curated shortlists populated, ~10 voice notes recorded, first real customer journey end-to-end | 154 SKUs |

### The daily prompt mechanism

The ops app needs a small "today's task" feature to drive this ramp. **This is a v1 add — a small Sprint 2 enhancement.** The mechanism:

- A new screen called `आज का काम` ("Today's task") on the ops app home dashboard
- Pre-populated with the Day 1–30 ramp tasks per the table above
- One task per day, dismissible after completion
- After Day 30, the screen transitions to a "weekly habit" rotation (see §5.5 below)
- **No notifications/push** — Sunil-bhaiya checks the app on his own rhythm. The screen waits patiently.

**Architectural implication:** Add **PRD S4.13 — "Today's task" daily prompt screen** as a v1 Sprint 2 story. ~2 days of work for Amelia. Cheap, high-leverage for adoption.

---

## §5.5 — Post-Day 30 daily management rhythm — what "managing the app on his own" actually looks like

The Day 1–30 ramp gets the catalog populated. But the question Alok asked — *"how will Sunil-bhaiya manage the app on his own?"* — is really about Day 31 onwards: the steady-state daily rhythm after the catalog is full and the novelty has worn off. This section answers that explicitly.

### Design principle: short bursts, never sessions

The ops app is designed to be **used in 5-minute bursts during the natural rhythm of the shop**, not as a dedicated 1-hour management session. Per Sally's UX Spec §3.4 + the brief's pre-mortem failure mode #12 (Saturday stopwatch finding), Sunil-bhaiya has ~30–45 minutes of free attention per day across 4 separate windows. The app fits INTO those windows; it never demands a window be created for it.

### A typical Tuesday in Harringtonganj — Day 31 onwards

| Time | Natural shop window | What happens in the app | Who does it | App time |
|---|---|---|---|---|
| **9:00 AM** | Morning chai | Open ops app → check overnight notifications: any new chat messages? Any new orders? Any udhaar payments due? | Bhaiya | 5 min |
| **11:00 AM** | Pre-lunch lull (Maya's "free finger" window) | Nephew replies to 2 customer chat messages from last night using voice notes (press → speak → release). Marks one SKU as out of stock. | Beta (nephew) | 10 min |
| **2:30 PM** | Golden hour | If new almirah arrived this week → photograph via S4.5. If nothing new → no app interaction. | Beta (nephew) | 5–15 min, only when new stock |
| **5:30 PM** | Pre-evening lull | Customer arrives for delivery → bhaiya marks order as "delivered" via S4.11. Munshi records cash if applicable. | Bhaiya + Munshi | 5 min |
| **8:30 PM** | After dinner, after closing | Final check: any unanswered messages? Tomorrow's deliveries? Record one voice note from the day. | Bhaiya | 10 min |

**Total daily ops time across the family: ~30–45 minutes, spread across 5 short windows.** Nobody sits down for a "management hour." The app fits the shop, not the other way around.

### Role split — who does what

| Role | Daily responsibility | Weekly responsibility | Total weekly time |
|---|---|---|---|
| **Bhaiya** (Sunil) | Voice notes, relationship-critical chat replies, marking deliveries, presence status updates, occasional settings | Review week's orders, refine curation, check customer memory entries | ~5 hrs/week |
| **Beta** (nephew) | Routine chat replies, inventory updates, photo capture (when new stock), data entry | Catalog cleanup, stock count audit | ~5–8 hrs/week |
| **Munshi** (optional) | Udhaar ledger entries, payment recording, COD reconciliation | Monthly udhaar statement review | ~2–3 hrs/week |

**Total operational human time across all 3 roles: ~12–16 hours per week.** This is normal Tier-3 shop ops time — not an additional burden, just a different surface for activity that already happens.

### System mechanisms that make this manageable

1. **FCM push notifications** — new orders, chat messages, payment confirmations all push to bhaiya's phone. He doesn't have to remember to check; the app tells him.
2. **Real-time Firestore listeners** — the orders list updates automatically. No refresh button needed.
3. **"Today's task" card (S4.13)** — one specific thing per day during Day 1–30, then transitions to a weekly habit prompt rotation post Day 30.
4. **Weekly habit prompts (post Day 30)** — repeat monthly to maintain rhythm:
   - Week 1 of month: "Record one voice note about a recent customer interaction"
   - Week 2: "Photograph any new arrivals during golden hour"
   - Week 3: "Review your शादी shortlist — anything outdated?"
   - Week 4: "Check udhaar ledger — any open accounts needing follow-up?"
5. **Multi-operator concurrent access** — bhaiya, beta, munshi all see the same data simultaneously across their devices. Bhaiya doesn't have to relay anything to the nephew; the nephew sees it.
6. **Honest absence presence** — when bhaiya is at a wedding, he taps `away` once, customers see the banner, the nephew or pre-recorded voice note handles the gap.
7. **No batch mode** — the app never demands "set aside an hour to do this." Every action is single-tap, single-screen: add SKU = 90 sec, reply text = 15 sec, mark delivered = 5 sec, record voice note = 10 sec.

### What happens if it starts to slip — early warning signals

| Signal | What it means | Mitigation |
|---|---|---|
| Chat reply latency >4 hours | Nephew isn't checking the app | Alok sends a daily WhatsApp reminder to the nephew |
| Inventory stale >1 week | Nephew has stopped updating | Weekly "stock check" prompt in Today's task rotation |
| No voice notes >2 weeks | Bhaiya is disengaging | Personal call from Alok |
| Days bhaiya OR beta opened app <3 in trailing 7 days | **Project is in trouble** | Emergency intervention per playbook §10 |
| Real customer chat goes unanswered for 24 hours | Total ops failure | Alok directly intervenes; consider Yugma-paid college student helper |

### What "managing the app on his own" looks like at Day 90

By Day 90, if everything has gone well:
- Bhaiya opens the app **without thinking about it** — it's part of morning chai, like checking WhatsApp
- The nephew handles all routine inventory + chat without prompting
- The "Today's task" card has transitioned to weekly habits and Sunil-bhaiya treats them like Sunday newspaper crosswords — ignorable but pleasant
- Real customers find him via the marketing site + WhatsApp shares from past customers
- Inventory is fresh, photos are current, voice notes are recorded organically when something interesting happens
- The app is no longer "the new thing" — it's just how the shop works now

**This is the success pattern.** The app should feel as native as the cash drawer by Day 90.

### What "managing the app on his own" looks like if it fails

By Day 90, if it has failed:
- Bhaiya opens the app once a week, mostly to dismiss notifications
- The nephew has lost interest after Week 4
- Catalog is half-stale
- Voice notes are 6 weeks old
- Real customer chat messages sit unanswered for days
- The app is "the thing Alok made me sign up for"

This is the failure pattern. The intervention thresholds in §10's pre-mortem are specifically designed to catch this BEFORE Day 90.

---

## §6 — Operator role clarity — name names

The brief assumes a multi-operator model (bhaiya + beta + munshi). Sally's pre-mortem #4 flagged that this might not match reality. **Do not start coding until Alok has the real names and real time commitments.**

### What Alok must capture in the first meeting

| Role | Real name | Relationship | Age | Day job? | Weekly hours committed | Google account |
|---|---|---|---|---|---|---|
| **bhaiya** (primary) | Sunil-bhaiya | (the shopkeeper) | 45–55 | Full-time at shop | 60+ hrs/week (the entire shop) | TBD |
| **beta** (digital operator) | _____ | son / nephew / cousin | 25–35 | TBD (Alok captures) | TBD (target: 5+ hrs/week) | TBD |
| **munshi** (payments + ledger) | _____ | longtime accounts helper, optional | 30–60 | Often part-time | TBD (target: 2+ hrs/week) | TBD |

**Rules:**
- The beta MUST be willing to commit at least 5 hours per week to the app — minimum threshold for inventory updates and customer chat replies. If no one in the shop can commit 5 hours, the project is in trouble before it starts.
- The munshi is OPTIONAL in v1. Don't force the udhaar khaata flow into someone who doesn't want it.
- Each operator gets their own Google login per S4.1. They don't share credentials.

### What to do if the beta doesn't exist

If after the first meeting Alok concludes there is NO viable "beta" (no son willing, no nephew available, no cousin nearby), the project has three options:

1. **Yugma Labs hires a part-time digital helper** for Sunil-bhaiya — a college student in Ayodhya, ₹3,000–₹5,000/month, 5 hrs/week, sits at the shop 2 evenings a week to handle inventory updates and chat replies. **This breaks the Triple Zero promise** (Yugma now has a recurring cost) but unblocks the operational reality.
2. **Defer the project** until Sunil-bhaiya has a real digital helper available. Don't waste engineering time on an unsupported shop.
3. **Reduce the v1 scope** — drop the chat replies feature, drop the daily inventory updates, ship a "static brochure" version that Sunil-bhaiya only needs to touch once a month. Loses most of the Bharosa pillar but is at least operational.

**My recommendation:** Option 1 if Sunil-bhaiya's situation requires it. The ₹3,000–₹5,000/month is a justified Yugma Labs investment for the flagship shop and is paid by Yugma directly, NOT by Sunil-bhaiya — the Triple Zero promise to him remains intact.

---

## §7 — Resistance handling

What if Sunil-bhaiya is polite but uninterested? What if he says "haan haan" but never opens the app after Day 1?

### Common resistance patterns and responses

| Pattern | What Sunil-bhaiya says | What Alok hears | What Alok says back |
|---|---|---|---|
| **Polite no** | "हाँ हाँ, बहुत बढ़िया है, बाद में देखेंगे" | He's not interested | "अच्छा बताइए, क्या कोई problem है? क्या मुझसे कोई गलती हुई?" — invite specific feedback |
| **Time excuse** | "मेरे पास इतना time नहीं है इन सब चीज़ों के लिए" | He's worried about effort | "बिल्कुल सही — इसलिए हम सब आपके बेटे/भतीजे को सिखाते हैं। आप सिर्फ़ approval देते हैं।" |
| **Trust gap** | "आप Yugma वाले अभी नये हैं, मैं तो 22 साल से dukan चला रहा हूँ" | He doesn't trust the platform | "हाँ बिल्कुल। हम भी आपसे सीख रहे हैं। पहली शॉप आप हैं — हम आपके साथ साथ बनाएंगे।" |
| **Customer doubt** | "मेरे ग्राहक app पर नहीं आते" | He thinks the customer base won't use the app | "ज़रूरी नहीं कि आपके मौजूदा ग्राहक app पर आएं। अगर 10 नए ग्राहक app से आएँ, तो भी फायदा है। और आप अपने पुराने ग्राहकों के साथ WhatsApp से जैसे काम करते हैं, वैसे ही चलता रहेगा।" |
| **Money question** | "इसमें मुझे क्या देना होगा?" | He doesn't believe ₹0 is real | "कुछ नहीं। हमेशा के लिए कुछ नहीं। अगर कभी हम पैसा माँगें तो आप ये LOI दिखा दीजिए।" — point at the LOI's zero-commission clause |
| **Family complication** | "मेरे बेटे को ये पसंद नहीं आएगा" / "मेरी बहू को नहीं आता ये" | Family politics | Listen carefully. Often the resistance is from someone NOT in the room. Ask to meet that person separately. |

### When to walk away

- After 14 days of zero app usage by Sunil-bhaiya AND zero by his beta
- After 3 missed scheduled meetings without explanation
- When Sunil-bhaiya explicitly says "I don't want to do this anymore"
- When the ops cost / Yugma effort exceeds what the flagship is worth as a learning exercise (define this threshold upfront — recommendation: 60 hours of Alok's time over 90 days)

**Walking away gracefully:** Yugma keeps the codebase. The shopkeeper keeps his data (a one-click export). No bridges burned. The next shopkeeper learns from this experience.

---

## §8 — Training assets to prepare

These are the printed / digital assets Alok needs in hand before the first meeting.

### Asset 1: Hindi value-prop card (1 page A4)

**Content:**
```
   सुनील ट्रेडिंग कंपनी के लिए
        Yugma Dukaan

   ✓ ₹0 commission — हमेशा के लिए
   ✓ ₹0 ग्राहक से fee
   ✓ आपका नाम, आपकी दुकान, आपकी पहचान
   ✓ हिंदी में सब कुछ
   ✓ आपका WhatsApp जैसा चलता है, वैसे ही
   ✓ आप जब चाहें close कर सकते हैं

   हम कौन हैं?
   Yugma Labs एक छोटी टीम है जो आप जैसे
   दुकानदारों के लिए app बनाती है — बिना
   commission, बिना hidden charges।

   आगे क्या?
   पहले 30 दिन हम आपके साथ हैं — हर step पर।
   30 दिन बाद, app आपका है।

   प्रश्न? अलोक से बात कीजिए:
   📞 +91-XXXX-XXXXXX
   📱 WhatsApp same number
```

**Design:** Plain, no logos beyond a small "Y" mark, big text (minimum 18pt for body, 32pt for headlines), Devanagari only (English on the back if needed). Print on 100gsm cream paper. NOT glossy.

### Asset 2: Day 1 checklist (printed, single page)

The §4 Day-1 ops app checklist, formatted as printable single-page checkboxes. Hindi headers, English step descriptions for the technical steps. Alok hands this to Sunil-bhaiya on Day 1 morning.

### Asset 3: Troubleshooting card (printed, single page)

Taped behind the counter for the operator to reference when the app does something unexpected.

```
   Yugma Dukaan — समस्या समाधान

   App नहीं खुल रहा?
   → फ़ोन restart कीजिए, फिर खोलिए

   ग्राहक का message नहीं दिख रहा?
   → Internet check कीजिए
   → अगर internet है, app बंद करके फिर खोलिए

   Inventory update नहीं हो रही?
   → "अभी" tap कीजिए (refresh)
   → Internet check कीजिए

   कोई आवाज़ नोट play नहीं हो रहा?
   → Phone का volume check कीजिए
   → Silent mode बंद कीजिए

   कोई और problem?
   → Alok को WhatsApp कीजिए:
   → +91-XXXX-XXXXXX
   → हम 1 घंटे में जवाब देंगे
```

### Asset 4: 90-second WhatsApp video tutorial

A short video (recorded by Alok, sent via WhatsApp) showing the 5 most common ops app actions:
1. Adding a new SKU (15 sec)
2. Recording a voice note (15 sec)
3. Replying to a customer message (15 sec)
4. Updating a curated shortlist (15 sec)
5. Marking an order as delivered (15 sec)

Alok speaks Hindi, on-screen text in Devanagari. Sent to Sunil-bhaiya the day before the first meeting so he can preview, and re-sent on Day 1 as a bookmarked reference.

---

## §9 — Success metrics for the first 30 days (operational, not product)

The PRD §6 success criteria are PRODUCT metrics (orders, leads, revenue). This playbook tracks OPERATIONAL ADOPTION metrics — the leading indicators of whether the platform will survive at this shop.

### Week-by-week adoption targets

| Week | Target metric | Threshold | Action if missed |
|---|---|---|---|
| Week 1 | SKUs loaded | ≥30 | Schedule Day 7 emergency check-in. Loading is too slow. |
| Week 1 | Voice notes recorded by Sunil-bhaiya | ≥3 | Demonstrate the recording flow again on Day 7. |
| Week 1 | Days the bhaiya opened the ops app | ≥4 of 7 | Trust gap forming. Schedule a longer check-in. |
| Week 1 | Days the beta opened the ops app | ≥3 of 7 | Beta engagement is the early warning. If beta is silent, escalate. |
| Week 2 | SKUs loaded (cumulative) | ≥70 | Pull in one of the rejected bulk-load options. |
| Week 2 | Curated shortlists populated (cumulative) | ≥3 of 6 | Help Sunil-bhaiya think through occasion segmentation. |
| Week 2 | First test customer journey (Mary or Alok as the customer) | ✅ End-to-end works | If this fails, halt content work and fix the bug. |
| Week 3 | SKUs loaded (cumulative) | ≥120 | If short, ramp the daily prompt. |
| Week 3 | Real customer chat (any message from a real customer) | ≥1 | If zero, the app exists but no one knows about it. Sunil-bhaiya needs to share his marketing site URL with 5 real customers via WhatsApp. |
| Week 4 | SKUs loaded (cumulative) | ≥150 | Catalog functionally complete. |
| Week 4 | All 6 curated shortlists populated | ✅ | Operator workflow established. |
| Week 4 | Real customer Project committed | ≥1 | The Month 3 hard gate per Brief §6 is now in reach. |

### Single most important metric

> **Days in the trailing 7 days when the bhaiya OR the beta opened the ops app.**
>
> If this drops below 3 of 7 at any point during the first 30 days, the project is in trouble. Active intervention required.

---

## §10 — 30-day pre-mortem

What goes wrong in each week if Yugma doesn't actively manage adoption?

### Week 1 — "He never came back"

**Failure mode:** Sunil-bhaiya signs in once on Day 1 with Alok present, then doesn't open the app again. The 6 SKUs Alok loaded sit in Firestore. The customer app landing renders correctly but no one is curating, no voice notes, no chat replies.

**Why it happens:** No daily reason to open the app. The "Today's task" feature isn't built yet (it's an S4.14 add). Sunil-bhaiya doesn't know what to do with it.

**Mitigation:**
- Alok sends a daily WhatsApp to Sunil-bhaiya for the first 7 days: "आज एक काम — 5 अल्मीरा और जोड़िए" / "आज: एक आवाज़ नोट रिकॉर्ड कीजिए"
- Alok physically visits the shop on Day 4 (mid-week check-in)
- The Day 7 phone call is non-negotiable

### Week 2 — "His nephew never showed up"

**Failure mode:** The "beta" (digital operator) was identified in the first meeting but never actually shows up to help. Sunil-bhaiya is the only one operating the app and he's overwhelmed.

**Why it happens:** Beta has a day job, the shopkeeper underestimated his nephew's availability, the beta lost interest after the novelty wore off.

**Mitigation:**
- Direct outreach to the beta — Alok messages him separately on WhatsApp
- Offer the beta a small monthly stipend (₹1,500–₹3,000) for committed weekly hours — paid by Yugma, not Sunil-bhaiya
- If the beta still doesn't engage, execute Option 1 from §6 (Yugma hires a college student helper)

### Week 3 — "No real customers found the app"

**Failure mode:** The app is ready, the catalog is half-loaded, Sunil-bhaiya is engaged — but no real customers have arrived. The app is a museum.

**Why it happens:** Sunil-bhaiya hasn't shared the marketing site URL with anyone. There's no acquisition story.

**Mitigation:**
- Hand Sunil-bhaiya 50 printed business cards with the marketing site URL on them. ₹500 print cost.
- Help him compose a WhatsApp broadcast to his existing customer list: "नमस्ते जी, मेरी नई website है — sunil-trading-company.yugmalabs.ai. यहाँ आप सब अल्मीरा देख सकते हैं और मुझसे online बात कर सकते हैं।"
- Encourage him to share it in 1–2 local WhatsApp groups (neighborhood, family)
- Acquisition isn't engineering's problem in v1, but it IS Yugma Labs' problem operationally.

### Week 4 — "First real order failed in production"

**Failure mode:** A real customer arrives, browses the app, tries to commit — and the Phone OTP flow fails OR the UPI deep link doesn't return correctly OR the Project state transition has a bug.

**Why it happens:** Sprint 1–4 are complete but Sprint 5 (commit + payment) was rushed.

**Mitigation:**
- Mary or John is "on call" for the first real customer journey
- Test with synthetic data daily during Week 3 to surface bugs before real customers hit them
- Have a fallback path: if the in-app commit fails, the customer can complete via WhatsApp and Sunil-bhaiya manually creates the Project in the ops app

### What "30 days in" looks like if all goes well

- Catalog: ~150 SKUs loaded, all with at least working-light photos, top 30 with Golden Hour photos
- Voice notes: ~10 recorded across welcome message, top SKUs, away/absence states
- Curated shortlists: All 6 occasion shortlists populated with Sunil-bhaiya's actual picks
- Operator engagement: bhaiya opens the app 5+ days per week, beta opens 3+ days per week
- Real customers: At least 1–3 real customers have completed full journeys end-to-end via the app
- First real order: Has happened (paid via UPI or COD or udhaar khaata)
- Sunil-bhaiya's 30-day verdict: "Theek hai, chalta hai" — neutral to mildly positive — is a SUCCESS at Day 30. We are not selling him the app. We are letting him discover whether it helps.

### What "30 days in" looks like if it fails

- Catalog: ~30–60 SKUs loaded, mostly during the first week, then nothing
- Voice notes: ~3, all recorded on Day 1
- Curated shortlists: 1 populated (शादी), the rest empty
- Operator engagement: bhaiya opens the app 1–2 days per week, beta has stopped opening it entirely
- Real customers: 0
- Sunil-bhaiya: polite but disengaged. Says "haan haan" when Alok asks but doesn't engage.
- **Action:** halt forward investment. Yugma Labs writes a post-mortem. The bundle is preserved as a zero-cost asset for the next shopkeeper. Sunil's data is exported and given to him. Bridges remain intact.

---

## §11 — Architectural follow-ups this playbook surfaces (for John to add to PRD v1.1)

This playbook surfaces 2 architecture/PRD additions that should be added to v1 scope:

### Addition #1 — PRD S4.14 (NEW): "Today's task" daily prompt screen

**Story:** As Sunil-bhaiya, I want a single screen on the ops app home dashboard that tells me ONE specific thing to do today (add 5 SKUs / record a voice note / review my शादी shortlist), so that I know how to use the app without thinking.

**Why:** The single biggest adoption risk is "shopkeeper opens the app and doesn't know what to do." This screen solves it.

**Scope:** Small. ~2 days for Amelia. Pre-populated with the 30-day ramp from §5 of this playbook. Dismissible per task. Disappears after Day 30 (or transitions to "weekly habit" prompts).

**Sprint:** Add to Sprint 2 alongside the other E4 stories.

### Addition #2 — PRD S4.15 (NEW): Bulk SKU import via CSV (deferred to v1.5)

**Story:** As Yugma Labs, I want a one-time bulk SKU import flow in the ops app that accepts a CSV / Google Sheet of inventory and creates SKU documents in batch, so that shop #2+ can onboard without 5 hours of one-by-one typing.

**Why:** Shop #1 (the Ayodhya flagship) is handled by the concierge plan in §2. Shop #2 onwards needs this to be repeatable.

**Scope:** ~3 days for Amelia. CSV columns: name (Devanagari), name (English), category, material, height, width, depth, base_price, negotiable_floor, in_stock, stock_count, description.

**Sprint:** v1.5 only (not v1). Add to the Epics List §10 v1.5 deferred backlog.

**John should add both stories to PRD v1.0.4 in a follow-up patch round.**

---

## End of Shopkeeper Onboarding Playbook v1.0

**Total length:** ~5,500 words
**Status:** Operational runbook ready for Alok's first meeting with Sunil-bhaiya
**Companion artifacts:** brief, SAD, PRD, Epics List, UX Spec, Design Bundle, IR Report
**New PRD additions surfaced:** 2 (S4.14 Today's task screen, S4.15 Bulk CSV import for v1.5)

**This document is OPERATIONAL, not technical.** Amelia does not implement it. Alok executes it. The real work is in the room with Sunil-bhaiya, not in the codebase.

— John (PM, with Mary's strategic lens), 2026-04-11
