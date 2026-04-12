// =============================================================================
// UpiIntentBuilder tests — C3.5 AC #8 Triple Zero UPI invariant.
//
// Per PRD C3.5 AC #8:
//   (a) am= integer equals project.totalAmount
//   (b) pa= equals shop.upiVpa
//   (c) no other numeric fee / charge / mdr parameter exists in the URI
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:lib_core/src/services/upi_intent_builder.dart';

void main() {
  group('UpiIntentBuilder', () {
    test('am= equals totalAmount exactly (AC #8a)', () {
      final uri = UpiIntentBuilder.build(
        shopVpa: 'sunil@oksbi',
        shopName: 'Sunil Trading Company',
        totalAmount: 22000,
        projectId: 'proj-123',
      );

      expect(uri.queryParameters['am'], '22000.00');
    });

    test('pa= equals shop.upiVpa directly (AC #8b)', () {
      final uri = UpiIntentBuilder.build(
        shopVpa: 'sunil@oksbi',
        shopName: 'Sunil Trading Company',
        totalAmount: 15000,
        projectId: 'proj-456',
      );

      expect(uri.queryParameters['pa'], 'sunil@oksbi');
    });

    test('no fee/charge/mdr parameters exist (AC #8c)', () {
      final uri = UpiIntentBuilder.build(
        shopVpa: 'sunil@oksbi',
        shopName: 'Sunil Trading Company',
        totalAmount: 18000,
        projectId: 'proj-789',
      );

      final params = uri.queryParameters;
      // Only these keys should exist: pa, pn, am, tn, cu.
      expect(params.keys.toSet(), {'pa', 'pn', 'am', 'tn', 'cu'});
      // Explicitly verify no fee-related params.
      expect(params.containsKey('fee'), false);
      expect(params.containsKey('charge'), false);
      expect(params.containsKey('mdr'), false);
      expect(params.containsKey('commission'), false);
    });

    test('scheme is upi and host is pay', () {
      final uri = UpiIntentBuilder.build(
        shopVpa: 'test@upi',
        shopName: 'Test',
        totalAmount: 100,
        projectId: 'p-1',
      );

      expect(uri.scheme, 'upi');
      expect(uri.host, 'pay');
    });

    test('cu is always INR', () {
      final uri = UpiIntentBuilder.build(
        shopVpa: 'test@upi',
        shopName: 'Test',
        totalAmount: 5000,
        projectId: 'p-2',
      );

      expect(uri.queryParameters['cu'], 'INR');
    });

    test('tn contains the projectId', () {
      final uri = UpiIntentBuilder.build(
        shopVpa: 'test@upi',
        shopName: 'Test Shop',
        totalAmount: 7000,
        projectId: 'order-xyz',
      );

      expect(uri.queryParameters['tn'], contains('order-xyz'));
    });

    test('amount in rupees not paise (AC #7)', () {
      // 22000 rupees should appear as "22000", not "2200000" (paise).
      final uri = UpiIntentBuilder.build(
        shopVpa: 'sunil@oksbi',
        shopName: 'Sunil Trading Company',
        totalAmount: 22000,
        projectId: 'proj-test',
      );

      expect(double.parse(uri.queryParameters['am']!), 22000.0);
    });
  });
}
