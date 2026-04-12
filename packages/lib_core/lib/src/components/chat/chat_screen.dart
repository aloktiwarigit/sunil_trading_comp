// =============================================================================
// ChatScreen — the full "Sunil-bhaiya Ka Kamra" chat screen.
//
// Per P2.4:
//   AC #4: Messages oldest-to-newest, paginated limit(20), infinite scroll
//   AC #5: Thread title: "सुनील भैया का कमरा — आपका ऑर्डर #<suffix>"
//   AC #9: Balance-scale layout: customer left, shopkeeper right, brass center
//
// This is a presentation-only widget. Message data and send logic are
// injected via parameters — the consuming app (customer_app) wires up the
// Riverpod controller and Firestore stream.
//
// Per P2.5:
//   AC #1: Text input at bottom with Devanagari placeholder
//   AC #2: Send button sends via the onSendText callback
//   AC #3: Optimistic UI — pending messages shown with clock icon
// =============================================================================

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:lib_core/src/locale/strings_base.dart';
import 'package:lib_core/src/models/message.dart';
import 'package:lib_core/src/theme/tokens.dart';
import 'package:lib_core/src/theme/yugma_theme_extension.dart';
import 'package:lib_core/src/components/chat/chat_bubble.dart';

/// The full chat screen with message list + input bar.
///
/// This widget is app-agnostic — it receives messages and callbacks,
/// does NOT directly depend on Firestore or Riverpod. The consuming
/// app wires up the data layer.
class ChatScreen extends StatefulWidget {
  /// Create the chat screen.
  const ChatScreen({
    super.key,
    required this.threadTitle,
    required this.strings,
    required this.currentUserUid,
    required this.messages,
    this.deliveryStatuses = const {},
    this.onSendText,
    this.onLoadOlder,
    this.isLoadingOlder = false,
    this.onBack,
  });

  /// Thread title — e.g., "सुनील भैया का कमरा — आपका ऑर्डर #A3F".
  final String threadTitle;

  /// Locale-resolved strings.
  final AppStrings strings;

  /// The current user's UID for message alignment.
  final String currentUserUid;

  /// The messages to display, ordered oldest-to-newest.
  final List<Message> messages;

  /// Map of messageId → delivery status for optimistic UI.
  final Map<String, MessageDeliveryStatus> deliveryStatuses;

  /// Called when the user submits a text message.
  final ValueChanged<String>? onSendText;

  /// Called when the user scrolls to the top to load older messages.
  final VoidCallback? onLoadOlder;

  /// True if older messages are currently being fetched.
  final bool isLoadingOlder;

  /// Called when back navigation is requested.
  final VoidCallback? onBack;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-scroll to bottom when new messages arrive.
    if (widget.messages.length > oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          unawaited(
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: YugmaMotion.fast,
              curve: YugmaMotion.standard,
            ),
          );
        }
      });
    }
  }

  void _onScroll() {
    // Infinite scroll — load older messages when near the top.
    if (_scrollController.position.pixels <=
        _scrollController.position.minScrollExtent + 50) {
      if (!widget.isLoadingOlder && widget.onLoadOlder != null) {
        widget.onLoadOlder!();
      }
    }
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    widget.onSendText?.call(text);
    _textController.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;

    return Scaffold(
      backgroundColor: theme.shopBackground,
      appBar: _buildAppBar(theme),
      body: Column(
        children: [
          // Brass thread center line decoration
          Container(
            height: 1,
            color: theme.shopAccent.withValues(alpha: 0.2),
          ),
          // Message list
          Expanded(
            child: _buildMessageList(theme),
          ),
          // Input bar
          _buildInputBar(theme),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(YugmaThemeExtension theme) {
    return AppBar(
      backgroundColor: theme.shopSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      leading: widget.onBack != null
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: theme.shopPrimary),
              onPressed: widget.onBack,
            )
          : null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.threadTitle,
            style: theme.bodyDeva.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: theme.isElderTier ? 18.0 : 15.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      iconTheme: IconThemeData(color: theme.shopPrimary),
    );
  }

  Widget _buildMessageList(YugmaThemeExtension theme) {
    if (widget.messages.isEmpty) {
      return Center(
        child: Text(
          widget.strings.chatInputPlaceholder,
          style: theme.bodyDeva.copyWith(color: theme.shopTextMuted),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: YugmaSpacing.s2),
      itemCount: widget.messages.length + (widget.isLoadingOlder ? 1 : 0),
      itemBuilder: (context, index) {
        if (widget.isLoadingOlder && index == 0) {
          return Padding(
            padding: const EdgeInsets.all(YugmaSpacing.s4),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.shopAccent,
                ),
              ),
            ),
          );
        }

        final msgIndex = widget.isLoadingOlder ? index - 1 : index;
        final message = widget.messages[msgIndex];
        final status = widget.deliveryStatuses[message.messageId] ??
            MessageDeliveryStatus.delivered;

        return ChatBubble(
          message: message,
          strings: widget.strings,
          currentUserUid: widget.currentUserUid,
          deliveryStatus: status,
        );
      },
    );
  }

  Widget _buildInputBar(YugmaThemeExtension theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.shopSurface,
        boxShadow: YugmaShadows.card,
      ),
      padding: EdgeInsets.only(
        left: YugmaSpacing.s3,
        right: YugmaSpacing.s2,
        top: YugmaSpacing.s2,
        bottom: MediaQuery.of(context).padding.bottom + YugmaSpacing.s2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Text input field — Devanagari placeholder per P2.5 AC #1
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: theme.shopBackground,
                borderRadius: BorderRadius.circular(YugmaRadius.xl),
                border: Border.all(
                  color: theme.shopDivider,
                ),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: theme.bodyDeva,
                decoration: InputDecoration(
                  hintText: widget.strings.chatInputPlaceholder,
                  hintStyle:
                      theme.bodyDeva.copyWith(color: theme.shopTextMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: YugmaSpacing.s4,
                    vertical: YugmaSpacing.s2,
                  ),
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
          ),
          const SizedBox(width: YugmaSpacing.s2),
          // Send button
          SizedBox(
            width: theme.tapTargetMin,
            height: theme.tapTargetMin,
            child: Material(
              color: theme.shopPrimary,
              borderRadius: BorderRadius.circular(YugmaRadius.pill),
              child: InkWell(
                borderRadius: BorderRadius.circular(YugmaRadius.pill),
                onTap: _handleSend,
                child: Icon(
                  Icons.send_rounded,
                  color: theme.shopTextOnPrimary,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
