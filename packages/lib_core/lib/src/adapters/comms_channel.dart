// =============================================================================
// CommsChannel — the third of the Three Adapters (R5 + R13 mitigation per
// SAD ADR-005).
//
// Abstracts the customer↔shopkeeper conversation surface so the v1 default
// (Firestore real-time chat, the "Sunil-bhaiya Ka Kamra" thread) can be
// swapped for a WhatsApp `wa.me` fallback without rewriting Project state
// or chat screen code.
//
// The two backends have fundamentally different paradigms:
//   - Firestore: full programmatic messaging (send, observe, multi-device)
//   - WhatsApp: one-shot launch into the native WhatsApp app with a
//     prefilled Hindi message; no programmatic send/observe after launch
//
// [openConversation] therefore returns a typed [ConversationHandle] union
// (sealed class with two variants) so the UI layer can `switch` on the
// backend type and route cleanly:
//   - FirestoreConversationHandle → navigate to in-app chat screen
//   - ExternalConversationHandle  → launch wa.me URL via url_launcher
//
// This explicit branch point honors the R13 mitigation path: if WhatsApp
// eats Firestore chat in production, flipping the `comms_channel_strategy`
// Remote Config flag to `whatsapp_wa_me` causes every caller to receive
// `ExternalConversationHandle` from [openConversation] and route to the
// launcher without any code change in the rest of the app.
//
// See PRD I6.5 for acceptance criteria.
// See SAD §5 ChatThread + Message + §7 Function 2 for the Firestore schema.
// See SAD ADR-005 for the architectural rationale.
// =============================================================================

import '../models/message.dart';

/// Typed handle returned by [CommsChannel.openConversation]. Sealed union
/// with two variants — UI callers MUST `switch` on the concrete type to
/// decide whether to render in-app chat or launch an external URL.
sealed class ConversationHandle {
  /// Common fields: every handle knows its shop and project.
  const ConversationHandle({
    required this.shopId,
    required this.projectId,
  });

  /// The shop that owns this conversation. Shop-scoped per PRD Standing Rule 7.
  final String shopId;

  /// The Project this conversation is attached to. In Firestore, this also
  /// equals the `threadId` per SAD §5 ChatThread schema (1:1 mapping).
  final String projectId;
}

/// In-app Firestore chat handle — the default backend. The UI layer opens
/// the bundled chat screen and calls [CommsChannel.sendText] /
/// [CommsChannel.sendVoiceNote] / [CommsChannel.observeMessages] for I/O.
class FirestoreConversationHandle extends ConversationHandle {
  /// Create a Firestore handle. The caller uses [shopId] + [projectId] to
  /// key all subsequent send/observe calls.
  const FirestoreConversationHandle({
    required super.shopId,
    required super.projectId,
  });

  /// The threadId is 1:1 with the Project per SAD §5 ChatThread schema.
  String get threadId => projectId;
}

/// External launcher handle — WhatsApp `wa.me` fallback. The UI layer calls
/// `url_launcher.launchUrl(launchUri)` and does NOT attempt to send or
/// observe via this adapter (those methods throw
/// [CommsChannelErrorCode.notSupported] on this backend).
class ExternalConversationHandle extends ConversationHandle {
  /// Create an external handle carrying a launch URL.
  const ExternalConversationHandle({
    required super.shopId,
    required super.projectId,
    required this.launchUri,
    required this.prefilledMessageHindi,
  });

  /// The URI to launch (e.g., `https://wa.me/919XXXXXXXXX?text=...`).
  final Uri launchUri;

  /// The Hindi prefilled message body that the external app will show to
  /// the user before they tap Send. Exposed so the customer app can preview
  /// the body in a confirmation dialog before launching WhatsApp.
  final String prefilledMessageHindi;
}

/// Normalized error codes for CommsChannel operations. Every implementation
/// MUST map its native errors to one of these so screens can route on a
/// stable enum instead of catching backend-specific exceptions.
enum CommsChannelErrorCode {
  /// The send request reached Firestore but the write failed.
  sendFailed,

  /// The thread (or its parent Project) does not exist. Usually means the
  /// caller forgot to create the thread via ChatThreadRepo before sending.
  notFound,

  /// Network failure — offline, timeout, DNS, etc.
  network,

  /// Firestore rule rejected the write (App Check failure, shopId mismatch,
  /// shopLifecycle != 'active', etc.).
  unauthorized,

  /// The `firestore_writes_blocked` kill-switch flag is active. Caller should
  /// surface a friendly "भेज नहीं पा रहे" message and NOT retry automatically.
  killSwitchActive,

  /// Method was called on a backend that doesn't support it. In v1 this
  /// means `sendText` / `sendVoiceNote` / `observeMessages` were called
  /// after `openConversation` returned an [ExternalConversationHandle].
  /// Indicates a caller bug (UI forgot to switch on the handle type).
  notSupported,

  /// Underlying provider rejected the request for a reason we don't model.
  unknown,
}

/// Normalized exception thrown by CommsChannel implementations.
class CommsChannelException implements Exception {
  /// Wrap a normalized code + human message + optional backend cause.
  const CommsChannelException(this.code, this.message, [this.cause]);

  /// Normalized error code callers can route on.
  final CommsChannelErrorCode code;

  /// Human-readable description.
  final String message;

  /// Underlying backend exception (FirebaseException, etc.) for debugging.
  final Object? cause;

  @override
  String toString() => 'CommsChannelException($code): $message';
}

/// The adapter interface itself.
///
/// Every implementation MUST honor these contracts:
///
///   1. Every method takes `shopId` + `projectId` as explicit parameters —
///      there is no ambient state. Shop-scoped per PRD Standing Rule 7.
///   2. [openConversation] does NOT create the parent ChatThread document.
///      That is the caller's job via [ChatThreadRepo] — Sprint 4 P2.4 adds
///      the create-if-missing method. Phase 1 adapter assumes the thread
///      either exists or will be created by the caller before sending.
///   3. [sendText] and [sendVoiceNote] check the kill-switch flag BEFORE
///      any network call, honoring PRD I6.7 AC #7 (<5s propagation from
///      Firestore onSnapshot listener).
///   4. Errors are normalized to [CommsChannelException] — implementations
///      MUST NOT leak backend-specific exceptions to callers.
///   5. [sendVoiceNote] assumes the audio file has ALREADY been uploaded
///      via [MediaStore.uploadVoiceNote]. The caller orchestrates the
///      two-step flow: MediaStore upload first, then CommsChannel send.
///   6. Calling [sendText] / [sendVoiceNote] / [observeMessages] on a
///      backend that can only produce [ExternalConversationHandle] throws
///      [CommsChannelErrorCode.notSupported].
abstract class CommsChannel {
  /// Open / get a handle for a conversation attached to a Project.
  /// Returns a sealed [ConversationHandle] union — callers MUST switch on
  /// the concrete type to branch between in-app chat and external launcher.
  Future<ConversationHandle> openConversation({
    required String shopId,
    required String projectId,
  });

  /// Send a text message.
  ///
  /// Firestore backend: creates a new Message document in
  /// `shops/{shopId}/chatThreads/{projectId}/messages/{messageId}` and
  /// updates the parent thread's system fields via [ChatThreadRepo].
  ///
  /// WhatsApp backend: throws [CommsChannelErrorCode.notSupported]. Callers
  /// that hold an [ExternalConversationHandle] should not call this method.
  ///
  /// May throw [CommsChannelException] with codes:
  ///   - [CommsChannelErrorCode.killSwitchActive]
  ///   - [CommsChannelErrorCode.sendFailed]
  ///   - [CommsChannelErrorCode.network]
  ///   - [CommsChannelErrorCode.unauthorized]
  ///   - [CommsChannelErrorCode.notSupported] (WhatsApp backend only)
  Future<void> sendText({
    required String shopId,
    required String projectId,
    required String authorUid,
    required MessageAuthorRole authorRole,
    required String text,
  });

  /// Send a voice note reference.
  ///
  /// IMPORTANT: the caller must FIRST upload the audio file via
  /// [MediaStore.uploadVoiceNote] and only then call this method with the
  /// resulting [voiceNoteId]. This adapter does NOT upload audio — it
  /// writes only the Message document that references the audio.
  ///
  /// [durationSeconds] must be in [5, 60] per PRD B1.6 AC #2.
  ///
  /// Firestore backend: creates a Message doc with `type: voiceNote`.
  /// WhatsApp backend: throws [CommsChannelErrorCode.notSupported].
  Future<void> sendVoiceNote({
    required String shopId,
    required String projectId,
    required String authorUid,
    required MessageAuthorRole authorRole,
    required String voiceNoteId,
    required int durationSeconds,
  });

  /// Real-time stream of messages in a conversation, newest at the bottom.
  ///
  /// Firestore backend: onSnapshot on the messages sub-sub-collection,
  /// ordered by `sentAt ascending`. The stream emits the full current list
  /// on every change — the UI diffs for animation.
  ///
  /// WhatsApp backend: throws [CommsChannelErrorCode.notSupported].
  ///
  /// The returned stream is single-subscription. Callers that need multiple
  /// listeners should wrap it in a broadcast stream or a Riverpod provider.
  Stream<List<Message>> observeMessages({
    required String shopId,
    required String projectId,
  });
}
