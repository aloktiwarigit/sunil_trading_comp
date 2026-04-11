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
  }) = _LineItem;

  factory LineItem.fromJson(Map<String, dynamic> json) =>
      _$LineItemFromJson(json);

  const LineItem._();

  int get lineTotalInr => quantity * unitPriceInr;
}
