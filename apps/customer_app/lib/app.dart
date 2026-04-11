// =============================================================================
// CustomerApp — MaterialApp.router root widget.
//
// Sprint 1 scope: minimal shell that boots, loads the AuthProvider, shows a
// placeholder splash. The Bharosa landing screen (B1.2) is Sprint 2 work.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routes/router.dart';

class CustomerApp extends ConsumerWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Sunil Trading Company',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      routerConfig: router,
    );
  }

  ThemeData _buildTheme() {
    // Sprint 1 default theme. The YugmaThemeExtension + ShopThemeTokens
    // integration from the frontend-design bundle lands in Sprint 2/3
    // alongside the Bharosa landing screen.
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6B3410), // Workshop Almanac sheesham
      ),
    );
  }
}
