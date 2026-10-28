import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

/// Mirrors how the website's "Discover Meals & Nutrition Catalog" actually
/// works (verified against app/templates/index.html): one batch fetch of up
/// to 60 personalized recipes via POST /recommend-foods, cached client-side,
/// then filtered locally by name/meal-slot/cuisine as the user types/taps —
/// no server round-trip per filter change.
class RecipeCatalogState {
  final bool isLoading;
  final List<dynamic> allResults;
  final List<dynamic> filteredResults;
  final String? error;

  RecipeCatalogState({
    this.isLoading = false,
    this.allResults = const [],
    this.filteredResults = const [],
    this.error,
  });

  RecipeCatalogState copyWith({
    bool? isLoading,
    List<dynamic>? allResults,
    List<dynamic>? filteredResults,
    String? error,
  }) {
    return RecipeCatalogState(
      isLoading: isLoading ?? this.isLoading,
      allResults: allResults ?? this.allResults,
      filteredResults: filteredResults ?? this.filteredResults,
      error: error,
    );
  }
}

class RecipeCatalogNotifier extends StateNotifier<RecipeCatalogState> {
  final Ref ref;

  RecipeCatalogNotifier(this.ref) : super(RecipeCatalogState());

  Future<void> fetchPersonalized(int userId, {int limit = 60}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.post(
        ApiEndpoints.recommendFoods,
        data: {'user_id': userId, 'limit': limit},
      );
      // The newer backend mixes up to 400 fast-food items into the default list.
      // They have their own tab (Fast Food), so keep this list to recipes.
      final results = response.data is List
          ? (response.data as List).where((r) => !(r['recipe_code']?.toString().startsWith('FF_') ?? false)).toList()
          : [];
      state = state.copyWith(isLoading: false, allResults: results, filteredResults: results);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: apiDetail(e) ?? 'Failed to load recommended meals.',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Pure client-side filter over the cached batch — matches the website's
  /// filterRecommendations() exactly (name/cuisine substring, exact meal-slot).
  void applyFilter({String query = '', String? category, String? cuisine}) {
    final q = query.trim().toLowerCase();
    var items = state.allResults;

    if (category != null && category.isNotEmpty) {
      items = items.where((item) => (item['category']?.toString() ?? '').toLowerCase() == category.toLowerCase()).toList();
    }
    if (cuisine != null && cuisine.isNotEmpty) {
      items = items.where((item) => (item['cuisine']?.toString() ?? '').toLowerCase().contains(cuisine.toLowerCase())).toList();
    }
    if (q.isNotEmpty) {
      items = items.where((item) {
        final name = (item['recipe_name']?.toString() ?? '').toLowerCase();
        final cuis = (item['cuisine']?.toString() ?? '').toLowerCase();
        return name.contains(q) || cuis.contains(q);
      }).toList();
    }

    state = state.copyWith(filteredResults: items);
  }
}

final recipeCatalogProvider = StateNotifierProvider<RecipeCatalogNotifier, RecipeCatalogState>((ref) {
  return RecipeCatalogNotifier(ref);
});
