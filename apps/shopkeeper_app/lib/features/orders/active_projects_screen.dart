// =============================================================================
// ActiveProjectsScreen — S4.6 order/project list with state filter.
//
// Per S4.6:
//   AC #1: Vertical list sorted by updatedAt desc
//   AC #2: Card shows customer name, state badge, total, items count,
//          last message, time since update
//   AC #3: Filter chips at top
//   AC #4: Tapping opens project detail (S4.7 — placeholder for now)
//   AC #6: Real-time via Firestore listener
// =============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lib_core/lib_core.dart';

import 'active_projects_controller.dart';

/// The active projects list screen for the shopkeeper ops app.
class ActiveProjectsScreen extends ConsumerStatefulWidget {
  const ActiveProjectsScreen({super.key});

  @override
  ConsumerState<ActiveProjectsScreen> createState() =>
      _ActiveProjectsScreenState();
}

class _ActiveProjectsScreenState extends ConsumerState<ActiveProjectsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {}); // Update clear-button visibility.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchQueryProvider.notifier).state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = const AppStringsHi();
    final projectsAsync = ref.watch(filteredProjectsProvider);
    final currentFilter = ref.watch(projectFilterProvider);

    return Scaffold(
      backgroundColor: YugmaColors.background,
      appBar: AppBar(
        backgroundColor: YugmaColors.primary,
        foregroundColor: YugmaColors.textOnPrimary,
        title: Text(
          strings.ordersTitle,
          style: TextStyle(
            fontFamily: YugmaFonts.devaDisplay,
            fontSize: YugmaTypeScale.h3,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              YugmaSpacing.s4,
              YugmaSpacing.s3,
              YugmaSpacing.s4,
              0,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: TextStyle(
                fontFamily: YugmaFonts.devaBody,
                fontSize: YugmaTypeScale.body,
                color: YugmaColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: strings.searchHintOrders,
                hintStyle: TextStyle(
                  fontFamily: YugmaFonts.devaBody,
                  fontSize: YugmaTypeScale.body,
                  color: YugmaColors.textMuted,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: YugmaColors.textMuted,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: YugmaColors.textMuted,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: YugmaColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: YugmaSpacing.s3,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(YugmaRadius.pill),
                  borderSide: BorderSide(color: YugmaColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(YugmaRadius.pill),
                  borderSide: BorderSide(color: YugmaColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(YugmaRadius.pill),
                  borderSide: BorderSide(color: YugmaColors.primary),
                ),
              ),
            ),
          ),
          // Filter chips (AC #3)
          _FilterChipRow(
            currentFilter: currentFilter,
            strings: strings,
            onChanged: (filter) {
              ref.read(projectFilterProvider.notifier).state = filter;
            },
          ),
          // Projects list
          Expanded(
            child: projectsAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: YugmaColors.primary),
              ),
              error: (err, _) => YugmaErrorBanner(error: err),
              data: (projects) {
                if (projects.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(YugmaSpacing.s8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: YugmaColors.textMuted,
                          ),
                          const SizedBox(height: YugmaSpacing.s4),
                          Text(
                            strings.emptyOrdersList,
                            style: TextStyle(
                              fontFamily: YugmaFonts.devaBody,
                              fontSize: YugmaTypeScale.body,
                              color: YugmaColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(YugmaSpacing.s4),
                  itemCount: projects.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: YugmaSpacing.s2),
                  itemBuilder: (context, index) {
                    return _ProjectCard(
                      project: projects[index],
                      strings: strings,
                      onTap: () {
                        // S4.7 — open project detail.
                        context.push(
                          '/orders/${projects[index].projectId}',
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter chip row (AC #3).
class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({
    required this.currentFilter,
    required this.strings,
    required this.onChanged,
  });

  final ProjectFilter currentFilter;
  final AppStrings strings;
  final ValueChanged<ProjectFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: YugmaSpacing.s4,
        vertical: YugmaSpacing.s3,
      ),
      child: Row(
        children: [
          _chip(ProjectFilter.all, strings.filterAll),
          _chip(ProjectFilter.committed, strings.filterCommitted),
          _chip(ProjectFilter.pendingPayment, strings.filterPendingPayment),
          _chip(ProjectFilter.delivering, strings.filterDelivering),
          _chip(ProjectFilter.closed, strings.filterClosed),
        ],
      ),
    );
  }

  Widget _chip(ProjectFilter filter, String label) {
    final isSelected = currentFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: YugmaSpacing.s2),
      child: FilterChip(
        selected: isSelected,
        label: Text(
          label,
          style: TextStyle(
            fontFamily: YugmaFonts.devaBody,
            fontSize: YugmaTypeScale.caption,
            color: isSelected
                ? YugmaColors.textOnPrimary
                : YugmaColors.textPrimary,
          ),
        ),
        backgroundColor: YugmaColors.surface,
        selectedColor: YugmaColors.primary,
        checkmarkColor: YugmaColors.textOnPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(YugmaRadius.pill),
          side: BorderSide(
            color: isSelected ? YugmaColors.primary : YugmaColors.divider,
          ),
        ),
        onSelected: (_) => onChanged(filter),
      ),
    );
  }
}

/// Project card for the orders list (AC #2).
class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.strings,
    required this.onTap,
  });

  final Project project;
  final AppStrings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(YugmaSpacing.s4),
        decoration: BoxDecoration(
          color: YugmaColors.surface,
          borderRadius: BorderRadius.circular(YugmaRadius.lg),
          border: Border.all(color: YugmaColors.divider),
          boxShadow: YugmaShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: customer name + state badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    project.customerDisplayName ??
                        project.customerPhone ??
                        project.customerUid.substring(0, 8),
                    style: TextStyle(
                      fontFamily: YugmaFonts.devaBody,
                      fontSize: YugmaTypeScale.body,
                      fontWeight: FontWeight.w600,
                      color: YugmaColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _StateBadge(state: project.state, strings: strings),
              ],
            ),
            const SizedBox(height: YugmaSpacing.s2),
            // Phase 3: COD-tagged committed projects show a "नकद —
            // डिलीवरी पर" hint so the operator knows to collect cash at
            // delivery and run Mark Paid.
            if (project.state == ProjectState.committed &&
                project.paymentMethod == 'cod') ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: YugmaSpacing.s2,
                  vertical: YugmaSpacing.s1,
                ),
                decoration: BoxDecoration(
                  color: YugmaColors.accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(YugmaRadius.sm),
                ),
                child: Text(
                  'नकद — डिलीवरी पर',
                  style: TextStyle(
                    fontFamily: YugmaFonts.devaBody,
                    fontSize: YugmaTypeScale.caption,
                    fontWeight: FontWeight.w600,
                    color: YugmaColors.accent,
                  ),
                ),
              ),
              const SizedBox(height: YugmaSpacing.s2),
            ],
            // Amount + item count
            Row(
              children: [
                Text(
                  '₹${formatInr(project.totalAmount)}',
                  style: TextStyle(
                    fontFamily: YugmaFonts.enBody,
                    fontSize: YugmaTypeScale.bodyLarge,
                    fontWeight: FontWeight.w700,
                    color: YugmaColors.textPrimary,
                  ),
                ),
                const SizedBox(width: YugmaSpacing.s3),
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
            // Last message preview
            if (project.lastMessagePreview != null) ...[
              const SizedBox(height: YugmaSpacing.s2),
              Text(
                project.lastMessagePreview!,
                style: TextStyle(
                  fontFamily: YugmaFonts.devaBody,
                  fontSize: YugmaTypeScale.caption,
                  color: YugmaColors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Devanagari state badge with color coding.
class _StateBadge extends StatelessWidget {
  const _StateBadge({required this.state, required this.strings});

  final ProjectState state;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      ProjectState.committed => (strings.filterCommitted, YugmaColors.accent),
      ProjectState.paid => (strings.filterPendingPayment, YugmaColors.primary),
      ProjectState.delivering => (
          strings.filterDelivering,
          YugmaColors.primaryDeep
        ),
      ProjectState.awaitingVerification => (
          strings.filterPendingPayment,
          YugmaColors.accent
        ),
      ProjectState.closed => (strings.filterClosed, YugmaColors.textMuted),
      _ => (state.name, YugmaColors.textMuted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: YugmaSpacing.s2,
        vertical: YugmaSpacing.s1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(YugmaRadius.sm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: YugmaFonts.devaBody,
          fontSize: YugmaTypeScale.caption,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
