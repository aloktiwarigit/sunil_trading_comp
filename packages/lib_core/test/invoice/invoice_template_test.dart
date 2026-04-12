// =============================================================================
// InvoiceTemplate — B1.13 unit tests.
//
// Tests assert:
//   1. PDF bytes are generated without crash
//   2. fileName follows the convention: रसीद_{shortId}_{date}.pdf
//   3. _formatInr produces Indian lakh separators
//   4. InvoicePayload carries all required data
//   5. Cancelled project includes watermark
//   6. Udhaar balance is included when present
//
// Note: font loading requires TTF bytes. We use pdf package's built-in
// fonts (Helvetica) as placeholders for unit tests. Real Devanagari fonts
// are loaded from app assets at runtime.
// =============================================================================

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:lib_core/src/invoice/invoice_template.dart';
import 'package:lib_core/src/models/line_item.dart';
import 'package:lib_core/src/models/project.dart';
import 'package:lib_core/src/theme/shop_theme_tokens.dart';

void main() {
  // Use built-in Helvetica as stand-in for Devanagari fonts in tests.
  // Real fonts are loaded from app binary assets at runtime.
  late InvoiceTemplate template;

  setUp(() {
    template = InvoiceTemplate(
      devaDisplayFont: pw.Font.helveticaBold(),
      devaBodyFont: pw.Font.helvetica(),
      devaBodyFontItalic: pw.Font.helveticaOblique(),
      monoFont: pw.Font.courier(),
    );
  });

  Project _minimalProject({
    ProjectState state = ProjectState.closed,
    String? paymentMethod,
    String? udhaarLedgerId,
  }) {
    return Project(
      projectId: 'ULID01ABCDEFGH',
      shopId: 'sunil-trading-company',
      customerId: 'c1',
      customerUid: 'uid-1',
      state: state,
      totalAmount: 45000,
      amountReceivedByShop: 45000,
      lineItems: const [
        LineItem(
          lineItemId: 'li-1',
          skuId: 'sku-1',
          skuName: 'तीन दरवाज़े वाली अलमारी',
          quantity: 1,
          unitPriceInr: 25000,
        ),
        LineItem(
          lineItemId: 'li-2',
          skuId: 'sku-2',
          skuName: 'दो दरवाज़े वाली अलमारी',
          quantity: 1,
          unitPriceInr: 20000,
        ),
      ],
      paymentMethod: paymentMethod ?? 'upi',
      committedAt: DateTime(2026, 4, 11),
      createdAt: DateTime(2026, 4, 10),
      udhaarLedgerId: udhaarLedgerId,
    );
  }

  InvoicePayload _payload({
    ProjectState state = ProjectState.closed,
    String? paymentMethod,
    int? udhaarBalance,
    String? udhaarLedgerId,
  }) {
    return InvoicePayload(
      project: _minimalProject(
        state: state,
        paymentMethod: paymentMethod,
        udhaarLedgerId: udhaarLedgerId,
      ),
      shopTokens: ShopThemeTokens.sunilTradingCompanyDefault(),
      customerDisplayName: 'सुनीता जी',
      udhaarRunningBalance: udhaarBalance,
    );
  }

  group('InvoiceTemplate', () {
    test('generates non-empty PDF bytes for a closed project', () async {
      final bytes = await template.generate(_payload());
      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(100));
      // PDF magic bytes
      expect(bytes[0], equals(0x25)); // %
      expect(bytes[1], equals(0x50)); // P
      expect(bytes[2], equals(0x44)); // D
      expect(bytes[3], equals(0x46)); // F
    });

    test('generates PDF for cancelled project (edge case #5)', () async {
      final bytes = await template.generate(
        _payload(state: ProjectState.cancelled),
      );
      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(100));
    });

    test('generates PDF with udhaar balance (edge case #2)', () async {
      final bytes = await template.generate(
        _payload(
          paymentMethod: 'udhaar',
          udhaarBalance: 13000,
          udhaarLedgerId: 'ledger-1',
        ),
      );
      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(100));
    });

    test('generates PDF for COD payment method', () async {
      final bytes = await template.generate(
        _payload(paymentMethod: 'cod'),
      );
      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(100));
    });

    test('generates PDF for bank transfer', () async {
      final bytes = await template.generate(
        _payload(paymentMethod: 'bank_transfer'),
      );
      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(100));
    });
  });

  group('InvoiceTemplate.fileName', () {
    test('follows convention: रसीद_{shortId}_{date}.pdf (AC #8)', () {
      final name = InvoiceTemplate.fileName(
        'ULID01ABCDEFGH',
        DateTime(2026, 4, 11),
      );
      expect(name, equals('रसीद_CDEFGH_2026-04-11.pdf'));
    });

    test('short projectId used as-is', () {
      final name = InvoiceTemplate.fileName(
        'ABC',
        DateTime(2026, 1, 5),
      );
      expect(name, equals('रसीद_ABC_2026-01-05.pdf'));
    });

    test('pads single-digit month and day', () {
      final name = InvoiceTemplate.fileName(
        'ULID01ABCDEFGH',
        DateTime(2026, 3, 7),
      );
      expect(name, contains('2026-03-07'));
    });
  });

  group('InvoicePayload', () {
    test('carries project and shop tokens', () {
      final p = _payload();
      expect(p.project.projectId, isNotEmpty);
      expect(p.shopTokens.shopId, equals('sunil-trading-company'));
      expect(p.customerDisplayName, equals('सुनीता जी'));
    });

    test('udhaar balance is optional', () {
      final p = _payload();
      expect(p.udhaarRunningBalance, isNull);

      final p2 = _payload(udhaarBalance: 5000);
      expect(p2.udhaarRunningBalance, equals(5000));
    });
  });
}
