// =============================================================================
// ChatController — Riverpod controller for the customer-side chat.
//
// Responsibilities:
//   1. Ensure ChatThread document exists for the project (create if missing)
//   2. Listen to real-time Firestore message stream (P2.4 AC #8)
//   3. Send text messages with optimistic UI (P2.5 AC #2, #3)
//   4. Paginate older messages — limit(20), infinite scroll (P2.4 AC #4)
//
// Per Standing Rule 11:
//   - ChatThread writes via ChatThreadParticipantPatch ONLY
//   - Message documents are written directly (immutable after create per SAD §6)
//
// Per P2.5 AC #4:
//   - Updates Project.lastMessagePreview + lastMessageAt + unreadCountForShopkeeper
//   - These are system-owned fields — in v1 the Cloud Function handles them.
//     The controller writes the Message only; the Cloud Function triggers
//     on new messages to update the Project and ChatThread system fields.
// =============================================================================

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';

/// State for the chat screen.
class ChatState {
  const ChatState({
    required this.messages,
    required this.pendingMessageIds,
    required this.thread,
    this.isLoadingOlder = false,
    this.hasOlderMessages = true,
  });

  /// All messages currently visible, ordered oldest-to-newest.
  final List<Message> messages;

  /// Message IDs that are pending Firestore confirmation (optimistic UI).
  final Set<String> pendingMessageIds;

  /// The ChatThread document, or null if not yet created.
  final ChatThread? thread;

  /// True while fetching older messages for pagination.
  final bool isLoadingOlder;

  /// False once we've loaded all messages (no more pagination).
  final bool hasOlderMessages;

  ChatState copyWith({
    List<Message>? messages,
    Set<String>? pendingMessageIds,
    ChatThread? thread,
    bool? isLoadingOlder,
    bool? hasOlderMessages,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      pendingMessageIds: pendingMessageIds ?? this.pendingMessageIds,
      thread: thread ?? this.thread,
      isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
      hasOlderMessages: hasOlderMessages ?? this.hasOlderMessages,
    );
  }
}

/// Family provider — one controller per projectId.
final chatControllerProvider = AsyncNotifierProvider.autoDispose
    .family<ChatController, ChatState, String>(
  ChatController.new,
);

class ChatController extends AutoDisposeFamilyAsyncNotifier<ChatState, String> {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _messagesSub;

  String get _projectId => arg;

  @override
  Future<ChatState> build(String arg) async {
    ref.onDispose(() {
      _messagesSub?.cancel();
    });

    final shopId = ref.read(shopIdProviderProvider).shopId;
    final firestore = FirebaseFirestore.instance;
    final authProvider = ref.read(authProviderInstanceProvider);
    final user = authProvider.currentUser;

    if (user == null) {
      return const ChatState(
        messages: [],
        pendingMessageIds: {},
        thread: null,
      );
    }

    // Ensure ChatThread exists (create if missing).
    final threadRef = firestore
        .collection('shops')
        .doc(shopId)
        .collection('chatThreads')
        .doc(_projectId);

    final threadSnap = await threadRef.get();
    ChatThread? thread;

    if (threadSnap.exists) {
      thread = ChatThread.fromJson(<String, dynamic>{
        ...threadSnap.data()!,
        'threadId': _projectId,
      });
    } else {
      // Create the chat thread document.
      final threadData = <String, dynamic>{
        'threadId': _projectId,
        'shopId': shopId,
        'projectId': _projectId,
        'customerUid': user.uid,
        'customerDisplayName': user.displayName ?? '',
        'participantUids': [user.uid],
        'createdAt': FieldValue.serverTimestamp(),
        'unreadCountForCustomer': 0,
        'unreadCountForShopkeeper': 0,
      };
      await threadRef.set(threadData);
      thread = ChatThread(
        threadId: _projectId,
        shopId: shopId,
        projectId: _projectId,
        customerUid: user.uid,
        customerDisplayName: user.displayName ?? '',
        participantUids: [user.uid],
        createdAt: DateTime.now(),
      );
    }

    // Reset customer unread count on open.
    final chatThreadRepo = ChatThreadRepo(
      firestore: firestore,
      shopIdProvider: ShopIdProvider(shopId),
    );
    await chatThreadRepo.applyParticipantPatch(
      _projectId,
      const ChatThreadParticipantPatch(unreadCountForCustomer: 0),
    );

    // Start listening to messages in real-time.
    _startMessageListener(firestore, shopId);

    // Fetch initial batch of messages.
    final initialMessages = await _fetchMessages(firestore, shopId);

    return ChatState(
      messages: initialMessages,
      pendingMessageIds: const {},
      thread: thread,
      hasOlderMessages: initialMessages.length >= 20,
    );
  }

  /// Send a text message with optimistic UI.
  Future<void> sendText(String text) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final authProvider = ref.read(authProviderInstanceProvider);
    final user = authProvider.currentUser;
    if (user == null) return;

    final shopId = ref.read(shopIdProviderProvider).shopId;
    final firestore = FirebaseFirestore.instance;

    final messageId = firestore.collection('_').doc().id;
    final now = DateTime.now();

    // Optimistic message — appears immediately with pending status.
    final optimisticMessage = Message(
      messageId: messageId,
      shopId: shopId,
      threadId: _projectId,
      projectId: _projectId,
      authorUid: user.uid,
      authorRole: MessageAuthorRole.customer,
      type: MessageType.text,
      sentAt: now,
      textBody: text,
    );

    // Update state optimistically.
    state = AsyncData(current.copyWith(
      messages: [...current.messages, optimisticMessage],
      pendingMessageIds: {...current.pendingMessageIds, messageId},
    ));

    // Write to Firestore.
    try {
      await firestore
          .collection('shops')
          .doc(shopId)
          .collection('chatThreads')
          .doc(_projectId)
          .collection('messages')
          .doc(messageId)
          .set({
        'messageId': messageId,
        'shopId': shopId,
        'threadId': _projectId,
        'projectId': _projectId,
        'authorUid': user.uid,
        'authorRole': 'customer',
        'type': 'text',
        'sentAt': FieldValue.serverTimestamp(),
        'textBody': text,
        'readByUids': <String>[],
      });

      // Mark as delivered — remove from pending.
      final updated = state.valueOrNull;
      if (updated != null) {
        final newPending = Set<String>.from(updated.pendingMessageIds)
          ..remove(messageId);
        state = AsyncData(updated.copyWith(pendingMessageIds: newPending));
      }
    } catch (_) {
      // On failure, the optimistic message stays with pending status.
      // The real-time listener will eventually reconcile if the write
      // succeeds on retry. For now, the clock icon remains visible.
    }
  }

  /// Load older messages (pagination — infinite scroll upward).
  Future<void> loadOlderMessages() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingOlder || !current.hasOlderMessages) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingOlder: true));

    final shopId = ref.read(shopIdProviderProvider).shopId;
    final firestore = FirebaseFirestore.instance;

    final oldestMessage =
        current.messages.isNotEmpty ? current.messages.first : null;

    Query<Map<String, dynamic>> query = firestore
        .collection('shops')
        .doc(shopId)
        .collection('chatThreads')
        .doc(_projectId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .limit(20);

    if (oldestMessage != null) {
      query = query.startAfter([oldestMessage.sentAt.toIso8601String()]);
    }

    final snap = await query.get();
    final olderMessages = snap.docs.map((doc) {
      return Message.fromJson(<String, dynamic>{
        ...doc.data(),
        'messageId': doc.id,
      });
    }).toList()
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));

    final merged = [...olderMessages, ...current.messages];

    state = AsyncData(current.copyWith(
      messages: merged,
      isLoadingOlder: false,
      hasOlderMessages: snap.docs.length >= 20,
    ));
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<List<Message>> _fetchMessages(
    FirebaseFirestore firestore,
    String shopId,
  ) async {
    final snap = await firestore
        .collection('shops')
        .doc(shopId)
        .collection('chatThreads')
        .doc(_projectId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .limit(20)
        .get();

    final messages = snap.docs.map((doc) {
      return Message.fromJson(<String, dynamic>{
        ...doc.data(),
        'messageId': doc.id,
      });
    }).toList()
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));

    return messages;
  }

  void _startMessageListener(
    FirebaseFirestore firestore,
    String shopId,
  ) {
    _messagesSub?.cancel();
    _messagesSub = firestore
        .collection('shops')
        .doc(shopId)
        .collection('chatThreads')
        .doc(_projectId)
        .collection('messages')
        .orderBy('sentAt')
        .limitToLast(20)
        .snapshots()
        .listen((snap) {
      final messages = snap.docs.map((doc) {
        return Message.fromJson(<String, dynamic>{
          ...doc.data(),
          'messageId': doc.id,
        });
      }).toList();

      final current = state.valueOrNull;
      if (current == null) return;

      // Reconcile: keep older messages from pagination, update recent 20.
      final olderMessages = current.messages
          .where((m) =>
              !messages.any((rm) => rm.messageId == m.messageId) &&
              !current.pendingMessageIds.contains(m.messageId))
          .toList();

      // Remove confirmed messages from pending set.
      final confirmedIds = messages.map((m) => m.messageId).toSet();
      final newPending = current.pendingMessageIds
          .where((id) => !confirmedIds.contains(id))
          .toSet();

      // Keep pending optimistic messages that haven't been confirmed yet.
      final pendingMessages = current.messages
          .where((m) => newPending.contains(m.messageId))
          .toList();

      final merged = [...olderMessages, ...messages, ...pendingMessages];

      state = AsyncData(current.copyWith(
        messages: merged,
        pendingMessageIds: newPending,
      ));
    });
  }
}
