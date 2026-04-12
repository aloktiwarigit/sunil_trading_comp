// =============================================================================
// MediaSpendTile — S4.16: Cloudinary/Storage cost monitoring widget.
//
// AC #1: adapter increments counter on upload (tracked in Firestore)
// AC #3: ops dashboard widget with spend %, month delta, projection
// AC #4: warning banners at 50%/80%/100%
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';

/// S4.16 — Media spend monitoring tile for the ops dashboard.
class MediaSpendTile extends ConsumerWidget {
  const MediaSpendTile({super.key});

  // Cloudinary free tier: 25 credits/month
  static const int _maxCredits = 25;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = const AppStringsHi();
    final shopId = ref.read(shopIdProviderProvider).shopId;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('shops')
          .doc(shopId)
          .collection('telemetry')
          .doc('media_spend')
          .snapshots(),
      builder: (context, snapshot) {
        final usedCredits = snapshot.hasData && snapshot.data!.exists
            ? (snapshot.data!.data()!['usedCreditsThisMonth'] as num?)
                    ?.toInt() ??
                0
            : 0;

        final pct = (usedCredits / _maxCredits * 100).clamp(0, 100).toInt();
        final barColor = pct >= 100
            ? YugmaColors.commit
            : pct >= 80
                ? YugmaColors.accent
                : YugmaColors.primary;

        return Container(
          margin: const EdgeInsets.symmetric(
            horizontal: YugmaSpacing.s4,
            vertical: YugmaSpacing.s2,
          ),
          padding: const EdgeInsets.all(YugmaSpacing.s4),
          decoration: BoxDecoration(
            color: YugmaColors.surface,
            borderRadius: BorderRadius.circular(YugmaRadius.lg),
            boxShadow: YugmaShadows.card,
            border: pct >= 80
                ? Border.all(color: barColor.withValues(alpha: 0.5))
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.cloud_outlined, color: barColor, size: 20),
                  const SizedBox(width: YugmaSpacing.s2),
                  Text(
                    strings.mediaSpendTileLabel,
                    style: TextStyle(
                      fontFamily: YugmaFonts.devaBody,
                      fontSize: YugmaTypeScale.body,
                      fontWeight: FontWeight.w600,
                      color: YugmaColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$usedCredits / $_maxCredits',
                    style: TextStyle(
                      fontFamily: YugmaFonts.mono,
                      fontSize: YugmaTypeScale.caption,
                      color: barColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: YugmaSpacing.s2),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  backgroundColor: YugmaColors.divider,
                  color: barColor,
                  minHeight: 8,
                ),
              ),
              if (pct >= 100) ...[
                const SizedBox(height: YugmaSpacing.s2),
                Text(
                  strings.cloudinaryExhaustedR2Active,
                  style: TextStyle(
                    fontFamily: YugmaFonts.devaBody,
                    fontSize: YugmaTypeScale.caption,
                    color: YugmaColors.commit,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
