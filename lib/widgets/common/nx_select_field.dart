import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class NxSelectOption<T> {
  final T value;
  final String title;
  final String? subtitle;

  const NxSelectOption({required this.value, required this.title, this.subtitle});
}

/// A form field that opens a bottom sheet of clearly separated option cards.
/// Replaces the stock Material dropdown, whose long labels wrapped and ran
/// together with no visible boundary between one option and the next.
class NxSelectField<T> extends StatelessWidget {
  final T? value;
  final List<NxSelectOption<T>> options;
  final ValueChanged<T> onChanged;
  final String sheetTitle;

  /// Shown before the selected title in the closed field (e.g. "Lunch: ").
  final String prefix;

  /// Tighter single-line field for dense layouts (rows, inline lists).
  final bool compact;

  /// Optional small caption drawn above the value inside the field
  /// (used by form fields that previously had a floating label).
  final String? label;

  const NxSelectField({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.sheetTitle,
    this.prefix = '',
    this.compact = false,
    this.label,
  });

  NxSelectOption<T>? get _selected {
    for (final o in options) {
      if (o.value == value) return o;
    }
    return null;
  }

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: options.length > 5 ? 0.7 : 0.45,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: sheetContext.borderColor, borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(sheetTitle, style: Theme.of(sheetContext).textTheme.titleMedium),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _optionTile(sheetContext, options[i]),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    if (picked != null) onChanged(picked);
  }

  Widget _optionTile(BuildContext context, NxSelectOption<T> o) {
    final isSelected = o.value == value;
    return Material(
      color: isSelected ? AppColors.primary.withValues(alpha: 0.10) : context.inputBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.pop(context, o.value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : context.borderColor,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o.title,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.textMain, height: 1.25),
                    ),
                    if (o.subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(o.subtitle!, style: TextStyle(fontSize: 12.5, color: context.textMuted)),
                    ],
                  ],
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 10),
                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return Material(
      color: context.inputBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _open(context),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16, vertical: compact ? 10 : 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (label != null) ...[
                      Text(label!, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: context.textMuted)),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      '$prefix${selected?.title ?? 'Select'}',
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: compact ? 14 : 15, fontWeight: FontWeight.w700, color: context.textMain, height: 1.25),
                    ),
                    if (!compact && selected?.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(selected!.subtitle!, style: TextStyle(fontSize: 12.5, color: context.textMuted)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.unfold_more_rounded, color: context.textDim),
            ],
          ),
        ),
      ),
    );
  }
}
