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
import 'routes/router.dart';

class CustomerApp extends ConsumerWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final onboarding = ref.watch(onboardingControllerProvider);

    // Build theme from loaded tokens or use compile-time defaults
    final themeData = onboarding.whenOrNull(
      data: (data) => _buildTheme(data.themeTokens),
    );

    return MaterialApp.router(
      title: 'Sunil Trading Company',
      debugShowCheckedModeBanner: false,
      theme: themeData ?? _buildDefaultTheme(),
      routerConfig: router,
    );
  }

  /// Build the full theme with YugmaThemeExtension from loaded tokens.
  ThemeData _buildTheme(ShopThemeTokens tokens) {
    final ext = YugmaThemeExtension.fromTokens(tokens);
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
  ThemeData _buildDefaultTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: YugmaColors.primary,
      ),
    );
  }
}
