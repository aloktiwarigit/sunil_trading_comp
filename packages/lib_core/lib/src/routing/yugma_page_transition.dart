// =============================================================================
// YugmaPageTransition — custom page transitions using Workshop Almanac motion.
//
// Uses YugmaMotion.standard curve (easeOutCubic) and YugmaMotion.normal
// duration (280ms) for forward navigation. Provides a consistent, warm
// transition across the entire app instead of default Material transitions.
//
// Per Sprint D-7: Applied via pageBuilder in GoRouter routes.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/tokens.dart';

/// Custom page transition builder for GoRouter routes.
///
/// Usage in router:
/// ```dart
/// GoRoute(
///   path: '/some-path',
///   pageBuilder: (context, state) => YugmaPageTransition.build(
///     child: SomeScreen(),
///     state: state,
///   ),
/// )
/// ```
class YugmaPageTransition {
  YugmaPageTransition._();

  /// Build a CustomTransitionPage with Workshop Almanac motion.
  ///
  /// Forward: fade + subtle slide from right.
  /// Reverse: fade + slide back to right.
  static CustomTransitionPage<T> build<T>({
    required Widget child,
    required GoRouterState state,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: YugmaMotion.normal,
      reverseTransitionDuration: YugmaMotion.normal,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: YugmaMotion.standard,
        );
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.12, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: YugmaMotion.standard,
        ));

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: child,
          ),
        );
      },
    );
  }
}
