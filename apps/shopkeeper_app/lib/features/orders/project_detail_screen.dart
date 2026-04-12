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

/// Normalize Firestore Timestamp → ISO8601 for Freezed JSON parsing.
/// CR #1: prevents P0 crash from Timestamp → String cast failure.
Object? _normalizeTimestamp(Object? value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate().toIso8601String();
  if (value is DateTime) return value.toIso8601String();
  return value;
}

/// Normalize all timestamp fields in a raw Firestore map.
Map<String, dynamic> _normalizeProjectTimestamps(Map<String, dynamic> raw) {
  return <String, dynamic>{
    ...raw,
    'createdAt': _normalizeTimestamp(raw['createdAt']),
    'committedAt': _normalizeTimestamp(raw['committedAt']),
    'paidAt': _normalizeTimestamp(raw['paidAt']),
    'deliveredAt': _normalizeTimestamp(raw['deliveredAt']),
    'closedAt': _normalizeTimestamp(raw['closedAt']),
    'lastMessageAt': _normalizeTimestamp(raw['lastMessageAt']),
    'updatedAt': _normalizeTimestamp(raw['updatedAt']),
  };
}

/// Provider for a single project, streamed by ID.
/// CR #2: reads shopId from provider instead of hardcoding.
final projectDetailProvider =
    StreamProvider.autoDispose.family<Project?, String>((ref, projectId) {
  final firestore = FirebaseFirestore.instance;
  final shopId = ref.read(shopIdProviderProvider).shopId;

  return firestore
      .collection('shops')
      .doc(shopId)
      .collection('projects')
      .doc(projectId)
      .snapshots()
      .map((snap) {
    if (!snap.exists) return null;
    final raw = snap.data()!;
    return Project.fromJson(<String, dynamic>{
      ..._normalizeProjectTimestamps(raw),
      'projectId': snap.id,
    });
  });
});

/// Provider for chat preview messages (last 10).
/// CR #2: reads shopId from provider instead of hardcoding.
final chatPreviewProvider =
    StreamProvider.autoDispose.family<List<Message>, String>((ref, projectId) {
  final firestore = FirebaseFirestore.instance;
  final shopId = ref.read(shopIdProviderProvider).shopId;

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
      final raw = doc.data();
      return Message.fromJson(<String, dynamic>{
        ...raw,
        'messageId': doc.id,
        'sentAt': _normalizeTimestamp(raw['sentAt']),
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
          return _buildDetail(context, ref, project, chatAsync, strings);
        },
      ),
    );
  }

  Widget _buildDetail(
    BuildContext context,
    WidgetRef ref,
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
          _buildActionButtons(context, ref, project, strings),
          const SizedBox(height: YugmaSpacing.s8),
        ],
      ),
    );
  }

  Widget _buildHeader(Project project, AppStrings strings) {
    // CR #6: correct state labels — paid ≠ pending payment, cancelled ≠ action.
    final stateLabel = switch (project.state) {
      ProjectState.draft => 'Draft',
      ProjectState.negotiating => strings.filterNegotiating,
      ProjectState.committed => strings.filterCommitted,
      ProjectState.paid => 'Paid',
      ProjectState.delivering => strings.filterDelivering,
      ProjectState.awaitingVerification => strings.filterPendingPayment,
      ProjectState.closed => strings.filterClosed,
      ProjectState.cancelled => 'Cancelled',
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
    WidgetRef ref,
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
        // C3.9: Record payment — visible when udhaar ledger exists.
        if (project.udhaarLedgerId != null) ...[
          const SizedBox(height: YugmaSpacing.s2),
          SizedBox(
            height: YugmaSpacing.s12,
            child: OutlinedButton.icon(
              onPressed: () =>
                  _showRecordPaymentDialog(context, ref, project, strings),
              icon: const Icon(Icons.payments_outlined, size: 20),
              label: Text(strings.udhaarRecordPaymentButton),
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
        ],
        // C3.8: Udhaar khaata button — visible for committed/paid projects
        // that don't already have a ledger.
        if ((project.state == ProjectState.committed ||
                project.state == ProjectState.paid) &&
            project.udhaarLedgerId == null) ...[
          const SizedBox(height: YugmaSpacing.s2),
          SizedBox(
            height: YugmaSpacing.s12,
            child: OutlinedButton.icon(
              onPressed: () => _showUdhaarDialog(context, ref, project, strings),
              icon: const Icon(Icons.account_balance_wallet_outlined, size: 20),
              label: Text(strings.udhaarStartButton),
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
        ],
      ],
    );
  }

  void _showUdhaarDialog(
    BuildContext context,
    WidgetRef ref,
    Project project,
    AppStrings strings,
  ) {
    final todayController = TextEditingController();
    final balanceController = TextEditingController();

    // Pre-fill balance with totalAmount.
    balanceController.text = project.totalAmount.toString();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          strings.udhaarStartButton,
          style: TextStyle(
            fontFamily: YugmaFonts.devaBody,
            fontSize: YugmaTypeScale.bodyLarge,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: todayController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: strings.udhaarTodayPaymentLabel,
                labelStyle: TextStyle(fontFamily: YugmaFonts.devaBody),
                prefixText: '₹ ',
              ),
            ),
            const SizedBox(height: YugmaSpacing.s3),
            TextField(
              controller: balanceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: strings.udhaarBalanceLabel,
                labelStyle: TextStyle(fontFamily: YugmaFonts.devaBody),
                prefixText: '₹ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(strings.draftQtyHighCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final balance =
                  int.tryParse(balanceController.text.trim()) ?? 0;
              if (balance <= 0) return;

              Navigator.of(ctx).pop();

              final repo = UdhaarLedgerRepo(
                firestore: FirebaseFirestore.instance,
                shopIdProvider: ShopIdProvider(
                  ref.read(shopIdProviderProvider).shopId,
                ),
              );

              try {
                await repo.createLedger(
                  projectId: project.projectId,
                  customerId: project.customerUid,
                  recordedAmount: balance,
                  runningBalance: balance,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(strings.udhaarCreatedSuccess)),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: YugmaColors.primary,
              foregroundColor: YugmaColors.textOnPrimary,
            ),
            child: Text(strings.udhaarConfirmButton),
          ),
        ],
      ),
    );
  }

  /// C3.9: Record a partial payment on the udhaar ledger.
  void _showRecordPaymentDialog(
    BuildContext context,
    WidgetRef ref,
    Project project,
    AppStrings strings,
  ) {
    final amountController = TextEditingController();
    var selectedMethod = 'cash';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            strings.udhaarRecordPaymentButton,
            style: TextStyle(
              fontFamily: YugmaFonts.devaBody,
              fontSize: YugmaTypeScale.bodyLarge,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: strings.udhaarAmountPaidLabel,
                  labelStyle: TextStyle(fontFamily: YugmaFonts.devaBody),
                  prefixText: '₹ ',
                ),
              ),
              const SizedBox(height: YugmaSpacing.s3),
              DropdownButtonFormField<String>(
                value: selectedMethod,
                decoration: InputDecoration(
                  labelText: strings.udhaarPaymentMethodLabel,
                  labelStyle: TextStyle(fontFamily: YugmaFonts.devaBody),
                ),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'upi', child: Text('UPI')),
                  DropdownMenuItem(value: 'bank', child: Text('Bank')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setDialogState(() => selectedMethod = v);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(strings.draftQtyHighCancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount =
                    int.tryParse(amountController.text.trim()) ?? 0;
                if (amount <= 0) return;

                Navigator.of(ctx).pop();

                final repo = UdhaarLedgerRepo(
                  firestore: FirebaseFirestore.instance,
                  shopIdProvider: ShopIdProvider(
                    ref.read(shopIdProviderProvider).shopId,
                  ),
                );

                try {
                  await repo.recordPayment(
                    ledgerId: project.udhaarLedgerId!,
                    amount: amount,
                    method: selectedMethod,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(strings.udhaarPaymentRecordedSuccess),
                      ),
                    );
                  }
                } on UdhaarLedgerRepoException catch (e) {
                  if (context.mounted) {
                    final msg = e.code == 'overpayment'
                        ? strings.udhaarOverpaymentError
                        : e.message;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(msg)),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: YugmaColors.primary,
                foregroundColor: YugmaColors.textOnPrimary,
              ),
              child: Text(strings.udhaarConfirmButton),
            ),
          ],
        ),
      ),
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
    // CR #8: show meaningful preview for non-text messages.
    final body = switch (message.type) {
      MessageType.text || MessageType.system => message.textBody ?? '',
      MessageType.priceProposal => '₹${message.proposedPrice ?? 0}',
      MessageType.voiceNote => '🎤',
      MessageType.image => '📷',
    };

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
