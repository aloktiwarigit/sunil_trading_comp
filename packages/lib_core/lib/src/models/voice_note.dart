// =============================================================================
// VoiceNote — Freezed model for /shops/{shopId}/voiceNotes/{voiceNoteId}.
//
// Schema per SAD §5 VoiceNote entity. VoiceNote is the core Bharosa pillar
// primitive — every voice-note-enabled screen (B1.2 landing greeting, B1.5
// SKU detail, B1.7 chat reply, B1.8 greeting update, B1.10 away banner)
// references these documents.
//
// **Audio file location:** Firebase Storage at
//   gs://yugma-dukaan-{env}.appspot.com/shops/{shopId}/voice_notes/{voiceNoteId}.m4a
// Uploaded via MediaStore.uploadVoiceNote (Phase 1.1). The Firestore doc
// itself holds ONLY metadata — the audio bytes are in Storage.
// =============================================================================

import 'package:freezed_annotation/freezed_annotation.dart';

part 'voice_note.freezed.dart';
part 'voice_note.g.dart';

/// The types of thing a voice note can be attached to — per SAD §5 schema.
enum VoiceNoteAttachment {
  /// Attached to an InventorySku document (played inline in B1.5).
  @JsonValue('sku')
  sku,

  /// Attached to a Project — shopkeeper's voice reply in a Project chat
  /// thread (B1.7). Also references the Project via messages sub-sub-
  /// collection.
  @JsonValue('project')
  project,

  /// Attached to a specific customer — the shopkeeper's voice memo ABOUT
  /// this customer (stored in customer_memory). Not a chat message.
  @JsonValue('customer')
  customer,

  /// Attached to the shop's presence status — "I'm at a wedding, back by
  /// 6 PM" pre-recorded away voice notes (B1.10).
  @JsonValue('absence_status')
  absenceStatus,

  /// Attached to the shop's landing (the greeting voice note every
  /// customer hears on first app open per B1.3).
  @JsonValue('shop_landing')
  shopLanding,
}

/// The operator who recorded a voice note. Subset of [OperatorRole] — only
/// `bhaiya` and `beta` record voice notes (munshi does not). Matches the
/// SAD §5 VoiceNote.authorRole field constraint.
enum VoiceNoteAuthorRole {
  /// Sunil-bhaiya himself — the primary voice the customer expects to hear.
  @JsonValue('bhaiya')
  bhaiya,

  /// The son / nephew — secondary voice for routine notes when bhaiya
  /// is away or busy.
  @JsonValue('beta')
  beta,
}

/// The voice note metadata document.
@freezed
class VoiceNote with _$VoiceNote {
  /// Construct a VoiceNote.
  const factory VoiceNote({
    required String voiceNoteId,
    required String shopId,

    /// UID of the Operator who recorded it.
    required String authorUid,

    /// Operator role at record time. Denormalized so the customer-side
    /// render doesn't need a second read into the operators collection
    /// just to show "आवाज़: सुनील भैया" vs "आवाज़: आदित्य (बेटा)".
    required VoiceNoteAuthorRole authorRole,

    /// Duration in seconds. PRD B1.6 AC #2 enforces [5, 60]. Stored up
    /// front so the waveform player can render without loading the audio.
    required int durationSeconds,

    /// Firebase Storage path (NOT a URL). Format:
    ///   shops/{shopId}/voice_notes/{voiceNoteId}.m4a
    /// Matches `MediaStore.uploadVoiceNote` path contract (Phase 1.1).
    /// The download URL is resolved lazily via `MediaStore.getVoiceNoteUrl`.
    required String audioStorageRef,

    /// Audio file size in bytes. Used for the S4.16 media-spend telemetry
    /// tile + cost forecasting per ADR-014.
    required int audioSizeBytes,

    /// What this voice note is attached to. Type-safe enum.
    required VoiceNoteAttachment attachmentType,

    /// ID of the attached entity (SKU ID, Project ID, customer UID, etc.)
    /// Resolution depends on [attachmentType].
    required String attachmentRefId,

    required DateTime recordedAt,

    /// Transcription of the voice note. NULL in v1 — deferred to v1.5+
    /// per Brief §10 (STT is not free-tier-friendly in 2026).
    String? transcript,
  }) = _VoiceNote;

  /// JSON round-trip for Firestore serialization.
  factory VoiceNote.fromJson(Map<String, dynamic> json) =>
      _$VoiceNoteFromJson(json);

  const VoiceNote._();

  /// True iff duration is within the PRD B1.6 AC #2 bounds [5, 60]. Used
  /// by the repo to double-check before writing, as a defense-in-depth
  /// layer above the security rule.
  bool get hasValidDuration => durationSeconds >= 5 && durationSeconds <= 60;

  /// True iff this voice note was recorded by Sunil-bhaiya himself (as
  /// opposed to his beta). Used by the landing greeting UI to decide
  /// whether to label as "स्वागत संदेश" (if bhaiya) vs "आदित्य का संदेश"
  /// (if beta — in the absence-presence fallback per B1.10).
  bool get isByBhaiya => authorRole == VoiceNoteAuthorRole.bhaiya;
}
