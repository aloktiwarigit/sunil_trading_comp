// =============================================================================
// Customer — Freezed model for /shops/{shopId}/customers/{customerId}.
//
// Schema per SAD v1.0.4 §5 with S4.18 repeat-customer tracking field.
// =============================================================================

import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer.freezed.dart';
part 'customer.g.dart';

@freezed
class Customer with _$Customer {
  const factory Customer({
    required String shopId,
    required String customerId,
    String? displayName,
    String? phoneNumber,
    @Default(false) bool isPhoneVerified,
    DateTime? phoneVerifiedAt,
    String? upiVpa,

    /// S4.18 — repeat-customer event tracking. Cloud Function appends the
    /// new Project ID on every Project commit and caps the array at 10
    /// most-recent entries. Read by the ops dashboard to compute repeat %.
    @Default(<String>[]) List<String> previousProjectIds,

    required DateTime createdAt,
  }) = _Customer;

  factory Customer.fromJson(Map<String, dynamic> json) =>
      _$CustomerFromJson(json);

  const Customer._();

  /// True iff this customer has at least one completed prior Project
  /// (S4.18 analytics dashboard tile).
  bool get isRepeatCustomer => previousProjectIds.isNotEmpty;
}
