// =============================================================================
// YugmaConnectivityBanner — D-8: animated offline/online indicator.
//
// Shows a slide-down banner with `strings.noInternetShowingCached` when the
// device loses connectivity. Auto-hides when connection restores.
// Uses `theme.shopAccent` background and `theme.bodyDeva` text.
//
// Wired into the ShellRoute scaffold in customer_app router (B-2) above
// the body, below the app bar.
// =============================================================================

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../locale/strings_base.dart';
import '../theme/yugma_theme_extension.dart';

/// Riverpod provider that streams connectivity state.
final connectivityStreamProvider =
    StreamProvider.autoDispose<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// D-8: Animated slide-down banner shown when offline.
class YugmaConnectivityBanner extends ConsumerWidget {
  const YugmaConnectivityBanner({super.key, required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityStreamProvider);
    final theme = context.yugmaTheme;

    final isOffline = connectivityAsync.whenOrNull(
      data: (results) =>
          results.contains(ConnectivityResult.none) || results.isEmpty,
    ) ?? false;

    return AnimatedSlide(
      offset: isOffline ? Offset.zero : const Offset(0, -1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: isOffline ? null : 0,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: theme.shopAccent,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 18,
                color: theme.shopTextOnPrimary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.noInternetShowingCached,
                  style: theme.bodyDeva.copyWith(
                    color: theme.shopTextOnPrimary,
                    fontSize: theme.isElderTier ? 15 : 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
