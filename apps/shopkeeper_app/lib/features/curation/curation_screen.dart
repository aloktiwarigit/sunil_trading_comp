// =============================================================================
// CurationScreen — B1.12: "Remote control for the finger" curation UX.
//
// AC #1: single screen titled "मेरी पसंद"
// AC #2: six tabs for occasion shortlists
// AC #3: vertical drag-to-reorder list per tab
// AC #4: "add from inventory" horizontal scroll below
// AC #5: long-press to remove
// AC #6: drag handle for reorder
// AC #7: auto-save on every change
// AC #8: badge showing count per tab
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';

/// The 6 occasion shortlist keys per B1.4 + B1.12.
const _occasionKeys = <String>[
  'shaadi',
  'naya_ghar',
  'dahej',
  'purana_badalne',
  'budget',
  'ladies',
];

/// D-2: Resolve occasion label from AppStrings.
String _occasionLabel(String key, AppStrings strings) => switch (key) {
      'shaadi' => strings.shortlistTitleShaadi,
      'naya_ghar' => strings.shortlistTitleNayaGhar,
      'dahej' => strings.shortlistTitleDahej,
      'purana_badalne' => strings.shortlistTitlePuranaBadlne,
      'budget' => strings.shortlistTitleBudget,
      'ladies' => strings.shortlistTitleLadies,
      _ => key,
    };

/// Provider for all shortlists in the shop.
final shortlistsProvider = StreamProvider.autoDispose<
    Map<String, List<String>>>((ref) {
  final firestore = FirebaseFirestore.instance;
  final shopId = ref.read(shopIdProviderProvider).shopId;

  return firestore
      .collection('shops')
      .doc(shopId)
      .collection('curated_shortlists')
      .snapshots()
      .map((snap) {
    final result = <String, List<String>>{};
    for (final doc in snap.docs) {
      final skuIds = List<String>.from(
        doc.data()['skuIds'] as List? ?? <String>[],
      );
      result[doc.id] = skuIds;
    }
    return result;
  });
});

/// Provider for all inventory SKUs (for the "add" section).
final allInventoryProvider =
    StreamProvider.autoDispose<List<InventorySku>>((ref) {
  final firestore = FirebaseFirestore.instance;
  final shopId = ref.read(shopIdProviderProvider).shopId;

  return firestore
      .collection('shops')
      .doc(shopId)
      .collection('inventory')
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

Object? _normalizeTimestamp(Object? value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate().toIso8601String();
  if (value is DateTime) return value.toIso8601String();
  return value;
}

/// B1.12 — Curation screen.
class CurationScreen extends ConsumerStatefulWidget {
  const CurationScreen({super.key});

  @override
  ConsumerState<CurationScreen> createState() => _CurationScreenState();
}

class _CurationScreenState extends ConsumerState<CurationScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _occasionKeys.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = const AppStringsHi();
    final shortlistsAsync = ref.watch(shortlistsProvider);
    final inventoryAsync = ref.watch(allInventoryProvider);

    return Scaffold(
      backgroundColor: YugmaColors.background,
      appBar: AppBar(
        backgroundColor: YugmaColors.primary,
        foregroundColor: YugmaColors.textOnPrimary,
        title: Text(
          strings.curationMyPicks,
          style: TextStyle(
            fontFamily: YugmaFonts.devaDisplay,
            fontSize: YugmaTypeScale.h3,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: YugmaColors.textOnPrimary,
          labelColor: YugmaColors.textOnPrimary,
          unselectedLabelColor: YugmaColors.textOnPrimary.withValues(alpha: 0.6),
          labelStyle: TextStyle(
            fontFamily: YugmaFonts.devaBody,
            fontSize: YugmaTypeScale.caption,
            fontWeight: FontWeight.w600,
          ),
          tabs: _occasionKeys.map((key) {
            final count = shortlistsAsync.valueOrNull?[key]?.length ?? 0;
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_occasionLabel(key, strings)),
                  if (count > 0) ...[
                    const SizedBox(width: 4),
                    // AC #8: badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: YugmaColors.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontFamily: YugmaFonts.mono,
                          fontSize: 10,
                          color: YugmaColors.textOnPrimary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: shortlistsAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: YugmaColors.primary),
        ),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (shortlists) {
          final inventory = inventoryAsync.valueOrNull ?? <InventorySku>[];
          return TabBarView(
            controller: _tabController,
            children: _occasionKeys.map((occasionTag) {
              final skuIds = shortlists[occasionTag] ?? <String>[];
              return _OccasionTab(
                occasionTag: occasionTag,
                skuIds: skuIds,
                allInventory: inventory,
                strings: strings,
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

/// A single occasion tab — shows the shortlist + "add from inventory".
class _OccasionTab extends ConsumerWidget {
  const _OccasionTab({
    required this.occasionTag,
    required this.skuIds,
    required this.allInventory,
    required this.strings,
  });

  final String occasionTag;
  final List<String> skuIds;
  final List<InventorySku> allInventory;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inShortlist = skuIds.toSet();
    final available = allInventory
        .where((sku) => !inShortlist.contains(sku.skuId))
        .toList();

    return Column(
      children: [
        // AC #3: reorderable list
        Expanded(
          child: skuIds.isEmpty
              ? Center(
                  child: Text(
                    strings.curationEmptyPrompt,
                    style: TextStyle(
                      fontFamily: YugmaFonts.devaBody,
                      fontSize: YugmaTypeScale.body,
                      color: YugmaColors.textMuted,
                    ),
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(YugmaSpacing.s2),
                  itemCount: skuIds.length,
                  onReorder: (oldIndex, newIndex) {
                    final updated = List<String>.from(skuIds);
                    if (newIndex > oldIndex) newIndex--;
                    final item = updated.removeAt(oldIndex);
                    updated.insert(newIndex, item);
                    _saveOrder(ref, updated);
                  },
                  itemBuilder: (ctx, i) {
                    final sku = allInventory
                        .where((s) => s.skuId == skuIds[i])
                        .firstOrNull;
                    return Dismissible(
                      key: ValueKey(skuIds[i]),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: YugmaColors.commit.withValues(alpha: 0.15),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(
                            right: YugmaSpacing.s4),
                        child: Icon(Icons.delete_outline,
                            color: YugmaColors.commit),
                      ),
                      // AC #5: long-press or swipe to remove
                      onDismissed: (_) {
                        final updated = List<String>.from(skuIds)
                          ..removeAt(i);
                        _saveOrder(ref, updated);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(
                            bottom: YugmaSpacing.s1),
                        padding: const EdgeInsets.all(YugmaSpacing.s3),
                        decoration: BoxDecoration(
                          color: YugmaColors.surface,
                          borderRadius:
                              BorderRadius.circular(YugmaRadius.md),
                          boxShadow: YugmaShadows.card,
                        ),
                        child: Row(
                          children: [
                            // AC #6: drag handle
                            Icon(Icons.drag_handle,
                                color: YugmaColors.textMuted, size: 20),
                            const SizedBox(width: YugmaSpacing.s2),
                            Expanded(
                              child: Text(
                                sku?.nameDevanagari ?? skuIds[i],
                                style: TextStyle(
                                  fontFamily: YugmaFonts.devaBody,
                                  fontSize: YugmaTypeScale.body,
                                  color: YugmaColors.textPrimary,
                                ),
                              ),
                            ),
                            if (sku != null)
                              Text(
                                '₹${sku.basePrice}',
                                style: TextStyle(
                                  fontFamily: YugmaFonts.mono,
                                  fontSize: YugmaTypeScale.caption,
                                  color: YugmaColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        // AC #4: "Add from inventory" horizontal scroll
        if (available.isNotEmpty)
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: YugmaColors.surface,
              border: Border(
                top: BorderSide(color: YugmaColors.divider),
              ),
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(YugmaSpacing.s2),
              itemCount: available.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: YugmaSpacing.s2),
              itemBuilder: (ctx, i) {
                final sku = available[i];
                return InkWell(
                  onTap: () {
                    final updated = List<String>.from(skuIds)
                      ..add(sku.skuId);
                    _saveOrder(ref, updated);
                  },
                  borderRadius: BorderRadius.circular(YugmaRadius.md),
                  child: Container(
                    padding: const EdgeInsets.all(YugmaSpacing.s2),
                    decoration: BoxDecoration(
                      border: Border.all(color: YugmaColors.divider),
                      borderRadius:
                          BorderRadius.circular(YugmaRadius.md),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          sku.nameDevanagari,
                          style: TextStyle(
                            fontFamily: YugmaFonts.devaBody,
                            fontSize: YugmaTypeScale.caption,
                            color: YugmaColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          strings.curationAddButton,
                          style: TextStyle(
                            fontFamily: YugmaFonts.devaBody,
                            fontSize: 10,
                            color: YugmaColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  /// AC #7: auto-save on every change.
  void _saveOrder(WidgetRef ref, List<String> updatedSkuIds) {
    final shopId = ref.read(shopIdProviderProvider).shopId;
    FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .collection('curated_shortlists')
        .doc(occasionTag)
        .set(<String, dynamic>{
      'occasionTag': occasionTag,
      'skuIds': updatedSkuIds,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
