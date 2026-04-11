// =============================================================================
// CommsChannelFirestore tests — PRD I6.5 AC #5 + #6.
//
// Uses fake_cloud_firestore for in-memory Firestore. Covers:
//   - openConversation returns FirestoreConversationHandle
//   - sendText writes to the canonical sub-sub-collection path
//   - sendVoiceNote writes voice_note type + duration
//   - observeMessages emits on new writes, ordered by sentAt
//   - kill-switch short-circuits send paths
//   - Validation: empty / path-traversal shopId/projectId/authorUid
//   - Duration validation [5, 60] per PRD B1.6 AC #2
//   - Shop-scoped path contract per Standing Rule 7
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_core/src/adapters/comms_channel.dart';
import 'package:lib_core/src/adapters/comms_channel_firestore.dart';
import 'package:lib_core/src/models/message.dart';

void main() {
  group('CommsChannelFirestore', () {
    late FakeFirebaseFirestore firestore;
    late CommsChannelFirestore adapter;

    const shopId = 'sunil-trading-company';
    const projectId = 'proj_abc123';
    const customerUid = 'uid_anon_sunita';
    const bhaiyaUid = 'uid_google_sunil';

    setUp(() {
      firestore = FakeFirebaseFirestore();
      adapter = CommsChannelFirestore(firestore: firestore);
    });

    // -------------------------------------------------------------------------
    // openConversation
    // -------------------------------------------------------------------------

    group('openConversation', () {
      test('returns FirestoreConversationHandle with shopId + projectId', () async {
        final handle = await adapter.openConversation(
          shopId: shopId,
          projectId: projectId,
        );

        expect(handle, isA<FirestoreConversationHandle>());
        expect(handle.shopId, equals(shopId));
        expect(handle.projectId, equals(projectId));
        expect(
          (handle as FirestoreConversationHandle).threadId,
          equals(projectId),
          reason: 'threadId is 1:1 with projectId per SAD §5',
        );
      });

      test('rejects empty shopId', () async {
        await expectLater(
          adapter.openConversation(shopId: '', projectId: projectId),
          throwsA(
            isA<CommsChannelException>().having(
              (e) => e.code,
              'code',
              CommsChannelErrorCode.unauthorized,
            ),
          ),
        );
      });

      test('rejects shopId with path traversal', () async {
        await expectLater(
          adapter.openConversation(shopId: '../evil', projectId: projectId),
          throwsA(
            isA<CommsChannelException>().having(
              (e) => e.code,
              'code',
              CommsChannelErrorCode.unauthorized,
            ),
          ),
        );
      });
    });

    // -------------------------------------------------------------------------
    // sendText
    // -------------------------------------------------------------------------

    group('sendText', () {
      test('writes message to canonical shop-scoped sub-sub-collection path',
          () async {
        await adapter.sendText(
          shopId: shopId,
          projectId: projectId,
          authorUid: customerUid,
          authorRole: MessageAuthorRole.customer,
          text: 'Bhaiya, polish kab tak ho jayega?',
        );

        final snapshot = await firestore
            .collection('shops')
            .doc(shopId)
            .collection('chatThreads')
            .doc(projectId)
            .collection('messages')
            .get();

        expect(snapshot.docs, hasLength(1));
        final doc = snapshot.docs.first.data();
        expect(doc['shopId'], equals(shopId));
        expect(doc['projectId'], equals(projectId));
        expect(doc['threadId'], equals(projectId));
        expect(doc['authorUid'], equals(customerUid));
        expect(doc['authorRole'], equals('customer'));
        expect(doc['type'], equals('text'));
        expect(doc['textBody'], equals('Bhaiya, polish kab tak ho jayega?'));
        expect(doc['readByUids'], contains(customerUid));
      });

      test('operator sending uses domain-grounded role name', () async {
        await adapter.sendText(
          shopId: shopId,
          projectId: projectId,
          authorUid: bhaiyaUid,
          authorRole: MessageAuthorRole.bhaiya,
          text: 'Didi, aaj shaam tak tayyar ho jayega',
        );

        final doc = (await firestore
                .collection('shops')
                .doc(shopId)
                .collection('chatThreads')
                .doc(projectId)
                .collection('messages')
                .get())
            .docs
            .first
            .data();

        expect(doc['authorRole'], equals('bhaiya'));
      });

      test('rejects empty text', () async {
        await expectLater(
          adapter.sendText(
            shopId: shopId,
            projectId: projectId,
            authorUid: customerUid,
            authorRole: MessageAuthorRole.customer,
            text: '',
          ),
          throwsA(
            isA<CommsChannelException>().having(
              (e) => e.code,
              'code',
              CommsChannelErrorCode.sendFailed,
            ),
          ),
        );
      });

      test('kill-switch active short-circuits before any write', () async {
        final killedAdapter = CommsChannelFirestore(
          firestore: firestore,
          isWriteKillSwitchActive: () async => true,
        );

        await expectLater(
          killedAdapter.sendText(
            shopId: shopId,
            projectId: projectId,
            authorUid: customerUid,
            authorRole: MessageAuthorRole.customer,
            text: 'hello',
          ),
          throwsA(
            isA<CommsChannelException>().having(
              (e) => e.code,
              'code',
              CommsChannelErrorCode.killSwitchActive,
            ),
          ),
        );

        // Assert NO write happened.
        final messages = await firestore
            .collection('shops')
            .doc(shopId)
            .collection('chatThreads')
            .doc(projectId)
            .collection('messages')
            .get();
        expect(messages.docs, isEmpty);
      });

      test('rejects empty authorUid', () async {
        await expectLater(
          adapter.sendText(
            shopId: shopId,
            projectId: projectId,
            authorUid: '',
            authorRole: MessageAuthorRole.customer,
            text: 'hello',
          ),
          throwsA(
            isA<CommsChannelException>().having(
              (e) => e.code,
              'code',
              CommsChannelErrorCode.unauthorized,
            ),
          ),
        );
      });
    });

    // -------------------------------------------------------------------------
    // sendVoiceNote
    // -------------------------------------------------------------------------

    group('sendVoiceNote', () {
      test('writes voice_note type with duration', () async {
        await adapter.sendVoiceNote(
          shopId: shopId,
          projectId: projectId,
          authorUid: bhaiyaUid,
          authorRole: MessageAuthorRole.bhaiya,
          voiceNoteId: 'vn_01HXYZ',
          durationSeconds: 23,
        );

        final doc = (await firestore
                .collection('shops')
                .doc(shopId)
                .collection('chatThreads')
                .doc(projectId)
                .collection('messages')
                .get())
            .docs
            .first
            .data();

        expect(doc['type'], equals('voice_note'));
        expect(doc['voiceNoteId'], equals('vn_01HXYZ'));
        expect(doc['voiceNoteDurationSeconds'], equals(23));
        expect(doc['authorRole'], equals('bhaiya'));
      });

      test('rejects duration below 5 seconds (PRD B1.6 AC #2)', () async {
        await expectLater(
          adapter.sendVoiceNote(
            shopId: shopId,
            projectId: projectId,
            authorUid: bhaiyaUid,
            authorRole: MessageAuthorRole.bhaiya,
            voiceNoteId: 'vn_01',
            durationSeconds: 3,
          ),
          throwsA(
            isA<CommsChannelException>().having(
              (e) => e.code,
              'code',
              CommsChannelErrorCode.sendFailed,
            ),
          ),
        );
      });

      test('rejects duration above 60 seconds (PRD B1.6 AC #2)', () async {
        await expectLater(
          adapter.sendVoiceNote(
            shopId: shopId,
            projectId: projectId,
            authorUid: bhaiyaUid,
            authorRole: MessageAuthorRole.bhaiya,
            voiceNoteId: 'vn_01',
            durationSeconds: 61,
          ),
          throwsA(
            isA<CommsChannelException>().having(
              (e) => e.code,
              'code',
              CommsChannelErrorCode.sendFailed,
            ),
          ),
        );
      });

      test('accepts boundary durations 5 and 60', () async {
        await adapter.sendVoiceNote(
          shopId: shopId,
          projectId: projectId,
          authorUid: bhaiyaUid,
          authorRole: MessageAuthorRole.bhaiya,
          voiceNoteId: 'vn_min',
          durationSeconds: 5,
        );

        await adapter.sendVoiceNote(
          shopId: shopId,
          projectId: projectId,
          authorUid: bhaiyaUid,
          authorRole: MessageAuthorRole.bhaiya,
          voiceNoteId: 'vn_max',
          durationSeconds: 60,
        );

        final docs = (await firestore
                .collection('shops')
                .doc(shopId)
                .collection('chatThreads')
                .doc(projectId)
                .collection('messages')
                .get())
            .docs;

        expect(docs, hasLength(2));
      });

      test('rejects empty voiceNoteId', () async {
        await expectLater(
          adapter.sendVoiceNote(
            shopId: shopId,
            projectId: projectId,
            authorUid: bhaiyaUid,
            authorRole: MessageAuthorRole.bhaiya,
            voiceNoteId: '',
            durationSeconds: 10,
          ),
          throwsA(
            isA<CommsChannelException>().having(
              (e) => e.code,
              'code',
              CommsChannelErrorCode.sendFailed,
            ),
          ),
        );
      });
    });

    // -------------------------------------------------------------------------
    // observeMessages
    // -------------------------------------------------------------------------

    group('observeMessages', () {
      test('emits messages ordered by sentAt', () async {
        // Seed 3 messages with controlled timestamps. Use direct Firestore
        // writes so we can set sentAt to specific values (the adapter uses
        // serverTimestamp which fake_cloud_firestore resolves immediately).
        final col = firestore
            .collection('shops')
            .doc(shopId)
            .collection('chatThreads')
            .doc(projectId)
            .collection('messages');

        await col.doc('m1').set(<String, dynamic>{
          'messageId': 'm1',
          'shopId': shopId,
          'threadId': projectId,
          'projectId': projectId,
          'authorUid': customerUid,
          'authorRole': 'customer',
          'type': 'text',
          'textBody': 'first',
          'sentAt': Timestamp.fromDate(DateTime.parse('2026-04-11T10:00:00Z')),
          'readByUids': <String>[customerUid],
        });

        await col.doc('m2').set(<String, dynamic>{
          'messageId': 'm2',
          'shopId': shopId,
          'threadId': projectId,
          'projectId': projectId,
          'authorUid': bhaiyaUid,
          'authorRole': 'bhaiya',
          'type': 'text',
          'textBody': 'second',
          'sentAt': Timestamp.fromDate(DateTime.parse('2026-04-11T10:01:00Z')),
          'readByUids': <String>[bhaiyaUid],
        });

        final stream = adapter.observeMessages(
          shopId: shopId,
          projectId: projectId,
        );

        final messages = await stream.first;

        expect(messages, hasLength(2));
        expect(messages[0].textBody, equals('first'));
        expect(messages[1].textBody, equals('second'));
        expect(messages[0].authorRole, equals(MessageAuthorRole.customer));
        expect(messages[1].authorRole, equals(MessageAuthorRole.bhaiya));
      });

      test('emits empty list for a thread with no messages', () async {
        final stream = adapter.observeMessages(
          shopId: shopId,
          projectId: projectId,
        );
        final messages = await stream.first;
        expect(messages, isEmpty);
      });
    });
  });
}
