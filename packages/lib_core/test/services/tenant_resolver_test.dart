// Tests for TenantResolver.parseTenantSlug().
//
// resolveShopId / readPersistedShopId / persistShopId are integration-level
// (SharedPreferences + AppLinks) and are NOT tested here — parseTenantSlug
// is pure Uri logic with no platform dependencies.

import 'package:flutter_test/flutter_test.dart';
import 'package:lib_core/lib_core.dart';

void main() {
  group('TenantResolver.parseTenantSlug', () {
    test('extracts slug from flagship subdomain', () {
      final uri = Uri.parse('https://sunil-trading-company.yugmalabs.ai');
      expect(
        TenantResolver.parseTenantSlug(uri),
        equals('sunil-trading-company'),
      );
    });

    test('normalises underscore subdomain to hyphen (shop_0 → shop-0)', () {
      final uri = Uri.parse('https://shop_0.yugmalabs.ai');
      expect(
        TenantResolver.parseTenantSlug(uri),
        equals('shop-0'),
      );
    });

    test('returns null for non-yugmalabs.ai host', () {
      final uri = Uri.parse('https://example.com/foo');
      expect(TenantResolver.parseTenantSlug(uri), isNull);
    });

    test('returns null for bare yugmalabs.ai (no subdomain)', () {
      final uri = Uri.parse('https://yugmalabs.ai/shop/abc');
      expect(TenantResolver.parseTenantSlug(uri), isNull);
    });

    test('returns null for multi-level subdomain', () {
      final uri = Uri.parse('https://a.b.yugmalabs.ai');
      expect(TenantResolver.parseTenantSlug(uri), isNull);
    });

    test('returns null for empty URI (no host)', () {
      final uri = Uri.parse('');
      expect(TenantResolver.parseTenantSlug(uri), isNull);
    });

    test('strips path and preserves slug-only host portion', () {
      final uri =
          Uri.parse('https://sunil-trading-company.yugmalabs.ai/products/almirah');
      expect(
        TenantResolver.parseTenantSlug(uri),
        equals('sunil-trading-company'),
      );
    });
  });
}
