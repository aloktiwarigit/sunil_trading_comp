// =============================================================================
// Message model tests — JSON round-trip + domain enum serialization.
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:lib_core/src/models/message.dart';

void main() {
  group('Message', () {
    test('text message round-trips through JSON', () {
      final original = Message(
        messageId: 'msg_01',
        shopId: 'sunil-trading-company',
        threadId: 'proj_abc',
        projectId: 'proj_abc',
        authorUid: 'uid_anon_123',
        authorRole: MessageAuthorRole.customer,
        type: MessageType.text,
        textBody: 'Bhaiya, polish kab tak ho jayega?',
        sentAt: DateTime.parse('2026-04-11T10:30:00Z'),
        readByUids: const <String>['uid_anon_123'],
      );

      final json = original.toJson();
      final restored = Message.fromJson(json);

      expect(restored.messageId, equals(original.messageId));
      expect(restored.authorRole, equals(MessageAuthorRole.customer));
      expect(restored.type, equals(MessageType.text));
      expect(restored.textBody, equals(original.textBody));
      expect(restored.hasText, isTrue);
      expect(restored.hasVoiceNote, isFalse);
    });

    test('voice note message round-trips with duration', () {
      final original = Message(
        messageId: 'msg_02',
        shopId: 'sunil-trading-company',
        threadId: 'proj_abc',
        projectId: 'proj_abc',
        authorUid: 'uid_bhaiya_google',
        authorRole: MessageAuthorRole.bhaiya,
        type: MessageType.voiceNote,
        voiceNoteId: 'vn_01HXYZ',
        voiceNoteDurationSeconds: 23,
        sentAt: DateTime.parse('2026-04-11T10:31:00Z'),
      );

      final json = original.toJson();
      final restored = Message.fromJson(json);

      expect(restored.authorRole, equals(MessageAuthorRole.bhaiya));
      expect(restored.type, equals(MessageType.voiceNote));
      expect(restored.voiceNoteId, equals('vn_01HXYZ'));
      expect(restored.voiceNoteDurationSeconds, equals(23));
      expect(restored.hasVoiceNote, isTrue);
      expect(restored.hasText, isFalse);
    });

    test('all domain operator roles serialize with domain-grounded names', () {
      // These JsonValue names must match the deployed Firestore rule
      // helpers (isShopOperator checks callerRole() against 'shopkeeper',
      // 'son', 'munshi') AND the ops app UI labels. If these drift, the
      // rule check / UI render will break.
      const roleJsonMap = <MessageAuthorRole, String>{
        MessageAuthorRole.customer: 'customer',
        MessageAuthorRole.bhaiya: 'bhaiya',
        MessageAuthorRole.beta: 'beta',
        MessageAuthorRole.munshi: 'munshi',
        MessageAuthorRole.system: 'system',
      };

      for (final entry in roleJsonMap.entries) {
        final msg = Message(
          messageId: 'm',
          shopId: 's',
          threadId: 't',
          projectId: 'p',
          authorUid: 'u',
          authorRole: entry.key,
          type: MessageType.system,
          textBody: 'test',
          sentAt: DateTime.parse('2026-04-11T00:00:00Z'),
        );
        final json = msg.toJson();
        expect(
          json['authorRole'],
          equals(entry.value),
          reason: 'Domain enum ${entry.key} must serialize as ${entry.value}',
        );
      }
    });

    test('message type voiceNote serializes as snake_case voice_note', () {
      final msg = Message(
        messageId: 'm',
        shopId: 's',
        threadId: 't',
        projectId: 'p',
        authorUid: 'u',
        authorRole: MessageAuthorRole.bhaiya,
        type: MessageType.voiceNote,
        voiceNoteId: 'vn_1',
        voiceNoteDurationSeconds: 10,
        sentAt: DateTime.parse('2026-04-11T00:00:00Z'),
      );

      final json = msg.toJson();
      expect(json['type'], equals('voice_note'));
    });

    test('system message is marked hasText but not hasVoiceNote', () {
      final msg = Message(
        messageId: 'm',
        shopId: 's',
        threadId: 't',
        projectId: 'p',
        authorUid: 'system',
        authorRole: MessageAuthorRole.system,
        type: MessageType.system,
        textBody: 'ऑर्डर पक्का हुआ',
        sentAt: DateTime.parse('2026-04-11T00:00:00Z'),
      );

      expect(msg.hasText, isTrue);
      expect(msg.hasVoiceNote, isFalse);
    });
  });
}
