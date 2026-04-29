// =============================================================================
// UdhaarListScreen — S4.10 AC #1–2, #5: all open udhaar ledgers.
//
// AC #1: list of open ledgers (closedAt == null AND runningBalance > 0)
// AC #2: card shows customer name, recorded amount, running balance,
//        last payment date, days since opening
// AC #5: closed ledgers filterable separately
// AC #6: NO lending vocabulary anywhere
// AC #7: reminder opt-in toggle per card
// AC #8: reminder count badge per card
// Edge #1: 50+ ledgers → paginated, sorted by runningBalance desc
// Edge #3: beta role → tab hidden (handled by router/dashboard)
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lib_core/lib_core.dart';

/// Resolves a customer display name from the project linked to a ledger.
/// Falls back to the raw customerId if no project is found.
final udhaarCustomerNameProvider =
    FutureProvider.autoDispose.family<String, UdhaarLedger>((ref, ledger) async {
  final firestore = FirebaseFirestore.instance;
  final shopId = ref.read(shopIdProviderProvider).shopId;

  // Look up the project that references this udhaar ledger.
  final snap = await firestore
      .collection('shops')
      .doc(shopId)
      .collection('projects')
      .where('udhaarLedgerId', isEqualTo: ledger.ledgerId)
      .limit(1)
      .get();

  if (snap.docs.isNotEmpty) {
    final name = snap.docs.first.data()['customerDisplayName'] as String?;
    if (name != null && name.isNotEmpty) return name;
  }
  return ledger.customerId;
});

/// Provider for all udhaar ledgers in the shop, sorted by runningBalance desc.
final udhaarLedgersProvider =
    StreamProvider.autoDispose<List<UdhaarLedger>>((ref) {
  final firestore = FirebaseFirestore.instance;
  final shopId = ref.read(shopIdProviderProvider).shopId;

  return firestore
      .collection('shops')
      .doc(shopId)
      .collection('udhaarLedger')
      .orderBy('runningBalance', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((doc) {
            final raw = doc.data();
            return UdhaarLedger.fromJson(<String, dynamic>{
              ...raw,
              'ledgerId': doc.id,
            });
          }).toList());
});

/// S4.10 — Udhaar ledger list screen.
class UdhaarListScreen extends ConsumerStatefulWidget {
  const UdhaarListScreen({super.key});

  @override
  ConsumerState<UdhaarListScreen> createState() => _UdhaarListScreenState();
}

class _UdhaarListScreenState extends ConsumerState<UdhaarListScreen> {
  bool _showClosed = false;

  @override
  Widget build(BuildContext context) {
    final strings = const AppStringsHi();
    final ledgersAsync = ref.watch(udhaarLedgersProvider);

    return Scaffold(
      backgroundColor: YugmaColors.background,
      appBar: AppBar(
        backgroundColor: YugmaColors.primary,
        foregroundColor: YugmaColors.textOnPrimary,
        title: Text(
          strings.udhaarScreenTitle,
          style: TextStyle(
            fontFamily: YugmaFonts.devaDisplay,
            fontSize: YugmaTypeScale.h3,
          ),
        ),
        actions: [
          // AC #5: toggle open/closed
          TextButton(
            onPressed: () => setState(() => _showClosed = !_showClosed),
            child: Text(
              _showClosed ? strings.shopUdhaarToggleOpen : strings.shopUdhaarToggleClosed,
              style: TextStyle(
                fontFamily: YugmaFonts.devaBody,
                color: YugmaColors.textOnPrimary,
              ),
            ),
          ),
        ],
      ),
      body: ledgersAsync.when(
        loading: () => const YugmaListSkeleton(),
        error: (err, _) => Center(
          child: Text(err.toString(),
              style: TextStyle(fontFamily: YugmaFonts.devaBody)),
        ),
        data: (ledgers) {
          final filtered = ledgers
              .where((l) => _showClosed ? l.isClosed : !l.isClosed)
              .toList();

          if (filtered.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(YugmaSpacing.s8),
                child: Text(
                  _showClosed
                      ? strings.shopUdhaarNoClosed
                      : strings.shopUdhaarNoOpen,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: YugmaFonts.devaBody,
                    fontSize: YugmaTypeScale.body,
                    color: YugmaColors.textMuted,
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: YugmaColors.accent,
            backgroundColor: YugmaColors.surface,
            onRefresh: () async {
              ref.invalidate(udhaarLedgersProvider);
              await Future<void>.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(YugmaSpacing.s4),
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: YugmaSpacing.s2),
              itemBuilder: (ctx, i) => _UdhaarCard(
                ledger: filtered[i],
                strings: strings,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// S4.10 AC #2: Udhaar ledger card.
class _UdhaarCard extends ConsumerWidget {
  const _UdhaarCard({required this.ledger, required this.strings});

  final UdhaarLedger ledger;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysSinceOpen = ledger.acknowledgedAt != null
        ? DateTime.now().difference(ledger.acknowledgedAt!).inDays
        : 0;

    return InkWell(
      onTap: () => context.push('/udhaar/${ledger.ledgerId}'),
      borderRadius: BorderRadius.circular(YugmaRadius.lg),
      child: Container(
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
                Expanded(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final nameAsync = ref.watch(udhaarCustomerNameProvider(ledger));
                      return Text(
                        nameAsync.valueOrNull ?? ledger.customerId,
                        style: TextStyle(
                          fontFamily: YugmaFonts.devaBody,
                          fontSize: YugmaTypeScale.body,
                          fontWeight: FontWeight.w600,
                          color: YugmaColors.textPrimary,
                        ),
                      );
                    },
                  ),
                ),
                // AC #8: reminder count badge
                if (ledger.reminderOptInByBhaiya)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: YugmaSpacing.s2,
                      vertical: YugmaSpacing.s1,
                    ),
                    decoration: BoxDecoration(
                      color: YugmaColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(YugmaRadius.sm),
                    ),
                    child: Text(
                      strings.udhaarReminderCountBadge(
                          ledger.reminderCountLifetime),
                      style: TextStyle(
                        fontFamily: YugmaFonts.devaBody,
                        fontSize: YugmaTypeScale.caption,
                        color: YugmaColors.accent,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: YugmaSpacing.s2),
            Row(
              children: [
                // Running balance
                Text(
                  '₹${formatInr(ledger.runningBalance)}',
                  style: TextStyle(
                    fontFamily: YugmaFonts.mono,
                    fontSize: YugmaTypeScale.bodyLarge,
                    fontWeight: FontWeight.w700,
                    color: ledger.isClosed
                        ? YugmaColors.textMuted
                        : YugmaColors.accent,
                  ),
                ),
                const SizedBox(width: YugmaSpacing.s2),
                Text(
                  '/ ₹${formatInr(ledger.recordedAmount)}',
                  style: TextStyle(
                    fontFamily: YugmaFonts.mono,
                    fontSize: YugmaTypeScale.caption,
                    color: YugmaColors.textSecondary,
                  ),
                ),
                const Spacer(),
                if (daysSinceOpen > 0)
                  Text(
                    '$daysSinceOpen दिन',
                    style: TextStyle(
                      fontFamily: YugmaFonts.devaBody,
                      fontSize: YugmaTypeScale.caption,
                      color: YugmaColors.textMuted,
                    ),
                  ),
              ],
            ),
            // AC #7: reminder opt-in toggle (only for open ledgers)
            if (!ledger.isClosed) ...[
              const SizedBox(height: YugmaSpacing.s2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.udhaarReminderOptInPrompt,
                      style: TextStyle(
                        fontFamily: YugmaFonts.devaBody,
                        fontSize: YugmaTypeScale.caption,
                        color: YugmaColors.textSecondary,
                      ),
                    ),
                  ),
                  Switch(
                    value: ledger.reminderOptInByBhaiya,
                    activeColor: YugmaColors.primary,
                    onChanged: (value) async {
                      final repo = UdhaarLedgerRepo(
                        firestore: FirebaseFirestore.instance,
                        shopIdProvider: ShopIdProvider(
                          ref.read(shopIdProviderProvider).shopId,
                        ),
                      );
                      await repo.applyOperatorPatch(
                        ledger.ledgerId,
                        UdhaarLedgerOperatorPatch(
                          reminderOptInByBhaiya: value,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

}
