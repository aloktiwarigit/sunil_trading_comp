// =============================================================================
// YugmaAlertDialog — themed alert dialog matching the Workshop Almanac
// aesthetic. Uses shopPrimary for primary buttons, YugmaRadius.lg corners,
// elder tier text scaling.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:lib_core/src/theme/yugma_theme_extension.dart';
import 'package:lib_core/src/theme/tokens.dart';

/// A themed alert dialog that inherits YugmaTheme tokens automatically.
class YugmaAlertDialog extends StatelessWidget {
  const YugmaAlertDialog({
    super.key,
    required this.title,
    this.body,
    this.bodyWidget,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.isPrimaryDestructive = false,
  });

  final String title;
  final String? body;
  final Widget? bodyWidget;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool isPrimaryDestructive;

  /// Show the dialog and return a Future.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? body,
    Widget? bodyWidget,
    required String primaryLabel,
    required VoidCallback onPrimary,
    String? secondaryLabel,
    VoidCallback? onSecondary,
    bool isPrimaryDestructive = false,
  }) {
    return showDialog<T>(
      context: context,
      builder: (_) => YugmaAlertDialog(
        title: title,
        body: body,
        bodyWidget: bodyWidget,
        primaryLabel: primaryLabel,
        onPrimary: onPrimary,
        secondaryLabel: secondaryLabel,
        onSecondary: onSecondary,
        isPrimaryDestructive: isPrimaryDestructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;
    final primaryColor =
        isPrimaryDestructive ? theme.shopCommit : theme.shopPrimary;

    return AlertDialog(
      backgroundColor: theme.shopSurfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(YugmaRadius.lg),
      ),
      title: Text(title, style: theme.h2Deva),
      content: bodyWidget ??
          (body != null ? Text(body!, style: theme.bodyDeva) : null),
      actions: [
        if (secondaryLabel != null)
          TextButton(
            onPressed: onSecondary ?? () => Navigator.of(context).pop(),
            child: Text(
              secondaryLabel!,
              style: theme.bodyDeva.copyWith(color: theme.shopTextSecondary),
            ),
          ),
        FilledButton(
          onPressed: () {
            onPrimary();
            Navigator.of(context).pop();
          },
          style: FilledButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: theme.shopTextOnPrimary,
            minimumSize: Size(0, theme.tapTargetMin),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(YugmaRadius.md),
            ),
          ),
          child: Text(
            primaryLabel,
            style: theme.bodyDeva.copyWith(color: theme.shopTextOnPrimary),
          ),
        ),
      ],
    );
  }
}
