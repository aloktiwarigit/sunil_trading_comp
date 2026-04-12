// =============================================================================
// ActiveProjectsController — Riverpod controller for S4.6 active projects list.
//
// Per S4.6:
//   AC #1: Projects sorted by updatedAt desc, paginated by 20
//   AC #3: Filter chips (All / Committed / Pending / Delivering / Closed)
//   AC #6: Real-time updates via Firestore listener
// =============================================================================

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';

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
  const shopId = 'sunil-trading-company'; // flagship shop

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
      return Project.fromJson(<String, dynamic>{
        ...doc.data(),
        'projectId': doc.id,
      });
    }).toList();
  });
});
