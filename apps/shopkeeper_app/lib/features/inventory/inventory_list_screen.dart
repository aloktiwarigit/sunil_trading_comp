// =============================================================================
// InventoryListScreen — S4.3 inventory list with + FAB.
//
// Simple list of the shop's inventory SKUs with a FloatingActionButton to
// navigate to the SKU creation form. Real-time listener via Firestore
// snapshots ensures the customer sees new SKUs on next refresh (AC #4).
//
// The list is scoped to the shop via ShopIdProvider and streams all active
// SKUs. For v1 this is the full catalog (typical Ayodhya almirah shop has
// 20-60 SKUs — well within memory).
//
// Binding rules:
//   - ALL strings via AppStrings
//   - ALL theme via YugmaColors/YugmaFonts
//   - Indian number formatting for prices
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lib_core/lib_core.dart';

/// Riverpod provider that streams the shop's inventory as a real-time list.
final inventoryListProvider =
    StreamProvider.autoDispose<List<InventorySku>>((ref) {
  final shopIdProvider = ref.watch(shopIdProviderProvider);
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('shops')
      .doc(shopIdProvider.shopId)
      .collection('inventory')
      .where('isActive', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((doc) {
            final raw = doc.data();
            return InventorySku.fromJson(<String, dynamic>{
              ...raw,
              'skuId': doc.id,
              'createdAt': _normalizeTimestamp(raw['createdAt']),
              'updatedAt': _normalizeTimestamp(raw['updatedAt']),
            });
          }).toList());
});

/// Normalize Firestore Timestamp to ISO8601 string for Freezed parsing.
Object? _normalizeTimestamp(Object? value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate().toIso8601String();
  if (value is DateTime) return value.toIso8601String();
  return value;
}

/// The inventory list screen — shows all active SKUs with a + FAB.
class InventoryListScreen extends ConsumerWidget {
  const InventoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = const AppStringsHi();
    final inventoryAsync = ref.watch(inventoryListProvider);

    return Scaffold(
      backgroundColor: YugmaColors.background,
      appBar: AppBar(
        backgroundColor: YugmaColors.primary,
        foregroundColor: YugmaColors.textOnPrimary,
        title: Text(
          strings.inventoryTitle,
          style: TextStyle(
            fontFamily: YugmaFonts.devaDisplay,
            fontSize: YugmaTypeScale.h3,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/inventory/create'),
        backgroundColor: YugmaColors.primary,
        foregroundColor: YugmaColors.textOnPrimary,
        tooltip: strings.createSkuButton,
        child: const Icon(Icons.add),
      ),
      body: inventoryAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: YugmaColors.primary),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(YugmaSpacing.s4),
            child: Text(
              error.toString(),
              style: TextStyle(
                fontFamily: YugmaFonts.enBody,
                fontSize: YugmaTypeScale.body,
                color: YugmaColors.error,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (skus) {
          if (skus.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(YugmaSpacing.s8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: YugmaColors.textMuted,
                    ),
                    const SizedBox(height: YugmaSpacing.s4),
                    Text(
                      strings.inventoryEmpty,
                      style: TextStyle(
                        fontFamily: YugmaFonts.devaBody,
                        fontSize: YugmaTypeScale.body,
                        color: YugmaColors.textMuted,
                        height: YugmaLineHeights.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.only(
              top: YugmaSpacing.s4,
              bottom: YugmaSpacing.s16, // space for FAB
            ),
            itemCount: skus.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: YugmaColors.divider,
              indent: YugmaSpacing.s4,
              endIndent: YugmaSpacing.s4,
            ),
            itemBuilder: (context, index) {
              final sku = skus[index];
              return GestureDetector(
                onTap: () => context.push('/inventory/${sku.skuId}'),
                child: _SkuListTile(sku: sku),
              );
            },
          );
        },
      ),
    );
  }
}

/// Single SKU list tile — shows name, category, price, stock status.
class _SkuListTile extends StatelessWidget {
  const _SkuListTile({required this.sku});

  final InventorySku sku;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: YugmaSpacing.s4,
        vertical: YugmaSpacing.s3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SKU info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Devanagari name
                Text(
                  sku.nameDevanagari,
                  style: TextStyle(
                    fontFamily: YugmaFonts.devaBody,
                    fontSize: YugmaTypeScale.bodyLarge,
                    color: YugmaColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (sku.name != sku.nameDevanagari && sku.name.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: YugmaSpacing.s1),
                    child: Text(
                      sku.name,
                      style: TextStyle(
                        fontFamily: YugmaFonts.enBody,
                        fontSize: YugmaTypeScale.bodySmall,
                        color: YugmaColors.textSecondary,
                      ),
                    ),
                  ),
                const SizedBox(height: YugmaSpacing.s1),
                // Category + material
                Text(
                  '${_categoryLabel(sku.category)} · ${_materialLabel(sku.material)}',
                  style: TextStyle(
                    fontFamily: YugmaFonts.enBody,
                    fontSize: YugmaTypeScale.caption,
                    color: YugmaColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Price + stock badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\u20b9${_formatInr(sku.basePrice)}',
                style: TextStyle(
                  fontFamily: YugmaFonts.mono,
                  fontSize: YugmaTypeScale.bodyLarge,
                  color: YugmaColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: YugmaSpacing.s1),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: YugmaSpacing.s2,
                  vertical: YugmaSpacing.s1,
                ),
                decoration: BoxDecoration(
                  color: sku.inStock
                      ? YugmaColors.success.withValues(alpha: 0.12)
                      : YugmaColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(YugmaRadius.sm),
                ),
                child: Text(
                  sku.inStock ? 'In stock' : 'Out',
                  style: TextStyle(
                    fontFamily: YugmaFonts.enBody,
                    fontSize: YugmaTypeScale.label,
                    color: sku.inStock ? YugmaColors.success : YugmaColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _categoryLabel(SkuCategory c) {
    switch (c) {
      case SkuCategory.steelAlmirah:
        return 'Steel Almirah';
      case SkuCategory.woodenWardrobe:
        return 'Wooden Wardrobe';
      case SkuCategory.modular:
        return 'Modular';
      case SkuCategory.dressing:
        return 'Dressing Table';
      case SkuCategory.sideCabinet:
        return 'Side Cabinet';
    }
  }

  static String _materialLabel(SkuMaterial m) {
    switch (m) {
      case SkuMaterial.steel:
        return 'Steel';
      case SkuMaterial.woodSheesham:
        return 'Sheesham';
      case SkuMaterial.woodTeak:
        return 'Teak';
      case SkuMaterial.plyLaminate:
        return 'Ply / Laminate';
    }
  }

  /// Indian number formatting for prices.
  static String _formatInr(int amount) {
    if (amount < 1000) return amount.toString();
    final str = amount.toString();
    if (str.length <= 3) return str;
    final lastThree = str.substring(str.length - 3);
    final rest = str.substring(0, str.length - 3);
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
