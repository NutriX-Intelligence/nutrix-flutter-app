import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fast_food_provider.dart';
import '../../providers/recipe_catalog_provider.dart';
import '../../providers/scanner_provider.dart';
import '../../providers/search_history_provider.dart';

/// Category value that switches the screen to the fast-food chain tree.
const String _fastFood = 'FastFood';

const List<Map<String, String>> _categories = [
  {'label': 'All', 'value': ''},
  {'label': 'Fast Food', 'value': _fastFood},
  {'label': 'Breakfast', 'value': 'Breakfast'},
  {'label': 'Lunch & Dinner', 'value': 'Lunch/Dinner'},
  {'label': 'Snack', 'value': 'Snack'},
];

// Matches the RankedFoodItem.cuisine values recipes are actually seeded with.
const List<String> _cuisines = ['All', 'Indian', 'Italian', 'Chinese', 'Mexican', 'Japanese', 'Continental'];

class BrowseRecipesScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const BrowseRecipesScreen({super.key, this.initialQuery});

  @override
  ConsumerState<BrowseRecipesScreen> createState() => _BrowseRecipesScreenState();
}

class _BrowseRecipesScreenState extends ConsumerState<BrowseRecipesScreen> {
  late final TextEditingController _searchCtrl;
  String _category = '';
  String _cuisine = 'All';
  String _brand = '';
  Timer? _debounce;

  bool get _isFastFood => _category == _fastFood;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.initialQuery ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = ref.read(authProvider).user;
      if (user == null) return;
      await ref.read(recipeCatalogProvider.notifier).fetchPersonalized(user.id);
      if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
        _applyFilter(logHistory: false);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _fetchFastFood({bool debounce = false}) {
    _debounce?.cancel();
    void run() => ref.read(fastFoodProvider.notifier).fetch(
          query: _searchCtrl.text,
          brand: _brand,
          userId: ref.read(authProvider).user?.id,
          dietType: ref.read(authProvider).user?.dietType,
        );
    if (debounce) {
      _debounce = Timer(const Duration(milliseconds: 350), run);
    } else {
      run();
    }
  }

  void _applyFilter({bool logHistory = false}) {
    final query = _searchCtrl.text.trim();
    if (_isFastFood) {
      // Fast food is searched on the server (brand aliases such as "dominos"
      // or "mcd" are resolved there), so typing is debounced.
      _fetchFastFood(debounce: !logHistory);
    } else {
      ref.read(recipeCatalogProvider.notifier).applyFilter(
            query: query,
            category: _category.isEmpty ? null : _category,
            cuisine: _cuisine == 'All' ? null : _cuisine,
          );
    }
    if (logHistory && query.isNotEmpty) {
      ref.read(searchHistoryProvider.notifier).logQuery(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recipeCatalogProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Recipes'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.history_rounded, color: context.textMuted),
            tooltip: 'Search History',
            onPressed: () => context.push('/search-history'),
          ),
        ],
      ),
      // Everything — filters included — scrolls as one unit, so the results
      // list isn't squeezed into whatever space a permanently-pinned filter
      // block leaves behind.
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user != null) _targetReference(user),
                  if (user != null) const SizedBox(height: 16),
                  TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _applyFilter(logHistory: true),
                    decoration: InputDecoration(
                      hintText: _isFastFood ? 'Search KFC, Whopper, Margherita...' : 'Search dishes by name or ingredients...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchCtrl.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                _applyFilter();
                                setState(() {});
                              },
                            ),
                    ),
                    onChanged: (_) {
                      _applyFilter();
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) => _filterChip(
                        _categories[i]['label']!,
                        _category == _categories[i]['value'],
                        () {
                          setState(() => _category = _categories[i]['value']!);
                          if (_isFastFood) {
                            _fetchFastFood();
                          } else {
                            _applyFilter();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Sub-options change with the category: restaurant chains
                  // for Fast Food, cuisines for everything else.
                  SizedBox(
                    height: 34,
                    child: _isFastFood
                        ? ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: kFastFoodBrands.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 8),
                            itemBuilder: (context, i) => _filterChip(
                              kFastFoodBrands[i]['label']!,
                              _brand == kFastFoodBrands[i]['value'],
                              () {
                                setState(() => _brand = kFastFoodBrands[i]['value']!);
                                _fetchFastFood();
                              },
                              accent: AppColors.accent,
                            ),
                          )
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _cuisines.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 8),
                            itemBuilder: (context, i) => _filterChip(
                              _cuisines[i],
                              _cuisine == _cuisines[i],
                              () {
                                setState(() => _cuisine = _cuisines[i]);
                                _applyFilter();
                              },
                              accent: AppColors.accent,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: Divider(height: 1)),
          if (_isFastFood) ..._buildFastFoodSlivers() else ..._buildResultSlivers(state),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Fast Food tree:  chain  ->  menu section  ->  item
  // ---------------------------------------------------------------------

  List<Widget> _buildFastFoodSlivers() {
    final ff = ref.watch(fastFoodProvider);

    if (ff.isLoading && ff.groups.isEmpty) {
      return [const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))];
    }
    if (ff.error != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(ff.error!, style: const TextStyle(color: AppColors.error), textAlign: TextAlign.center),
          ),
        ),
      ];
    }
    if (ff.groups.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No fast-food items match this search.\nTry another chain or dish name.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textMuted, height: 1.5),
            ),
          ),
        ),
      ];
    }

    final total = ff.groups.fold<int>(0, (sum, g) => sum + ((g['item_count'] as num?)?.toInt() ?? 0));
    final searching = _searchCtrl.text.trim().isNotEmpty;
    // A single chain, or an active search, opens the tree so results are visible at once.
    final openChains = searching || ff.groups.length == 1;

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('${ff.groups.length} chains · $total items',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.textMuted)),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.all(20),
        sliver: SliverList.separated(
          itemCount: ff.groups.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) => _chainNode(ff.groups[i], openChains),
        ),
      ),
    ];
  }

  Widget _chainNode(dynamic group, bool open) {
    final brand = group['brand']?.toString() ?? 'Fast Food';
    final minC = (group['min_calories'] as num?)?.round() ?? 0;
    final maxC = (group['max_calories'] as num?)?.round() ?? 0;
    final sections = (group['sections'] as List?) ?? const [];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(14),
        color: context.cardBg,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          // The key includes the open flag so the tile re-opens when a search starts.
          key: PageStorageKey('chain-$brand-$open'),
          initiallyExpanded: open,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          title: Text(brand, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _tag('${group['item_count']} items', AppColors.primary),
                if (maxC > 0) _tag('$minC - $maxC kcal', AppColors.calories),
              ],
            ),
          ),
          children: [for (final s in sections) _sectionNode(s, open)],
        ),
      ),
    );
  }

  Widget _sectionNode(dynamic section, bool open) {
    final name = section['section_name']?.toString() ?? 'Menu';
    final items = (section['items'] as List?) ?? const [];

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: PageStorageKey('section-$name-${items.length}-$open'),
        initiallyExpanded: open,
        tilePadding: const EdgeInsets.symmetric(horizontal: 10),
        childrenPadding: EdgeInsets.zero,
        dense: true,
        title: Row(
          children: [
            Expanded(
              child: Text(name.toUpperCase(),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.4, color: context.textMuted)),
            ),
            Text('${items.length}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.textDim)),
          ],
        ),
        children: [for (final it in items) _fastFoodItem(it)],
      ),
    );
  }

  Widget _fastFoodItem(dynamic item) {
    final kcal = (item['energy_kcal'] as num?)?.round() ?? 0;
    final tag = item['dietary_tag']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(12),
        color: context.inputBg,
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.only(left: 12, right: 4),
        title: Text(item['recipe_name']?.toString() ?? 'Item', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (tag != null) _tag(tag, AppColors.primary),
              _tag('$kcal kcal', AppColors.calories),
              _tag('${(item['protein_g'] as num?)?.round() ?? 0}g P', AppColors.protein),
              _tag('${(item['carb_g'] as num?)?.round() ?? 0}g C', AppColors.carbs),
              _tag('${(item['fat_g'] as num?)?.round() ?? 0}g F', AppColors.fat),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
          tooltip: 'Log meal',
          onPressed: () => _chooseSlotAndLog(item),
        ),
      ),
    );
  }

  Future<void> _chooseSlotAndLog(dynamic item) async {
    final slot = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('Log "${item['recipe_name']}" as', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
            for (final s in const ['Breakfast', 'Lunch', 'Dinner', 'Snack'])
              ListTile(title: Text(s), onTap: () => Navigator.pop(ctx, s)),
          ],
        ),
      ),
    );
    if (slot == null || !mounted) return;

    final user = ref.read(authProvider).user;
    if (user == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ApiClient().dio.post(ApiEndpoints.mealLogs, data: {
        'user_id': user.id,
        'meal_type': slot,
        'source': 'fast_food',
        'food_name': item['recipe_name'],
        'calories': item['energy_kcal'],
        'protein': item['protein_g'],
        'carbs': item['carb_g'],
        'fat': item['fat_g'],
      });
      unawaited(ref.read(analyticsProvider.notifier).fetchMealLogs(user.id));
      messenger.showSnackBar(SnackBar(content: Text('Logged ${item['recipe_name']} for $slot')));
    } on DioException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(apiDetail(e) ?? 'Could not log this meal.')));
    }
  }

  Widget _targetReference(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.inputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('YOUR PERSONALIZED TARGET REFERENCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: context.textMuted, letterSpacing: 0.4)),
          const SizedBox(height: 10),
          Row(
            children: [
              _targetTile('Calories', user.targetCalories, '', AppColors.calories),
              const SizedBox(width: 8),
              _targetTile('Protein', user.targetProtein, 'g', AppColors.protein),
              const SizedBox(width: 8),
              _targetTile('Carbs', user.targetCarbs, 'g', AppColors.carbs),
              const SizedBox(width: 8),
              _targetTile('Fat', user.targetFat, 'g', AppColors.fat),
            ],
          ),
        ],
      ),
    );
  }

  Widget _targetTile(String label, num? value, String unit, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value != null ? '${value.round()}$unit' : '—', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 9, color: context.textMuted)),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap, {Color accent = AppColors.primary}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.12) : context.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? accent : context.borderColor, width: selected ? 1.4 : 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? accent : context.textMuted,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildResultSlivers(RecipeCatalogState state) {
    if (state.isLoading) {
      return [
        const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
      ];
    }

    if (state.error != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(state.error!, style: const TextStyle(color: AppColors.error), textAlign: TextAlign.center),
          ),
        ),
      ];
    }

    if (state.allResults.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No recommendations available. Save your profile to discover meals.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textMuted, height: 1.5),
            ),
          ),
        ),
      ];
    }

    if (state.filteredResults.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.no_meals_rounded, size: 48, color: context.textDim),
                const SizedBox(height: 12),
                Text(
                  'No recipes match this search.\nTry a different name, cuisine, or meal type.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.textMuted, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('${state.filteredResults.length} recipes', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.textMuted)),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.all(20),
        sliver: SliverList.separated(
          itemCount: state.filteredResults.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final r = state.filteredResults[index];
            final healthScore = r['health_score'] as num?;
            final color = healthScore == null
                ? context.textMuted
                : healthScore >= 70
                    ? AppColors.success
                    : healthScore >= 40
                        ? AppColors.warning
                        : AppColors.error;

            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: context.borderColor),
                borderRadius: BorderRadius.circular(14),
                color: context.cardBg,
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                onTap: () => context.push('/recipe/${r['recipe_code']}'),
                title: Text(r['recipe_name'] ?? 'Unnamed Recipe', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (r['dietary_tag'] != null) _tag(r['dietary_tag'].toString(), AppColors.primary),
                      if (r['cuisine'] != null) _tag(r['cuisine'].toString(), AppColors.accent),
                      if (r['category'] != null) _tag(r['category'].toString(), context.textMuted),
                      _tag('${(r['energy_kcal'] as num?)?.round() ?? 0} kcal', AppColors.calories),
                    ],
                  ),
                ),
                trailing: healthScore != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${healthScore.round()}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color)),
                          Text('score', style: TextStyle(fontSize: 9, color: context.textDim)),
                        ],
                      )
                    : Icon(Icons.chevron_right_rounded, color: context.textDim),
              ),
            );
          },
        ),
      ),
    ];
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
