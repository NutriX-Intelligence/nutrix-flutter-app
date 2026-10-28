import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

/// Fast-food chains offered as the sub-options of the "Fast Food" category.
/// Values are the canonical brand names the backend filters on.
const List<Map<String, String>> kFastFoodBrands = [
  {'label': 'All Chains', 'value': ''},
  {'label': "Domino's", 'value': "Domino's"},
  {'label': "McDonald's", 'value': "McDonald's"},
  {'label': 'Subway', 'value': 'Subway'},
  {'label': 'Burger King', 'value': 'Burger King'},
  {'label': 'KFC', 'value': 'KFC'},
  {'label': 'Pizza Hut', 'value': 'Pizza Hut'},
  {'label': 'Starbucks', 'value': 'Starbucks'},
  {'label': 'Taco Bell', 'value': 'Taco Bell'},
];

/// Tree returned by GET /api/fast-food/grouped:
/// brand -> sections (menu categories) -> items.
class FastFoodState {
  final bool isLoading;
  final List<dynamic> groups;
  final String? error;

  const FastFoodState({this.isLoading = false, this.groups = const [], this.error});
}

class FastFoodNotifier extends StateNotifier<FastFoodState> {
  FastFoodNotifier() : super(const FastFoodState());

  // Guards against an older, slower response overwriting a newer one while
  // the user is typing or switching chains.
  int _requestId = 0;

  /// The backend only filters by the account's diet when the profile column is
  /// filled, but the app stores the diet as a preference. So the app sends the
  /// diet explicitly. Non-vegetarian and "Any" accounts see everything.
  static String? dietFilterFor(String? dietType) {
    final d = (dietType ?? '').toLowerCase();
    if (d.contains('jain')) return 'jain';
    if (d.contains('vegan')) return 'vegan';
    if (d.contains('egg') || (d.contains('vegetarian') && !d.contains('non'))) return 'vegetarian';
    return null;
  }

  Future<void> fetch({String query = '', String brand = '', int? userId, String? dietType}) async {
    final id = ++_requestId;
    state = FastFoodState(isLoading: true, groups: state.groups);
    try {
      final params = <String, dynamic>{
        if (query.trim().isNotEmpty) 'q': query.trim(),
        if (brand.isNotEmpty) 'brand': brand,
        if (userId != null) 'user_id': userId,
        if (dietFilterFor(dietType) != null) 'diet_filter': dietFilterFor(dietType),
      };
      final response = await ApiClient().dio.get(ApiEndpoints.fastFoodGrouped, queryParameters: params);
      if (id != _requestId) return;
      state = FastFoodState(groups: response.data is List ? response.data : const []);
    } on DioException catch (e) {
      if (id != _requestId) return;
      state = FastFoodState(error: apiDetail(e) ?? 'Could not load fast-food menus.');
    } catch (e) {
      if (id != _requestId) return;
      state = FastFoodState(error: e.toString());
    }
  }
}

final fastFoodProvider = StateNotifierProvider<FastFoodNotifier, FastFoodState>((ref) => FastFoodNotifier());
