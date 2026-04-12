// =============================================================================
// InvoiceTemplate — B1.13 Devanagari invoice / receipt generation.
//
// Client-side PDF via the `pdf` Dart package per SAD v1.0.4 ADR-015.
// No Cloud Function. Works fully offline.
//
// Per B1.13 ACs:
//   AC #2: client-side via `pdf` package, template at this file path
//   AC #3: header — shop logo fallback, brandName, address, GST, since year
//   AC #4: body — project ID, date, customer name, line items, total, method
//   AC #5: footer — thank-you line + Mukta italic signature
//   AC #6: numerics in DM Mono per Constraint 4
//   AC #7: saved to local storage + platform share sheet
//   AC #8: filename convention: रसीद_{shortProjectId}_{date}.pdf
//   AC #9: embedded font faces from app binary — no network fetch
//
// Font stack compliance (Constraint 4):
//   - Tiro Devanagari Hindi → header display
//   - Mukta → body text + signature italic
//   - DM Mono → prices, project ID, numerics
//   - Fraunces / EB Garamond — NOT used in PDF (Latin display fonts)
//
// ADR-010 compliance: NO forbidden vocabulary in any string or field name.
// =============================================================================

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/line_item.dart';
import '../models/project.dart';
import '../theme/shop_theme_tokens.dart';

/// Data payload for invoice generation. Decouples the template from
/// Firestore reads — the caller assembles this from Project + Shop docs.
class InvoicePayload {
  const InvoicePayload({
    required this.project,
    required this.shopTokens,
    required this.customerDisplayName,
    this.udhaarRunningBalance,
  });

  final Project project;
  final ShopThemeTokens shopTokens;
  final String customerDisplayName;

  /// If udhaar khaata is open, show the running balance on receipt.
  /// ADR-010: labeled "बाकी" not "balance due" or "outstanding".
  final int? udhaarRunningBalance;
}

/// Generates a Devanagari receipt PDF as raw bytes.
///
/// The caller is responsible for:
///   1. Loading font data (TTF bytes) for Mukta and DM Mono
///   2. Saving the returned bytes to local storage
///   3. Opening the platform share sheet
///
/// Font loading is deferred to the caller because the `pdf` package needs
/// raw TTF bytes, and asset loading requires Flutter's rootBundle which is
/// not available in pure-Dart tests.
class InvoiceTemplate {
  const InvoiceTemplate({
    required this.devaDisplayFont,
    required this.devaBodyFont,
    required this.devaBodyFontItalic,
    required this.monoFont,
  });

  /// Tiro Devanagari Hindi — header display.
  final pw.Font devaDisplayFont;

  /// Mukta — body text.
  final pw.Font devaBodyFont;

  /// Mukta Italic — footer signature approximation (AC #5).
  final pw.Font devaBodyFontItalic;

  /// DM Mono — prices, project ID, numerics (AC #6).
  final pw.Font monoFont;

  /// Generate the PDF bytes for the given invoice payload.
  Future<Uint8List> generate(InvoicePayload payload) async {
    final pdf = pw.Document();
    final project = payload.project;
    final shop = payload.shopTokens;

    // Devanagari month names for date formatting (AC #4).
    const months = <int, String>{
      1: 'जनवरी',
      2: 'फ़रवरी',
      3: 'मार्च',
      4: 'अप्रैल',
      5: 'मई',
      6: 'जून',
      7: 'जुलाई',
      8: 'अगस्त',
      9: 'सितंबर',
      10: 'अक्टूबर',
      11: 'नवंबर',
      12: 'दिसंबर',
    };

    final date = project.committedAt ?? project.createdAt;
    final dateStr = '${date.day} ${months[date.month]} ${date.year}';
    final shortId = project.projectId.length > 6
        ? project.projectId.substring(project.projectId.length - 6)
        : project.projectId;

    // Payment method in Devanagari (AC #4).
    final paymentMethodLabel = switch (project.paymentMethod) {
      'upi' => 'UPI',
      'cod' => 'नकद (डिलीवरी पर)',
      'bank_transfer' => 'बैंक ट्रांसफ़र',
      'udhaar' => 'उधार खाता',
      _ => '',
    };

    // Build text styles.
    final headerStyle = pw.TextStyle(
      font: devaDisplayFont,
      fontSize: 22,
      fontWeight: pw.FontWeight.bold,
    );
    final bodyStyle = pw.TextStyle(font: devaBodyFont, fontSize: 11);
    final bodyBold =
        pw.TextStyle(font: devaBodyFont, fontSize: 11, fontWeight: pw.FontWeight.bold);
    final monoStyle = pw.TextStyle(font: monoFont, fontSize: 11);
    final monoBold =
        pw.TextStyle(font: monoFont, fontSize: 14, fontWeight: pw.FontWeight.bold);
    final signatureStyle = pw.TextStyle(
      font: devaBodyFontItalic,
      fontSize: 16,
      fontWeight: pw.FontWeight.bold,
    );
    final captionStyle = pw.TextStyle(font: devaBodyFont, fontSize: 9);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // ============== HEADER ==============
          _buildHeader(shop, headerStyle, bodyStyle, monoStyle, captionStyle),
          pw.SizedBox(height: 20),
          pw.Divider(thickness: 1),
          pw.SizedBox(height: 12),

          // ============== PROJECT INFO ==============
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(dateStr, style: bodyStyle),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    payload.customerDisplayName,
                    style: bodyBold,
                  ),
                ],
              ),
              pw.Text('#$shortId', style: monoBold),
            ],
          ),
          pw.SizedBox(height: 16),

          // ============== LINE ITEMS TABLE ==============
          _buildLineItemsTable(
            project.lineItems,
            bodyStyle,
            bodyBold,
            monoStyle,
          ),
          pw.SizedBox(height: 12),

          // ============== TOTALS ==============
          pw.Divider(thickness: 0.5),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text('कुल: ', style: bodyBold),
              pw.Text(
                '₹${_formatInr(project.totalAmount)}',
                style: monoBold,
              ),
            ],
          ),
          if (paymentMethodLabel.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('भुगतान: ', style: captionStyle),
                pw.Text(paymentMethodLabel, style: captionStyle),
              ],
            ),
          ],

          // Udhaar balance (edge case #2)
          if (payload.udhaarRunningBalance != null &&
              payload.udhaarRunningBalance! > 0) ...[
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('बाकी: ', style: bodyBold),
                pw.Text(
                  '₹${_formatInr(payload.udhaarRunningBalance!)}',
                  style: monoBold,
                ),
              ],
            ),
          ],

          // Cancelled watermark (edge case #5)
          if (project.state == ProjectState.cancelled)
            pw.Center(
              child: pw.Transform.rotateBox(
                angle: -0.3,
                child: pw.Text(
                  'रद्द',
                  style: pw.TextStyle(
                    font: devaDisplayFont,
                    fontSize: 60,
                    color: PdfColor.fromHex('#CC0000'),
                  ),
                ),
              ),
            ),

          pw.SizedBox(height: 40),

          // ============== FOOTER ==============
          pw.Divider(thickness: 0.5),
          pw.SizedBox(height: 12),
          // Thank-you line (AC #5)
          pw.Center(
            child: pw.Text(
              'धन्यवाद, आपका विश्वास हमारा भविष्य है',
              style: bodyStyle,
            ),
          ),
          pw.SizedBox(height: 20),
          // Signature — Mukta italic at larger size (AC #5, Constraint 4)
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              shop.ownerName,
              style: signatureStyle,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              shop.brandName,
              style: captionStyle,
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(
    ShopThemeTokens shop,
    pw.TextStyle headerStyle,
    pw.TextStyle bodyStyle,
    pw.TextStyle monoStyle,
    pw.TextStyle captionStyle,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Shop initial fallback (AC #3 edge case #4)
        pw.Container(
          width: 50,
          height: 50,
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex(shop.primaryColorHex.replaceAll('#', '')),
            borderRadius: pw.BorderRadius.circular(25),
          ),
          child: pw.Center(
            child: pw.Text(
              shop.brandName.isNotEmpty ? shop.brandName[0] : '',
              style: pw.TextStyle(
                font: devaDisplayFont,
                fontSize: 24,
                color: PdfColors.white,
              ),
            ),
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(shop.brandName, style: headerStyle),
              pw.SizedBox(height: 2),
              pw.Text(
                '${shop.marketArea}, ${shop.city} · ${shop.establishedYear} से',
                style: captionStyle,
              ),
              if (shop.gstNumber != null && shop.gstNumber!.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text('GST: ${shop.gstNumber}', style: monoStyle),
              ],
              pw.SizedBox(height: 2),
              pw.Text(shop.upiVpa, style: monoStyle),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildLineItemsTable(
    List<LineItem> items,
    pw.TextStyle bodyStyle,
    pw.TextStyle bodyBold,
    pw.TextStyle monoStyle,
  ) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerStyle: bodyBold,
      cellStyle: bodyStyle,
      headerDecoration: pw.BoxDecoration(
        color: PdfColor.fromHex('F5F0EB'),
      ),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
      headers: ['सामान', 'मात्रा', 'दाम', 'कुल'],
      data: items.map((item) {
        final effectivePrice = item.finalPrice ?? item.unitPriceInr;
        final lineTotal = effectivePrice * item.quantity;
        return [
          item.skuName,
          '${item.quantity}',
          '₹${_formatInr(effectivePrice)}',
          '₹${_formatInr(lineTotal)}',
        ];
      }).toList(),
    );
  }

  /// Indian lakh/thousand separators.
  /// CR #5: handle negative amounts gracefully.
  static String _formatInr(int amount) {
    if (amount < 0) return '-${_formatInr(-amount)}';
    final s = amount.toString();
    if (s.length <= 3) return s;
    final lastThree = s.substring(s.length - 3);
    final rest = s.substring(0, s.length - 3);
    final buffer = StringBuffer();
    for (var i = 0; i < rest.length; i++) {
      if (i != 0 && (rest.length - i) % 2 == 0) {
        buffer.write(',');
      }
      buffer.write(rest[i]);
    }
    return '$buffer,$lastThree';
  }

  /// Generate the filename per AC #8.
  static String fileName(String projectId, DateTime date) {
    final shortId = projectId.length > 6
        ? projectId.substring(projectId.length - 6)
        : projectId;
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return 'रसीद_${shortId}_$dateStr.pdf';
  }
}
