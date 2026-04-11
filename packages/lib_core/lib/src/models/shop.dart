// =============================================================================
// Shop — Freezed model for the top-level /shops/{shopId} document.
//
// Schema per SAD v1.0.4 §5 with ADR-013 lifecycle fields.
// Every field traces to a specific architectural decision — do not add fields
// without an ADR.
// =============================================================================

import 'package:freezed_annotation/freezed_annotation.dart';

part 'shop.freezed.dart';
part 'shop.g.dart';

/// Shop lifecycle state machine (ADR-013, v1.0.4).
///
/// Transitions:
///   active → deactivating → purge_scheduled → purged
///
/// Only `active` permits client writes. All other states freeze writes via
/// the `shopIsWritable(shopId)` rule helper, so Cloud Function 8
/// (`shopDeactivationSweep`) owns all mutations during lifecycle transitions.
enum ShopLifecycle {
  @JsonValue('active')
  active,

  @JsonValue('deactivating')
  deactivating,

  @JsonValue('purge_scheduled')
  purgeScheduled,

  @JsonValue('purged')
  purged,
}

/// Shop document — top-level tenant root.
///
/// Scoped by `shopId` which is a human-readable slug (e.g.
/// `sunil-trading-company`), NOT a UUID, per ADR-003.
@freezed
class Shop with _$Shop {
  const factory Shop({
    required String shopId,
    required String brandName,
    required String brandNameDevanagari,
    required String ownerUid,
    required String market,
    required DateTime createdAt,
    required DateTime activeFromDay,

    // ---- ADR-013 lifecycle fields (v1.0.4) ----

    /// Current lifecycle state. `active` = normal operation, anything else
    /// freezes client writes via security rule.
    @Default(ShopLifecycle.active) ShopLifecycle shopLifecycle,

    /// Server timestamp recorded when `shopLifecycle` last changed.
    DateTime? shopLifecycleChangedAt,

    /// Free-text reason the shopkeeper provided when deactivating
    /// (dropdown enum from S4.19). Null when `shopLifecycle == active`.
    String? shopLifecycleReason,

    /// Absolute date after which the DPDP retention window expires and
    /// `shopDeactivationSweep` Function 8 performs scoped deletion. Null
    /// when `shopLifecycle == active`.
    DateTime? dpdpRetentionUntil,
  }) = _Shop;

  factory Shop.fromJson(Map<String, dynamic> json) => _$ShopFromJson(json);

  const Shop._();

  /// True iff the shop is currently mutable by clients.
  /// Mirrors the `shopIsWritable(shopId)` helper in `firestore.rules`.
  bool get isWritable => shopLifecycle == ShopLifecycle.active;
}
