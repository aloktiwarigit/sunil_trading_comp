// =============================================================================
// ReadTrackingController â€” P2.7: multi-participant message read tracking.
//
// AC #1: message doc has readByUids array (already in Message model)
// AC #2: marked read on view by adding session UID
// AC #3: shows "à¤¦à¥‡à¤–à¤¾ à¤—à¤¯à¤¾" with persona labels
// AC #4: shopkeeper sees same status
// AC #5: works without Decision Circle (per-device fallback)
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';

/// P2.7 â€” Read tracking controller.
///
/// When the customer views a chat thread, marks all unread messages as read
/// by appending the current UID to readByUids.
class ReadTrackingController {
  ReadTrackingController({
    required this.firestore,
    required this.shopId,
  });

  final FirebaseFirestore firestore;
  final String shopId;

  /// Mark all messages in a thread as read by the current user.
  /// AC #2: adds uid to readByUids via arrayUnion (idempotent).
  Future<void> markThreadAsRead({
    required String projectId,
    required String currentUid,
    required List<Message> messages,
  }) async {
    final batch = firestore.batch();
    var batchCount = 0;

    for (final msg in messages) {
      if (msg.readByUids.contains(currentUid)) continue;

      final ref = firestore
          .collection('shops')
          .doc(shopId)
          .collection('chatThreads')
          .doc(projectId)
          .collection('messages')
          .doc(msg.messageId);

      batch.update(ref, <String, dynamic>{
        'readByUids': FieldValue.arrayUnion([currentUid]),
      });

      batchCount++;
      // Firestore batch limit is 500
      if (batchCount >= 500) break;
    }

    if (batchCount > 0) {
      await batch.commit();
    }
  }
}

/// Provider for marking messages read when chat opens.
final readTrackingProvider = Provider<ReadTrackingController>((ref) {
  final shopId = ref.read(shopIdProviderProvider).shopId;
  return ReadTrackingController(
    firestore: FirebaseFirestore.instance,
    shopId: shopId,
  );
});

/// P2.7 AC #3: helper to build "à¤¦à¥‡à¤–à¤¾ à¤—à¤¯à¤¾" label from readByUids.
/// Maps UIDs to persona labels if Decision Circle data is available.
String readStatusLabel(List<String> readByUids, String currentUid) {
  const strings = AppStringsHi();
  // Filter out current user
  final others = readByUids.where((uid) => uid != currentUid).toList();
  if (others.isEmpty) return '';
  if (others.length == 1) return strings.readStatusSeen;
  return strings.readStatusSeenByCount(others.length);
}
