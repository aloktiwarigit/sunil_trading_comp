# Yugma Dukaan

> सुनील ट्रेडिंग कंपनी का डिजिटल दुकान — जहाँ हर शादी की पहली खुशी शुरू होती है।
>
> The digital storefront for **Sunil Trading Company**, an almirah shop in Ayodhya's Harringtonganj market. Built by **Yugma Labs**.

This monorepo contains the three components of the Yugma Dukaan platform plus the shared core library, security rules, Cloud Functions, and CI workflows.

---

## Repository structure

```
.
├── apps/
│   ├── customer_app/        # Flutter — what wedding families use
│   └── shopkeeper_app/      # Flutter — what Sunil-bhaiya & team use behind the counter
├── packages/
│   └── lib_core/            # Shared models, adapters, repositories, theme, locale
├── sites/
│   └── marketing/           # Astro static site (sunil-trading-company.yugmalabs.ai)
├── functions/               # TypeScript Cloud Functions (Firebase gen 2)
├── tools/                   # Synthetic shop_0 seeder, font subsetter, cost forecaster
├── .github/workflows/       # 5 CI pipelines (Flutter, marketing, functions, cross-tenant, deploy)
├── firestore.rules          # Per-shop security rules (see SAD §6)
├── firestore.indexes.json
├── storage.rules
├── firebase.json            # Firebase project config
├── .firebaserc              # Project aliases — dev / staging / prod
├── melos.yaml               # Dart workspace tooling
└── pubspec.yaml             # Workspace root pubspec
```

---

## The Five Truths (architectural foundation — see SAD §1)

1. **One Firebase project per environment** — `yugma-dukaan-dev`, `yugma-dukaan-staging`, `yugma-dukaan-prod`. Multi-tenant by `shopId` field on every document.
2. **Auth is layered, persistent, and behind a swappable adapter.** Anonymous browse → Phone OTP at commit → silent sign-in forever after via refresh token.
3. **Firestore is offline-first by default.** Designed for ≤30 reads per typical customer session.
4. **Decision Circle is a feature flag, NOT a schema foundation.** A Project works fully without any DecisionCircle document.
5. **Udhaar khaata is an accounting mirror.** Forbidden vocabulary (`interest`, `dueDate`, `overdueFee`, …) is enforced at the security rule layer per ADR-010.

## The Three Adapters (mandatory v1)

- **AuthProvider** — wraps Firebase Auth; swappable to MSG91 / email magic link / UPI-metadata-only without rewriting screens.
- **CommsChannel** — Firestore real-time chat default + WhatsApp `wa.me` deep link fallback.
- **MediaStore** — Cloudinary Free for catalog + Firebase Storage for voice notes; R2 stub for shop #25+.

---

## Quickstart

### Prerequisites

- Flutter 3.x (pinned in `.fvm/fvm_config.json` once added)
- Dart 3.x
- Node 22 LTS (for the marketing site and Cloud Functions)
- `melos` global: `dart pub global activate melos`
- Firebase CLI: `npm install -g firebase-tools`

### Bootstrap

```bash
melos bootstrap                  # Wires lib_core into both apps
cd functions && npm ci && cd ..
cd sites/marketing && npm ci && cd ../..
```

### Run the customer app

```bash
melos run dev:customer
```

### Run the shopkeeper app

```bash
melos run dev:shopkeeper
```

### Run the cross-tenant integrity test (the one that blocks every PR)

```bash
melos run test:cross-tenant
```

---

## Documentation

| Doc | What it is |
|---|---|
| [`_bmad-output/planning-artifacts/product-brief.md`](./_bmad-output/planning-artifacts/product-brief.md) | The why and what (Mary, v1.4) |
| [`_bmad-output/planning-artifacts/solution-architecture.md`](./_bmad-output/planning-artifacts/solution-architecture.md) | The how — 14 sections, 12 ADRs (Winston, v1.0.3) |
| [`_bmad-output/planning-artifacts/prd.md`](./_bmad-output/planning-artifacts/prd.md) | 59 stories across 6 epics (John, v1.0.4) |
| [`_bmad-output/planning-artifacts/epics-and-stories.md`](./_bmad-output/planning-artifacts/epics-and-stories.md) | Sprint plan + dependency graphs (v1.1) |
| [`_bmad-output/planning-artifacts/ux-spec.md`](./_bmad-output/planning-artifacts/ux-spec.md) | UX strategy + 34 state catalog (Sally) |
| [`_bmad-output/planning-artifacts/frontend-design-bundle/`](./_bmad-output/planning-artifacts/frontend-design-bundle/) | Workshop Almanac design system |
| [`_bmad-output/planning-artifacts/shopkeeper-onboarding-playbook.md`](./_bmad-output/planning-artifacts/shopkeeper-onboarding-playbook.md) | Day 1–30 ramp + post-Day-30 daily rhythm |

---

## License

Proprietary © Yugma Labs 2026. All rights reserved.
