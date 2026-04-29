// =============================================================================
// CustomerApp — MaterialApp.router root widget.
//
// B1.1 AC #4: "ShopThemeTokens loaded; the entire app's theme is reskinned
// to Sunil Trading Company's colors."
//
// The theme integration flows:
//   1. Boot with compile-time YugmaColors defaults (splash screen)
//   2. OnboardingController fetches ShopThemeTokens from Firestore
//   3. Router re-builds with YugmaThemeExtension.fromTokens
//   4. Every widget reads context.yugmaTheme — warm sheesham/brass/cream
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';

import 'features/onboarding/onboarding_controller.dart';
import 'features/pariwar/elder_tier_provider.dart';
import 'features/pariwar/large_text_toggle.dart';
import 'routes/router.dart';

class CustomerApp extends ConsumerWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('[APP] CustomerApp.build() called');
    final router = ref.watch(routerProvider);
    debugPrint('[APP] routerProvider watched');
    final onboarding = ref.watch(onboardingControllerProvider);
    debugPrint(
        '[APP] onboardingProvider watched — isLoading=${onboarding.isLoading}, hasError=${onboarding.hasError}, hasValue=${onboarding.hasValue}');

    // P2.3 + P2.8: Elder tier activation via persona OR large text toggle.
    // Both providers default to false when onboarding hasn't loaded yet.
    final isElder = ref.watch(isElderTierProvider);
    final isLargeText = ref.watch(largeTextProvider);
    final elderTierActive = isElder || isLargeText;

    // Build theme from loaded tokens or use compile-time defaults
    final themeData = onboarding.whenOrNull(
      data: (data) => _buildTheme(data.themeTokens, elderTierActive),
    );

    return MaterialApp.router(
      title: 'Sunil Trading Company',
      debugShowCheckedModeBanner: false,
      theme: themeData ?? _buildDefaultTheme(),
      // P2.3 AC #2: 300ms animated transition when elder tier toggles.
      themeAnimationDuration: const Duration(milliseconds: 300),
      routerConfig: router,
    );
  }

  /// Build the full theme with YugmaThemeExtension from loaded tokens.
  /// [isElderTier] activates 1.4× text, 56dp taps, slower motion per P2.3.
  ThemeData _buildTheme(ShopThemeTokens tokens, bool isElderTier) {
    final ext =
        YugmaThemeExtension.fromTokens(tokens, isElderTier: isElderTier);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color(
          int.parse(tokens.primaryColorHex.replaceFirst('#', ''), radix: 16) |
              0xFF000000,
        ),
      ),
      extensions: [ext],
    );
  }

  /// Compile-time default theme used during splash before Firestore loads.
  /// Registers a YugmaThemeExtension from compile-time defaults so any
  /// widget that calls context.yugmaTheme during the splash window does
  /// not crash (code review blocker #1).
  ThemeData _buildDefaultTheme() {
    final defaultExt = YugmaThemeExtension.fromTokens(
      ShopThemeTokens.sunilTradingCompanyDefault(),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: YugmaColors.primary,
      ),
      extensions: [defaultExt],
    );
  }
}
