# lib_core

Shared Freezed models, adapters, repositories, theme, locale, and Firebase client wrapper for the Yugma Dukaan customer and shopkeeper apps.

## What lives here

```
lib/
├── lib_core.dart                    # Barrel export — public API surface
└── src/
    ├── adapters/                    # The Three Adapters (auth / comms / media)
    │   ├── auth_provider*.dart      # Firebase / MSG91 / Email / UPI-only
    │   ├── comms_channel*.dart      # Firestore real-time / WhatsApp wa.me
    │   └── media_store*.dart        # Cloudinary + Firebase Storage / R2 stub
    ├── models/                      # Freezed 3 data classes
    │   ├── shop.dart                # Shop document
    │   ├── customer.dart            # Customer profile
    │   ├── operator.dart            # Operator + OperatorRole (bhaiya/beta/munshi)
    │   ├── project.dart             # Project state machine
    │   ├── project_patch.dart       # Partition discipline (Standing Rule 11)
    │   ├── chat_thread.dart         # Sunil-bhaiya Ka Kamra thread
    │   ├── chat_thread_patch.dart   # Partition discipline
    │   ├── message.dart             # Chat messages with MessageAuthorRole
    │   ├── udhaar_ledger.dart       # Accounting mirror (ADR-010)
    │   ├── udhaar_ledger_patch.dart # Partition discipline
    │   ├── inventory_sku.dart       # SKUs + SkuCategory + SkuMaterial
    │   ├── curated_shortlist.dart   # 6 occasion shortlists (Sunil-bhaiya ki pasand)
    │   ├── line_item.dart           # Project line items
    │   └── voice_note.dart          # Voice note metadata (audio in Storage)
    ├── repositories/                # Typed write paths (no generic update Map)
    │   ├── project_repo.dart
    │   ├── chat_thread_repo.dart
    │   ├── udhaar_ledger_repo.dart
    │   ├── customer_repo.dart
    │   ├── operator_repo.dart
    │   ├── inventory_sku_repo.dart
    │   ├── curated_shortlist_repo.dart
    │   └── voice_note_repo.dart
    ├── feature_flags/               # Remote Config + real-time kill-switch
    │   ├── feature_flags.dart       # String constants
    │   ├── remote_config_loader.dart
    │   ├── runtime_feature_flags.dart  # Firestore-resident real-time subset
    │   └── kill_switch_listener.dart   # onSnapshot watcher with cached getters
    ├── locale/                      # Devanagari-first UI strings
    │   ├── strings_base.dart        # Abstract AppStrings (50 methods)
    │   ├── strings_hi.dart          # Devanagari source-of-truth
    │   ├── strings_en.dart          # English toggle target
    │   └── locale_resolver.dart     # Remote Config defaultLocale resolver
    ├── observability/               # Crashlytics + Analytics events
    │   ├── observability.dart
    │   └── analytics_events.dart    # 9 canonical events + session_restored
    ├── services/                    # Cross-cutting orchestration
    │   ├── phone_upgrade_coordinator.dart  # Anonymous → Phone UID merger
    │   └── session_bootstrap.dart   # Silent refresh-token sign-in
    ├── firebase_client.dart         # App Check + init wrapper
    └── shop_id_provider.dart        # Current tenant resolver
```

## The Three Adapters

All three live under `adapters/` and exist for elicitation-identified fragility mitigations (SAD §1 + ADR-002 / ADR-005 / ADR-006).

| Adapter | Interface | Default | Fallback | Selected by |
|---|---|---|---|---|
| **AuthProvider** | `auth_provider.dart` | Firebase (Anonymous + Phone + Google) | MSG91 / Email magic link / UPI-only stubs | Remote Config `auth_provider_strategy` (R8 / R12 mitigation) |
| **CommsChannel** | `comms_channel.dart` | Firestore real-time sub-sub-collection | `wa.me` deep link launcher (`ExternalConversationHandle`) | Remote Config `comms_channel_strategy` (R13 mitigation) |
| **MediaStore** | `media_store.dart` | Cloudinary catalog + Firebase Storage voice notes | Cloudflare R2 stub | Remote Config `media_store_strategy` (R3 mitigation, ADR-014) |

Each has a factory (`*_factory.dart`) that reads Remote Config at build time and returns the matching implementation. The Phase 1.3 `KillSwitchListener` supplies kill-switch probes so adapter writes can short-circuit in <5 seconds without waiting for the Remote Config fetch cycle (PRD I6.7 AC #7 real-time contract).

## Partition discipline (Standing Rule 11)

The Project / ChatThread / UdhaarLedger entities follow **sealed partition patches** enforced at compile time via Freezed. See `CONTRIBUTING.md` at the project root for the full rationale + field-level partition table.

**TL;DR:** customer_app imports only `*CustomerPatch`, shopkeeper_app imports only `*OperatorPatch`, Cloud Functions import only `*SystemPatch`. Cross-imports fail at `tools/audit_project_patch_imports.sh` in CI and at `test/fails_to_compile/*.dart` negative compilation tests.

## Feature flag model

Two separate channels with complementary responsibilities:

- **Remote Config** (`remote_config_loader.dart`) — slow / cosmetic flags with 1-hour minimum fetch: `decisionCircleEnabled`, `guestModeEnabled`, `voiceSearchEnabled`, `arPlacementEnabled`, `defaultLocale`.
- **Firestore `onSnapshot`** (`kill_switch_listener.dart`) — real-time billable kill-switch flags at `/shops/{shopId}/featureFlags/runtime`: `killSwitchActive`, `cloudinaryUploadsBlocked`, `firestoreWritesBlocked`, `authProviderStrategy`, `commsChannelStrategy`, `mediaStoreStrategy`, `otpAtCommitEnabled`.

Adapters consume the listener's synchronous `bool` getters via injected probe lambdas — no async state, no stale cache.

## Locale

The canonical source-of-truth language is **Hindi (Devanagari)** per Brief Constraint 4. Every user-facing string lives in `strings_hi.dart`; `strings_en.dart` is the derived English toggle target.

Both files implement the abstract `AppStrings` interface in `strings_base.dart`. The interface has ~50 getters + parameterized methods corresponding to UX Spec v1.1 §5.5 rows #1–50. A compilation failure in either implementation means a missing translation — the symmetry is a compile-time contract.

`LocaleResolver.resolve(remoteConfig, userOverride)` returns the active `AppStrings` instance based on Remote Config `defaultLocale` + user `shared_preferences` override. Per PRD I6.11, if Sprint 0 Constraint 15 capacity cannot be secured, the flag flips `"hi" → "en"` and the customer app boots with English-first strings + Hindi toggle.

Forbidden vocabulary lists (udhaar lending + mythic Sanskritized) are enforced by `test/locale/strings_test.dart` on every PR.

## Models and repos — quick guide

**Every repository method is shop-scoped via `ShopIdProvider`.** Never pass shopId as a parameter — it's resolved from the provider at call time so repos can't leak between tenants in tests.

**Every model uses Freezed 3** with `@JsonValue`-annotated enums for deterministic serialization. Nested Freezed classes (e.g., `OperatorPermissions`, `SkuDimensions`) serialize recursively via `build.yaml`'s `explicit_to_json: true` setting.

**Every repo normalizes Firebase errors** to a typed exception (`ProjectRepoException`, `CommsChannelException`, `MediaStoreException`, etc.) with a stable `code` string. Callers route on the code, not on `FirebaseException`.

## Testing

```bash
# All lib_core tests
flutter test

# Cross-tenant integrity (Dart shape test — fake_cloud_firestore)
flutter test test/cross_tenant_integrity_test.dart

# Locale forbidden vocabulary scan
flutter test test/locale/strings_test.dart

# Negative compilation tests (Standing Rule 11 enforcement)
# These are in test/fails_to_compile/ and fail the build if the
# customer_app imports a ProjectOperatorPatch, etc.
```

## Related docs

- `../../CONTRIBUTING.md` — Standing Rule 11, forbidden vocabulary, free-features-only, monorepo workflow
- `../../_bmad-output/planning-artifacts/solution-architecture.md` — SAD §5 schema, §6 rules, §7 Cloud Functions
- `../../_bmad-output/planning-artifacts/prd.md` — 67 stories + 11 Standing Rules preamble
- `../../docs/runbook/font-subset-build.md` — Devanagari font subset pipeline
