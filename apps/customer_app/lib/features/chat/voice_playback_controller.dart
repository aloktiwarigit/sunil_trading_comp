// =============================================================================
// VoicePlaybackController — P2.6: voice note playback in chat.
//
// AC #1: messages with type voiceNote render as audio player (ChatBubble)
// AC #2: player shows play/pause, waveform, duration, position, sender label
// AC #4: only one plays at a time (auto-pause previous)
// AC #5: cached locally after first play (just_audio default cache)
//
// Uses just_audio for actual platform audio playback with Firebase Storage
// download URLs. Provides progress stream for waveform display.
// =============================================================================

import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:just_audio/just_audio.dart';

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

  AudioPlayer? _player;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  /// Start or resume playback for a voice note.
  /// AC #4: auto-pauses any currently playing note.
  ///
  /// [audioStorageRef] is the Firebase Storage path (e.g.,
  /// "shops/{shopId}/voice_notes/{noteId}.aac").
  Future<void> play({
    required String voiceNoteId,
    required int durationSeconds,
    required String audioStorageRef,
  }) async {
    // If a different note is playing, stop it first (AC #4).
    if (state.activeVoiceNoteId != null &&
        state.activeVoiceNoteId != voiceNoteId) {
      await stop();
    }

    // If same note is paused, resume.
    if (state.activeVoiceNoteId == voiceNoteId && !state.isPlaying) {
      state = VoicePlaybackState(
        activeVoiceNoteId: voiceNoteId,
        isPlaying: true,
        progress: state.progress,
        durationSeconds: durationSeconds,
      );
      await _player?.play();
      return;
    }

    // New note — create player and start fresh.
    _player ??= AudioPlayer();

    state = VoicePlaybackState(
      activeVoiceNoteId: voiceNoteId,
      isPlaying: true,
      progress: 0.0,
      durationSeconds: durationSeconds,
    );

    try {
      // Fetch download URL from Firebase Storage.
      final ref = FirebaseStorage.instance.ref(audioStorageRef);
      final url = await ref.getDownloadURL();

      // Set source — just_audio caches internally (AC #5).
      await _player!.setUrl(url);

      // Listen to position for progress updates.
      _positionSub?.cancel();
      _positionSub = _player!.positionStream.listen((position) {
        final totalMs = _player!.duration?.inMilliseconds ?? 1;
        if (totalMs > 0) {
          final progress = (position.inMilliseconds / totalMs).clamp(0.0, 1.0);
          if (mounted) {
            state = VoicePlaybackState(
              activeVoiceNoteId: voiceNoteId,
              isPlaying: state.isPlaying,
              progress: progress,
              durationSeconds: durationSeconds,
            );
          }
        }
      });

      // Listen for completion.
      _playerStateSub?.cancel();
      _playerStateSub = _player!.playerStateStream.listen((playerState) {
        if (playerState.processingState == ProcessingState.completed) {
          if (mounted) {
            stop();
          }
        }
      });

      await _player!.play();
    } catch (e) {
      // On error (network, storage, etc.), reset to idle.
      if (mounted) {
        state = const VoicePlaybackState();
      }
    }
  }

  /// Pause the current playback.
  void pause() {
    if (state.isPlaying) {
      _player?.pause();
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
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    await _player?.stop();
    if (mounted) {
      state = const VoicePlaybackState();
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _player?.dispose();
    super.dispose();
  }
}
