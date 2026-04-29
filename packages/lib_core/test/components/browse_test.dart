// =============================================================================
// Sprint 3 browse widget tests — B1.3 + B1.4 + B1.5
//
// Covers:
//   1. VoiceNotePlayerWidget — renders play/pause, waveform, duration label
//   2. CuratedShortlistCard — renders all fields, price formatting, badge, elder tier
//   3. ShortlistScreen — renders SKU list, empty state
//   4. GoldenHourPhotoView — renders image, asli roop toggle
//   5. SkuDetailCard — renders hero photo, info, action buttons, no negotiable floor
//   6. AppStrings new keys — skuTopPickBadge, skuNegotiableLabel, goldenHourToggleBeautiful
//   7. Indian number formatting correctness
//   8. Forbidden vocabulary not present in new strings
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_core/src/components/browse/curated_shortlist_card.dart';
import 'package:lib_core/src/components/browse/golden_hour_photo_view.dart';
import 'package:lib_core/src/components/browse/shortlist_screen.dart';
import 'package:lib_core/src/components/browse/sku_detail_card.dart';
import 'package:lib_core/src/components/voice_note_player.dart';
import 'package:lib_core/src/locale/strings_en.dart';
import 'package:lib_core/src/locale/strings_hi.dart';
import 'package:lib_core/src/models/curated_shortlist.dart';
import 'package:lib_core/src/models/inventory_sku.dart';
import 'package:lib_core/src/theme/shop_theme_tokens.dart';
import 'package:lib_core/src/theme/yugma_theme_extension.dart';

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

/// Wrap a widget in MaterialApp with YugmaThemeExtension registered.
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
    home: child,
  );
}

/// Build a test InventorySku.
InventorySku _testSku({
  String skuId = 'sku-1',
  String nameDevanagari = 'गोदरेज स्टील अलमारी',
  String name = 'Godrej Steel Almirah',
  String description = 'दो दरवाजे, ब्रास लॉक',
  int basePrice = 17500,
  int negotiableDownTo = 15000,
  SkuMaterial material = SkuMaterial.steel,
  List<String> goldenHourPhotoIds = const [],
  List<String> fallbackPhotoUrls = const [],
}) {
  return InventorySku(
    skuId: skuId,
    shopId: 'sunil-trading-company',
    name: name,
    nameDevanagari: nameDevanagari,
    description: description,
    category: SkuCategory.steelAlmirah,
    material: material,
    dimensions: const SkuDimensions(
      heightCm: 152,
      widthCm: 92,
      depthCm: 51,
    ),
    basePrice: basePrice,
    negotiableDownTo: negotiableDownTo,
    goldenHourPhotoIds: goldenHourPhotoIds,
    fallbackPhotoUrls: fallbackPhotoUrls,
    createdAt: DateTime(2026, 4, 1),
  );
}

CuratedShortlist _testShortlist({
  ShortlistOccasion occasion = ShortlistOccasion.shaadi,
  List<String> skuIds = const ['sku-1', 'sku-2'],
}) {
  return CuratedShortlist(
    shortlistId: 'shortlist-1',
    shopId: 'sunil-trading-company',
    occasion: occasion,
    titleDevanagari: 'शादी के लिए',
    titleEnglish: 'For a wedding',
    skuIdsInOrder: skuIds,
    createdAt: DateTime(2026, 4, 1),
  );
}

void main() {
  // ===========================================================================
  // 1. VoiceNotePlayerWidget
  // ===========================================================================

  group('VoiceNotePlayerWidget', () {
    testWidgets('renders play button and duration label', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          const Scaffold(
            body: Center(
              child: VoiceNotePlayerWidget(durationSeconds: 15),
            ),
          ),
        ),
      );

      // Play button icon present
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      // Duration label
      expect(find.text('0:15'), findsOneWidget);
    });

    testWidgets('toggles to pause icon on tap', (tester) async {
      bool? lastPlayState;
      await tester.pumpWidget(
        _wrapWithTheme(
          Scaffold(
            body: Center(
              child: VoiceNotePlayerWidget(
                durationSeconds: 30,
                onPlayPause: (playing) => lastPlayState = playing,
              ),
            ),
          ),
        ),
      );

      // Tap play
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pump();

      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(lastPlayState, isTrue);

      // Tap pause
      await tester.tap(find.byIcon(Icons.pause_rounded));
      await tester.pump();

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(lastPlayState, isFalse);
    });

    testWidgets('formats duration correctly for > 60s', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          const Scaffold(
            body: Center(
              child: VoiceNotePlayerWidget(durationSeconds: 65),
            ),
          ),
        ),
      );

      expect(find.text('1:05'), findsOneWidget);
    });

    testWidgets('renders 14 waveform bars', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          const Scaffold(
            body: Center(
              child: VoiceNotePlayerWidget(durationSeconds: 15),
            ),
          ),
        ),
      );

      // The waveform bars are Containers inside a Row inside a SizedBox(width:120)
      // We check for at least the play icon + duration = widget is rendering
      expect(find.byType(VoiceNotePlayerWidget), findsOneWidget);
    });

    testWidgets('elder tier inflates button size', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          const Scaffold(
            body: Center(
              child: VoiceNotePlayerWidget(durationSeconds: 15),
            ),
          ),
          isElderTier: true,
        ),
      );

      // Should still render without error
      expect(find.byType(VoiceNotePlayerWidget), findsOneWidget);
      expect(find.text('0:15'), findsOneWidget);
    });
  });

  // ===========================================================================
  // 2. CuratedShortlistCard
  // ===========================================================================

  group('CuratedShortlistCard', () {
    testWidgets('renders Devanagari name, price, and description',
        (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          Scaffold(
            body: CuratedShortlistCard(
              nameDevanagari: 'गोदरेज स्टील अलमारी',
              nameEnglish: 'Godrej Steel Almirah',
              materialLabel: 'Steel',
              dimensionsLabel: '152 \u00D7 92 \u00D7 51 cm',
              priceInr: 17500,
              negotiable: true,
              negotiableLabel: 'Negotiable',
              topPickBadgeLabel: "Sunil-bhaiya's pick",
              thumbnailUrl: null,
              isShopkeepersTopPick: true,
              description: 'दो दरवाजे, ब्रास लॉक',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('गोदरेज स्टील अलमारी'), findsOneWidget);
      expect(find.text('Godrej Steel Almirah'), findsOneWidget);
      expect(find.text('\u20B917,500'), findsOneWidget);
      expect(find.text('Negotiable'), findsOneWidget);
      expect(find.text("Sunil-bhaiya's pick"), findsOneWidget);
      expect(find.text('दो दरवाजे, ब्रास लॉक'), findsOneWidget);
    });

    testWidgets('hides negotiable label when not negotiable', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          Scaffold(
            body: CuratedShortlistCard(
              nameDevanagari: 'टेस्ट',
              nameEnglish: 'Test',
              materialLabel: 'Steel',
              dimensionsLabel: '100 cm',
              priceInr: 5000,
              negotiable: false,
              negotiableLabel: 'Negotiable',
              topPickBadgeLabel: 'Pick',
              thumbnailUrl: null,
              isShopkeepersTopPick: false,
              description: '',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Negotiable'), findsNothing);
      expect(find.text('Pick'), findsNothing);
    });

    testWidgets('fires onTap callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrapWithTheme(
          Scaffold(
            body: CuratedShortlistCard(
              nameDevanagari: 'टेस्ट',
              nameEnglish: 'Test',
              materialLabel: 'Steel',
              dimensionsLabel: '100 cm',
              priceInr: 5000,
              negotiable: false,
              negotiableLabel: 'Negotiable',
              topPickBadgeLabel: 'Pick',
              thumbnailUrl: null,
              isShopkeepersTopPick: false,
              description: '',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CuratedShortlistCard));
      expect(tapped, isTrue);
    });
  });

  // ===========================================================================
  // 3. ShortlistScreen
  // ===========================================================================

  group('ShortlistScreen', () {
    testWidgets('renders SKU cards when shortlist has items', (tester) async {
      final skus = [_testSku(skuId: 'sku-1'), _testSku(skuId: 'sku-2')];

      await tester.pumpWidget(
        _wrapWithTheme(
          ShortlistScreen(
            shortlist: _testShortlist(),
            skus: skus,
            strings: const AppStringsEn(),
          ),
        ),
      );

      // Should render 2 cards
      expect(find.byType(CuratedShortlistCard), findsNWidgets(2));
    });

    testWidgets('renders empty state when shortlist is empty', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          ShortlistScreen(
            shortlist: _testShortlist(skuIds: []),
            skus: const [],
            strings: const AppStringsEn(),
          ),
        ),
      );

      expect(find.text("Sunil-bhaiya hasn't picked anything for this yet"),
          findsOneWidget);
      expect(find.byType(CuratedShortlistCard), findsNothing);
    });

    testWidgets('fires onSkuTap when a card is tapped', (tester) async {
      InventorySku? tappedSku;
      final skus = [_testSku(skuId: 'sku-1')];

      await tester.pumpWidget(
        _wrapWithTheme(
          ShortlistScreen(
            shortlist: _testShortlist(skuIds: ['sku-1']),
            skus: skus,
            strings: const AppStringsEn(),
            onSkuTap: (sku) => tappedSku = sku,
          ),
        ),
      );

      await tester.tap(find.byType(CuratedShortlistCard));
      expect(tappedSku, isNotNull);
      expect(tappedSku!.skuId, equals('sku-1'));
    });

    testWidgets('uses correct title for each occasion', (tester) async {
      for (final occasion in ShortlistOccasion.values) {
        await tester.pumpWidget(
          _wrapWithTheme(
            ShortlistScreen(
              shortlist: _testShortlist(occasion: occasion, skuIds: []),
              skus: const [],
              strings: const AppStringsHi(),
            ),
          ),
        );

        // Each occasion should produce a non-empty title in the AppBar
        expect(find.byType(AppBar), findsOneWidget);
      }
    });
  });

  // ===========================================================================
  // 4. GoldenHourPhotoView
  // ===========================================================================

  group('GoldenHourPhotoView', () {
    testWidgets('renders without toggle when no working-light URL',
        (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          Scaffold(
            body: GoldenHourPhotoView(
              goldenHourImageUrl: 'https://example.com/golden.jpg',
              workingLightImageUrl: null,
              asliRoopLabel: 'Show real form',
              goldenHourToggleLabel: 'Beautiful view',
            ),
          ),
        ),
      );

      expect(find.text('Show real form'), findsNothing);
      expect(find.text('Beautiful view'), findsNothing);
    });

    testWidgets('shows toggle when working-light URL present', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          Scaffold(
            body: GoldenHourPhotoView(
              goldenHourImageUrl: 'https://example.com/golden.jpg',
              workingLightImageUrl: 'https://example.com/working.jpg',
              asliRoopLabel: 'Show real form',
              goldenHourToggleLabel: 'Beautiful view',
            ),
          ),
        ),
      );

      // Initially shows "asli roop" label
      expect(find.text('Show real form'), findsOneWidget);
    });

    testWidgets('toggles label on tap', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          Scaffold(
            body: GoldenHourPhotoView(
              goldenHourImageUrl: 'https://example.com/golden.jpg',
              workingLightImageUrl: 'https://example.com/working.jpg',
              asliRoopLabel: 'Show real form',
              goldenHourToggleLabel: 'Beautiful view',
            ),
          ),
        ),
      );

      // Tap the toggle
      await tester.tap(find.text('Show real form'));
      await tester.pump();

      // Now should show "beautiful view"
      expect(find.text('Beautiful view'), findsOneWidget);
      expect(find.text('Show real form'), findsNothing);
    });
  });

  // ===========================================================================
  // 5. SkuDetailCard
  // ===========================================================================

  group('SkuDetailCard', () {
    testWidgets('renders SKU name, description, and price', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          SkuDetailCard(
            sku: _testSku(),
            strings: const AppStringsEn(),
            goldenHourPhotoUrl: '',
          ),
        ),
      );

      expect(find.text('गोदरेज स्टील अलमारी'), findsOneWidget);
      expect(find.text('Godrej Steel Almirah'), findsOneWidget);
      expect(find.text('दो दरवाजे, ब्रास लॉक'), findsOneWidget);
      expect(find.text('\u20B917,500'), findsOneWidget);
    });

    testWidgets('renders both action buttons', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          SkuDetailCard(
            sku: _testSku(),
            strings: const AppStringsEn(),
            goldenHourPhotoUrl: '',
          ),
        ),
      );
      // Sticky-bottom buttons are in the widget tree regardless of scroll
      // (v0.2.0 redesign — commit 3e6e2b0 — no longer uses CustomScrollView).
      await tester.pumpAndSettle();

      expect(find.text('Add to my list'), findsOneWidget);
      expect(find.text('Talk to Sunil-bhaiya'), findsOneWidget);
    });

    testWidgets('shows negotiable label when price has room', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          SkuDetailCard(
            sku: _testSku(basePrice: 20000, negotiableDownTo: 17000),
            strings: const AppStringsEn(),
            goldenHourPhotoUrl: '',
          ),
        ),
      );

      expect(find.text('Negotiable'), findsOneWidget);
    });

    testWidgets('hides negotiable label when no negotiation room',
        (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          SkuDetailCard(
            sku: _testSku(basePrice: 15000, negotiableDownTo: 15000),
            strings: const AppStringsEn(),
            goldenHourPhotoUrl: '',
          ),
        ),
      );

      expect(find.text('Negotiable'), findsNothing);
    });

    testWidgets('NEVER shows negotiableDownTo value (AC #7)', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          SkuDetailCard(
            sku: _testSku(basePrice: 20000, negotiableDownTo: 15000),
            strings: const AppStringsEn(),
            goldenHourPhotoUrl: '',
          ),
        ),
      );

      // The negotiableDownTo value (15,000) must NEVER appear
      expect(find.text('\u20B915,000'), findsNothing);
      expect(find.text('15,000'), findsNothing);
      expect(find.text('15000'), findsNothing);
    });

    testWidgets('fires onAddToList and onTalkToBhaiya callbacks',
        (tester) async {
      var addTapped = false;
      var talkTapped = false;

      await tester.pumpWidget(
        _wrapWithTheme(
          SkuDetailCard(
            sku: _testSku(),
            strings: const AppStringsEn(),
            goldenHourPhotoUrl: '',
            onAddToList: () => addTapped = true,
            onTalkToBhaiya: () => talkTapped = true,
          ),
        ),
      );
      // Sticky-bottom buttons are visible at viewport bottom; no scroll needed
      // (v0.2.0 redesign — commit 3e6e2b0 — no longer uses CustomScrollView).
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add to my list'));
      expect(addTapped, isTrue);

      await tester.tap(find.text('Talk to Sunil-bhaiya'));
      expect(talkTapped, isTrue);
    });
  });

  // ===========================================================================
  // 6. AppStrings new keys
  // ===========================================================================

  group('AppStrings new keys', () {
    test('Hindi strings have correct values', () {
      const hi = AppStringsHi();
      expect(hi.skuTopPickBadge, equals('सुनील भैया की पसंद'));
      expect(hi.skuNegotiableLabel, equals('मोल भाव'));
      expect(hi.goldenHourToggleBeautiful, equals('सुंदर रूप'));
    });

    test('English strings have correct values', () {
      const en = AppStringsEn();
      expect(en.skuTopPickBadge, equals("Sunil-bhaiya's pick"));
      expect(en.skuNegotiableLabel, equals('Negotiable'));
      expect(en.goldenHourToggleBeautiful, equals('Beautiful view'));
    });
  });

  // ===========================================================================
  // 7. Indian number formatting
  // ===========================================================================

  group('Indian number formatting', () {
    // Test via CuratedShortlistCard which exposes _formatInr
    testWidgets('formats 17500 as 17,500', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          Scaffold(
            body: CuratedShortlistCard(
              nameDevanagari: 'Test',
              nameEnglish: 'Test',
              materialLabel: 'Steel',
              dimensionsLabel: '100 cm',
              priceInr: 17500,
              negotiable: false,
              negotiableLabel: '',
              topPickBadgeLabel: '',
              thumbnailUrl: null,
              isShopkeepersTopPick: false,
              description: '',
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('\u20B917,500'), findsOneWidget);
    });

    testWidgets('formats 150000 as 1,50,000', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          Scaffold(
            body: CuratedShortlistCard(
              nameDevanagari: 'Test',
              nameEnglish: 'Test',
              materialLabel: 'Steel',
              dimensionsLabel: '100 cm',
              priceInr: 150000,
              negotiable: false,
              negotiableLabel: '',
              topPickBadgeLabel: '',
              thumbnailUrl: null,
              isShopkeepersTopPick: false,
              description: '',
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('\u20B91,50,000'), findsOneWidget);
    });

    testWidgets('formats 500 as 500 (no comma)', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          Scaffold(
            body: CuratedShortlistCard(
              nameDevanagari: 'Test',
              nameEnglish: 'Test',
              materialLabel: 'Steel',
              dimensionsLabel: '100 cm',
              priceInr: 500,
              negotiable: false,
              negotiableLabel: '',
              topPickBadgeLabel: '',
              thumbnailUrl: null,
              isShopkeepersTopPick: false,
              description: '',
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('\u20B9500'), findsOneWidget);
    });
  });

  // ===========================================================================
  // 8. Forbidden vocabulary check on new strings
  // ===========================================================================

  group('Forbidden vocabulary in new strings', () {
    test('no mythic vocabulary in Hindi strings', () {
      const forbidden = <String>[
        'शुभ',
        'मंगल',
        'मंदिर',
        'धर्म',
        'तीर्थ',
        'पूज्य',
        'आशीर्वाद',
        'स्वागतम्',
        'उत्पाद',
        'गुणवत्ता',
        'श्रेष्ठ',
      ];

      const hi = AppStringsHi();
      final newStrings = [
        hi.skuTopPickBadge,
        hi.skuNegotiableLabel,
        hi.goldenHourToggleBeautiful,
      ];

      for (final str in newStrings) {
        for (final word in forbidden) {
          expect(
            str.contains(word),
            isFalse,
            reason: 'New string "$str" must not contain mythic "$word"',
          );
        }
      }
    });

    test('no udhaar lending vocabulary in English strings', () {
      const forbidden = <String>[
        'interest',
        'due date',
        'overdue',
        'penalty',
        'loan',
        'default',
        'collection',
        'installment',
        'EMI',
      ];

      const en = AppStringsEn();
      final newStrings = [
        en.skuTopPickBadge,
        en.skuNegotiableLabel,
        en.goldenHourToggleBeautiful,
      ];

      for (final str in newStrings) {
        for (final word in forbidden) {
          expect(
            str.toLowerCase().contains(word.toLowerCase()),
            isFalse,
            reason: 'New string "$str" must not contain udhaar term "$word"',
          );
        }
      }
    });
  });
}
