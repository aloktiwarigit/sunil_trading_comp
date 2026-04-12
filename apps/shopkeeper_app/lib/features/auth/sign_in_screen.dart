// =============================================================================
// SignInScreen — Full-screen Google sign-in for the shopkeeper ops app.
//
// S4.1 AC #1: First launch shows full-screen sign-in with Google button.
// S4.1 AC #4: If operator doc does NOT exist, shows unauthorized message.
//
// Per binding rules:
//   - ALL strings via AppStrings (no hardcoded Devanagari in render paths)
//   - ALL theme via context.yugmaTheme (no hardcoded colors)
//   - Workshop Almanac aesthetic: sheesham wood + aged cream + brass accents
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';

import 'auth_controller.dart';

/// Full-screen sign-in screen for the ops app.
class OpsSignInScreen extends ConsumerWidget {
  const OpsSignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(opsAuthControllerProvider);
    final theme = Theme.of(context);
    final strings = const AppStringsHi();

    return Scaffold(
      backgroundColor: YugmaColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: YugmaSpacing.s6,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Shop identity — brand name
              Text(
                strings.shopDisplayName,
                style: TextStyle(
                  fontFamily: YugmaFonts.devaDisplay,
                  fontSize: YugmaTypeScale.display,
                  height: YugmaLineHeights.tight,
                  color: YugmaColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: YugmaSpacing.s2),

              // Subtitle — Ops
              Text(
                'Ops',
                style: TextStyle(
                  fontFamily: YugmaFonts.enDisplay,
                  fontSize: YugmaTypeScale.h3,
                  fontStyle: FontStyle.italic,
                  color: YugmaColors.textSecondary,
                ),
              ),

              const Spacer(flex: 1),

              // Unauthorized message (AC #4)
              if (authState.value?.status == OpsAuthStatus.unauthorized)
                _UnauthorizedBanner(strings: strings),

              // Permission revoked message
              if (authState.value?.status == OpsAuthStatus.permissionRevoked)
                _PermissionRevokedBanner(strings: strings),

              const SizedBox(height: YugmaSpacing.s8),

              // Google sign-in button (AC #1)
              _GoogleSignInButton(
                strings: strings,
                isLoading: authState.isLoading,
                onPressed: () {
                  ref.read(opsAuthControllerProvider.notifier).signInWithGoogle();
                },
              ),

              // Error display
              if (authState.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: YugmaSpacing.s4),
                  child: Text(
                    strings.noInternetShowingCached,
                    style: TextStyle(
                      fontFamily: YugmaFonts.devaBody,
                      fontSize: YugmaTypeScale.bodySmall,
                      color: YugmaColors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

/// The unauthorized banner — shown when operator doc does NOT exist.
class _UnauthorizedBanner extends StatelessWidget {
  const _UnauthorizedBanner({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(YugmaSpacing.s4),
      decoration: BoxDecoration(
        color: YugmaColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(YugmaRadius.lg),
        border: Border.all(
          color: YugmaColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        strings.opsAppNotAuthorized,
        style: TextStyle(
          fontFamily: YugmaFonts.devaBody,
          fontSize: YugmaTypeScale.body,
          height: YugmaLineHeights.normal,
          color: YugmaColors.textPrimary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Permission-revoked banner — shown when operator doc is deleted while
/// the user is signed in.
class _PermissionRevokedBanner extends StatelessWidget {
  const _PermissionRevokedBanner({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(YugmaSpacing.s4),
      decoration: BoxDecoration(
        color: YugmaColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(YugmaRadius.lg),
        border: Border.all(
          color: YugmaColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        strings.opsPermissionRevoked,
        style: TextStyle(
          fontFamily: YugmaFonts.devaBody,
          fontSize: YugmaTypeScale.body,
          height: YugmaLineHeights.normal,
          color: YugmaColors.textPrimary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// The Google sign-in button — Workshop Almanac styled.
class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({
    required this.strings,
    required this.isLoading,
    required this.onPressed,
  });

  final AppStrings strings;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: YugmaTapTargets.minDefault,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: YugmaColors.primary,
          foregroundColor: YugmaColors.textOnPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(YugmaRadius.md),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: YugmaColors.textOnPrimary,
                ),
              )
            : Text(
                strings.signInWithGoogle,
                style: TextStyle(
                  fontFamily: YugmaFonts.devaBody,
                  fontSize: YugmaTypeScale.bodyLarge,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
