// =============================================================================
// ActiveProjectsController — Riverpod controller for S4.6 active projects list.
//
// Per S4.6:
//   AC #1: Projects sorted by updatedAt desc, paginated by 20
//   AC #3: Filter chips (All / Committed / Pending / Delivering / Closed)
//   AC #6: Real-time updates via Firestore listener
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';

/// SD005 fix: normalize Firestore Timestamp → ISO8601 for Freezed JSON.
Object? _normalizeTimestamp(Object? value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate().toIso8601String();
  if (value is DateTime) return value.toIso8601String();
  return value;
}

/// The active filter for the projects list.
enum ProjectFilter {
  all,
  committed,
  pendingPayment,
  delivering,
  closed,
}

/// Provider for the current filter selection.
final projectFilterProvider = StateProvider<ProjectFilter>(
  (ref) => ProjectFilter.all,
);

/// Provider for the active projects stream, filtered by current selection.
final activeProjectsProvider = StreamProvider<List<Project>>((ref) {
  final filter = ref.watch(projectFilterProvider);
  final firestore = FirebaseFirestore.instance;
  final shopId = ref.read(shopIdProviderProvider).shopId;

  var query = firestore
      .collection('shops')
      .doc(shopId)
      .collection('projects')
      .orderBy('updatedAt', descending: true)
      .limit(20);

  // Apply state filter.
  switch (filter) {
    case ProjectFilter.all:
      // Exclude drafts and cancelled — shopkeeper only sees active orders.
      query = query.where('state', whereIn: [
        'committed',
        'paid',
        'delivering',
        'awaiting_verification',
        'closed',
      ]);
    case ProjectFilter.committed:
      query = query.where('state', isEqualTo: 'committed');
    case ProjectFilter.pendingPayment:
      query = query.where('state', whereIn: [
        'committed',
        'awaiting_verification',
      ]);
    case ProjectFilter.delivering:
      query = query.where('state', isEqualTo: 'delivering');
    case ProjectFilter.closed:
      query = query.where('state', isEqualTo: 'closed');
  }

  return query.snapshots().map((snapshot) {
    return snapshot.docs.map((doc) {
      final raw = doc.data();
      return Project.fromJson(<String, dynamic>{
        ...raw,
        'projectId': doc.id,
        // SD005 fix: normalize Timestamps to avoid Freezed fromJson crash.
        'createdAt': _normalizeTimestamp(raw['createdAt']),
        'updatedAt': _normalizeTimestamp(raw['updatedAt']),
        'committedAt': _normalizeTimestamp(raw['committedAt']),
        'paidAt': _normalizeTimestamp(raw['paidAt']),
        'cancelledAt': _normalizeTimestamp(raw['cancelledAt']),
        'deliveredAt': _normalizeTimestamp(raw['deliveredAt']),
      });
    }).toList();
  });
});

/// Provider for the search query text.
final searchQueryProvider = StateProvider<String>(
  (ref) => '',
);

/// Filtered projects — applies client-side search over active projects.
///
/// Matches against customerDisplayName, customerPhone, or totalAmount.
/// Empty query returns all projects unfiltered.
final filteredProjectsProvider = Provider<AsyncValue<List<Project>>>((ref) {
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final projectsAsync = ref.watch(activeProjectsProvider);

  if (query.isEmpty) return projectsAsync;

  return projectsAsync.whenData((projects) {
    return projects.where((p) {
      final name = (p.customerDisplayName ?? '').toLowerCase();
      final phone = (p.customerPhone ?? '').toLowerCase();
      final amount = p.totalAmount.toString();
      return name.contains(query) ||
          phone.contains(query) ||
          amount.contains(query);
    }).toList();
  });
});
