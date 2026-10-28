import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import 'auth_provider.dart';

class AiPlanState {
  final bool isLoading;
  final List<dynamic>? dietPlan;
  final dynamic recipeResult;
  final String? error;

  AiPlanState({
    this.isLoading = false,
    this.dietPlan,
    this.recipeResult,
    this.error,
  });

  AiPlanState copyWith({
    bool? isLoading,
    List<dynamic>? dietPlan,
    dynamic recipeResult,
    String? error,
    bool clearError = false,
  }) {
    return AiPlanState(
      isLoading: isLoading ?? this.isLoading,
      dietPlan: dietPlan ?? this.dietPlan,
      recipeResult: recipeResult ?? this.recipeResult,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AiPlanNotifier extends StateNotifier<AiPlanState> {
  final Ref ref;

  AiPlanNotifier(this.ref) : super(AiPlanState());

  Future<void> generateDietPlan({
    required int days,
    required String goal,
    required String dietType,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = ref.read(authProvider).user;
      if (user == null) {
        state = state.copyWith(isLoading: false, error: 'User not logged in');
        return;
      }

      final apiClient = ApiClient();
      final payload = {
        'user_id': user.id,
        'preference': goal == 'weight loss' ? 'low_fat' : (goal == 'muscle gain' ? 'high_protein' : 'balanced'),
      };

      final response = await apiClient.dio.post(
        ApiEndpoints.aiDietPlan,
        data: payload,
      );

      final data = response.data;
      List<dynamic> plan = [];

      if (data is Map && data.containsKey('meals') && data.containsKey('plan_date')) {
        // Map the new OR-Tools schema to the old UI format
        String dateStr = data['plan_date'];
        try {
          final parsedDate = DateTime.parse(dateStr);
          dateStr = DateFormat('MMM d, yyyy').format(parsedDate);
        } catch (_) {}
        final mealsMap = data['meals'] as Map<String, dynamic>;
        
        List<dynamic> mealsList = [];
        mealsMap.forEach((mealType, mealData) {
          mealsList.add({
            'type': mealType,
            'name': mealData['recipe_name'] ?? '',
            'calories': mealData['calories']?.round() ?? 0,
            'protein': mealData['protein_g']?.round() ?? 0,
          });
        });

        plan.add({
          'day': dateStr, // This passes the date directly as 'day'
          'meals': mealsList,
        });
      } else if (data is Map && data.containsKey('plan')) {
        plan = data['plan'] as List;
      } else if (data is List) {
        plan = data;
      }

      state = state.copyWith(isLoading: false, dietPlan: plan);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: apiDetail(e) ?? 'Failed to generate diet plan.',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> generateRecipe(String ingredients) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.post(
        ApiEndpoints.aiRecipeGenerator,
        data: {'ingredients': ingredients},
      );

      state = state.copyWith(isLoading: false, recipeResult: response.data);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: apiDetail(e) ?? 'Failed to generate recipe.',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final aiPlanProvider = StateNotifierProvider<AiPlanNotifier, AiPlanState>((ref) {
  return AiPlanNotifier(ref);
});
