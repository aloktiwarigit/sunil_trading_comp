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
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';

import '../auth/auth_controller.dart';
import 'voice_recorder_widget.dart';

/// B1.8 — Greeting voice note management screen.
class GreetingManagementScreen extends ConsumerWidget {
  const GreetingManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = const AppStringsHi();
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

          final voiceNoteId = 'vn_greeting_${DateTime.now().millisecondsSinceEpoch}';

          try {
            // Upload audio
            final mediaStore = MediaStoreCloudinaryFirebase(
              firebaseStorage: FirebaseStorage.instance,
              cloudinaryCloudName: '',
            );
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
