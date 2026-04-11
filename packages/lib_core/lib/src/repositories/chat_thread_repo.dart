// =============================================================================
// ChatThreadRepo — same partition discipline as ProjectRepo.
//
// Per PRD Standing Rule 11: participant (customer) / operator / system.
// See `project_repo.dart` for the design rationale.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import '../models/chat_thread.dart';
import '../models/chat_thread_patch.dart';
import '../shop_id_provider.dart';

class ChatThreadRepo {
  ChatThreadRepo({
    required FirebaseFirestore firestore,
    required ShopIdProvider shopIdProvider,
  })  : _firestore = firestore,
        _shopIdProvider = shopIdProvider;

  final FirebaseFirestore _firestore;
  final ShopIdProvider _shopIdProvider;
  static final Logger _log = Logger('ChatThreadRepo');

  CollectionReference<Map<String, dynamic>> _collection() =>
      _firestore
          .collection('shops')
          .doc(_shopIdProvider.shopId)
          .collection('chatThreads');

  Future<ChatThread?> getById(String threadId) async {
    final snap = await _collection().doc(threadId).get();
    if (!snap.exists) return null;
    return ChatThread.fromJson(<String, dynamic>{
      ...snap.data()!,
      'threadId': threadId,
    });
  }

  Stream<ChatThread?> watchById(String threadId) =>
      _collection().doc(threadId).snapshots().map((snap) {
        if (!snap.exists) return null;
        return ChatThread.fromJson(<String, dynamic>{
          ...snap.data()!,
          'threadId': threadId,
        });
      });

  Future<void> applyParticipantPatch(
    String threadId,
    ChatThreadParticipantPatch patch,
  ) async {
    final map = patch.toFirestoreMap();
    if (map.isEmpty) return;
    await _collection().doc(threadId).set(map, SetOptions(merge: true));
    _log.info('participant patch applied: threadId=$threadId');
  }

  Future<void> applyOperatorPatch(
    String threadId,
    ChatThreadOperatorPatch patch,
  ) async {
    final map = patch.toFirestoreMap();
    if (map.isEmpty) return;
    await _collection().doc(threadId).set(map, SetOptions(merge: true));
    _log.info('operator patch applied: threadId=$threadId');
  }

  Future<void> applySystemPatch(
    String threadId,
    ChatThreadSystemPatch patch,
  ) async {
    final map = patch.toFirestoreMap();
    if (map.isEmpty) return;
    await _collection().doc(threadId).set(map, SetOptions(merge: true));
  }
}
