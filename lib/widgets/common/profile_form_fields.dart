import 'package:flutter/material.dart';
import '../../core/theme/app_tokens.dart';
import 'nx_chip_input.dart';
import 'nx_select_field.dart';

/// Canonical diet-type values the backend actually recognizes
/// (app/services/classification_engine.py) — was duplicated verbatim
/// across register/edit-profile/profile-setup.
const List<Map<String, String>> kDietTypeOptions = [
  {'value': 'Any', 'label': 'Any'},
  {'value': 'Non-Vegetarian', 'label': 'Non-Vegetarian (All foods)'},
  {'value': 'Eggetarian', 'label': 'Eggetarian (Vegetarian + Eggs)'},
  {'value': 'Vegetarian', 'label': 'Vegetarian (No meat/fish/eggs)'},
  {'value': 'Jain', 'label': 'Jain Vegetarian (Strict: No onion/garlic/roots)'},
  {'value': 'Vegan', 'label': 'Vegan (Plant-based only)'},
];

const List<Map<String, String>> kActivityLevelOptions = [
  {'value': 'sedentary', 'label': 'Sedentary'},
  {'value': 'lightly_active', 'label': 'Lightly Active'},
  {'value': 'moderately_active', 'label': 'Moderately Active'},
  {'value': 'active', 'label': 'Active'},
  {'value': 'very_active', 'label': 'Very Active'},
];

const List<Map<String, String>> kGoalOptions = [
  {'value': 'fat loss', 'label': 'Fat Loss'},
  {'value': 'weight gain', 'label': 'Weight Gain'},
  {'value': 'muscle gain', 'label': 'Muscle Gain'},
  {'value': 'maintenance', 'label': 'Maintenance'},
];

/// The 9-field body profile form — age, gender, height, weight, activity
/// level, goal, diet type, and liked/allergic/disliked ingredients. Used
/// to be hand-copied across register, edit-profile, and profile-setup
/// (same fields, same diet-type list, three times). Grouped into three
/// labeled sections instead of one flat scroll.
///
/// A stateless renderer, not a form controller — each screen keeps owning
/// its own `TextEditingController`s and selected values (they have
/// genuinely different lifecycles: register starts blank, edit prefills
/// from the current user, setup starts blank with different copy).
class ProfileFormFields extends StatelessWidget {
  const ProfileFormFields({
    super.key,
    required this.ageController,
    required this.heightController,
    required this.weightController,
    required this.gender,
    required this.onGenderChanged,
    required this.activityLevel,
    required this.onActivityLevelChanged,
    required this.goal,
    required this.onGoalChanged,
    required this.dietType,
    required this.onDietTypeChanged,
    required this.likes,
    required this.onLikesChanged,
    required this.allergies,
    required this.onAllergiesChanged,
    required this.dislikes,
    required this.onDislikesChanged,
  });

  final TextEditingController ageController;
  final TextEditingController heightController;
  final TextEditingController weightController;
  final String gender;
  final ValueChanged<String?> onGenderChanged;
  final String activityLevel;
  final ValueChanged<String?> onActivityLevelChanged;
  final String goal;
  final ValueChanged<String?> onGoalChanged;
  final String dietType;
  final ValueChanged<String?> onDietTypeChanged;
  final String likes;
  final ValueChanged<String> onLikesChanged;
  final String allergies;
  final ValueChanged<String> onAllergiesChanged;
  final String dislikes;
  final ValueChanged<String> onDislikesChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, 'About you'),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Age', prefixIcon: Icon(Icons.cake_outlined, size: 20)),
                validator: (v) {
                  final age = int.tryParse(v ?? '');
                  if (age == null || age < 1 || age > 119) return 'Invalid';
                  return null;
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: NxSelectField<String>(
                label: 'Gender',
                value: gender,
                sheetTitle: 'Gender',
                options: const [
                  NxSelectOption<String>(value: 'male', title: 'Male'),
                  NxSelectOption<String>(value: 'female', title: 'Female'),
                ],
                onChanged: onGenderChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),

        _sectionHeader(context, 'Your body'),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Height (cm)', prefixIcon: Icon(Icons.height, size: 20)),
                validator: (v) {
                  final h = double.tryParse(v ?? '');
                  if (h == null || h < 30 || h > 300) return 'Invalid';
                  return null;
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextFormField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Weight (kg)', prefixIcon: Icon(Icons.monitor_weight_outlined, size: 20)),
                validator: (v) {
                  final w = double.tryParse(v ?? '');
                  if (w == null || w < 10 || w > 600) return 'Invalid';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        NxSelectField<String>(
          label: 'Activity Level',
          value: activityLevel,
          sheetTitle: 'Activity level',
          options: kActivityLevelOptions.map((o) => NxSelectOption<String>(value: o['value']!, title: o['label']!)).toList(),
          onChanged: onActivityLevelChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
        NxSelectField<String>(
          label: 'Fitness Goal',
          value: goal,
          sheetTitle: 'Fitness goal',
          options: kGoalOptions.map((o) => NxSelectOption<String>(value: o['value']!, title: o['label']!)).toList(),
          onChanged: onGoalChanged,
        ),
        const SizedBox(height: AppSpacing.xxl),

        _sectionHeader(context, 'Food preferences'),
        const SizedBox(height: AppSpacing.md),
        NxSelectField<String>(
          label: 'Diet Type',
          value: dietType,
          sheetTitle: 'Diet type',
          options: kDietTypeOptions
              .map((o) => NxSelectOption<String>(
                    value: o['value']!,
                    title: o['value'] == 'Jain' ? 'Jain Vegetarian' : o['value']!,
                    subtitle: o['label'] == o['value'] ? null : o['label'],
                  ))
              .toList(),
          onChanged: onDietTypeChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
        NxChipInput(
          label: 'Liked Ingredients',
          hint: 'e.g. Paneer, Spinach, Rice',
          icon: Icons.thumb_up_alt_outlined,
          initialValue: likes,
          onChanged: onLikesChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
        NxChipInput(
          label: 'Allergies (Filtered Out)',
          hint: 'e.g. Peanut, Cashew',
          icon: Icons.warning_amber_outlined,
          initialValue: allergies,
          onChanged: onAllergiesChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
        NxChipInput(
          label: 'Dislikes (Filtered Out)',
          hint: 'e.g. Mushroom, Garlic',
          icon: Icons.thumb_down_alt_outlined,
          initialValue: dislikes,
          onChanged: onDislikesChanged,
        ),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}
