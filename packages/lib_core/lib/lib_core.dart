/// Yugma Dukaan shared core library.
///
/// Exports:
///   - The Three Adapters (AuthProvider, CommsChannel, MediaStore)
///   - Freezed data models (Shop, Project, etc.) with partition discipline
///   - Firestore repositories (partition-scoped write methods only)
///   - Theme + locale + feature flags
///   - Firebase client wrapper + shopId provider
///
/// **Partition import discipline (PRD Standing Rule 11 + I6.12):**
/// This barrel file re-exports ALL patch classes for convenience in tests
/// and Cloud Functions. App code (customer_app + shopkeeper_app) MUST NOT
/// use this barrel file — they MUST import the specific partition patch
/// classes directly from `src/models/project_patch.dart` with `show` clauses
/// that restrict the imported symbols to their partition only. The
/// `tools/audit_project_patch_imports.sh` CI script enforces this.
library lib_core;

// ---------- Adapters ----------
export 'src/adapters/auth_provider.dart';
export 'src/adapters/auth_provider_firebase.dart';
export 'src/adapters/auth_provider_msg91.dart';
export 'src/adapters/auth_provider_email_magic_link.dart';
export 'src/adapters/auth_provider_upi_only.dart';
export 'src/adapters/auth_provider_factory.dart';
export 'src/adapters/media_store.dart';
export 'src/adapters/media_store_cloudinary_firebase.dart';
export 'src/adapters/media_store_r2.dart';
export 'src/adapters/media_store_factory.dart';
export 'src/adapters/comms_channel.dart';
export 'src/adapters/comms_channel_firestore.dart';
export 'src/adapters/comms_channel_whatsapp.dart';
export 'src/adapters/comms_channel_factory.dart';

// ---------- Infrastructure ----------
export 'src/firebase_client.dart';
export 'src/shop_id_provider.dart';
export 'src/feature_flags/remote_config_loader.dart';
export 'src/feature_flags/feature_flags.dart';
export 'src/feature_flags/runtime_feature_flags.dart';
export 'src/feature_flags/kill_switch_listener.dart';

// ---------- Locale ----------
export 'src/locale/strings_base.dart';
export 'src/locale/strings_hi.dart';
export 'src/locale/strings_en.dart';
export 'src/locale/locale_resolver.dart';

// ---------- Theme (Phase 2.0 Wave 1) ----------
export 'src/theme/tokens.dart';
export 'src/theme/shop_theme_tokens.dart';
export 'src/theme/yugma_theme_extension.dart';

// ---------- Observability ----------
export 'src/observability/analytics_events.dart';
export 'src/observability/observability.dart';

// ---------- Models ----------
export 'src/models/shop.dart';
export 'src/models/customer.dart';
export 'src/models/line_item.dart';
export 'src/models/project.dart';
export 'src/models/chat_thread.dart';
export 'src/models/message.dart';
export 'src/models/udhaar_ledger.dart';
export 'src/models/operator.dart';
export 'src/models/inventory_sku.dart';
export 'src/models/curated_shortlist.dart';
export 'src/models/voice_note.dart';

// ---------- Partition patches (see library-level doc comment above) ----------
export 'src/models/project_patch.dart';
export 'src/models/chat_thread_patch.dart';
export 'src/models/udhaar_ledger_patch.dart';

// ---------- Repositories ----------
export 'src/repositories/project_repo.dart';
export 'src/repositories/chat_thread_repo.dart';
export 'src/repositories/udhaar_ledger_repo.dart';
export 'src/repositories/customer_repo.dart';
export 'src/repositories/operator_repo.dart';
export 'src/repositories/inventory_sku_repo.dart';
export 'src/repositories/curated_shortlist_repo.dart';
export 'src/repositories/voice_note_repo.dart';

// ---------- Components (Phase 2.1 — widget library) ----------
export 'src/components/bharosa_landing/bharosa_landing_barrel.dart';
export 'src/components/voice_note_player.dart';
export 'src/components/browse/browse_barrel.dart';
export 'src/components/chat/chat_barrel.dart';

// ---------- Services (orchestration over adapters + repositories) ----------
export 'src/services/phone_upgrade_coordinator.dart';
export 'src/services/session_bootstrap.dart';
export 'src/services/upi_intent_builder.dart';
