// =============================================================================
// EditSkuScreen — S4.4 edit existing SKU price, stock, and description.
//
// Per S4.4:
//   AC #1: Tap SKU → detail view with editable fields
//   AC #2: Save on tap
//   AC #4: Quick stock +/- buttons without opening full edit
//
// Edge cases:
//   #1: SKU in active draft — snapshot preserved, new price for future drafts
//   #3: Non-bhaiya operator tries delete — blocked (not exposed in this screen)
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lib_core/lib_core.dart';

import '../../main.dart';
import '../auth/auth_controller.dart';
import '../voice/voice_recorder_widget.dart';

/// Edit SKU screen — opens from inventory list tap.
class EditSkuScreen extends ConsumerStatefulWidget {
  const EditSkuScreen({super.key, required this.skuId});
  final String skuId;

  @override
  ConsumerState<EditSkuScreen> createState() => _EditSkuScreenState();
}

class _EditSkuScreenState extends ConsumerState<EditSkuScreen> {
  final _basePriceController = TextEditingController();
  final _floorPriceController = TextEditingController();
  final _stockCountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _inStock = true;
  bool _saving = false;
  bool _loaded = false;

  // CR #10: create stream once in initState to avoid re-subscription on rebuild.
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _skuStream;

  @override
  void initState() {
    super.initState();
    final shopId = ref.read(shopIdProviderProvider).shopId;
    _skuStream = FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .collection('inventory')
        .doc(widget.skuId)
        .snapshots();
  }

  @override
  void dispose() {
    _basePriceController.dispose();
    _floorPriceController.dispose();
    _stockCountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _populateFromSku(InventorySku sku) {
    if (_loaded) return;
    _loaded = true;
    _basePriceController.text = sku.basePrice.toString();
    _floorPriceController.text = sku.negotiableDownTo.toString();
    _stockCountController.text = (sku.stockCount ?? 0).toString();
    _descriptionController.text = sku.description;
    _inStock = sku.inStock;
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
          strings.editSkuTitle,
          style: TextStyle(
            fontFamily: YugmaFonts.devaDisplay,
            fontSize: YugmaTypeScale.h3,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _skuStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: CircularProgressIndicator(color: YugmaColors.primary),
            );
          }
          final raw = snapshot.data!.data()!;
          final sku = InventorySku.fromJson(<String, dynamic>{
            ...raw,
            'skuId': widget.skuId,
            'createdAt': _normalizeTimestamp(raw['createdAt']),
            'updatedAt': _normalizeTimestamp(raw['updatedAt']),
          });
          _populateFromSku(sku);

          return _buildForm(context, sku, strings);
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, InventorySku sku, AppStrings strings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(YugmaSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SKU name (read-only)
          Text(
            sku.nameDevanagari,
            style: TextStyle(
              fontFamily: YugmaFonts.devaDisplay,
              fontSize: YugmaTypeScale.h2,
              color: YugmaColors.textPrimary,
            ),
          ),
          const SizedBox(height: YugmaSpacing.s1),
          Text(
            sku.name,
            style: TextStyle(
              fontFamily: YugmaFonts.enBody,
              fontSize: YugmaTypeScale.caption,
              color: YugmaColors.textSecondary,
            ),
          ),
          const SizedBox(height: YugmaSpacing.s6),

          // Base price
          _buildField(strings.skuBasePriceLabel, _basePriceController,
              keyboardType: TextInputType.number),
          const SizedBox(height: YugmaSpacing.s4),

          // Negotiable floor
          _buildField(strings.skuNegotiableFloorLabel, _floorPriceController,
              keyboardType: TextInputType.number),
          const SizedBox(height: YugmaSpacing.s4),

          // Stock toggle + quick adjust (AC #4)
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.skuInStockLabel,
                  style: TextStyle(
                    fontFamily: YugmaFonts.devaBody,
                    fontSize: YugmaTypeScale.body,
                    color: YugmaColors.textPrimary,
                  ),
                ),
              ),
              Switch(
                value: _inStock,
                activeColor: YugmaColors.primary,
                onChanged: (v) => setState(() => _inStock = v),
              ),
            ],
          ),
          const SizedBox(height: YugmaSpacing.s2),

          // Stock count with +/- buttons (AC #4)
          Row(
            children: [
              Text(
                strings.skuStockAdjustLabel,
                style: TextStyle(
                  fontFamily: YugmaFonts.devaBody,
                  fontSize: YugmaTypeScale.body,
                  color: YugmaColors.textPrimary,
                ),
              ),
              const Spacer(),
              _StockButton(
                icon: Icons.remove,
                onTap: () {
                  final current =
                      int.tryParse(_stockCountController.text) ?? 0;
                  if (current > 0) {
                    setState(() {
                      _stockCountController.text = (current - 1).toString();
                    });
                  }
                },
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: YugmaSpacing.s3),
                child: SizedBox(
                  width: 60,
                  child: TextField(
                    controller: _stockCountController,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      fontFamily: YugmaFonts.mono,
                      fontSize: YugmaTypeScale.bodyLarge,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: YugmaSpacing.s2,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(YugmaRadius.md),
                      ),
                    ),
                  ),
                ),
              ),
              _StockButton(
                icon: Icons.add,
                onTap: () {
                  final current =
                      int.tryParse(_stockCountController.text) ?? 0;
                  setState(() {
                    _stockCountController.text = (current + 1).toString();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: YugmaSpacing.s4),

          // Description
          _buildField(
            strings.skuDescriptionLabel,
            _descriptionController,
            maxLines: 3,
          ),
          const SizedBox(height: YugmaSpacing.s4),

          // B1.6 AC #1: Voice note recording button
          SizedBox(
            height: YugmaSpacing.s12,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showVoiceRecorder(context, sku, strings),
              icon: const Icon(Icons.mic, size: 20),
              label: Text(strings.voiceNoteButtonLabel),
              style: OutlinedButton.styleFrom(
                foregroundColor: YugmaColors.accent,
                side: BorderSide(color: YugmaColors.accent),
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
          const SizedBox(height: YugmaSpacing.s6),

          // Save button
          SizedBox(
            height: YugmaSpacing.s12,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : () => _handleSave(sku, strings),
              style: ElevatedButton.styleFrom(
                backgroundColor: YugmaColors.primary,
                foregroundColor: YugmaColors.textOnPrimary,
                disabledBackgroundColor: YugmaColors.divider,
                textStyle: TextStyle(
                  fontFamily: YugmaFonts.devaBody,
                  fontSize: YugmaTypeScale.body,
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
                  : Text(strings.skuSaveChangesButton),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: YugmaFonts.devaBody,
            fontSize: YugmaTypeScale.body,
            color: YugmaColors.textSecondary,
          ),
        ),
        const SizedBox(height: YugmaSpacing.s1),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(
            fontFamily: YugmaFonts.devaBody,
            fontSize: YugmaTypeScale.body,
          ),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(YugmaRadius.md),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(YugmaRadius.md),
              borderSide: BorderSide(color: YugmaColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  /// B1.6 AC #1–6: open voice recorder, upload to Storage, create VoiceNote doc.
  void _showVoiceRecorder(
    BuildContext context,
    InventorySku sku,
    AppStrings strings,
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

          final shopId = ref.read(shopIdProviderProvider).shopId;
          final authState = ref.read(opsAuthControllerProvider).value;
          final op = authState?.operator;
          if (op == null) return;

          final voiceNoteId = 'vn_${DateTime.now().millisecondsSinceEpoch}';

          // Step 1: Upload audio via MediaStore adapter.
          try {
            // Upload via shared MediaStore provider.
            final mediaStore = ref.read(mediaStoreProvider);
            await mediaStore.uploadVoiceNote(
              bytes: result.bytes,
              shopId: shopId,
              voiceNoteId: voiceNoteId,
            );

            // Step 2: Create VoiceNote metadata doc.
            final repo = VoiceNoteRepo(
              firestore: FirebaseFirestore.instance,
              shopIdProvider: ShopIdProvider(shopId),
            );
            await repo.create(VoiceNote(
              voiceNoteId: voiceNoteId,
              shopId: shopId,
              authorUid: op.uid,
              authorRole: op.isBhaiya
                  ? VoiceNoteAuthorRole.bhaiya
                  : VoiceNoteAuthorRole.beta,
              durationSeconds: result.durationSeconds,
              audioStorageRef:
                  'shops/$shopId/voice_notes/$voiceNoteId.m4a',
              audioSizeBytes: result.bytes.length,
              attachmentType: VoiceNoteAttachment.sku,
              attachmentRefId: sku.skuId,
              recordedAt: DateTime.now(),
            ));

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(strings.voiceNoteAttached)),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString())),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _handleSave(InventorySku sku, AppStrings strings) async {
    final basePrice = int.tryParse(_basePriceController.text.trim()) ?? 0;
    final floorPrice = int.tryParse(_floorPriceController.text.trim()) ?? 0;
    final stockCount = int.tryParse(_stockCountController.text.trim());

    // CR #5: validate before save — basePrice > 0, floorPrice <= basePrice.
    if (basePrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.validationPricePositive)),
      );
      return;
    }
    if (floorPrice > basePrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.validationFloorExceedsBase)),
      );
      return;
    }

    setState(() => _saving = true);

    final updated = sku.copyWith(
      basePrice: basePrice,
      negotiableDownTo: floorPrice,
      inStock: _inStock,
      stockCount: stockCount,
      description: _descriptionController.text.trim(),
    );

    final shopId = ref.read(shopIdProviderProvider).shopId;
    final repo = InventorySkuRepo(
      firestore: FirebaseFirestore.instance,
      shopIdProvider: ShopIdProvider(shopId),
    );

    try {
      await repo.upsert(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.skuChangesSaved)),
        );
        context.pop();
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

  static Object? _normalizeTimestamp(Object? value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    return value;
  }
}

/// Small stock +/- button.
class _StockButton extends StatelessWidget {
  const _StockButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: YugmaColors.primary.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(YugmaRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(YugmaRadius.sm),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: YugmaColors.primary),
        ),
      ),
    );
  }
}
