// =============================================================================
// ChatBubble — balance-scale layout chat message bubble.
//
// Ported from design bundle Widget 3 (balance-scale layout):
//   - Customer messages: LEFT aligned
//   - Shopkeeper messages: RIGHT aligned
//   - System messages: CENTER, brass thread divider
//
// Per P2.4 AC #6:
//   - Sender labels: "आप" for customer, "सुनील भैया" for shopkeeper
// Per P2.4 AC #7:
//   - Message types: text, voice note (inline player), image, system
//
// BINDING RULES enforced:
//   - ALL strings via AppStrings parameters (no hardcoded Devanagari)
//   - ALL colors via context.yugmaTheme (no hardcoded colors)
//   - Oxblood commit color MUST NOT appear in chat widgets (rule #7)
//   - Font refs via YugmaFonts (rule #5)
// =============================================================================

import 'package:flutter/material.dart';

import 'package:lib_core/src/locale/strings_base.dart';
import 'package:lib_core/src/models/message.dart';
import 'package:lib_core/src/theme/tokens.dart';
import 'package:lib_core/src/theme/yugma_theme_extension.dart';
import 'package:lib_core/src/components/voice_note_player.dart';

/// The delivery status of a message for UI rendering.
enum MessageDeliveryStatus {
  /// Message sent optimistically, not yet confirmed by server.
  pending,

  /// Message confirmed written to Firestore.
  delivered,

  /// Message read by the recipient (future — Sprint 4 P2.7).
  read,
}

/// A single chat bubble in the balance-scale layout.
///
/// Customer messages render LEFT, shopkeeper messages RIGHT, system messages
/// CENTER with a brass thread divider.
class ChatBubble extends StatelessWidget {
  /// Create a chat bubble.
  const ChatBubble({
    super.key,
    required this.message,
    required this.strings,
    required this.currentUserUid,
    this.deliveryStatus = MessageDeliveryStatus.delivered,
    this.onVoiceNotePlayPause,
    this.voiceNoteProgress,
    this.imageUrl,
  });

  /// The message to render.
  final Message message;

  /// Locale-resolved strings for sender labels.
  final AppStrings strings;

  /// Delivery status for optimistic UI indicators.
  final MessageDeliveryStatus deliveryStatus;

  /// The current customer's UID — used to determine alignment.
  final String currentUserUid;

  /// Called when a voice note play/pause is tapped.
  final ValueChanged<bool>? onVoiceNotePlayPause;

  /// Current voice note playback progress [0.0, 1.0], if applicable.
  final double? voiceNoteProgress;

  /// Image URL loader — called to resolve image URLs for image messages.
  final String? imageUrl;

  /// True if this message was sent by the current customer.
  bool get _isCustomerMessage => message.authorUid == currentUserUid;

  /// True if this is a system-generated message.
  bool get _isSystemMessage => message.authorRole == MessageAuthorRole.system;

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;

    if (_isSystemMessage) {
      return _buildSystemMessage(theme);
    }

    return _buildChatMessage(theme);
  }

  /// System messages — centered with brass thread accents.
  Widget _buildSystemMessage(YugmaThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: YugmaSpacing.s4,
        vertical: YugmaSpacing.s2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: theme.shopAccent.withValues(alpha: 0.3)),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: YugmaSpacing.s3),
            child: Text(
              message.textBody ?? '',
              style: theme.captionDeva.copyWith(
                color: theme.shopAccent,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Divider(color: theme.shopAccent.withValues(alpha: 0.3)),
          ),
        ],
      ),
    );
  }

  /// Customer and shopkeeper message bubbles — balance-scale layout.
  Widget _buildChatMessage(YugmaThemeExtension theme) {
    final isCustomer = _isCustomerMessage;

    // Balance-scale: customer LEFT, shopkeeper RIGHT
    final alignment =
        isCustomer ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    final mainAxisAlignment =
        isCustomer ? MainAxisAlignment.start : MainAxisAlignment.end;

    // Bubble colors — never use oxblood (shopCommit) per binding rule #7
    final bubbleColor = isCustomer
        ? theme.shopSurface
        : theme.shopPrimary.withValues(alpha: 0.08);
    final textColor = theme.shopTextPrimary;

    // Sender label
    final senderLabel = isCustomer ? strings.chatSenderYou : _shopkeeperLabel;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: YugmaSpacing.s4,
        vertical: YugmaSpacing.s1,
      ),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          // Sender label — small, above the bubble
          Padding(
            padding: const EdgeInsets.only(
              bottom: 2,
              left: 4,
              right: 4,
            ),
            child: Text(
              senderLabel,
              style: theme.captionDeva.copyWith(
                color: theme.shopTextMuted,
                fontSize: theme.isElderTier ? 14.0 : 11.0,
              ),
            ),
          ),
          // The bubble itself
          Row(
            mainAxisAlignment: mainAxisAlignment,
            children: [
              // Constrain bubble width to ~75% of screen
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Container(
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(YugmaRadius.lg),
                      topRight: const Radius.circular(YugmaRadius.lg),
                      bottomLeft: isCustomer
                          ? const Radius.circular(YugmaRadius.sm)
                          : const Radius.circular(YugmaRadius.lg),
                      bottomRight: isCustomer
                          ? const Radius.circular(YugmaRadius.lg)
                          : const Radius.circular(YugmaRadius.sm),
                    ),
                    boxShadow: YugmaShadows.card,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: YugmaSpacing.s3,
                    vertical: YugmaSpacing.s2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMessageContent(theme, textColor),
                      const SizedBox(height: YugmaSpacing.s1),
                      _buildTimestampRow(theme),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Resolve shopkeeper sender label based on author role.
  String get _shopkeeperLabel {
    switch (message.authorRole) {
      case MessageAuthorRole.bhaiya:
      case MessageAuthorRole.beta:
      case MessageAuthorRole.munshi:
        return strings.chatSenderBhaiya;
      case MessageAuthorRole.customer:
        return strings.chatSenderYou;
      case MessageAuthorRole.system:
        return '';
    }
  }

  /// Build the appropriate content widget based on message type.
  Widget _buildMessageContent(YugmaThemeExtension theme, Color textColor) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.textBody ?? '',
          style: theme.bodyDeva.copyWith(color: textColor),
        );

      case MessageType.voiceNote:
        return VoiceNotePlayerWidget(
          durationSeconds: message.voiceNoteDurationSeconds ?? 0,
          onPlayPause: onVoiceNotePlayPause,
          progress: voiceNoteProgress,
        );

      case MessageType.image:
        if (imageUrl != null && imageUrl!.isNotEmpty) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(YugmaRadius.md),
            child: Image.network(
              imageUrl!,
              width: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.broken_image_outlined,
                color: theme.shopTextMuted,
                size: 48,
              ),
            ),
          );
        }
        return Icon(
          Icons.image_outlined,
          color: theme.shopTextMuted,
          size: 48,
        );

      case MessageType.system:
        // Should not reach here — system messages are handled above.
        return Text(
          message.textBody ?? '',
          style: theme.captionDeva,
        );
    }
  }

  /// Timestamp row with optional delivery status indicator.
  Widget _buildTimestampRow(YugmaThemeExtension theme) {
    final timeStr = _formatTime(message.sentAt);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          timeStr,
          style: TextStyle(
            fontFamily: YugmaFonts.mono,
            fontSize: theme.isElderTier ? 13.0 : 10.0,
            color: theme.shopTextMuted,
          ),
        ),
        if (_isCustomerMessage) ...[
          const SizedBox(width: 4),
          _buildDeliveryIcon(theme),
        ],
      ],
    );
  }

  /// Delivery status icon — clock (pending), single check (delivered).
  Widget _buildDeliveryIcon(YugmaThemeExtension theme) {
    final size = theme.isElderTier ? 14.0 : 12.0;

    switch (deliveryStatus) {
      case MessageDeliveryStatus.pending:
        return Icon(
          Icons.access_time,
          size: size,
          color: theme.shopTextMuted,
        );
      case MessageDeliveryStatus.delivered:
        return Icon(
          Icons.check,
          size: size,
          color: theme.shopAccent,
        );
      case MessageDeliveryStatus.read:
        return Icon(
          Icons.done_all,
          size: size,
          color: theme.shopAccent,
        );
    }
  }

  /// Format DateTime to HH:MM display.
  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
