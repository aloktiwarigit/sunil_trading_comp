// =============================================================================
// ProjectDetailScreen — S4.7 full project view for shopkeeper.
//
// Per S4.7:
//   AC #1: Single scroll — state badge, total, line items, customer info,
//          chat preview, action buttons
//   AC #2: Customer memory section (read-only in S4.7; editable in S4.9)
//   AC #3: Quick state transition buttons contextual to current state
//   AC #4: Chat thread expand opens full chat (S4.8)
//
// Edge cases:
//   #1: No customer memory → "नया ग्राहक" placeholder
//   #2: 50+ messages → pagination on expand (handled by ChatScreen)
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lib_core/lib_core.dart';

/// Provider for a single project, streamed by ID.
final projectDetailProvider =
    StreamProvider.autoDispose.family<Project?, String>((ref, projectId) {
  final firestore = FirebaseFirestore.instance;
  const shopId = 'sunil-trading-company';

  return firestore
      .collection('shops')
      .doc(shopId)
      .collection('projects')
      .doc(projectId)
      .snapshots()
      .map((snap) {
    if (!snap.exists) return null;
    return Project.fromJson(<String, dynamic>{
      ...snap.data()!,
      'projectId': snap.id,
    });
  });
});

/// Provider for chat preview messages (last 10).
final chatPreviewProvider =
    StreamProvider.autoDispose.family<List<Message>, String>((ref, projectId) {
  final firestore = FirebaseFirestore.instance;
  const shopId = 'sunil-trading-company';

  return firestore
      .collection('shops')
      .doc(shopId)
      .collection('chatThreads')
      .doc(projectId)
      .collection('messages')
      .orderBy('sentAt', descending: true)
      .limit(10)
      .snapshots()
      .map((snap) {
    return snap.docs.map((doc) {
      return Message.fromJson(<String, dynamic>{
        ...doc.data(),
        'messageId': doc.id,
      });
    }).toList()
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
  });
});

/// S4.7 — Project detail screen.
class ProjectDetailScreen extends ConsumerWidget {
  const ProjectDetailScreen({
    super.key,
    required this.projectId,
  });

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = const AppStringsHi();
    final projectAsync = ref.watch(projectDetailProvider(projectId));
    final chatAsync = ref.watch(chatPreviewProvider(projectId));

    return Scaffold(
      backgroundColor: YugmaColors.background,
      appBar: AppBar(
        backgroundColor: YugmaColors.primary,
        foregroundColor: YugmaColors.textOnPrimary,
        title: Text(
          strings.projectDetailTitle,
          style: TextStyle(
            fontFamily: YugmaFonts.devaDisplay,
            fontSize: YugmaTypeScale.h3,
          ),
        ),
      ),
      body: projectAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: YugmaColors.primary),
        ),
        error: (err, _) => Center(
          child: Text(err.toString(),
              style: TextStyle(fontFamily: YugmaFonts.devaBody)),
        ),
        data: (project) {
          if (project == null) {
            return Center(
              child: Text(
                strings.emptyOrdersList,
                style: TextStyle(fontFamily: YugmaFonts.devaBody),
              ),
            );
          }
          return _buildDetail(context, project, chatAsync, strings);
        },
      ),
    );
  }

  Widget _buildDetail(
    BuildContext context,
    Project project,
    AsyncValue<List<Message>> chatAsync,
    AppStrings strings,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(YugmaSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- State + Total ----
          _buildHeader(project, strings),
          const SizedBox(height: YugmaSpacing.s4),

          // ---- Line items ----
          _buildSectionHeader(strings.lineItemsHeader),
          const SizedBox(height: YugmaSpacing.s2),
          _buildLineItems(project),
          const SizedBox(height: YugmaSpacing.s4),

          // ---- Customer info ----
          _buildSectionHeader(strings.customerInfoHeader),
          const SizedBox(height: YugmaSpacing.s2),
          _buildCustomerCard(project, strings),
          const SizedBox(height: YugmaSpacing.s4),

          // ---- Chat preview ----
          chatAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (messages) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    strings.chatPreviewHeader(messages.length),
                  ),
                  const SizedBox(height: YugmaSpacing.s2),
                  _buildChatPreview(context, messages, strings),
                  const SizedBox(height: YugmaSpacing.s4),
                ],
              );
            },
          ),

          // ---- Action buttons ----
          _buildActionButtons(context, project, strings),
          const SizedBox(height: YugmaSpacing.s8),
        ],
      ),
    );
  }

  Widget _buildHeader(Project project, AppStrings strings) {
    final stateLabel = switch (project.state) {
      ProjectState.draft => 'Draft',
      ProjectState.negotiating => strings.filterNegotiating,
      ProjectState.committed => strings.filterCommitted,
      ProjectState.paid => strings.filterPendingPayment,
      ProjectState.delivering => strings.filterDelivering,
      ProjectState.awaitingVerification => strings.filterPendingPayment,
      ProjectState.closed => strings.filterClosed,
      ProjectState.cancelled => strings.cancelOrderButton,
    };

    return Container(
      padding: const EdgeInsets.all(YugmaSpacing.s4),
      decoration: BoxDecoration(
        color: YugmaColors.surface,
        borderRadius: BorderRadius.circular(YugmaRadius.lg),
        boxShadow: YugmaShadows.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹${_formatInr(project.totalAmount)}',
                  style: TextStyle(
                    fontFamily: YugmaFonts.mono,
                    fontSize: YugmaTypeScale.display,
                    fontWeight: FontWeight.w700,
                    color: YugmaColors.textPrimary,
                  ),
                ),
                const SizedBox(height: YugmaSpacing.s1),
                Text(
                  '${project.lineItems.length} items',
                  style: TextStyle(
                    fontFamily: YugmaFonts.enBody,
                    fontSize: YugmaTypeScale.caption,
                    color: YugmaColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: YugmaSpacing.s3,
              vertical: YugmaSpacing.s1,
            ),
            decoration: BoxDecoration(
              color: YugmaColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(YugmaRadius.sm),
            ),
            child: Text(
              stateLabel,
              style: TextStyle(
                fontFamily: YugmaFonts.devaBody,
                fontSize: YugmaTypeScale.caption,
                fontWeight: FontWeight.w600,
                color: YugmaColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: YugmaFonts.devaBody,
        fontSize: YugmaTypeScale.bodyLarge,
        fontWeight: FontWeight.w700,
        color: YugmaColors.textPrimary,
      ),
    );
  }

  Widget _buildLineItems(Project project) {
    return Container(
      decoration: BoxDecoration(
        color: YugmaColors.surface,
        borderRadius: BorderRadius.circular(YugmaRadius.lg),
        boxShadow: YugmaShadows.card,
      ),
      child: Column(
        children: [
          for (var i = 0; i < project.lineItems.length; i++) ...[
            if (i > 0) Divider(color: YugmaColors.divider, height: 1),
            _LineItemRow(item: project.lineItems[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Project project, AppStrings strings) {
    final name = project.customerDisplayName ??
        project.customerPhone ??
        strings.newCustomerPlaceholder;

    return Container(
      padding: const EdgeInsets.all(YugmaSpacing.s4),
      decoration: BoxDecoration(
        color: YugmaColors.surface,
        borderRadius: BorderRadius.circular(YugmaRadius.lg),
        boxShadow: YugmaShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: YugmaColors.primary, size: 20),
              const SizedBox(width: YugmaSpacing.s2),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontFamily: YugmaFonts.devaBody,
                    fontSize: YugmaTypeScale.body,
                    fontWeight: FontWeight.w600,
                    color: YugmaColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (project.customerPhone != null) ...[
            const SizedBox(height: YugmaSpacing.s2),
            Text(
              project.customerPhone!,
              style: TextStyle(
                fontFamily: YugmaFonts.mono,
                fontSize: YugmaTypeScale.caption,
                color: YugmaColors.textSecondary,
              ),
            ),
          ],
          if (project.customerVpa != null) ...[
            const SizedBox(height: YugmaSpacing.s1),
            Text(
              project.customerVpa!,
              style: TextStyle(
                fontFamily: YugmaFonts.mono,
                fontSize: YugmaTypeScale.caption,
                color: YugmaColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChatPreview(
    BuildContext context,
    List<Message> messages,
    AppStrings strings,
  ) {
    if (messages.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(YugmaSpacing.s4),
        decoration: BoxDecoration(
          color: YugmaColors.surface,
          borderRadius: BorderRadius.circular(YugmaRadius.lg),
        ),
        child: Text(
          strings.chatInputPlaceholder,
          style: TextStyle(
            fontFamily: YugmaFonts.devaBody,
            fontSize: YugmaTypeScale.caption,
            color: YugmaColors.textMuted,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: YugmaColors.surface,
        borderRadius: BorderRadius.circular(YugmaRadius.lg),
        boxShadow: YugmaShadows.card,
      ),
      child: Column(
        children: [
          for (var i = 0; i < messages.length; i++) ...[
            if (i > 0) Divider(color: YugmaColors.divider, height: 1),
            _ChatPreviewRow(message: messages[i], strings: strings),
          ],
          // "Open full chat" button
          Divider(color: YugmaColors.divider, height: 1),
          InkWell(
            onTap: () => context.push('/orders/$projectId/chat'),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(YugmaRadius.lg),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(YugmaSpacing.s3),
              child: Text(
                strings.sendMessageButton,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: YugmaFonts.devaBody,
                  fontSize: YugmaTypeScale.caption,
                  fontWeight: FontWeight.w600,
                  color: YugmaColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    Project project,
    AppStrings strings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Send message — always available
        SizedBox(
          height: YugmaSpacing.s12,
          child: ElevatedButton.icon(
            onPressed: () => context.push('/orders/$projectId/chat'),
            icon: const Icon(Icons.chat_bubble_outline, size: 20),
            label: Text(strings.sendMessageButton),
            style: ElevatedButton.styleFrom(
              backgroundColor: YugmaColors.primary,
              foregroundColor: YugmaColors.textOnPrimary,
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
        const SizedBox(height: YugmaSpacing.s2),
        // Contextual action based on state
        if (project.state == ProjectState.paid ||
            project.state == ProjectState.committed)
          SizedBox(
            height: YugmaSpacing.s12,
            child: OutlinedButton.icon(
              onPressed: () {
                // Mark delivered — deferred to full state machine wiring
              },
              icon: const Icon(Icons.local_shipping_outlined, size: 20),
              label: Text(strings.markDeliveredButton),
              style: OutlinedButton.styleFrom(
                foregroundColor: YugmaColors.primary,
                side: BorderSide(color: YugmaColors.primary),
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
      ],
    );
  }

  static String _formatInr(int amount) {
    final s = amount.toString();
    if (s.length <= 3) return s;
    final lastThree = s.substring(s.length - 3);
    final rest = s.substring(0, s.length - 3);
    final buffer = StringBuffer();
    for (var i = 0; i < rest.length; i++) {
      if (i != 0 && (rest.length - i) % 2 == 0) {
        buffer.write(',');
      }
      buffer.write(rest[i]);
    }
    return '$buffer,$lastThree';
  }
}

/// Line item row in the detail view.
class _LineItemRow extends StatelessWidget {
  const _LineItemRow({required this.item});
  final LineItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(YugmaSpacing.s3),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.skuName,
                  style: TextStyle(
                    fontFamily: YugmaFonts.devaBody,
                    fontSize: YugmaTypeScale.body,
                    fontWeight: FontWeight.w600,
                    color: YugmaColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '×${item.quantity}',
                  style: TextStyle(
                    fontFamily: YugmaFonts.mono,
                    fontSize: YugmaTypeScale.caption,
                    color: YugmaColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${_formatPrice(item.effectivePrice)}',
                style: TextStyle(
                  fontFamily: YugmaFonts.mono,
                  fontSize: YugmaTypeScale.body,
                  fontWeight: FontWeight.w600,
                  color: YugmaColors.textPrimary,
                ),
              ),
              if (item.finalPrice != null &&
                  item.finalPrice != item.unitPriceInr)
                Text(
                  '₹${_formatPrice(item.unitPriceInr)}',
                  style: TextStyle(
                    fontFamily: YugmaFonts.mono,
                    fontSize: YugmaTypeScale.caption,
                    color: YugmaColors.textMuted,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatPrice(int amount) {
    final s = amount.toString();
    if (s.length <= 3) return s;
    final lastThree = s.substring(s.length - 3);
    final rest = s.substring(0, s.length - 3);
    final buffer = StringBuffer();
    for (var i = 0; i < rest.length; i++) {
      if (i != 0 && (rest.length - i) % 2 == 0) {
        buffer.write(',');
      }
      buffer.write(rest[i]);
    }
    return '$buffer,$lastThree';
  }
}

/// Chat preview row — compact one-line per message.
class _ChatPreviewRow extends StatelessWidget {
  const _ChatPreviewRow({
    required this.message,
    required this.strings,
  });

  final Message message;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final isCustomer = message.authorRole == MessageAuthorRole.customer;
    final sender = isCustomer ? strings.chatSenderYou : strings.chatSenderBhaiya;
    final body = message.textBody ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: YugmaSpacing.s3,
        vertical: YugmaSpacing.s2,
      ),
      child: Row(
        children: [
          Text(
            '$sender: ',
            style: TextStyle(
              fontFamily: YugmaFonts.devaBody,
              fontSize: YugmaTypeScale.caption,
              fontWeight: FontWeight.w600,
              color: isCustomer
                  ? YugmaColors.textSecondary
                  : YugmaColors.primary,
            ),
          ),
          Expanded(
            child: Text(
              body,
              style: TextStyle(
                fontFamily: YugmaFonts.devaBody,
                fontSize: YugmaTypeScale.caption,
                color: YugmaColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
