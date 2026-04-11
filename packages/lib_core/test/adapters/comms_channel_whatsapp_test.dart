// =============================================================================
// CommsChannelWhatsApp tests — PRD I6.5 AC #3 (wa.me deep link fallback).
//
// Coverage:
//   - openConversation reads Shop + Project, returns ExternalConversationHandle
//     with a correct wa.me URL and Hindi prefilled body
//   - Hindi body contains no forbidden vocabulary
//   - sendText / sendVoiceNote / observeMessages all throw
//     CommsChannelErrorCode.notSupported
//   - Missing Shop or Project returns notFound
//   - Shop without whatsappNumber returns sendFailed
//   - Phone digits are stripped to digits-only
// =============================================================================

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_core/src/adapters/comms_channel.dart';
import 'package:lib_core/src/adapters/comms_channel_whatsapp.dart';
import 'package:lib_core/src/models/message.dart';

void main() {
  group('CommsChannelWhatsApp', () {
    late FakeFirebaseFirestore firestore;
    late CommsChannelWhatsApp adapter;

    const shopId = 'sunil-trading-company';
    const projectId = 'proj_abc123';

    setUp(() {
      firestore = FakeFirebaseFirestore();
      adapter = CommsChannelWhatsApp(firestore: firestore);
    });

    Future<void> seedShop({
      String whatsappNumber = '+91 98765 43210',
      String displayName = 'सुनील ट्रेडिंग कंपनी',
    }) async {
      await firestore.doc('shops/$shopId').set(<String, dynamic>{
        'shopId': shopId,
        'displayName': displayName,
        'displayNameEnglish': 'Sunil Trading Company',
        'whatsappNumber': whatsappNumber,
        'shopLifecycle': 'active',
      });
    }

    Future<void> seedProject({
      int totalAmount = 22000,
      int lineItemsCount = 2,
    }) async {
      await firestore.doc('shops/$shopId/projects/$projectId').set(
        <String, dynamic>{
          'projectId': projectId,
          'shopId': shopId,
          'totalAmount': totalAmount,
          'lineItemsCount': lineItemsCount,
          'state': 'draft',
        },
      );
    }

    // -------------------------------------------------------------------------
    // openConversation — the happy path
    // -------------------------------------------------------------------------

    group('openConversation', () {
      test('returns ExternalConversationHandle with wa.me URL', () async {
        await seedShop();
        await seedProject();

        final handle = await adapter.openConversation(
          shopId: shopId,
          projectId: projectId,
        );

        expect(handle, isA<ExternalConversationHandle>());
        final ext = handle as ExternalConversationHandle;

        expect(ext.launchUri.host, equals('wa.me'));
        expect(ext.launchUri.scheme, equals('https'));
        expect(
          ext.launchUri.path,
          equals('/919876543210'),
          reason: 'phone should be digits-only, +91 and spaces stripped',
        );
        expect(ext.launchUri.queryParameters['text'], isNotNull);
        expect(ext.prefilledMessageHindi, contains('सुनील ट्रेडिंग कंपनी'));
      });

      test('Hindi body contains domain-grounded warmth words only', () async {
        await seedShop();
        await seedProject();

        final handle = await adapter.openConversation(
          shopId: shopId,
          projectId: projectId,
        ) as ExternalConversationHandle;

        final body = handle.prefilledMessageHindi;

        // Required warmth / domain vocabulary
        expect(body, contains('नमस्ते'));
        expect(body, contains('कृपया'));
        expect(body, contains('ऑर्डर'));
        expect(body, contains('कुल'));
        expect(body, contains('सामान'));

        // Forbidden mythic vocabulary (Constraint 10) — must NOT appear
        const forbidden = <String>[
          'शुभ',
          'मंगल',
          'मंदिर',
          'धर्म',
          'तीर्थ',
          'आशीर्वाद',
          'पूज्य',
          'स्वागतम्',
          'उत्पाद',
          'गुणवत्ता',
          'श्रेष्ठ',
        ];
        for (final word in forbidden) {
          expect(
            body,
            isNot(contains(word)),
            reason: 'forbidden mythic vocabulary "$word" must not appear '
                'in prefilled wa.me body (Constraint 10)',
          );
        }

        // Forbidden udhaar vocabulary (ADR-010) — must NOT appear
        const forbiddenUdhaar = <String>[
          'ब्याज',
          'पेनल्टी',
          'ऋण',
          'वसूली',
          'डिफ़ॉल्ट',
          'जुर्माना',
        ];
        for (final word in forbiddenUdhaar) {
          expect(
            body,
            isNot(contains(word)),
            reason: 'forbidden udhaar vocabulary "$word" must not appear '
                '(ADR-010)',
          );
        }
      });

      test('formats INR totalAmount with Indian lakh/thousand separators',
          () async {
        await seedShop();
        await seedProject(totalAmount: 150000, lineItemsCount: 3);

        final handle = await adapter.openConversation(
          shopId: shopId,
          projectId: projectId,
        ) as ExternalConversationHandle;

        expect(
          handle.prefilledMessageHindi,
          contains('₹1,50,000'),
          reason: 'Indian number format: 150000 → 1,50,000 not 150,000',
        );
      });

      test('long projectId is truncated to last 6 chars in body', () async {
        const longProjectId = 'proj_01HXYZ_ABCDEF_123456';
        await seedShop();
        await firestore.doc('shops/$shopId/projects/$longProjectId').set(
          <String, dynamic>{
            'projectId': longProjectId,
            'shopId': shopId,
            'totalAmount': 10000,
            'lineItemsCount': 1,
            'state': 'draft',
          },
        );

        final handle = await adapter.openConversation(
          shopId: shopId,
          projectId: longProjectId,
        ) as ExternalConversationHandle;

        expect(
          handle.prefilledMessageHindi,
          contains('ऑर्डर: 123456'),
          reason: 'projectId longer than 6 chars should show only last 6',
        );
      });
    });

    // -------------------------------------------------------------------------
    // Error conditions
    // -------------------------------------------------------------------------

    group('openConversation error conditions', () {
      test('throws notFound when shop does not exist', () async {
        await expectLater(
          adapter.openConversation(
            shopId: 'nonexistent-shop',
            projectId: projectId,
          ),
          throwsA(
            isA<CommsChannelException>().having(
              (e) => e.code,
              'code',
              CommsChannelErrorCode.notFound,
            ),
          ),
        );
      });

      test('throws notFound when project does not exist', () async {
        await seedShop();
        // No project seeded.

        await expectLater(
          adapter.openConversation(
            shopId: shopId,
            projectId: 'ghost-project',
          ),
          throwsA(
            isA<CommsChannelException>().having(
              (e) => e.code,
              'code',
              CommsChannelErrorCode.notFound,
            ),
          ),
        );
      });

      test('throws sendFailed when shop has no whatsappNumber', () async {
        await seedShop(whatsappNumber: '');
        await seedProject();

        await expectLater(
          adapter.openConversation(
            shopId: shopId,
            projectId: projectId,
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
    });

    // -------------------------------------------------------------------------
    // notSupported — send/observe methods
    // -------------------------------------------------------------------------

    group('unsupported operations throw notSupported', () {
      test('sendText throws notSupported', () async {
        await expectLater(
          adapter.sendText(
            shopId: shopId,
            projectId: projectId,
            authorUid: 'uid',
            authorRole: MessageAuthorRole.customer,
            text: 'hello',
          ),
          throwsA(
            isA<CommsChannelException>().having(
              (e) => e.code,
              'code',
              CommsChannelErrorCode.notSupported,
            ),
          ),
        );
      });

      test('sendVoiceNote throws notSupported', () async {
        await expectLater(
          adapter.sendVoiceNote(
            shopId: shopId,
            projectId: projectId,
            authorUid: 'uid',
            authorRole: MessageAuthorRole.bhaiya,
            voiceNoteId: 'vn_01',
            durationSeconds: 10,
          ),
          throwsA(
            isA<CommsChannelException>().having(
              (e) => e.code,
              'code',
              CommsChannelErrorCode.notSupported,
            ),
          ),
        );
      });

      test('observeMessages emits notSupported error on first listen', () async {
        final stream = adapter.observeMessages(
          shopId: shopId,
          projectId: projectId,
        );

        await expectLater(
          stream,
          emitsError(
            isA<CommsChannelException>().having(
              (e) => e.code,
              'code',
              CommsChannelErrorCode.notSupported,
            ),
          ),
        );
      });
    });
  });
}
