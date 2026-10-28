import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';

/// A labeled chip-entry field — type a word, press enter or comma to turn
/// it into a removable chip. Replaces a plain comma-separated `TextField`
/// for list-like inputs (liked ingredients, allergies, dislikes), where a
/// stream of unstructured text is harder to scan and edit than discrete
/// tags. The underlying value stays a comma-separated string, matching
/// what the backend's preference payload already expects.
class NxChipInput extends StatefulWidget {
  const NxChipInput({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.hint,
    this.icon,
  });

  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final String? hint;
  final IconData? icon;

  @override
  State<NxChipInput> createState() => _NxChipInputState();
}

class _NxChipInputState extends State<NxChipInput> {
  late final List<String> _chips = widget.initialValue
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commit() => widget.onChanged(_chips.join(', '));

  void _addChip(String raw) {
    final value = raw.trim();
    _controller.clear();
    if (value.isEmpty) return;
    setState(() {
      if (!_chips.contains(value)) _chips.add(value);
    });
    _commit();
  }

  void _removeChip(String chip) {
    setState(() => _chips.remove(chip));
    _commit();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: 16, color: context.textMuted),
              const SizedBox(width: 6),
            ],
            Text(widget.label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: context.textMuted)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(color: context.inputBg, borderRadius: AppRadius.mdAll, border: Border.all(color: context.borderColor)),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final chip in _chips)
                Chip(
                  label: Text(chip, style: const TextStyle(fontSize: 12)),
                  onDeleted: () => _removeChip(chip),
                  deleteIconColor: context.textMuted,
                  backgroundColor: context.cardBg,
                  side: BorderSide(color: context.borderColor),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              SizedBox(
                width: _chips.isEmpty ? double.infinity : 140,
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: _chips.isEmpty ? widget.hint : 'Add more',
                    hintStyle: TextStyle(fontSize: 13, color: context.textDim),
                    // The app-wide input theme fills and outlines every
                    // field; inside this container that drew a second pill
                    // around the hint text and clipped it.
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  style: TextStyle(fontSize: 13, color: context.textMain),
                  textInputAction: TextInputAction.done,
                  onTapOutside: (_) {
                    if (_controller.text.trim().isNotEmpty) _addChip(_controller.text);
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  onSubmitted: _addChip,
                  onChanged: (v) {
                    if (v.endsWith(',')) _addChip(v.substring(0, v.length - 1));
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
