// =============================================================================
// CustomerMemory — Freezed model for
//   /shops/{shopId}/customer_memory/{customerUid}.
//
// Schema per B1.11 AC #5 + SAD §5 CustomerMemory entity.
//
// **OPERATOR-ONLY.** Customer must NEVER read this document. Firestore
// security rules enforce operator-read + operator-write only. Cross-tenant
// integrity test asserts the customer's own UID cannot read their memory doc.
//
// This is Sunil-bhaiya's relationship notebook — notes about family ties,
// preferred occasions, price sensitivity. It is NOT a CRM profile; it is the
// digital equivalent of the shopkeeper's memory. Domain terms apply.
// =============================================================================

import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer_memory.freezed.dart';
part 'customer_memory.g.dart';

/// Occasions that customers typically buy almirahs for.
/// Domain-grounded: shaadi, naya_ghar, dahej, purana_badalne — NOT
/// "wedding", "new_home", "dowry", "replacement".
enum PreferredOccasion {
  shaadi,
  nayaGhar,
  dahej,
  puranaBadalne,
  budget,
  ladies,
  other,
}

@freezed
class CustomerMemory with _$CustomerMemory {
  const factory CustomerMemory({
    required String customerUid,
    required String shopId,

    /// Free-text notes about the customer (500 char limit enforced in UI).
    /// Example: "Sunita ki bahen Geeta bhi hamari customer hai"
    @Default('') String notes,

    /// Relationship notes — links to other customers.
    /// Example: "Sunita-ji ki saas ne 2019 mein Storwel li thi"
    @Default('') String relationshipNotes,

    /// Occasions this customer typically buys for.
    /// CR #6: unknown enum values from future app versions map to `other`.
    @Default(<PreferredOccasion>[])
    @JsonKey(unknownEnumValue: PreferredOccasion.other)
    List<PreferredOccasion> preferredOccasions,

    /// Preferred price range — minimum (INR).
    int? preferredPriceMin,

    /// Preferred price range — maximum (INR).
    int? preferredPriceMax,

    /// First time this customer was seen by the shopkeeper.
    DateTime? firstSeenAt,

    /// Last time the shopkeeper interacted with this customer.
    DateTime? lastSeenAt,

    /// Total projects over the lifetime of this relationship.
    @Default(0) int totalProjectsLifetime,
  }) = _CustomerMemory;

  factory CustomerMemory.fromJson(Map<String, dynamic> json) =>
      _$CustomerMemoryFromJson(json);

  const CustomerMemory._();

  /// True if this memory has any content at all.
  bool get hasContent =>
      notes.isNotEmpty ||
      relationshipNotes.isNotEmpty ||
      preferredOccasions.isNotEmpty ||
      preferredPriceMin != null ||
      preferredPriceMax != null;
}
