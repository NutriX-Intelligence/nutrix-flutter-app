import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';

/// A shimmering placeholder block for loading states. Wires up the
/// `shimmer` package, which was already a dependency but had zero import
/// sites anywhere in the app — every loading state was either a bare
/// spinner or, worse, nothing at all.
class NxSkeleton extends StatelessWidget {
  const NxSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = AppRadius.smAll,
  });

  final double? width;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: context.borderColor,
      highlightColor: isDark ? AppColors.textDarkTertiary : AppColors.bgLight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: context.borderColor,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

/// A skeleton shaped like an [NxCard] — for screens that load a whole card
/// of content at once (today's totals, a meal-plan slot, a recipe result).
class NxCardSkeleton extends StatelessWidget {
  const NxCardSkeleton({super.key, this.lines = 3, this.height});

  final int lines;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const NxSkeleton(width: 120, height: 14),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < lines; i++) ...[
            NxSkeleton(width: i.isEven ? double.infinity : 180),
            if (i != lines - 1) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
