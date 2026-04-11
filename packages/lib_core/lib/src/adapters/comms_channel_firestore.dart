// =============================================================================
// CommsChannelFirestore — default CommsChannel implementation.
//
// Writes/reads Messages in the sub-sub-collection:
//   /shops/{shopId}/chatThreads/{threadId}/messages/{messageId}
//
// The thread is assumed to exist (created via ChatThreadRepo in Sprint 4
// P2.4). This adapter is strictly the message I/O layer; it does not create
// threads, does not manage participant membership, and does not update
// read-tracking state — all of those are separate concerns.
//
// Kill-switch integration: sendText / sendVoiceNote check the
// `firestore_writes_blocked` flag BEFORE any network call via an injected
// probe. The Phase 1.3 KillSwitchListener supplies the real probe in
// production via Firestore onSnapshot on the runtime feature flag doc.
// =============================================================================

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import '../models/message.dart';
import 'comms_channel.dart';

/// Default [CommsChannel] — Firestore real-time sub-sub-collection writes.
class CommsChannelFirestore implements CommsChannel {
  /// Create the Firestore-backed CommsChannel.
  ///
  /// [firestore] is the current Firebase project's Firestore instance.
  /// [isWriteKillSwitchActive] is the `firestore_writes_blocked` flag probe;
  /// defaults to a no-op that returns false for tests.
  CommsChannelFirestore({
    required FirebaseFirestore firestore,
    FutureOr<bool> Function()? isWriteKillSwitchActive,
  })  : _firestore = firestore,
        _isWriteKillSwitchActive =
            isWriteKillSwitchActive ?? _defaultKillSwitchProbe;

  final FirebaseFirestore _firestore;
  final FutureOr<bool> Function() _isWriteKillSwitchActive;

  static final Logger _log = Logger('CommsChannelFirestore');

  static bool _defaultKillSwitchProbe() => false;

  /// Collection reference for the messages sub-sub-collection of a thread.
  /// Path: `shops/{shopId}/chatThreads/{projectId}/messages`.
  /// Note: the deployed Firestore rules use `chatThreads` (camelCase) per
  /// `firestore.rules` line 157 — this must match or writes get
  /// permission-denied once rules are deployed for chat.
  CollectionReference<Map<String, dynamic>> _messagesCollection(
    String shopId,
    String projectId,
  ) {
    return _firestore
        .collection('shops')
        .doc(shopId)
        .collection('chatThreads')
        .doc(projectId)
        .collection('messages');
  }

  @override
  Future<ConversationHandle> openConversation({
    required String shopId,
    required String projectId,
  }) async {
    _validateIds(shopId: shopId, projectId: projectId);

    // Firestore backend: return a handle that keys send/observe calls.
    // Does NOT create the parent thread document — caller's responsibility
    // via ChatThreadRepo (Sprint 4 P2.4).
    return FirestoreConversationHandle(
      shopId: shopId,
      projectId: projectId,
    );
  }

  @override
  Future<void> sendText({
    required String shopId,
    required String projectId,
    required String authorUid,
    required MessageAuthorRole authorRole,
    required String text,
  }) async {
    _validateIds(shopId: shopId, projectId: projectId);
    _validateAuthor(authorUid: authorUid);

    if (text.isEmpty) {
      throw const CommsChannelException(
        CommsChannelErrorCode.sendFailed,
        'text must not be empty',
      );
    }

    // Kill-switch gate FIRST (per PRD I6.7 AC #7 — no network on block).
    final killed = await _isWriteKillSwitchActive();
    if (killed) {
      _log.warning(
        'sendText blocked: kill-switch active (shop=$shopId, project=$projectId)',
      );
      throw const CommsChannelException(
        CommsChannelErrorCode.killSwitchActive,
        'Firestore writes are currently blocked by the kill-switch flag.',
      );
    }

    final messageRef = _messagesCollection(shopId, projectId).doc();
    final message = <String, dynamic>{
      'messageId': messageRef.id,
      'shopId': shopId,
      'threadId': projectId,
      'projectId': projectId,
      'authorUid': authorUid,
      // MessageAuthorRole enum values already match their @JsonValue strings
      // exactly (`customer`, `bhaiya`, `beta`, `munshi`, `system`) so
      // `.name` is the right serialization.
      'authorRole': authorRole.name,
      'type': 'text',
      'textBody': text,
      'sentAt': FieldValue.serverTimestamp(),
      'readByUids': <String>[authorUid],
    };

    try {
      await messageRef.set(message);
      _log.info(
        'message sent: shop=$shopId, project=$projectId, id=${messageRef.id}',
      );
    } on FirebaseException catch (e) {
      throw CommsChannelException(
        _mapFirestoreError(e.code),
        'Firestore sendText failed: ${e.message ?? e.code}',
        e,
      );
    } on Object catch (e, st) {
      _log.warning('sendText failed with unexpected error: $e\n$st');
      throw CommsChannelException(
        CommsChannelErrorCode.unknown,
        'Unexpected error sending text: $e',
        e,
      );
    }
  }

  @override
  Future<void> sendVoiceNote({
    required String shopId,
    required String projectId,
    required String authorUid,
    required MessageAuthorRole authorRole,
    required String voiceNoteId,
    required int durationSeconds,
  }) async {
    _validateIds(shopId: shopId, projectId: projectId);
    _validateAuthor(authorUid: authorUid);

    if (voiceNoteId.isEmpty) {
      throw const CommsChannelException(
        CommsChannelErrorCode.sendFailed,
        'voiceNoteId must not be empty',
      );
    }
    if (durationSeconds < 5 || durationSeconds > 60) {
      throw CommsChannelException(
        CommsChannelErrorCode.sendFailed,
        'durationSeconds must be in [5, 60] per PRD B1.6 AC #2, '
        'got $durationSeconds',
      );
    }

    final killed = await _isWriteKillSwitchActive();
    if (killed) {
      throw const CommsChannelException(
        CommsChannelErrorCode.killSwitchActive,
        'Firestore writes are currently blocked by the kill-switch flag.',
      );
    }

    final messageRef = _messagesCollection(shopId, projectId).doc();
    final message = <String, dynamic>{
      'messageId': messageRef.id,
      'shopId': shopId,
      'threadId': projectId,
      'projectId': projectId,
      'authorUid': authorUid,
      'authorRole': authorRole.name,
      'type': 'voice_note',
      'voiceNoteId': voiceNoteId,
      'voiceNoteDurationSeconds': durationSeconds,
      'sentAt': FieldValue.serverTimestamp(),
      'readByUids': <String>[authorUid],
    };

    try {
      await messageRef.set(message);
      _log.info(
        'voice note message sent: shop=$shopId, project=$projectId, '
        'voiceNoteId=$voiceNoteId',
      );
    } on FirebaseException catch (e) {
      throw CommsChannelException(
        _mapFirestoreError(e.code),
        'Firestore sendVoiceNote failed: ${e.message ?? e.code}',
        e,
      );
    }
  }

  @override
  Stream<List<Message>> observeMessages({
    required String shopId,
    required String projectId,
  }) {
    _validateIds(shopId: shopId, projectId: projectId);

    return _messagesCollection(shopId, projectId)
        .orderBy('sentAt')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final raw = doc.data();
        final normalized = <String, dynamic>{
          ...raw,
          // Ensure messageId is set in case the doc was written without it
          // (defense-in-depth for out-of-band writes).
          'messageId': doc.id,
          // Firestore returns Timestamp for serverTimestamp writes; Message's
          // fromJson via Freezed expects a DateTime-parseable shape. We
          // convert here to keep the adapter's contract domain-neutral.
          'sentAt': _normalizeTimestamp(raw['sentAt']),
        };
        return Message.fromJson(normalized);
      }).toList();
    });
  }

  /// Normalize Firestore Timestamp to an ISO8601 string the Freezed JSON
  /// round-trip understands. Pending writes (before serverTimestamp
  /// resolves) arrive as null and fall back to the current time so the UI
  /// can render optimistically.
  static Object? _normalizeTimestamp(Object? value) {
    if (value == null) {
      return DateTime.now().toIso8601String();
    }
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    return value;
  }

  // ---------------------------------------------------------------------------
  // Validation + error mapping
  // ---------------------------------------------------------------------------

  void _validateIds({required String shopId, required String projectId}) {
    if (shopId.isEmpty) {
      throw const CommsChannelException(
        CommsChannelErrorCode.unauthorized,
        'shopId must not be empty',
      );
    }
    if (shopId.contains('/') || shopId.contains('..')) {
      throw CommsChannelException(
        CommsChannelErrorCode.unauthorized,
        'shopId contains illegal characters: $shopId',
      );
    }
    if (projectId.isEmpty) {
      throw const CommsChannelException(
        CommsChannelErrorCode.sendFailed,
        'projectId must not be empty',
      );
    }
    if (projectId.contains('/') || projectId.contains('..')) {
      throw CommsChannelException(
        CommsChannelErrorCode.sendFailed,
        'projectId contains illegal characters: $projectId',
      );
    }
  }

  void _validateAuthor({required String authorUid}) {
    if (authorUid.isEmpty) {
      throw const CommsChannelException(
        CommsChannelErrorCode.unauthorized,
        'authorUid must not be empty',
      );
    }
  }

  /// Map Firestore error codes to our normalized enum.
  /// Reference: https://firebase.google.com/docs/reference/js/firestore_.firestoreerror
  static CommsChannelErrorCode _mapFirestoreError(String code) {
    switch (code) {
      case 'not-found':
        return CommsChannelErrorCode.notFound;
      case 'permission-denied':
      case 'unauthenticated':
        return CommsChannelErrorCode.unauthorized;
      case 'unavailable':
      case 'deadline-exceeded':
      case 'cancelled':
        return CommsChannelErrorCode.network;
      case 'failed-precondition':
      case 'invalid-argument':
      case 'already-exists':
        return CommsChannelErrorCode.sendFailed;
      default:
        return CommsChannelErrorCode.unknown;
    }
  }
}
