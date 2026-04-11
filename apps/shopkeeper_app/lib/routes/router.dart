// =============================================================================
// Shopkeeper app router — GoRouter scaffold.
//
// Sprint 1 scope: boot splash only. Ops screens ship with their S4.x stories.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final shopkeeperRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => const _OpsBootSplash(),
      ),
    ],
  );
});

class _OpsBootSplash extends StatelessWidget {
  const _OpsBootSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'सुनील की दुकान',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Ops',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
