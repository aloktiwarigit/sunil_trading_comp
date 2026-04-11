// =============================================================================
// ShopIdProvider — current tenant identifier.
//
// Every Firestore read/write in lib_core must scope by this value. The
// cross-tenant integrity test (cross_tenant_integrity_test.dart) asserts
// that a `shop_1` operator cannot read or write `shop_0` documents.
//
// Per SAD §5: shopId is a human-readable slug (e.g. `sunil-trading-company`),
// NOT a UUID. Validated unique at onboarding.
//
// PRD I6.4 — this is the foundation of multi-tenant scoping.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Currently-active shop ID.
///
/// In v1 the customer_app is built per-shop (shop #1 = `sunil-trading-company`)
/// so the value is compile-time. From shop #2 onwards, the shopId is read
/// from the marketing-site subdomain or a deep link param.
///
/// The shopkeeper_app reads its shopId from the operator's Firebase custom
/// claim (`request.auth.token.shopId`).
class ShopIdProvider {
  const ShopIdProvider(this.shopId);

  /// Active shop slug. Empty string is forbidden (will fail security rules).
  final String shopId;

  /// The synthetic tenant used by the cross-tenant integrity test.
  /// Documents in this shop must NEVER be readable by any other shop.
  static const String syntheticShopId = 'shop_0';

  /// The flagship shop for v1.
  static const String flagshipShopId = 'sunil-trading-company';
}

/// Riverpod provider — overridden in main.dart per app target.
///
/// Customer app: overridden with the slug from build config.
/// Shopkeeper app: overridden after Google Sign-In completes and the
///                 operator's `shopId` claim is read.
final shopIdProviderProvider = Provider<ShopIdProvider>((ref) {
  throw UnimplementedError(
    'shopIdProviderProvider must be overridden in main.dart with a real shopId',
  );
});
