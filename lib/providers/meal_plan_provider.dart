import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/meal_plan.dart';

class MealPlanNotifier extends StateNotifier<AsyncValue<MealPlan?>> {
  MealPlanNotifier() : super(const AsyncValue.data(null));

  Future<void> generatePlan(
    int userId,
    String preference, {
    DateTime? planDate,
    Map<String, String>? mealCuisines,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await ApiClient().dio.post(
        ApiEndpoints.generateMealPlan,
        data: {
          'user_id': userId,
          'preference': preference,
          'tolerance': 0.15,
          if (planDate != null) 'plan_date': DateFormat('yyyy-MM-dd').format(planDate),
          if (mealCuisines != null && mealCuisines.isNotEmpty) 'meal_cuisines': mealCuisines,
        },
      );
      state = AsyncValue.data(MealPlan.fromJson(response.data));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final mealPlanProvider = StateNotifierProvider<MealPlanNotifier, AsyncValue<MealPlan?>>((ref) {
  return MealPlanNotifier();
});

// Saved meal plan history — GET /users/{user_id}/meal-plans, previously
// registered as an ApiEndpoints constant but never called anywhere.
class MealPlanHistoryNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  MealPlanHistoryNotifier() : super(const AsyncValue.data([]));

  Future<void> fetchHistory(int userId) async {
    state = const AsyncValue.loading();
    try {
      final response = await ApiClient().dio.get(ApiEndpoints.mealPlanHistory(userId));
      state = AsyncValue.data(response.data is List ? response.data : []);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final mealPlanHistoryProvider = StateNotifierProvider<MealPlanHistoryNotifier, AsyncValue<List<dynamic>>>((ref) {
  return MealPlanHistoryNotifier();
});
