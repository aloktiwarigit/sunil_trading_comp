// =============================================================================
// TenantResolver — resolves the active shopId from three sources (priority):
//   1. Initial deep link  (https://<slug>.yugmalabs.ai at first install)
//   2. Persisted value    (SharedPreferences after first successful resolve)
//   3. Flagship fallback  (ShopIdProvider.flagshipShopId — dev/CI only)
//
// WS1: customer_app tenant resolver + deep-link boot.
// Architecture: SAD §8 "App Links / Universal Links" pattern.
// =============================================================================

import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../shop_id_provider.dart';

const _kShopIdKey = 'tenant_shop_id';

/// Resolves and persists the active tenant (shopId) for the customer app.
class TenantResolver {
  static final _appLinks = AppLinks();

  /// Retrieves the URI that launched the app at install / cold start.
  /// Returns null if no deep link was present or on any platform error.
  static Future<Uri?> getInitialAppLink() async {
    try {
      return await _appLinks.getInitialLink();
    } catch (_) {
      return null;
    }
  }

  /// Extracts the tenant slug from a yugmalabs.ai subdomain URI.
  ///
  /// Examples:
  ///   sunil-trading-company.yugmalabs.ai → 'sunil-trading-company'
  ///   shop_0.yugmalabs.ai               → 'shop-0'  (underscore → hyphen)
  ///   example.com                       → null
  ///   (malformed / empty host)          → null
  static String? parseTenantSlug(Uri uri) {
    final host = uri.host;
    const suffix = '.yugmalabs.ai';
    if (!host.endsWith(suffix)) return null;
    final subdomain = host.substring(0, host.length - suffix.length);
    // Reject empty subdomain or multi-level subdomains (e.g. a.b.yugmalabs.ai)
    if (subdomain.isEmpty || subdomain.contains('.')) return null;
    return subdomain.replaceAll('_', '-');
  }

  /// Reads the previously-persisted shopId, or null if none.
  static Future<String?> readPersistedShopId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kShopIdKey);
  }

  /// Persists shopId to SharedPreferences for future cold starts.
  static Future<void> persistShopId(String shopId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kShopIdKey, shopId);
  }

  /// Resolves the shopId to use for this session.
  ///
  /// Resolution order:
  ///   1. [initialLink] param (or getInitialAppLink() if null)
  ///   2. readPersistedShopId()
  ///   3. ShopIdProvider.flagshipShopId
  ///
  /// When a valid slug is found via a deep link it is persisted for
  /// future cold starts before returning.
  static Future<String> resolveShopId({Uri? initialLink}) async {
    final link = initialLink ?? await getInitialAppLink();
    if (link != null) {
      final slug = parseTenantSlug(link);
      if (slug != null && slug.isNotEmpty) {
        await persistShopId(slug);
        return slug;
      }
    }

    final persisted = await readPersistedShopId();
    if (persisted != null && persisted.isNotEmpty) {
      return persisted;
    }

    return ShopIdProvider.flagshipShopId;
  }

  /// Stream of incoming URIs while the app is already running.
  /// Used for WS1.5 re-bind detection.
  static Stream<Uri> get uriLinkStream => _appLinks.uriLinkStream;
}
