// =============================================================================
// Customer app router — GoRouter with onboarding-gated splash → landing.
//
// B1.1 AC #7: "No OTP screen, no 'create account' screen, no 'welcome aboard'
// screen — the first screen IS the shopkeeper."
//
// Route structure:
//   /         → Splash (while onboarding loads) → redirects to /landing
//   /landing  → BharosaLanding (the real first screen)
//
// Deep link handling (B1.1 edge cases #3, #4):
//   /project/:projectId → bypass landing, go to Project view (future sprint)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lib_core/lib_core.dart';

import '../features/onboarding/onboarding_controller.dart';
import '../features/onboarding/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final onboarding = ref.watch(onboardingControllerProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoading = onboarding.isLoading;
      final hasError = onboarding.hasError;
      final isOnSplash = state.matchedLocation == '/';

      // While loading, stay on splash
      if (isLoading && isOnSplash) return null;

      // If error during onboarding, stay on splash (shows error state)
      if (hasError && isOnSplash) return null;

      // Once loaded, redirect splash → landing
      if (!isLoading && !hasError && isOnSplash) return '/landing';

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/landing',
        builder: (context, state) {
          final data = onboarding.valueOrNull;
          if (data == null) {
            // Should not happen due to redirect, but defensive
            return const SplashScreen();
          }

          final theme = YugmaThemeExtension.fromTokens(data.themeTokens);

          return Theme(
            data: ThemeData(
              useMaterial3: true,
              extensions: [theme],
            ),
            child: BharosaLanding(
              onShortlistTap: (occasionTag) {
                // TODO(sprint-3): route to /shortlist/:occasionTag (B1.4)
              },
              onGreetingPlay: () {
                // TODO(sprint-2): wire MediaStore voice note playback (B1.3)
              },
              autoPlayGreeting: true,
              onPresenceVoiceNote: () {
                // TODO(sprint-2): wire presence dock voice note
              },
              previewShortlists: const [],
              // TODO(sprint-3): fetch curated shortlists from Firestore (B1.4)
              strings: data.strings,
              hasGreetingVoiceNote:
                  data.themeTokens.greetingVoiceNoteId.isNotEmpty,
              greetingDurationSeconds: 0,
              // TODO(sprint-2): fetch voice note metadata for duration
              currentLocaleCode: data.localeCode,
              onLocaleToggle: () {
                ref.read(onboardingControllerProvider.notifier).toggleLocale();
              },
              onRefresh: () async {
                await ref
                    .read(onboardingControllerProvider.notifier)
                    .refreshTheme();
              },
            ),
          );
        },
      ),
    ],
  );
});
