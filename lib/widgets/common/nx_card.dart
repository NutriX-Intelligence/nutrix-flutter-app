import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';

/// The app's single card surface. Replaces the ~100 one-off
/// `Container(decoration: BoxDecoration(...))` blocks scattered across
/// screens (5 different radius/padding/border combinations before this).
class NxCard extends StatelessWidget {
  const NxCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? context.cardBg,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: context.borderColor),
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.lgAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: content,
      ),
    );
  }
}
