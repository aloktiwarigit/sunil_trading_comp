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
    final theme = context.yugmaTheme;
    final projectAsync = ref.watch(customerProjectDetailProvider(projectId));

    return Scaffold(
      backgroundColor: theme.shopBackground,
      appBar: AppBar(
        backgroundColor: theme.shopPrimary,
        foregroundColor: theme.shopTextOnPrimary,
        title: Text(
          strings.ordersTitle,
          style: theme.h2Deva.copyWith(
            fontSize: YugmaTypeScale.h3,
          ),
        ),
      ),
      body: projectAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: theme.shopPrimary),
        ),
        error: (err, _) => YugmaErrorBanner(error: err),
        data: (project) {
          if (project == null) {
            return Center(
              child: Text(
                strings.emptyOrdersList,
                style: theme.bodyDeva,
              ),
            );
          }
          return _buildDetail(context, ref, project);
        },
      ),
    );
  }

  Widget _buildDetail(BuildContext context, WidgetRef ref, Project project) {
    final theme = context.yugmaTheme;
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
              color: theme.shopSurface,
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
                        '₹${formatInr(project.totalAmount)}',
                        style: theme.monoNumeral.copyWith(
                          fontSize: YugmaTypeScale.display,
                          fontWeight: FontWeight.w700,
                          color: theme.shopTextPrimary,
                        ),
                      ),
                      const SizedBox(height: YugmaSpacing.s1),
                      Text(
                        '${strings.orderItemCount(project.lineItems.length)} · #$shortId',
                        style: TextStyle(
                          fontFamily: theme.fontFamilyEnglishBody,
                          fontSize: YugmaTypeScale.caption,
                          color: theme.shopTextSecondary,
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
            strings.orderStatusLabel,
            style: theme.bodyDeva.copyWith(
              fontSize: YugmaTypeScale.bodyLarge,
              fontWeight: FontWeight.w700,
              color: theme.shopTextPrimary,
            ),
          ),
          const SizedBox(height: YugmaSpacing.s2),
          _buildTimeline(context, project),

          // B-6: Download receipt button — visible only for closed/delivering.
          if (project.state == ProjectState.closed ||
              project.state == ProjectState.delivering) ...[
            const SizedBox(height: YugmaSpacing.s3),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _generateAndShareInvoice(context, project),
                icon: const Icon(Icons.receipt_long, semanticLabel: 'Download receipt'),
                label: Text(strings.orderDownloadReceipt),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.shopPrimary,
                  side: BorderSide(color: theme.shopPrimary),
                  textStyle: theme.bodyDeva.copyWith(
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
            style: theme.bodyDeva.copyWith(
              fontSize: YugmaTypeScale.bodyLarge,
              fontWeight: FontWeight.w700,
              color: theme.shopTextPrimary,
            ),
          ),
          const SizedBox(height: YugmaSpacing.s2),
          _buildLineItems(context, project),
        ],
      ),
    );
  }

  /// C3.10 AC #3: vertical state timeline.
  /// Only visited states show (edge case #1).
  Widget _buildTimeline(BuildContext context, Project project) {
    final entries = _buildTimelineEntries(project);

    final theme = context.yugmaTheme;
    return Container(
      padding: const EdgeInsets.all(YugmaSpacing.s4),
      decoration: BoxDecoration(
        color: theme.shopSurface,
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
              strings: strings,
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
        label: strings.timelineCommitted,
        timestamp: project.committedAt,
        isActive: true,
        isCurrent: currentState == ProjectState.committed,
      ));
    }

    // Paid or Udhaar started
    if (project.paidAt != null) {
      final label = project.udhaarLedgerId != null
          ? strings.timelineUdhaarStarted
          : strings.timelinePaid;
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
        label: strings.timelineBankTransferPending,
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
        label: strings.timelineDelivering,
        timestamp: null,
        isActive: project.deliveredAt != null ||
            currentState == ProjectState.closed,
        isCurrent: currentState == ProjectState.delivering,
      ));
    }

    // Delivered
    if (project.deliveredAt != null) {
      entries.add(_TimelineEntry(
        label: strings.timelineDelivered,
        timestamp: project.deliveredAt,
        isActive: true,
        isCurrent: currentState == ProjectState.closed &&
            project.closedAt == null,
      ));
    }

    // Closed
    if (project.closedAt != null) {
      entries.add(_TimelineEntry(
        label: strings.timelineClosed,
        timestamp: project.closedAt,
        isActive: true,
        isCurrent: currentState == ProjectState.closed,
      ));
    }

    // Cancelled (edge case #2)
    if (currentState == ProjectState.cancelled) {
      entries.add(_TimelineEntry(
        label: strings.timelineCancelled,
        timestamp: project.closedAt ?? project.updatedAt,
        isActive: true,
        isCurrent: true,
      ));
    }

    // If no entries (draft only), show the draft state
    if (entries.isEmpty) {
      entries.add(_TimelineEntry(
        label: strings.timelineDraft,
        timestamp: project.createdAt,
        isActive: true,
        isCurrent: true,
      ));
    }

    return entries;
  }

  Widget _buildLineItems(BuildContext context, Project project) {
    final theme = context.yugmaTheme;
    return Container(
      decoration: BoxDecoration(
        color: theme.shopSurface,
        borderRadius: BorderRadius.circular(YugmaRadius.lg),
        boxShadow: YugmaShadows.card,
      ),
      child: Column(
        children: [
          for (var i = 0; i < project.lineItems.length; i++) ...[
            if (i > 0) Divider(color: theme.shopDivider, height: 1),
            Padding(
              padding: const EdgeInsets.all(YugmaSpacing.s3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      project.lineItems[i].skuName,
                      style: theme.bodyDeva.copyWith(
                        color: theme.shopTextPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '×${project.lineItems[i].quantity}',
                    style: theme.monoNumeral.copyWith(
                      fontSize: YugmaTypeScale.caption,
                      color: theme.shopTextSecondary,
                    ),
                  ),
                  const SizedBox(width: YugmaSpacing.s2),
                  Text(
                    '₹${formatInr(project.lineItems[i].effectivePrice)}',
                    style: theme.monoNumeral.copyWith(
                      fontSize: YugmaTypeScale.body,
                      fontWeight: FontWeight.w600,
                      color: theme.shopTextPrimary,
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
              strings.receiptGenerating,
              style: context.yugmaTheme.bodyDeva,
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Load fonts for the PDF.
      // TODO(F021): Bundle a Devanagari TTF (e.g. NotoSansDevanagari) in
      // assets/fonts/ and load via rootBundle.load() so Hindi text renders
      // correctly in the invoice PDF. Helvetica cannot render Devanagari
      // glyphs — customers will see empty boxes for Hindi strings until
      // this is resolved. Tracking: F021 in gap register.
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
          onboardingState.user.displayName ?? strings.receiptCustomerFallback;

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
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: strings.receiptShareSubject(project.projectId),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              strings.receiptGenerationError('$e'),
              style: context.yugmaTheme.bodyDeva,
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

}

/// A single row in the vertical timeline.
class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.entry,
    required this.isFirst,
    required this.isLast,
    required this.strings,
  });

  final _TimelineEntry entry;
  final bool isFirst;
  final bool isLast;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;
    final activeColor = entry.isActive ? theme.shopPrimary : theme.shopDivider;
    final textColor = entry.isActive ? theme.shopTextPrimary : theme.shopTextMuted;

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
                    style: theme.bodyDeva.copyWith(
                      fontWeight:
                          entry.isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  if (entry.timestamp != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(entry.timestamp!, strings),
                      style: theme.monoNumeral.copyWith(
                        fontSize: YugmaTypeScale.caption,
                        color: theme.shopTextMuted,
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

  /// Format date locale-aware: "11 अप्रैल 2026, 2:30 PM" / "11 April 2026, 2:30 PM"
  static String _formatDate(DateTime date, AppStrings strings) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    final min = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${strings.monthName(date.month)} ${date.year}, $hour:$min $amPm';
  }
}
