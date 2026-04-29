// =============================================================================
// DraftListScreen — shows current draft line items with remove/quantity controls.
//
// Per C3.1 AC #5: Draft is visible in a "My List" section accessible from
// the landing screen.
//
// All strings via AppStrings. All colors via context.yugmaTheme per ADR-003.
// =============================================================================

import 'package:customer_app/features/project/draft_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';

/// Screen showing the customer's draft project line items.
///
/// Parameters:
///   [strings] — locale-resolved AppStrings instance.
class DraftListScreen extends ConsumerWidget {
  /// Create the draft list screen.
  const DraftListScreen({
    super.key,
    required this.strings,
    this.onBrowse,
    this.onTalkToBhaiya,
    this.onCommit,
  });

  /// Locale-resolved strings.
  final AppStrings strings;

  /// Called when user taps "keep browsing" or back navigation from empty state.
  final VoidCallback? onBrowse;

  /// Called when user taps "talk to bhaiya" to open chat.
  final VoidCallback? onTalkToBhaiya;

  /// Called when user taps "ऑर्डर पक्का कीजिए" to start commit flow (C3.4).
  final VoidCallback? onCommit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.yugmaTheme;
    final draftAsync = ref.watch(draftControllerProvider);

    return Scaffold(
      backgroundColor: theme.shopBackground,
      appBar: AppBar(
        title: Text(
          strings.myListTitle,
          style: theme.h2Deva,
        ),
        backgroundColor: theme.shopBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: theme.shopPrimary),
      ),
      body: draftAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: theme.shopAccent),
        ),
        error: (err, _) => YugmaErrorBanner(error: err),
        data: (draftState) {
          if (draftState.isEmpty) {
            return _buildEmptyState(context, theme);
          }
          return _buildItemsList(context, ref, theme, draftState);
        },
      ),
    );
  }

  static int _computeTotal(DraftState draftState) {
    return draftState.lineItems.fold<int>(
      0,
      (sum, item) => sum + item.lineTotalInr,
    );
  }

  Widget _buildEmptyState(BuildContext context, YugmaThemeExtension theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(YugmaSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.list_alt_outlined,
              size: 64,
              color: theme.shopTextMuted,
              semanticLabel: '',
            ),
            const SizedBox(height: YugmaSpacing.s4),
            Text(
              strings.emptyDraftList,
              style: theme.bodyDeva.copyWith(color: theme.shopTextSecondary),
              textAlign: TextAlign.center,
            ),
            if (onBrowse != null) ...[
              const SizedBox(height: YugmaSpacing.s6),
              SizedBox(
                height: theme.tapTargetMin,
                child: ElevatedButton(
                  onPressed: onBrowse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.shopPrimary,
                    foregroundColor: theme.shopTextOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(YugmaRadius.md),
                    ),
                  ),
                  child: Text(
                    strings.skuAddToList,
                    style: TextStyle(
                      fontFamily: theme.fontFamilyDevanagariBody,
                      fontSize: theme.isElderTier ? 18.0 : 15.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(
    BuildContext context,
    WidgetRef ref,
    YugmaThemeExtension theme,
    DraftState draftState,
  ) {
    final items = draftState.lineItems;

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(YugmaSpacing.s4),
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                Divider(color: theme.shopDivider, height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              // C3.2 AC #2: swipe-to-dismiss with undo snackbar.
              return Dismissible(
                key: ValueKey(item.lineItemId),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding:
                      const EdgeInsets.only(right: YugmaSpacing.s4),
                  color: theme.shopCommit.withValues(alpha: 0.15),
                  child: Icon(
                    Icons.delete_outline,
                    color: theme.shopCommit,
                    semanticLabel: 'Remove item',
                  ),
                ),
                onDismissed: (_) {
                  HapticFeedback.mediumImpact();
                  final removedItem = item;
                  ref
                      .read(draftControllerProvider.notifier)
                      .removeLineItem(removedItem.lineItemId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        strings.draftItemRemoved(removedItem.skuName),
                      ),
                      action: SnackBarAction(
                        label: strings.draftUndoRemove,
                        onPressed: () {
                          // Re-add the removed item via addSku is not
                          // perfect (generates new lineItemId), but
                          // preserves the undo UX. A full undo would
                          // require caching the old state.
                          ref
                              .read(draftControllerProvider.notifier)
                              .undoRemoveLineItem(removedItem);
                        },
                      ),
                    ),
                  );
                },
                child: _DraftLineItemTile(
                  item: item,
                  theme: theme,
                  strings: strings,
                  onRemove: () {
                    ref
                        .read(draftControllerProvider.notifier)
                        .removeLineItem(item.lineItemId);
                  },
                  onQuantityChanged: (qty) async {
                    // C3.2 Edge #3: qty > 10 confirmation prompt.
                    if (qty > 10) {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(
                            strings.draftQtyHighTitle,
                            style: theme.h2Deva,
                          ),
                          content: Text(
                            strings.draftQtyHighBody(qty, item.skuName),
                            style: theme.bodyDeva,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(false),
                              child: Text(
                                strings.draftQtyHighCancel,
                                style: TextStyle(
                                  fontFamily:
                                      theme.fontFamilyDevanagariBody,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(true),
                              child: Text(
                                strings.draftQtyHighConfirm,
                                style: TextStyle(
                                  fontFamily:
                                      theme.fontFamilyDevanagariBody,
                                  color: theme.shopPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                    }
                    ref
                        .read(draftControllerProvider.notifier)
                        .updateQuantity(item.lineItemId, qty);
                  },
                ),
              );
            },
          ),
        ),
        // Bottom action bar
        _buildBottomBar(context, ref, theme, draftState),
      ],
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    WidgetRef ref,
    YugmaThemeExtension theme,
    DraftState draftState,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.shopSurface,
        boxShadow: YugmaShadows.card,
      ),
      padding: const EdgeInsets.all(YugmaSpacing.s4),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // C3.2 AC #3: show recomputed total.
            Padding(
              padding:
                  const EdgeInsets.only(bottom: YugmaSpacing.s3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    strings.draftTotalLabel,
                    style: theme.bodyDeva.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '\u20B9${formatInr(_computeTotal(draftState))}',
                    style: theme.monoNumeral.copyWith(
                      fontSize: theme.isElderTier ? 20.0 : 17.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            // C3.4 — Oxblood commit button (first legitimate use of shopCommit)
            if (onCommit != null)
              SizedBox(
                height: theme.tapTargetMin,
                child: ElevatedButton(
                  onPressed: onCommit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.shopCommit,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(YugmaRadius.md),
                    ),
                    textStyle: TextStyle(
                      fontFamily: theme.fontFamilyDevanagariBody,
                      fontSize: theme.isElderTier ? 20.0 : 16.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(strings.commitButtonPakka),
                ),
              ),
            if (onCommit != null && onTalkToBhaiya != null)
              const SizedBox(height: YugmaSpacing.s2),
            if (onTalkToBhaiya != null)
              SizedBox(
                height: theme.tapTargetMin,
                child: OutlinedButton(
                  onPressed: onTalkToBhaiya,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.shopPrimary,
                    side: BorderSide(color: theme.shopPrimary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(YugmaRadius.md),
                    ),
                    textStyle: TextStyle(
                      fontFamily: theme.fontFamilyDevanagariBody,
                      fontSize: theme.isElderTier ? 18.0 : 15.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(strings.skuTalkToBhaiya),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Individual line item tile in the draft list.
class _DraftLineItemTile extends StatelessWidget {
  const _DraftLineItemTile({
    required this.item,
    required this.theme,
    required this.strings,
    required this.onRemove,
    required this.onQuantityChanged,
  });

  final LineItem item;
  final YugmaThemeExtension theme;
  final AppStrings strings;
  final VoidCallback onRemove;
  final ValueChanged<int> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: YugmaSpacing.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SKU name + price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.skuName,
                  style: theme.bodyDeva.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: YugmaSpacing.s1),
                Text(
                  '\u20B9${formatInr(item.unitPriceInr)}',
                  style: theme.monoNumeral.copyWith(
                    fontSize: theme.isElderTier ? 18.0 : 15.0,
                  ),
                ),
              ],
            ),
          ),
          // Quantity controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _QuantityButton(
                icon: Icons.remove,
                theme: theme,
                semanticLabel: 'Decrease quantity',
                onTap: item.quantity > 1
                    ? () => onQuantityChanged(item.quantity - 1)
                    : null,
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: YugmaSpacing.s2),
                child: Text(
                  '${item.quantity}',
                  style: theme.monoNumeral.copyWith(
                    fontSize: theme.isElderTier ? 18.0 : 15.0,
                  ),
                ),
              ),
              _QuantityButton(
                icon: Icons.add,
                theme: theme,
                semanticLabel: 'Increase quantity',
                onTap: () => onQuantityChanged(item.quantity + 1),
              ),
            ],
          ),
          // Remove button
          IconButton(
            icon: Icon(
              Icons.close,
              color: theme.shopTextMuted,
              size: 20,
              semanticLabel: 'Remove item',
            ),
            onPressed: onRemove,
            constraints: BoxConstraints(
              minWidth: theme.tapTargetMin,
              minHeight: theme.tapTargetMin,
            ),
          ),
        ],
      ),
    );
  }

}

/// Small quantity +/- button.
class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.theme,
    this.onTap,
    this.semanticLabel,
  });

  final IconData icon;
  final YugmaThemeExtension theme;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap != null
          ? theme.shopAccent.withValues(alpha: 0.12)
          : theme.shopDivider,
      borderRadius: BorderRadius.circular(YugmaRadius.sm),
      child: InkWell(
        onTap: onTap != null
            ? () {
                HapticFeedback.selectionClick();
                onTap!();
              }
            : null,
        borderRadius: BorderRadius.circular(YugmaRadius.sm),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            size: 18,
            color: onTap != null ? theme.shopPrimary : theme.shopTextMuted,
            semanticLabel: semanticLabel,
          ),
        ),
      ),
    );
  }
}
