// =============================================================================
// ShopkeeperApp — MaterialApp.router root widget.
//
// Sprint 3 scope: wired with YugmaThemeExtension from ShopThemeTokens.
// Real ops screens (inventory, orders, chat, udhaar, settings, absence/
// presence) ship in subsequent sprints as S4.x stories.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';

import 'routes/router.dart';

class ShopkeeperApp extends ConsumerWidget {
  const ShopkeeperApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(shopkeeperRouterProvider);

    return MaterialApp.router(
      title: 'Sunil Trading Company — Ops',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      routerConfig: router,
    );
  }

  ThemeData _buildTheme() {
    // Build the YugmaThemeExtension from the flagship shop's default tokens.
    final tokens = ShopThemeTokens.sunilTradingCompanyDefault();
    final yugmaExt = YugmaThemeExtension.fromTokens(tokens);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6B3410), // Workshop Almanac sheesham
        brightness: Brightness.light,
      ),
      extensions: <ThemeExtension<dynamic>>[yugmaExt],
    );
  }
}
