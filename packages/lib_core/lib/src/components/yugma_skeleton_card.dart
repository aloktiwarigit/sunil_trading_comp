import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/tokens.dart';

/// Warm-toned skeleton card for loading states.
/// Uses shopPrimary at 10% as base, shopAccent at 20% as highlight.
class YugmaSkeletonCard extends StatelessWidget {
  final double height;
  final double width;

  const YugmaSkeletonCard(
      {super.key, this.height = 80, this.width = double.infinity});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: YugmaColors.primary.withValues(alpha: 0.10),
      highlightColor: YugmaColors.accent.withValues(alpha: 0.20),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(YugmaRadius.md),
        ),
      ),
    );
  }
}

/// List of skeleton cards for loading a list screen.
class YugmaListSkeleton extends StatelessWidget {
  final int count;
  final double cardHeight;

  const YugmaListSkeleton({super.key, this.count = 5, this.cardHeight = 80});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.all(YugmaSpacing.s4),
      itemCount: count,
      separatorBuilder: (_, __) => SizedBox(height: YugmaSpacing.s2),
      itemBuilder: (_, __) => YugmaSkeletonCard(height: cardHeight),
    );
  }
}
