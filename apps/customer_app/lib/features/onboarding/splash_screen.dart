// Splash screen — shown during bootstrap while auth + theme load.
//
// B1.1 AC #2: "splash screen shows the shop logo + tagline"
// B1.1 AC #3: "Anonymous Auth completes silently before splash finishes"
// B1.1 edge case #1: "Devanagari skeleton screen (not a generic spinner)"
//
// This screen renders immediately from compile-time ShopThemeTokens defaults
// (YugmaColors.primary, etc.) and transitions to the BharosaLanding once the
// onboarding controller completes.

import 'package:flutter/material.dart';
import 'package:lib_core/lib_core.dart';

/// Boot splash with Devanagari branding. Shown for <2 seconds while
/// anonymous auth + ShopThemeTokens load in parallel.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(curved);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use compile-time defaults — ShopThemeTokens may not be loaded yet.
    // These are the same sheesham/brass/cream values from tokens.dart.
    return Scaffold(
      backgroundColor: YugmaColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Devanagari-initial circle (same visual vocabulary as D4 fallback)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        YugmaColors.accentGlow,
                        YugmaColors.primary,
                      ],
                    ),
                    border: Border.all(color: YugmaColors.accent, width: 3),
                  ),
                  child: const Center(
                    child: Text(
                      'सु',
                      style: TextStyle(
                        fontFamily: YugmaFonts.devaDisplay,
                        fontSize: 32,
                        color: YugmaColors.textOnPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Shop name — compile-time constant, not from Firestore
                Text(
                  ShopThemeTokens.sunilTradingCompanyDefault().brandName,
                  style: const TextStyle(
                    fontFamily: YugmaFonts.devaDisplay,
                    fontSize: 24,
                    color: YugmaColors.primary,
                    height: YugmaLineHeights.tight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Tagline — uses compile-time default. If empty (Sprint 0
                // discipline), shows nothing.
                Builder(
                  builder: (context) {
                    final tagline = ShopThemeTokens.sunilTradingCompanyDefault()
                        .taglineDevanagari;
                    if (tagline.isEmpty) return const SizedBox.shrink();
                    return Text(
                      tagline,
                      style: const TextStyle(
                        fontFamily: YugmaFonts.devaBody,
                        fontSize: 14,
                        color: YugmaColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
                const SizedBox(height: 32),
                // Devanagari-styled progress indicator (brass accent, not blue)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: YugmaColors.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
