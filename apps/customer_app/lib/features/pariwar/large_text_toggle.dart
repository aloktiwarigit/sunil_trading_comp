// =============================================================================
// LargeTextToggle — P2.8: universal large-text accessibility toggle.
//
// AC #1: single toggle "बड़ा अक्षर" in customer app settings
// AC #2: applies elder UI tier regardless of Decision Circle
// AC #3: stored in SharedPreferences
// AC #4: works even if Decision Circle disabled
// AC #6: toggle wins if both persona + toggle active
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// P2.8 — Large text toggle provider.
final largeTextProvider =
    StateNotifierProvider<LargeTextNotifier, bool>((ref) {
  return LargeTextNotifier();
});

class LargeTextNotifier extends StateNotifier<bool> {
  LargeTextNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('large_text_enabled') ?? false;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('large_text_enabled', state);
  }
}

/// P2.8 — Large text toggle widget for settings.
class LargeTextToggle extends ConsumerWidget {
  const LargeTextToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLargeText = ref.watch(largeTextProvider);

    return Container(
      padding: const EdgeInsets.all(YugmaSpacing.s3),
      decoration: BoxDecoration(
        color: YugmaColors.surface,
        borderRadius: BorderRadius.circular(YugmaRadius.md),
        border: Border.all(color: YugmaColors.divider),
      ),
      child: Row(
        children: [
          Icon(Icons.text_increase, color: YugmaColors.primary, size: 22),
          const SizedBox(width: YugmaSpacing.s2),
          Expanded(
            child: Text(
              const AppStringsHi().largeTextToggleLabel,
              style: TextStyle(
                fontFamily: YugmaFonts.devaBody,
                fontSize: YugmaTypeScale.body,
                fontWeight: FontWeight.w600,
                color: YugmaColors.textPrimary,
              ),
            ),
          ),
          Switch(
            value: isLargeText,
            activeColor: YugmaColors.primary,
            onChanged: (_) => ref.read(largeTextProvider.notifier).toggle(),
          ),
        ],
      ),
    );
  }
}
