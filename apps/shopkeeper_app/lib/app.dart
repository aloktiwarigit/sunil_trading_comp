// =============================================================================
// ShopkeeperApp — MaterialApp.router root widget.
//
// Sprint 1 scope: minimal shell. Real ops screens (inventory, orders, chat,
// udhaar, settings, absence/presence) ship in Sprints 3–6 as S4.x stories.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routes/router.dart';

class ShopkeeperApp extends ConsumerWidget {
  const ShopkeeperApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(shopkeeperRouterProvider);

    return MaterialApp.router(
      title: 'सुनील की दुकान — Ops',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      routerConfig: router,
    );
  }

  ThemeData _buildTheme() {
    // Sprint 1 default. Real YugmaThemeExtension integration lands with
    // S4.12 (Shop branding ops) in Sprint 4–5.
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6B3410), // Workshop Almanac sheesham
        brightness: Brightness.light,
      ),
    );
  }
}
