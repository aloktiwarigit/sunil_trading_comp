// =============================================================================
// OrderListScreen — C3.10 AC #1–2: customer's "मेरे ऑर्डर" tab.
//
// Shows all projects for the current customer (filtered by customerUid).
// Each card: state badge in Devanagari, total amount, last updated,
// line items count, last message preview.
//
// Tapping a card navigates to OrderDetailScreen (state timeline).
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lib_core/lib_core.dart';

import '../../main.dart' show authProviderInstanceProvider;

/// Normalize Firestore Timestamp → ISO8601 for Freezed JSON parsing.
Object? _normalizeTimestamp(Object? value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate().toIso8601String();
  if (value is DateTime) return value.toIso8601String();
  return value;
}

/// Provider for customer's projects list, sorted by updatedAt desc.
/// C3.10 AC #1: filtered by customerUid == currentUid.
final customerProjectsProvider =
    StreamProvider.autoDispose<List<Project>>((ref) {
  final firestore = FirebaseFirestore.instance;
  final shopId = ref.read(shopIdProviderProvider).shopId;
  final currentUid = ref.read(authProviderInstanceProvider).currentUser?.uid;

  if (currentUid == null) return const Stream.empty();

  return firestore
      .collection('shops')
      .doc(shopId)
      .collection('projects')
      .where('customerUid', isEqualTo: currentUid)
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((doc) {
            final raw = doc.data();
            return Project.fromJson(<String, dynamic>{
              ...raw,
              'projectId': doc.id,
              'createdAt': _normalizeTimestamp(raw['createdAt']),
              'committedAt': _normalizeTimestamp(raw['committedAt']),
              'paidAt': _normalizeTimestamp(raw['paidAt']),
              'deliveredAt': _normalizeTimestamp(raw['deliveredAt']),
              'closedAt': _normalizeTimestamp(raw['closedAt']),
              'lastMessageAt': _normalizeTimestamp(raw['lastMessageAt']),
              'updatedAt': _normalizeTimestamp(raw['updatedAt']),
            });
          }).toList());
});

/// C3.10 — Customer's order list.
class OrderListScreen extends ConsumerWidget {
  const OrderListScreen({super.key, required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.yugmaTheme;
    final projectsAsync = ref.watch(customerProjectsProvider);

    return Scaffold(
      backgroundColor: theme.shopBackground,
      appBar: AppBar(
        backgroundColor: theme.shopPrimary,
        foregroundColor: theme.shopTextOnPrimary,
        title: Text(
          strings.ordersTitle,
          style: theme.h2Deva.copyWith(
            fontSize: YugmaTypeScale.h3,
          ),
        ),
      ),
      body: projectsAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: theme.shopPrimary),
        ),
        error: (err, _) => YugmaErrorBanner(error: err),
        data: (projects) {
          if (projects.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(YugmaSpacing.s8),
                child: Text(
                  strings.noOrdersYet,
                  textAlign: TextAlign.center,
                  style: theme.bodyDeva.copyWith(
                    color: theme.shopTextMuted,
                  ),
                ),
              ),
            );
          }
          return RefreshIndicator(
            color: theme.shopAccent,
            backgroundColor: theme.shopSurface,
            onRefresh: () async {
              ref.invalidate(customerProjectsProvider);
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(YugmaSpacing.s4),
              itemCount: projects.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: YugmaSpacing.s2),
              itemBuilder: (ctx, i) =>
                  _OrderCard(project: projects[i], strings: strings),
            ),
          );
        },
      ),
    );
  }
}

/// C3.10 AC #2: project card with state badge, total, items count, message preview.
class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.project, required this.strings});

  final Project project;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;
    final stateLabel = _stateLabel(project.state, strings);
    final shortId = project.projectId.length > 6
        ? project.projectId.substring(project.projectId.length - 6)
        : project.projectId;

    return InkWell(
      onTap: () => context.push('/orders/${project.projectId}'),
      borderRadius: BorderRadius.circular(YugmaRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(YugmaSpacing.s4),
        decoration: BoxDecoration(
          color: theme.shopSurface,
          borderRadius: BorderRadius.circular(YugmaRadius.lg),
          boxShadow: YugmaShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // State badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: YugmaSpacing.s2,
                    vertical: YugmaSpacing.s1,
                  ),
                  decoration: BoxDecoration(
                    color: theme.shopAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(YugmaRadius.sm),
                  ),
                  child: Text(
                    stateLabel,
                    style: theme.captionDeva.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.shopAccent,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '#$shortId',
                  style: theme.monoNumeral.copyWith(
                    fontSize: YugmaTypeScale.caption,
                    color: theme.shopTextMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: YugmaSpacing.s2),
            Row(
              children: [
                Text(
                  '₹${_formatInr(project.totalAmount)}',
                  style: theme.monoNumeral.copyWith(
                    fontSize: YugmaTypeScale.bodyLarge,
                    fontWeight: FontWeight.w700,
                    color: theme.shopTextPrimary,
                  ),
                ),
                const SizedBox(width: YugmaSpacing.s2),
                Text(
                  strings.orderItemCount(project.lineItems.length),
                  style: TextStyle(
                    fontFamily: theme.fontFamilyEnglishBody,
                    fontSize: YugmaTypeScale.caption,
                    color: theme.shopTextSecondary,
                  ),
                ),
              ],
            ),
            if (project.lastMessagePreview != null) ...[
              const SizedBox(height: YugmaSpacing.s2),
              Text(
                project.lastMessagePreview!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.captionDeva.copyWith(
                  color: theme.shopTextMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// C3.10 AC #2: state badge — locale-aware via AppStrings.
  static String _stateLabel(ProjectState state, AppStrings strings) =>
      switch (state) {
        ProjectState.draft => strings.stateBadgeDraft,
        ProjectState.negotiating => strings.stateBadgeNegotiating,
        ProjectState.committed => strings.stateBadgeCommitted,
        ProjectState.paid => strings.stateBadgePaid,
        ProjectState.delivering => strings.stateBadgeDelivering,
        ProjectState.awaitingVerification =>
          strings.stateBadgeAwaitingVerification,
        ProjectState.closed => strings.stateBadgeClosed,
        ProjectState.cancelled => strings.stateBadgeCancelled,
      };

  static String _formatInr(int amount) {
    if (amount < 0) return '-${_formatInr(-amount)}';
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
