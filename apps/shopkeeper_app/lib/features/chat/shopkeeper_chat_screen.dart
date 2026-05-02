// =============================================================================
// ShopkeeperChatScreen — wraps lib_core ChatScreen for shopkeeper ops app.
//
// Per S4.8:
//   AC #1: Text input + voice note button (voice deferred to B1.7)
//   AC #2: Messages sent as authorRole: "bhaiya"
//   AC #4: Price proposal sending UI (bottom sheet)
//   AC #5: Operator name appears next to messages
//
// This screen also wires the "propose price" button that opens a
// bottom sheet for selecting a line item and entering a proposed price.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lib_core/lib_core.dart';

import 'package:shopkeeper_app/features/auth/auth_controller.dart';
import 'package:shopkeeper_app/features/chat/shopkeeper_chat_controller.dart';
import 'package:shopkeeper_app/features/orders/project_detail_screen.dart';
import 'package:shopkeeper_app/features/voice/voice_recorder_widget.dart';
import 'package:shopkeeper_app/main.dart';

/// Shopkeeper-side chat screen.
class ShopkeeperChatScreen extends ConsumerWidget {
  const ShopkeeperChatScreen({
    super.key,
    required this.projectId,
  });

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = const AppStringsHi();
    final chatAsync = ref.watch(shopkeeperChatControllerProvider(projectId));
    final authProvider = ref.read(shopkeeperAuthProviderInstance);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: YugmaColors.background,
        body: Center(
          child: Text(strings.opsAppNotAuthorized,
              style: TextStyle(fontFamily: YugmaFonts.devaBody)),
        ),
      );
    }

    // Generate order suffix.
    final orderSuffix = projectId.length >= 3
        ? projectId.substring(projectId.length - 3).toUpperCase()
        : projectId.toUpperCase();
    final threadTitle = strings.chatThreadTitleWithOrder(orderSuffix);

    return chatAsync.when(
      loading: () => Scaffold(
        backgroundColor: YugmaColors.background,
        appBar: AppBar(
          backgroundColor: YugmaColors.primary,
          foregroundColor: YugmaColors.textOnPrimary,
          title: Text(threadTitle,
              style: TextStyle(fontFamily: YugmaFonts.devaBody)),
        ),
        body: Center(
          child: CircularProgressIndicator(color: YugmaColors.primary),
        ),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: YugmaColors.background,
        body: Center(child: Text(err.toString())),
      ),
      data: (chatState) {
        final deliveryStatuses = <String, MessageDeliveryStatus>{};
        for (final msg in chatState.messages) {
          deliveryStatuses[msg.messageId] =
              chatState.pendingMessageIds.contains(msg.messageId)
                  ? MessageDeliveryStatus.pending
                  : MessageDeliveryStatus.delivered;
        }

        return Scaffold(
          backgroundColor: YugmaColors.background,
          body: Column(
            children: [
              // Chat screen takes most of the space
              Expanded(
                child: ChatScreen(
                  threadTitle: threadTitle,
                  strings: strings,
                  currentUserUid: currentUser.uid,
                  messages: chatState.messages,
                  deliveryStatuses: deliveryStatuses,
                  isLoadingOlder: chatState.isLoadingOlder,
                  onSendText: (text) {
                    ref
                        .read(shopkeeperChatControllerProvider(projectId)
                            .notifier)
                        .sendText(text);
                  },
                  onBack: () => context.pop(),
                ),
              ),
              // "Propose price" button bar
              _ProposePriceBar(
                projectId: projectId,
                strings: strings,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Bottom bar with "propose price" button.
class _ProposePriceBar extends ConsumerWidget {
  const _ProposePriceBar({
    required this.projectId,
    required this.strings,
  });

  final String projectId;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: YugmaColors.surface,
        border: Border(top: BorderSide(color: YugmaColors.divider)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: YugmaSpacing.s4,
        vertical: YugmaSpacing.s2,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // B1.7 AC #1: voice note button, always visible
            SizedBox(
              height: YugmaSpacing.s12,
              child: OutlinedButton.icon(
                onPressed: () => _showVoiceRecorder(context, ref),
                icon: const Icon(Icons.mic, size: 20),
                label: const Text('🎤'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: YugmaColors.primary,
                  side: BorderSide(color: YugmaColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(YugmaRadius.md),
                  ),
                ),
              ),
            ),
            const SizedBox(width: YugmaSpacing.s2),
            // Propose price button
            Expanded(
              child: SizedBox(
                height: YugmaSpacing.s12,
                child: OutlinedButton.icon(
                  onPressed: () => _showProposePriceSheet(context, ref),
                  icon: const Icon(Icons.local_offer_outlined, size: 20),
                  label: Text(strings.proposePriceButton),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: YugmaColors.accent,
                    side: BorderSide(color: YugmaColors.accent),
                    textStyle: TextStyle(
                      fontFamily: YugmaFonts.devaBody,
                      fontSize: YugmaTypeScale.body,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(YugmaRadius.md),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// B1.7 AC #1–6: open voice recorder, upload, create Message + VoiceNote doc.
  void _showVoiceRecorder(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: YugmaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(YugmaRadius.lg),
        ),
      ),
      builder: (ctx) => VoiceRecorderWidget(
        onCancel: () => Navigator.of(ctx).pop(),
        onSend: (result) async {
          Navigator.of(ctx).pop();

          final shopId = ref.read(shopIdProviderProvider).shopId;
          final authState = ref.read(opsAuthControllerProvider).value;
          final op = authState?.operator;
          if (op == null) return;

          final voiceNoteId = 'vn_${DateTime.now().millisecondsSinceEpoch}';

          try {
            // Step 1: Upload audio via shared MediaStore provider.
            final mediaStore = ref.read(mediaStoreProvider);
            await mediaStore.uploadVoiceNote(
              bytes: result.bytes,
              shopId: shopId,
              voiceNoteId: voiceNoteId,
            );

            // Step 2: Create VoiceNote metadata doc.
            final vnRepo = VoiceNoteRepo(
              firestore: FirebaseFirestore.instance,
              shopIdProvider: ShopIdProvider(shopId),
            );
            await vnRepo.create(VoiceNote(
              voiceNoteId: voiceNoteId,
              shopId: shopId,
              authorUid: op.uid,
              authorRole: op.isBhaiya
                  ? VoiceNoteAuthorRole.bhaiya
                  : VoiceNoteAuthorRole.beta,
              durationSeconds: result.durationSeconds,
              audioStorageRef: 'shops/$shopId/voice_notes/$voiceNoteId.m4a',
              audioSizeBytes: result.bytes.length,
              attachmentType: VoiceNoteAttachment.project,
              attachmentRefId: projectId,
              recordedAt: DateTime.now(),
            ));

            // Step 3: Create chat Message with type voiceNote.
            // B1.7 AC #4: message doc in chat thread.
            await FirebaseFirestore.instance
                .collection('shops')
                .doc(shopId)
                .collection('chatThreads')
                .doc(projectId)
                .collection('messages')
                .add(<String, dynamic>{
              'type': 'voice_note',
              'voiceNoteId': voiceNoteId,
              'authorUid': op.uid,
              'authorRole': 'bhaiya',
              'sentAt': FieldValue.serverTimestamp(),
            });

            // Phase 7b (post-deploy of updateMessagePreview CF): the
            // project-level lastMessagePreview / lastMessageAt fields are
            // now updated by the Firestore-trigger Cloud Function that
            // fires on message create. Client no longer writes these
            // fields directly. The CF also updates the chatThread doc and
            // increments the recipient-side unread counter; see
            // functions/src/update_message_preview.ts.
            //
            // Phase 7c will tighten the operator allowlist in
            // firestore.rules to remove `lastMessagePreview` /
            // `lastMessageAt` once this code is shipped and the staging
            // smoke test confirms the CF takes over.

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('आवाज़ नोट भेजा गया')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString())),
              );
            }
          }
        },
      ),
    );
  }

  void _showProposePriceSheet(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.read(projectDetailProvider(projectId));
    final project = projectAsync.valueOrNull;
    if (project == null || project.lineItems.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _PriceProposalSheet(
          lineItems: project.lineItems,
          strings: strings,
          onSend: (lineItemId, price) {
            // CR #4: safe lookup — line item may have been removed concurrently.
            final lineItem = project.lineItems
                .where((li) => li.lineItemId == lineItemId)
                .firstOrNull;
            if (lineItem == null) return;
            ref
                .read(shopkeeperChatControllerProvider(projectId).notifier)
                .sendPriceProposal(
                  lineItemId: lineItemId,
                  proposedPrice: price,
                  skuName: lineItem.skuName,
                );
            Navigator.of(sheetContext).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(strings.proposalSentConfirmation)),
            );
          },
        );
      },
    );
  }
}

/// Bottom sheet for selecting a line item and entering a proposed price.
class _PriceProposalSheet extends StatefulWidget {
  const _PriceProposalSheet({
    required this.lineItems,
    required this.strings,
    required this.onSend,
  });

  final List<LineItem> lineItems;
  final AppStrings strings;
  final void Function(String lineItemId, int price) onSend;

  @override
  State<_PriceProposalSheet> createState() => _PriceProposalSheetState();
}

class _PriceProposalSheetState extends State<_PriceProposalSheet> {
  String? _selectedLineItemId;
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // CR #3: rebuild on text changes so _canSend updates the button state.
    _priceController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: YugmaSpacing.s4,
        right: YugmaSpacing.s4,
        top: YugmaSpacing.s4,
        bottom: MediaQuery.of(context).viewInsets.bottom + YugmaSpacing.s4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Which item?" prompt
          Text(
            widget.strings.proposalSelectItemPrompt,
            style: TextStyle(
              fontFamily: YugmaFonts.devaBody,
              fontSize: YugmaTypeScale.bodyLarge,
              fontWeight: FontWeight.w600,
              color: YugmaColors.textPrimary,
            ),
          ),
          const SizedBox(height: YugmaSpacing.s3),
          // Line item selection
          ...widget.lineItems.map((item) {
            final isSelected = _selectedLineItemId == item.lineItemId;
            return Padding(
              padding: const EdgeInsets.only(bottom: YugmaSpacing.s2),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedLineItemId = item.lineItemId;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(YugmaSpacing.s3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? YugmaColors.primary.withValues(alpha: 0.08)
                        : YugmaColors.surface,
                    borderRadius: BorderRadius.circular(YugmaRadius.md),
                    border: Border.all(
                      color: isSelected
                          ? YugmaColors.primary
                          : YugmaColors.divider,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.skuName,
                          style: TextStyle(
                            fontFamily: YugmaFonts.devaBody,
                            fontSize: YugmaTypeScale.body,
                            color: YugmaColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '₹${item.unitPriceInr}',
                        style: TextStyle(
                          fontFamily: YugmaFonts.mono,
                          fontSize: YugmaTypeScale.caption,
                          color: YugmaColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: YugmaSpacing.s3),
          // Price input
          Text(
            widget.strings.proposalPriceInputLabel,
            style: TextStyle(
              fontFamily: YugmaFonts.devaBody,
              fontSize: YugmaTypeScale.body,
              color: YugmaColors.textSecondary,
            ),
          ),
          const SizedBox(height: YugmaSpacing.s2),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            style: TextStyle(
              fontFamily: YugmaFonts.mono,
              fontSize: YugmaTypeScale.bodyLarge,
            ),
            decoration: InputDecoration(
              prefixText: '₹ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(YugmaRadius.md),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(YugmaRadius.md),
                borderSide: BorderSide(color: YugmaColors.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: YugmaSpacing.s4),
          // Send button
          SizedBox(
            height: YugmaSpacing.s12,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canSend ? _handleSend : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: YugmaColors.primary,
                foregroundColor: YugmaColors.textOnPrimary,
                disabledBackgroundColor: YugmaColors.divider,
                textStyle: TextStyle(
                  fontFamily: YugmaFonts.devaBody,
                  fontSize: YugmaTypeScale.body,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(YugmaRadius.md),
                ),
              ),
              child: Text(widget.strings.proposalSendButton),
            ),
          ),
        ],
      ),
    );
  }

  bool get _canSend {
    if (_selectedLineItemId == null) return false;
    final price = int.tryParse(_priceController.text.trim());
    return price != null && price > 0;
  }

  void _handleSend() {
    final price = int.tryParse(_priceController.text.trim());
    if (_selectedLineItemId == null || price == null || price <= 0) return;
    widget.onSend(_selectedLineItemId!, price);
  }
}
