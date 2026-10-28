import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import 'auth_provider.dart';

class AiPlanState {
  final bool isLoading;
  /// Markdown text (never a list) as returned by POST /ai/diet-plan.
  final String? dietPlan;
  /// Who answered: gemini | local | offline.
  final String? planSource;
  final dynamic recipeResult;
  final String? error;

  AiPlanState({
    this.isLoading = false,
    this.dietPlan,
    this.planSource,
    this.recipeResult,
    this.error,
  });

  AiPlanState copyWith({
    bool? isLoading,
    String? dietPlan,
    String? planSource,
    dynamic recipeResult,
    String? error,
    bool clearError = false,
  }) {
    return AiPlanState(
      isLoading: isLoading ?? this.isLoading,
      dietPlan: dietPlan ?? this.dietPlan,
      planSource: planSource ?? this.planSource,
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
      // The backend uses the goal and diet sent here instead of the saved profile.
      final payload = {
        'user_id': user.id,
        'goal': goal == 'weight loss' ? 'fat loss' : goal,
        'diet_type': dietType == 'standard' ? 'any' : dietType,
      };

      final response = await apiClient.dio.post(
        ApiEndpoints.aiDietPlan,
        data: payload,
      );

      // `plan` is a Markdown string. Do not cast it to a list.
      final data = response.data;
      final plan = (data is Map ? data['plan'] : null)?.toString() ?? '';
      final source = (data is Map ? data['source'] : null)?.toString();
      if (plan.trim().isEmpty) {
        state = state.copyWith(isLoading: false, error: 'The AI returned an empty plan. Please try again.');
        return;
      }
      state = state.copyWith(isLoading: false, dietPlan: plan, planSource: source);
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
