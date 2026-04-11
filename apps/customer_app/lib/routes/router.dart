// =============================================================================
// Customer app router — GoRouter scaffold.
//
// Sprint 1 scope: boot splash only. Real routes (landing, browse, chat,
// commit, payment) ship in Sprints 2–5 as their stories land.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => const _BootSplashScreen(),
      ),
    ],
  );
});

/// Sprint 1 placeholder. Replaced by BharosaLanding in B1.2 (Sprint 2).
class _BootSplashScreen extends StatelessWidget {
  const _BootSplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Devanagari placeholder — real shop branding from ShopThemeTokens
            // ships with the theme integration in Sprint 2.
            Text(
              'सुनील ट्रेडिंग कंपनी',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
