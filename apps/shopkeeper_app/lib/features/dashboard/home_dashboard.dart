// =============================================================================
// HomeDashboard — the ops app home screen.
//
// S4.13 AC #1: Ops app home dashboard has prominent "Aaj ka kaam" card at top.
// S4.1 AC #6: Sign-out option accessible from this screen.
//
// Sprint 3 scope: TodaysTaskCard + placeholder sections for future stories.
// Future stories (S4.x) will add: inventory summary, pending orders,
// chat unread count, udhaar summary, presence toggle, analytics tile.
//
// Per binding rules:
//   - ALL strings via AppStrings
//   - ALL theme via YugmaColors/YugmaFonts
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';

import '../auth/auth_controller.dart';
import 'todays_task_card.dart';

/// The ops app home dashboard — the primary screen after successful auth.
class HomeDashboard extends ConsumerWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(opsAuthControllerProvider);
    final strings = const AppStringsHi();
    final operator = authState.value?.operator;

    return Scaffold(
      backgroundColor: YugmaColors.background,
      appBar: AppBar(
        backgroundColor: YugmaColors.primary,
        foregroundColor: YugmaColors.textOnPrimary,
        title: Text(
          strings.opsDashboardTitle,
          style: TextStyle(
            fontFamily: YugmaFonts.devaDisplay,
            fontSize: YugmaTypeScale.h3,
          ),
        ),
        actions: [
          // Sign-out (S4.1 AC #6)
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: YugmaColors.textOnPrimary,
            ),
            color: YugmaColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(YugmaRadius.md),
            ),
            onSelected: (value) {
              if (value == 'sign_out') {
                ref.read(opsAuthControllerProvider.notifier).signOut();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'sign_out',
                child: Text(
                  strings.signOutLabel,
                  style: TextStyle(
                    fontFamily: YugmaFonts.devaBody,
                    fontSize: YugmaTypeScale.body,
                    color: YugmaColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(top: YugmaSpacing.s4),
          children: [
            // Operator greeting
            if (operator != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: YugmaSpacing.s5,
                  vertical: YugmaSpacing.s2,
                ),
                child: Text(
                  '${operator.displayName} (${operator.role.name})',
                  style: TextStyle(
                    fontFamily: YugmaFonts.devaBody,
                    fontSize: YugmaTypeScale.bodyLarge,
                    height: YugmaLineHeights.normal,
                    color: YugmaColors.textSecondary,
                  ),
                ),
              ),

            // ── S4.13: Today's task card (prominent at top) ──
            if (operator != null)
              TodaysTaskCard(
                operatorJoinedAt: operator.joinedAt,
              ),

            const SizedBox(height: YugmaSpacing.s4),

            // ── Placeholder sections for future Sprint stories ──
            _PlaceholderSection(
              title: 'Inventory',
              icon: Icons.inventory_2_outlined,
            ),
            _PlaceholderSection(
              title: 'Orders',
              icon: Icons.receipt_long_outlined,
            ),
            _PlaceholderSection(
              title: 'Chat',
              icon: Icons.chat_outlined,
            ),
            _PlaceholderSection(
              title: 'Udhaar',
              icon: Icons.account_balance_wallet_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder section for future sprint stories. Shows a muted card
/// with an icon and label to indicate what will be built here.
class _PlaceholderSection extends StatelessWidget {
  const _PlaceholderSection({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: YugmaSpacing.s4,
        vertical: YugmaSpacing.s2,
      ),
      padding: const EdgeInsets.all(YugmaSpacing.s5),
      decoration: BoxDecoration(
        color: YugmaColors.surface,
        borderRadius: BorderRadius.circular(YugmaRadius.lg),
        border: Border.all(
          color: YugmaColors.divider,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: YugmaColors.textMuted,
            size: 24,
          ),
          const SizedBox(width: YugmaSpacing.s3),
          Text(
            title,
            style: TextStyle(
              fontFamily: YugmaFonts.enBody,
              fontSize: YugmaTypeScale.body,
              color: YugmaColors.textMuted,
            ),
          ),
          const Spacer(),
          Text(
            'Coming soon',
            style: TextStyle(
              fontFamily: YugmaFonts.enBody,
              fontSize: YugmaTypeScale.caption,
              fontStyle: FontStyle.italic,
              color: YugmaColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
