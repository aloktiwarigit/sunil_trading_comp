// =============================================================================
// MediaStoreCloudinaryFirebase — default MediaStore implementation.
//
// Pairing rationale (SAD ADR-006):
//   - Cloudinary Free (25 credits/month) for catalog images — transformation
//     pipeline, CDN delivery, and per-image cost visibility outweigh
//     Firebase Storage's simpler model for the catalog use case
//   - Firebase Storage for voice notes — 5 GB free tier is sufficient for
//     ~500 × 2 MB voice notes per shop, and the client SDK integrates
//     cleanly with the existing firebase_auth + firebase_app_check setup
//
// Phase 1 scope (Sprint 2 prep):
//   - Voice note upload + URL retrieval via Firebase Storage — WORKING
//   - Catalog URL builder (Cloudinary transformation syntax) — WORKING
//   - Catalog upload — throws MediaStoreErrorCode.notYetWired until the
//     `generateCloudinarySignature` Cloud Function deploys in Sprint 2
//     (the signed-upload preset requires a server-side secret)
//
// B1.2 (BharosaLanding) does NOT need catalog upload because the D4
// fallback (Devanagari-initial circle) is a pure Flutter widget. B1.3
// (greeting voice note) uses the Firebase Storage voice note path which
// IS working from Phase 1.
// =============================================================================

import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:logging/logging.dart';

import 'media_store.dart';

/// Default [MediaStore] — Cloudinary catalog + Firebase Storage voice notes.
class MediaStoreCloudinaryFirebase implements MediaStore {
  /// Create the default MediaStore implementation.
  ///
  /// [firebaseStorage] is the active Firebase Storage instance — use the
  /// default (current Firebase project) bucket. [cloudinaryCloudName] is the
  /// Cloudinary cloud_name used to build delivery URLs.
  /// [isUploadKillSwitchActive] is an optional probe that short-circuits
  /// catalog uploads when the `cloudinary_uploads_blocked` kill-switch flag
  /// is active — supplied by the Phase 1.3 KillSwitchListener in production.
  MediaStoreCloudinaryFirebase({
    required FirebaseStorage firebaseStorage,
    required String cloudinaryCloudName,
    FutureOr<bool> Function()? isUploadKillSwitchActive,
  })  : _firebaseStorage = firebaseStorage,
        _cloudinaryCloudName = cloudinaryCloudName,
        _isUploadKillSwitchActive =
            isUploadKillSwitchActive ?? _defaultKillSwitchProbe;

  final FirebaseStorage _firebaseStorage;
  final String _cloudinaryCloudName;
  final FutureOr<bool> Function() _isUploadKillSwitchActive;

  static final Logger _log = Logger('MediaStoreCloudinaryFirebase');

  /// Default kill-switch probe — returns false. Real kill-switch comes from
  /// the Phase 1.3 `KillSwitchListener` which watches
  /// `/shops/{shopId}/feature_flags/runtime` via Firestore onSnapshot.
  /// Callers inject their own probe via the constructor in production.
  static bool _defaultKillSwitchProbe() => false;

  // ---------------------------------------------------------------------------
  // Catalog images — Cloudinary
  // ---------------------------------------------------------------------------

  @override
  Future<CatalogUploadResult> uploadCatalogImage({
    required List<int> bytes,
    required String shopId,
    required CatalogMediaType type,
    Map<String, String>? metadata,
  }) async {
    // Check kill-switch FIRST per PRD I6.7 AC #7 — no network call if the
    // `cloudinary_uploads_blocked` flag is active.
    final killed = await _isUploadKillSwitchActive();
    if (killed) {
      _log.warning(
        'uploadCatalogImage blocked: kill-switch active (shop=$shopId)',
      );
      throw const MediaStoreException(
        MediaStoreErrorCode.killSwitchActive,
        'Cloudinary uploads are currently blocked by the kill-switch flag. '
        'This is a cost-protection circuit breaker — check the ops dashboard.',
      );
    }

    // F006 fix: use Firebase Storage as interim catalog upload path.
    // Cloudinary signed-upload Cloud Function is not yet deployed, so we
    // store images in Firebase Storage under /shops/{shopId}/catalog/{type}_{ts}
    // and return the download URL. The marketing site and customer app can
    // read these via the public download URL.
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = 'jpg';
      final path = 'shops/$shopId/catalog/${type.name}_$timestamp.$ext';
      final ref = _firebaseStorage.ref().child(path);

      final uploadTask = await ref.putData(
        Uint8List.fromList(bytes),
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'shopId': shopId,
            'type': type.name,
            if (metadata != null) ...metadata,
          },
        ),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      _log.info('uploadCatalogImage: stored in Firebase Storage ($path)');

      return CatalogUploadResult(
        publicId: path,
        secureUrl: downloadUrl,
        width: 0, // Not available without image decoding
        height: 0,
      );
    } catch (e) {
      _log.severe('uploadCatalogImage failed: $e');
      throw MediaStoreException(
        MediaStoreErrorCode.uploadFailed,
        'Catalog image upload failed: $e',
      );
    }
  }

  @override
  String getCatalogUrl(String publicId, {String? transform}) {
    // Cloudinary delivery URL format:
    //   https://res.cloudinary.com/{cloud_name}/image/upload/{transform}/{public_id}
    //
    // Default transformation (when caller passes null) is `q_auto,f_auto`
    // which delegates quality + format selection to Cloudinary's automatic
    // pipeline. Both are free-tier transformations.
    final effectiveTransform =
        (transform == null || transform.isEmpty) ? 'q_auto,f_auto' : transform;

    return 'https://res.cloudinary.com/$_cloudinaryCloudName/image/upload/'
        '$effectiveTransform/$publicId';
  }

  // ---------------------------------------------------------------------------
  // Voice notes — Firebase Storage
  // ---------------------------------------------------------------------------

  @override
  Future<void> uploadVoiceNote({
    required List<int> bytes,
    required String shopId,
    required String voiceNoteId,
  }) async {
    _validateShopScope(shopId);
    _validateVoiceNoteId(voiceNoteId);

    final ref = _voiceNoteRef(shopId, voiceNoteId);
    final payload = Uint8List.fromList(bytes);

    try {
      await ref.putData(
        payload,
        SettableMetadata(
          contentType: 'audio/mp4',
          customMetadata: <String, String>{
            'shopId': shopId,
            'voiceNoteId': voiceNoteId,
          },
        ),
      );
      _log.info(
        'voice note uploaded: shop=$shopId, id=$voiceNoteId, bytes=${bytes.length}',
      );
    } on FirebaseException catch (e) {
      throw MediaStoreException(
        _mapFirebaseStorageError(e.code),
        'Firebase Storage upload failed: ${e.message ?? e.code}',
        e,
      );
    } on Object catch (e, st) {
      _log.warning('voice note upload failed with unexpected error: $e\n$st');
      throw MediaStoreException(
        MediaStoreErrorCode.unknown,
        'Unexpected error uploading voice note: $e',
        e,
      );
    }
  }

  @override
  Future<String> getVoiceNoteUrl({
    required String shopId,
    required String voiceNoteId,
  }) async {
    _validateShopScope(shopId);
    _validateVoiceNoteId(voiceNoteId);

    final ref = _voiceNoteRef(shopId, voiceNoteId);

    try {
      final url = await ref.getDownloadURL();
      return url;
    } on FirebaseException catch (e) {
      // object-not-found is the specific Firebase Storage error code for
      // "the path you asked for doesn't exist". Distinguish it from other
      // errors so callers can show "नोट अभी नहीं है" vs "network error".
      if (e.code == 'object-not-found' || e.code == 'storage/object-not-found') {
        throw MediaStoreException(
          MediaStoreErrorCode.notFound,
          'Voice note $voiceNoteId not found in shop $shopId',
          e,
        );
      }
      throw MediaStoreException(
        _mapFirebaseStorageError(e.code),
        'Firebase Storage getDownloadURL failed: ${e.message ?? e.code}',
        e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Build the voice note Storage reference using the canonical shop-scoped path.
  ///
  /// Path contract per PRD I6.6 AC #6:
  ///   `shops/{shopId}/voice_notes/{voiceNoteId}.m4a`
  ///
  /// The bucket prefix (`gs://yugma-dukaan-{env}.appspot.com/`) is supplied
  /// by the `FirebaseStorage` instance the caller passed to the constructor —
  /// which is the current Firebase project's default bucket. Dev tests write
  /// to `yugma-dukaan-dev`, staging to staging, prod to prod.
  Reference _voiceNoteRef(String shopId, String voiceNoteId) {
    return _firebaseStorage.ref('shops/$shopId/voice_notes/$voiceNoteId.m4a');
  }

  /// Reject empty strings and path traversal attempts.
  void _validateShopScope(String shopId) {
    if (shopId.isEmpty) {
      throw const MediaStoreException(
        MediaStoreErrorCode.unauthorized,
        'shopId must not be empty',
      );
    }
    if (shopId.contains('/') || shopId.contains('..')) {
      throw MediaStoreException(
        MediaStoreErrorCode.unauthorized,
        'shopId contains illegal characters: $shopId',
      );
    }
  }

  void _validateVoiceNoteId(String voiceNoteId) {
    if (voiceNoteId.isEmpty) {
      throw const MediaStoreException(
        MediaStoreErrorCode.uploadFailed,
        'voiceNoteId must not be empty',
      );
    }
    if (voiceNoteId.contains('/') || voiceNoteId.contains('..')) {
      throw MediaStoreException(
        MediaStoreErrorCode.uploadFailed,
        'voiceNoteId contains illegal characters: $voiceNoteId',
      );
    }
  }

  /// Map Firebase Storage error codes to our normalized enum.
  /// Reference: https://firebase.google.com/docs/storage/web/handle-errors
  static MediaStoreErrorCode _mapFirebaseStorageError(String code) {
    switch (code) {
      case 'storage/object-not-found':
      case 'object-not-found':
        return MediaStoreErrorCode.notFound;
      case 'storage/unauthorized':
      case 'unauthorized':
      case 'storage/unauthenticated':
      case 'unauthenticated':
        return MediaStoreErrorCode.unauthorized;
      case 'storage/quota-exceeded':
      case 'quota-exceeded':
        return MediaStoreErrorCode.quotaExhausted;
      case 'storage/retry-limit-exceeded':
      case 'retry-limit-exceeded':
      case 'storage/canceled':
      case 'canceled':
        return MediaStoreErrorCode.network;
      case 'storage/invalid-checksum':
      case 'invalid-checksum':
      case 'storage/invalid-argument':
      case 'invalid-argument':
        return MediaStoreErrorCode.uploadFailed;
      default:
        return MediaStoreErrorCode.unknown;
    }
  }
}
