// =============================================================================
// TodaysTaskCard — the "Aaj ka kaam" daily prompt card for ops dashboard.
//
// S4.13 ACs:
//   #1: Prominent card at top of ops home dashboard
//   #2: ONE task per day from 30-day ramp sequence
//   #3: Devanagari title, English subtitle, estimated time, done button
//   #4: Done marks complete in Firestore today_tasks/{date}
//   #5: Tasks from static seed for Day 1-30, then weekly rotation
//   #6: Dismissible via long-press "छुपा दीजिए" (persist per operator)
//   #7: NO push notifications
//   #8: Day 30 celebration + first-customer-test walkthrough
//   #9: After Day 30: weekly habit rotation
//
// Per binding rules:
//   - ALL strings via AppStrings
//   - ALL theme via YugmaColors/YugmaFonts (pre-YugmaThemeExtension wiring)
//   - Font references: YugmaFonts.devaDisplay, .devaBody, .enBody
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'todays_task_seed.dart';

/// Provider that resolves the current task day number based on operator
/// join date. In the real implementation this reads from Firestore; for
/// Sprint 3 we compute from the operator's joinedAt field.
final todaysTaskDayProvider = Provider.family<int, DateTime>((ref, joinedAt) {
  final now = DateTime.now();
  final daysSinceJoin = now.difference(joinedAt).inDays;
  // Day 1 = join date, so add 1.
  return daysSinceJoin + 1;
});

/// SharedPreferences-backed state notifier for daily task persistence.
/// Key pattern: `{prefix}_{dayNumber}` — auto-resets each day.
class _DayKeyNotifier extends StateNotifier<bool> {
  _DayKeyNotifier(this._keyPrefix) : super(false) {
    _load();
  }

  final String _keyPrefix;

  String get _key {
    final now = DateTime.now();
    final dayNumber = now.difference(DateTime(2024)).inDays;
    return '${_keyPrefix}_$dayNumber';
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> set(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}

/// Provider that tracks whether today's task is completed.
/// Persisted via SharedPreferences — survives app restart.
final todaysTaskCompletedProvider =
    StateNotifierProvider<_DayKeyNotifier, bool>(
  (ref) => _DayKeyNotifier('today_task_completed'),
);

/// Provider that tracks whether the task card has been dismissed.
/// Persisted via SharedPreferences — survives app restart.
final todaysTaskDismissedProvider =
    StateNotifierProvider<_DayKeyNotifier, bool>(
  (ref) => _DayKeyNotifier('today_task_dismissed'),
);

/// The "Today's task" card widget.
class TodaysTaskCard extends ConsumerWidget {
  const TodaysTaskCard({
    super.key,
    required this.operatorJoinedAt,
  });

  /// The operator's join date — used to compute the ramp day number.
  final DateTime operatorJoinedAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = const AppStringsHi();
    final isDismissed = ref.watch(todaysTaskDismissedProvider);
    final isCompleted = ref.watch(todaysTaskCompletedProvider);

    if (isDismissed) return const SizedBox.shrink();

    final dayNumber = ref.watch(todaysTaskDayProvider(operatorJoinedAt));
    final task = TodaysTaskSeed.taskForDay(dayNumber);
    final isCelebration = TodaysTaskSeed.isCelebrationDay(dayNumber);

    return GestureDetector(
      onLongPress: () => _showDismissDialog(context, ref, strings),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(
          horizontal: YugmaSpacing.s4,
          vertical: YugmaSpacing.s3,
        ),
        padding: const EdgeInsets.all(YugmaSpacing.s5),
        decoration: BoxDecoration(
          color: YugmaColors.surface,
          borderRadius: BorderRadius.circular(YugmaRadius.lg),
          boxShadow: YugmaShadows.card,
          border: Border.all(
            color: isCelebration
                ? YugmaColors.accent
                : YugmaColors.divider,
            width: isCelebration ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header — "Aaj ka kaam"
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.todaysTaskTitle,
                    style: TextStyle(
                      fontFamily: YugmaFonts.devaDisplay,
                      fontSize: YugmaTypeScale.h3,
                      height: YugmaLineHeights.snug,
                      color: YugmaColors.primary,
                    ),
                  ),
                ),
                // Estimated time badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: YugmaSpacing.s2,
                    vertical: YugmaSpacing.s1,
                  ),
                  decoration: BoxDecoration(
                    color: YugmaColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(YugmaRadius.sm),
                  ),
                  child: Text(
                    strings.todaysTaskMinutes(task.estimatedMinutes),
                    style: TextStyle(
                      fontFamily: YugmaFonts.mono,
                      fontSize: YugmaTypeScale.label,
                      color: YugmaColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: YugmaSpacing.s3),

            // Day 30 celebration banner (AC #8)
            if (isCelebration) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(YugmaSpacing.s3),
                decoration: BoxDecoration(
                  color: YugmaColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(YugmaRadius.md),
                ),
                child: Text(
                  strings.todaysTaskDay30Celebration,
                  style: TextStyle(
                    fontFamily: YugmaFonts.devaBody,
                    fontSize: YugmaTypeScale.body,
                    height: YugmaLineHeights.normal,
                    color: YugmaColors.success,
                  ),
                ),
              ),
              const SizedBox(height: YugmaSpacing.s3),
            ],

            // Task Devanagari title
            Text(
              task.titleHi,
              style: TextStyle(
                fontFamily: YugmaFonts.devaBody,
                fontSize: YugmaTypeScale.bodyLarge,
                height: YugmaLineHeights.normal,
                color: YugmaColors.textPrimary,
                fontWeight: FontWeight.w600,
                decoration: isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),

            const SizedBox(height: YugmaSpacing.s1),

            // Task English subtitle
            Text(
              task.subtitleEn,
              style: TextStyle(
                fontFamily: YugmaFonts.enBody,
                fontSize: YugmaTypeScale.bodySmall,
                height: YugmaLineHeights.snug,
                color: YugmaColors.textSecondary,
                fontStyle: FontStyle.italic,
                decoration: isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),

            const SizedBox(height: YugmaSpacing.s4),

            // "Ho gaya" done button (AC #3)
            SizedBox(
              width: double.infinity,
              height: YugmaTapTargets.minDefault,
              child: ElevatedButton(
                onPressed: isCompleted
                    ? null
                    : () => _markComplete(ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted
                      ? YugmaColors.success.withValues(alpha: 0.12)
                      : YugmaColors.primary,
                  foregroundColor: isCompleted
                      ? YugmaColors.success
                      : YugmaColors.textOnPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(YugmaRadius.md),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isCompleted ? '${strings.todaysTaskDone}!' : strings.todaysTaskDone,
                  style: TextStyle(
                    fontFamily: YugmaFonts.devaBody,
                    fontSize: YugmaTypeScale.bodyLarge,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mark today's task as complete. In the full implementation, this
  /// writes to Firestore `shops/{shopId}/operators/{uid}/today_tasks/{date}`.
  void _markComplete(WidgetRef ref) {
    ref.read(todaysTaskCompletedProvider.notifier).set(true);
  }

  /// Show the dismiss confirmation dialog (AC #6).
  void _showDismissDialog(
    BuildContext context,
    WidgetRef ref,
    AppStrings strings,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: YugmaColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(YugmaRadius.lg),
        ),
        content: Text(
          strings.todaysTaskDismiss,
          style: TextStyle(
            fontFamily: YugmaFonts.devaBody,
            fontSize: YugmaTypeScale.body,
            color: YugmaColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              strings.npsSnoozeLater,
              style: TextStyle(
                fontFamily: YugmaFonts.devaBody,
                color: YugmaColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(todaysTaskDismissedProvider.notifier).set(true);
              Navigator.of(dialogContext).pop();
            },
            child: Text(
              strings.todaysTaskDismiss,
              style: TextStyle(
                fontFamily: YugmaFonts.devaBody,
                color: YugmaColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
