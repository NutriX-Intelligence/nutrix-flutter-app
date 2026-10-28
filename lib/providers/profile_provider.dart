import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/storage/local_cache.dart';
import '../core/services/widget_service.dart';
import 'auth_provider.dart';

class ProfileState {
  final bool isLoading;
  final List<dynamic>? weightHistory;
  final String? error;

  ProfileState({
    this.isLoading = false,
    this.weightHistory,
    this.error,
  });

  ProfileState copyWith({
    bool? isLoading,
    List<dynamic>? weightHistory,
    String? error,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      weightHistory: weightHistory ?? this.weightHistory,
      error: error,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final Ref ref;

  ProfileNotifier(this.ref) : super(ProfileState());

  Future<void> fetchWeightHistory() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    state = state.copyWith(isLoading: true, error: null);
    final cacheKey = 'weight_history_${user.id}';
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get(ApiEndpoints.weightHistory(user.id));

      state = state.copyWith(
        isLoading: false,
        weightHistory: response.data as List,
      );
      unawaited(LocalCache.save(cacheKey, response.data));
      unawaited(_updateWeightWidget(response.data as List));
    } on DioException catch (e) {
      final cached = await LocalCache.load(cacheKey);
      if (cached is List) {
        state = state.copyWith(isLoading: false, weightHistory: cached);
        unawaited(_updateWeightWidget(cached));
        return;
      }
      state = state.copyWith(
        isLoading: false,
        error: apiDetail(e) ?? 'Failed to load weight history.',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Home-screen "Weight" widget — backend returns most-recent-first, the
  /// widget chart wants ascending chronological order.
  Future<void> _updateWeightWidget(List history) async {
    if (history.isEmpty) return;
    final ascending = history.reversed.toList();
    final weights = ascending.map((e) => (e['weight'] as num).toDouble()).toList();
    final dates = ascending.map((e) => DateTime.parse(e['logged_at'].toString())).toList();
    await WidgetService.updateWeightWidget(weights, dates, weights.last);
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(ref);
});
