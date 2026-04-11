// =============================================================================
// MediaStoreR2 — stub implementation for the Cloudflare R2 migration path.
//
// Per SAD ADR-014, this adapter is activated at shop #25+ when Cloudinary's
// 25-credit/month free tier becomes uneconomical across the tenant base.
// The swap is a Remote Config flip of `media_store_strategy` from
// `cloudinary_firebase` to `r2` — no code change, no app rebuild.
//
// This file exists in v1 so the interface contract is validated against a
// second implementation at compile time. All methods throw UnimplementedError
// per PRD I6.6 AC #4. Attempting to activate this strategy in production
// before the R2 credentials + worker + object-key schema are in place will
// FAIL LOUDLY — which is the correct behavior for a migration stub.
//
// The real implementation lands in v1.5 as part of the MediaStore migration
// playbook (SAD §10 cost forecasting model).
// =============================================================================

import 'media_store.dart';

/// R2 stub — throws [UnimplementedError] on every method until v1.5.
class MediaStoreR2 implements MediaStore {
  /// Create the stub. No arguments — the real implementation will take
  /// R2 credentials, a worker URL, and object-key prefix, but that's v1.5.
  const MediaStoreR2();

  static Never _unimplemented(String method) {
    throw UnimplementedError(
      '$method is not implemented on MediaStoreR2. This stub exists to '
      'validate the interface contract against a second implementation. '
      'Activating the r2 strategy in Remote Config before the real '
      'implementation lands will trip this error. See SAD ADR-014 for '
      'the migration plan.',
    );
  }

  @override
  Future<CatalogUploadResult> uploadCatalogImage({
    required List<int> bytes,
    required String shopId,
    required CatalogMediaType type,
    Map<String, String>? metadata,
  }) =>
      _unimplemented('uploadCatalogImage');

  @override
  String getCatalogUrl(String publicId, {String? transform}) =>
      _unimplemented('getCatalogUrl');

  @override
  Future<void> uploadVoiceNote({
    required List<int> bytes,
    required String shopId,
    required String voiceNoteId,
  }) =>
      _unimplemented('uploadVoiceNote');

  @override
  Future<String> getVoiceNoteUrl({
    required String shopId,
    required String voiceNoteId,
  }) =>
      _unimplemented('getVoiceNoteUrl');
}
