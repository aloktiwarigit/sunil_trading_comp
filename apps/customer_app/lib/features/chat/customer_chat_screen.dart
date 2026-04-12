// =============================================================================
// CustomerChatScreen — wires the lib_core ChatScreen with customer-specific
// send logic and Riverpod state management.
//
// Per P2.4 + P2.5: this is the customer_app-specific wrapper that:
//   1. Reads the ChatController (family provider keyed by projectId)
//   2. Passes real-time messages + delivery statuses to ChatScreen
//   3. Wires the onSendText callback to ChatController.sendText
//   4. Wires the onLoadOlder callback to ChatController.loadOlderMessages
//   5. Generates the thread title with order suffix (P2.4 AC #5)
//
// Per Standing Rule 11: this screen ONLY imports customer-safe patches.
// =============================================================================

import 'package:customer_app/features/chat/chat_controller.dart';
import 'package:customer_app/features/chat/read_tracking_controller.dart';
import 'package:customer_app/features/project/draft_controller.dart';
import 'package:customer_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lib_core/lib_core.dart';

/// Customer-side chat screen — wraps [ChatScreen] from lib_core with
/// customer-app-specific Riverpod wiring.
class CustomerChatScreen extends ConsumerStatefulWidget {
  /// Create the customer chat screen.
  const CustomerChatScreen({
    super.key,
    required this.projectId,
    required this.strings,
  });

  /// The project this chat thread is attached to.
  final String projectId;

  /// Locale-resolved strings.
  final AppStrings strings;

  @override
  ConsumerState<CustomerChatScreen> createState() =>
      _CustomerChatScreenState();
}

class _CustomerChatScreenState extends ConsumerState<CustomerChatScreen> {
  /// Guard to avoid redundant Firestore batch writes — markThreadAsRead is
  /// idempotent (arrayUnion) but we avoid wasteful repeat calls.
  bool _hasMarkedRead = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;
    final chatAsync = ref.watch(chatControllerProvider(widget.projectId));
    final authProvider = ref.read(authProviderInstanceProvider);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: theme.shopBackground,
        body: Center(
          child: Text(
            widget.strings.opsAppNotAuthorized,
            style: theme.bodyDeva,
          ),
        ),
      );
    }

    // Generate order suffix from projectId — last 3 chars uppercase.
    final orderSuffix = widget.projectId.length >= 3
        ? widget.projectId.substring(widget.projectId.length - 3).toUpperCase()
        : widget.projectId.toUpperCase();

    final threadTitle = widget.strings.chatThreadTitleWithOrder(orderSuffix);

    return chatAsync.when(
      loading: () => Scaffold(
        backgroundColor: theme.shopBackground,
        appBar: AppBar(
          backgroundColor: theme.shopSurface,
          title: Text(threadTitle, style: theme.bodyDeva),
          iconTheme: IconThemeData(color: theme.shopPrimary),
        ),
        body: Center(
          child: CircularProgressIndicator(color: theme.shopAccent),
        ),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: theme.shopBackground,
        appBar: AppBar(
          backgroundColor: theme.shopSurface,
          title: Text(threadTitle, style: theme.bodyDeva),
          iconTheme: IconThemeData(color: theme.shopPrimary),
        ),
        body: Center(
          child: Text(err.toString(), style: theme.bodyDeva),
        ),
      ),
      data: (chatState) {
        // P2.7: Mark all messages as read when the thread is first displayed.
        // markThreadAsRead uses arrayUnion — idempotent, but the guard avoids
        // redundant Firestore batch writes on every rebuild.
        if (!_hasMarkedRead && chatState.messages.isNotEmpty) {
          _hasMarkedRead = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(readTrackingProvider).markThreadAsRead(
                  projectId: widget.projectId,
                  currentUid: currentUser.uid,
                  messages: chatState.messages,
                );
          });
        }

        // Build delivery status map for optimistic UI.
        final deliveryStatuses = <String, MessageDeliveryStatus>{};
        for (final msg in chatState.messages) {
          if (chatState.pendingMessageIds.contains(msg.messageId)) {
            deliveryStatuses[msg.messageId] = MessageDeliveryStatus.pending;
          } else {
            deliveryStatuses[msg.messageId] = MessageDeliveryStatus.delivered;
          }
        }

        // C3.3: Build proposal metadata from draft line items.
        final draftState = ref.watch(draftControllerProvider).valueOrNull;
        final proposalMetadata = <String, ProposalDisplayMetadata>{};

        for (final msg in chatState.messages) {
          if (msg.isPriceProposal) {
            final lineItem = draftState?.lineItems
                .where((li) => li.lineItemId == msg.lineItemId)
                .firstOrNull;
            final isAccepted = lineItem?.finalPrice == msg.proposedPrice;
            proposalMetadata[msg.messageId] = ProposalDisplayMetadata(
              skuName: lineItem?.skuName ?? '',
              originalPrice: lineItem?.unitPriceInr,
              isAccepted: isAccepted,
            );
          }
        }

        return ChatScreen(
          threadTitle: threadTitle,
          strings: widget.strings,
          currentUserUid: currentUser.uid,
          messages: chatState.messages,
          deliveryStatuses: deliveryStatuses,
          isLoadingOlder: chatState.isLoadingOlder,
          onSendText: (text) {
            ref.read(chatControllerProvider(widget.projectId).notifier).sendText(text);
          },
          onLoadOlder: () {
            ref
                .read(chatControllerProvider(widget.projectId).notifier)
                .loadOlderMessages();
          },
          onBack: () => context.pop(),
          // C3.3: wire proposal acceptance.
          onAcceptProposal: (messageId) {
            ref
                .read(chatControllerProvider(widget.projectId).notifier)
                .acceptPriceProposal(messageId);
          },
          proposalMetadata: proposalMetadata,
        );
      },
    );
  }
}
