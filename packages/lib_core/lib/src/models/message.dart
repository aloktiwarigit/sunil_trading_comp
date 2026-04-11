// =============================================================================
// Message — Freezed model for chat messages in the Sunil-bhaiya Ka Kamra
// thread at:
//   /shops/{shopId}/chatThreads/{threadId}/messages/{messageId}
//
// Schema per SAD v1.0.4 §5 Message entity. Messages are immutable once sent
// (no update, no delete per SAD §6 security rule) — they are the historical
// record of the shopkeeper↔customer conversation attached to a Project.
// =============================================================================

import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';
part 'message.g.dart';

/// What kind of content this message carries.
enum MessageType {
  /// Plain text written by a customer or operator. `textBody` is set.
  @JsonValue('text')
  text,

  /// Voice note reference. `voiceNoteId` is set; audio lives in Firebase
  /// Storage at the path `shops/{shopId}/voice_notes/{voiceNoteId}.m4a`.
  /// Played inline in the chat UI via the bundled VoiceNotePlayer widget.
  @JsonValue('voice_note')
  voiceNote,

  /// Image attached to the conversation (photos of delivered almirahs,
  /// customer reference photos, etc.). `imageUrl` is set.
  @JsonValue('image')
  image,

  /// System-generated message (e.g., "Project state changed to committed",
  /// "udhaar opened", "delivery scheduled"). `textBody` is the rendered
  /// Devanagari sentence.
  @JsonValue('system')
  system,
}

/// Who sent the message. Mapped to PRD S4.1 / SAD §5 operator roles — these
/// are not generic "user / admin" values; they are the specific roles in a
/// multi-generational almirah shop family per Brief §5.
enum MessageAuthorRole {
  /// The customer side of the conversation (anonymous or phone-verified).
  /// Maps to PRD `anonymous` + `phoneVerified` auth tiers.
  @JsonValue('customer')
  customer,

  /// Sunil-bhaiya himself — the primary shopkeeper, owner of all customer
  /// relationships. Google Sign-In with role=shopkeeper.
  @JsonValue('bhaiya')
  bhaiya,

  /// The shopkeeper's son or nephew (Aditya in the playbook) — digital
  /// native, handles inventory entry, photo capture, day-to-day chat
  /// replies. Google Sign-In with role=son.
  @JsonValue('beta')
  beta,

  /// The shop's munshi — optional role, handles payments and udhaar ledger
  /// reconciliation. Google Sign-In with role=munshi.
  @JsonValue('munshi')
  munshi,

  /// Cloud Function-authored system message (state changes, reminders).
  @JsonValue('system')
  system,
}

/// Chat message in a Sunil-bhaiya Ka Kamra thread.
///
/// Immutable after create per SAD §6 rules. The `readByUids` array is the
/// ONE field that can be updated after write, and only by the system (not
/// directly by client code) via a dedicated ChatThreadSystemPatch flow —
/// Sprint 4 P2.7 will ship the read-tracking mechanism.
///
/// Field notes:
/// - `textBody` is set for `text` and `system` messages, null otherwise
/// - `voiceNoteId` is set for `voiceNote` messages only
/// - `voiceNoteDurationSeconds` is set alongside `voiceNoteId` for UI rendering
///   (waveform player needs the duration up front to avoid a second fetch)
/// - `imageUrl` is set for `image` messages only (catalog images are
///   referenced by publicId, not URL — this is for one-off customer
///   reference photos that do not go through Cloudinary)
@freezed
class Message with _$Message {
  /// Create a message document.
  const factory Message({
    required String messageId,
    required String shopId,
    required String threadId,
    required String projectId,
    required String authorUid,
    required MessageAuthorRole authorRole,
    required MessageType type,
    required DateTime sentAt,

    /// Present for `text` and `system` message types.
    String? textBody,

    /// Present for `voiceNote` message type. References
    /// `shops/{shopId}/voice_notes/{voiceNoteId}.m4a` in Firebase Storage.
    String? voiceNoteId,

    /// Duration of the voice note in seconds (5–60 per PRD B1.6 AC #2).
    /// Stored so the chat UI can render the waveform without fetching the
    /// audio first.
    int? voiceNoteDurationSeconds,

    /// Present for `image` message type. One-off image URL (customer
    /// reference photos, delivery confirmation shots). Catalog images use
    /// `MediaStore.getCatalogUrl(publicId)` instead.
    String? imageUrl,

    /// UIDs that have marked this message as read. Updated via a system
    /// patch, not by client code directly. Sprint 4 P2.7 wires this up.
    @Default(<String>[]) List<String> readByUids,
  }) = _Message;

  /// JSON round-trip for Firestore serialization.
  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

  const Message._();

  /// True iff this message has a renderable text body (text or system type).
  bool get hasText => type == MessageType.text || type == MessageType.system;

  /// True iff this message has an inline voice note for playback.
  bool get hasVoiceNote => type == MessageType.voiceNote && voiceNoteId != null;
}
