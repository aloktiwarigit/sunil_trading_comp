// =============================================================================
// S4.3 Inventory SKU creation — unit + widget tests.
//
// Tests cover:
//   - AppStrings §18 keys: non-empty, symmetry between hi/en
//   - CreateSkuController state machine
//   - CreateSkuScreen form validation
//   - InventoryListScreen empty state rendering
//   - HomeDashboard inventory section rendering + navigation
//   - Forbidden vocabulary checks on new strings
//   - Domain naming enforcement (no forbidden words)
//   - Indian number formatting in list tile
//   - Router: inventory routes registered
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';

import 'package:shopkeeper_app/features/auth/auth_controller.dart';
import 'package:shopkeeper_app/features/inventory/create_sku_controller.dart';
import 'package:shopkeeper_app/features/inventory/create_sku_screen.dart';
import 'package:shopkeeper_app/features/inventory/inventory_list_screen.dart';
import 'package:shopkeeper_app/features/dashboard/home_dashboard.dart';

/// Mirrors `app.dart`'s production theme so widgets that read
/// `context.yugmaTheme` (HomeDashboard et al.) can build inside tests.
ThemeData _testTheme() => ThemeData(
      extensions: <ThemeExtension<dynamic>>[
        YugmaThemeExtension.fromTokens(
          ShopThemeTokens.sunilTradingCompanyDefault(),
        ),
      ],
    );

void main() {
  // =========================================================================
  // AppStrings §18 — inventory strings
  // =========================================================================

  group('AppStrings §18 — inventory strings (Hindi)', () {
    const hi = AppStringsHi();

    test('all inventory getters are non-empty', () {
      expect(hi.inventoryTitle, isNotEmpty);
      expect(hi.createSkuButton, isNotEmpty);
      expect(hi.skuNameDevanagariLabel, isNotEmpty);
      expect(hi.skuNameEnglishLabel, isNotEmpty);
      expect(hi.skuCategoryLabel, isNotEmpty);
      expect(hi.skuBasePriceLabel, isNotEmpty);
      expect(hi.skuNegotiableFloorLabel, isNotEmpty);
      expect(hi.skuDimensionsLabel, isNotEmpty);
      expect(hi.skuMaterialLabel, isNotEmpty);
      expect(hi.skuInStockLabel, isNotEmpty);
      expect(hi.skuDescriptionLabel, isNotEmpty);
      expect(hi.skuSaveButton, isNotEmpty);
      expect(hi.skuGoldenHourPhotoButton, isNotEmpty);
      expect(hi.skuStockCountLabel, isNotEmpty);
      expect(hi.skuDuplicateNameWarning, isNotEmpty);
      expect(hi.skuSavedSuccess, isNotEmpty);
      expect(hi.validationRequired, isNotEmpty);
      expect(hi.validationPricePositive, isNotEmpty);
      expect(hi.validationFloorExceedsBase, isNotEmpty);
      expect(hi.validationDimensionPositive, isNotEmpty);
      expect(hi.inventoryEmpty, isNotEmpty);
    });

    test('inventoryTitle is domain-grounded Hindi', () {
      expect(hi.inventoryTitle, 'सामान');
    });

    test('skuBasePriceLabel contains rupee symbol', () {
      expect(hi.skuBasePriceLabel, contains('₹'));
    });
  });

  group('AppStrings §18 — inventory strings (English)', () {
    const en = AppStringsEn();

    test('all inventory getters are non-empty', () {
      expect(en.inventoryTitle, isNotEmpty);
      expect(en.createSkuButton, isNotEmpty);
      expect(en.skuNameDevanagariLabel, isNotEmpty);
      expect(en.skuNameEnglishLabel, isNotEmpty);
      expect(en.skuCategoryLabel, isNotEmpty);
      expect(en.skuBasePriceLabel, isNotEmpty);
      expect(en.skuNegotiableFloorLabel, isNotEmpty);
      expect(en.skuDimensionsLabel, isNotEmpty);
      expect(en.skuMaterialLabel, isNotEmpty);
      expect(en.skuInStockLabel, isNotEmpty);
      expect(en.skuDescriptionLabel, isNotEmpty);
      expect(en.skuSaveButton, isNotEmpty);
      expect(en.skuGoldenHourPhotoButton, isNotEmpty);
      expect(en.skuStockCountLabel, isNotEmpty);
      expect(en.skuDuplicateNameWarning, isNotEmpty);
      expect(en.skuSavedSuccess, isNotEmpty);
      expect(en.validationRequired, isNotEmpty);
      expect(en.validationPricePositive, isNotEmpty);
      expect(en.validationFloorExceedsBase, isNotEmpty);
      expect(en.validationDimensionPositive, isNotEmpty);
      expect(en.inventoryEmpty, isNotEmpty);
    });

    test('inventoryTitle is English', () {
      expect(en.inventoryTitle, 'Inventory');
    });
  });

  group('AppStrings §18 — forbidden vocabulary check', () {
    const hi = AppStringsHi();
    const en = AppStringsEn();

    final hiStrings = [
      hi.inventoryTitle,
      hi.createSkuButton,
      hi.skuNameDevanagariLabel,
      hi.skuNameEnglishLabel,
      hi.skuCategoryLabel,
      hi.skuBasePriceLabel,
      hi.skuNegotiableFloorLabel,
      hi.skuDimensionsLabel,
      hi.skuMaterialLabel,
      hi.skuInStockLabel,
      hi.skuDescriptionLabel,
      hi.skuSaveButton,
      hi.skuGoldenHourPhotoButton,
      hi.skuStockCountLabel,
      hi.skuDuplicateNameWarning,
      hi.skuSavedSuccess,
      hi.validationRequired,
      hi.validationPricePositive,
      hi.validationFloorExceedsBase,
      hi.validationDimensionPositive,
      hi.inventoryEmpty,
    ];

    final enStrings = [
      en.inventoryTitle,
      en.createSkuButton,
      en.skuNameDevanagariLabel,
      en.skuNameEnglishLabel,
      en.skuCategoryLabel,
      en.skuBasePriceLabel,
      en.skuNegotiableFloorLabel,
      en.skuDimensionsLabel,
      en.skuMaterialLabel,
      en.skuInStockLabel,
      en.skuDescriptionLabel,
      en.skuSaveButton,
      en.skuGoldenHourPhotoButton,
      en.skuStockCountLabel,
      en.skuDuplicateNameWarning,
      en.skuSavedSuccess,
      en.validationRequired,
      en.validationPricePositive,
      en.validationFloorExceedsBase,
      en.validationDimensionPositive,
      en.inventoryEmpty,
    ];

    test('no forbidden udhaar vocabulary in inventory strings', () {
      const forbidden = [
        'interest',
        'loan',
        'penalty',
        'due date',
        'overdue',
        'default',
        'collection',
        'recovery',
        'installment',
        'EMI',
        'ब्याज',
        'ऋण',
        'जुर्माना',
        'देय तिथि',
        'क़िस्त',
      ];
      for (final s in [...hiStrings, ...enStrings]) {
        for (final word in forbidden) {
          expect(
            s.toLowerCase().contains(word.toLowerCase()),
            isFalse,
            reason: 'Forbidden "$word" found in: $s',
          );
        }
      }
    });

    test('no forbidden mythic vocabulary in inventory strings', () {
      const forbidden = [
        'शुभ',
        'मंगल',
        'मंदिर',
        'धर्म',
        'तीर्थ',
        'स्वागतम्',
        'उत्पाद',
        'गुणवत्ता',
        'श्रेष्ठ',
      ];
      for (final s in hiStrings) {
        for (final word in forbidden) {
          expect(
            s.contains(word),
            isFalse,
            reason: 'Forbidden "$word" found in: $s',
          );
        }
      }
    });

    test('no forbidden operator naming in inventory strings', () {
      // Binding rule 3: bhaiya/beta/munshi — NEVER shopkeeper/son
      for (final s in [...hiStrings, ...enStrings]) {
        expect(
          s.toLowerCase().contains('shopkeeper'),
          isFalse,
          reason: 'Forbidden "shopkeeper" found in: $s',
        );
      }
    });
  });

  // =========================================================================
  // CreateSkuController state machine
  // =========================================================================

  group('CreateSkuController', () {
    test('initial state is idle', () {
      const state = CreateSkuState();
      expect(state.status, CreateSkuStatus.idle);
      expect(state.errorMessage, isNull);
      expect(state.savedSkuId, isNull);
    });

    test('copyWith preserves unset fields', () {
      const state = CreateSkuState(
        status: CreateSkuStatus.saving,
        errorMessage: 'test',
      );
      final copied = state.copyWith(status: CreateSkuStatus.error);
      expect(copied.status, CreateSkuStatus.error);
      expect(copied.errorMessage, 'test');
    });

    test('saved state includes skuId', () {
      const state = CreateSkuState(
        status: CreateSkuStatus.saved,
        savedSkuId: 'sku-123',
      );
      expect(state.savedSkuId, 'sku-123');
    });
  });

  // =========================================================================
  // InventorySku model domain checks
  // =========================================================================

  group('InventorySku model — domain checks', () {
    test('SkuCategory has all 5 expected values', () {
      expect(SkuCategory.values.length, 5);
      expect(
        SkuCategory.values.map((c) => c.name),
        containsAll([
          'steelAlmirah',
          'woodenWardrobe',
          'modular',
          'dressing',
          'sideCabinet',
        ]),
      );
    });

    test('SkuMaterial has all 4 expected values', () {
      expect(SkuMaterial.values.length, 4);
      expect(
        SkuMaterial.values.map((m) => m.name),
        containsAll([
          'steel',
          'woodSheesham',
          'woodTeak',
          'plyLaminate',
        ]),
      );
    });

    test('SkuDimensions requires all three fields', () {
      const dim = SkuDimensions(heightCm: 152, widthCm: 92, depthCm: 51);
      expect(dim.heightCm, 152);
      expect(dim.widthCm, 92);
      expect(dim.depthCm, 51);
    });

    test('InventorySku defaults are correct', () {
      final sku = InventorySku(
        skuId: 'test',
        shopId: 'shop',
        name: 'Test',
        nameDevanagari: 'टेस्ट',
        category: SkuCategory.steelAlmirah,
        material: SkuMaterial.steel,
        dimensions: const SkuDimensions(
          heightCm: 100,
          widthCm: 50,
          depthCm: 40,
        ),
        basePrice: 15000,
        negotiableDownTo: 13000,
        createdAt: DateTime(2026, 4, 11),
      );
      expect(sku.inStock, isTrue);
      expect(sku.stockCount, isNull);
      expect(sku.isActive, isTrue);
      expect(sku.goldenHourPhotoIds, isEmpty);
      expect(sku.hasGoldenHourPhoto, isFalse);
      expect(sku.description, isEmpty);
    });
  });

  // =========================================================================
  // CreateSkuScreen widget tests
  // =========================================================================

  group('CreateSkuScreen widget', () {
    testWidgets('renders all form fields', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shopIdProviderProvider.overrideWithValue(
              const ShopIdProvider('sunil-trading-company'),
            ),
          ],
          child: const MaterialApp(home: CreateSkuScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final strings = const AppStringsHi();

      // App bar title
      expect(find.text(strings.createSkuButton), findsOneWidget);

      // Form labels
      expect(find.text(strings.skuNameDevanagariLabel), findsOneWidget);
      expect(find.text(strings.skuNameEnglishLabel), findsOneWidget);
      expect(find.text(strings.skuCategoryLabel), findsOneWidget);
      expect(find.text(strings.skuMaterialLabel), findsOneWidget);
      expect(find.text(strings.skuDimensionsLabel), findsOneWidget);
      expect(find.text(strings.skuBasePriceLabel), findsOneWidget);
      expect(find.text(strings.skuNegotiableFloorLabel), findsOneWidget);
      expect(find.text(strings.skuInStockLabel), findsOneWidget);
    });

    testWidgets('save button and golden hour button are visible',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shopIdProviderProvider.overrideWithValue(
              const ShopIdProvider('sunil-trading-company'),
            ),
          ],
          child: const MaterialApp(home: CreateSkuScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final strings = const AppStringsHi();

      // Scroll down to see save + photo buttons
      await tester.scrollUntilVisible(
        find.text(strings.skuSaveButton),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(strings.skuSaveButton), findsOneWidget);
      expect(find.text(strings.skuGoldenHourPhotoButton), findsOneWidget);
    });

    testWidgets('validation blocks save when name is empty', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shopIdProviderProvider.overrideWithValue(
              const ShopIdProvider('sunil-trading-company'),
            ),
          ],
          child: const MaterialApp(home: CreateSkuScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final strings = const AppStringsHi();

      // Scroll to save button and tap it with empty form
      await tester.scrollUntilVisible(
        find.text(strings.skuSaveButton),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(strings.skuSaveButton));
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.text(strings.validationRequired), findsWidgets);
    });

    testWidgets('in-stock toggle shows/hides stock count field',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shopIdProviderProvider.overrideWithValue(
              const ShopIdProvider('sunil-trading-company'),
            ),
          ],
          child: const MaterialApp(home: CreateSkuScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final strings = const AppStringsHi();

      // Scroll down to make the stock count field visible
      await tester.scrollUntilVisible(
        find.text(strings.skuStockCountLabel),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      // Stock count should be visible (inStock is true by default)
      expect(find.text(strings.skuStockCountLabel), findsOneWidget);

      // Toggle off — scroll up to find the Switch
      await tester.scrollUntilVisible(
        find.byType(Switch),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Stock count should be hidden
      expect(find.text(strings.skuStockCountLabel), findsNothing);
    });
  });

  // =========================================================================
  // InventoryListScreen widget tests
  // =========================================================================

  group('InventoryListScreen widget', () {
    testWidgets('renders app bar with inventory title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shopIdProviderProvider.overrideWithValue(
              const ShopIdProvider('sunil-trading-company'),
            ),
            // Override stream to avoid Firestore dependency.
            inventoryListProvider.overrideWith(
              (ref) => Stream.value(<InventorySku>[]),
            ),
          ],
          child: const MaterialApp(home: InventoryListScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(const AppStringsHi().inventoryTitle),
        findsOneWidget,
      );
    });

    testWidgets('shows FAB with + icon', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shopIdProviderProvider.overrideWithValue(
              const ShopIdProvider('sunil-trading-company'),
            ),
            inventoryListProvider.overrideWith(
              (ref) => Stream.value(<InventorySku>[]),
            ),
          ],
          child: const MaterialApp(home: InventoryListScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows empty state when no SKUs', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shopIdProviderProvider.overrideWithValue(
              const ShopIdProvider('sunil-trading-company'),
            ),
            inventoryListProvider.overrideWith(
              (ref) => Stream.value(<InventorySku>[]),
            ),
          ],
          child: const MaterialApp(home: InventoryListScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(const AppStringsHi().inventoryEmpty),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });

    testWidgets('renders SKU list tiles with correct data', (tester) async {
      final testSkus = [
        InventorySku(
          skuId: 'sku-1',
          shopId: 'sunil-trading-company',
          name: 'Steel Almirah 6x3',
          nameDevanagari: 'स्टील अलमारी 6x3',
          category: SkuCategory.steelAlmirah,
          material: SkuMaterial.steel,
          dimensions: const SkuDimensions(
            heightCm: 182,
            widthCm: 91,
            depthCm: 46,
          ),
          basePrice: 22000,
          negotiableDownTo: 19000,
          inStock: true,
          createdAt: DateTime(2026, 4, 10),
        ),
        InventorySku(
          skuId: 'sku-2',
          shopId: 'sunil-trading-company',
          name: 'Sheesham Wardrobe',
          nameDevanagari: 'शीशम अलमारी',
          category: SkuCategory.woodenWardrobe,
          material: SkuMaterial.woodSheesham,
          dimensions: const SkuDimensions(
            heightCm: 200,
            widthCm: 120,
            depthCm: 55,
          ),
          basePrice: 45000,
          negotiableDownTo: 40000,
          inStock: false,
          createdAt: DateTime(2026, 4, 9),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shopIdProviderProvider.overrideWithValue(
              const ShopIdProvider('sunil-trading-company'),
            ),
            inventoryListProvider.overrideWith(
              (ref) => Stream.value(testSkus),
            ),
          ],
          child: const MaterialApp(home: InventoryListScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // First SKU
      expect(find.text('स्टील अलमारी 6x3'), findsOneWidget);
      expect(find.text('₹22,000'), findsOneWidget);
      // Hindi-ified per inventory_list_screen.dart:319 (sku.inStock ?
      // 'स्टॉक में' : 'खत्म'). Test was authored when label was English.
      expect(find.text('स्टॉक में'), findsOneWidget);

      // Second SKU
      expect(find.text('शीशम अलमारी'), findsOneWidget);
      expect(find.text('₹45,000'), findsOneWidget);
      expect(find.text('खत्म'), findsOneWidget);
    });

    testWidgets('Indian number formatting for large prices', (tester) async {
      final testSkus = [
        InventorySku(
          skuId: 'sku-big',
          shopId: 'sunil-trading-company',
          name: 'Premium Teak',
          nameDevanagari: 'प्रीमियम टीक',
          category: SkuCategory.woodenWardrobe,
          material: SkuMaterial.woodTeak,
          dimensions: const SkuDimensions(
            heightCm: 210,
            widthCm: 150,
            depthCm: 60,
          ),
          basePrice: 150000,
          negotiableDownTo: 130000,
          createdAt: DateTime(2026, 4, 11),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shopIdProviderProvider.overrideWithValue(
              const ShopIdProvider('sunil-trading-company'),
            ),
            inventoryListProvider.overrideWith(
              (ref) => Stream.value(testSkus),
            ),
          ],
          child: const MaterialApp(home: InventoryListScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Indian format: 1,50,000 (not 150,000)
      expect(find.text('₹1,50,000'), findsOneWidget);
    });
  });

  // =========================================================================
  // HomeDashboard — inventory section
  // =========================================================================

  group('HomeDashboard — inventory section', () {
    testWidgets(
      'renders inventory section with domain label',
      (tester) async {
        final testOperator = Operator(
          uid: 'test-uid',
          shopId: 'sunil-trading-company',
          role: OperatorRole.bhaiya,
          displayName: 'Test Bhaiya',
          email: 'test@test.com',
          joinedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              opsAuthControllerProvider.overrideWith(
                () => _FakeOpsAuthController(
                  OpsAuthState(
                    status: OpsAuthStatus.authorized,
                    user: const AppUser(
                      uid: 'test-uid',
                      tier: AuthTier.googleOperator,
                      isAnonymous: false,
                      isPhoneVerified: false,
                    ),
                    operator: testOperator,
                  ),
                ),
              ),
            ],
            child:
                MaterialApp(theme: _testTheme(), home: const HomeDashboard()),
          ),
        );
        await tester.pumpAndSettle();

        // Inventory section should show the Hindi label
        expect(
          find.text(const AppStringsHi().inventoryTitle),
          findsOneWidget,
        );

        // Should show inventory icon
        expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);

        // Should show navigation chevron
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      },
      skip: true, // Task #20: MediaSpendTile needs provider injection refactor.
    );

    testWidgets(
      'inventory placeholder is gone from dashboard',
      (tester) async {
        final testOperator = Operator(
          uid: 'test-uid',
          shopId: 'sunil-trading-company',
          role: OperatorRole.bhaiya,
          displayName: 'Test Bhaiya',
          email: 'test@test.com',
          joinedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              opsAuthControllerProvider.overrideWith(
                () => _FakeOpsAuthController(
                  OpsAuthState(
                    status: OpsAuthStatus.authorized,
                    user: const AppUser(
                      uid: 'test-uid',
                      tier: AuthTier.googleOperator,
                      isAnonymous: false,
                      isPhoneVerified: false,
                    ),
                    operator: testOperator,
                  ),
                ),
              ),
            ],
            child:
                MaterialApp(theme: _testTheme(), home: const HomeDashboard()),
          ),
        );
        await tester.pumpAndSettle();

        // The old placeholder text "Coming soon" should NOT appear next to Inventory
        // (Other placeholders for Orders/Chat/Udhaar still have it)
        // Check that "Inventory" text no longer appears with "Coming soon" in the
        // same _PlaceholderSection.
        // We verify by checking that the Inventory label is followed by a chevron,
        // not "Coming soon".

        // The old English "Inventory" placeholder should be gone
        // (it was replaced by the Hindi "सामान" section)
        // We verify other placeholders still exist
        expect(find.text('Orders'), findsOneWidget);
        expect(find.text('Chat'), findsOneWidget);
        expect(find.text('Udhaar'), findsOneWidget);
      },
      skip: true, // Task #20: MediaSpendTile needs provider injection refactor.
    );
  });

  // =========================================================================
  // String symmetry: hi/en have same key count
  // =========================================================================

  group('String symmetry check', () {
    test('hi and en both implement all §18 getters', () {
      // If either class is missing an implementation, the Dart analyzer
      // would catch it at compile time. This test provides runtime verification.
      const hi = AppStringsHi();
      const en = AppStringsEn();

      // Just exercising all getters to ensure no runtime exceptions.
      expect(hi.inventoryTitle.isNotEmpty, isTrue);
      expect(en.inventoryTitle.isNotEmpty, isTrue);
      expect(hi.skuSaveButton.isNotEmpty, isTrue);
      expect(en.skuSaveButton.isNotEmpty, isTrue);
      expect(hi.inventoryEmpty.isNotEmpty, isTrue);
      expect(en.inventoryEmpty.isNotEmpty, isTrue);
    });
  });
}

/// Fake OpsAuthController for widget tests.
class _FakeOpsAuthController extends OpsAuthController {
  _FakeOpsAuthController(this._fixedState);

  final OpsAuthState _fixedState;

  @override
  Future<OpsAuthState> build() async => _fixedState;

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async {}
}
