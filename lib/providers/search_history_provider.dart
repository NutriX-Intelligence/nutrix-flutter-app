import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

class SearchHistoryState {
  final bool isLoading;
  final List<dynamic> history;
  final String? error;

  SearchHistoryState({this.isLoading = false, this.history = const [], this.error});

  SearchHistoryState copyWith({bool? isLoading, List<dynamic>? history, String? error}) {
    return SearchHistoryState(
      isLoading: isLoading ?? this.isLoading,
      history: history ?? this.history,
      error: error,
    );
  }
}

class SearchHistoryNotifier extends StateNotifier<SearchHistoryState> {
  final Ref ref;

  SearchHistoryNotifier(this.ref) : super(SearchHistoryState());

  Future<void> fetchHistory() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get(ApiEndpoints.searchHistory);
      state = state.copyWith(
        isLoading: false,
        history: response.data is List ? response.data : [],
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: apiDetail(e) ?? 'Failed to load search history.',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Fire-and-forget: a failed history save should never block the search itself.
  Future<void> logQuery(String query) async {
    if (query.trim().isEmpty) return;
    try {
      final apiClient = ApiClient();
      await apiClient.dio.post(ApiEndpoints.searchHistory, data: {'query': query.trim()});
    } catch (_) {}
  }
}

final searchHistoryProvider = StateNotifierProvider<SearchHistoryNotifier, SearchHistoryState>((ref) {
  return SearchHistoryNotifier(ref);
});
