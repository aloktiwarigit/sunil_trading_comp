// =============================================================================
// shopkeeper_app tests — Sprint 3 S4.1 + S4.13 verification.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';

import 'package:shopkeeper_app/features/auth/auth_controller.dart';
import 'package:shopkeeper_app/features/auth/sign_in_screen.dart';
import 'package:shopkeeper_app/features/dashboard/todays_task_card.dart';
import 'package:shopkeeper_app/features/dashboard/todays_task_seed.dart';
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
  group('OpsAuthState', () {
    test('loading factory has correct status', () {
      expect(OpsAuthState.loading.status, OpsAuthStatus.loading);
      expect(OpsAuthState.loading.user, isNull);
      expect(OpsAuthState.loading.operator, isNull);
    });

    test('signedOut factory has correct status', () {
      expect(OpsAuthState.signedOut.status, OpsAuthStatus.signedOut);
      expect(OpsAuthState.signedOut.user, isNull);
    });

    test('authorized state holds operator', () {
      final op = Operator(
        uid: 'test-uid',
        shopId: 'sunil-trading-company',
        role: OperatorRole.bhaiya,
        displayName: 'Test Bhaiya',
        email: 'test@example.com',
        joinedAt: DateTime(2026, 3, 12),
      );
      final state = OpsAuthState(
        status: OpsAuthStatus.authorized,
        user: const AppUser(
          uid: 'test-uid',
          tier: AuthTier.googleOperator,
          isAnonymous: false,
          isPhoneVerified: false,
          email: 'test@example.com',
        ),
        operator: op,
      );
      expect(state.status, OpsAuthStatus.authorized);
      expect(state.operator?.role, OperatorRole.bhaiya);
      expect(state.operator?.isBhaiya, isTrue);
    });
  });

  group('TodaysTaskSeed', () {
    test('ramp sequence has exactly 30 entries', () {
      expect(TodaysTaskSeed.rampSequence.length, 30);
    });

    test('weekly rotation has exactly 7 entries', () {
      expect(TodaysTaskSeed.weeklyRotation.length, 7);
    });

    test('ramp sequence day numbers are 1-30 in order', () {
      for (var i = 0; i < 30; i++) {
        expect(TodaysTaskSeed.rampSequence[i].day, i + 1);
      }
    });

    test('every task has non-empty titleHi and subtitleEn', () {
      for (final task in TodaysTaskSeed.rampSequence) {
        expect(task.titleHi, isNotEmpty, reason: 'Day ${task.day} titleHi');
        expect(task.subtitleEn, isNotEmpty, reason: 'Day ${task.day} subtitleEn');
      }
      for (final task in TodaysTaskSeed.weeklyRotation) {
        expect(task.titleHi, isNotEmpty);
        expect(task.subtitleEn, isNotEmpty);
      }
    });

    test('every task has positive estimatedMinutes', () {
      for (final task in TodaysTaskSeed.rampSequence) {
        expect(task.estimatedMinutes, greaterThan(0),
            reason: 'Day ${task.day}');
      }
      for (final task in TodaysTaskSeed.weeklyRotation) {
        expect(task.estimatedMinutes, greaterThan(0));
      }
    });

    test('taskForDay returns correct ramp entry for days 1-30', () {
      for (var d = 1; d <= 30; d++) {
        final task = TodaysTaskSeed.taskForDay(d);
        expect(task.day, d);
      }
    });

    test('taskForDay returns rotation entry for days > 30', () {
      // Day 31 → weeklyRotation[0]
      final day31 = TodaysTaskSeed.taskForDay(31);
      expect(day31.titleHi, TodaysTaskSeed.weeklyRotation[0].titleHi);

      // Day 37 → weeklyRotation[6]
      final day37 = TodaysTaskSeed.taskForDay(37);
      expect(day37.titleHi, TodaysTaskSeed.weeklyRotation[6].titleHi);

      // Day 38 → cycles back to weeklyRotation[0]
      final day38 = TodaysTaskSeed.taskForDay(38);
      expect(day38.titleHi, TodaysTaskSeed.weeklyRotation[0].titleHi);
    });

    test('isCelebrationDay is true only for day 30', () {
      expect(TodaysTaskSeed.isCelebrationDay(29), isFalse);
      expect(TodaysTaskSeed.isCelebrationDay(30), isTrue);
      expect(TodaysTaskSeed.isCelebrationDay(31), isFalse);
    });

    test('no forbidden udhaar vocabulary in any task', () {
      const forbidden = [
        'interest', 'loan', 'penalty', 'due date', 'overdue',
        'default', 'collection', 'recovery', 'installment', 'EMI',
        'ब्याज', 'ऋण', 'जुर्माना', 'देय तिथि', 'क़िस्त',
      ];
      for (final task in [
        ...TodaysTaskSeed.rampSequence,
        ...TodaysTaskSeed.weeklyRotation,
      ]) {
        for (final word in forbidden) {
          expect(
            task.titleHi.toLowerCase().contains(word.toLowerCase()),
            isFalse,
            reason: 'Forbidden "$word" in titleHi: ${task.titleHi}',
          );
          expect(
            task.subtitleEn.toLowerCase().contains(word.toLowerCase()),
            isFalse,
            reason: 'Forbidden "$word" in subtitleEn: ${task.subtitleEn}',
          );
        }
      }
    });

    test('no forbidden mythic vocabulary in any task', () {
      const forbidden = [
        'शुभ', 'मंगल', 'मंदिर', 'धर्म', 'तीर्थ', 'स्वागतम्',
        'उत्पाद', 'गुणवत्ता', 'श्रेष्ठ',
      ];
      for (final task in [
        ...TodaysTaskSeed.rampSequence,
        ...TodaysTaskSeed.weeklyRotation,
      ]) {
        for (final word in forbidden) {
          expect(
            task.titleHi.contains(word),
            isFalse,
            reason: 'Forbidden "$word" in titleHi: ${task.titleHi}',
          );
        }
      }
    });
  });

  group('AppStrings — Sprint 3 ops strings', () {
    test('Hindi ops strings are non-empty', () {
      const hi = AppStringsHi();
      expect(hi.signInWithGoogle, isNotEmpty);
      expect(hi.todaysTaskTitle, isNotEmpty);
      expect(hi.todaysTaskDone, isNotEmpty);
      expect(hi.todaysTaskDismiss, isNotEmpty);
      expect(hi.todaysTaskMinutes(10), contains('10'));
      expect(hi.signOutLabel, isNotEmpty);
      expect(hi.opsDashboardTitle, isNotEmpty);
      expect(hi.todaysTaskDay30Celebration, isNotEmpty);
      expect(hi.opsPermissionRevoked, isNotEmpty);
    });

    test('English ops strings are non-empty', () {
      const en = AppStringsEn();
      expect(en.signInWithGoogle, isNotEmpty);
      expect(en.todaysTaskTitle, isNotEmpty);
      expect(en.todaysTaskDone, isNotEmpty);
      expect(en.todaysTaskDismiss, isNotEmpty);
      expect(en.todaysTaskMinutes(10), contains('10'));
      expect(en.signOutLabel, isNotEmpty);
      expect(en.opsDashboardTitle, isNotEmpty);
      expect(en.todaysTaskDay30Celebration, isNotEmpty);
      expect(en.opsPermissionRevoked, isNotEmpty);
    });

    test('opsAppNotAuthorized already exists and is valid', () {
      const hi = AppStringsHi();
      const en = AppStringsEn();
      expect(hi.opsAppNotAuthorized, contains('authorized'));
      expect(en.opsAppNotAuthorized, contains('authorized'));
    });

    test('Hindi todaysTaskMinutes formats correctly', () {
      const hi = AppStringsHi();
      expect(hi.todaysTaskMinutes(5), '5 मिनट');
      expect(hi.todaysTaskMinutes(15), '15 मिनट');
    });

    test('English todaysTaskMinutes formats correctly', () {
      const en = AppStringsEn();
      expect(en.todaysTaskMinutes(5), '5 min');
      expect(en.todaysTaskMinutes(15), '15 min');
    });

    test('no forbidden udhaar vocab in new ops strings', () {
      const forbidden = [
        'interest', 'loan', 'penalty', 'due date',
        'ब्याज', 'ऋण', 'जुर्माना',
      ];
      const hi = AppStringsHi();
      const en = AppStringsEn();

      final hiStrings = [
        hi.signInWithGoogle, hi.todaysTaskTitle, hi.todaysTaskDone,
        hi.todaysTaskDismiss, hi.signOutLabel, hi.opsDashboardTitle,
        hi.todaysTaskDay30Celebration, hi.opsPermissionRevoked,
      ];
      final enStrings = [
        en.signInWithGoogle, en.todaysTaskTitle, en.todaysTaskDone,
        en.todaysTaskDismiss, en.signOutLabel, en.opsDashboardTitle,
        en.todaysTaskDay30Celebration, en.opsPermissionRevoked,
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
  });

  group('OpsSignInScreen widget', () {
    testWidgets('renders sign-in button with correct text', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            opsAuthControllerProvider.overrideWith(
              () => _FakeOpsAuthController(OpsAuthState.signedOut),
            ),
          ],
          child: const MaterialApp(home: OpsSignInScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(const AppStringsHi().signInWithGoogle), findsOneWidget);
      expect(find.text(const AppStringsHi().shopDisplayName), findsOneWidget);
    });

    testWidgets('shows unauthorized banner when status is unauthorized',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            opsAuthControllerProvider.overrideWith(
              () => _FakeOpsAuthController(
                const OpsAuthState(status: OpsAuthStatus.unauthorized),
              ),
            ),
          ],
          child: const MaterialApp(home: OpsSignInScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(const AppStringsHi().opsAppNotAuthorized),
        findsOneWidget,
      );
    });

    testWidgets('shows permission-revoked banner when status is permissionRevoked',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            opsAuthControllerProvider.overrideWith(
              () => _FakeOpsAuthController(
                const OpsAuthState(status: OpsAuthStatus.permissionRevoked),
              ),
            ),
          ],
          child: const MaterialApp(home: OpsSignInScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(const AppStringsHi().opsPermissionRevoked),
        findsOneWidget,
      );
    });
  });

  group('TodaysTaskCard widget', () {
    testWidgets('renders day 1 task with correct text', (tester) async {
      final joinedAt = DateTime.now(); // Day 1

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TodaysTaskCard(operatorJoinedAt: joinedAt),
            ),
          ),
        ),
      );

      // Title
      expect(find.text(const AppStringsHi().todaysTaskTitle), findsOneWidget);
      // Done button
      expect(find.text(const AppStringsHi().todaysTaskDone), findsOneWidget);
      // Day 1 task text
      expect(
        find.text(TodaysTaskSeed.rampSequence[0].titleHi),
        findsOneWidget,
      );
      expect(
        find.text(TodaysTaskSeed.rampSequence[0].subtitleEn),
        findsOneWidget,
      );
    });

    testWidgets('done button marks task as complete', (tester) async {
      final joinedAt = DateTime.now();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TodaysTaskCard(operatorJoinedAt: joinedAt),
            ),
          ),
        ),
      );

      // Tap done
      await tester.tap(find.text(const AppStringsHi().todaysTaskDone));
      await tester.pump();

      // Should show completed state
      expect(
        find.text('${const AppStringsHi().todaysTaskDone}!'),
        findsOneWidget,
      );
    });

    testWidgets('long press shows dismiss dialog', (tester) async {
      final joinedAt = DateTime.now();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TodaysTaskCard(operatorJoinedAt: joinedAt),
            ),
          ),
        ),
      );

      // Long press the card
      await tester.longPress(find.byType(TodaysTaskCard));
      await tester.pumpAndSettle();

      // Dismiss dialog should appear
      expect(
        find.text(const AppStringsHi().todaysTaskDismiss),
        findsWidgets, // appears in dialog content + button
      );
    });

    testWidgets('dismissed card hides', (tester) async {
      final joinedAt = DateTime.now();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TodaysTaskCard(operatorJoinedAt: joinedAt),
            ),
          ),
        ),
      );

      // Long press to show dialog
      await tester.longPress(find.byType(TodaysTaskCard));
      await tester.pumpAndSettle();

      // Find the dismiss button in the dialog actions (the second one)
      final dismissButtons = find.text(const AppStringsHi().todaysTaskDismiss);
      // Tap the last dismiss button (the action button, not dialog content)
      await tester.tap(dismissButtons.last);
      await tester.pumpAndSettle();

      // Card should be gone
      expect(find.text(const AppStringsHi().todaysTaskTitle), findsNothing);
    });

    testWidgets('day 30 shows celebration banner', (tester) async {
      // Join date 29 days ago → day 30.
      final joinedAt = DateTime.now().subtract(const Duration(days: 29));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TodaysTaskCard(operatorJoinedAt: joinedAt),
            ),
          ),
        ),
      );

      expect(
        find.text(const AppStringsHi().todaysTaskDay30Celebration),
        findsOneWidget,
      );
    });
  });

  group('HomeDashboard widget', () {
    testWidgets('renders dashboard with sign-out menu', (tester) async {
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
          child: MaterialApp(theme: _testTheme(), home: const HomeDashboard()),
        ),
      );
      await tester.pumpAndSettle();

      // Dashboard title
      expect(
        find.text(const AppStringsHi().opsDashboardTitle),
        findsOneWidget,
      );

      // Operator name + role
      expect(find.text('Test Bhaiya (bhaiya)'), findsOneWidget);

      // Inventory section (S4.3 — now live, uses Hindi label)
      expect(find.text(const AppStringsHi().inventoryTitle), findsOneWidget);
      // Remaining placeholder sections
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Udhaar'), findsOneWidget);
    });
  });

  group('Operator model domain naming', () {
    test('roles use canonical bhaiya/beta/munshi naming', () {
      expect(OperatorRole.values.map((r) => r.name).toList(),
          containsAll(['bhaiya', 'beta', 'munshi']));
    });

    test('roles do NOT use forbidden shopkeeper/son names', () {
      final roleNames = OperatorRole.values.map((r) => r.name).toList();
      expect(roleNames, isNot(contains('shopkeeper')));
      expect(roleNames, isNot(contains('son')));
    });
  });
}

/// Fake OpsAuthController for widget tests that returns a fixed state
/// without touching Firebase.
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
