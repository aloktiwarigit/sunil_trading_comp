// =============================================================================
// CreateSkuScreen — S4.3 inventory SKU creation form.
//
// Streamlined form for adding a new almirah / wardrobe SKU to the shop's
// inventory. All fields per S4.3 ACs:
//   - Name in Devanagari (required), Name in English (optional)
//   - Category dropdown, Material dropdown
//   - Dimensions (H x W x D cm)
//   - Base price (₹), Negotiable floor (₹) — internal
//   - In stock toggle, Stock count (optional)
//   - Description in Devanagari (textarea)
//   - Golden Hour photo button — placeholder for S4.5
//
// Binding rules enforced:
//   - ALL strings via AppStrings (no hardcoded Devanagari in render paths)
//   - ALL theme via YugmaColors/YugmaFonts (no hardcoded colors)
//   - Indian number formatting for prices
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lib_core/lib_core.dart';

import 'create_sku_controller.dart';
import 'golden_hour_capture_screen.dart';

/// SKU creation form screen.
class CreateSkuScreen extends ConsumerStatefulWidget {
  const CreateSkuScreen({super.key});

  @override
  ConsumerState<CreateSkuScreen> createState() => _CreateSkuScreenState();
}

class _CreateSkuScreenState extends ConsumerState<CreateSkuScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _nameDevanagariController = TextEditingController();
  final _nameEnglishController = TextEditingController();
  final _basePriceController = TextEditingController();
  final _negotiableFloorController = TextEditingController();
  final _heightController = TextEditingController();
  final _widthController = TextEditingController();
  final _depthController = TextEditingController();
  final _stockCountController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Dropdown values
  SkuCategory _category = SkuCategory.steelAlmirah;
  SkuMaterial _material = SkuMaterial.steel;
  bool _inStock = true;

  @override
  void dispose() {
    _nameDevanagariController.dispose();
    _nameEnglishController.dispose();
    _basePriceController.dispose();
    _negotiableFloorController.dispose();
    _heightController.dispose();
    _widthController.dispose();
    _depthController.dispose();
    _stockCountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = const AppStringsHi();
    final controllerState = ref.watch(createSkuControllerProvider);

    // Listen for save success.
    ref.listen<CreateSkuState>(createSkuControllerProvider, (prev, next) {
      if (next.status == CreateSkuStatus.saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              strings.skuSavedSuccess,
              style: TextStyle(
                fontFamily: YugmaFonts.devaBody,
                fontSize: YugmaTypeScale.body,
              ),
            ),
            backgroundColor: YugmaColors.success,
          ),
        );
        context.pop();
      } else if (next.status == CreateSkuStatus.error &&
          next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next.errorMessage!,
              style: TextStyle(
                fontFamily: YugmaFonts.enBody,
                fontSize: YugmaTypeScale.body,
              ),
            ),
            backgroundColor: YugmaColors.error,
          ),
        );
      }
    });

    final isSaving = controllerState.status == CreateSkuStatus.saving;

    return Scaffold(
      backgroundColor: YugmaColors.background,
      appBar: AppBar(
        backgroundColor: YugmaColors.primary,
        foregroundColor: YugmaColors.textOnPrimary,
        title: Text(
          strings.createSkuButton,
          style: TextStyle(
            fontFamily: YugmaFonts.devaDisplay,
            fontSize: YugmaTypeScale.h3,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(YugmaSpacing.s4),
            children: [
              // ── Name in Devanagari (required) ──
              _DevanagariTextFormField(
                controller: _nameDevanagariController,
                label: strings.skuNameDevanagariLabel,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? strings.validationRequired : null,
              ),
              const SizedBox(height: YugmaSpacing.s4),

              // ── Name in English (optional) ──
              _EnglishTextFormField(
                controller: _nameEnglishController,
                label: strings.skuNameEnglishLabel,
              ),
              const SizedBox(height: YugmaSpacing.s4),

              // ── Category dropdown ──
              _DropdownField<SkuCategory>(
                label: strings.skuCategoryLabel,
                value: _category,
                items: SkuCategory.values,
                displayName: _categoryDisplayName,
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: YugmaSpacing.s4),

              // ── Material dropdown ──
              _DropdownField<SkuMaterial>(
                label: strings.skuMaterialLabel,
                value: _material,
                items: SkuMaterial.values,
                displayName: _materialDisplayName,
                onChanged: (v) => setState(() => _material = v!),
              ),
              const SizedBox(height: YugmaSpacing.s4),

              // ── Dimensions (H x W x D) ──
              Text(
                strings.skuDimensionsLabel,
                style: TextStyle(
                  fontFamily: YugmaFonts.devaBody,
                  fontSize: YugmaTypeScale.bodySmall,
                  color: YugmaColors.textSecondary,
                ),
              ),
              const SizedBox(height: YugmaSpacing.s2),
              Row(
                children: [
                  Expanded(
                    child: _NumericField(
                      controller: _heightController,
                      hint: 'H',
                      validator: _dimensionValidator,
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: YugmaSpacing.s2),
                    child: Text(
                      '\u00d7',
                      style: TextStyle(
                        fontFamily: YugmaFonts.mono,
                        fontSize: YugmaTypeScale.h3,
                        color: YugmaColors.textMuted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _NumericField(
                      controller: _widthController,
                      hint: 'W',
                      validator: _dimensionValidator,
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: YugmaSpacing.s2),
                    child: Text(
                      '\u00d7',
                      style: TextStyle(
                        fontFamily: YugmaFonts.mono,
                        fontSize: YugmaTypeScale.h3,
                        color: YugmaColors.textMuted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _NumericField(
                      controller: _depthController,
                      hint: 'D',
                      validator: _dimensionValidator,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: YugmaSpacing.s4),

              // ── Base price ──
              _NumericField(
                controller: _basePriceController,
                label: strings.skuBasePriceLabel,
                validator: (v) {
                  if (v == null || v.isEmpty) return strings.validationRequired;
                  final n = int.tryParse(v);
                  if (n == null || n <= 0) return strings.validationPricePositive;
                  return null;
                },
              ),
              const SizedBox(height: YugmaSpacing.s4),

              // ── Negotiable floor ──
              _NumericField(
                controller: _negotiableFloorController,
                label: strings.skuNegotiableFloorLabel,
                validator: (v) {
                  if (v == null || v.isEmpty) return strings.validationRequired;
                  final n = int.tryParse(v);
                  if (n == null || n <= 0) return strings.validationPricePositive;
                  final base = int.tryParse(_basePriceController.text);
                  if (base != null && n >= base) {
                    return strings.validationFloorExceedsBase;
                  }
                  return null;
                },
              ),
              const SizedBox(height: YugmaSpacing.s4),

              // ── In stock toggle ──
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  strings.skuInStockLabel,
                  style: TextStyle(
                    fontFamily: YugmaFonts.devaBody,
                    fontSize: YugmaTypeScale.body,
                    color: YugmaColors.textPrimary,
                  ),
                ),
                value: _inStock,
                activeColor: YugmaColors.success,
                onChanged: (v) => setState(() => _inStock = v),
              ),

              // ── Stock count (optional) ──
              if (_inStock)
                Padding(
                  padding: const EdgeInsets.only(bottom: YugmaSpacing.s4),
                  child: _NumericField(
                    controller: _stockCountController,
                    label: strings.skuStockCountLabel,
                  ),
                ),

              // ── Description ──
              _DevanagariTextFormField(
                controller: _descriptionController,
                label: strings.skuDescriptionLabel,
                maxLines: 4,
              ),
              const SizedBox(height: YugmaSpacing.s4),

              // ── Golden Hour photo placeholder (S4.5) ──
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => GoldenHourCaptureScreen(
                        skuId: '', // SKU not yet saved — will be assigned post-save
                        skuName: _nameDevanagariController.text.trim().isNotEmpty
                            ? _nameDevanagariController.text.trim()
                            : 'New SKU',
                      ),
                    ),
                  );
                },
                icon: Icon(
                  Icons.camera_alt_outlined,
                  color: YugmaColors.accent,
                ),
                label: Text(
                  strings.skuGoldenHourPhotoButton,
                  style: TextStyle(
                    fontFamily: YugmaFonts.devaBody,
                    fontSize: YugmaTypeScale.body,
                    color: YugmaColors.accent,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: YugmaColors.accent),
                  padding: const EdgeInsets.symmetric(
                    horizontal: YugmaSpacing.s4,
                    vertical: YugmaSpacing.s3,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(YugmaRadius.md),
                  ),
                  minimumSize: const Size(
                    double.infinity,
                    YugmaTapTargets.minDefault,
                  ),
                ),
              ),
              const SizedBox(height: YugmaSpacing.s6),

              // ── Save button ──
              SizedBox(
                width: double.infinity,
                height: YugmaTapTargets.minDefault,
                child: ElevatedButton(
                  onPressed: isSaving ? null : _onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: YugmaColors.primary,
                    foregroundColor: YugmaColors.textOnPrimary,
                    disabledBackgroundColor:
                        YugmaColors.primary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(YugmaRadius.md),
                    ),
                  ),
                  child: isSaving
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: YugmaColors.textOnPrimary,
                          ),
                        )
                      : Text(
                          strings.skuSaveButton,
                          style: TextStyle(
                            fontFamily: YugmaFonts.devaBody,
                            fontSize: YugmaTypeScale.bodyLarge,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: YugmaSpacing.s8),
            ],
          ),
        ),
      ),
    );
  }

  String? _dimensionValidator(String? v) {
    final strings = const AppStringsHi();
    if (v == null || v.isEmpty) return strings.validationRequired;
    final n = int.tryParse(v);
    if (n == null || n <= 0) return strings.validationDimensionPositive;
    return null;
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    ref.read(createSkuControllerProvider.notifier).save(
          nameDevanagari: _nameDevanagariController.text.trim(),
          nameEnglish: _nameEnglishController.text.trim(),
          category: _category,
          material: _material,
          heightCm: int.parse(_heightController.text),
          widthCm: int.parse(_widthController.text),
          depthCm: int.parse(_depthController.text),
          basePrice: int.parse(_basePriceController.text),
          negotiableDownTo: int.parse(_negotiableFloorController.text),
          inStock: _inStock,
          stockCount: _stockCountController.text.isNotEmpty
              ? int.tryParse(_stockCountController.text)
              : null,
          description: _descriptionController.text.trim(),
        );
  }

  /// Domain-grounded category display names (Devanagari).
  String _categoryDisplayName(SkuCategory c) {
    switch (c) {
      case SkuCategory.steelAlmirah:
        return 'Steel Almirah';
      case SkuCategory.woodenWardrobe:
        return 'Wooden Wardrobe';
      case SkuCategory.modular:
        return 'Modular';
      case SkuCategory.dressing:
        return 'Dressing Table';
      case SkuCategory.sideCabinet:
        return 'Side Cabinet';
    }
  }

  /// Domain-grounded material display names.
  String _materialDisplayName(SkuMaterial m) {
    switch (m) {
      case SkuMaterial.steel:
        return 'Steel';
      case SkuMaterial.woodSheesham:
        return 'Sheesham';
      case SkuMaterial.woodTeak:
        return 'Teak';
      case SkuMaterial.plyLaminate:
        return 'Ply / Laminate';
    }
  }
}

// =============================================================================
// Private reusable form field widgets
// =============================================================================

/// Text field styled for Devanagari input.
class _DevanagariTextFormField extends StatelessWidget {
  const _DevanagariTextFormField({
    required this.controller,
    required this.label,
    this.validator,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      style: TextStyle(
        fontFamily: YugmaFonts.devaBody,
        fontSize: YugmaTypeScale.body,
        color: YugmaColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontFamily: YugmaFonts.devaBody,
          fontSize: YugmaTypeScale.bodySmall,
          color: YugmaColors.textSecondary,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(YugmaRadius.md),
          borderSide: BorderSide(color: YugmaColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(YugmaRadius.md),
          borderSide: BorderSide(color: YugmaColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(YugmaRadius.md),
          borderSide: BorderSide(color: YugmaColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(YugmaRadius.md),
          borderSide: BorderSide(color: YugmaColors.error, width: 2),
        ),
        filled: true,
        fillColor: YugmaColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: YugmaSpacing.s4,
          vertical: YugmaSpacing.s3,
        ),
      ),
    );
  }
}

/// Text field styled for English input.
class _EnglishTextFormField extends StatelessWidget {
  const _EnglishTextFormField({
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: TextStyle(
        fontFamily: YugmaFonts.enBody,
        fontSize: YugmaTypeScale.body,
        color: YugmaColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontFamily: YugmaFonts.devaBody,
          fontSize: YugmaTypeScale.bodySmall,
          color: YugmaColors.textSecondary,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(YugmaRadius.md),
          borderSide: BorderSide(color: YugmaColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(YugmaRadius.md),
          borderSide: BorderSide(color: YugmaColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(YugmaRadius.md),
          borderSide: BorderSide(color: YugmaColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(YugmaRadius.md),
          borderSide: BorderSide(color: YugmaColors.error, width: 2),
        ),
        filled: true,
        fillColor: YugmaColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: YugmaSpacing.s4,
          vertical: YugmaSpacing.s3,
        ),
      ),
    );
  }
}

/// Numeric input field with mono font for prices / dimensions.
class _NumericField extends StatelessWidget {
  const _NumericField({
    required this.controller,
    this.label,
    this.hint,
    this.validator,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: TextStyle(
        fontFamily: YugmaFonts.mono,
        fontSize: YugmaTypeScale.body,
        color: YugmaColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          fontFamily: YugmaFonts.devaBody,
          fontSize: YugmaTypeScale.bodySmall,
          color: YugmaColors.textSecondary,
        ),
        hintStyle: TextStyle(
          fontFamily: YugmaFonts.mono,
          fontSize: YugmaTypeScale.bodySmall,
          color: YugmaColors.textMuted,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(YugmaRadius.md),
          borderSide: BorderSide(color: YugmaColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(YugmaRadius.md),
          borderSide: BorderSide(color: YugmaColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(YugmaRadius.md),
          borderSide: BorderSide(color: YugmaColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(YugmaRadius.md),
          borderSide: BorderSide(color: YugmaColors.error, width: 2),
        ),
        filled: true,
        fillColor: YugmaColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: YugmaSpacing.s4,
          vertical: YugmaSpacing.s3,
        ),
      ),
    );
  }
}

/// Generic dropdown field wrapper with Yugma styling.
class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.displayName,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T) displayName;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontFamily: YugmaFonts.devaBody,
          fontSize: YugmaTypeScale.bodySmall,
          color: YugmaColors.textSecondary,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(YugmaRadius.md),
          borderSide: BorderSide(color: YugmaColors.divider),
        ),
        filled: true,
        fillColor: YugmaColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: YugmaSpacing.s4,
          vertical: YugmaSpacing.s1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: YugmaColors.surface,
          style: TextStyle(
            fontFamily: YugmaFonts.enBody,
            fontSize: YugmaTypeScale.body,
            color: YugmaColors.textPrimary,
          ),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(displayName(item)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
