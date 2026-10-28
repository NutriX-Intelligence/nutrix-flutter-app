import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'nx_select_field.dart';

/// The "which meal is this?" picker shown before logging an item. Replaces
/// the same `AlertDialog` + `StatefulBuilder` + bordered dropdown duplicated
/// in the barcode scanner, recipe detail, and homely meal detail screens.
///
/// Returns the chosen meal type, or `null` if the user cancelled.
class NxMealTypeDialog {
  static const List<String> mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];

  static Future<String?> show(
    BuildContext context, {
    required String itemLabel,
    String initialMealType = 'Breakfast',
    String title = 'Log to Diary',
    String confirmLabel = 'Log Meal',
  }) {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        var mealType = initialMealType;
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Log "$itemLabel" to your diary:'),
                  const SizedBox(height: 16),
                  Text(
                    'MEAL TYPE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: dialogContext.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  NxSelectField<String>(
                    value: mealType,
                    sheetTitle: 'Meal type',
                    options: mealTypes.map((e) => NxSelectOption<String>(value: e, title: e)).toList(),
                    onChanged: (val) => setState(() => mealType = val),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, mealType),
                  child: Text(confirmLabel),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
