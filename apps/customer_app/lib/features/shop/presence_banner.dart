// =============================================================================
// PresenceBanner — B1.9 AC #1–6 + B1.10 AC #1–6.
//
// B1.9: customer sees honest banner when shopkeeper is unavailable
// B1.10: play pre-recorded away voice note if available
// =============================================================================

import 'package:flutter/material.dart';
import 'package:lib_core/lib_core.dart';

/// B1.9 — Presence status banner for the customer app.
///
/// Shows when the shopkeeper is away/busy/at_event.
/// Hidden when available. Does NOT block browsing (AC #5).
class PresenceBanner extends StatelessWidget {
  const PresenceBanner({
    super.key,
    required this.presenceStatus,
    required this.presenceMessage,
    this.returnTime,
    this.hasAwayVoiceNote = false,
    this.onPlayVoiceNote,
  });

  final String presenceStatus;
  final String presenceMessage;
  final String? returnTime;

  /// B1.10 AC #1–2: whether an away voice note exists.
  final bool hasAwayVoiceNote;
  final VoidCallback? onPlayVoiceNote;

  @override
  Widget build(BuildContext context) {
    if (presenceStatus == 'available' || presenceStatus.isEmpty) {
      return const SizedBox.shrink();
    }

    final returnText = returnTime != null && returnTime!.isNotEmpty
        ? ', $returnTime तक वापस'
        : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: YugmaSpacing.s4,
        vertical: YugmaSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: YugmaColors.accent.withValues(alpha: 0.12),
        border: Border(
          bottom: BorderSide(
            color: YugmaColors.accent.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _statusIcon,
            size: 18,
            color: YugmaColors.accent,
          ),
          const SizedBox(width: YugmaSpacing.s2),
          Expanded(
            child: Text(
              '$presenceMessage$returnText',
              style: TextStyle(
                fontFamily: YugmaFonts.devaBody,
                fontSize: YugmaTypeScale.caption,
                fontWeight: FontWeight.w600,
                color: YugmaColors.accent,
              ),
            ),
          ),
          // B1.10 AC #2: play button when away voice note exists
          if (hasAwayVoiceNote && onPlayVoiceNote != null)
            IconButton(
              onPressed: onPlayVoiceNote,
              icon: Icon(
                Icons.play_circle_outline,
                color: YugmaColors.primary,
                size: 24,
              ),
              tooltip: 'आवाज़ सुनिए',
            ),
        ],
      ),
    );
  }

  IconData get _statusIcon => switch (presenceStatus) {
        'away' => Icons.directions_walk,
        'busyWithCustomer' => Icons.people,
        'atEvent' => Icons.celebration,
        _ => Icons.info_outline,
      };
}
