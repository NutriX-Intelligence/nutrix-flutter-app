import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

class SubstitutionItem {
  final String originalIngredient;
  final String violatesDiet;
  final String detectedTrigger;
  final List<String> recommendedSubstitutes;
  final String culinaryTip;

  SubstitutionItem({
    required this.originalIngredient,
    required this.violatesDiet,
    required this.detectedTrigger,
    required this.recommendedSubstitutes,
    required this.culinaryTip,
  });

  factory SubstitutionItem.fromJson(Map<String, dynamic> json) {
    return SubstitutionItem(
      originalIngredient: json['original_ingredient'] ?? '',
      violatesDiet: json['violates_diet'] ?? '',
      detectedTrigger: json['detected_trigger'] ?? '',
      recommendedSubstitutes: List<String>.from(json['recommended_substitutes'] ?? []),
      culinaryTip: json['culinary_tip'] ?? '',
    );
  }
}

class SubstitutionResponse {
  final String targetDiet;
  final List<SubstitutionItem> substitutions;

  SubstitutionResponse({
    required this.targetDiet,
    required this.substitutions,
  });

  factory SubstitutionResponse.fromJson(Map<String, dynamic> json) {
    return SubstitutionResponse(
      targetDiet: json['target_diet'] ?? '',
      substitutions: (json['substitutions'] as List?)
              ?.map((item) => SubstitutionItem.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class SubstitutionState {
  final bool isLoading;
  final SubstitutionResponse? data;
  final String? error;

  SubstitutionState({
    this.isLoading = false,
    this.data,
    this.error,
  });

  SubstitutionState copyWith({
    bool? isLoading,
    SubstitutionResponse? data,
    String? error,
  }) {
    return SubstitutionState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error,
    );
  }
}

class SubstitutionNotifier extends StateNotifier<SubstitutionState> {
  SubstitutionNotifier() : super(SubstitutionState());

  Future<void> getSubstitutions({
    required List<String> ingredients,
    required String targetDiet,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.post(
        ApiEndpoints.substitutions,
        data: {
          'ingredients': ingredients,
          'target_diet': targetDiet,
        },
      );

      if (response.statusCode == 200) {
        state = state.copyWith(
          isLoading: false,
          data: SubstitutionResponse.fromJson(response.data),
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load substitutions: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: apiDetail(e) ?? e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final substitutionProvider = StateNotifierProvider<SubstitutionNotifier, SubstitutionState>((ref) {
  return SubstitutionNotifier();
});
