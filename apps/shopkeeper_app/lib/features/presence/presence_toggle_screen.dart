// =============================================================================
// PresenceToggleScreen — B1.9 AC #3: shopkeeper toggles presence status.
//
// 4 states: available / away / busy_with_customer / at_event
// Each has a Devanagari message + optional return time.
// B1.10 AC #4: record away voice note from here.
// =============================================================================

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';

import '../../main.dart';
import '../voice/voice_recorder_widget.dart';

/// Presence status options per B1.9 AC #1.
enum PresenceStatus {
  available(Icons.storefront),
  away(Icons.directions_walk),
  busyWithCustomer(Icons.people),
  atEvent(Icons.celebration);

  const PresenceStatus(this.icon);
  final IconData icon;

  /// Resolve the display label from AppStrings (D-2 locale-aware).
  String label(AppStrings strings) => switch (this) {
        available => strings.presenceAtShop,
        away => strings.presenceAway,
        busyWithCustomer => strings.presenceBusyWithCustomer,
        atEvent => strings.presenceAtEvent,
      };
}

/// B1.9 — Presence status toggle screen.
class PresenceToggleScreen extends ConsumerStatefulWidget {
  const PresenceToggleScreen({super.key});

  @override
  ConsumerState<PresenceToggleScreen> createState() =>
      _PresenceToggleScreenState();
}

class _PresenceToggleScreenState extends ConsumerState<PresenceToggleScreen> {
  PresenceStatus _selected = PresenceStatus.available;
  final _returnTimeController = TextEditingController();
  bool _saving = false;

  /// B-10: absence voice note bytes + duration, populated by VoiceRecorderWidget.
  Uint8List? _absenceVoiceNoteBytes;
  int _absenceVoiceNoteDuration = 0;

  @override
  void dispose() {
    _returnTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = const AppStringsHi();
    return Scaffold(
      backgroundColor: YugmaColors.background,
      appBar: AppBar(
        backgroundColor: YugmaColors.primary,
        foregroundColor: YugmaColors.textOnPrimary,
        title: Text(
          strings.presenceMyAvailability,
          style: TextStyle(
            fontFamily: YugmaFonts.devaDisplay,
            fontSize: YugmaTypeScale.h3,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(YugmaSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status options
            ...PresenceStatus.values.map((status) {
              final isSelected = _selected == status;
              return Padding(
                padding: const EdgeInsets.only(bottom: YugmaSpacing.s2),
                child: InkWell(
                  onTap: () => setState(() => _selected = status),
                  borderRadius: BorderRadius.circular(YugmaRadius.lg),
                  child: Container(
                    padding: const EdgeInsets.all(YugmaSpacing.s4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? YugmaColors.primary.withValues(alpha: 0.08)
                          : YugmaColors.surface,
                      borderRadius: BorderRadius.circular(YugmaRadius.lg),
                      border: Border.all(
                        color: isSelected
                            ? YugmaColors.primary
                            : YugmaColors.divider,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(status.icon, color: YugmaColors.primary, size: 24),
                        const SizedBox(width: YugmaSpacing.s3),
                        Text(
                          status.label(strings),
                          style: TextStyle(
                            fontFamily: YugmaFonts.devaBody,
                            fontSize: YugmaTypeScale.body,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: YugmaColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            // Return time (for away/atEvent)
            if (_selected != PresenceStatus.available) ...[
              const SizedBox(height: YugmaSpacing.s2),
              TextField(
                controller: _returnTimeController,
                decoration: InputDecoration(
                  labelText: strings.presenceReturnTimePrompt,
                  labelStyle: TextStyle(fontFamily: YugmaFonts.devaBody),
                  hintText: strings.presenceReturnTimeDefault,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(YugmaRadius.md),
                  ),
                ),
                style: TextStyle(
                  fontFamily: YugmaFonts.devaBody,
                  fontSize: YugmaTypeScale.body,
                ),
              ),
            ],

            // B-10: absence voice note (away / atEvent only)
            if (_selected == PresenceStatus.away ||
                _selected == PresenceStatus.atEvent) ...[
              const SizedBox(height: YugmaSpacing.s3),
              Text(
                strings.presenceVoicePrompt,
                style: TextStyle(
                  fontFamily: YugmaFonts.devaBody,
                  fontSize: YugmaTypeScale.body,
                  fontWeight: FontWeight.w600,
                  color: YugmaColors.textPrimary,
                ),
              ),
              const SizedBox(height: YugmaSpacing.s2),
              if (_absenceVoiceNoteBytes != null)
                Container(
                  padding: const EdgeInsets.all(YugmaSpacing.s3),
                  decoration: BoxDecoration(
                    color: YugmaColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(YugmaRadius.md),
                    border: Border.all(color: YugmaColors.primary),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: YugmaColors.primary, size: 20),
                      const SizedBox(width: YugmaSpacing.s2),
                      Expanded(
                        child: Text(
                          strings.presenceVoiceRecorded(_absenceVoiceNoteDuration),
                          style: TextStyle(
                            fontFamily: YugmaFonts.devaBody,
                            fontSize: YugmaTypeScale.caption,
                            color: YugmaColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() {
                          _absenceVoiceNoteBytes = null;
                          _absenceVoiceNoteDuration = 0;
                        }),
                        icon: Icon(Icons.close, color: YugmaColors.textMuted, size: 20),
                        tooltip: strings.presenceRemoveVoice,
                      ),
                    ],
                  ),
                )
              else
                VoiceRecorderWidget(
                  onSend: (result) {
                    setState(() {
                      _absenceVoiceNoteBytes = Uint8List.fromList(result.bytes);
                      _absenceVoiceNoteDuration = result.durationSeconds;
                    });
                  },
                  onCancel: () {
                    // Nothing to do — widget stays in place
                  },
                ),
            ],

            const Spacer(),

            // Save button
            SizedBox(
              width: double.infinity,
              height: YugmaSpacing.s12,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: YugmaColors.primary,
                  foregroundColor: YugmaColors.textOnPrimary,
                  textStyle: TextStyle(
                    fontFamily: YugmaFonts.devaBody,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(YugmaRadius.md),
                  ),
                ),
                child: _saving
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: YugmaColors.textOnPrimary,
                        ),
                      )
                    : Text(strings.presenceUpdateButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final shopId = ref.read(shopIdProviderProvider).shopId;

    try {
      // B-10: upload absence voice note if recorded
      String? absenceVoiceStorageRef;
      if (_absenceVoiceNoteBytes != null) {
        final voiceNoteId =
            'vn_absence_${DateTime.now().millisecondsSinceEpoch}';
        final mediaStore = ref.read(mediaStoreProvider);
        await mediaStore.uploadVoiceNote(
          bytes: _absenceVoiceNoteBytes!.toList(),
          shopId: shopId,
          voiceNoteId: voiceNoteId,
        );
        absenceVoiceStorageRef =
            'shops/$shopId/voice_notes/$voiceNoteId.m4a';
      }

      await FirebaseFirestore.instance
          .collection('shops')
          .doc(shopId)
          .set(<String, dynamic>{
        'presenceStatus': _selected.name,
        'presenceMessage': _selected.label(const AppStringsHi()),
        'presenceReturnTime': _returnTimeController.text.trim(),
        'presenceUpdatedAt': FieldValue.serverTimestamp(),
        if (absenceVoiceStorageRef != null)
          'absenceVoiceNoteRef': absenceVoiceStorageRef,
        if (absenceVoiceStorageRef != null)
          'absenceVoiceNoteDuration': _absenceVoiceNoteDuration,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(const AppStringsHi().presenceUpdated)),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
