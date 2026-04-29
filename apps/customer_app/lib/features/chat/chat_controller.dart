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
import 'package:customer_app/features/project/draft_controller.dart';
import 'package:customer_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';
import 'package:logging/logging.dart';

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
final chatControllerProvider =
    AsyncNotifierProvider.autoDispose.family<ChatController, ChatState, String>(
  ChatController.new,
);

class ChatController extends AutoDisposeFamilyAsyncNotifier<ChatState, String> {
  static final Logger _log = Logger('ChatController');
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _messagesSub;

  /// CR #2: lock to prevent double-tap on Accept button.
  bool _acceptingProposal = false;

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

  /// C3.3: Accept a price proposal.
  ///
  /// 1. Reads the proposal message to get proposedPrice + lineItemId
  /// 2. Updates the target LineItem's finalPrice in the Project document
  /// 3. Recomputes totalAmount atomically
  /// 4. Sends a system message confirming acceptance
  ///
  /// The write to lineItems + totalAmount is a direct Firestore update
  /// (same pattern as DraftController._updateDraftLineItems) — security rules
  /// allow customer writes to these fields when state in ['draft', 'negotiating'].
  ///
  /// CR #1: wrapped in try/catch for error handling.
  /// CR #2: double-tap guard via _acceptingProposal lock.
  /// CR #6: system message uses AppStrings (locale-resolved) + INR formatting.
  /// CR #8: invalidates draftControllerProvider after success.
  /// CR #9: aborts if target lineItemId not found in project.
  Future<void> acceptPriceProposal(String messageId) async {
    // CR #2: prevent double-tap.
    if (_acceptingProposal) return;
    _acceptingProposal = true;

    try {
      final current = state.valueOrNull;
      if (current == null) return;

      // Find the proposal message.
      final proposalMsg = current.messages
          .where((m) => m.messageId == messageId && m.isPriceProposal)
          .firstOrNull;
      if (proposalMsg == null) return;

      final proposedPrice = proposalMsg.proposedPrice!;
      final targetLineItemId = proposalMsg.lineItemId!;

      final shopId = ref.read(shopIdProviderProvider).shopId;
      final firestore = FirebaseFirestore.instance;
      final authProvider = ref.read(authProviderInstanceProvider);
      final user = authProvider.currentUser;
      if (user == null) return;

      final projectRef = firestore
          .collection('shops')
          .doc(shopId)
          .collection('projects')
          .doc(_projectId);

      // Atomic update: read line items, set finalPrice, recompute total.
      var lineItemNotFound = false;
      await firestore.runTransaction((txn) async {
        final snap = await txn.get(projectRef);
        if (!snap.exists) return;

        final data = snap.data()!;
        final currentState = data['state'] as String?;

        // Only allow acceptance in draft or negotiating state.
        if (currentState != 'draft' && currentState != 'negotiating') return;

        final rawItems = data['lineItems'] as List<dynamic>? ?? <dynamic>[];
        final updatedItems = <Map<String, dynamic>>[];
        String? skuName;
        var totalAmount = 0;
        var lineItemFound = false;

        for (final raw in rawItems) {
          final item = Map<String, dynamic>.from(raw as Map);
          if (item['lineItemId'] == targetLineItemId) {
            item['finalPrice'] = proposedPrice;
            skuName = item['skuName'] as String?;
            lineItemFound = true;
          }
          // Recompute using finalPrice if set, otherwise unitPriceInr.
          final effectivePrice = (item['finalPrice'] as num?)?.toInt() ??
              (item['unitPriceInr'] as num?)?.toInt() ??
              0;
          final qty = (item['quantity'] as num?)?.toInt() ?? 1;
          totalAmount += effectivePrice * qty;
          updatedItems.add(item);
        }

        // CR #9: abort if the target line item was not found (e.g., removed).
        if (!lineItemFound) {
          _log.warning(
            'acceptPriceProposal: lineItemId=$targetLineItemId not found '
            'in project=$_projectId — aborting',
          );
          lineItemNotFound = true;
          return;
        }

        txn.update(projectRef, {
          'lineItems': updatedItems,
          'totalAmount': totalAmount,
          'state': 'negotiating',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Send a system message confirming the acceptance (AC #6).
        // CR #6: use locale-resolved string with INR formatting.
        final sysMsgRef = firestore
            .collection('shops')
            .doc(shopId)
            .collection('chatThreads')
            .doc(_projectId)
            .collection('messages')
            .doc();

        txn.set(sysMsgRef, {
          'messageId': sysMsgRef.id,
          'shopId': shopId,
          'threadId': _projectId,
          'projectId': _projectId,
          'authorUid': user.uid,
          'authorRole': 'system',
          'type': 'system',
          'sentAt': FieldValue.serverTimestamp(),
          // Hindi source-of-truth for system messages (persisted in Firestore,
          // not locale-switched at render time).
          'textBody':
              '₹${formatInr(proposedPrice)} पर ${skuName ?? ''} पक्का हुआ',
          'readByUids': <String>[],
        });
      });

      // Surface error to UI if the line item was removed while proposal
      // was pending (race condition between shopkeeper and customer).
      if (lineItemNotFound) {
        _log.warning('acceptPriceProposal: surfacing lineItemNotFound to UI');
        throw Exception('lineItemNotFound:$targetLineItemId');
      }

      // CR #8: invalidate draft controller so isAccepted updates.
      ref.invalidate(draftControllerProvider);

      _log.info('price proposal accepted: messageId=$messageId');
    } catch (e) {
      // CR #1: log the error. The Accept button remains enabled so the user
      // can retry. Emit a warning-level log for Crashlytics breadcrumbs.
      _log.warning('acceptPriceProposal failed: $e');
      Observability.crashlytics.log('acceptPriceProposal failed: $e');
    } finally {
      _acceptingProposal = false;
    }
  }

  /// Load older messages (pagination — infinite scroll upward).
  Future<void> loadOlderMessages() async {
    final current = state.valueOrNull;
    if (current == null ||
        current.isLoadingOlder ||
        !current.hasOlderMessages) {
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
