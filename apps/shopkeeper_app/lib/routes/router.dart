// =============================================================================
// Shopkeeper app router — GoRouter with auth-based routing.
//
// Flow per S4.1:
//   / (boot splash) → /sign-in (if not authenticated) → /home (dashboard)
//
// S4.3 additions:
//   /inventory → inventory list with + FAB
//   /inventory/create → SKU creation form
//
// The router watches the OpsAuthController state and redirects accordingly:
//   - loading → boot splash
//   - signedOut / unauthorized / permissionRevoked → sign-in screen
//   - authorized → home dashboard
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lib_core/lib_core.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/dashboard/analytics_dashboard_screen.dart';
import '../features/dashboard/home_dashboard.dart';
import '../features/inventory/create_sku_screen.dart';
import '../features/inventory/edit_sku_screen.dart';
import '../features/inventory/inventory_list_screen.dart';
import '../features/chat/shopkeeper_chat_screen.dart';
import '../features/curation/curation_screen.dart';
import '../features/inventory/golden_hour_capture_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/orders/active_projects_screen.dart';
import '../features/orders/project_detail_screen.dart';
import '../features/udhaar/udhaar_detail_screen.dart';
import '../features/udhaar/udhaar_list_screen.dart';
import '../features/voice/greeting_management_screen.dart';

final shopkeeperRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final authAsync = ref.read(opsAuthControllerProvider);
      final authState = authAsync.value;

      // Still loading — stay on splash.
      if (authAsync.isLoading || authState == null) {
        return state.matchedLocation == '/' ? null : '/';
      }

      final isOnSignIn = state.matchedLocation == '/sign-in';
      final isOnHome = state.matchedLocation == '/home';

      switch (authState.status) {
        case OpsAuthStatus.loading:
          return state.matchedLocation == '/' ? null : '/';

        case OpsAuthStatus.signedOut:
        case OpsAuthStatus.unauthorized:
        case OpsAuthStatus.permissionRevoked:
          return isOnSignIn ? null : '/sign-in';

        case OpsAuthStatus.authorized:
          // Allow navigation to sub-routes when authorized.
          if (isOnHome ||
              state.matchedLocation.startsWith('/inventory') ||
              state.matchedLocation.startsWith('/orders') ||
              state.matchedLocation.startsWith('/udhaar') ||
              state.matchedLocation.startsWith('/dashboard') ||
              state.matchedLocation.startsWith('/greeting') ||
              state.matchedLocation.startsWith('/curation') ||
              state.matchedLocation.startsWith('/golden-hour') ||
              state.matchedLocation.startsWith('/settings')) {
            return null;
          }
          return '/home';
      }
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => const _OpsBootSplash(),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const OpsSignInScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeDashboard(),
      ),
      // S4.6 — Active projects / orders list
      GoRoute(
        path: '/orders',
        builder: (context, state) => const ActiveProjectsScreen(),
        routes: <RouteBase>[
          // S4.7 — Project detail
          GoRoute(
            path: ':projectId',
            builder: (context, state) => ProjectDetailScreen(
              projectId: state.pathParameters['projectId']!,
            ),
            routes: <RouteBase>[
              // S4.8 — Shopkeeper chat
              GoRoute(
                path: 'chat',
                builder: (context, state) => ShopkeeperChatScreen(
                  projectId: state.pathParameters['projectId']!,
                ),
              ),
            ],
          ),
        ],
      ),
      // S4.11 — Analytics dashboard
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const AnalyticsDashboardScreen(),
      ),
      // S4.12 — Settings (bhaiya only)
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      // S4.5 — Golden Hour photo capture
      GoRoute(
        path: '/golden-hour/:skuId',
        builder: (context, state) => GoldenHourCaptureScreen(
          skuId: state.pathParameters['skuId']!,
          skuName: state.uri.queryParameters['name'] ?? '',
        ),
      ),
      // B1.12 — Curation screen
      GoRoute(
        path: '/curation',
        builder: (context, state) => const CurationScreen(),
      ),
      // B1.8 — Greeting voice note management (bhaiya only)
      GoRoute(
        path: '/greeting',
        builder: (context, state) => const GreetingManagementScreen(),
      ),
      // S4.10 — Udhaar ledger management
      GoRoute(
        path: '/udhaar',
        builder: (context, state) => const UdhaarListScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: ':ledgerId',
            builder: (context, state) => UdhaarDetailScreen(
              ledgerId: state.pathParameters['ledgerId']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/inventory',
        builder: (context, state) => const InventoryListScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: 'create',
            builder: (context, state) => const CreateSkuScreen(),
          ),
          // S4.4 — Edit existing SKU
          GoRoute(
            path: ':skuId',
            builder: (context, state) => EditSkuScreen(
              skuId: state.pathParameters['skuId']!,
            ),
          ),
        ],
      ),
    ],
  );
});

/// Boot splash — shown while the auth state is being resolved.
class _OpsBootSplash extends StatelessWidget {
  const _OpsBootSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YugmaColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              const AppStringsHi().shopDisplayName,
              style: TextStyle(
                fontFamily: YugmaFonts.devaDisplay,
                fontSize: YugmaTypeScale.display,
                height: YugmaLineHeights.tight,
                color: YugmaColors.primary,
              ),
            ),
            const SizedBox(height: YugmaSpacing.s2),
            Text(
              'Ops',
              style: TextStyle(
                fontFamily: YugmaFonts.enDisplay,
                fontSize: YugmaTypeScale.h3,
                fontStyle: FontStyle.italic,
                color: YugmaColors.textSecondary,
              ),
            ),
            const SizedBox(height: YugmaSpacing.s8),
            CircularProgressIndicator(
              color: YugmaColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
