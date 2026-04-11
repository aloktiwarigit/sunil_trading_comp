// =============================================================================
// InventorySku — Freezed model for /shops/{shopId}/inventory/{skuId}.
//
// Schema per SAD §5 InventorySku entity. Each almirah SKU has name (both
// Devanagari and English), category, material, dimensions, base price with
// a "negotiable down to" floor the shopkeeper never exposes to customers,
// Golden Hour photo refs + working-light fallback URLs, voice note refs,
// and occasion tags for curated shortlist membership.
//
// Consumed by PRD B1.4 (curated shortlists read via SKU IDs), B1.5 (SKU
// detail), S4.3 (ops inventory create), S4.4 (ops inventory edit), S4.5
// (Golden Hour photo attach), B1.6 (voice note attach).
// =============================================================================

import 'package:freezed_annotation/freezed_annotation.dart';

part 'inventory_sku.freezed.dart';
part 'inventory_sku.g.dart';

/// Category of almirah / wardrobe / storage furniture. Domain-grounded
/// (NOT generic product categories) — matches the actual product range
/// of an Ayodhya almirah shop per Brief §7 + Shopkeeper Onboarding
/// Playbook §2 catalog breakdown.
enum SkuCategory {
  /// Traditional steel almirah (Godrej-style, brass lock).
  @JsonValue('steel_almirah')
  steelAlmirah,

  /// Wooden wardrobe — typically sheesham, teak, or mango wood.
  @JsonValue('wooden_wardrobe')
  woodenWardrobe,

  /// Modular / knock-down wardrobes (laminate or ply construction).
  @JsonValue('modular')
  modular,

  /// Dressing table (common adjacent purchase in wedding shortlists).
  @JsonValue('dressing')
  dressing,

  /// Side cabinet / night stand (bedroom-set adjacency).
  @JsonValue('side_cabinet')
  sideCabinet,
}

/// Material type. Affects durability claims + price positioning.
enum SkuMaterial {
  /// Steel sheet construction — traditional Godrej-style almirah.
  @JsonValue('steel')
  steel,

  /// Solid sheesham (Indian rosewood) — heavy, durable, higher price.
  @JsonValue('wood_sheesham')
  woodSheesham,

  /// Solid teak — premium wood, highest price tier.
  @JsonValue('wood_teak')
  woodTeak,

  /// Ply / laminate construction — modular, lighter, budget-friendly.
  @JsonValue('ply_laminate')
  plyLaminate,
}

/// Dimensions in centimeters. Indian market uses cm, not inches.
@freezed
class SkuDimensions with _$SkuDimensions {
  /// Create dimensions. All three values are required so the customer
  /// app can render a clean "152 × 92 × 51 cm" format without null-checks.
  const factory SkuDimensions({
    required int heightCm,
    required int widthCm,
    required int depthCm,
  }) = _SkuDimensions;

  /// JSON round-trip for Firestore serialization.
  factory SkuDimensions.fromJson(Map<String, dynamic> json) =>
      _$SkuDimensionsFromJson(json);
}

/// The inventory SKU document.
@freezed
class InventorySku with _$InventorySku {
  /// Construct an InventorySku.
  const factory InventorySku({
    required String skuId,
    required String shopId,

    /// Primary display name (English or Hindi, shopkeeper's choice — the
    /// Devanagari variant lives in [nameDevanagari]).
    required String name,

    /// Devanagari name — the source-of-truth per Brief Constraint 4 + the
    /// shopkeeper's own naming. Customer app shows THIS as the dominant
    /// label; [name] is the fallback for the English toggle.
    required String nameDevanagari,

    /// Short description — 1 line, plain, shopkeeper's register. Never
    /// marketing copy ("श्रेष्ठ / सर्वोत्तम / गुणवत्ता" forbidden per Constraint 10).
    @Default('') String description,

    required SkuCategory category,
    required SkuMaterial material,
    required SkuDimensions dimensions,

    /// Base price in INR rupees (paise omitted — v1 almirahs are round
    /// rupees at this market's price point).
    required int basePrice,

    /// The lowest price the shopkeeper will negotiate to. NEVER shown to
    /// the customer directly — this is a shopkeeper-only field consumed
    /// by the C3.3 discount approval flow and by the S4.12 Settings.
    required int negotiableDownTo,

    /// Human-readable stock status. v1 uses a simple bool; v1.5 can add
    /// reservation / hold semantics.
    @Default(true) bool inStock,

    /// Integer count, or null if the shopkeeper doesn't track quantities.
    int? stockCount,

    /// Golden Hour photo IDs (refs into the `goldenHourPhotos` sub-
    /// collection). Ordered — index 0 is the hero photo for this SKU.
    @Default(<String>[]) List<String> goldenHourPhotoIds,

    /// Working-light fallback photo URLs (used before Golden Hour photos
    /// exist for a newly-added SKU, or when the customer taps
    /// `असली रूप दिखाइए` to see the unfiltered shop-light version).
    @Default(<String>[]) List<String> fallbackPhotoUrls,

    /// Voice note IDs (refs into the `voiceNotes` collection). Ordered —
    /// index 0 is the primary voice note played inline in B1.5 SKU detail.
    @Default(<String>[]) List<String> voiceNoteIds,

    /// Occasion tags determining which curated shortlists this SKU
    /// belongs to. Values map to [ShortlistOccasion] in
    /// `curated_shortlist.dart`. Example: `['shaadi', 'dahej']` means this
    /// SKU appears in both the wedding and dowry shortlists.
    @Default(<String>[]) List<String> occasionTags,

    required DateTime createdAt,
    DateTime? updatedAt,

    /// Soft-delete flag. Per PRD PQ-D locked answer, v1 never hard-deletes
    /// SKUs — removed SKUs are marked inactive so past Project line-items
    /// still resolve.
    @Default(true) bool isActive,
  }) = _InventorySku;

  /// JSON round-trip for Firestore serialization.
  factory InventorySku.fromJson(Map<String, dynamic> json) =>
      _$InventorySkuFromJson(json);

  const InventorySku._();

  /// True iff the SKU has at least one Golden Hour photo captured. When
  /// false, the B1.5 UI shows a "जल्द ही असली रूप" (real form coming soon)
  /// badge on the working-light fallback.
  bool get hasGoldenHourPhoto => goldenHourPhotoIds.isNotEmpty;

  /// True iff the SKU has at least one voice note attached. When false,
  /// the B1.5 "सुनील भैया is is almirah ke baare mein..." section is
  /// suppressed rather than rendered with a placeholder.
  bool get hasVoiceNote => voiceNoteIds.isNotEmpty;
}
