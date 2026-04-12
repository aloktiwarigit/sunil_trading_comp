// =============================================================================
// YugmaEmptyState — branded empty state widget with warm illustration,
// Devanagari title, subtitle, and optional CTA button.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:lib_core/src/theme/yugma_theme_extension.dart';
import 'package:lib_core/src/theme/tokens.dart';

/// A branded empty state that replaces generic Material icon + text combos.
class YugmaEmptyState extends StatelessWidget {
  const YugmaEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.ctaLabel,
    this.onCta,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(YugmaSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warm-toned icon in a circular badge
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.shopPrimary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: theme.shopPrimary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: YugmaSpacing.s6),
            Text(
              title,
              style: theme.h2Deva.copyWith(color: theme.shopTextSecondary),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: YugmaSpacing.s2),
              Text(
                subtitle!,
                style: theme.bodyDeva.copyWith(color: theme.shopTextMuted),
                textAlign: TextAlign.center,
              ),
            ],
            if (ctaLabel != null && onCta != null) ...[
              const SizedBox(height: YugmaSpacing.s6),
              FilledButton(
                onPressed: onCta,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.shopPrimary,
                  foregroundColor: theme.shopTextOnPrimary,
                  minimumSize: Size(0, theme.tapTargetMin),
                ),
                child: Text(
                  ctaLabel!,
                  style:
                      theme.bodyDeva.copyWith(color: theme.shopTextOnPrimary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
