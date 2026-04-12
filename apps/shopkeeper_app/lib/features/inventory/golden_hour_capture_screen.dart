// =============================================================================
// GoldenHourCaptureScreen — S4.5: golden hour photo capture for SKUs.
//
// AC #1: from SKU detail, button opens device camera
// AC #2: raking light guide overlay (placeholder in v1)
// AC #3: preview with save options
// AC #4: upload to Cloudinary via MediaStore
// AC #5: GoldenHourPhoto Firestore doc created
// AC #6: SKU goldenHourPhotoIds updated
// AC #7: customer sees on next view
// =============================================================================

import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lib_core/lib_core.dart';

import '../../main.dart';
import 'package:path_provider/path_provider.dart';

import '../auth/auth_controller.dart';

/// S4.5 — Golden Hour photo capture screen.
///
/// Opens the device camera, captures a photo, uploads via MediaStore,
/// creates a GoldenHourPhoto doc, and updates the SKU's photo array.
class GoldenHourCaptureScreen extends ConsumerStatefulWidget {
  const GoldenHourCaptureScreen({
    super.key,
    required this.skuId,
    required this.skuName,
  });

  final String skuId;
  final String skuName;

  @override
  ConsumerState<GoldenHourCaptureScreen> createState() =>
      _GoldenHourCaptureScreenState();
}

class _GoldenHourCaptureScreenState
    extends ConsumerState<GoldenHourCaptureScreen> {
  Uint8List? _capturedBytes;
  bool _uploading = false;
  String _selectedTier = 'hero'; // 'hero' or 'working'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YugmaColors.background,
      appBar: AppBar(
        backgroundColor: YugmaColors.primary,
        foregroundColor: YugmaColors.textOnPrimary,
        title: Text(
          'Golden Hour फ़ोटो',
          style: TextStyle(
            fontFamily: YugmaFonts.devaDisplay,
            fontSize: YugmaTypeScale.h3,
          ),
        ),
      ),
      body: _capturedBytes == null
          ? _buildCaptureView()
          : _buildPreview(),
    );
  }

  Widget _buildCaptureView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // AC #2: raking light guide placeholder
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              border: Border.all(
                color: YugmaColors.accent.withValues(alpha: 0.5),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(YugmaRadius.lg),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wb_sunny_outlined,
                  color: YugmaColors.accent,
                  size: 48,
                ),
                const SizedBox(height: YugmaSpacing.s2),
                Text(
                  'सूरज की रोशनी तिरछी पड़नी चाहिए',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: YugmaFonts.devaBody,
                    fontSize: YugmaTypeScale.caption,
                    color: YugmaColors.textSecondary,
                  ),
                ),
                const SizedBox(height: YugmaSpacing.s1),
                Text(
                  widget.skuName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: YugmaFonts.devaBody,
                    fontSize: YugmaTypeScale.body,
                    fontWeight: FontWeight.w600,
                    color: YugmaColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: YugmaSpacing.s8),
          // Camera button — uses image_picker pattern but simplified
          // to just pick from gallery for now (camera requires platform config)
          SizedBox(
            width: 80,
            height: 80,
            child: ElevatedButton(
              onPressed: _capturePhoto,
              style: ElevatedButton.styleFrom(
                backgroundColor: YugmaColors.primary,
                shape: const CircleBorder(),
              ),
              child: Icon(
                Icons.camera_alt,
                color: YugmaColors.textOnPrimary,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: YugmaSpacing.s2),
          Text(
            'फ़ोटो लीजिए',
            style: TextStyle(
              fontFamily: YugmaFonts.devaBody,
              fontSize: YugmaTypeScale.caption,
              color: YugmaColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  /// Capture a photo using the device camera via image_picker.
  Future<void> _capturePhoto() async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (photo == null) return; // User cancelled camera.

    final bytes = await photo.readAsBytes();
    setState(() {
      _capturedBytes = bytes;
    });
  }

  Widget _buildPreview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(YugmaSpacing.s4),
      child: Column(
        children: [
          // Photo preview
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              color: YugmaColors.divider,
              borderRadius: BorderRadius.circular(YugmaRadius.lg),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(YugmaRadius.lg),
              child: Image.memory(
                _capturedBytes!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 300,
              ),
            ),
          ),
          const SizedBox(height: YugmaSpacing.s4),

          // AC #3: tier selection
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  selected: _selectedTier == 'hero',
                  label: Text(
                    'Hero फ़ोटो',
                    style: TextStyle(fontFamily: YugmaFonts.devaBody),
                  ),
                  selectedColor: YugmaColors.primary.withValues(alpha: 0.15),
                  onSelected: (_) =>
                      setState(() => _selectedTier = 'hero'),
                ),
              ),
              const SizedBox(width: YugmaSpacing.s2),
              Expanded(
                child: ChoiceChip(
                  selected: _selectedTier == 'working',
                  label: Text(
                    'Working फ़ोटो',
                    style: TextStyle(fontFamily: YugmaFonts.devaBody),
                  ),
                  selectedColor: YugmaColors.primary.withValues(alpha: 0.15),
                  onSelected: (_) =>
                      setState(() => _selectedTier = 'working'),
                ),
              ),
            ],
          ),
          const SizedBox(height: YugmaSpacing.s4),

          // Save + retake buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _capturedBytes = null),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: YugmaColors.textSecondary,
                  ),
                  child: Text(
                    'दुबारा लीजिए',
                    style: TextStyle(fontFamily: YugmaFonts.devaBody),
                  ),
                ),
              ),
              const SizedBox(width: YugmaSpacing.s2),
              Expanded(
                child: ElevatedButton(
                  onPressed: _uploading ? null : _upload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: YugmaColors.primary,
                    foregroundColor: YugmaColors.textOnPrimary,
                    textStyle: TextStyle(
                      fontFamily: YugmaFonts.devaBody,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: _uploading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: YugmaColors.textOnPrimary,
                          ),
                        )
                      : Text('सहेजिए'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _upload() async {
    if (_capturedBytes == null) return;
    setState(() => _uploading = true);

    final shopId = ref.read(shopIdProviderProvider).shopId;
    final photoId = 'gh_${DateTime.now().millisecondsSinceEpoch}';

    try {
      // AC #4: upload to Cloudinary via shared MediaStore provider
      final mediaStore = ref.read(mediaStoreProvider);
      await mediaStore.uploadCatalogImage(
        bytes: _capturedBytes!,
        shopId: shopId,
        type: CatalogMediaType.goldenHour,
        metadata: {'photoId': photoId, 'skuId': widget.skuId},
      );

      // AC #5: create GoldenHourPhoto Firestore doc
      await FirebaseFirestore.instance
          .collection('shops')
          .doc(shopId)
          .collection('golden_hour_photos')
          .doc(photoId)
          .set(<String, dynamic>{
        'photoId': photoId,
        'shopId': shopId,
        'skuId': widget.skuId,
        'tier': _selectedTier,
        'capturedAt': FieldValue.serverTimestamp(),
        'sizeBytes': _capturedBytes!.length,
      });

      // AC #6: append to SKU's goldenHourPhotoIds
      await FirebaseFirestore.instance
          .collection('shops')
          .doc(shopId)
          .collection('inventory')
          .doc(widget.skuId)
          .set(<String, dynamic>{
        'goldenHourPhotoIds': FieldValue.arrayUnion([photoId]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Golden Hour फ़ोटो सहेजा गया')),
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
      if (mounted) setState(() => _uploading = false);
    }
  }
}
