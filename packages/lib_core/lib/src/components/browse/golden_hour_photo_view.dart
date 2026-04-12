// =============================================================================
// GoldenHourPhotoView — full-width hero photo with "asli roop" toggle.
//
// Ported from design bundle Widget 12 (components_library.dart lines 1471-1572).
// Uses context.yugmaTheme for all colors per ADR-003. All user-visible strings
// come via parameters from AppStrings — no hardcoded Devanagari.
//
// Per PRD B1.5 AC #1: full-width Golden Hour photo, ~70% screen height.
// Per PRD B1.5 AC #3: "असली रूप दिखाइए" toggle to working-light photo.
//
// The toggle text uses two AppStrings parameters:
//   - asliRoopLabel: "असली रूप दिखाइए" (show real form)
//   - goldenHourToggleLabel: "सुंदर रूप" (beautiful view) — shown when
//     already viewing the working-light photo, to switch back.
// =============================================================================

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../../theme/yugma_theme_extension.dart';

/// Full-width Golden Hour photo view with working-light toggle.
class GoldenHourPhotoView extends StatefulWidget {
  /// URL for the Golden Hour (styled) photo.
  final String goldenHourImageUrl;

  /// URL for the working-light (real) photo. Null hides the toggle.
  final String? workingLightImageUrl;

  /// Height of the photo view. Defaults to 280.
  final double height;

  /// Label for "show real form" — from AppStrings.asliRoopToggle.
  final String asliRoopLabel;

  /// Label for "beautiful view" (switch back) — from
  /// AppStrings.goldenHourToggleBeautiful.
  final String goldenHourToggleLabel;

  const GoldenHourPhotoView({
    super.key,
    required this.goldenHourImageUrl,
    this.workingLightImageUrl,
    this.height = 280,
    required this.asliRoopLabel,
    required this.goldenHourToggleLabel,
  });

  @override
  State<GoldenHourPhotoView> createState() => _GoldenHourPhotoViewState();
}

class _GoldenHourPhotoViewState extends State<GoldenHourPhotoView> {
  bool _showAsli = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;
    final imageUrl = _showAsli && widget.workingLightImageUrl != null
        ? widget.workingLightImageUrl!
        : widget.goldenHourImageUrl;

    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.shopSecondary,
            theme.shopPrimaryDeep,
            const Color(0xFF2C1810),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Image (or fallback gradient) — pinch-to-zoom via InteractiveViewer (D-6)
          if (imageUrl.isNotEmpty)
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                clipBehavior: Clip.none,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),

          // Bottom gradient for legibility
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),
          ),

          // Asli roop toggle
          if (widget.workingLightImageUrl != null)
            Positioned(
              top: YugmaSpacing.s3,
              right: YugmaSpacing.s3,
              child: Material(
                color: const Color(0xB3000000),
                borderRadius: BorderRadius.circular(YugmaRadius.pill),
                child: InkWell(
                  borderRadius: BorderRadius.circular(YugmaRadius.pill),
                  onTap: () => setState(() => _showAsli = !_showAsli),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: YugmaSpacing.s3,
                      vertical: theme.isElderTier ? 10.0 : 6.0,
                    ),
                    child: Text(
                      _showAsli
                          ? widget.goldenHourToggleLabel
                          : widget.asliRoopLabel,
                      style: TextStyle(
                        fontFamily: theme.fontFamilyDevanagariBody,
                        fontSize: theme.isElderTier ? 15.0 : 11.0,
                        color: theme.shopAccent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
