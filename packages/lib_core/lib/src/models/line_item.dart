// =============================================================================
// LineItem — denormalized line item inside a Project document.
// =============================================================================

import 'package:freezed_annotation/freezed_annotation.dart';

part 'line_item.freezed.dart';
part 'line_item.g.dart';

@freezed
class LineItem with _$LineItem {
  const factory LineItem({
    required String lineItemId,
    required String skuId,
    required String skuName,
    required int quantity,
    required int unitPriceInr,
    String? notes,

    /// C3.3: negotiated price accepted by the customer via price_proposal
    /// in the chat thread. When set, this overrides [unitPriceInr] for
    /// total computation. Null means no negotiation occurred — original
    /// catalog price applies.
    int? finalPrice,
  }) = _LineItem;

  factory LineItem.fromJson(Map<String, dynamic> json) =>
      _$LineItemFromJson(json);

  const LineItem._();

  /// The effective per-unit price: negotiated [finalPrice] if accepted,
  /// otherwise the original [unitPriceInr].
  int get effectivePrice => finalPrice ?? unitPriceInr;

  /// Line total uses the effective (possibly negotiated) price.
  int get lineTotalInr => quantity * effectivePrice;
}
