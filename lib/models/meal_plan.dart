class MealItem {
  final String recipeCode;
  final String recipeName;
  final double servingSize;
  final String servingUnit;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  MealItem({
    required this.recipeCode,
    required this.recipeName,
    this.servingSize = 1.0,
    this.servingUnit = 'serving',
    this.calories = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
  });

  factory MealItem.fromJson(Map<String, dynamic> json) {
    return MealItem(
      recipeCode: json['recipe_code'] ?? '',
      recipeName: json['recipe_name'] ?? '',
      servingSize: (json['serving_size'] ?? 1.0).toDouble(),
      servingUnit: json['serving_unit'] ?? 'serving',
      calories: (json['calories'] ?? 0).toDouble(),
      proteinG: (json['protein_g'] ?? 0).toDouble(),
      carbsG: (json['carbs_g'] ?? 0).toDouble(),
      fatG: (json['fat_g'] ?? 0).toDouble(),
    );
  }
}

class MealPlan {
  final int userId;
  final String planDate;
  final Map<String, MealItem> meals;
  final Map<String, double> totals;
  final Map<String, double> targets;
  final double toleranceUsed;

  MealPlan({
    required this.userId,
    required this.planDate,
    required this.meals,
    required this.totals,
    required this.targets,
    this.toleranceUsed = 0.15,
  });

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    final mealsMap = <String, MealItem>{};
    if (json['meals'] != null) {
      (json['meals'] as Map<String, dynamic>).forEach((key, value) {
        mealsMap[key] = MealItem.fromJson(value as Map<String, dynamic>);
      });
    }

    return MealPlan(
      userId: json['user_id'] ?? 0,
      planDate: json['plan_date']?.toString() ?? '',
      meals: mealsMap,
      totals: Map<String, double>.from(
        (json['totals'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
            ) ??
            {},
      ),
      targets: Map<String, double>.from(
        (json['targets'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
            ) ??
            {},
      ),
      toleranceUsed: (json['tolerance_used'] ?? 0.15).toDouble(),
    );
  }
}

class WeightLog {
  final int id;
  final double weight;
  final String loggedAt;

  WeightLog({required this.id, required this.weight, required this.loggedAt});

  factory WeightLog.fromJson(Map<String, dynamic> json) {
    return WeightLog(
      id: json['id'] ?? 0,
      weight: (json['weight'] ?? 0).toDouble(),
      loggedAt: json['logged_at']?.toString() ?? '',
    );
  }
}

class MealLog {
  final int id;
  final int userId;
  final String logDate;
  final String mealType;
  final String foodName;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  MealLog({
    required this.id,
    required this.userId,
    required this.logDate,
    required this.mealType,
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory MealLog.fromJson(Map<String, dynamic> json) {
    return MealLog(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      logDate: json['log_date']?.toString() ?? '',
      mealType: json['meal_type'] ?? '',
      foodName: json['food_name'] ?? '',
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
    );
  }
}
