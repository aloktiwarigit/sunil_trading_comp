// =============================================================================
// ChatThread — Freezed model for /shops/{shopId}/chatThreads/{threadId}.
//
// Same partition discipline as Project per PRD Standing Rule 11.
// =============================================================================

import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_thread.freezed.dart';
part 'chat_thread.g.dart';

@freezed
class ChatThread with _$ChatThread {
  const factory ChatThread({
    required String threadId,
    required String shopId,
    required String projectId,
    required String customerUid,
    required String customerDisplayName,
    required List<String> participantUids,
    required DateTime createdAt,
    DateTime? lastMessageAt,
    String? lastMessagePreview,
    @Default(0) int unreadCountForCustomer,
    @Default(0) int unreadCountForShopkeeper,
  }) = _ChatThread;

  factory ChatThread.fromJson(Map<String, dynamic> json) =>
      _$ChatThreadFromJson(json);
}
