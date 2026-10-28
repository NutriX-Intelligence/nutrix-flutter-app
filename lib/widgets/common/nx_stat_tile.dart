import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';

/// A single value/label tile for stat grids (body metrics, macro summaries,
/// weight stats...). Replaces 7 near-identical `_statTile`/`_targetTile`/
/// `_metricItem`/`_macroStat`/`_weightStatTile` builders duplicated per
/// screen.
class NxStatTile extends StatelessWidget {
  const NxStatTile({
    super.key,
    required this.value,
    required this.label,
    this.color,
    this.icon,
  });

  final String value;
  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color ?? context.textMuted),
            const SizedBox(height: 4),
          ],
          Text(
            value,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 15,
                  color: color ?? context.textMain,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  letterSpacing: 0.3,
                  color: context.textMuted,
                ),
          ),
        ],
      ),
    );
  }
}
