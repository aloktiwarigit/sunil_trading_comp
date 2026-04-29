// =============================================================================
// VoiceRecorderWidget — shared recording UI for B1.6 + B1.7.
//
// B1.6 AC #1: press to record, release to stop
// B1.6 AC #2: 5s min, 60s max
// B1.6 AC #3: send / re-record / cancel buttons
// B1.6 AC #7: waveform + duration counter
// Edge #1: mic permission prompt in Hindi
// Edge #3: auto-stop at 60s
//
// Returns recorded bytes + duration via callback. Caller handles upload.
// =============================================================================

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lib_core/lib_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Result of a voice recording session.
class VoiceRecordingResult {
  const VoiceRecordingResult({
    required this.bytes,
    required this.durationSeconds,
  });

  final List<int> bytes;
  final int durationSeconds;
}

/// Shared voice recorder widget. Used by B1.6 (SKU) and B1.7 (chat).
class VoiceRecorderWidget extends StatefulWidget {
  const VoiceRecorderWidget({
    super.key,
    required this.onSend,
    required this.onCancel,
    this.strings = const AppStringsHi(),
  });

  /// Called when the user taps "send" with the recorded audio.
  final void Function(VoiceRecordingResult result) onSend;

  /// Called when the user cancels recording.
  final VoidCallback onCancel;

  /// Locale strings for UI labels.
  final AppStrings strings;

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget> {
  final _recorder = AudioRecorder();
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isRecording = false;
  bool _hasRecording = false;
  String? _filePath;
  bool _permissionDenied = false;

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    // Clean up temp file
    if (_filePath != null) {
      File(_filePath!).delete().catchError((Object _) => File(''));
    }
    super.dispose();
  }

  Future<void> _startRecording() async {
    HapticFeedback.lightImpact();
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      setState(() => _permissionDenied = true);
      return;
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    setState(() {
      _isRecording = true;
      _elapsedSeconds = 0;
      _filePath = path;
      _permissionDenied = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _elapsedSeconds++);
      // B1.6 edge #3: auto-stop at 60s
      if (_elapsedSeconds >= 60) {
        _stopRecording();
      }
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final path = await _recorder.stop();

    setState(() {
      _isRecording = false;
      _hasRecording = path != null && _elapsedSeconds >= 5;
      if (path != null) _filePath = path;
    });
  }

  Future<void> _send() async {
    if (_filePath == null) return;
    final file = File(_filePath!);
    if (!await file.exists()) return;

    final bytes = await file.readAsBytes();
    widget.onSend(VoiceRecordingResult(
      bytes: bytes,
      durationSeconds: _elapsedSeconds,
    ));
  }

  Future<void> _reRecord() async {
    // Delete old file
    if (_filePath != null) {
      File(_filePath!).delete().catchError((Object _) => File(''));
    }
    setState(() {
      _hasRecording = false;
      _elapsedSeconds = 0;
    });
    await _startRecording();
  }

  @override
  Widget build(BuildContext context) {
    // Edge #1: mic permission denied
    if (_permissionDenied) {
      return Container(
        padding: const EdgeInsets.all(YugmaSpacing.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mic_off, color: YugmaColors.commit, size: 40),
            const SizedBox(height: YugmaSpacing.s2),
            Text(
              widget.strings.micPermissionNeeded,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: YugmaFonts.devaBody,
                fontSize: YugmaTypeScale.body,
                color: YugmaColors.textPrimary,
              ),
            ),
            const SizedBox(height: YugmaSpacing.s3),
            TextButton(
              onPressed: widget.onCancel,
              child: Text(widget.strings.voiceGoBack),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(YugmaSpacing.s4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Duration counter
          Text(
            _formatDuration(_elapsedSeconds),
            style: TextStyle(
              fontFamily: YugmaFonts.mono,
              fontSize: YugmaTypeScale.display,
              fontWeight: FontWeight.w700,
              color:
                  _isRecording ? YugmaColors.commit : YugmaColors.textPrimary,
            ),
          ),
          const SizedBox(height: YugmaSpacing.s2),

          // Minimum duration hint
          if (_isRecording && _elapsedSeconds < 5)
            Text(
              widget.strings.voiceMinDuration,
              style: TextStyle(
                fontFamily: YugmaFonts.devaBody,
                fontSize: YugmaTypeScale.caption,
                color: YugmaColors.textMuted,
              ),
            ),

          // Recording indicator
          if (_isRecording)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: YugmaSpacing.s3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: YugmaColors.commit,
                    ),
                  ),
                  const SizedBox(width: YugmaSpacing.s2),
                  Text(
                    widget.strings.voiceRecordingInProgress,
                    style: TextStyle(
                      fontFamily: YugmaFonts.devaBody,
                      fontSize: YugmaTypeScale.body,
                      color: YugmaColors.commit,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: YugmaSpacing.s4),

          // Buttons
          if (!_isRecording && !_hasRecording) ...[
            // Not started — show record button
            SizedBox(
              width: 80,
              height: 80,
              child: ElevatedButton(
                onPressed: _startRecording,
                style: ElevatedButton.styleFrom(
                  backgroundColor: YugmaColors.commit,
                  shape: const CircleBorder(),
                ),
                child:
                    Icon(Icons.mic, color: YugmaColors.textOnPrimary, size: 36),
              ),
            ),
            const SizedBox(height: YugmaSpacing.s2),
            TextButton(
              onPressed: widget.onCancel,
              child: Text(
                widget.strings.voiceCancel,
                style: TextStyle(
                  fontFamily: YugmaFonts.devaBody,
                  color: YugmaColors.textMuted,
                ),
              ),
            ),
          ] else if (_isRecording) ...[
            // Recording — show stop button
            SizedBox(
              width: 80,
              height: 80,
              child: ElevatedButton(
                onPressed: _elapsedSeconds >= 5 ? _stopRecording : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _elapsedSeconds >= 5
                      ? YugmaColors.primary
                      : YugmaColors.divider,
                  shape: const CircleBorder(),
                ),
                child: Icon(Icons.stop,
                    color: YugmaColors.textOnPrimary, size: 36),
              ),
            ),
          ] else if (_hasRecording) ...[
            // B1.6 AC #3: send / re-record / cancel
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Re-record
                Column(
                  children: [
                    IconButton(
                      onPressed: _reRecord,
                      icon: Icon(Icons.refresh,
                          color: YugmaColors.textSecondary, size: 28),
                    ),
                    Text(
                      widget.strings.voiceReRecord,
                      style: TextStyle(
                        fontFamily: YugmaFonts.devaBody,
                        fontSize: YugmaTypeScale.caption,
                        color: YugmaColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                // Send
                SizedBox(
                  width: 72,
                  height: 72,
                  child: ElevatedButton(
                    onPressed: _send,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: YugmaColors.primary,
                      shape: const CircleBorder(),
                    ),
                    child: Icon(Icons.send,
                        color: YugmaColors.textOnPrimary, size: 28),
                  ),
                ),
                // Cancel
                Column(
                  children: [
                    IconButton(
                      onPressed: widget.onCancel,
                      icon: Icon(Icons.close,
                          color: YugmaColors.textMuted, size: 28),
                    ),
                    Text(
                      widget.strings.voiceCancelShort,
                      style: TextStyle(
                        fontFamily: YugmaFonts.devaBody,
                        fontSize: YugmaTypeScale.caption,
                        color: YugmaColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
