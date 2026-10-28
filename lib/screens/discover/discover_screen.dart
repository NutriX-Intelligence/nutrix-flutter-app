import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recipe_catalog_provider.dart';

class _DiscoverTile {
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final String route;

  const _DiscoverTile({required this.title, required this.desc, required this.icon, required this.color, required this.route});
}

const _tiles = [
  _DiscoverTile(title: 'Find by Ingredients', desc: "Tell us what's in your kitchen", icon: Icons.kitchen_rounded, color: AppColors.primary, route: '/recipes'),
  _DiscoverTile(title: 'Browse Recipes', desc: 'Explore the full recipe catalog', icon: Icons.travel_explore_rounded, color: AppColors.accent, route: '/browse'),
  _DiscoverTile(title: 'Meal Plan', desc: 'AI-optimized daily meal plan', icon: Icons.auto_awesome_rounded, color: AppColors.calories, route: '/meal-plan'),
  _DiscoverTile(title: 'AI Diet Plan', desc: 'Personalized guidance from your goals', icon: Icons.insights_rounded, color: AppColors.purpleAction, route: '/ai-diet-plan'),
  _DiscoverTile(title: 'AI Recipe Generator', desc: 'Generate a recipe from a craving', icon: Icons.auto_fix_high_rounded, color: AppColors.purpleAction, route: '/ai-recipe-gen'),
  _DiscoverTile(title: 'AI Coach', desc: 'Chat about nutrition & healthy eating', icon: Icons.smart_toy_outlined, color: AppColors.purpleAction, route: '/ai-coach'),
];

/// Used to be a menu page — 4 grid tiles and nothing else, with AI Diet
/// Plan and AI Recipe Generator hidden 3 taps deep inside a generic "AI
/// Tools" sheet nothing on the tab hinted at. Now the AI tools are
/// first-class tiles, there's a tap-to-search shortcut into Browse, and a
/// personalized row so the tab has actual content instead of only being a
/// menu.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.read(recipeCatalogProvider.notifier).fetchPersonalized(user.id, limit: 10);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(recipeCatalogProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Discover', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text('Recipes, meal plans & AI tools built around your goals', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              readOnly: true,
              onTap: () => context.push('/browse'),
              decoration: InputDecoration(
                hintText: 'Search dishes by name or cuisine...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true,
                fillColor: context.inputBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _tiles.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (context, index) => _tileCard(context, _tiles[index]),
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildRecommendedRow(context, catalogState),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedRow(BuildContext context, RecipeCatalogState state) {
    if (state.isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24), child: CircularProgressIndicator()));
    }
    if (state.error != null || state.allResults.isEmpty) {
      // A logged-out preview, or a personalization failure, isn't worth
      // surfacing as an error here — the tile grid above still works fine.
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recommended for you', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.textMain, letterSpacing: -0.2)),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: state.allResults.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) => _recommendedCard(context, state.allResults[index]),
          ),
        ),
      ],
    );
  }

  Widget _recommendedCard(BuildContext context, dynamic item) {
    final healthScore = (item['health_score'] as num?)?.round();
    final isHealthy = item['health_category'] == 'Healthy';
    final isUnhealthy = item['health_category'] == 'Unhealthy';
    final scoreColor = isHealthy ? AppColors.healthy : (isUnhealthy ? AppColors.unhealthy : AppColors.moderate);

    return Material(
      color: context.cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => context.push('/recipe/${item['recipe_code']}'),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 176,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: context.borderColor)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item['recipe_name']?.toString() ?? 'Recipe',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.textMain),
              ),
              Text(item['cuisine']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: context.textMuted)),
              if (healthScore != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: scoreColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text('$healthScore/100', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: scoreColor)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tileCard(BuildContext context, _DiscoverTile tile) {
    return Card(
      elevation: 0.5,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: context.borderColor, width: 1),
      ),
      child: InkWell(
        onTap: () => context.push(tile.route),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tile.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(tile.icon, color: tile.color, size: 22),
              ),
              const SizedBox(height: 14),
              Text(
                tile.title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.textMain),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                tile.desc,
                style: TextStyle(fontSize: 11, color: context.textMuted, height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
