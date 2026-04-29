// =============================================================================
// Customer app router — GoRouter with onboarding-gated splash → landing.
//
// B1.1 AC #7: "No OTP screen, no 'create account' screen, no 'welcome aboard'
// screen — the first screen IS the shopkeeper."
//
// B-2: ShopkeeperPresenceDock persists on EVERY customer-facing screen.
//   - BharosaLanding embeds the dock in its own body (bharosa_landing.dart).
//   - All other routes are wrapped in a ShellRoute that provides the dock
//     as bottomNavigationBar via a shared Scaffold shell.
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
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lib_core/lib_core.dart';

import 'package:customer_app/features/chat/customer_chat_screen.dart';
import 'package:customer_app/features/onboarding/onboarding_controller.dart';
import 'package:customer_app/features/onboarding/splash_screen.dart';
import 'package:customer_app/features/orders/order_detail_screen.dart';
import 'package:customer_app/features/orders/order_list_screen.dart';
import 'package:customer_app/features/shop/deactivation_banner.dart';
import 'package:customer_app/features/shop/presence_banner.dart';
import 'package:customer_app/features/project/commit_screen.dart';
import 'package:customer_app/features/browse/shortlist_providers.dart';
import 'package:customer_app/features/udhaar/customer_udhaar_screen.dart';
import 'package:customer_app/features/project/draft_controller.dart';
import 'package:customer_app/features/project/draft_list_screen.dart';
import 'package:customer_app/features/project/payment_screen.dart';

/// Wraps a child widget in a fade + subtle slide page transition.
/// Uses YugmaMotion tokens for duration and curve.
CustomTransitionPage<void> _buildTransitionPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.05, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: YugmaMotion.standard,
          )),
          child: child,
        ),
      );
    },
    transitionDuration: YugmaMotion.normal,
  );
}

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

          return Consumer(
            builder: (ctx, innerRef, _) {
              final previews = innerRef
                      .watch(curatedShortlistsPreviewProvider)
                      .valueOrNull ??
                  const [];

              // Featured products for carousel + grid.
              final featuredProducts =
                  innerRef.watch(allActiveSkusProvider).valueOrNull ?? const [];

              // C3.12: Build deactivation banner if shop is not active.
              final lifecycle = data.shop.shopLifecycle;
              Widget? deactivationBanner;
              if (lifecycle != ShopLifecycle.active) {
                deactivationBanner = DeactivationBanner(
                  shopLifecycle: lifecycle,
                  dpdpRetentionUntil: data.shop.dpdpRetentionUntil,
                  strings: data.strings,
                  onFaqTap: () => context.push('/deactivation-faq'),
                );
              }

              // B1.9: Presence banner (defaults to available — hidden).
              final presenceBanner = PresenceBanner(
                presenceStatus: 'available',
                presenceMessage: '',
                strings: data.strings,
              );

              return BharosaLanding(
                onShortlistTap: (occasionTag) {
                  context.push('/shortlist/$occasionTag');
                },
                onGreetingPlay: () {},
                autoPlayGreeting: false,
                onPresenceVoiceNote: () {},
                previewShortlists: previews,
                strings: data.strings,
                hasGreetingVoiceNote:
                    data.themeTokens.greetingVoiceNoteId.isNotEmpty,
                greetingDurationSeconds: 0,
                currentLocaleCode: data.localeCode,
                onLocaleToggle: () {
                  ref
                      .read(onboardingControllerProvider.notifier)
                      .toggleLocale();
                },
                onRefresh: () async {
                  ref.invalidate(curatedShortlistsPreviewProvider);
                  ref.invalidate(allActiveSkusProvider);
                  await ref
                      .read(onboardingControllerProvider.notifier)
                      .refreshTheme();
                },
                onMyListTap: () => context.push('/draft'),
                onOrdersTap: () => context.push('/orders'),
                onUdhaarTap: () => context.push('/udhaar'),
                shopLifecycle: lifecycle.name,
                dpdpRetentionUntil: data.shop.dpdpRetentionUntil,
                onDeactivationFaqTap: () => context.push('/deactivation-faq'),
                presenceStatus: 'available',
                presenceMessage: '',
                deactivationBanner: deactivationBanner,
                presenceBanner: presenceBanner,
                featuredProducts: featuredProducts,
                onProductTap: (skuId) => context.push('/sku/$skuId'),
              );
            },
          );
        },
      ),
      // ─────────────────────────────────────────────────────────────
      // ShellRoute — wraps ALL non-splash/non-landing routes with
      // the ShopkeeperPresenceDock as bottomNavigationBar (B-2).
      // ─────────────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) {
          return Consumer(
            builder: (ctx, shellRef, _) {
              final shellOnboarding =
                  shellRef.watch(onboardingControllerProvider);
              final data = shellOnboarding.valueOrNull;
              if (data == null) return child;
              return Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    Expanded(child: child),
                    ShopkeeperPresenceDock(
                      onVoiceNote: () {},
                      strings: data.strings,
                      onMyListTap: () => context.go('/draft'),
                      onOrdersTap: () => context.go('/orders'),
                      onUdhaarTap: () => context.go('/udhaar'),
                    ),
                  ],
                ),
              );
            },
          );
        },
        routes: <RouteBase>[
          // C3.1 — "My List" draft screen
          GoRoute(
            path: '/draft',
            pageBuilder: (context, state) {
              final data = onboarding.valueOrNull;
              if (data == null) {
                return _buildTransitionPage(
                    key: state.pageKey, child: const SplashScreen());
              }

              return _buildTransitionPage(
                key: state.pageKey,
                child: DraftListScreen(
                  strings: data.strings,
                  onBrowse: () => context.go('/landing'),
                  onTalkToBhaiya: () {
                    // Navigate to chat once a draft project exists.
                    final draftState =
                        ref.read(draftControllerProvider).valueOrNull;
                    final projectId = draftState?.projectId;
                    if (projectId != null) {
                      context.push('/project/$projectId/chat');
                    }
                  },
                  onCommit: () {
                    // C3.4 — Navigate to commit flow.
                    final draftState =
                        ref.read(draftControllerProvider).valueOrNull;
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
            pageBuilder: (context, state) {
              final data = onboarding.valueOrNull;
              if (data == null) {
                return _buildTransitionPage(
                    key: state.pageKey, child: const SplashScreen());
              }

              final projectId = state.pathParameters['id'];
              if (projectId == null) {
                return _buildTransitionPage(
                  key: state.pageKey,
                  child: const Center(child: Text('Missing route parameter')),
                );
              }

              return _buildTransitionPage(
                key: state.pageKey,
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
            pageBuilder: (context, state) {
              final data = onboarding.valueOrNull;
              if (data == null) {
                return _buildTransitionPage(
                    key: state.pageKey, child: const SplashScreen());
              }

              final projectId = state.pathParameters['id'];
              if (projectId == null) {
                return _buildTransitionPage(
                  key: state.pageKey,
                  child: const Center(child: Text('Missing route parameter')),
                );
              }

              return _buildTransitionPage(
                key: state.pageKey,
                child: PaymentScreen(
                  projectId: projectId,
                  strings: data.strings,
                ),
              );
            },
          ),
          // C3.10 — Order list
          GoRoute(
            path: '/orders',
            pageBuilder: (context, state) {
              final data = onboarding.valueOrNull;
              if (data == null) {
                return _buildTransitionPage(
                    key: state.pageKey, child: const SplashScreen());
              }

              return _buildTransitionPage(
                key: state.pageKey,
                child: OrderListScreen(strings: data.strings),
              );
            },
          ),
          // C3.10 — Order detail with state timeline
          GoRoute(
            path: '/orders/:id',
            pageBuilder: (context, state) {
              final data = onboarding.valueOrNull;
              if (data == null) {
                return _buildTransitionPage(
                    key: state.pageKey, child: const SplashScreen());
              }

              final projectId = state.pathParameters['id'];
              if (projectId == null) {
                return _buildTransitionPage(
                  key: state.pageKey,
                  child: const Center(child: Text('Missing route parameter')),
                );
              }

              return _buildTransitionPage(
                key: state.pageKey,
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
            pageBuilder: (context, state) {
              final data = onboarding.valueOrNull;
              if (data == null) {
                return _buildTransitionPage(
                    key: state.pageKey, child: const SplashScreen());
              }

              // CR F6: compute retention days from Shop.dpdpRetentionUntil.
              final retentionUntil = data.shop.dpdpRetentionUntil;
              final retentionDays = retentionUntil != null
                  ? retentionUntil
                      .difference(DateTime.now())
                      .inDays
                      .clamp(0, 999)
                  : 180;

              return _buildTransitionPage(
                key: state.pageKey,
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
            pageBuilder: (context, state) {
              final data = onboarding.valueOrNull;
              if (data == null) {
                return _buildTransitionPage(
                    key: state.pageKey, child: const SplashScreen());
              }

              return _buildTransitionPage(
                key: state.pageKey,
                child: CustomerUdhaarScreen(strings: data.strings),
              );
            },
          ),
          // B1.4 — Curated shortlist screen (per occasion)
          GoRoute(
            path: '/shortlist/:occasionTag',
            pageBuilder: (context, state) {
              final data = onboarding.valueOrNull;
              if (data == null) {
                return _buildTransitionPage(
                    key: state.pageKey, child: const SplashScreen());
              }

              final occasionTag = state.pathParameters['occasionTag'];
              if (occasionTag == null) {
                return _buildTransitionPage(
                  key: state.pageKey,
                  child: const Center(child: Text('Missing route parameter')),
                );
              }

              return _buildTransitionPage(
                key: state.pageKey,
                child: Consumer(
                  builder: (ctx, innerRef, _) {
                    final shortlistAsync = innerRef
                        .watch(curatedShortlistByOccasionProvider(occasionTag));
                    final skusAsync =
                        innerRef.watch(shortlistSkusProvider(occasionTag));

                    final isLoading =
                        shortlistAsync.isLoading || skusAsync.isLoading;
                    final error = shortlistAsync.error ?? skusAsync.error;
                    final theme = context.yugmaTheme;

                    if (isLoading) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: theme.shopAccent,
                        ),
                      );
                    }

                    if (error != null) {
                      return Center(child: Text('$error'));
                    }

                    final shortlist = shortlistAsync.valueOrNull;
                    if (shortlist == null) {
                      return Center(
                        child: Text(
                          data.strings.emptyShortlistNotYetCurated,
                          style: theme.bodyDeva,
                        ),
                      );
                    }
                    return ShortlistScreen(
                      shortlist: shortlist,
                      skus: skusAsync.valueOrNull ?? const [],
                      strings: data.strings,
                      onSkuTap: (sku) {
                        HapticFeedback.lightImpact();
                        context.push('/sku/${sku.skuId}');
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
            pageBuilder: (context, state) {
              final data = onboarding.valueOrNull;
              if (data == null) {
                return _buildTransitionPage(
                    key: state.pageKey, child: const SplashScreen());
              }

              final skuId = state.pathParameters['skuId'];
              if (skuId == null) {
                return _buildTransitionPage(
                  key: state.pageKey,
                  child: const Center(child: Text('Missing route parameter')),
                );
              }

              return _buildTransitionPage(
                key: state.pageKey,
                child: Consumer(
                  builder: (ctx, innerRef, _) {
                    final skuAsync = innerRef.watch(skuByIdProvider(skuId));
                    final theme = context.yugmaTheme;

                    return skuAsync.when(
                      loading: () => Center(
                        child: CircularProgressIndicator(
                          color: theme.shopAccent,
                        ),
                      ),
                      error: (e, _) => Center(child: Text('$e')),
                      data: (sku) {
                        if (sku == null) {
                          return Center(
                            child: Text(
                              data.strings.emptyShortlistNotYetCurated,
                              style: theme.bodyDeva,
                            ),
                          );
                        }
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
                          onAddToList: () async {
                            HapticFeedback.lightImpact();
                            await innerRef
                                .read(draftControllerProvider.notifier)
                                .addSku(sku);
                            if (context.mounted) {
                              context.push('/draft');
                            }
                          },
                          onTalkToBhaiya: () async {
                            HapticFeedback.lightImpact();
                            final draft = innerRef
                                .read(draftControllerProvider)
                                .valueOrNull;
                            final projectId = draft?.projectId;
                            if (projectId != null) {
                              context.push('/project/$projectId/chat');
                            } else {
                              await innerRef
                                  .read(draftControllerProvider.notifier)
                                  .addSku(sku);
                              if (context.mounted) {
                                context.push('/draft');
                              }
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
            pageBuilder: (context, state) {
              final data = onboarding.valueOrNull;
              if (data == null) {
                return _buildTransitionPage(
                    key: state.pageKey, child: const SplashScreen());
              }

              final projectId = state.pathParameters['id'];
              if (projectId == null) {
                return _buildTransitionPage(
                  key: state.pageKey,
                  child: const Center(child: Text('Missing route parameter')),
                );
              }

              return _buildTransitionPage(
                key: state.pageKey,
                child: CustomerChatScreen(
                  projectId: projectId,
                  strings: data.strings,
                ),
              );
            },
          ),
        ],
      ),
    ],
  );
});
