// =============================================================================
// MediaStore — The second of the Three Adapters (R3 mitigation per ADR-006).
//
// Abstracts catalog image storage + voice note audio storage so the
// Cloudinary-to-Cloudflare-R2 migration path (SAD ADR-014, activated at
// shop #20+) does not require rewriting image-rendering code.
//
// Default implementation pairs:
//   - Cloudinary Free tier (25 credits/month) for catalog images
//   - Firebase Storage for voice notes (Firebase Storage free tier is generous)
//
// See SAD §1 "Three Adapters" paragraph for the architectural contract.
// See PRD I6.6 for the acceptance criteria this interface satisfies.
// See SAD §5 GoldenHourPhoto + VoiceNote entities for the Firestore shapes
// that hold references to what this adapter stores.
// =============================================================================

/// The category of catalog media being uploaded. Drives the Cloudinary
/// public_id naming convention and any per-category transformation defaults.
///
/// Note: voice notes are NOT a catalog media type — they have their own
/// dedicated `uploadVoiceNote` / `getVoiceNoteUrl` methods because their
/// storage backend (Firebase Storage) is different from catalog images
/// (Cloudinary) in the default implementation, and their access pattern
/// (inline playback in chat + SKU detail) is distinct from catalog browsing.
enum CatalogMediaType {
  /// Main photo for an InventorySku (the "hero" image shown in the curated
  /// shortlist card). Consumed by B1.4 / B1.5.
  skuPrimary,

  /// A raking-light "golden hour" photo for an SKU. References stored in
  /// `shops/{shopId}/golden_hour_photos/{photoId}` per SAD §5. Consumed by
  /// B1.5 via the `असली रूप दिखाइए` toggle.
  goldenHour,

  /// The shopkeeper's face photo shown on `BharosaLanding` (B1.2) and the
  /// marketing site hero (M5.1). Stored against `ShopThemeTokens.shopkeeperFaceUrl`.
  ///
  /// **D4 note:** in the current implementation of B1.2, if no face photo
  /// has been uploaded (consent pending), the landing renders the
  /// Devanagari-initial-circle fallback defined in the frontend-design-bundle.
  /// Upload is a pure config swap — no code change — when consent lands.
  shopkeeperFace,

  /// The shop's logo. Stored against `ShopThemeTokens.logoUrl`.
  shopLogo,

  /// Generic shop branding asset (banner, promotional image). Rarely used
  /// in v1; placeholder for v1.5 promotional engine.
  branding,
}

/// Result of a successful catalog image upload. Immutable — all fields are
/// `final`.
///
/// The [publicId] is what callers store in Firestore (on `GoldenHourPhoto`,
/// `ShopThemeTokens`, etc.). The [url] is a ready-to-render URL at the
/// default transformation (`q_auto,f_auto`); for custom transformations use
/// [MediaStore.getCatalogUrl] with the stored publicId.
class CatalogUploadResult {
  /// Create a result record. `publicId` and `url` are required; the
  /// dimension and size fields are best-effort (not every backend reports them).
  const CatalogUploadResult({
    required this.publicId,
    required this.url,
    this.width,
    this.height,
    this.sizeBytes,
  });

  /// Backend-specific stable identifier. For Cloudinary: the `public_id`
  /// (e.g., `shops/sunil-trading-company/catalog/sku_primary/abc123`).
  /// For R2: an equivalent object key.
  final String publicId;

  /// Default-transformation URL ready to hand to `Image.network`.
  final String url;

  /// Image width in pixels, if the backend reported it. Callers can use
  /// this for aspect-ratio placeholders to avoid layout shift on first paint.
  final int? width;

  /// Image height in pixels, if the backend reported it.
  final int? height;

  /// Uploaded size in bytes, for cost telemetry (S4.16 depends on this
  /// field — see PRD S4.16 AC for the counter-increment side effect).
  final int? sizeBytes;

  @override
  String toString() => 'CatalogUploadResult(publicId: $publicId, url: $url)';
}

/// Normalized error codes for MediaStore operations. Every implementation
/// MUST map its native errors to one of these so screens can route on a
/// stable enum instead of catching backend-specific exceptions.
enum MediaStoreErrorCode {
  /// The upload request reached the backend but the backend rejected it
  /// (bad file type, corrupt payload, validation failure).
  uploadFailed,

  /// The requested publicId / voice note id does not exist in the backend.
  notFound,

  /// Cloudinary 25-credit/month ceiling reached OR Firebase Storage 5 GB
  /// ceiling reached OR `mediaCostMonitor` Cloud Function (SAD §7 Function 7)
  /// has tripped its warning threshold. Callers should surface a friendly
  /// "cannot upload right now" message and queue the bytes for retry.
  quotaExhausted,

  /// Network failure — no connectivity, timeout, DNS, or transient HTTP error.
  network,

  /// App Check / Firestore rule rejected the caller. Indicates either a
  /// real auth bug or a tampered client.
  unauthorized,

  /// The `cloudinary_uploads_blocked` kill-switch flag is currently true
  /// (set by `killSwitchOnBudgetAlert` Cloud Function per SAD §7 Function 1).
  /// Upload is refused client-side BEFORE any network call, honoring PRD
  /// I6.7 AC #7 (<5s propagation from Firestore listener). Caller should
  /// surface a "अभी upload नहीं हो रहा" message and NOT retry automatically.
  killSwitchActive,

  /// The signed-upload Cloud Function for Cloudinary is not yet deployed.
  /// Phase 1 (Sprint 2 prep) returns this from `uploadCatalogImage`. Real
  /// signed upload lands in Sprint 2 alongside B1.2 when the Cloud Function
  /// deploys. Voice note uploads via Firebase Storage are NOT affected —
  /// they work from Phase 1.
  notYetWired,

  /// Underlying provider rejected the request for a reason we don't model.
  unknown,
}

/// Normalized exception thrown by MediaStore implementations.
class MediaStoreException implements Exception {
  /// Wrap a normalized error code and a human-readable message. The optional
  /// [cause] is the underlying backend exception for debugging / Crashlytics.
  const MediaStoreException(this.code, this.message, [this.cause]);

  /// Normalized error code callers can route on.
  final MediaStoreErrorCode code;

  /// Human-readable error description.
  final String message;

  /// Underlying backend exception (Firebase Storage, Cloudinary, etc.).
  final Object? cause;

  @override
  String toString() => 'MediaStoreException($code): $message';
}

/// The adapter interface itself.
///
/// Every implementation MUST honor these contracts:
///
///   1. Every method takes `shopId` as an explicit parameter — there is no
///      ambient shop state. This is non-negotiable for PRD Standing Rule 7
///      (Cloud Storage paths are shop-scoped) and for the cross-tenant
///      integrity test.
///   2. [getCatalogUrl] is a pure function — no network IO, no caching,
///      no ambient state. It just builds a URL from a publicId.
///   3. [uploadVoiceNote] uses the exact path convention
///      `gs://yugma-dukaan-{env}.appspot.com/shops/{shopId}/voice_notes/{voiceNoteId}.m4a`
///      per PRD I6.6 AC #6 and the locked Q2 decision.
///   4. Errors are normalized to [MediaStoreException] — implementations
///      MUST NOT leak backend-specific exceptions (`FirebaseException`,
///      Cloudinary HTTP errors, etc.) to callers.
///   5. Kill-switch flags (`cloudinary_uploads_blocked`) are checked BEFORE
///      any network call, so the <5s propagation budget in PRD I6.7 AC #7
///      is met without needing a retry.
abstract class MediaStore {
  /// Upload a catalog image.
  ///
  /// Returns a [CatalogUploadResult] whose [CatalogUploadResult.publicId]
  /// the caller stores in Firestore (on `GoldenHourPhoto`, `ShopThemeTokens`,
  /// or `InventorySku`) as the reference to this upload.
  ///
  /// May throw [MediaStoreException] with codes:
  ///   - [MediaStoreErrorCode.killSwitchActive] — `cloudinary_uploads_blocked` is true
  ///   - [MediaStoreErrorCode.quotaExhausted] — Cloudinary credits exhausted
  ///   - [MediaStoreErrorCode.network]
  ///   - [MediaStoreErrorCode.uploadFailed]
  ///   - [MediaStoreErrorCode.notYetWired] — Phase 1 default implementation
  ///     returns this until Sprint 2 deploys the signed-upload Cloud Function
  Future<CatalogUploadResult> uploadCatalogImage({
    required List<int> bytes,
    required String shopId,
    required CatalogMediaType type,
    Map<String, String>? metadata,
  });

  /// Build a transformation URL for a previously-uploaded catalog image.
  ///
  /// This is a pure function — no network IO. Implementations map
  /// [transform] to their backend's transformation syntax:
  ///
  ///   - Cloudinary: the string is embedded verbatim (e.g., `"q_auto,f_auto,w_400"`)
  ///   - R2: mapped to R2-equivalent query parameters where possible
  ///
  /// Passing `null` returns the default-transformation URL (equivalent to
  /// `"q_auto,f_auto"` under Cloudinary).
  String getCatalogUrl(String publicId, {String? transform});

  /// Upload a voice note audio file to shop-scoped Cloud Storage.
  ///
  /// Path contract (PRD I6.6 AC #6 + PRD Standing Rule 7 + locked Q2):
  ///   `gs://yugma-dukaan-{env}.appspot.com/shops/{shopId}/voice_notes/{voiceNoteId}.m4a`
  ///
  /// The [voiceNoteId] is the same ID used for the Firestore VoiceNote
  /// document under `shops/{shopId}/voice_notes/{voiceNoteId}` per SAD §5.
  /// Caller is responsible for generating the ID (ULID convention: `vn_<ulid>`).
  ///
  /// May throw [MediaStoreException] with codes:
  ///   - [MediaStoreErrorCode.network]
  ///   - [MediaStoreErrorCode.unauthorized] — Storage rule rejection
  ///   - [MediaStoreErrorCode.quotaExhausted] — Firebase Storage 5 GB ceiling
  ///   - [MediaStoreErrorCode.uploadFailed]
  Future<void> uploadVoiceNote({
    required List<int> bytes,
    required String shopId,
    required String voiceNoteId,
  });

  /// Get a download URL for a previously-uploaded voice note.
  ///
  /// The default implementation uses Firebase Storage's `getDownloadURL()`
  /// which returns a long-lived public URL appropriate for inline audio
  /// playback in the customer app chat screen and SKU detail screen.
  ///
  /// May throw [MediaStoreException] with codes:
  ///   - [MediaStoreErrorCode.notFound] — voice note doesn't exist
  ///   - [MediaStoreErrorCode.network]
  ///   - [MediaStoreErrorCode.unauthorized]
  Future<String> getVoiceNoteUrl({
    required String shopId,
    required String voiceNoteId,
  });
}
