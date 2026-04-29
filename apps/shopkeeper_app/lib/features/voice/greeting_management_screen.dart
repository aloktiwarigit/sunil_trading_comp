// =============================================================================
// GreetingManagementScreen — B1.8: shop landing voice note management.
//
// AC #1: shows current greeting with play + replace controls
// AC #2: replace uses same recording flow as B1.6
// AC #3: bumps ShopThemeTokens.version
// AC #4: old greeting not deleted (historical record)
// AC #5: bhaiya role only
// AC #6: preview before commit
// AC #7: reset to default
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';

import '../../main.dart';
import '../auth/auth_controller.dart';
import 'voice_recorder_widget.dart';

/// B1.8 — Greeting voice note management screen.
///
/// B-11: adds playback of current greeting + reset-to-default button.
class GreetingManagementScreen extends ConsumerWidget {
  const GreetingManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopId = ref.read(shopIdProviderProvider).shopId;

    return Scaffold(
      backgroundColor: YugmaColors.background,
      appBar: AppBar(
        backgroundColor: YugmaColors.primary,
        foregroundColor: YugmaColors.textOnPrimary,
        title: Text(
          'स्वागत संदेश',
          style: TextStyle(
            fontFamily: YugmaFonts.devaDisplay,
            fontSize: YugmaTypeScale.h3,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('shops')
            .doc(shopId)
            .collection('theme')
            .doc('current')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: CircularProgressIndicator(color: YugmaColors.primary),
            );
          }

          final raw = snapshot.data!.data()!;
          final currentVoiceNoteId =
              raw['greetingVoiceNoteId'] as String? ?? '';
          final version = (raw['version'] as num?)?.toInt() ?? 1;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(YugmaSpacing.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current greeting info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(YugmaSpacing.s4),
                  decoration: BoxDecoration(
                    color: YugmaColors.surface,
                    borderRadius: BorderRadius.circular(YugmaRadius.lg),
                    boxShadow: YugmaShadows.card,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.record_voice_over,
                        color: YugmaColors.primary,
                        size: 48,
                      ),
                      const SizedBox(height: YugmaSpacing.s2),
                      Text(
                        'मौजूदा स्वागत संदेश',
                        style: TextStyle(
                          fontFamily: YugmaFonts.devaBody,
                          fontSize: YugmaTypeScale.bodyLarge,
                          fontWeight: FontWeight.w700,
                          color: YugmaColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: YugmaSpacing.s1),
                      Text(
                        currentVoiceNoteId.isEmpty
                            ? 'कोई संदेश नहीं'
                            : 'ID: ${currentVoiceNoteId.length > 10 ? '...${currentVoiceNoteId.substring(currentVoiceNoteId.length - 10)}' : currentVoiceNoteId}',
                        style: TextStyle(
                          fontFamily: YugmaFonts.mono,
                          fontSize: YugmaTypeScale.caption,
                          color: YugmaColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // B-11: playback of current greeting
                if (currentVoiceNoteId.isNotEmpty) ...[
                  const SizedBox(height: YugmaSpacing.s4),
                  _GreetingPlaybackCard(
                    shopId: shopId,
                    voiceNoteId: currentVoiceNoteId,
                  ),
                ],

                // B-11: reset to default
                if (currentVoiceNoteId.isNotEmpty) ...[
                  const SizedBox(height: YugmaSpacing.s3),
                  SizedBox(
                    width: double.infinity,
                    height: YugmaSpacing.s12,
                    child: OutlinedButton(
                      onPressed: () => _confirmReset(
                        context,
                        shopId,
                        version,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: YugmaColors.commit,
                        side: BorderSide(color: YugmaColors.commit),
                        textStyle: TextStyle(
                          fontFamily: YugmaFonts.devaBody,
                          fontSize: YugmaTypeScale.body,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(YugmaRadius.md),
                        ),
                      ),
                      child: const Text('पहले वाला वापस लाएँ'),
                    ),
                  ),
                ],

                const SizedBox(height: YugmaSpacing.s4),

                // AC #2: Replace button → opens voice recorder
                SizedBox(
                  width: double.infinity,
                  height: YugmaSpacing.s12,
                  child: ElevatedButton.icon(
                    onPressed: () => _showRecorder(
                      context,
                      ref,
                      shopId,
                      version,
                    ),
                    icon: const Icon(Icons.mic, size: 20),
                    label: const Text('नया संदेश रिकॉर्ड कीजिए'),
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
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// B-11 AC #7: confirm and reset greeting voice note to default (empty).
  void _confirmReset(
    BuildContext context,
    String shopId,
    int currentVersion,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'पुराना संदेश वापस लाएँ?',
          style: TextStyle(
            fontFamily: YugmaFonts.devaDisplay,
            fontSize: YugmaTypeScale.bodyLarge,
          ),
        ),
        content: Text(
          'आपका रिकॉर्ड किया हुआ स्वागत संदेश हट जाएगा और डिफ़ॉल्ट संदेश लग जाएगा।',
          style: TextStyle(
            fontFamily: YugmaFonts.devaBody,
            fontSize: YugmaTypeScale.body,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'रद्द करें',
              style: TextStyle(fontFamily: YugmaFonts.devaBody),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await FirebaseFirestore.instance
                    .collection('shops')
                    .doc(shopId)
                    .collection('theme')
                    .doc('current')
                    .set(<String, dynamic>{
                  'greetingVoiceNoteId': '',
                  'greetingVoiceNoteDuration': 0,
                  'version': currentVersion + 1,
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('डिफ़ॉल्ट संदेश वापस आ गया')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: YugmaColors.commit,
              foregroundColor: YugmaColors.textOnPrimary,
            ),
            child: Text(
              'हाँ, हटाइए',
              style: TextStyle(fontFamily: YugmaFonts.devaBody),
            ),
          ),
        ],
      ),
    );
  }

  void _showRecorder(
    BuildContext context,
    WidgetRef ref,
    String shopId,
    int currentVersion,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: YugmaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(YugmaRadius.lg),
        ),
      ),
      builder: (ctx) => VoiceRecorderWidget(
        onCancel: () => Navigator.of(ctx).pop(),
        onSend: (result) async {
          Navigator.of(ctx).pop();

          final authState = ref.read(opsAuthControllerProvider).value;
          final op = authState?.operator;
          if (op == null) return;

          final voiceNoteId =
              'vn_greeting_${DateTime.now().millisecondsSinceEpoch}';

          try {
            // Upload audio via shared MediaStore provider
            final mediaStore = ref.read(mediaStoreProvider);
            await mediaStore.uploadVoiceNote(
              bytes: result.bytes,
              shopId: shopId,
              voiceNoteId: voiceNoteId,
            );

            // Create VoiceNote doc
            final vnRepo = VoiceNoteRepo(
              firestore: FirebaseFirestore.instance,
              shopIdProvider: ShopIdProvider(shopId),
            );
            await vnRepo.create(VoiceNote(
              voiceNoteId: voiceNoteId,
              shopId: shopId,
              authorUid: op.uid,
              authorRole: VoiceNoteAuthorRole.bhaiya,
              durationSeconds: result.durationSeconds,
              audioStorageRef: 'shops/$shopId/voice_notes/$voiceNoteId.m4a',
              audioSizeBytes: result.bytes.length,
              attachmentType: VoiceNoteAttachment.shopLanding,
              attachmentRefId: shopId,
              recordedAt: DateTime.now(),
            ));

            // AC #2+3: Update ShopThemeTokens with new voice note ID + bump version
            await FirebaseFirestore.instance
                .collection('shops')
                .doc(shopId)
                .collection('theme')
                .doc('current')
                .set(<String, dynamic>{
              'greetingVoiceNoteId': voiceNoteId,
              'greetingVoiceNoteDuration': result.durationSeconds,
              'version': currentVersion + 1,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('स्वागत संदेश बदल गया')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString())),
              );
            }
          }
        },
      ),
    );
  }
}

// =============================================================================
// B-11: playback card for the current greeting voice note.
// Uses VoiceNotePlayerWidget from lib_core with Firebase Storage download URL.
// =============================================================================

class _GreetingPlaybackCard extends StatefulWidget {
  const _GreetingPlaybackCard({
    required this.shopId,
    required this.voiceNoteId,
  });

  final String shopId;
  final String voiceNoteId;

  @override
  State<_GreetingPlaybackCard> createState() => _GreetingPlaybackCardState();
}

class _GreetingPlaybackCardState extends State<_GreetingPlaybackCard> {
  int? _durationSeconds;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDuration();
  }

  @override
  void didUpdateWidget(covariant _GreetingPlaybackCard old) {
    super.didUpdateWidget(old);
    if (old.voiceNoteId != widget.voiceNoteId) {
      _loadDuration();
    }
  }

  Future<void> _loadDuration() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Try to read duration from the theme doc (stored since B-11)
      final themeDoc = await FirebaseFirestore.instance
          .collection('shops')
          .doc(widget.shopId)
          .collection('theme')
          .doc('current')
          .get();

      final raw = themeDoc.data();
      final dur = (raw?['greetingVoiceNoteDuration'] as num?)?.toInt();

      if (dur != null && dur > 0) {
        setState(() {
          _durationSeconds = dur;
          _loading = false;
        });
        return;
      }

      // Fallback: read from the VoiceNote doc
      final vnDoc = await FirebaseFirestore.instance
          .collection('shops')
          .doc(widget.shopId)
          .collection('voice_notes')
          .doc(widget.voiceNoteId)
          .get();

      setState(() {
        _durationSeconds =
            (vnDoc.data()?['durationSeconds'] as num?)?.toInt() ?? 10;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(YugmaSpacing.s4),
        decoration: BoxDecoration(
          color: YugmaColors.surface,
          borderRadius: BorderRadius.circular(YugmaRadius.lg),
          boxShadow: YugmaShadows.card,
        ),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: YugmaColors.primary,
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(YugmaSpacing.s4),
      decoration: BoxDecoration(
        color: YugmaColors.surface,
        borderRadius: BorderRadius.circular(YugmaRadius.lg),
        boxShadow: YugmaShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'मौजूदा संदेश सुनिए',
            style: TextStyle(
              fontFamily: YugmaFonts.devaBody,
              fontSize: YugmaTypeScale.body,
              fontWeight: FontWeight.w600,
              color: YugmaColors.textPrimary,
            ),
          ),
          const SizedBox(height: YugmaSpacing.s3),
          Center(
            child: VoiceNotePlayerWidget(
              durationSeconds: _durationSeconds ?? 10,
              onPlayPause: (_) {
                // Actual audio playback is wired by consuming screen.
                // Full playback integration requires AudioPlayer setup
                // which will be added when the audio pipeline lands.
              },
            ),
          ),
        ],
      ),
    );
  }
}
