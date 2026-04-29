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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lib_core/lib_core.dart';

import '../auth/auth_controller.dart';
import '../auth/role_gate.dart';
import '../presence/presence_toggle_screen.dart';
import 'media_spend_tile.dart';
import 'nps_card.dart';
import 'todays_task_card.dart';

// ---------------------------------------------------------------------------
// SU006: Dashboard count badge providers (Firestore-backed)
// ---------------------------------------------------------------------------

/// Streams the shop's current presence status from Firestore.
final _shopPresenceProvider = StreamProvider<PresenceStatus>((ref) {
  final shopId = ref.read(shopIdProviderProvider).shopId;
  return FirebaseFirestore.instance
      .collection('shops')
      .doc(shopId)
      .snapshots()
      .map((snap) {
    final data = snap.data();
    final raw = data?['presenceStatus'] as String? ?? 'available';
    return PresenceStatus.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => PresenceStatus.available,
    );
  });
});

/// Streams the count of orders with status != 'delivered' for this shop.
final _pendingOrdersCountProvider = StreamProvider<int>((ref) {
  final shopId = ref.read(shopIdProviderProvider).shopId;
  return FirebaseFirestore.instance
      .collection('shops')
      .doc(shopId)
      .collection('projects')
      .where('status', isNotEqualTo: 'delivered')
      .snapshots()
      .map((snap) => snap.docs.length);
});

/// Streams the count of open udhaar entries (unpaid) for this shop.
final _openUdhaarCountProvider = StreamProvider<int>((ref) {
  final shopId = ref.read(shopIdProviderProvider).shopId;
  return FirebaseFirestore.instance
      .collection('shops')
      .doc(shopId)
      .collection('udhaar')
      .where('status', isEqualTo: 'unpaid')
      .snapshots()
      .map((snap) => snap.docs.length);
});

/// The ops app home dashboard — the primary screen after successful auth.
class HomeDashboard extends ConsumerWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.yugmaTheme;
    final authState = ref.watch(opsAuthControllerProvider);
    final strings = const AppStringsHi();
    final operator = authState.value?.operator;

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
        actions: [
          // Sign-out (S4.1 AC #6)
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: theme.shopTextOnPrimary,
            ),
            color: theme.shopSurface,
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
                  style: theme.bodyDeva.copyWith(
                    color: theme.shopTextPrimary,
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
            // SU007: Shop presence status indicator
            _PresenceStatusBanner(strings: strings),

            // Operator greeting
            if (operator != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: YugmaSpacing.s5,
                  vertical: YugmaSpacing.s2,
                ),
                child: Text(
                  '${operator.displayName} (${operator.role.name})',
                  style: theme.bodyDeva.copyWith(
                    fontSize: YugmaTypeScale.bodyLarge,
                    color: theme.shopTextSecondary,
                  ),
                ),
              ),

            // ── S4.13: Today's task card (prominent at top) ──
            if (operator != null)
              TodaysTaskCard(
                operatorJoinedAt: operator.joinedAt,
              ),

            // ── S4.17: NPS survey card (non-intrusive, bi-weekly) ──
            const NpsCard(),

            const SizedBox(height: YugmaSpacing.s4),

            // ── S4.3: Inventory section — bhaiya + beta only ──
            // S4.2 AC #2: munshi cannot see inventory
            RoleSetGate(
              allowedRoles: const {OperatorRole.bhaiya, OperatorRole.beta},
              child: const _InventorySection(),
            ),
            // ── S4.6: Orders section — all roles ──
            const _OrdersSection(),
            // ── S4.11: Dashboard section — all roles ──
            const _DashboardSection(),
            // ── B1.12: Curation section — bhaiya + beta ──
            RoleSetGate(
              allowedRoles: const {OperatorRole.bhaiya, OperatorRole.beta},
              child: const _CurationSection(),
            ),
            // ── S4.12: Settings — bhaiya only ──
            BhaiyaOnlyGate(
              child: const _SettingsSection(),
            ),
            // ── S4.16: Media spend tile — bhaiya only ──
            BhaiyaOnlyGate(
              child: const MediaSpendTile(),
            ),
            // ── S4.10: Udhaar section — bhaiya + munshi only ──
            // S4.2 AC #2: beta cannot access udhaar
            RoleSetGate(
              allowedRoles: const {OperatorRole.bhaiya, OperatorRole.munshi},
              child: const _UdhaarSection(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inventory section — tappable card that navigates to /inventory.
/// Replaces the placeholder after S4.3 implementation.
class _InventorySection extends StatelessWidget {
  const _InventorySection();

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;
    final strings = const AppStringsHi();

    return GestureDetector(
      onTap: () => context.push('/inventory'),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: YugmaSpacing.s4,
          vertical: YugmaSpacing.s2,
        ),
        padding: const EdgeInsets.all(YugmaSpacing.s5),
        decoration: BoxDecoration(
          color: theme.shopSurface,
          borderRadius: BorderRadius.circular(YugmaRadius.lg),
          border: Border.all(
            color: theme.shopPrimary.withValues(alpha: 0.2),
          ),
          boxShadow: YugmaShadows.card,
        ),
        child: Row(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              color: theme.shopPrimary,
              size: 24,
            ),
            const SizedBox(width: YugmaSpacing.s3),
            Text(
              strings.inventoryTitle,
              style: theme.bodyDeva.copyWith(
                color: theme.shopTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: theme.shopTextMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// Orders section — tappable card that navigates to /orders (S4.6).
/// SU006: shows pending order count badge.
class _OrdersSection extends ConsumerWidget {
  const _OrdersSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.yugmaTheme;
    final strings = const AppStringsHi();
    final pendingCount = ref.watch(_pendingOrdersCountProvider).valueOrNull ?? 0;

    return GestureDetector(
      onTap: () => context.push('/orders'),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: YugmaSpacing.s4,
          vertical: YugmaSpacing.s2,
        ),
        padding: const EdgeInsets.all(YugmaSpacing.s5),
        decoration: BoxDecoration(
          color: theme.shopSurface,
          borderRadius: BorderRadius.circular(YugmaRadius.lg),
          border: Border.all(
            color: theme.shopPrimary.withValues(alpha: 0.2),
          ),
          boxShadow: YugmaShadows.card,
        ),
        child: Row(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              color: theme.shopPrimary,
              size: 24,
            ),
            const SizedBox(width: YugmaSpacing.s3),
            Text(
              strings.ordersTitle,
              style: theme.bodyDeva.copyWith(
                color: theme.shopTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (pendingCount > 0)
              _CountBadge(count: pendingCount, theme: theme),
            Icon(
              Icons.chevron_right,
              color: theme.shopTextMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// B1.12 — Curation section.
class _CurationSection extends StatelessWidget {
  const _CurationSection();

  @override
  Widget build(BuildContext context) {
    final strings = const AppStringsHi();
    final theme = context.yugmaTheme;
    return GestureDetector(
      onTap: () => context.push('/curation'),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: YugmaSpacing.s4,
          vertical: YugmaSpacing.s2,
        ),
        padding: const EdgeInsets.all(YugmaSpacing.s5),
        decoration: BoxDecoration(
          color: theme.shopSurface,
          borderRadius: BorderRadius.circular(YugmaRadius.lg),
          border: Border.all(
            color: theme.shopPrimary.withValues(alpha: 0.2),
          ),
          boxShadow: YugmaShadows.card,
        ),
        child: Row(
          children: [
            Icon(Icons.star_outline, color: theme.shopPrimary, size: 24),
            const SizedBox(width: YugmaSpacing.s3),
            Text(
              strings.homeSectionMyPicks,
              style: theme.bodyDeva.copyWith(
                color: theme.shopTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: theme.shopTextMuted),
          ],
        ),
      ),
    );
  }
}

/// S4.12 — Settings section (bhaiya only).
class _SettingsSection extends StatelessWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context) {
    final strings = const AppStringsHi();
    final theme = context.yugmaTheme;
    return GestureDetector(
      onTap: () => context.push('/settings'),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: YugmaSpacing.s4,
          vertical: YugmaSpacing.s2,
        ),
        padding: const EdgeInsets.all(YugmaSpacing.s5),
        decoration: BoxDecoration(
          color: theme.shopSurface,
          borderRadius: BorderRadius.circular(YugmaRadius.lg),
          border: Border.all(
            color: theme.shopPrimary.withValues(alpha: 0.2),
          ),
          boxShadow: YugmaShadows.card,
        ),
        child: Row(
          children: [
            Icon(Icons.settings_outlined, color: theme.shopPrimary, size: 24),
            const SizedBox(width: YugmaSpacing.s3),
            Text(
              strings.homeSectionSettings,
              style: theme.bodyDeva.copyWith(
                color: theme.shopTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: theme.shopTextMuted),
          ],
        ),
      ),
    );
  }
}

/// S4.11 — Dashboard section (analytics).
class _DashboardSection extends StatelessWidget {
  const _DashboardSection();

  @override
  Widget build(BuildContext context) {
    final strings = const AppStringsHi();
    final theme = context.yugmaTheme;
    return GestureDetector(
      onTap: () => context.push('/dashboard'),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: YugmaSpacing.s4,
          vertical: YugmaSpacing.s2,
        ),
        padding: const EdgeInsets.all(YugmaSpacing.s5),
        decoration: BoxDecoration(
          color: theme.shopSurface,
          borderRadius: BorderRadius.circular(YugmaRadius.lg),
          border: Border.all(
            color: theme.shopPrimary.withValues(alpha: 0.2),
          ),
          boxShadow: YugmaShadows.card,
        ),
        child: Row(
          children: [
            Icon(
              Icons.bar_chart_outlined,
              color: theme.shopPrimary,
              size: 24,
            ),
            const SizedBox(width: YugmaSpacing.s3),
            Text(
              strings.homeSectionDashboard,
              style: TextStyle(
                fontFamily: theme.fontFamilyDevanagariBody,
                fontSize: YugmaTypeScale.body,
                color: theme.shopTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: theme.shopTextMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// S4.10 — Udhaar section (ledger management).
/// SU006: shows open udhaar count badge.
class _UdhaarSection extends ConsumerWidget {
  const _UdhaarSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = const AppStringsHi();
    final theme = context.yugmaTheme;
    final openCount = ref.watch(_openUdhaarCountProvider).valueOrNull ?? 0;

    return GestureDetector(
      onTap: () => context.push('/udhaar'),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: YugmaSpacing.s4,
          vertical: YugmaSpacing.s2,
        ),
        padding: const EdgeInsets.all(YugmaSpacing.s5),
        decoration: BoxDecoration(
          color: theme.shopSurface,
          borderRadius: BorderRadius.circular(YugmaRadius.lg),
          border: Border.all(
            color: theme.shopPrimary.withValues(alpha: 0.2),
          ),
          boxShadow: YugmaShadows.card,
        ),
        child: Row(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              color: theme.shopPrimary,
              size: 24,
            ),
            const SizedBox(width: YugmaSpacing.s3),
            Text(
              strings.homeSectionUdhaar,
              style: theme.bodyDeva.copyWith(
                color: theme.shopTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (openCount > 0)
              _CountBadge(count: openCount, theme: theme),
            Icon(
              Icons.chevron_right,
              color: theme.shopTextMuted,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SU006: Reusable count badge widget for dashboard section cards.
// ---------------------------------------------------------------------------
class _CountBadge extends StatelessWidget {
  final int count;
  final YugmaThemeExtension theme;

  const _CountBadge({required this.count, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: YugmaSpacing.s2),
      padding: const EdgeInsets.symmetric(
        horizontal: YugmaSpacing.s2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: theme.shopAccent,
        borderRadius: BorderRadius.circular(YugmaRadius.pill),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(
          fontFamily: theme.fontFamilyEnglishBody,
          fontSize: YugmaTypeScale.caption,
          fontWeight: FontWeight.w700,
          color: theme.shopPrimaryDeep,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SU007: Presence status banner at top of dashboard.
// ---------------------------------------------------------------------------
class _PresenceStatusBanner extends ConsumerWidget {
  final AppStrings strings;

  const _PresenceStatusBanner({required this.strings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.yugmaTheme;
    final presenceAsync = ref.watch(_shopPresenceProvider);
    final status = presenceAsync.valueOrNull ?? PresenceStatus.available;

    final isAvailable = status == PresenceStatus.available;
    final dotColor = isAvailable
        ? const Color(0xFF3D5C2A) // success green (matches dock dot)
        : theme.shopTextMuted;

    return GestureDetector(
      onTap: () => context.push('/presence'),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: YugmaSpacing.s4,
          vertical: YugmaSpacing.s2,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: YugmaSpacing.s4,
          vertical: YugmaSpacing.s3,
        ),
        decoration: BoxDecoration(
          color: theme.shopSurface,
          borderRadius: BorderRadius.circular(YugmaRadius.md),
          border: Border.all(
            color: isAvailable
                ? const Color(0xFF3D5C2A).withValues(alpha: 0.3)
                : theme.shopDivider,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: YugmaSpacing.s3),
            Text(
              status.label(strings),
              style: theme.bodyDeva.copyWith(
                color: theme.shopTextPrimary,
                fontSize: YugmaTypeScale.body,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.edit_outlined,
              color: theme.shopTextMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
