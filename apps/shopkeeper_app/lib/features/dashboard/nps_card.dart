// =============================================================================
// NpsCard — S4.17 AC #1–3: bi-weekly NPS prompt on the ops dashboard.
//
// AC #1: every 14 days of active use, show a non-intrusive card with
//        1-10 rating + optional textarea. NOT a modal.
// AC #2: writes feedback doc to shops/{shopId}/feedback/{id}
// AC #3: dismissible with 7-day snooze.
// Edge #1: first 14 days → card not shown.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_controller.dart';

/// S4.17 — NPS survey card for the ops dashboard.
class NpsCard extends ConsumerStatefulWidget {
  const NpsCard({super.key});

  @override
  ConsumerState<NpsCard> createState() => _NpsCardState();
}

class _NpsCardState extends ConsumerState<NpsCard> {
  int? _selectedScore;
  final _textController = TextEditingController();
  bool _submitted = false;
  bool _dismissed = false;
  bool _loading = true;
  bool _shouldShow = false;

  @override
  void initState() {
    super.initState();
    _checkShouldShow();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _checkShouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDismissed = prefs.getInt('nps_last_dismissed_ms') ?? 0;
    final lastSubmitted = prefs.getInt('nps_last_submitted_ms') ?? 0;

    final now = DateTime.now().millisecondsSinceEpoch;
    const fourteenDays = 14 * 24 * 60 * 60 * 1000;
    const sevenDays = 7 * 24 * 60 * 60 * 1000;

    // AC #1: every 14 days since last submit
    final dueSinceSubmit = (now - lastSubmitted) >= fourteenDays;
    // AC #3: snooze for 7 days after dismiss
    final snoozePassed = (now - lastDismissed) >= sevenDays;

    // Edge #1: check operator joined > 14 days ago
    final op = ref.read(opsAuthControllerProvider).valueOrNull?.operator;
    final joinedDaysAgo =
        op != null ? DateTime.now().difference(op.joinedAt).inDays : 0;

    setState(() {
      _shouldShow = dueSinceSubmit && snoozePassed && joinedDaysAgo >= 14;
      _loading = false;
    });
  }

  Future<void> _submit() async {
    if (_selectedScore == null) return;

    final authState = ref.read(opsAuthControllerProvider).valueOrNull;
    final op = authState?.operator;
    if (op == null) return;

    final shopId = ref.read(shopIdProviderProvider).shopId;

    // AC #2: write feedback document
    await FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .collection('feedback')
        .add(<String, dynamic>{
      'type': 'shopkeeper_burnout_self_report',
      'score': _selectedScore,
      'textBody': _textController.text.trim(),
      'authorUid': op.uid,
      'authorRole': op.role.name,
      'sampledAt': FieldValue.serverTimestamp(),
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'nps_last_submitted_ms',
      DateTime.now().millisecondsSinceEpoch,
    );

    setState(() => _submitted = true);
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'nps_last_dismissed_ms',
      DateTime.now().millisecondsSinceEpoch,
    );
    setState(() => _dismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || !_shouldShow || _submitted || _dismissed) {
      return const SizedBox.shrink();
    }

    final strings = const AppStringsHi();

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: YugmaSpacing.s4,
        vertical: YugmaSpacing.s2,
      ),
      padding: const EdgeInsets.all(YugmaSpacing.s4),
      decoration: BoxDecoration(
        color: YugmaColors.surface,
        borderRadius: BorderRadius.circular(YugmaRadius.lg),
        border: Border.all(
          color: YugmaColors.accent.withValues(alpha: 0.3),
        ),
        boxShadow: YugmaShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.npsCardHeadline,
                  style: TextStyle(
                    fontFamily: YugmaFonts.devaBody,
                    fontSize: YugmaTypeScale.bodyLarge,
                    fontWeight: FontWeight.w700,
                    color: YugmaColors.textPrimary,
                  ),
                ),
              ),
              // AC #3: dismiss button
              InkWell(
                onTap: _dismiss,
                child: Text(
                  strings.npsSnoozeLater,
                  style: TextStyle(
                    fontFamily: YugmaFonts.devaBody,
                    fontSize: YugmaTypeScale.caption,
                    color: YugmaColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: YugmaSpacing.s3),

          // 1-10 rating dots
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(10, (i) {
              final score = i + 1;
              final isSelected = _selectedScore == score;
              return InkWell(
                onTap: () => setState(() => _selectedScore = score),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isSelected ? YugmaColors.primary : YugmaColors.divider,
                  ),
                  child: Center(
                    child: Text(
                      '$score',
                      style: TextStyle(
                        fontFamily: YugmaFonts.mono,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? YugmaColors.textOnPrimary
                            : YugmaColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: YugmaSpacing.s3),

          // Optional textarea
          TextField(
            controller: _textController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: strings.npsOptionalPrompt,
              hintStyle: TextStyle(fontFamily: YugmaFonts.devaBody),
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.all(YugmaSpacing.s2),
            ),
            style: TextStyle(
              fontFamily: YugmaFonts.devaBody,
              fontSize: YugmaTypeScale.body,
            ),
          ),
          const SizedBox(height: YugmaSpacing.s2),

          // Submit button
          if (_selectedScore != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: YugmaColors.primary,
                  foregroundColor: YugmaColors.textOnPrimary,
                  textStyle: TextStyle(
                    fontFamily: YugmaFonts.devaBody,
                    fontSize: YugmaTypeScale.body,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(YugmaRadius.md),
                  ),
                ),
                child: Text(strings.todaysTaskDone),
              ),
            ),
        ],
      ),
    );
  }
}
