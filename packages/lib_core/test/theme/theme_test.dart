// =============================================================================
// Theme foundation tests — Phase 2.0 Wave 1.
//
// Covers:
//   1. YugmaColors constants stability (no drift in sheesham / brass / oxblood)
//   2. YugmaTypeScale.elder multiplier math (1.4×)
//   3. ShopThemeTokens JSON round-trip via Freezed
//   4. sunilTradingCompanyDefault is Sprint 0-clean (no unreviewed design copy)
//   5. syntheticShop0 has ugly colors (cross-tenant leakage visibility)
//   6. YugmaThemeExtension.fromTokens maps hex strings to Color correctly
//   7. YugmaThemeExtension.lerp smooth color interpolation
//   8. YugmaThemeExtension elder tier switches tap targets + motion
//   9. context.yugmaTheme extension lookup throws when not registered
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_core/src/theme/shop_theme_tokens.dart';
import 'package:lib_core/src/theme/tokens.dart';
import 'package:lib_core/src/theme/yugma_theme_extension.dart';

void main() {
  // ===========================================================================
  // 1. YugmaColors constants stability
  // ===========================================================================

  group('YugmaColors', () {
    test('primary is polished sheesham brown (#6B3410)', () {
      expect(YugmaColors.primary.toARGB32(), equals(0xFF6B3410));
    });

    test('commit is oxblood and equals error (intentional)', () {
      expect(YugmaColors.commit.toARGB32(), equals(0xFF7B1F1F));
      expect(YugmaColors.error, equals(YugmaColors.commit));
    });

    test('background is aged cream not pure white', () {
      expect(YugmaColors.background.toARGB32(), equals(0xFFFAF3E7));
      expect(YugmaColors.background, isNot(equals(const Color(0xFFFFFFFF))));
    });

    test('divider is 12% primary transparency', () {
      expect(YugmaColors.divider.toARGB32(), equals(0x1F6B3410));
    });

    test('textPrimary is warm near-black not pure black', () {
      expect(YugmaColors.textPrimary, isNot(equals(const Color(0xFF000000))));
      expect(YugmaColors.textPrimary.toARGB32(), equals(0xFF1F1611));
    });
  });

  // ===========================================================================
  // 2. YugmaTypeScale elder multiplier
  // ===========================================================================

  group('YugmaTypeScale elder tier', () {
    test('elder multiplier is 1.4× per PRD P2.3', () {
      expect(YugmaTypeScale.elderMultiplier, equals(1.4));
    });

    test('elder(body) scales 15 → 21', () {
      expect(YugmaTypeScale.elder(YugmaTypeScale.body), equals(21.0));
    });

    test('elder(h1) scales 26 → 36.4', () {
      expect(YugmaTypeScale.elder(YugmaTypeScale.h1), closeTo(36.4, 0.01));
    });

    test('tap target minimum elder is 56 not 48', () {
      expect(YugmaTapTargets.minElder, equals(56.0));
      expect(YugmaTapTargets.minDefault, equals(48.0));
    });
  });

  // ===========================================================================
  // 3. ShopThemeTokens JSON round-trip
  // ===========================================================================

  group('ShopThemeTokens JSON round-trip', () {
    test('sunilTradingCompanyDefault round-trips losslessly', () {
      final original = ShopThemeTokens.sunilTradingCompanyDefault();
      final json = original.toJson();
      final restored = ShopThemeTokens.fromJson(json);

      expect(restored.shopId, equals('sunil-trading-company'));
      expect(restored.brandName, equals('सुनील ट्रेडिंग कंपनी'));
      expect(restored.ownerName, equals('सुनील भैया'));
      expect(restored.primaryColorHex, equals('#6B3410'));
      expect(restored.establishedYear, equals(2003));
    });

    test('syntheticShop0 round-trips losslessly', () {
      final original = ShopThemeTokens.syntheticShop0();
      final json = original.toJson();
      final restored = ShopThemeTokens.fromJson(json);

      expect(restored.shopId, equals('shop_0'));
      expect(restored.primaryColorHex, equals('#FF00FF'),
          reason: 'shop_0 uses deliberately ugly magenta for leakage visibility');
    });
  });

  // ===========================================================================
  // 4. Sprint 0 cleanliness of defaults
  // ===========================================================================

  group('Sprint 0 discipline', () {
    test(
      'sunilTradingCompanyDefault tagline is empty string pending Sprint 0 review',
      () {
        final defaults = ShopThemeTokens.sunilTradingCompanyDefault();
        expect(
          defaults.taglineDevanagari,
          equals(''),
          reason: 'Sally-authored tagline must come from Firestore after '
              'Sprint 0 I6.11 closes — not from compile-time defaults',
        );
        expect(defaults.taglineEnglish, equals(''));
      },
    );

    test('brandName + ownerName are retained as shop legal identity', () {
      final defaults = ShopThemeTokens.sunilTradingCompanyDefault();
      expect(
        defaults.brandName,
        isNotEmpty,
        reason: 'shop legal name is not subject to Sprint 0 review',
      );
      expect(defaults.ownerName, isNotEmpty);
    });

    test(
      'sunilTradingCompanyDefault contains no mythic forbidden vocabulary',
      () {
        // Constraint 10 — no शुभ / मंगल / मंदिर / धर्म / तीर्थ / पूज्य /
        // आशीर्वाद / स्वागतम् / उत्पाद / गुणवत्ता / श्रेष्ठ anywhere in defaults.
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

        final defaults = ShopThemeTokens.sunilTradingCompanyDefault();
        final text = [
          defaults.brandName,
          defaults.ownerName,
          defaults.taglineDevanagari,
          defaults.taglineEnglish,
          defaults.city,
          defaults.marketArea,
        ].join(' ');

        for (final word in forbidden) {
          expect(
            text.contains(word),
            isFalse,
            reason: 'ShopThemeTokens defaults must not contain "$word" '
                '(Constraint 10 forbidden mythic vocabulary)',
          );
        }
      },
    );
  });

  // ===========================================================================
  // 5. YugmaThemeExtension.fromTokens — hex → Color mapping
  // ===========================================================================

  group('YugmaThemeExtension.fromTokens', () {
    test('maps hex strings to Color correctly', () {
      final ext = YugmaThemeExtension.fromTokens(
        ShopThemeTokens.sunilTradingCompanyDefault(),
      );

      expect(ext.shopPrimary.toARGB32(), equals(0xFF6B3410));
      expect(ext.shopCommit.toARGB32(), equals(0xFF7B1F1F));
      expect(ext.shopBackground.toARGB32(), equals(0xFFFAF3E7));
    });

    test('default elder tier is false', () {
      final ext = YugmaThemeExtension.fromTokens(
        ShopThemeTokens.sunilTradingCompanyDefault(),
      );
      expect(ext.isElderTier, isFalse);
      expect(ext.tapTargetMin, equals(YugmaTapTargets.minDefault));
    });

    test('elder tier switches tap target to 56 and slows motion', () {
      final ext = YugmaThemeExtension.fromTokens(
        ShopThemeTokens.sunilTradingCompanyDefault(),
        isElderTier: true,
      );
      expect(ext.isElderTier, isTrue);
      expect(ext.tapTargetMin, equals(YugmaTapTargets.minElder));
      expect(ext.motionFast, equals(YugmaMotion.elderFast));
      expect(ext.motionNormal, equals(YugmaMotion.elderNormal));
    });

    test('elder tier body text scales 15 → 21', () {
      final defaultExt = YugmaThemeExtension.fromTokens(
        ShopThemeTokens.sunilTradingCompanyDefault(),
      );
      final elderExt = YugmaThemeExtension.fromTokens(
        ShopThemeTokens.sunilTradingCompanyDefault(),
        isElderTier: true,
      );
      expect(defaultExt.bodyDeva.fontSize, equals(15.0));
      expect(elderExt.bodyDeva.fontSize, equals(21.0));
    });

    test('syntheticShop0 produces ugly magenta primary', () {
      final ext = YugmaThemeExtension.fromTokens(
        ShopThemeTokens.syntheticShop0(),
      );
      expect(
        ext.shopPrimary.toARGB32(),
        equals(0xFFFF00FF),
        reason: 'shop_0 uses magenta for cross-tenant leakage visibility',
      );
    });
  });

  // ===========================================================================
  // 6. YugmaThemeExtension.lerp smooth transitions
  // ===========================================================================

  group('YugmaThemeExtension.lerp', () {
    test('lerp from shop_0 to sunil-trading-company at t=0 returns self', () {
      final a = YugmaThemeExtension.fromTokens(
        ShopThemeTokens.syntheticShop0(),
      );
      final b = YugmaThemeExtension.fromTokens(
        ShopThemeTokens.sunilTradingCompanyDefault(),
      );
      final lerped = a.lerp(b, 0);
      expect(lerped.shopPrimary, equals(a.shopPrimary));
    });

    test('lerp at t=1 returns other', () {
      final a = YugmaThemeExtension.fromTokens(
        ShopThemeTokens.syntheticShop0(),
      );
      final b = YugmaThemeExtension.fromTokens(
        ShopThemeTokens.sunilTradingCompanyDefault(),
      );
      final lerped = a.lerp(b, 1);
      expect(lerped.shopPrimary, equals(b.shopPrimary));
    });

    test('lerp at t=0.5 interpolates color channels', () {
      final a = YugmaThemeExtension.fromTokens(
        ShopThemeTokens.syntheticShop0(),
      );
      final b = YugmaThemeExtension.fromTokens(
        ShopThemeTokens.sunilTradingCompanyDefault(),
      );
      final lerped = a.lerp(b, 0.5);
      // At t=0.5, the primary should be between magenta and sheesham
      expect(lerped.shopPrimary, isNot(equals(a.shopPrimary)));
      expect(lerped.shopPrimary, isNot(equals(b.shopPrimary)));
    });

    test('lerp with non-YugmaThemeExtension returns self unchanged', () {
      final a = YugmaThemeExtension.fromTokens(
        ShopThemeTokens.sunilTradingCompanyDefault(),
      );
      final lerped = a.lerp(null, 0.5);
      expect(lerped.shopPrimary, equals(a.shopPrimary));
    });
  });

  // ===========================================================================
  // 7. context.yugmaTheme extension lookup
  // ===========================================================================

  group('YugmaThemeContext', () {
    testWidgets('context.yugmaTheme returns registered extension',
        (tester) async {
      final extension = YugmaThemeExtension.fromTokens(
        ShopThemeTokens.sunilTradingCompanyDefault(),
      );

      YugmaThemeExtension? captured;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [extension]),
          home: Builder(
            builder: (context) {
              captured = context.yugmaTheme;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(captured, isNotNull);
      expect(captured!.shopId, equals('sunil-trading-company'));
      expect(captured!.shopPrimary.toARGB32(), equals(0xFF6B3410));
    });

    testWidgets('context.yugmaTheme assertion fails when not registered',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(),
          home: Builder(
            builder: (context) {
              // This should throw an assertion error in debug mode.
              expect(
                () => context.yugmaTheme,
                throwsA(isA<AssertionError>()),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });
  });

  // ===========================================================================
  // 8. Hex parsing edge cases (_hexToColor via fromTokens)
  // ===========================================================================

  group('hex parsing via fromTokens', () {
    test('accepts hex with leading #', () {
      final tokens = ShopThemeTokens.sunilTradingCompanyDefault();
      final ext = YugmaThemeExtension.fromTokens(tokens);
      expect(ext.shopPrimary.toARGB32(), equals(0xFF6B3410));
    });

    test('full-alpha derived correctly from 6-char hex', () {
      final tokens = ShopThemeTokens.syntheticShop0();
      final ext = YugmaThemeExtension.fromTokens(tokens);
      // 0xFFFF00FF — full alpha (the high byte is 0xFF, not 0x00)
      expect(ext.shopPrimary.toARGB32() >> 24, equals(0xFF));
    });
  });
}
