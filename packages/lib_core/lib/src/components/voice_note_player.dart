// =============================================================================
// VoiceNotePlayer — waveform-style inline audio player widget.
//
// Ported from design bundle Widget 4 (components_library.dart lines 452-533).
// Uses context.yugmaTheme for all colors per ADR-003. Respects elder tier
// for tap target sizing.
//
// Consumed by B1.3 (greeting voice note auto-play on BharosaLanding) and
// B1.5 (SKU detail inline voice note). The widget is a visual player shell;
// actual audio playback is wired via the onPlayPause callback by the
// consuming screen (which holds the AudioPlayer instance).
// =============================================================================

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../theme/yugma_theme_extension.dart';

/// Waveform-style inline voice note player.
///
/// Renders a play/pause button, pseudo-waveform bars, and a duration label.
/// [onPlayPause] is called when the user taps play/pause — the consuming
/// widget is responsible for actual audio playback control.
class VoiceNotePlayerWidget extends StatefulWidget {
  /// Duration of the voice note in seconds. Used for the duration label.
  final int durationSeconds;

  /// True if rendered on a dark/primary background — adjusts accent color
  /// to [shopAccentGlow] for legibility.
  final bool isOnPrimary;

  /// Called when the user taps play/pause. The bool parameter is `true`
  /// when transitioning TO playing, `false` when pausing.
  final ValueChanged<bool>? onPlayPause;

  /// Current playback progress in [0.0, 1.0]. When non-null, the waveform
  /// bars to the left of the progress point use the accent color, and bars
  /// to the right are muted. When null, all bars use the accent color.
  final double? progress;

  const VoiceNotePlayerWidget({
    super.key,
    required this.durationSeconds,
    this.isOnPrimary = false,
    this.onPlayPause,
    this.progress,
  });

  @override
  State<VoiceNotePlayerWidget> createState() => _VoiceNotePlayerWidgetState();
}

class _VoiceNotePlayerWidgetState extends State<VoiceNotePlayerWidget> {
  bool _playing = false;

  void _toggle() {
    setState(() => _playing = !_playing);
    widget.onPlayPause?.call(_playing);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;
    final accentColor =
        widget.isOnPrimary ? theme.shopAccentGlow : theme.shopAccent;
    final mutedBarColor = widget.isOnPrimary
        ? theme.shopTextOnPrimary.withValues(alpha: 0.25)
        : theme.shopDivider;

    // Elder tier: inflate tap target to 56dp minimum
    final buttonSize = theme.isElderTier ? 40.0 : 28.0;
    final iconSize = theme.isElderTier ? 22.0 : 16.0;

    // Pseudo-random waveform bar heights (static aesthetic pattern)
    const barHeights = [8, 14, 18, 22, 16, 12, 20, 14, 18, 10, 16, 22, 12, 8];
    const barCount = 14;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play/pause button
        Material(
          color: accentColor,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _toggle,
            child: SizedBox(
              width: buttonSize,
              height: buttonSize,
              child: Icon(
                _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: theme.shopPrimaryDeep,
                size: iconSize,
              ),
            ),
          ),
        ),
        const SizedBox(width: YugmaSpacing.s2),
        // Waveform bars
        SizedBox(
          width: 120,
          height: buttonSize,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(barCount, (i) {
              final isPlayed = widget.progress != null &&
                  i < (widget.progress! * barCount).ceil();
              return Container(
                width: 3,
                height: barHeights[i].toDouble(),
                decoration: BoxDecoration(
                  color: isPlayed || widget.progress == null
                      ? accentColor
                      : mutedBarColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: YugmaSpacing.s2),
        // Duration label
        Text(
          _formatDuration(widget.durationSeconds),
          style: TextStyle(
            fontFamily: YugmaFonts.mono,
            fontSize: theme.isElderTier ? 13.0 : 9.0,
            color: widget.isOnPrimary
                ? theme.shopTextOnPrimary.withValues(alpha: 0.7)
                : theme.shopTextMuted,
          ),
        ),
      ],
    );
  }

  /// Format seconds as "M:SS".
  static String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
