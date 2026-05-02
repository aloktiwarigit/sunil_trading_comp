// =============================================================================
// ShopkeeperChatController — Riverpod controller for shopkeeper-side chat.
//
// Per S4.8:
//   AC #1: Chat screen with text input + voice note button (voice deferred)
//   AC #2: Text messages sent as authorRole: "bhaiya" (or beta/munshi)
//   AC #4: Price proposal sending for a specific line item
//
// Per Standing Rule 11:
//   - ChatThread writes via ChatThreadOperatorPatch ONLY
//   - Message documents written directly (immutable after create per SAD §6)
// =============================================================================

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';
import 'package:logging/logging.dart';

import 'package:shopkeeper_app/features/auth/role_gate.dart';
import 'package:shopkeeper_app/main.dart';

/// State for the shopkeeper chat screen.
class ShopkeeperChatState {
  const ShopkeeperChatState({
    required this.messages,
    required this.pendingMessageIds,
    this.isLoadingOlder = false,
    this.hasOlderMessages = true,
  });

  final List<Message> messages;
  final Set<String> pendingMessageIds;
  final bool isLoadingOlder;
  final bool hasOlderMessages;

  ShopkeeperChatState copyWith({
    List<Message>? messages,
    Set<String>? pendingMessageIds,
    bool? isLoadingOlder,
    bool? hasOlderMessages,
  }) {
    return ShopkeeperChatState(
      messages: messages ?? this.messages,
      pendingMessageIds: pendingMessageIds ?? this.pendingMessageIds,
      isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
      hasOlderMessages: hasOlderMessages ?? this.hasOlderMessages,
    );
  }
}

/// Family provider — one controller per projectId.
final shopkeeperChatControllerProvider = AsyncNotifierProvider.autoDispose
    .family<ShopkeeperChatController, ShopkeeperChatState, String>(
  ShopkeeperChatController.new,
);

class ShopkeeperChatController
    extends AutoDisposeFamilyAsyncNotifier<ShopkeeperChatState, String> {
  static final Logger _log = Logger('ShopkeeperChatController');
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _messagesSub;

  String get _projectId => arg;

  /// Map operator role to message author role.
  /// Falls back to bhaiya if operator data is unavailable (defensive).
  MessageAuthorRole get _authorRole {
    final op = ref.read(currentOperatorProvider);
    if (op == null) return MessageAuthorRole.bhaiya;
    return switch (op.role) {
      OperatorRole.bhaiya => MessageAuthorRole.bhaiya,
      OperatorRole.beta => MessageAuthorRole.beta,
      OperatorRole.munshi => MessageAuthorRole.munshi,
    };
  }

  /// String representation for Firestore document writes.
  String get _authorRoleString {
    final op = ref.read(currentOperatorProvider);
    if (op == null) return 'bhaiya';
    return op.role.name; // 'bhaiya', 'beta', 'munshi' — matches @JsonValue
  }

  @override
  Future<ShopkeeperChatState> build(String arg) async {
    ref.onDispose(() {
      _messagesSub?.cancel();
    });

    final shopId = ref.read(shopIdProviderProvider).shopId;
    final firestore = FirebaseFirestore.instance;

    // Start real-time listener.
    _startMessageListener(firestore, shopId);

    // Fetch initial messages.
    final messages = await _fetchMessages(firestore, shopId);

    // Phase 7a r6 (Codex r6 #1): reset the shopkeeper-side unread counter
    // on chat open. The Phase 7a updateMessagePreview Cloud Function
    // increments `chatThreads/{threadId}.unreadCountForShopkeeper` on
    // customer messages; without this reset the badge grows unboundedly
    // because the counter is never cleared anywhere else. Symmetric with
    // the customer-side reset that ChatScreen drives via
    // ChatThreadParticipantPatch(unreadCountForCustomer: 0).
    //
    // Wrapped in try/catch so a transient failure (network blip, rule
    // change in flight) does NOT block the chat from opening. The next
    // open attempt is idempotent and will succeed.
    try {
      final chatThreadRepo = ChatThreadRepo(
        firestore: firestore,
        shopIdProvider: ref.read(shopIdProviderProvider),
      );
      await chatThreadRepo.applyOperatorPatch(
        arg, // projectId == threadId per PRD P2.4 (1:1 chat per project)
        const ChatThreadOperatorPatch(unreadCountForShopkeeper: 0),
      );
    } catch (e, stack) {
      // Never block chat open. Log via the package logger if it surfaces;
      // operator can re-open the chat to retry.
      // ignore: avoid_print
      print('shopkeeper_chat_controller: unread reset failed: $e\n$stack');
    }

    return ShopkeeperChatState(
      messages: messages,
      pendingMessageIds: const {},
      hasOlderMessages: messages.length >= 20,
    );
  }

  /// Send a text message as shopkeeper (bhaiya role).
  Future<void> sendText(String text) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final shopId = ref.read(shopIdProviderProvider).shopId;
    final firestore = FirebaseFirestore.instance;
    final authProvider = ref.read(shopkeeperAuthProviderInstance);
    final user = authProvider.currentUser;
    if (user == null) return;

    final messageId = firestore.collection('_').doc().id;
    final now = DateTime.now();

    // Optimistic message.
    final optimistic = Message(
      messageId: messageId,
      shopId: shopId,
      threadId: _projectId,
      projectId: _projectId,
      authorUid: user.uid,
      authorRole: _authorRole,
      type: MessageType.text,
      sentAt: now,
      textBody: text,
    );

    state = AsyncData(current.copyWith(
      messages: [...current.messages, optimistic],
      pendingMessageIds: {...current.pendingMessageIds, messageId},
    ));

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
        'authorRole': _authorRoleString,
        'type': 'text',
        'sentAt': FieldValue.serverTimestamp(),
        'textBody': text,
        'readByUids': <String>[],
      });

      final updated = state.valueOrNull;
      if (updated != null) {
        final newPending = Set<String>.from(updated.pendingMessageIds)
          ..remove(messageId);
        state = AsyncData(updated.copyWith(pendingMessageIds: newPending));
      }
    } catch (e) {
      _log.warning('sendText failed: $e');
    }
  }

  /// Send a price proposal for a specific line item (C3.3 AC #2 + S4.8 AC #4).
  Future<void> sendPriceProposal({
    required String lineItemId,
    required int proposedPrice,
    required String skuName,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final shopId = ref.read(shopIdProviderProvider).shopId;
    final firestore = FirebaseFirestore.instance;
    final authProvider = ref.read(shopkeeperAuthProviderInstance);
    final user = authProvider.currentUser;
    if (user == null) return;

    final messageId = firestore.collection('_').doc().id;
    final now = DateTime.now();

    final optimistic = Message(
      messageId: messageId,
      shopId: shopId,
      threadId: _projectId,
      projectId: _projectId,
      authorUid: user.uid,
      authorRole: _authorRole,
      type: MessageType.priceProposal,
      sentAt: now,
      proposedPrice: proposedPrice,
      lineItemId: lineItemId,
    );

    state = AsyncData(current.copyWith(
      messages: [...current.messages, optimistic],
      pendingMessageIds: {...current.pendingMessageIds, messageId},
    ));

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
        'authorRole': _authorRoleString,
        'type': 'price_proposal',
        'sentAt': FieldValue.serverTimestamp(),
        'proposedPrice': proposedPrice,
        'lineItemId': lineItemId,
        'readByUids': <String>[],
      });

      final updated = state.valueOrNull;
      if (updated != null) {
        final newPending = Set<String>.from(updated.pendingMessageIds)
          ..remove(messageId);
        state = AsyncData(updated.copyWith(pendingMessageIds: newPending));
      }
      _log.info(
          'price proposal sent: lineItem=$lineItemId price=$proposedPrice');
    } catch (e) {
      _log.warning('sendPriceProposal failed: $e');
    }
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

    return snap.docs.map((doc) {
      final raw = doc.data();
      return Message.fromJson(<String, dynamic>{
        ...raw,
        'messageId': doc.id,
        'sentAt': _normalizeTimestamp(raw['sentAt']),
      });
    }).toList()
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
  }

  /// CR #1: normalize Firestore Timestamp → ISO8601 for Freezed.
  static Object? _normalizeTimestamp(Object? value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    return value;
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
        final raw = doc.data();
        return Message.fromJson(<String, dynamic>{
          ...raw,
          'messageId': doc.id,
          'sentAt': _normalizeTimestamp(raw['sentAt']),
        });
      }).toList();

      final current = state.valueOrNull;
      if (current == null) return;

      final confirmedIds = messages.map((m) => m.messageId).toSet();
      final newPending = current.pendingMessageIds
          .where((id) => !confirmedIds.contains(id))
          .toSet();
      final pendingMessages = current.messages
          .where((m) => newPending.contains(m.messageId))
          .toList();

      state = AsyncData(current.copyWith(
        messages: [...messages, ...pendingMessages],
        pendingMessageIds: newPending,
      ));
    });
  }
}
