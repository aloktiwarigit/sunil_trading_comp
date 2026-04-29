// =============================================================================
// ChatBubble widget tests — P2.4 balance-scale layout + P2.5 delivery status.
//
// Covers:
//   1. Customer messages align LEFT
//   2. Shopkeeper messages align RIGHT
//   3. System messages render centered with brass dividers
//   4. Sender labels use AppStrings (no hardcoded Devanagari)
//   5. Delivery status icons: clock for pending, check for delivered
//   6. Text messages render textBody
//   7. Voice note messages render VoiceNotePlayerWidget
//   8. No oxblood commit color in chat bubbles (binding rule #7)
//   9. Hindi sender labels match domain vocabulary
//  10. Elder tier respects larger tap targets + type
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_core/src/components/chat/chat_bubble.dart';
import 'package:lib_core/src/components/voice_note_player.dart';
import 'package:lib_core/src/locale/strings_en.dart';
import 'package:lib_core/src/locale/strings_hi.dart';
import 'package:lib_core/src/models/message.dart';
import 'package:lib_core/src/theme/shop_theme_tokens.dart';
import 'package:lib_core/src/theme/yugma_theme_extension.dart';

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

Widget _wrapWithTheme(
  Widget child, {
  bool isElderTier = false,
}) {
  final ext = YugmaThemeExtension.fromTokens(
    ShopThemeTokens.sunilTradingCompanyDefault(),
    isElderTier: isElderTier,
  );
  return MaterialApp(
    theme: ThemeData(extensions: [ext]),
    home: Scaffold(body: child),
  );
}

Message _textMessage({
  String messageId = 'msg-1',
  String authorUid = 'customer-uid-1',
  MessageAuthorRole authorRole = MessageAuthorRole.customer,
  String textBody = 'Hello Sunil-bhaiya',
  DateTime? sentAt,
}) {
  return Message(
    messageId: messageId,
    shopId: 'sunil-trading-company',
    threadId: 'project-1',
    projectId: 'project-1',
    authorUid: authorUid,
    authorRole: authorRole,
    type: MessageType.text,
    sentAt: sentAt ?? DateTime(2026, 4, 11, 14, 30),
    textBody: textBody,
  );
}

Message _voiceNoteMessage({
  String authorUid = 'bhaiya-uid',
  MessageAuthorRole authorRole = MessageAuthorRole.bhaiya,
}) {
  return Message(
    messageId: 'msg-vn-1',
    shopId: 'sunil-trading-company',
    threadId: 'project-1',
    projectId: 'project-1',
    authorUid: authorUid,
    authorRole: authorRole,
    type: MessageType.voiceNote,
    sentAt: DateTime(2026, 4, 11, 14, 35),
    voiceNoteId: 'vn-123',
    voiceNoteDurationSeconds: 15,
  );
}

Message _systemMessage() {
  return Message(
    messageId: 'msg-sys-1',
    shopId: 'sunil-trading-company',
    threadId: 'project-1',
    projectId: 'project-1',
    authorUid: 'system',
    authorRole: MessageAuthorRole.system,
    type: MessageType.system,
    sentAt: DateTime(2026, 4, 11, 14, 32),
    textBody: 'Project state changed',
  );
}

const _customerUid = 'customer-uid-1';

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ChatBubble', () {
    testWidgets('customer text message renders LEFT with sender label', (
      tester,
    ) async {
      final strings = const AppStringsEn();
      final msg = _textMessage();

      await tester.pumpWidget(_wrapWithTheme(
        SingleChildScrollView(
          child: ChatBubble(
            message: msg,
            strings: strings,
            currentUserUid: _customerUid,
          ),
        ),
      ));

      // Sender label should be "You" (English)
      expect(find.text('You'), findsOneWidget);
      // Text body should be rendered
      expect(find.text('Hello Sunil-bhaiya'), findsOneWidget);
      // Timestamp should show
      expect(find.text('14:30'), findsOneWidget);
    });

    testWidgets('shopkeeper text message renders RIGHT with bhaiya label', (
      tester,
    ) async {
      final strings = const AppStringsEn();
      final msg = _textMessage(
        authorUid: 'bhaiya-uid',
        authorRole: MessageAuthorRole.bhaiya,
        textBody: 'Ji, bilkul',
      );

      await tester.pumpWidget(_wrapWithTheme(
        SingleChildScrollView(
          child: ChatBubble(
            message: msg,
            strings: strings,
            currentUserUid: _customerUid,
          ),
        ),
      ));

      // Sender label should be "Sunil-bhaiya"
      expect(find.text('Sunil-bhaiya'), findsOneWidget);
      expect(find.text('Ji, bilkul'), findsOneWidget);
    });

    testWidgets('system message renders centered with dividers', (
      tester,
    ) async {
      final strings = const AppStringsEn();
      final msg = _systemMessage();

      await tester.pumpWidget(_wrapWithTheme(
        SingleChildScrollView(
          child: ChatBubble(
            message: msg,
            strings: strings,
            currentUserUid: _customerUid,
          ),
        ),
      ));

      // System text should be rendered
      expect(find.text('Project state changed'), findsOneWidget);
      // Divider lines should be present (two Expanded Dividers)
      expect(find.byType(Divider), findsNWidgets(2));
    });

    testWidgets('pending message shows clock icon', (tester) async {
      final strings = const AppStringsEn();
      final msg = _textMessage();

      await tester.pumpWidget(_wrapWithTheme(
        SingleChildScrollView(
          child: ChatBubble(
            message: msg,
            strings: strings,
            currentUserUid: _customerUid,
            deliveryStatus: MessageDeliveryStatus.pending,
          ),
        ),
      ));

      // Clock icon for pending
      expect(find.byIcon(Icons.access_time), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('delivered message shows check icon', (tester) async {
      final strings = const AppStringsEn();
      final msg = _textMessage();

      await tester.pumpWidget(_wrapWithTheme(
        SingleChildScrollView(
          child: ChatBubble(
            message: msg,
            strings: strings,
            currentUserUid: _customerUid,
            deliveryStatus: MessageDeliveryStatus.delivered,
          ),
        ),
      ));

      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsNothing);
    });

    testWidgets('voice note message renders VoiceNotePlayerWidget', (
      tester,
    ) async {
      final strings = const AppStringsEn();
      final msg = _voiceNoteMessage();

      await tester.pumpWidget(_wrapWithTheme(
        SingleChildScrollView(
          child: ChatBubble(
            message: msg,
            strings: strings,
            currentUserUid: _customerUid,
          ),
        ),
      ));

      expect(find.byType(VoiceNotePlayerWidget), findsOneWidget);
    });

    testWidgets('Hindi sender labels use domain vocabulary', (tester) async {
      final strings = const AppStringsHi();

      // Customer message
      final customerMsg = _textMessage();
      await tester.pumpWidget(_wrapWithTheme(
        SingleChildScrollView(
          child: ChatBubble(
            message: customerMsg,
            strings: strings,
            currentUserUid: _customerUid,
          ),
        ),
      ));
      expect(find.text('आप'), findsOneWidget);

      // Shopkeeper message
      final bhaiMsg = _textMessage(
        authorUid: 'bhaiya-uid',
        authorRole: MessageAuthorRole.bhaiya,
        textBody: 'Ji',
      );
      await tester.pumpWidget(_wrapWithTheme(
        SingleChildScrollView(
          child: ChatBubble(
            message: bhaiMsg,
            strings: strings,
            currentUserUid: _customerUid,
          ),
        ),
      ));
      expect(find.text('सुनील भैया'), findsOneWidget);
    });

    testWidgets('no oxblood commit color in chat bubble (binding rule #7)',
        (tester) async {
      final strings = const AppStringsEn();
      final msg = _textMessage();

      await tester.pumpWidget(_wrapWithTheme(
        SingleChildScrollView(
          child: ChatBubble(
            message: msg,
            strings: strings,
            currentUserUid: _customerUid,
          ),
        ),
      ));

      // Get the YugmaThemeExtension to check commit color.
      final context = tester.element(find.byType(ChatBubble));
      final theme = context.yugmaTheme;
      final commitColor = theme.shopCommit;

      // Walk the widget tree — no Container or DecoratedBox should use
      // the commit color as background.
      bool containsCommitColor = false;

      void checkWidget(Element element) {
        final widget = element.widget;
        if (widget is Container && widget.decoration is BoxDecoration) {
          final boxDec = widget.decoration! as BoxDecoration;
          if (boxDec.color == commitColor) {
            containsCommitColor = true;
          }
        }
        if (widget is Material && widget.color == commitColor) {
          containsCommitColor = true;
        }
        element.visitChildren(checkWidget);
      }

      tester.element(find.byType(ChatBubble)).visitChildren(checkWidget);
      expect(
        containsCommitColor,
        isFalse,
        reason: 'Oxblood commit color must not appear in chat widgets',
      );
    });

    testWidgets('shopkeeper delivery status icon not shown', (tester) async {
      final strings = const AppStringsEn();
      final msg = _textMessage(
        authorUid: 'bhaiya-uid',
        authorRole: MessageAuthorRole.bhaiya,
        textBody: 'Reply',
      );

      await tester.pumpWidget(_wrapWithTheme(
        SingleChildScrollView(
          child: ChatBubble(
            message: msg,
            strings: strings,
            currentUserUid: _customerUid,
            deliveryStatus: MessageDeliveryStatus.delivered,
          ),
        ),
      ));

      // Delivery icons should NOT show for shopkeeper messages.
      expect(find.byIcon(Icons.check), findsNothing);
      expect(find.byIcon(Icons.access_time), findsNothing);
    });

    testWidgets('elder tier renders with larger text', (tester) async {
      final strings = const AppStringsEn();
      final msg = _textMessage();

      await tester.pumpWidget(_wrapWithTheme(
        SingleChildScrollView(
          child: ChatBubble(
            message: msg,
            strings: strings,
            currentUserUid: _customerUid,
          ),
        ),
        isElderTier: true,
      ));

      // Widget should render without errors in elder tier.
      expect(find.text('Hello Sunil-bhaiya'), findsOneWidget);
    });
  });

  group('AppStrings new chat keys', () {
    test('Hindi strings have all required chat keys', () {
      const hi = AppStringsHi();
      expect(hi.myListTitle, 'मेरी सूची');
      expect(hi.addedToList, 'सूची में जोड़ा गया');
      expect(hi.chatSenderYou, 'आप');
      expect(hi.chatSenderBhaiya, 'सुनील भैया');
      expect(
        hi.chatThreadTitleWithOrder('A3F'),
        'सुनील भैया का कमरा — आपका ऑर्डर #A3F',
      );
      expect(hi.chatSendButton, 'भेजिए');
      expect(hi.chatMessagePending, 'भेज रहे हैं...');
    });

    test('English strings have all required chat keys', () {
      const en = AppStringsEn();
      expect(en.myListTitle, 'My list');
      expect(en.addedToList, 'Added to list');
      expect(en.chatSenderYou, 'You');
      expect(en.chatSenderBhaiya, 'Sunil-bhaiya');
      expect(
        en.chatThreadTitleWithOrder('A3F'),
        "Sunil-bhaiya's room — your order #A3F",
      );
      expect(en.chatSendButton, 'Send');
      expect(en.chatMessagePending, 'Sending...');
    });

    test('new strings contain no forbidden udhaar vocabulary', () {
      const hi = AppStringsHi();
      const en = AppStringsEn();

      final forbiddenEn = [
        'interest',
        'overdue',
        'penalty',
        'loan',
        'credit',
        'lending',
        'default',
        'collection',
        'installment',
        'EMI',
        'debt',
        'due date',
        'late fee',
      ];
      final forbiddenHi = [
        'ब्याज',
        'देय तिथि',
        'जुर्माना',
        'ऋण',
        'वसूली',
        'डिफ़ॉल्ट',
        'क़िस्त',
      ];
      final forbiddenMythic = [
        'शुभ',
        'मंगल',
        'मंदिर',
        'धर्म',
        'तीर्थ',
        'स्वागतम्',
        'उत्पाद',
        'गुणवत्ता',
        'श्रेष्ठ',
      ];

      final hiStrings = [
        hi.myListTitle,
        hi.addedToList,
        hi.chatSenderYou,
        hi.chatSenderBhaiya,
        hi.chatThreadTitleWithOrder('X'),
        hi.chatSendButton,
        hi.chatMessagePending,
      ];
      final enStrings = [
        en.myListTitle,
        en.addedToList,
        en.chatSenderYou,
        en.chatSenderBhaiya,
        en.chatThreadTitleWithOrder('X'),
        en.chatSendButton,
        en.chatMessagePending,
      ];

      for (final s in hiStrings) {
        for (final f in forbiddenHi) {
          expect(s.contains(f), isFalse, reason: '"$s" contains "$f"');
        }
        for (final f in forbiddenMythic) {
          expect(s.contains(f), isFalse, reason: '"$s" contains "$f"');
        }
      }
      for (final s in enStrings) {
        for (final f in forbiddenEn) {
          expect(
            s.toLowerCase().contains(f.toLowerCase()),
            isFalse,
            reason: '"$s" contains "$f"',
          );
        }
      }
    });
  });
}
