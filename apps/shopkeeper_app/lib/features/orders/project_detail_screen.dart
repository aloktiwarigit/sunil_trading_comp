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

import 'dart:async';

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

/// S4.9 — Provider for customer memory, streamed by customerUid.
final customerMemoryProvider =
    StreamProvider.autoDispose.family<CustomerMemory?, String>((ref, customerUid) {
  final firestore = FirebaseFirestore.instance;
  final shopId = ref.read(shopIdProviderProvider).shopId;

  return firestore
      .collection('shops')
      .doc(shopId)
      .collection('customer_memory')
      .doc(customerUid)
      .snapshots()
      .map((snap) {
    if (!snap.exists) return null;
    final raw = snap.data()!;
    // CR #1: normalize Firestore Timestamps before Freezed JSON parsing.
    return CustomerMemory.fromJson(<String, dynamic>{
      ...raw,
      'customerUid': snap.id,
      'shopId': shopId,
      'firstSeenAt': _normalizeTimestamp(raw['firstSeenAt']),
      'lastSeenAt': _normalizeTimestamp(raw['lastSeenAt']),
    });
  });
});

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

          // ---- Customer info + memory (S4.9) ----
          _buildSectionHeader(strings.customerInfoHeader),
          const SizedBox(height: YugmaSpacing.s2),
          _buildCustomerCard(context, ref, project, strings),
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

  Widget _buildCustomerCard(
    BuildContext context,
    WidgetRef ref,
    Project project,
    AppStrings strings,
  ) {
    final name = project.customerDisplayName ??
        project.customerPhone ??
        strings.newCustomerPlaceholder;

    // S4.9: stream customer memory for this customer.
    final memoryAsync = ref.watch(
      customerMemoryProvider(project.customerUid),
    );

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
              // S4.9 AC #1: "Edit memory" button
              IconButton(
                icon: Icon(
                  Icons.edit_note,
                  color: YugmaColors.primary,
                  size: 22,
                ),
                tooltip: strings.memoryEditButton,
                onPressed: () => _showMemoryEditSheet(
                  context,
                  ref,
                  project.customerUid,
                  memoryAsync.valueOrNull,
                  strings,
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
          // S4.9: Display memory summary if exists
          memoryAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (memory) {
              if (memory == null || !memory.hasContent) {
                return Padding(
                  padding: const EdgeInsets.only(top: YugmaSpacing.s2),
                  child: Text(
                    strings.memoryNewCustomerPlaceholder,
                    style: TextStyle(
                      fontFamily: YugmaFonts.devaBody,
                      fontSize: YugmaTypeScale.caption,
                      fontStyle: FontStyle.italic,
                      color: YugmaColors.textMuted,
                    ),
                  ),
                );
              }
              return _MemorySummary(memory: memory, strings: strings);
            },
          ),
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
        // C3.11: Delivery confirmation — visible for paid/committed/delivering.
        if (project.state == ProjectState.paid ||
            project.state == ProjectState.committed ||
            project.state == ProjectState.delivering)
          SizedBox(
            height: YugmaSpacing.s12,
            child: OutlinedButton.icon(
              onPressed: () => _confirmDelivery(context, ref, project, strings),
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

  /// C3.11 AC #1–3: One-tap delivery confirmation with optional photo.
  /// State transition: current → closed, deliveredAt set.
  void _confirmDelivery(
    BuildContext context,
    WidgetRef ref,
    Project project,
    AppStrings strings,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          strings.markDeliveredButton,
          style: TextStyle(
            fontFamily: YugmaFonts.devaBody,
            fontSize: YugmaTypeScale.bodyLarge,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          strings.deliveryConfirmed,
          style: TextStyle(fontFamily: YugmaFonts.devaBody),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(strings.draftQtyHighCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();

              final repo = ProjectRepo(
                firestore: FirebaseFirestore.instance,
                shopIdProvider: ShopIdProvider(
                  ref.read(shopIdProviderProvider).shopId,
                ),
              );

              try {
                // CR F1+F3: use server timestamps, include closedAt.
                final patchMap = const ProjectOperatorPatch(
                  state: ProjectState.closed,
                ).toFirestoreMap();
                patchMap['deliveredAt'] = FieldValue.serverTimestamp();
                patchMap['closedAt'] = FieldValue.serverTimestamp();
                patchMap['updatedAt'] = FieldValue.serverTimestamp();

                await FirebaseFirestore.instance
                    .collection('shops')
                    .doc(ref.read(shopIdProviderProvider).shopId)
                    .collection('projects')
                    .doc(project.projectId)
                    .set(patchMap, SetOptions(merge: true));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(strings.deliveryConfirmed),
                    ),
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
            child: Text(strings.draftQtyHighConfirm),
          ),
        ],
      ),
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

  /// S4.9 AC #1: Open bottom sheet for editing customer memory.
  void _showMemoryEditSheet(
    BuildContext context,
    WidgetRef ref,
    String customerUid,
    CustomerMemory? existing,
    AppStrings strings,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: YugmaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(YugmaRadius.lg),
        ),
      ),
      builder: (ctx) => _MemoryEditSheet(
        customerUid: customerUid,
        existing: existing,
        strings: strings,
        shopId: ref.read(shopIdProviderProvider).shopId,
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

// =============================================================================
// S4.9 — Customer memory inline display + edit sheet.
// =============================================================================

/// Compact memory summary displayed on the customer info card.
class _MemorySummary extends StatelessWidget {
  const _MemorySummary({required this.memory, required this.strings});

  final CustomerMemory memory;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: YugmaSpacing.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: YugmaColors.divider, height: 1),
          const SizedBox(height: YugmaSpacing.s2),
          if (memory.notes.isNotEmpty)
            _memoryLine(Icons.sticky_note_2_outlined, memory.notes),
          if (memory.relationshipNotes.isNotEmpty)
            _memoryLine(Icons.people_outline, memory.relationshipNotes),
          if (memory.preferredOccasions.isNotEmpty)
            _memoryLine(
              Icons.event_outlined,
              memory.preferredOccasions
                  .map(_occasionLabel)
                  .join(', '),
            ),
          if (memory.preferredPriceMin != null ||
              memory.preferredPriceMax != null)
            _memoryLine(
              Icons.currency_rupee,
              '${memory.preferredPriceMin ?? '–'} – ${memory.preferredPriceMax ?? '–'}',
            ),
        ],
      ),
    );
  }

  Widget _memoryLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: YugmaSpacing.s1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: YugmaColors.textMuted),
          const SizedBox(width: YugmaSpacing.s1),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: YugmaFonts.devaBody,
                fontSize: YugmaTypeScale.caption,
                color: YugmaColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  static String _occasionLabel(PreferredOccasion o) => switch (o) {
        PreferredOccasion.shaadi => 'शादी',
        PreferredOccasion.nayaGhar => 'नया घर',
        PreferredOccasion.dahej => 'दहेज',
        PreferredOccasion.puranaBadalne => 'पुराना बदलने',
        PreferredOccasion.budget => 'बजट',
        PreferredOccasion.ladies => 'लेडीज',
        PreferredOccasion.other => 'और',
      };
}

/// S4.9 AC #1–3: Bottom sheet for editing customer memory.
/// Auto-save on changes (debounced).
class _MemoryEditSheet extends StatefulWidget {
  const _MemoryEditSheet({
    required this.customerUid,
    required this.existing,
    required this.strings,
    required this.shopId,
  });

  final String customerUid;
  final CustomerMemory? existing;
  final AppStrings strings;
  final String shopId;

  @override
  State<_MemoryEditSheet> createState() => _MemoryEditSheetState();
}

class _MemoryEditSheetState extends State<_MemoryEditSheet> {
  late final TextEditingController _notesController;
  late final TextEditingController _relationshipController;
  late final TextEditingController _priceMinController;
  late final TextEditingController _priceMaxController;
  late Set<PreferredOccasion> _selectedOccasions;

  /// Debounce timer for auto-save.
  Timer? _debounce;

  /// CR #3: guard against save-after-dispose race.
  bool _disposed = false;

  late final CustomerMemoryRepo _repo;

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    _notesController = TextEditingController(text: m?.notes ?? '');
    _relationshipController =
        TextEditingController(text: m?.relationshipNotes ?? '');
    _priceMinController =
        TextEditingController(text: m?.preferredPriceMin?.toString() ?? '');
    _priceMaxController =
        TextEditingController(text: m?.preferredPriceMax?.toString() ?? '');
    _selectedOccasions = Set<PreferredOccasion>.from(
      m?.preferredOccasions ?? <PreferredOccasion>[],
    );

    _repo = CustomerMemoryRepo(
      firestore: FirebaseFirestore.instance,
      shopIdProvider: ShopIdProvider(widget.shopId),
    );

    _notesController.addListener(_onChanged);
    _relationshipController.addListener(_onChanged);
    _priceMinController.addListener(_onChanged);
    _priceMaxController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    _notesController.dispose();
    _relationshipController.dispose();
    _priceMinController.dispose();
    _priceMaxController.dispose();
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), _save);
  }

  void _onOccasionToggled(PreferredOccasion occasion) {
    setState(() {
      if (_selectedOccasions.contains(occasion)) {
        _selectedOccasions.remove(occasion);
      } else {
        _selectedOccasions.add(occasion);
      }
    });
    _onChanged();
  }

  Future<void> _save() async {
    // CR #3: don't save if the sheet was already dismissed.
    if (_disposed) return;
    final notes = _notesController.text.trim();
    // B1.11 AC #4: 500 char limit.
    final clampedNotes = notes.length > 500 ? notes.substring(0, 500) : notes;

    final relNotes = _relationshipController.text.trim();
    // CR #4: clamp relationship notes to 500 chars, parity with notes.
    final clampedRelNotes =
        relNotes.length > 500 ? relNotes.substring(0, 500) : relNotes;

    await _repo.upsertMemory(
      customerUid: widget.customerUid,
      notes: clampedNotes,
      relationshipNotes: clampedRelNotes,
      preferredOccasions: _selectedOccasions.toList(),
      preferredPriceMin: int.tryParse(_priceMinController.text.trim()),
      preferredPriceMax: int.tryParse(_priceMaxController.text.trim()),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.strings.memorySaved),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: YugmaSpacing.s4,
        right: YugmaSpacing.s4,
        top: YugmaSpacing.s4,
        bottom: bottomInset + YugmaSpacing.s4,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: YugmaColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: YugmaSpacing.s3),
            // Title
            Text(
              strings.memorySheetTitle,
              style: TextStyle(
                fontFamily: YugmaFonts.devaDisplay,
                fontSize: YugmaTypeScale.h3,
                fontWeight: FontWeight.w700,
                color: YugmaColors.textPrimary,
              ),
            ),
            const SizedBox(height: YugmaSpacing.s4),

            // Notes field
            TextField(
              controller: _notesController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: strings.memoryNotesLabel,
                labelStyle: TextStyle(fontFamily: YugmaFonts.devaBody),
                border: const OutlineInputBorder(),
              ),
              style: TextStyle(
                fontFamily: YugmaFonts.devaBody,
                fontSize: YugmaTypeScale.body,
              ),
            ),
            const SizedBox(height: YugmaSpacing.s3),

            // Relationship notes
            // CR #4: enforce 500 char limit, parity with notes field.
            TextField(
              controller: _relationshipController,
              maxLines: 2,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: strings.memoryRelationshipLabel,
                labelStyle: TextStyle(fontFamily: YugmaFonts.devaBody),
                border: const OutlineInputBorder(),
              ),
              style: TextStyle(
                fontFamily: YugmaFonts.devaBody,
                fontSize: YugmaTypeScale.body,
              ),
            ),
            const SizedBox(height: YugmaSpacing.s3),

            // Preferred occasions — multi-select chips
            Text(
              strings.memoryOccasionsLabel,
              style: TextStyle(
                fontFamily: YugmaFonts.devaBody,
                fontSize: YugmaTypeScale.caption,
                color: YugmaColors.textSecondary,
              ),
            ),
            const SizedBox(height: YugmaSpacing.s1),
            Wrap(
              spacing: YugmaSpacing.s1,
              runSpacing: YugmaSpacing.s1,
              children: PreferredOccasion.values.map((o) {
                final selected = _selectedOccasions.contains(o);
                return FilterChip(
                  selected: selected,
                  label: Text(
                    _MemorySummary._occasionLabel(o),
                    style: TextStyle(
                      fontFamily: YugmaFonts.devaBody,
                      fontSize: YugmaTypeScale.caption,
                    ),
                  ),
                  selectedColor: YugmaColors.primary.withValues(alpha: 0.15),
                  checkmarkColor: YugmaColors.primary,
                  onSelected: (_) => _onOccasionToggled(o),
                );
              }).toList(),
            ),
            const SizedBox(height: YugmaSpacing.s3),

            // Price range
            Text(
              strings.memoryPriceRangeLabel,
              style: TextStyle(
                fontFamily: YugmaFonts.devaBody,
                fontSize: YugmaTypeScale.caption,
                color: YugmaColors.textSecondary,
              ),
            ),
            const SizedBox(height: YugmaSpacing.s1),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceMinController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: strings.memoryPriceMinLabel,
                      labelStyle: TextStyle(fontFamily: YugmaFonts.devaBody),
                      prefixText: '₹ ',
                      border: const OutlineInputBorder(),
                    ),
                    style: TextStyle(
                      fontFamily: YugmaFonts.mono,
                      fontSize: YugmaTypeScale.body,
                    ),
                  ),
                ),
                const SizedBox(width: YugmaSpacing.s2),
                Expanded(
                  child: TextField(
                    controller: _priceMaxController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: strings.memoryPriceMaxLabel,
                      labelStyle: TextStyle(fontFamily: YugmaFonts.devaBody),
                      prefixText: '₹ ',
                      border: const OutlineInputBorder(),
                    ),
                    style: TextStyle(
                      fontFamily: YugmaFonts.mono,
                      fontSize: YugmaTypeScale.body,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: YugmaSpacing.s4),
          ],
        ),
      ),
    );
  }
}

