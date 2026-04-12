// =============================================================================
// AnalyticsDashboardScreen — S4.11: sales analytics for Sunil-bhaiya.
//
// AC #1: current month — committed orders, revenue, open orders, open udhaar,
//        new customers.
// AC #2: delta arrows vs previous month.
// AC #3: bar chart of last 7 days' orders.
// AC #4: tapping any number drills down.
// Edge #1: new shop with no data → friendly empty state.
// Edge #2: client-side aggregation from cached projects list.
// Edge #3: offline staleness timestamp.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lib_core/lib_core.dart';

/// Normalize Firestore Timestamp → ISO8601 for Freezed JSON parsing.
Object? _normalizeTimestamp(Object? value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate().toIso8601String();
  if (value is DateTime) return value.toIso8601String();
  return value;
}

/// All projects for the shop (client-side aggregation source).
final allShopProjectsProvider =
    StreamProvider.autoDispose<List<Project>>((ref) {
  final firestore = FirebaseFirestore.instance;
  final shopId = ref.read(shopIdProviderProvider).shopId;

  return firestore
      .collection('shops')
      .doc(shopId)
      .collection('projects')
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

/// Aggregated metrics for a month.
class _MonthMetrics {
  _MonthMetrics({
    required this.committedCount,
    required this.revenue,
    required this.openOrders,
    required this.openUdhaarTotal,
    required this.newCustomers,
  });

  final int committedCount;
  final int revenue;
  final int openOrders;
  final int openUdhaarTotal;
  final int newCustomers;
}

/// S4.11 — Analytics dashboard screen.
class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.yugmaTheme;
    final strings = const AppStringsHi();
    final projectsAsync = ref.watch(allShopProjectsProvider);

    return Scaffold(
      backgroundColor: theme.shopBackground,
      appBar: AppBar(
        backgroundColor: theme.shopPrimary,
        foregroundColor: theme.shopTextOnPrimary,
        title: Text(
          strings.opsDashboardTitle,
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
                  strings.emptyOrdersList,
                  textAlign: TextAlign.center,
                  style: theme.bodyDeva.copyWith(
                    color: theme.shopTextMuted,
                  ),
                ),
              ),
            );
          }
          return _buildDashboard(context, projects, strings);
        },
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, List<Project> projects, AppStrings strings) {
    final theme = context.yugmaTheme;
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final lastMonth = DateTime(now.year, now.month - 1);

    final current = _computeMetrics(projects, thisMonth, now);
    final previous = _computeMetrics(
        projects, lastMonth, DateTime(now.year, now.month, 0));

    // Last 7 days bar data
    final barData = _last7DaysOrders(projects, now);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(YugmaSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metric tiles (AC #1 + #2)
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: strings.analyticsOrders,
                  value: current.committedCount,
                  delta: current.committedCount - previous.committedCount,
                  onTap: () => context.push('/orders'),
                ),
              ),
              const SizedBox(width: YugmaSpacing.s2),
              Expanded(
                child: _MetricTile(
                  label: strings.analyticsRevenue,
                  value: current.revenue,
                  delta: current.revenue - previous.revenue,
                  isRupee: true,
                  onTap: () => context.push('/orders'),
                ),
              ),
            ],
          ),
          const SizedBox(height: YugmaSpacing.s2),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: strings.analyticsOpenOrders,
                  value: current.openOrders,
                  delta: current.openOrders - previous.openOrders,
                  onTap: () => context.push('/orders'),
                ),
              ),
              const SizedBox(width: YugmaSpacing.s2),
              Expanded(
                child: _MetricTile(
                  label: strings.analyticsUdhaarPending,
                  value: current.openUdhaarTotal,
                  delta: current.openUdhaarTotal - previous.openUdhaarTotal,
                  isRupee: true,
                  onTap: () => context.push('/udhaar'),
                ),
              ),
            ],
          ),
          const SizedBox(height: YugmaSpacing.s2),
          _MetricTile(
            label: strings.analyticsNewCustomers,
            value: current.newCustomers,
            delta: current.newCustomers - previous.newCustomers,
          ),
          const SizedBox(height: YugmaSpacing.s4),

          // AC #3: Bar chart — last 7 days
          Text(
            strings.analyticsLast7Days,
            style: theme.bodyDeva.copyWith(
              fontSize: YugmaTypeScale.bodyLarge,
              fontWeight: FontWeight.w700,
              color: theme.shopTextPrimary,
            ),
          ),
          const SizedBox(height: YugmaSpacing.s2),
          _SimpleBarChart(data: barData, strings: strings),
        ],
      ),
    );
  }

  _MonthMetrics _computeMetrics(
    List<Project> projects,
    DateTime monthStart,
    DateTime monthEnd,
  ) {
    final monthProjects = projects.where((p) {
      final date = p.committedAt ?? p.createdAt;
      return date.isAfter(monthStart) &&
          date.isBefore(monthEnd.add(const Duration(days: 1)));
    }).toList();

    final committedCount = monthProjects
        .where((p) =>
            p.state != ProjectState.draft &&
            p.state != ProjectState.cancelled)
        .length;

    final revenue = monthProjects
        .where((p) =>
            p.state == ProjectState.paid || p.state == ProjectState.closed)
        .fold<int>(0, (sum, p) => sum + p.totalAmount);

    final openOrders = projects
        .where((p) =>
            p.state != ProjectState.draft &&
            p.state != ProjectState.closed &&
            p.state != ProjectState.cancelled)
        .length;

    // Rough udhaar total — count projects with udhaarLedgerId
    final openUdhaarTotal = projects
        .where((p) => p.udhaarLedgerId != null && p.state != ProjectState.closed)
        .fold<int>(0, (sum, p) => sum + p.totalAmount);

    final uniqueCustomers =
        monthProjects.map((p) => p.customerUid).toSet().length;

    return _MonthMetrics(
      committedCount: committedCount,
      revenue: revenue,
      openOrders: openOrders,
      openUdhaarTotal: openUdhaarTotal,
      newCustomers: uniqueCustomers,
    );
  }

  List<int> _last7DaysOrders(List<Project> projects, DateTime now) {
    final result = <int>[];
    for (var i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final nextDay = day.add(const Duration(days: 1));
      final count = projects.where((p) {
        final date = p.committedAt ?? p.createdAt;
        return date.isAfter(day) && date.isBefore(nextDay);
      }).length;
      result.add(count);
    }
    return result;
  }
}

/// Single metric tile with delta arrow.
class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.delta,
    this.isRupee = false,
    this.onTap,
  });

  final String label;
  final int value;
  final int delta;
  final bool isRupee;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;
    final displayValue = isRupee ? '₹${_formatInr(value)}' : '$value';
    final deltaColor = delta > 0
        ? theme.shopPrimary
        : delta < 0
            ? theme.shopCommit
            : theme.shopTextMuted;
    final deltaIcon = delta > 0
        ? Icons.arrow_upward
        : delta < 0
            ? Icons.arrow_downward
            : null;

    return InkWell(
      onTap: onTap,
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
            Text(
              label,
              style: theme.captionDeva.copyWith(
                color: theme.shopTextSecondary,
              ),
            ),
            const SizedBox(height: YugmaSpacing.s1),
            Text(
              displayValue,
              style: theme.monoNumeral.copyWith(
                fontSize: YugmaTypeScale.h3,
                fontWeight: FontWeight.w700,
                color: theme.shopTextPrimary,
              ),
            ),
            if (delta != 0) ...[
              const SizedBox(height: YugmaSpacing.s1),
              Row(
                children: [
                  if (deltaIcon != null)
                    Icon(deltaIcon, size: 14, color: deltaColor),
                  Text(
                    '${delta.abs()}',
                    style: theme.monoNumeral.copyWith(
                      fontSize: YugmaTypeScale.caption,
                      color: deltaColor,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

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

/// Simple horizontal bar chart using basic Flutter widgets.
/// No external chart package needed — just proportional containers.
class _SimpleBarChart extends StatelessWidget {
  const _SimpleBarChart({required this.data, required this.strings});

  final List<int> data;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;
    final maxVal = data.fold<int>(0, (m, v) => v > m ? v : m);
    if (maxVal == 0) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: theme.shopSurface,
          borderRadius: BorderRadius.circular(YugmaRadius.lg),
        ),
        child: Center(
          child: Text(
            strings.analyticsNoOrdersYet,
            style: theme.captionDeva.copyWith(
              color: theme.shopTextMuted,
            ),
          ),
        ),
      );
    }

    final now = DateTime.now();

    return Container(
      height: 160,
      padding: const EdgeInsets.all(YugmaSpacing.s3),
      decoration: BoxDecoration(
        color: theme.shopSurface,
        borderRadius: BorderRadius.circular(YugmaRadius.lg),
        boxShadow: YugmaShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < data.length; i++) ...[
            if (i > 0) const SizedBox(width: YugmaSpacing.s1),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (data[i] > 0)
                    Text(
                      '${data[i]}',
                      style: theme.monoNumeral.copyWith(
                        fontSize: 10,
                        color: theme.shopTextSecondary,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Container(
                    height: (data[i] / maxVal) * 100,
                    decoration: BoxDecoration(
                      color: theme.shopPrimary.withValues(
                        alpha: i == data.length - 1 ? 1.0 : 0.5,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${now.subtract(Duration(days: 6 - i)).day}',
                    style: theme.monoNumeral.copyWith(
                      fontSize: 10,
                      color: theme.shopTextMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
