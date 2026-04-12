// OnboardingController — orchestrates the first-launch bootstrap.
//
// Sequence (B1.1 AC #3: all silent, no UI step):
//   1. Anonymous auth (if not already signed in from a persisted session)
//   2. ShopThemeTokens fetch from Firestore
//   3. Locale resolution (Remote Config + user preference)
//   4. Signal ready → router transitions splash → BharosaLanding
//
// This is a Riverpod AsyncNotifier so the router can watch its state
// and transition when ready.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';

/// The resolved onboarding state. Contains everything the landing screen
/// needs to render without additional async work.
class OnboardingState {
  const OnboardingState({
    required this.themeTokens,
    required this.strings,
    required this.localeCode,
    required this.user,
    required this.shop,
  });

  /// Loaded ShopThemeTokens for the flagship shop.
  final ShopThemeTokens themeTokens;

  /// Resolved locale strings.
  final AppStrings strings;

  /// Current locale code ('hi' or 'en').
  final String localeCode;

  /// The authenticated user (anonymous or phone-verified).
  final AppUser user;

  /// Shop document — needed for lifecycle state (ADR-013) and
  /// dpdpRetentionUntil (C3.12 FAQ screen).
  final Shop shop;
}

/// Riverpod provider for the onboarding controller.
final onboardingControllerProvider =
    AsyncNotifierProvider<OnboardingController, OnboardingState>(
  OnboardingController.new,
);

/// Locale preference persistence key.
const _localePrefsKey = 'user_locale_override';

class OnboardingController extends AsyncNotifier<OnboardingState> {
  @override
  Future<OnboardingState> build() async {
    final authProvider = ref.read(authProviderInstanceProvider);
    final shopId = ref.read(shopIdProviderProvider).shopId;

    // Step 1: Ensure anonymous auth (B1.1 AC #3 — silent, before splash ends)
    AppUser user;
    final existing = authProvider.currentUser;
    if (existing != null) {
      user = existing;
    } else {
      user = await authProvider.signInAnonymous();
    }

    // Step 2: Fetch Shop document + ShopThemeTokens from Firestore
    final firestore = FirebaseFirestore.instance;
    final shopDoc = await firestore
        .collection('shops')
        .doc(shopId)
        .get();

    final shop = shopDoc.exists && shopDoc.data() != null
        ? Shop.fromJson(shopDoc.data()!)
        : Shop(
            shopId: shopId,
            brandName: 'Sunil Trading Company',
            brandNameDevanagari: 'सुनील ट्रेडिंग कंपनी',
            ownerUid: '',
            market: 'Harringtonganj',
            createdAt: DateTime.now(),
            activeFromDay: DateTime.now(),
          );

    final themeDoc = await firestore
        .collection('shops')
        .doc(shopId)
        .collection('theme')
        .doc('current')
        .get();

    ShopThemeTokens themeTokens;
    if (themeDoc.exists && themeDoc.data() != null) {
      themeTokens = ShopThemeTokens.fromJson(themeDoc.data()!);
    } else {
      // Fallback to compile-time defaults — shop hasn't customized yet
      themeTokens = ShopThemeTokens.sunilTradingCompanyDefault();
    }

    // Step 3: Resolve locale
    final remoteConfig = FirebaseRemoteConfig.instance;
    final prefs = await SharedPreferences.getInstance();
    final userOverride = prefs.getString(_localePrefsKey) ?? '';

    final strings = LocaleResolver.resolve(
      remoteConfig: remoteConfig,
      userOverride: userOverride,
    );
    final localeCode = strings.localeCode;

    return OnboardingState(
      themeTokens: themeTokens,
      strings: strings,
      localeCode: localeCode,
      user: user,
      shop: shop,
    );
  }

  /// Toggle locale between hi/en. Persists to SharedPreferences.
  /// B1.2 AC #7.
  Future<void> toggleLocale() async {
    final current = state.valueOrNull;
    if (current == null) return;

    final newCode = current.localeCode == 'hi' ? 'en' : 'hi';
    final newStrings = LocaleResolver.forCode(newCode);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localePrefsKey, newCode);

    state = AsyncData(OnboardingState(
      themeTokens: current.themeTokens,
      strings: newStrings,
      localeCode: newCode,
      user: current.user,
      shop: current.shop,
    ));
  }

  /// Refresh shop theme tokens from Firestore. B1.2 AC #6.
  Future<void> refreshTheme() async {
    final current = state.valueOrNull;
    if (current == null) return;

    final shopId = ref.read(shopIdProviderProvider).shopId;
    final firestore = FirebaseFirestore.instance;
    final themeDoc = await firestore
        .collection('shops')
        .doc(shopId)
        .collection('theme')
        .doc('current')
        .get();

    ShopThemeTokens themeTokens;
    if (themeDoc.exists && themeDoc.data() != null) {
      themeTokens = ShopThemeTokens.fromJson(themeDoc.data()!);
    } else {
      themeTokens = ShopThemeTokens.sunilTradingCompanyDefault();
    }

    state = AsyncData(OnboardingState(
      themeTokens: themeTokens,
      strings: current.strings,
      localeCode: current.localeCode,
      user: current.user,
      shop: current.shop,
    ));
  }
}
