// lib_core/src/components/invoice_template.dart
//
// InvoiceTemplate — the Devanagari receipt / invoice for PRD B1.13.
//
// This widget is the single most typographically demanding artifact in the
// entire product. It renders both as an in-app preview (which IS elder-tier
// transformable) and as the input to the `pdf` Dart package's client-side
// PDF renderer (which is NOT elder-tier transformable — per UX Spec v1.1
// §10 handoff item #13: "the PDF is a document").
//
// The two render modes share this widget tree. Elder-tier differences are
// applied ONLY when `mode == InvoiceRenderMode.preview`. In `pdf` mode the
// fixed point sizes from UX Spec v1.1 §4.11 are authoritative.
//
// Typographic hierarchy (UX Spec §4.11, Constraint 4 compliant — Tiro
// Devanagari Hindi + Mukta + DM Mono + EB Garamond + Fraunces only):
//   - Shop name header  : Tiro Devanagari Hindi, 32pt, regular
//   - Address / GST     : Mukta, 11pt, regular
//   - Line item names   : Mukta, 12pt, regular
//   - Line item prices  : DM Mono, 12pt (totals: 16pt bold)
//   - Footer thank-you  : Mukta, 13pt, plain (NOT italic)
//   - Signature         : Mukta italic, 24pt
//
// Explicit DO-NOT list (UX Spec v1.1 §10 handoff item #12, red-team
// inversion F16). The template MUST NOT contain:
//   - Yugma Labs logo or "powered by" footer
//   - QR code of any kind
//   - Cross-sell ("you may also like")
//   - Rate-this-receipt link or feedback CTA
//   - Discount coupon / promo code
//   - Share-and-earn incentive
//   - View-on-web link
//   - Star ratings
//   - Third-party ad or sponsor pixel
// Amelia is explicitly prohibited from "polishing" this template with any
// of the above. Additions must route through Sally first.
//
// Forbidden vocabulary (R10 compliance, UX Spec §5.6):
//   - No ब्याज / पेनल्टी / बकाया तारीख / देय / ऋण / क़िस्त / वसूली anywhere
//   - "बाकी" is the ONLY permitted word for remaining udhaar balance
//
// Forbidden mythic vocabulary (Constraint 10 compliance, UX Spec §5.6):
//   - No शुभ / मंदिर / धर्म / आशीर्वाद / पूज्य / मंगल / स्वागतम् / उत्पाद /
//     गुणवत्ता / श्रेष्ठ anywhere
//
// Partition discipline (I6.12, SAD §9):
//   - This widget is PURE RENDER. It does not write to Firestore. Any
//     action (share, save-as, retry) is routed via callback. The invoice
//     data model is a read-only snapshot; no customer-side write from this
//     widget can ever touch Project/operator-owned fields.
//
// Maps to PRD story: B1.13
// Maps to UX Spec §4.11, §5.5 strings #31–#36, §6.6 states #35–#41b,
//                   §10 handoff items #12, #13.

import 'package:flutter/material.dart';
import '../theme/yugma_theme_extension.dart';
import '../theme/tokens.dart';

/// Two render modes — the preview (on-screen, elder-tier transformable)
/// versus the PDF (fixed sizes, print-safe).
enum InvoiceRenderMode { preview, pdf }

/// Lifecycle of the receipt. Maps to Project state + UdhaarLedger presence.
enum InvoiceStatus {
  /// Default layout, Project closed + paid.
  paid,

  /// 45-degree `रद्द` diagonal watermark overlay at 15% opacity.
  cancelled,

  /// Adds a single `बाकी: ₹{amount}` line below totals. No other change.
  udhaarOpen,
}

/// Immutable snapshot of an invoice. Passed in by the caller — this widget
/// does not fetch from Firestore.
class InvoiceData {
  final String projectShortId; // last 6 of ULID — DM Mono
  final DateTime issuedAt;
  final String? customerDisplayName; // null → `ग्राहक` fallback
  final List<InvoiceLineItem> lineItems;
  final int totalInr;
  final String paymentMethodLabel; // e.g., 'UPI', 'नकद', 'खाता'
  final int udhaarBalanceInr; // only used when status == udhaarOpen

  const InvoiceData({
    required this.projectShortId,
    required this.issuedAt,
    required this.customerDisplayName,
    required this.lineItems,
    required this.totalInr,
    required this.paymentMethodLabel,
    this.udhaarBalanceInr = 0,
  });
}

class InvoiceLineItem {
  final String nameDevanagari;
  final int quantity;
  final int unitPriceInr;
  final int lineTotalInr;

  const InvoiceLineItem({
    required this.nameDevanagari,
    required this.quantity,
    required this.unitPriceInr,
    required this.lineTotalInr,
  });
}

/// The renderer. Consumes tokens via [context.yugmaTheme]; never hardcodes
/// colors / fonts / spacing.
///
/// Example:
/// ```dart
/// InvoiceTemplate(
///   data: invoiceData,
///   status: InvoiceStatus.paid,
///   mode: InvoiceRenderMode.preview,
/// )
/// ```
class InvoiceTemplate extends StatelessWidget {
  final InvoiceData data;
  final InvoiceStatus status;
  final InvoiceRenderMode mode;

  const InvoiceTemplate({
    super.key,
    required this.data,
    required this.status,
    this.mode = InvoiceRenderMode.preview,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;
    // Elder-tier transformations apply ONLY to the in-app preview.
    // The PDF render is fixed per UX Spec §10 handoff item #13.
    final bool allowElderTier =
        mode == InvoiceRenderMode.preview && theme.isElderTier;

    return Stack(
      children: [
        Container(
          color: theme.shopBackground,
          padding: const EdgeInsets.all(YugmaSpacing.s6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InvoiceHeader(theme: theme, allowElderTier: allowElderTier),
              const SizedBox(height: YugmaSpacing.s4),
              _InvoiceDivider(theme: theme),
              const SizedBox(height: YugmaSpacing.s3),
              _InvoiceMetaRow(
                theme: theme,
                data: data,
                allowElderTier: allowElderTier,
              ),
              const SizedBox(height: YugmaSpacing.s4),
              _InvoiceLineItems(
                theme: theme,
                items: data.lineItems,
                allowElderTier: allowElderTier,
              ),
              const SizedBox(height: YugmaSpacing.s3),
              _InvoiceDivider(theme: theme),
              const SizedBox(height: YugmaSpacing.s3),
              _InvoiceTotals(
                theme: theme,
                data: data,
                status: status,
                allowElderTier: allowElderTier,
              ),
              const SizedBox(height: YugmaSpacing.s8),
              _InvoiceFooter(theme: theme, allowElderTier: allowElderTier),
            ],
          ),
        ),

        // Cancelled watermark — 45-deg `रद्द` at 15% opacity in red-ink
        // color token (shopCommit, which IS the red-ink). Does not block
        // reading — the customer may still share the cancelled receipt as
        // part of a refund trail.
        if (status == InvoiceStatus.cancelled)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Transform.rotate(
                  angle: -0.52, // ~ -30 degrees
                  child: Opacity(
                    opacity: 0.15,
                    child: Text(
                      'रद्द',
                      style: TextStyle(
                        fontFamily: theme.fontFamilyDevanagariDisplay,
                        fontSize: 160,
                        color: theme.shopCommit,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Header: logo/initial + shop name + address + GST + VPA ────────────
class _InvoiceHeader extends StatelessWidget {
  final YugmaThemeExtension theme;
  final bool allowElderTier;
  const _InvoiceHeader({required this.theme, required this.allowElderTier});

  @override
  Widget build(BuildContext context) {
    // Fallback state #39: no shop logo → Devanagari-initial circle.
    // Matches B1.2's fallback treatment (same ShopkeeperFaceFrame visual
    // vocabulary — initial in Tiro Devanagari Hindi, cornsilk fill, shop
    // accent-color stroke).
    final initial = theme.brandName.isNotEmpty
        ? theme.brandName.substring(0, 1)
        : '';
    // Fixed PDF sizes from UX Spec §4.11 table; preview may scale up.
    final nameSize = allowElderTier ? 36.0 : 32.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.shopSurface,
            border: Border.all(color: theme.shopAccent, width: 2),
          ),
          child: Center(
            child: Text(
              initial,
              style: TextStyle(
                fontFamily: theme.fontFamilyDevanagariDisplay,
                fontSize: 32,
                color: theme.shopPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(width: YugmaSpacing.s4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                theme.brandName, // "सुनील ट्रेडिंग कंपनी"
                style: TextStyle(
                  fontFamily: theme.fontFamilyDevanagariDisplay,
                  fontSize: nameSize,
                  height: YugmaLineHeights.tight,
                  color: theme.shopPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${theme.marketArea}, ${theme.city}',
                style: TextStyle(
                  fontFamily: theme.fontFamilyEnglishBody,
                  fontSize: 10,
                  color: theme.shopTextSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  if (theme.gstNumber != null)
                    Text(
                      'GST: ${theme.gstNumber}  •  ',
                      style: TextStyle(
                        fontFamily: theme.fontFamilyDevanagariBody,
                        fontSize: 11,
                        color: theme.shopTextMuted,
                      ),
                    ),
                  Text(
                    'since ${theme.establishedYear}',
                    style: TextStyle(
                      fontFamily: theme.fontFamilyDevanagariBody,
                      fontSize: 11,
                      color: theme.shopTextMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'VPA: ${theme.upiVpa}   •   ${theme.whatsappNumberE164}',
                style: TextStyle(
                  fontFamily: YugmaFonts.mono,
                  fontSize: 11,
                  color: theme.shopTextMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Receipt # + date + customer name (with `ग्राहक` fallback) ─────────
class _InvoiceMetaRow extends StatelessWidget {
  final YugmaThemeExtension theme;
  final InvoiceData data;
  final bool allowElderTier;
  const _InvoiceMetaRow({
    required this.theme,
    required this.data,
    required this.allowElderTier,
  });

  @override
  Widget build(BuildContext context) {
    // Fallback state #38: missing customer display name → `ग्राहक`
    // fallback. No friction screen ever (Standing Rule 8).
    // UX Spec §5.5 string #36.
    final displayName =
        (data.customerDisplayName?.isNotEmpty ?? false)
            ? data.customerDisplayName!
            : 'ग्राहक';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'रसीद # ${data.projectShortId}',
              style: TextStyle(
                fontFamily: YugmaFonts.mono,
                fontSize: 12,
                color: theme.shopTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ग्राहक: $displayName',
              style: TextStyle(
                fontFamily: theme.fontFamilyDevanagariBody,
                fontSize: 12,
                color: theme.shopTextSecondary,
              ),
            ),
          ],
        ),
        Text(
          'दिनांक: ${_formatDate(data.issuedAt)}',
          style: TextStyle(
            fontFamily: theme.fontFamilyDevanagariBody,
            fontSize: 12,
            color: theme.shopTextSecondary,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime t) {
    // Simple "{day} {month} {year}" in Devanagari numerals is overkill for
    // v1 — we use Latin digits + Devanagari month name from a lookup table.
    const months = [
      'जनवरी', 'फरवरी', 'मार्च', 'अप्रैल', 'मई', 'जून',
      'जुलाई', 'अगस्त', 'सितंबर', 'अक्टूबर', 'नवंबर', 'दिसंबर',
    ];
    return '${t.day} ${months[t.month - 1]} ${t.year}';
  }
}

// ─── Line items table — Mukta body + DM Mono numerics ──────────────────
class _InvoiceLineItems extends StatelessWidget {
  final YugmaThemeExtension theme;
  final List<InvoiceLineItem> items;
  final bool allowElderTier;
  const _InvoiceLineItems({
    required this.theme,
    required this.items,
    required this.allowElderTier,
  });

  @override
  Widget build(BuildContext context) {
    // Page-break at >10 line items (state #40) is handled by the `pdf`
    // package's MultiPage directive at render time, not in the widget
    // tree. Here we just emit all items; the PDF renderer wraps.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LineRow(
          theme: theme,
          name: 'सामान',
          qty: 'मात्रा',
          unit: 'दाम',
          total: 'कुल',
          isHeader: true,
        ),
        const SizedBox(height: 4),
        ...items.map(
          (it) => _LineRow(
            theme: theme,
            name: it.nameDevanagari,
            qty: it.quantity.toString(),
            unit: '₹${_formatInr(it.unitPriceInr)}',
            total: '₹${_formatInr(it.lineTotalInr)}',
            isHeader: false,
          ),
        ),
      ],
    );
  }
}

class _LineRow extends StatelessWidget {
  final YugmaThemeExtension theme;
  final String name;
  final String qty;
  final String unit;
  final String total;
  final bool isHeader;
  const _LineRow({
    required this.theme,
    required this.name,
    required this.qty,
    required this.unit,
    required this.total,
    required this.isHeader,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontFamily: theme.fontFamilyDevanagariBody,
      fontSize: 12,
      color: isHeader ? theme.shopTextPrimary : theme.shopTextPrimary,
      fontWeight: isHeader ? FontWeight.w600 : FontWeight.w400,
    );
    final numStyle = TextStyle(
      fontFamily: YugmaFonts.mono,
      fontSize: 12,
      color: theme.shopTextPrimary,
      fontWeight: isHeader ? FontWeight.w600 : FontWeight.w400,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text(name, style: labelStyle)),
          Expanded(
            flex: 1,
            child: Text(
              qty,
              style: isHeader ? labelStyle : numStyle,
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              unit,
              style: isHeader ? labelStyle : numStyle,
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              total,
              style: isHeader ? labelStyle : numStyle,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Totals block — DM Mono 16pt bold + payment method +
//                   optional `बाकी: ₹{amount}` line ─────────────────────
class _InvoiceTotals extends StatelessWidget {
  final YugmaThemeExtension theme;
  final InvoiceData data;
  final InvoiceStatus status;
  final bool allowElderTier;

  const _InvoiceTotals({
    required this.theme,
    required this.data,
    required this.status,
    required this.allowElderTier,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'कुल: ',
              style: TextStyle(
                fontFamily: theme.fontFamilyDevanagariBody,
                fontSize: 13,
                color: theme.shopTextPrimary,
              ),
            ),
            Text(
              '₹${_formatInr(data.totalInr)}',
              style: TextStyle(
                fontFamily: YugmaFonts.mono,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.shopPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'भुगतान: ${data.paymentMethodLabel}',
          style: TextStyle(
            fontFamily: theme.fontFamilyDevanagariBody,
            fontSize: 11,
            color: theme.shopTextMuted,
          ),
        ),
        // State #37: udhaar-open variant adds exactly ONE line below the
        // totals. No interest column. No due-date field. No penalty line.
        // UX Spec §5.5 string #35 — "बाकी" is the only permitted word.
        // CI lint at packages/lib_core/lib/src/invoice/invoice_template.dart
        // rejects any edit introducing R10 forbidden substrings.
        if (status == InvoiceStatus.udhaarOpen) ...[
          const SizedBox(height: YugmaSpacing.s2),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: YugmaSpacing.s3,
              vertical: YugmaSpacing.s2,
            ),
            decoration: BoxDecoration(
              color: theme.shopBackgroundWarmer,
              border: Border(
                left: BorderSide(color: theme.shopCommit, width: 3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'बाकी: ',
                  style: TextStyle(
                    fontFamily: theme.fontFamilyDevanagariBody,
                    fontSize: 13,
                    color: theme.shopCommit,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '₹${_formatInr(data.udhaarBalanceInr)}',
                  style: TextStyle(
                    fontFamily: YugmaFonts.mono,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.shopCommit,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Footer: Mukta 13pt thank-you + Mukta italic 24pt signature ────────
class _InvoiceFooter extends StatelessWidget {
  final YugmaThemeExtension theme;
  final bool allowElderTier;
  const _InvoiceFooter({required this.theme, required this.allowElderTier});

  @override
  Widget build(BuildContext context) {
    // UX Spec §5.5 string #31 — plain, no mythic framing.
    // Constraint 10 cross-check: "विश्वास" and "भविष्य" are everyday
    // commerce words, NOT Sanskritized temple vocabulary.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(
            'धन्यवाद, आपका विश्वास हमारा भविष्य है',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: theme.fontFamilyDevanagariBody,
              fontSize: 13,
              color: theme.shopTextPrimary,
              // Plain, NOT italic — italic is reserved for the signature.
            ),
          ),
        ),
        const SizedBox(height: YugmaSpacing.s6),
        // The one deliberate typographic-personality moment. Mukta italic
        // 24pt is the closest approximation to handwritten warmth inside
        // Constraint 4. Caveat is forbidden. Any new Google Font is
        // forbidden. This is the signature fallback that stays inside the
        // 5-font stack.
        Text(
          theme.ownerName, // "सुनील भैया"
          style: TextStyle(
            fontFamily: theme.fontFamilyDevanagariBody,
            fontSize: 24,
            fontStyle: FontStyle.italic,
            color: theme.shopPrimary,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 120,
          height: 1.5,
          color: theme.shopAccent,
        ),
      ],
    );
  }
}

class _InvoiceDivider extends StatelessWidget {
  final YugmaThemeExtension theme;
  const _InvoiceDivider({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1.5,
      color: theme.shopDivider,
    );
  }
}

// ─── PDF render-failure fallback widget (state #41b) ───────────────────
//
// Used as a graceful-degradation alternative when the `pdf` package
// throws on a cheap Android device (OOM, font subset glitch, platform
// quirk). Per UX Spec §6.6 state #41b, this widget:
//   1. Renders the same copy content as the main template
//   2. Uses Mukta body only (no fancy header typography, no circle logo,
//      no watermark)
//   3. If even this plain variant fails, the caller shows the inline
//      error string from UX Spec §5.5 #41b and logs `b1_13_pdf_render_failed`
//      to Crashlytics
//
// Never a white-screen failure.

class InvoiceTextOnlyFallback extends StatelessWidget {
  final InvoiceData data;
  final InvoiceStatus status;

  const InvoiceTextOnlyFallback({
    super.key,
    required this.data,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;
    final displayName =
        (data.customerDisplayName?.isNotEmpty ?? false)
            ? data.customerDisplayName!
            : 'ग्राहक';

    return Container(
      color: theme.shopBackground,
      padding: const EdgeInsets.all(YugmaSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            theme.brandName,
            style: TextStyle(
              fontFamily: theme.fontFamilyDevanagariBody,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.shopPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${theme.marketArea}, ${theme.city}',
            style: TextStyle(
              fontFamily: theme.fontFamilyDevanagariBody,
              fontSize: 11,
              color: theme.shopTextMuted,
            ),
          ),
          const SizedBox(height: YugmaSpacing.s4),
          Text(
            'रसीद # ${data.projectShortId}',
            style: TextStyle(
              fontFamily: YugmaFonts.mono,
              fontSize: 12,
              color: theme.shopTextPrimary,
            ),
          ),
          Text(
            'ग्राहक: $displayName',
            style: TextStyle(
              fontFamily: theme.fontFamilyDevanagariBody,
              fontSize: 12,
              color: theme.shopTextSecondary,
            ),
          ),
          const SizedBox(height: YugmaSpacing.s3),
          ...data.lineItems.map(
            (it) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '${it.nameDevanagari}  ×${it.quantity}  ₹${_formatInr(it.lineTotalInr)}',
                style: TextStyle(
                  fontFamily: theme.fontFamilyDevanagariBody,
                  fontSize: 12,
                  color: theme.shopTextPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: YugmaSpacing.s3),
          Text(
            'कुल: ₹${_formatInr(data.totalInr)}',
            style: TextStyle(
              fontFamily: YugmaFonts.mono,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: theme.shopPrimary,
            ),
          ),
          if (status == InvoiceStatus.udhaarOpen)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'बाकी: ₹${_formatInr(data.udhaarBalanceInr)}',
                style: TextStyle(
                  fontFamily: YugmaFonts.mono,
                  fontSize: 13,
                  color: theme.shopCommit,
                ),
              ),
            ),
          const SizedBox(height: YugmaSpacing.s4),
          Text(
            'धन्यवाद, आपका विश्वास हमारा भविष्य है',
            style: TextStyle(
              fontFamily: theme.fontFamilyDevanagariBody,
              fontSize: 12,
              color: theme.shopTextPrimary,
            ),
          ),
          const SizedBox(height: YugmaSpacing.s3),
          Text(
            theme.ownerName,
            style: TextStyle(
              fontFamily: theme.fontFamilyDevanagariBody,
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: theme.shopPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// Shared helper: Indian number-system grouping (17,500 not 17500).
String _formatInr(int amount) {
  final s = amount.toString();
  if (s.length <= 3) return s;
  if (s.length <= 5) {
    return '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
  }
  final last3 = s.substring(s.length - 3);
  final mid = s.substring(s.length - 5, s.length - 3);
  final rest = s.substring(0, s.length - 5);
  return '$rest,$mid,$last3';
}
