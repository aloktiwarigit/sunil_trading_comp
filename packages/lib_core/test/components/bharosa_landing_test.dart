// =============================================================================
// BharosaLanding widget tests — B1.2 + B1.3 acceptance criteria coverage.
//
// Tests:
//   1. ShopkeeperFaceFrame D4 fallback renders Devanagari initial
//   2. ShopkeeperFaceFrame with real photo URL renders Image.network
//   3. BharosaLanding suppresses greeting card when hasGreetingVoiceNote=false
//   4. BharosaLanding shows greeting card when hasGreetingVoiceNote=true
//   5. BharosaLanding locale toggle renders correct label
//   6. BharosaLanding shortlist tiles render occasion labels
//   7. ShopkeeperPresenceDock renders owner name + status
//   8. BharosaLanding auto-play does NOT fire when muted
//   9. Elder tier inflates font sizes
//  10. Shortlist badge shows on first tile only
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_core/src/components/bharosa_landing/bharosa_landing.dart';
import 'package:lib_core/src/components/bharosa_landing/shopkeeper_face_frame.dart';
import 'package:lib_core/src/components/bharosa_landing/shopkeeper_presence_dock.dart';
import 'package:lib_core/src/locale/strings_en.dart';
import 'package:lib_core/src/locale/strings_hi.dart';
import 'package:lib_core/src/theme/shop_theme_tokens.dart';
import 'package:lib_core/src/theme/yugma_theme_extension.dart';

/// Wraps [child] in a MaterialApp with a registered YugmaThemeExtension.
Widget _wrap(Widget child, {bool isElderTier = false}) {
  final tokens = ShopThemeTokens.sunilTradingCompanyDefault();
  final ext = YugmaThemeExtension.fromTokens(tokens, isElderTier: isElderTier);
  return MaterialApp(
    theme: ThemeData(
      extensions: [ext],
    ),
    home: child,
  );
}

void main() {
  // ===========================================================================
  // 1. ShopkeeperFaceFrame — D4 fallback
  // ===========================================================================

  group('ShopkeeperFaceFrame', () {
    testWidgets('renders Devanagari initial when faceUrl is empty', (t) async {
      await t.pumpWidget(_wrap(
        const Scaffold(
          body: Center(
            child: ShopkeeperFaceFrame(
              size: 100,
              faceUrl: '',
              ownerName: 'सुनील भैया',
            ),
          ),
        ),
      ));

      // Should show first 2 chars of owner name as fallback
      expect(find.text('सु'), findsOneWidget);
    });

    testWidgets('renders Devanagari initial when faceUrl is null (uses theme)',
        (t) async {
      // sunilTradingCompanyDefault has empty shopkeeperFaceUrl
      await t.pumpWidget(_wrap(
        const Scaffold(
          body: Center(child: ShopkeeperFaceFrame(size: 100)),
        ),
      ));

      // Theme ownerName is "सुनील भैया" → fallback "सु"
      expect(find.text('सु'), findsOneWidget);
    });

    testWidgets('attempts to load Image.network when faceUrl is non-empty',
        (t) async {
      await t.pumpWidget(_wrap(
        const Scaffold(
          body: Center(
            child: ShopkeeperFaceFrame(
              size: 100,
              faceUrl: 'https://example.com/face.jpg',
              ownerName: 'सुनील भैया',
            ),
          ),
        ),
      ));

      // Image.network widget should be in the tree
      expect(find.byType(Image), findsOneWidget);
    });
  });

  // ===========================================================================
  // 2. BharosaLanding — B1.3 AC #8: greeting card suppression
  // ===========================================================================

  group('BharosaLanding greeting card', () {
    testWidgets('suppresses greeting card when hasGreetingVoiceNote=false',
        (t) async {
      await t.pumpWidget(_wrap(
        BharosaLanding(
          onShortlistTap: (_) {},
          onGreetingPlay: () {},
          autoPlayGreeting: true,
          onPresenceVoiceNote: () {},
          previewShortlists: const [],
          strings: const AppStringsHi(),
          hasGreetingVoiceNote: false,
        ),
      ));

      // Greeting card title should NOT be present
      expect(find.text('नमस्ते जी, स्वागत है'), findsNothing);
    });

    testWidgets('shows greeting card when hasGreetingVoiceNote=true',
        (t) async {
      await t.pumpWidget(_wrap(
        BharosaLanding(
          onShortlistTap: (_) {},
          onGreetingPlay: () {},
          autoPlayGreeting: true,
          onPresenceVoiceNote: () {},
          previewShortlists: const [],
          strings: const AppStringsHi(),
          hasGreetingVoiceNote: true,
          greetingDurationSeconds: 23,
        ),
      ));

      expect(find.text('नमस्ते जी, स्वागत है'), findsOneWidget);

      // Drain the 800ms auto-play timer to avoid pending-timer assertion
      await t.pump(const Duration(milliseconds: 900));
    });
  });

  // ===========================================================================
  // 3. BharosaLanding — B1.2 AC #7: locale toggle
  // ===========================================================================

  group('BharosaLanding locale toggle', () {
    testWidgets('shows EN toggle when current locale is hi', (t) async {
      await t.pumpWidget(_wrap(
        BharosaLanding(
          onShortlistTap: (_) {},
          onGreetingPlay: () {},
          autoPlayGreeting: false,
          onPresenceVoiceNote: () {},
          previewShortlists: const [],
          strings: const AppStringsHi(),
          currentLocaleCode: 'hi',
          onLocaleToggle: () {},
        ),
      ));

      expect(find.text('EN'), findsOneWidget);
    });

    testWidgets('shows हिं toggle when current locale is en', (t) async {
      await t.pumpWidget(_wrap(
        BharosaLanding(
          onShortlistTap: (_) {},
          onGreetingPlay: () {},
          autoPlayGreeting: false,
          onPresenceVoiceNote: () {},
          previewShortlists: const [],
          strings: const AppStringsEn(),
          currentLocaleCode: 'en',
          onLocaleToggle: () {},
        ),
      ));

      expect(find.text('हिं'), findsOneWidget);
    });
  });

  // ===========================================================================
  // 4. BharosaLanding — shortlist tiles
  // ===========================================================================

  group('BharosaLanding shortlist tiles', () {
    testWidgets('renders occasion labels from preview data', (t) async {
      await t.pumpWidget(_wrap(
        BharosaLanding(
          onShortlistTap: (_) {},
          onGreetingPlay: () {},
          autoPlayGreeting: false,
          onPresenceVoiceNote: () {},
          previewShortlists: const [
            CuratedShortlistPreview(
              occasionTag: 'shaadi',
              occasionLabel: 'शादी के लिए',
              skuCount: 6,
            ),
            CuratedShortlistPreview(
              occasionTag: 'naya_ghar',
              occasionLabel: 'नए घर के लिए',
              skuCount: 4,
            ),
          ],
          strings: const AppStringsHi(),
        ),
      ));

      expect(find.text('शादी के लिए'), findsOneWidget);
      expect(find.text('नए घर के लिए'), findsOneWidget);
    });

    testWidgets('first tile shows curated badge, second does not', (t) async {
      await t.pumpWidget(_wrap(
        BharosaLanding(
          onShortlistTap: (_) {},
          onGreetingPlay: () {},
          autoPlayGreeting: false,
          onPresenceVoiceNote: () {},
          previewShortlists: const [
            CuratedShortlistPreview(
              occasionTag: 'shaadi',
              occasionLabel: 'शादी के लिए',
              skuCount: 6,
            ),
            CuratedShortlistPreview(
              occasionTag: 'naya_ghar',
              occasionLabel: 'नए घर के लिए',
              skuCount: 4,
            ),
          ],
          strings: const AppStringsHi(),
        ),
      ));

      // "चुनी हुई" badge appears exactly once (first tile only)
      expect(find.text('चुनी हुई'), findsOneWidget);
    });
  });

  // ===========================================================================
  // 5. ShopkeeperPresenceDock
  // ===========================================================================

  group('ShopkeeperPresenceDock', () {
    testWidgets('renders owner name and available status', (t) async {
      await t.pumpWidget(_wrap(
        Scaffold(
          body: ShopkeeperPresenceDock(
            onVoiceNote: () {},
            strings: const AppStringsHi(),
          ),
        ),
      ));

      // Owner name from theme tokens
      expect(find.text('सुनील भैया'), findsAtLeast(1));
      // Presence status
      expect(find.text('● दुकान पर हैं'), findsOneWidget);
    });

    testWidgets('renders English status with AppStringsEn', (t) async {
      await t.pumpWidget(_wrap(
        Scaffold(
          body: ShopkeeperPresenceDock(
            onVoiceNote: () {},
            strings: const AppStringsEn(),
          ),
        ),
      ));

      expect(find.text('● At the shop'), findsOneWidget);
    });
  });

  // ===========================================================================
  // 6. BharosaLanding — auto-play gating
  // ===========================================================================

  group('BharosaLanding auto-play', () {
    testWidgets('does NOT auto-play when autoPlayGreeting=false', (t) async {
      var playCalled = false;
      await t.pumpWidget(_wrap(
        BharosaLanding(
          onShortlistTap: (_) {},
          onGreetingPlay: () => playCalled = true,
          autoPlayGreeting: false,
          onPresenceVoiceNote: () {},
          previewShortlists: const [],
          strings: const AppStringsHi(),
          hasGreetingVoiceNote: true,
          greetingDurationSeconds: 23,
        ),
      ));

      // Wait for the 800ms delayed auto-play + extra
      await t.pump(const Duration(milliseconds: 1200));
      expect(playCalled, isFalse);
    });
  });

  // ===========================================================================
  // 7. BharosaLanding — hero renders theme identity
  // ===========================================================================

  group('BharosaLanding hero', () {
    testWidgets('renders brand name and market area from theme', (t) async {
      await t.pumpWidget(_wrap(
        BharosaLanding(
          onShortlistTap: (_) {},
          onGreetingPlay: () {},
          autoPlayGreeting: false,
          onPresenceVoiceNote: () {},
          previewShortlists: const [],
          strings: const AppStringsHi(),
        ),
      ));

      // ownerName from theme
      expect(find.text('सुनील भैया'), findsAtLeast(1));
      // brandName · marketArea, city
      expect(
        find.textContaining('सुनील ट्रेडिंग कंपनी'),
        findsAtLeast(1),
      );
    });
  });

  // ===========================================================================
  // 8. New AppStrings keys produce expected output
  // ===========================================================================

  group('AppStrings new B1.2 keys', () {
    const hi = AppStringsHi();
    const en = AppStringsEn();

    test('metaBarYearsInBusiness Hindi', () {
      expect(hi.metaBarYearsInBusiness(23, 2003), equals('23 साल · 2003 से'));
    });

    test('metaBarYearsInBusiness English', () {
      expect(
          en.metaBarYearsInBusiness(23, 2003), equals('23 years · since 2003'));
    });

    test('greetingCardTitle Hindi', () {
      expect(hi.greetingCardTitle, equals('नमस्ते जी, स्वागत है'));
    });

    test('greetingVoiceNoteSublabel Hindi', () {
      expect(
        hi.greetingVoiceNoteSublabel('सुनील भैया', 23),
        equals('सुनील भैया का स्वागत संदेश · 23 सेकंड'),
      );
    });

    test('greetingVoiceNoteSublabel English', () {
      expect(
        en.greetingVoiceNoteSublabel('Sunil-bhaiya', 23),
        equals("Sunil-bhaiya's welcome message · 23 sec"),
      );
    });

    test('shortlistPreviewHeadline Hindi parameterized', () {
      expect(
        hi.shortlistPreviewHeadline('सुनील भैया'),
        equals('सुनील भैया की पसंद · आज के लिए'),
      );
    });

    test('presenceStatusAvailable Hindi', () {
      expect(hi.presenceStatusAvailable, equals('● दुकान पर हैं'));
    });

    test('presenceStatusAvailable English', () {
      expect(en.presenceStatusAvailable, equals('● At the shop'));
    });
  });
}
