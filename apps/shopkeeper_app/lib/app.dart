// =============================================================================
// ShopkeeperApp — MaterialApp.router root widget.
//
// Sprint 3 scope: wired with YugmaThemeExtension from ShopThemeTokens.
// Real ops screens (inventory, orders, chat, udhaar, settings, absence/
// presence) ship in subsequent sprints as S4.x stories.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';

import 'routes/router.dart';

/// Watches /shops/{shopId}/theme/current and maps to ShopThemeTokens.
/// Falls back to sunilTradingCompanyDefault() on any error or absence.
final shopThemeProvider = FutureProvider<ShopThemeTokens>((ref) async {
  final shopId = ref.read(shopIdProviderProvider).shopId;
  try {
    final doc = await FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .collection('theme')
        .doc('current')
        .get();
    if (doc.exists && doc.data() != null) {
      final raw = doc.data()!;
      return ShopThemeTokens.fromJson(<String, dynamic>{
        ...raw,
        'updatedAt': _normalizeTimestamp(raw['updatedAt']),
        'createdAt': _normalizeTimestamp(raw['createdAt']),
      });
    }
  } catch (_) {
    // fall through to default
  }
  return ShopThemeTokens.sunilTradingCompanyDefault();
});

/// Normalizes a Firestore Timestamp or DateTime to ISO8601 for Freezed.
Object? _normalizeTimestamp(Object? value) {
  if (value is Timestamp) return value.toDate().toIso8601String();
  if (value is DateTime) return value.toIso8601String();
  return value;
}

class ShopkeeperApp extends ConsumerWidget {
  const ShopkeeperApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(shopkeeperRouterProvider);
    final tokens = ref.watch(shopThemeProvider).valueOrNull;

    return MaterialApp.router(
      title: 'Sunil Trading Company — Ops',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(tokens),
      routerConfig: router,
    );
  }

  ThemeData _buildTheme(ShopThemeTokens? tokens) {
    final resolvedTokens =
        tokens ?? ShopThemeTokens.sunilTradingCompanyDefault();
    final yugmaExt = YugmaThemeExtension.fromTokens(resolvedTokens);

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
