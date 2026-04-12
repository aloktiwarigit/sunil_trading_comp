// =============================================================================
// Shortlist providers — Riverpod providers for B1.4 curated catalog browsing.
//
// Per PRD B1.4:
//   AC #1: 6 named occasion shortlists displayed on landing
//   AC #2: Each contains EXACTLY 6 SKU cards (finite, shopkeeper-curated)
//   AC #3: Customer taps shortlist tile → full shortlist screen
//   AC #4: Customer taps SKU card → full SKU detail screen
//
// Data flow:
//   BharosaLanding (preview tiles) → ShortlistScreen → SkuDetailCard
//
// All Firestore reads are scoped by shopId via lib_core repos.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';

// ---------------------------------------------------------------------------
// Repo providers — scoped by shopId
// ---------------------------------------------------------------------------

final _curatedShortlistRepoProvider = Provider<CuratedShortlistRepo>((ref) {
  return CuratedShortlistRepo(
    firestore: FirebaseFirestore.instance,
    shopIdProvider: ref.read(shopIdProviderProvider),
  );
});

final _inventorySkuRepoProvider = Provider<InventorySkuRepo>((ref) {
  return InventorySkuRepo(
    firestore: FirebaseFirestore.instance,
    shopIdProvider: ref.read(shopIdProviderProvider),
  );
});

// ---------------------------------------------------------------------------
// Preview provider — used by BharosaLanding to show shortlist tiles.
// Returns list of CuratedShortlistPreview for the horizontal scroll.
// ---------------------------------------------------------------------------

final curatedShortlistsPreviewProvider =
    FutureProvider<List<CuratedShortlistPreview>>((ref) async {
  final repo = ref.read(_curatedShortlistRepoProvider);
  final shortlists = await repo.listAll();

  // Map to the preview model used by BharosaLanding.
  return shortlists.map((s) {
    return CuratedShortlistPreview(
      occasionTag: s.occasion.name,
      occasionLabel: s.titleDevanagari,
      skuCount: s.skuIdsInOrder.length,
    );
  }).toList();
});

// ---------------------------------------------------------------------------
// Full shortlist provider — used by ShortlistScreen.
// Family provider keyed by occasion tag (e.g., "shaadi", "naya_ghar").
// ---------------------------------------------------------------------------

final curatedShortlistByOccasionProvider =
    FutureProvider.family<CuratedShortlist?, String>((ref, occasionTag) async {
  final repo = ref.read(_curatedShortlistRepoProvider);
  final allShortlists = await repo.listAll();

  // Find the shortlist matching the occasion tag.
  return allShortlists.cast<CuratedShortlist?>().firstWhere(
        (s) => s!.occasion.name == occasionTag,
        orElse: () => null,
      );
});

// ---------------------------------------------------------------------------
// SKU list provider — resolves SKU IDs from a shortlist to full models.
// Family provider keyed by occasion tag.
// Uses InventorySkuRepo.getByIds (capped at 6 per shortlist, well within
// the Firestore whereIn limit of 10).
// ---------------------------------------------------------------------------

final shortlistSkusProvider =
    FutureProvider.family<List<InventorySku>, String>((ref, occasionTag) async {
  final shortlist =
      await ref.watch(curatedShortlistByOccasionProvider(occasionTag).future);
  if (shortlist == null) return const [];

  final skuRepo = ref.read(_inventorySkuRepoProvider);
  final skus = await skuRepo.getByIds(shortlist.skuIdsInOrder);

  // Preserve shopkeeper-curated order (getByIds may return unordered).
  final skuMap = {for (final s in skus) s.skuId: s};
  return shortlist.skuIdsInOrder
      .where((id) => skuMap.containsKey(id))
      .map((id) => skuMap[id]!)
      .toList();
});

// ---------------------------------------------------------------------------
// Individual SKU provider — used by SkuDetailCard route.
// Stream for real-time updates when shopkeeper edits SKU details.
// ---------------------------------------------------------------------------

final skuByIdProvider =
    StreamProvider.family<InventorySku?, String>((ref, skuId) {
  final repo = ref.read(_inventorySkuRepoProvider);
  return repo.watchById(skuId);
});
