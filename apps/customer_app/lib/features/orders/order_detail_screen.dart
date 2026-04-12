// =============================================================================
// OrderDetailScreen — C3.10 AC #3–5: customer order detail with state timeline.
//
// Vertical timeline showing state transitions with timestamps.
// Only visited states show (AC edge case #1: state skips).
// Cancelled projects show रद्द with reason (edge case #2).
// =============================================================================

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../main.dart' show authProviderInstanceProvider;
import '../onboarding/onboarding_controller.dart';

/// Normalize Firestore Timestamp → ISO8601 for Freezed JSON parsing.
Object? _normalizeTimestamp(Object? value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate().toIso8601String();
  if (value is DateTime) return value.toIso8601String();
  return value;
}

/// Provider for a single project by ID (customer-side).
/// Provider for a single project by ID (customer-side).
/// CR F5: guard by customerUid — defence-in-depth against cross-customer reads.
final customerProjectDetailProvider =
    StreamProvider.autoDispose.family<Project?, String>((ref, projectId) {
  final firestore = FirebaseFirestore.instance;
  final shopId = ref.read(shopIdProviderProvider).shopId;
  final currentUid = ref.read(authProviderInstanceProvider).currentUser?.uid;

  return firestore
      .collection('shops')
      .doc(shopId)
      .collection('projects')
      .doc(projectId)
      .snapshots()
      .map((snap) {
    if (!snap.exists) return null;
    final raw = snap.data()!;
    // CR F5: verify this project belongs to the current customer.
    final projectCustomerUid = raw['customerUid'] as String?;
    if (currentUid != null && projectCustomerUid != currentUid) return null;
    return Project.fromJson(<String, dynamic>{
      ...raw,
      'projectId': snap.id,
      'createdAt': _normalizeTimestamp(raw['createdAt']),
      'committedAt': _normalizeTimestamp(raw['committedAt']),
      'paidAt': _normalizeTimestamp(raw['paidAt']),
      'deliveredAt': _normalizeTimestamp(raw['deliveredAt']),
      'closedAt': _normalizeTimestamp(raw['closedAt']),
      'lastMessageAt': _normalizeTimestamp(raw['lastMessageAt']),
      'updatedAt': _normalizeTimestamp(raw['updatedAt']),
    });
  });
});

/// A single entry in the state timeline.
class _TimelineEntry {
  const _TimelineEntry({
    required this.label,
    required this.timestamp,
    this.isActive = false,
    this.isCurrent = false,
  });

  final String label;
  final DateTime? timestamp;
  final bool isActive;
  final bool isCurrent;
}

/// C3.10 — Order detail screen with vertical state timeline.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({
    super.key,
    required this.projectId,
    required this.strings,
  });

  final String projectId;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(customerProjectDetailProvider(projectId));

    return Scaffold(
      backgroundColor: YugmaColors.background,
      appBar: AppBar(
        backgroundColor: YugmaColors.primary,
        foregroundColor: YugmaColors.textOnPrimary,
        title: Text(
          strings.ordersTitle,
          style: TextStyle(
            fontFamily: YugmaFonts.devaDisplay,
            fontSize: YugmaTypeScale.h3,
          ),
        ),
      ),
      body: projectAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: YugmaColors.primary),
        ),
        error: (err, _) => YugmaErrorBanner(error: err),
        data: (project) {
          if (project == null) {
            return Center(
              child: Text(
                strings.emptyOrdersList,
                style: TextStyle(fontFamily: YugmaFonts.devaBody),
              ),
            );
          }
          return _buildDetail(context, ref, project);
        },
      ),
    );
  }

  Widget _buildDetail(BuildContext context, WidgetRef ref, Project project) {
    final shortId = project.projectId.length > 6
        ? project.projectId.substring(project.projectId.length - 6)
        : project.projectId;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(YugmaSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — total + ID
          Container(
            padding: const EdgeInsets.all(YugmaSpacing.s4),
            decoration: BoxDecoration(
              color: YugmaColors.surface,
              borderRadius: BorderRadius.circular(YugmaRadius.lg),
              boxShadow: YugmaShadows.card,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${_formatInr(project.totalAmount)}',
                        style: TextStyle(
                          fontFamily: YugmaFonts.mono,
                          fontSize: YugmaTypeScale.display,
                          fontWeight: FontWeight.w700,
                          color: YugmaColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: YugmaSpacing.s1),
                      Text(
                        '${project.lineItems.length} सामान · #$shortId',
                        style: TextStyle(
                          fontFamily: YugmaFonts.enBody,
                          fontSize: YugmaTypeScale.caption,
                          color: YugmaColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: YugmaSpacing.s4),

          // State timeline (AC #3)
          Text(
            'स्थिति',
            style: TextStyle(
              fontFamily: YugmaFonts.devaBody,
              fontSize: YugmaTypeScale.bodyLarge,
              fontWeight: FontWeight.w700,
              color: YugmaColors.textPrimary,
            ),
          ),
          const SizedBox(height: YugmaSpacing.s2),
          _buildTimeline(project),

          // B-6: Download receipt button — visible only for closed/delivering.
          if (project.state == ProjectState.closed ||
              project.state == ProjectState.delivering) ...[
            const SizedBox(height: YugmaSpacing.s3),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _generateAndShareInvoice(context, project),
                icon: const Icon(Icons.receipt_long),
                label: const Text('रसीद डाउनलोड करें'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: YugmaColors.primary,
                  side: BorderSide(color: YugmaColors.primary),
                  textStyle: TextStyle(
                    fontFamily: YugmaFonts.devaBody,
                    fontSize: YugmaTypeScale.body,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: YugmaSpacing.s4),

          // Line items
          Text(
            strings.lineItemsHeader,
            style: TextStyle(
              fontFamily: YugmaFonts.devaBody,
              fontSize: YugmaTypeScale.bodyLarge,
              fontWeight: FontWeight.w700,
              color: YugmaColors.textPrimary,
            ),
          ),
          const SizedBox(height: YugmaSpacing.s2),
          _buildLineItems(project),
        ],
      ),
    );
  }

  /// C3.10 AC #3: vertical state timeline.
  /// Only visited states show (edge case #1).
  Widget _buildTimeline(Project project) {
    final entries = _buildTimelineEntries(project);

    return Container(
      padding: const EdgeInsets.all(YugmaSpacing.s4),
      decoration: BoxDecoration(
        color: YugmaColors.surface,
        borderRadius: BorderRadius.circular(YugmaRadius.lg),
        boxShadow: YugmaShadows.card,
      ),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            _TimelineRow(
              entry: entries[i],
              isFirst: i == 0,
              isLast: i == entries.length - 1,
            ),
          ],
        ],
      ),
    );
  }

  /// Build timeline entries based on which states the project has visited.
  /// C3.10 edge case #1: only visited states show.
  List<_TimelineEntry> _buildTimelineEntries(Project project) {
    final entries = <_TimelineEntry>[];
    final currentState = project.state;

    // Committed
    if (project.committedAt != null) {
      entries.add(_TimelineEntry(
        label: 'पुष्टि की गयी',
        timestamp: project.committedAt,
        isActive: true,
        isCurrent: currentState == ProjectState.committed,
      ));
    }

    // Paid or Udhaar started
    if (project.paidAt != null) {
      final label = project.udhaarLedgerId != null
          ? 'उधार खाता शुरू'
          : 'भुगतान हुआ';
      entries.add(_TimelineEntry(
        label: label,
        timestamp: project.paidAt,
        isActive: true,
        isCurrent: currentState == ProjectState.paid,
      ));
    }

    // Awaiting verification (bank transfer — C3.7)
    // CR F4: handle awaitingVerification state in timeline.
    if (currentState == ProjectState.awaitingVerification) {
      entries.add(_TimelineEntry(
        label: 'बैंक ट्रांसफ़र — जाँच बाकी',
        timestamp: null,
        isActive: true,
        isCurrent: true,
      ));
    }

    // Delivering
    if (currentState == ProjectState.delivering ||
        project.deliveredAt != null ||
        currentState == ProjectState.closed) {
      entries.add(_TimelineEntry(
        label: 'डिलीवरी में',
        timestamp: null,
        isActive: project.deliveredAt != null ||
            currentState == ProjectState.closed,
        isCurrent: currentState == ProjectState.delivering,
      ));
    }

    // Delivered
    if (project.deliveredAt != null) {
      entries.add(_TimelineEntry(
        label: 'डिलीवर हुआ',
        timestamp: project.deliveredAt,
        isActive: true,
        isCurrent: currentState == ProjectState.closed &&
            project.closedAt == null,
      ));
    }

    // Closed
    if (project.closedAt != null) {
      entries.add(_TimelineEntry(
        label: 'बंद हुआ',
        timestamp: project.closedAt,
        isActive: true,
        isCurrent: currentState == ProjectState.closed,
      ));
    }

    // Cancelled (edge case #2)
    if (currentState == ProjectState.cancelled) {
      entries.add(_TimelineEntry(
        label: 'रद्द',
        timestamp: project.closedAt ?? project.updatedAt,
        isActive: true,
        isCurrent: true,
      ));
    }

    // If no entries (draft only), show the draft state
    if (entries.isEmpty) {
      entries.add(_TimelineEntry(
        label: 'ड्राफ़्ट',
        timestamp: project.createdAt,
        isActive: true,
        isCurrent: true,
      ));
    }

    return entries;
  }

  Widget _buildLineItems(Project project) {
    return Container(
      decoration: BoxDecoration(
        color: YugmaColors.surface,
        borderRadius: BorderRadius.circular(YugmaRadius.lg),
        boxShadow: YugmaShadows.card,
      ),
      child: Column(
        children: [
          for (var i = 0; i < project.lineItems.length; i++) ...[
            if (i > 0) Divider(color: YugmaColors.divider, height: 1),
            Padding(
              padding: const EdgeInsets.all(YugmaSpacing.s3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      project.lineItems[i].skuName,
                      style: TextStyle(
                        fontFamily: YugmaFonts.devaBody,
                        fontSize: YugmaTypeScale.body,
                        color: YugmaColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '×${project.lineItems[i].quantity}',
                    style: TextStyle(
                      fontFamily: YugmaFonts.mono,
                      fontSize: YugmaTypeScale.caption,
                      color: YugmaColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: YugmaSpacing.s2),
                  Text(
                    '₹${_formatInr(project.lineItems[i].effectivePrice)}',
                    style: TextStyle(
                      fontFamily: YugmaFonts.mono,
                      fontSize: YugmaTypeScale.body,
                      fontWeight: FontWeight.w600,
                      color: YugmaColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// B-6: Generate invoice PDF and share via platform sheet.
  Future<void> _generateAndShareInvoice(
    BuildContext context,
    Project project,
  ) async {
    try {
      // Show loading indicator.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'रसीद बन रही है…',
              style: TextStyle(fontFamily: YugmaFonts.devaBody),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Load fonts for the PDF.
      // NOTE: When font TTF assets are bundled, load them via rootBundle.
      // For now, use the pdf package's built-in Helvetica as a fallback.
      final devaDisplay = pw.Font.helvetica();
      final devaBody = pw.Font.helvetica();
      final devaBodyItalic = pw.Font.helveticaOblique();
      final mono = pw.Font.courier();

      final template = InvoiceTemplate(
        devaDisplayFont: devaDisplay,
        devaBodyFont: devaBody,
        devaBodyFontItalic: devaBodyItalic,
        monoFont: mono,
      );

      // Assemble the payload. Read shop tokens from onboarding state.
      // The onboardingControllerProvider is available via ProviderScope.
      final container = ProviderScope.containerOf(context);
      final onboardingState =
          container.read(onboardingControllerProvider).valueOrNull;
      if (onboardingState == null) return;

      final customerName =
          onboardingState.user.displayName ?? 'ग्राहक';

      final payload = InvoicePayload(
        project: project,
        shopTokens: onboardingState.themeTokens,
        customerDisplayName: customerName,
      );

      // Generate PDF bytes.
      final pdfBytes = await template.generate(payload);

      // Save to temp directory.
      final tempDir = await getTemporaryDirectory();
      final date = project.committedAt ?? project.createdAt;
      final fileName = InvoiceTemplate.fileName(project.projectId, date);
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      // Share via platform sheet.
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'रसीद — ${project.projectId}',
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'रसीद बनाने में समस्या: $e',
              style: TextStyle(fontFamily: YugmaFonts.devaBody),
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

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
}

/// A single row in the vertical timeline.
class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.entry,
    required this.isFirst,
    required this.isLast,
  });

  final _TimelineEntry entry;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final activeColor = entry.isActive ? YugmaColors.primary : YugmaColors.divider;
    final textColor = entry.isActive ? YugmaColors.textPrimary : YugmaColors.textMuted;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 32,
            child: Column(
              children: [
                // Top line (hidden for first)
                if (!isFirst)
                  Container(width: 2, height: 8, color: activeColor),
                // Dot
                Container(
                  width: entry.isCurrent ? 16 : 12,
                  height: entry.isCurrent ? 16 : 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: entry.isCurrent ? activeColor : Colors.transparent,
                    border: Border.all(color: activeColor, width: 2),
                  ),
                ),
                // Bottom line (hidden for last)
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: activeColor),
                  ),
              ],
            ),
          ),
          const SizedBox(width: YugmaSpacing.s2),
          // Label + timestamp
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: YugmaSpacing.s3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.label,
                    style: TextStyle(
                      fontFamily: YugmaFonts.devaBody,
                      fontSize: YugmaTypeScale.body,
                      fontWeight:
                          entry.isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  if (entry.timestamp != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(entry.timestamp!),
                      style: TextStyle(
                        fontFamily: YugmaFonts.mono,
                        fontSize: YugmaTypeScale.caption,
                        color: YugmaColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Format date in Devanagari: "11 अप्रैल 2026, 2:30 PM"
  static String _formatDate(DateTime date) {
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
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    final min = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month]} ${date.year}, $hour:$min $amPm';
  }
}
