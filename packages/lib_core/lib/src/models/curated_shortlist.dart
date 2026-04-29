// =============================================================================
// CuratedShortlist — Freezed model for /shops/{shopId}/curatedShortlists/{id}.
//
// Schema per SAD §5 CuratedShortlist entity + PRD B1.4 + UX Spec v1.1 §4.3.
//
// "Sunil-bhaiya ki pasand" — the shopkeeper hand-picks a FINITE set of
// SKUs (max 6 per occasion per UX Spec §4.3 pushback) for each of six
// occasion categories. The customer browses these instead of an infinite
// product grid. The finiteness IS the feature.
//
// Consumed by:
//   - PRD B1.4 (customer-side shortlist render)
//   - PRD B1.12 (shopkeeper-side "remote control for the finger" curation)
// =============================================================================

import 'package:freezed_annotation/freezed_annotation.dart';

part 'curated_shortlist.freezed.dart';
part 'curated_shortlist.g.dart';

/// The 6 occasion categories the customer browses by. Mirrors PRD B1.4
/// AC #1 + UX Spec v1.1 §5.5 rows #3-5. Domain-grounded naming — NOT
/// generic "category_1..6" or "collection_a/b/c".
enum ShortlistOccasion {
  /// शादी के लिए — for a wedding (highest volume driver per Brief Persona A).
  @JsonValue('shaadi')
  shaadi,

  /// नए घर के लिए — for the new home (Persona B: new homeowner).
  @JsonValue('naya_ghar')
  nayaGhar,

  /// बेटी का नया घर — for daughter's new home.
  @JsonValue('beti_ka_ghar')
  betiKaGhar,

  /// पुराना बदलने के लिए — to replace the old one (Persona C: replacement
  /// buyer). Honest framing per Maya's reframe.
  @JsonValue('replacement')
  replacement,

  /// बजट के अनुसार — budget-friendly picks. Never called "cheap" / "सस्ता".
  @JsonValue('budget')
  budget,

  /// लेडीज के लिए — for female customers / their specific preferences.
  @JsonValue('ladies')
  ladies,
}

/// The curated shortlist document.
///
/// The `skuIdsInOrder` field is the load-bearing state — the shopkeeper's
/// ORDER matters. Drag-to-reorder in S4.12 / B1.12 writes the new order
/// back, and the customer sees SKUs in exactly the order the shopkeeper
/// intended (not alphabetized, not sorted by price).
@freezed
class CuratedShortlist with _$CuratedShortlist {
  /// Construct a curated shortlist.
  const factory CuratedShortlist({
    required String shortlistId,
    required String shopId,
    required ShortlistOccasion occasion,

    /// Devanagari title per UX Spec §5.5 #3-5. Source-of-truth language.
    required String titleDevanagari,

    /// English title for the toggle locale. Mirrors the Devanagari.
    required String titleEnglish,

    /// Short description — 1 line, shopkeeper's register.
    @Default('') String description,

    /// SKU IDs in shopkeeper-curated order. Per PRD B1.4 AC #2 + UX Spec
    /// §4.3, the customer sees exactly these SKUs in this order. No
    /// pagination, no "load more" — the list is finite by design. Max
    /// 6 per UX Spec §4.3.
    @Default(<String>[]) List<String> skuIdsInOrder,

    required DateTime createdAt,
    DateTime? updatedAt,

    /// Soft-active flag. A shortlist can exist but be hidden from the
    /// customer (e.g., during seasonal re-curation).
    @Default(true) bool isActive,
  }) = _CuratedShortlist;

  /// JSON round-trip for Firestore serialization.
  factory CuratedShortlist.fromJson(Map<String, dynamic> json) =>
      _$CuratedShortlistFromJson(json);

  const CuratedShortlist._();

  /// True iff this shortlist has been curated with at least one SKU.
  /// Empty shortlists render the "अभी तक सुनील भैया ने इसमें कुछ नहीं चुना"
  /// empty state per UX Spec §5.5 #27.
  bool get isCurated => skuIdsInOrder.isNotEmpty;

  /// True iff this shortlist has hit the 6-SKU finite cap from UX Spec §4.3.
  /// The shopkeeper curation UI (PRD B1.12) uses this to decide whether
  /// to show the "add from inventory" affordance.
  bool get atFiniteCap => skuIdsInOrder.length >= 6;
}
