import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

class RecipeState {
  final bool isLoading;
  final List<dynamic> recipes;
  final int totalResults;
  final String? error;

  RecipeState({
    this.isLoading = false,
    this.recipes = const [],
    this.totalResults = 0,
    this.error,
  });

  RecipeState copyWith({
    bool? isLoading,
    List<dynamic>? recipes,
    int? totalResults,
    String? error,
  }) {
    return RecipeState(
      isLoading: isLoading ?? this.isLoading,
      recipes: recipes ?? this.recipes,
      totalResults: totalResults ?? this.totalResults,
      error: error,
    );
  }
}

class RecipeNotifier extends StateNotifier<RecipeState> {
  final Ref ref;

  RecipeNotifier(this.ref) : super(RecipeState());

  Future<void> recommendRecipes({
    required List<String> ingredients,
    String? goal,
    String? dietType,
    String? cuisine,
    List<String>? excludeIngredients,
    int? maxCookingTime,
    int topN = 10,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = ApiClient();
      final payload = {
        'ingredients': ingredients,
        if (goal != null && goal.isNotEmpty) 'goal': goal,
        if (dietType != null && dietType.isNotEmpty) 'diet_type': dietType,
        if (cuisine != null && cuisine.isNotEmpty) 'cuisine': cuisine,
        if (excludeIngredients != null && excludeIngredients.isNotEmpty)
          'exclude_ingredients': excludeIngredients,
        if (maxCookingTime != null) 'max_cooking_time': maxCookingTime,
        'top_n': topN,
      };

      final response = await apiClient.dio.post(
        ApiEndpoints.recommendRecipes,
        data: payload,
      );

      final data = response.data ?? {};
      final topRecipes = data['top_recipes'] as List? ?? [];
      final total = data['total_results'] as int? ?? topRecipes.length;

      state = RecipeState(
        isLoading: false,
        recipes: topRecipes,
        totalResults: total,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: apiDetail(e) ?? 'Failed to recommend recipes.',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clear() {
    state = RecipeState();
  }
}

final recipeProvider = StateNotifierProvider<RecipeNotifier, RecipeState>((ref) {
  return RecipeNotifier(ref);
});
