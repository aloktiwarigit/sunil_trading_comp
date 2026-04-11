// =============================================================================
// VoiceNoteRepo — /shops/{shopId}/voiceNotes/{voiceNoteId}.
//
// The Firestore-side metadata repo for VoiceNote documents. The actual
// audio bytes live in Firebase Storage and are handled by MediaStore
// (Phase 1.1). Callers orchestrate the two-step flow:
//
//   1. MediaStore.uploadVoiceNote(bytes, shopId, voiceNoteId)
//   2. VoiceNoteRepo.create(VoiceNote(...))
//
// The repo enforces PRD B1.6 AC #2 duration bounds [5, 60] client-side
// as a defense-in-depth check above the security rule.
//
// Consumed by:
//   - PRD B1.6 (shopkeeper records voice note on SKU)
//   - PRD B1.7 (shopkeeper records voice note in Project chat)
//   - PRD B1.8 (shopkeeper updates shop landing greeting voice note)
//   - PRD B1.10 (shopkeeper records away-banner voice note)
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import '../models/voice_note.dart';
import '../shop_id_provider.dart';

/// Normalized exceptions thrown by VoiceNoteRepo.
class VoiceNoteRepoException implements Exception {
  /// Wrap a code + message.
  const VoiceNoteRepoException(this.code, this.message);
  /// Stable error code.
  final String code;
  /// Human-readable message.
  final String message;
  @override
  String toString() => 'VoiceNoteRepoException($code): $message';
}

/// Repository for VoiceNote metadata documents.
class VoiceNoteRepo {
  /// Construct with Firestore + shopIdProvider.
  VoiceNoteRepo({
    required FirebaseFirestore firestore,
    required ShopIdProvider shopIdProvider,
  })  : _firestore = firestore,
        _shopIdProvider = shopIdProvider;

  final FirebaseFirestore _firestore;
  final ShopIdProvider _shopIdProvider;
  static final Logger _log = Logger('VoiceNoteRepo');

  /// PRD B1.6 AC #2 minimum duration.
  static const int minDurationSeconds = 5;

  /// PRD B1.6 AC #2 maximum duration.
  static const int maxDurationSeconds = 60;

  CollectionReference<Map<String, dynamic>> _collection() =>
      _firestore
          .collection('shops')
          .doc(_shopIdProvider.shopId)
          .collection('voiceNotes');

  /// Read one voice note metadata doc by ID. The audio URL is resolved
  /// separately via [MediaStore.getVoiceNoteUrl] using the stored
  /// `audioStorageRef`.
  Future<VoiceNote?> getById(String voiceNoteId) async {
    try {
      final snap = await _collection().doc(voiceNoteId).get();
      if (!snap.exists) return null;
      final raw = snap.data()!;
      return VoiceNote.fromJson(<String, dynamic>{
        ...raw,
        'voiceNoteId': voiceNoteId,
        'recordedAt': _normalizeTimestamp(raw['recordedAt']),
      });
    } on FirebaseException catch (e) {
      throw VoiceNoteRepoException(
        e.code,
        'Failed to read voice note $voiceNoteId: ${e.message ?? e.code}',
      );
    }
  }

  /// Bulk read voice notes by ID — used by B1.5 SKU detail to resolve
  /// `InventorySku.voiceNoteIds` into actual VoiceNote objects.
  /// Firestore whereIn cap of 10 — in practice SKUs have ≤3 voice notes.
  Future<List<VoiceNote>> getByIds(List<String> voiceNoteIds) async {
    if (voiceNoteIds.isEmpty) return const <VoiceNote>[];
    if (voiceNoteIds.length > 10) {
      throw const VoiceNoteRepoException(
        'too-many-ids',
        'getByIds accepts at most 10 voice note IDs per call',
      );
    }
    try {
      final snap = await _collection()
          .where(FieldPath.documentId, whereIn: voiceNoteIds)
          .get();
      final byId = <String, VoiceNote>{
        for (final doc in snap.docs)
          doc.id: VoiceNote.fromJson(<String, dynamic>{
            ...doc.data(),
            'voiceNoteId': doc.id,
            'recordedAt': _normalizeTimestamp(doc.data()['recordedAt']),
          }),
      };
      return voiceNoteIds
          .map((id) => byId[id])
          .whereType<VoiceNote>()
          .toList(growable: false);
    } on FirebaseException catch (e) {
      throw VoiceNoteRepoException(
        e.code,
        'Failed to read voice notes: ${e.message ?? e.code}',
      );
    }
  }

  /// Create a new voice note metadata doc. Caller must have already
  /// uploaded the audio file via MediaStore — the `audioStorageRef`
  /// field must point to an existing Firebase Storage object.
  ///
  /// Enforces the [5, 60] second duration invariant client-side.
  Future<void> create(VoiceNote voiceNote) async {
    if (!voiceNote.hasValidDuration) {
      throw VoiceNoteRepoException(
        'invalid-duration',
        'durationSeconds must be in [$minDurationSeconds, $maxDurationSeconds] '
        'per PRD B1.6 AC #2, got ${voiceNote.durationSeconds}',
      );
    }
    try {
      await _collection().doc(voiceNote.voiceNoteId).set(<String, dynamic>{
        ...voiceNote.toJson(),
        'recordedAt': FieldValue.serverTimestamp(),
      });
      _log.info(
        'voice note created: id=${voiceNote.voiceNoteId} '
        'duration=${voiceNote.durationSeconds}s attachment=${voiceNote.attachmentType.name}',
      );
    } on FirebaseException catch (e) {
      throw VoiceNoteRepoException(
        e.code,
        'Failed to create voice note ${voiceNote.voiceNoteId}: '
        '${e.message ?? e.code}',
      );
    }
  }

  /// List voice notes by attachment. Used by B1.5 SKU detail to find
  /// every voice note attached to a specific SKU in one query.
  /// **Read budget:** up to N reads where N is the number of voice notes
  /// on that attachment target (typically ≤3).
  Future<List<VoiceNote>> listByAttachment({
    required VoiceNoteAttachment attachmentType,
    required String attachmentRefId,
  }) async {
    try {
      final snap = await _collection()
          .where('attachmentType', isEqualTo: _attachmentJson(attachmentType))
          .where('attachmentRefId', isEqualTo: attachmentRefId)
          .orderBy('recordedAt', descending: true)
          .get();
      return snap.docs.map((doc) {
        final raw = doc.data();
        return VoiceNote.fromJson(<String, dynamic>{
          ...raw,
          'voiceNoteId': doc.id,
          'recordedAt': _normalizeTimestamp(raw['recordedAt']),
        });
      }).toList();
    } on FirebaseException catch (e) {
      throw VoiceNoteRepoException(
        e.code,
        'Failed to list voice notes by attachment: ${e.message ?? e.code}',
      );
    }
  }

  /// Map the VoiceNoteAttachment enum to its JSON value. Matches the
  /// @JsonValue annotations in voice_note.dart.
  static String _attachmentJson(VoiceNoteAttachment t) {
    switch (t) {
      case VoiceNoteAttachment.sku:
        return 'sku';
      case VoiceNoteAttachment.project:
        return 'project';
      case VoiceNoteAttachment.customer:
        return 'customer';
      case VoiceNoteAttachment.absenceStatus:
        return 'absence_status';
      case VoiceNoteAttachment.shopLanding:
        return 'shop_landing';
    }
  }

  /// Normalize Firestore Timestamp → ISO8601.
  static Object? _normalizeTimestamp(Object? value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    return value;
  }
}
