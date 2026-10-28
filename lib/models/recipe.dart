class Recipe {
  final String recipeCode;
  final String recipeName;
  final String category;
  final String? cuisine;
  final String? difficulty;
  final int? cookingTimeMinutes;
  final String? instructions;
  final String? primarysource;
  final List<RecipeIngredient> ingredients;
  final Map<String, dynamic>? nutrition;
  final double? healthScore;
  final String? healthCategory;

  Recipe({
    required this.recipeCode,
    required this.recipeName,
    required this.category,
    this.cuisine,
    this.difficulty,
    this.cookingTimeMinutes,
    this.instructions,
    this.primarysource,
    this.ingredients = const [],
    this.nutrition,
    this.healthScore,
    this.healthCategory,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      recipeCode: json['recipe_code'] ?? '',
      recipeName: json['recipe_name'] ?? '',
      category: json['category'] ?? '',
      cuisine: json['cuisine'],
      difficulty: json['difficulty'],
      cookingTimeMinutes: json['cooking_time_minutes'],
      instructions: json['instructions'],
      primarysource: json['primarysource'],
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => RecipeIngredient.fromJson(e))
              .toList() ??
          [],
      nutrition: json['nutrition'] as Map<String, dynamic>?,
      healthScore: json['health_score']?.toDouble(),
      healthCategory: json['health_category'],
    );
  }
}

class RecipeIngredient {
  final String? ingredientName;
  final String? foodName;
  final double? amount;
  final String? unit;

  RecipeIngredient({this.ingredientName, this.foodName, this.amount, this.unit});

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      ingredientName: json['ingredient_name'],
      foodName: json['food_name'],
      amount: json['amount']?.toDouble(),
      unit: json['unit'],
    );
  }
}

class RankedRecipe {
  final String recipeCode;
  final String recipeName;
  final String category;
  final String? cuisine;
  final String? difficulty;
  final int? cookingTimeMinutes;
  final double matchScore;
  final double healthScore;
  final String healthCategory;
  final double finalScore;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final String reason;

  RankedRecipe({
    required this.recipeCode,
    required this.recipeName,
    required this.category,
    this.cuisine,
    this.difficulty,
    this.cookingTimeMinutes,
    this.matchScore = 0,
    this.healthScore = 0,
    this.healthCategory = 'Moderate',
    this.finalScore = 0,
    this.calories = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.reason = '',
  });

  factory RankedRecipe.fromJson(Map<String, dynamic> json) {
    return RankedRecipe(
      recipeCode: json['recipe_code'] ?? '',
      recipeName: json['recipe_name'] ?? '',
      category: json['category'] ?? '',
      cuisine: json['cuisine'],
      difficulty: json['difficulty'],
      cookingTimeMinutes: json['cooking_time_minutes'],
      matchScore: (json['match_score'] ?? 0).toDouble(),
      healthScore: (json['health_score'] ?? 0).toDouble(),
      healthCategory: json['health_category'] ?? 'Moderate',
      finalScore: (json['final_score'] ?? 0).toDouble(),
      calories: (json['calories'] ?? 0).toDouble(),
      proteinG: (json['protein_g'] ?? 0).toDouble(),
      carbsG: (json['carbs_g'] ?? 0).toDouble(),
      fatG: (json['fat_g'] ?? 0).toDouble(),
      reason: json['reason'] ?? '',
    );
  }
}

class RecipeSearchResult {
  final String recipeCode;
  final String recipeName;
  final String category;
  final String? cuisine;

  RecipeSearchResult({
    required this.recipeCode,
    required this.recipeName,
    required this.category,
    this.cuisine,
  });

  factory RecipeSearchResult.fromJson(Map<String, dynamic> json) {
    return RecipeSearchResult(
      recipeCode: json['recipe_code'] ?? '',
      recipeName: json['recipe_name'] ?? '',
      category: json['category'] ?? '',
      cuisine: json['cuisine'],
    );
  }
}

class TopRecipe {
  final String recipeCode;
  final String recipeName;
  final String category;
  final String? cuisine;
  final double healthScore;
  final String healthCategory;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  TopRecipe({
    required this.recipeCode,
    required this.recipeName,
    required this.category,
    this.cuisine,
    this.healthScore = 0,
    this.healthCategory = 'Moderate',
    this.calories = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
  });

  factory TopRecipe.fromJson(Map<String, dynamic> json) {
    return TopRecipe(
      recipeCode: json['recipe_code'] ?? '',
      recipeName: json['recipe_name'] ?? '',
      category: json['category'] ?? '',
      cuisine: json['cuisine'],
      healthScore: (json['health_score'] ?? 0).toDouble(),
      healthCategory: json['health_category'] ?? 'Moderate',
      calories: (json['calories'] ?? 0).toDouble(),
      proteinG: (json['protein_g'] ?? 0).toDouble(),
      carbsG: (json['carbs_g'] ?? 0).toDouble(),
      fatG: (json['fat_g'] ?? 0).toDouble(),
    );
  }
}
