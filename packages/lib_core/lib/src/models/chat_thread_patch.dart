// =============================================================================
// ChatThread patches — partition discipline for ChatThread writes.
//
// Per PRD Standing Rule 11 and SAD §9, same shape as Project patches:
//   - Participant (customer) patches: unreadCountForCustomer only
//   - Owner (operator) patches: unreadCountForShopkeeper + participant mgmt
//   - System patches: lastMessageAt, lastMessagePreview (Cloud Function only)
//
// See `project_patch.dart` for the design rationale on why these are three
// separate classes, not one sealed union.
// =============================================================================

import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_thread_patch.freezed.dart';

@freezed
class ChatThreadParticipantPatch with _$ChatThreadParticipantPatch {
  const factory ChatThreadParticipantPatch({
    int? unreadCountForCustomer,
  }) = _ChatThreadParticipantPatch;

  const ChatThreadParticipantPatch._();

  Map<String, Object?> toFirestoreMap() {
    final out = <String, Object?>{};
    if (unreadCountForCustomer != null) {
      out['unreadCountForCustomer'] = unreadCountForCustomer;
    }
    return out;
  }
}

@freezed
class ChatThreadOperatorPatch with _$ChatThreadOperatorPatch {
  const factory ChatThreadOperatorPatch({
    int? unreadCountForShopkeeper,
    List<String>? participantUids,
  }) = _ChatThreadOperatorPatch;

  const ChatThreadOperatorPatch._();

  Map<String, Object?> toFirestoreMap() {
    final out = <String, Object?>{};
    if (unreadCountForShopkeeper != null) {
      out['unreadCountForShopkeeper'] = unreadCountForShopkeeper;
    }
    if (participantUids != null) out['participantUids'] = participantUids;
    return out;
  }
}

@freezed
class ChatThreadSystemPatch with _$ChatThreadSystemPatch {
  const factory ChatThreadSystemPatch({
    DateTime? lastMessageAt,
    String? lastMessagePreview,
  }) = _ChatThreadSystemPatch;

  const ChatThreadSystemPatch._();

  Map<String, Object?> toFirestoreMap() {
    final out = <String, Object?>{};
    if (lastMessageAt != null) out['lastMessageAt'] = lastMessageAt;
    if (lastMessagePreview != null) {
      out['lastMessagePreview'] = lastMessagePreview;
    }
    return out;
  }
}
