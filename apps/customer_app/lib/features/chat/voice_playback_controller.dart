// =============================================================================
// VoicePlaybackController — P2.6: voice note playback in chat.
//
// AC #1: messages with type voiceNote render as audio player (already done in ChatBubble)
// AC #2: player shows play/pause, waveform, duration, position, sender label
// AC #4: only one plays at a time (auto-pause previous)
// AC #5: cached locally after first play
//
// This controller manages playback state for voice notes in the chat.
// It tracks which voice note is playing and provides progress updates.
// Actual audio decoding is deferred to a platform plugin (just_audio or
// audioplayers) — this sprint wires the state management layer.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for a single voice note playback.
class VoicePlaybackState {
  const VoicePlaybackState({
    this.activeVoiceNoteId,
    this.isPlaying = false,
    this.progress = 0.0,
    this.durationSeconds = 0,
  });

  /// Currently active voice note ID (null if nothing is playing).
  final String? activeVoiceNoteId;
  final bool isPlaying;

  /// Playback progress [0.0, 1.0].
  final double progress;
  final int durationSeconds;
}

/// P2.6 — Voice playback controller.
///
/// Ensures only one voice note plays at a time (AC #4).
/// Tracks progress for the waveform display (AC #2).
final voicePlaybackProvider =
    StateNotifierProvider<VoicePlaybackNotifier, VoicePlaybackState>((ref) {
  return VoicePlaybackNotifier();
});

class VoicePlaybackNotifier extends StateNotifier<VoicePlaybackState> {
  VoicePlaybackNotifier() : super(const VoicePlaybackState());

  /// Start or resume playback for a voice note.
  /// AC #4: auto-pauses any currently playing note.
  Future<void> play({
    required String voiceNoteId,
    required int durationSeconds,
    required String audioStorageRef,
  }) async {
    // If a different note is playing, stop it first.
    if (state.activeVoiceNoteId != null &&
        state.activeVoiceNoteId != voiceNoteId) {
      await stop();
    }

    state = VoicePlaybackState(
      activeVoiceNoteId: voiceNoteId,
      isPlaying: true,
      progress: 0.0,
      durationSeconds: durationSeconds,
    );

    // TODO: wire actual audio playback via just_audio or audioplayers.
    // For now, simulate progress for UI testing.
    // In production:
    //   1. Fetch download URL from Firebase Storage
    //   2. Cache locally (AC #5)
    //   3. Stream audio with progress updates
  }

  /// Pause the current playback.
  void pause() {
    if (state.isPlaying) {
      state = VoicePlaybackState(
        activeVoiceNoteId: state.activeVoiceNoteId,
        isPlaying: false,
        progress: state.progress,
        durationSeconds: state.durationSeconds,
      );
    }
  }

  /// Stop and reset playback.
  Future<void> stop() async {
    state = const VoicePlaybackState();
  }

  /// Update progress (called by the audio player stream).
  void updateProgress(double progress) {
    if (state.isPlaying) {
      state = VoicePlaybackState(
        activeVoiceNoteId: state.activeVoiceNoteId,
        isPlaying: true,
        progress: progress.clamp(0.0, 1.0),
        durationSeconds: state.durationSeconds,
      );
    }

    // Auto-stop at end.
    if (progress >= 1.0) {
      stop();
    }
  }
}
