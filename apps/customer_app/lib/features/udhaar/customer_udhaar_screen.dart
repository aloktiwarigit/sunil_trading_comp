// =============================================================================
// CustomerUdhaarScreen — B-5: read-only udhaar (credit) balance view.
//
// Streams the customer's open udhaar ledgers via UdhaarLedgerRepo.watchByCustomer()
// and displays recorded amount, running balance, partial payment count,
// reminder count, and closed status.
//
// READ-ONLY — customer cannot modify udhaar entries per ADR-010.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';

import '../../main.dart' show authProviderInstanceProvider;

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final _udhaarLedgerRepoProvider = Provider<UdhaarLedgerRepo>((ref) {
  return UdhaarLedgerRepo(
    firestore: FirebaseFirestore.instance,
    shopIdProvider: ref.read(shopIdProviderProvider),
  );
});

/// Streams the current customer's udhaar ledgers.
final _customerUdhaarLedgersProvider =
    StreamProvider.autoDispose<List<UdhaarLedger>>((ref) {
  final repo = ref.read(_udhaarLedgerRepoProvider);
  final uid = ref.read(authProviderInstanceProvider).currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return repo.watchByCustomer(uid);
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// B-5: Customer udhaar balance view — read-only.
class CustomerUdhaarScreen extends ConsumerWidget {
  const CustomerUdhaarScreen({
    super.key,
    required this.strings,
  });

  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.yugmaTheme;
    final ledgersAsync = ref.watch(_customerUdhaarLedgersProvider);

    return Scaffold(
      backgroundColor: theme.shopBackground,
      appBar: AppBar(
        backgroundColor: theme.shopPrimary,
        foregroundColor: theme.shopTextOnPrimary,
        title: Text(
          strings.udhaarScreenTitle,
          style: TextStyle(
            fontFamily: theme.fontFamilyDevanagariDisplay,
            fontSize: YugmaTypeScale.h3,
          ),
        ),
      ),
      body: ledgersAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: theme.shopAccent),
        ),
        error: (err, _) => Center(
          child: Text(
            err.toString(),
            style: theme.bodyDeva,
          ),
        ),
        data: (ledgers) {
          if (ledgers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(YugmaSpacing.s4),
                child: Text(
                  strings.udhaarNoLedgers,
                  style: theme.bodyDeva.copyWith(
                    color: theme.shopTextMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // Separate open and closed ledgers.
          final open = ledgers.where((l) => !l.isClosed).toList();
          final closed = ledgers.where((l) => l.isClosed).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(YugmaSpacing.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary card — total बाकी
                _buildSummaryCard(context, theme, open),
                const SizedBox(height: YugmaSpacing.s4),

                // Open ledgers
                if (open.isNotEmpty) ...[
                  Text(
                    strings.udhaarOpenLedgers,
                    style: theme.bodyDeva.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: YugmaTypeScale.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: YugmaSpacing.s2),
                  for (final ledger in open)
                    _buildLedgerCard(context, theme, ledger),
                ],

                // Closed ledgers
                if (closed.isNotEmpty) ...[
                  const SizedBox(height: YugmaSpacing.s4),
                  Text(
                    strings.udhaarClosedLedgers,
                    style: theme.bodyDeva.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: YugmaTypeScale.bodyLarge,
                      color: theme.shopTextMuted,
                    ),
                  ),
                  const SizedBox(height: YugmaSpacing.s2),
                  for (final ledger in closed)
                    _buildLedgerCard(context, theme, ledger),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// Summary card showing total outstanding balance across all open ledgers.
  Widget _buildSummaryCard(
    BuildContext context,
    YugmaThemeExtension theme,
    List<UdhaarLedger> openLedgers,
  ) {
    final totalBaaki = openLedgers.fold<int>(
      0,
      (sum, l) => sum + l.runningBalance,
    );

    return Container(
      width: double.infinity,
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
            strings.udhaarTotalBaaki,
            style: theme.captionDeva,
          ),
          const SizedBox(height: YugmaSpacing.s1),
          Text(
            '₹${formatInr(totalBaaki)}',
            style: theme.monoNumeral.copyWith(
              fontSize: YugmaTypeScale.display,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: YugmaSpacing.s1),
          Text(
            strings.udhaarOpenAccountsCount(openLedgers.length),
            style: theme.captionDeva,
          ),
        ],
      ),
    );
  }

  /// Individual ledger card — shows recorded amount, running balance,
  /// partial payment count, reminder count, and closed status.
  Widget _buildLedgerCard(
    BuildContext context,
    YugmaThemeExtension theme,
    UdhaarLedger ledger,
  ) {
    final isClosed = ledger.isClosed;

    return Padding(
      padding: const EdgeInsets.only(bottom: YugmaSpacing.s3),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(YugmaSpacing.s4),
        decoration: BoxDecoration(
          color: theme.shopSurface,
          borderRadius: BorderRadius.circular(YugmaRadius.lg),
          boxShadow: YugmaShadows.card,
          border: isClosed
              ? Border.all(
                  color: theme.shopDivider,
                  width: 1,
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row: recorded amount + closed badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${strings.udhaarOriginalAmountPrefix}: ₹${formatInr(ledger.recordedAmount)}',
                    style: theme.bodyDeva.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isClosed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: YugmaSpacing.s2,
                      vertical: YugmaSpacing.s1,
                    ),
                    decoration: BoxDecoration(
                      color: theme.shopCommit.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(YugmaRadius.sm),
                    ),
                    child: Text(
                      strings.udhaarSettledBadge,
                      style: theme.captionDeva.copyWith(
                        color: theme.shopCommit,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: YugmaSpacing.s2),

            // Running balance
            if (!isClosed) ...[
              Text(
                strings.udhaarBaakiLabel,
                style: theme.captionDeva,
              ),
              const SizedBox(height: 2),
              Text(
                '₹${formatInr(ledger.runningBalance)}',
                style: theme.monoNumeral,
              ),
              const SizedBox(height: YugmaSpacing.s2),
            ],

            // Partial payments count
            if (ledger.partialPaymentReferences.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: YugmaSpacing.s1),
                child: Row(
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      size: 16,
                      color: theme.shopTextMuted,
                      semanticLabel: '',
                    ),
                    const SizedBox(width: YugmaSpacing.s1),
                    Text(
                      strings.udhaarPartialPaymentCount(ledger.partialPaymentReferences.length),
                      style: theme.captionDeva,
                    ),
                  ],
                ),
              ),

            // Reminder count
            if (ledger.reminderCountLifetime > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: YugmaSpacing.s1),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      size: 16,
                      color: theme.shopTextMuted,
                      semanticLabel: '',
                    ),
                    const SizedBox(width: YugmaSpacing.s1),
                    Text(
                      strings.udhaarRemindersSentCount(ledger.reminderCountLifetime),
                      style: theme.captionDeva,
                    ),
                  ],
                ),
              ),

            // Ledger ID (truncated)
            Text(
              '#${ledger.ledgerId.length > 6 ? ledger.ledgerId.substring(ledger.ledgerId.length - 6) : ledger.ledgerId}',
              style: theme.monoNumeral.copyWith(
                fontSize: YugmaTypeScale.caption,
                color: theme.shopTextMuted,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
