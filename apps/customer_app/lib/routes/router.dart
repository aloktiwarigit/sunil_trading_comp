// =============================================================================
// Customer app router — GoRouter with onboarding-gated splash → landing.
//
// B1.1 AC #7: "No OTP screen, no 'create account' screen, no 'welcome aboard'
// screen — the first screen IS the shopkeeper."
//
// B-2: ShopkeeperPresenceDock persists on EVERY customer-facing screen.
//   - BharosaLanding embeds the dock in its own body (bharosa_landing.dart:181).
//   - Other routes get the dock via their Scaffold's bottomNavigationBar.
//   - _dockFor() helper builds the dock with wired callbacks.
//
// Route structure:
//   /                       → Splash (while onboarding loads) → redirects to /landing
//   /landing                → BharosaLanding (dock built-in)
//   /draft                  → DraftListScreen + dock
//   /project/:id/commit     → CommitScreen + dock
//   /project/:id/payment    → PaymentScreen + dock
//   /project/:id/chat       → CustomerChatScreen + dock
//   /orders                 → OrderListScreen + dock
//   /orders/:id             → OrderDetailScreen + dock
//   /deactivation-faq       → DeactivationFaqScreen + dock
//   /udhaar                 → CustomerUdhaarScreen + dock
//   /shortlist/:tag         → ShortlistScreen + dock
//   /sku/:skuId             → SkuDetailCard + dock
//
// Deep link handling (B1.1 edge cases #3, #4):
//   /project/:projectId → bypass landing, go to Project view (future sprint)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lib_core/lib_core.dart';

import 'package:customer_app/features/chat/customer_chat_screen.dart';
import 'package:customer_app/features/onboarding/onboarding_controller.dart';
import 'package:customer_app/features/onboarding/splash_screen.dart';
import 'package:customer_app/features/orders/order_detail_screen.dart';
import 'package:customer_app/features/orders/order_list_screen.dart';
import 'package:customer_app/features/shop/deactivation_banner.dart';
import 'package:customer_app/features/project/commit_screen.dart';
import 'package:customer_app/features/browse/shortlist_providers.dart';
import 'package:customer_app/features/udhaar/customer_udhaar_screen.dart';
import 'package:customer_app/features/project/draft_controller.dart';
import 'package:customer_app/features/project/draft_list_screen.dart';
import 'package:customer_app/features/project/payment_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final onboarding = ref.watch(onboardingControllerProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoading = onboarding.isLoading;
      final hasError = onboarding.hasError;
      final isReady = !isLoading && !hasError && onboarding.hasValue;
      final isOnSplash = state.matchedLocation == '/';
      final isOnLanding = state.matchedLocation == '/landing';

      // Guard: block navigation to /landing before data is ready
      // (code review blocker #2 — prevents deeplink bypass)
      if (!isReady && isOnLanding) return '/';

      // While loading or error, stay on splash
      if (!isReady && isOnSplash) return null;

      // Once loaded, redirect splash → landing
      if (isReady && isOnSplash) return '/landing';

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

          // BharosaLanding already embeds ShopkeeperPresenceDock + its own
          // Scaffold. Just provide Theme wrapper.
          return Theme(
            data: ThemeData(
              useMaterial3: true,
              extensions: [theme],
            ),
            child: Consumer(
              builder: (ctx, innerRef, _) {
                final previews = innerRef
                    .watch(curatedShortlistsPreviewProvider)
                    .valueOrNull ?? const [];

                return BharosaLanding(
                  onShortlistTap: (occasionTag) {
                    context.push('/shortlist/$occasionTag');
                  },
                  onGreetingPlay: () {
                    // TODO(sprint-B4): wire audio playback via just_audio
                  },
                  autoPlayGreeting: true,
                  onPresenceVoiceNote: () {
                    // TODO(sprint-B4): wire presence dock voice note
                  },
                  previewShortlists: previews,
                  strings: data.strings,
                  hasGreetingVoiceNote:
                      data.themeTokens.greetingVoiceNoteId.isNotEmpty,
                  greetingDurationSeconds: 0,
                  // TODO(sprint-B4): fetch voice note metadata for duration
                  currentLocaleCode: data.localeCode,
                  onLocaleToggle: () {
                    ref.read(onboardingControllerProvider.notifier).toggleLocale();
                  },
                  onRefresh: () async {
                    await ref
                        .read(onboardingControllerProvider.notifier)
                        .refreshTheme();
                  },
                  // B-2: wire dock navigation
                  onMyListTap: () => context.push('/draft'),
                  onOrdersTap: () => context.push('/orders'),
                );
              },
            ),
          );
        },
      ),
      // C3.1 — "My List" draft screen
      GoRoute(
        path: '/draft',
        builder: (context, state) {
          final data = onboarding.valueOrNull;
          if (data == null) return const SplashScreen();

          final theme = YugmaThemeExtension.fromTokens(data.themeTokens);

          return Theme(
            data: ThemeData(
              useMaterial3: true,
              extensions: [theme],
            ),
            child: DraftListScreen(
              strings: data.strings,
              onBrowse: () => context.go('/landing'),
              onTalkToBhaiya: () {
                // Navigate to chat once a draft project exists.
                final draftState = ref.read(draftControllerProvider).valueOrNull;
                final projectId = draftState?.projectId;
                if (projectId != null) {
                  context.push('/project/$projectId/chat');
                }
              },
              onCommit: () {
                // C3.4 — Navigate to commit flow.
                final draftState = ref.read(draftControllerProvider).valueOrNull;
                final projectId = draftState?.projectId;
                if (projectId != null) {
                  context.push('/project/$projectId/commit');
                }
              },
            ),
          );
        },
      ),
      // C3.4 — Commit flow screen
      GoRoute(
        path: '/project/:id/commit',
        builder: (context, state) {
          final data = onboarding.valueOrNull;
          if (data == null) return const SplashScreen();

          final projectId = state.pathParameters['id'];
          if (projectId == null) {
            return const Scaffold(body: Center(child: Text('Missing route parameter')));
          }
          final theme = YugmaThemeExtension.fromTokens(data.themeTokens);

          return Theme(
            data: ThemeData(
              useMaterial3: true,
              extensions: [theme],
            ),
            child: CommitScreen(
              projectId: projectId,
              strings: data.strings,
            ),
          );
        },
      ),
      // C3.5 — Payment flow screen
      GoRoute(
        path: '/project/:id/payment',
        builder: (context, state) {
          final data = onboarding.valueOrNull;
          if (data == null) return const SplashScreen();

          final projectId = state.pathParameters['id'];
          if (projectId == null) {
            return const Scaffold(body: Center(child: Text('Missing route parameter')));
          }
          final theme = YugmaThemeExtension.fromTokens(data.themeTokens);

          return Theme(
            data: ThemeData(
              useMaterial3: true,
              extensions: [theme],
            ),
            child: PaymentScreen(
              projectId: projectId,
              strings: data.strings,
            ),
          );
        },
      ),
      // C3.10 — Order list ("मेरे ऑर्डर")
      GoRoute(
        path: '/orders',
        builder: (context, state) {
          final data = onboarding.valueOrNull;
          if (data == null) return const SplashScreen();

          final theme = YugmaThemeExtension.fromTokens(data.themeTokens);

          return Theme(
            data: ThemeData(
              useMaterial3: true,
              extensions: [theme],
            ),
            child: OrderListScreen(strings: data.strings),
          );
        },
      ),
      // C3.10 — Order detail with state timeline
      GoRoute(
        path: '/orders/:id',
        builder: (context, state) {
          final data = onboarding.valueOrNull;
          if (data == null) return const SplashScreen();

          final projectId = state.pathParameters['id'];
          if (projectId == null) {
            return const Scaffold(body: Center(child: Text('Missing route parameter')));
          }
          final theme = YugmaThemeExtension.fromTokens(data.themeTokens);

          return Theme(
            data: ThemeData(
              useMaterial3: true,
              extensions: [theme],
            ),
            child: OrderDetailScreen(
              projectId: projectId,
              strings: data.strings,
            ),
          );
        },
      ),
      // C3.12 — Shop deactivation FAQ screen
      GoRoute(
        path: '/deactivation-faq',
        builder: (context, state) {
          final data = onboarding.valueOrNull;
          if (data == null) return const SplashScreen();

          final theme = YugmaThemeExtension.fromTokens(data.themeTokens);
          // CR F6: compute retention days from Shop.dpdpRetentionUntil.
          // Default to 180 if the field is null (shop is active, not deactivating).
          final retentionUntil = data.shop.dpdpRetentionUntil;
          final retentionDays = retentionUntil != null
              ? retentionUntil.difference(DateTime.now()).inDays.clamp(0, 999)
              : 180;

          return Theme(
            data: ThemeData(
              useMaterial3: true,
              extensions: [theme],
            ),
            child: DeactivationFaqScreen(
              strings: data.strings,
              retentionDays: retentionDays,
            ),
          );
        },
      ),
      // B-5 — Customer udhaar balance view (read-only)
      GoRoute(
        path: '/udhaar',
        builder: (context, state) {
          final data = onboarding.valueOrNull;
          if (data == null) return const SplashScreen();

          final theme = YugmaThemeExtension.fromTokens(data.themeTokens);

          return Theme(
            data: ThemeData(
              useMaterial3: true,
              extensions: [theme],
            ),
            child: CustomerUdhaarScreen(strings: data.strings),
          );
        },
      ),
      // B1.4 — Curated shortlist screen (per occasion)
      GoRoute(
        path: '/shortlist/:occasionTag',
        builder: (context, state) {
          final data = onboarding.valueOrNull;
          if (data == null) return const SplashScreen();

          final occasionTag = state.pathParameters['occasionTag'];
          if (occasionTag == null) {
            return const Scaffold(body: Center(child: Text('Missing route parameter')));
          }
          final theme = YugmaThemeExtension.fromTokens(data.themeTokens);

          return Theme(
            data: ThemeData(
              useMaterial3: true,
              extensions: [theme],
            ),
            child: Consumer(
              builder: (ctx, innerRef, _) {
                final shortlistAsync =
                    innerRef.watch(curatedShortlistByOccasionProvider(occasionTag));
                final skusAsync =
                    innerRef.watch(shortlistSkusProvider(occasionTag));

                return shortlistAsync.when(
                  loading: () => Scaffold(
                    backgroundColor: theme.shopBackground,
                    body: Center(
                      child: CircularProgressIndicator(
                        color: theme.shopAccent,
                      ),
                    ),
                  ),
                  error: (e, _) => Scaffold(
                    backgroundColor: theme.shopBackground,
                    body: Center(child: Text('$e')),
                  ),
                  data: (shortlist) {
                    if (shortlist == null) {
                      return Scaffold(
                        backgroundColor: theme.shopBackground,
                        appBar: AppBar(
                          backgroundColor: theme.shopPrimary,
                          foregroundColor: theme.shopTextOnPrimary,
                        ),
                        body: Center(
                          child: Text(
                            data.strings.emptyShortlistNotYetCurated,
                            style: theme.bodyDeva,
                          ),
                        ),
                      );
                    }
                    return ShortlistScreen(
                      shortlist: shortlist,
                      skus: skusAsync.valueOrNull ?? const [],
                      strings: data.strings,
                      onSkuTap: (sku) => context.push('/sku/${sku.skuId}'),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      // B1.5 — SKU detail screen
      GoRoute(
        path: '/sku/:skuId',
        builder: (context, state) {
          final data = onboarding.valueOrNull;
          if (data == null) return const SplashScreen();

          final skuId = state.pathParameters['skuId'];
          if (skuId == null) {
            return const Scaffold(body: Center(child: Text('Missing route parameter')));
          }
          final theme = YugmaThemeExtension.fromTokens(data.themeTokens);

          return Theme(
            data: ThemeData(
              useMaterial3: true,
              extensions: [theme],
            ),
            child: Consumer(
              builder: (ctx, innerRef, _) {
                final skuAsync = innerRef.watch(skuByIdProvider(skuId));

                return skuAsync.when(
                  loading: () => Scaffold(
                    backgroundColor: theme.shopBackground,
                    body: Center(
                      child: CircularProgressIndicator(
                        color: theme.shopAccent,
                      ),
                    ),
                  ),
                  error: (e, _) => Scaffold(
                    backgroundColor: theme.shopBackground,
                    body: Center(child: Text('$e')),
                  ),
                  data: (sku) {
                    if (sku == null) {
                      return Scaffold(
                        backgroundColor: theme.shopBackground,
                        body: Center(
                          child: Text(
                            data.strings.emptyShortlistNotYetCurated,
                            style: theme.bodyDeva,
                          ),
                        ),
                      );
                    }
                    // Resolve photo URLs from SKU model.
                    final goldenHourUrl = sku.fallbackPhotoUrls.isNotEmpty
                        ? sku.fallbackPhotoUrls.first
                        : '';
                    final workingUrl = sku.fallbackPhotoUrls.length > 1
                        ? sku.fallbackPhotoUrls[1]
                        : null;

                    return SkuDetailCard(
                      sku: sku,
                      strings: data.strings,
                      goldenHourPhotoUrl: goldenHourUrl,
                      workingLightPhotoUrl: workingUrl,
                      onAddToList: () {
                        // C3.1: Add SKU to draft list and navigate.
                        innerRef
                            .read(draftControllerProvider.notifier)
                            .addSku(sku);
                        context.push('/draft');
                      },
                      onTalkToBhaiya: () {
                        // Navigate to chat — first ensure a draft exists.
                        final draft = innerRef
                            .read(draftControllerProvider)
                            .valueOrNull;
                        final projectId = draft?.projectId;
                        if (projectId != null) {
                          context.push('/project/$projectId/chat');
                        } else {
                          // Add to draft first, then navigate.
                          innerRef
                              .read(draftControllerProvider.notifier)
                              .addSku(sku);
                          // Draft creation is async — navigate to draft list.
                          context.push('/draft');
                        }
                      },
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      // P2.4 + P2.5 — Chat thread screen
      GoRoute(
        path: '/project/:id/chat',
        builder: (context, state) {
          final data = onboarding.valueOrNull;
          if (data == null) return const SplashScreen();

          final projectId = state.pathParameters['id'];
          if (projectId == null) {
            return const Scaffold(body: Center(child: Text('Missing route parameter')));
          }
          final theme = YugmaThemeExtension.fromTokens(data.themeTokens);

          return Theme(
            data: ThemeData(
              useMaterial3: true,
              extensions: [theme],
            ),
            child: CustomerChatScreen(
              projectId: projectId,
              strings: data.strings,
            ),
          );
        },
      ),
    ],
  );
});
