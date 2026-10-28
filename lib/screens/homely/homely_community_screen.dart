import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../providers/auth_provider.dart';
import '../../providers/homely_provider.dart';
import '../../providers/scanner_provider.dart';
import '../../widgets/common/nx_error_state.dart';
import '../../widgets/common/nx_meal_type_dialog.dart';
import '../../widgets/common/nx_segmented.dart';
import 'homely_switcher.dart';

enum _CommunityTab { approved, pending, mine }

/// Search + moderation for community-submitted homely meals. Was two
/// always-expanded cards sharing one loading state under a hand-rolled
/// 3-way segmented control that didn't match the TabBar above it — now one
/// screen with a single [NxSegmented] toggle.
class HomelyCommunityScreen extends ConsumerStatefulWidget {
  const HomelyCommunityScreen({super.key});

  @override
  ConsumerState<HomelyCommunityScreen> createState() => _HomelyCommunityScreenState();
}

class _HomelyCommunityScreenState extends ConsumerState<HomelyCommunityScreen> {
  final _searchCtrl = TextEditingController();
  _CommunityTab _tab = _CommunityTab.approved;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homelyCommunityProvider.notifier).searchMeals('');
      ref.read(homelyCommunityProvider.notifier).fetchPending();
      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.read(homelyCommunityProvider.notifier).fetchMyMeals(user.id);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reload() => _onTabChanged(_tab);

  void _onTabChanged(_CommunityTab tab) {
    setState(() => _tab = tab);
    switch (tab) {
      case _CommunityTab.pending:
        ref.read(homelyCommunityProvider.notifier).fetchPending();
        break;
      case _CommunityTab.mine:
        final user = ref.read(authProvider).user;
        if (user != null) ref.read(homelyCommunityProvider.notifier).fetchMyMeals(user.id);
        break;
      case _CommunityTab.approved:
        ref.read(homelyCommunityProvider.notifier).searchMeals(_searchCtrl.text);
        break;
    }
  }

  void _addToMyBuilder(dynamic meal) async {
    // addSyntheticBaseMeal is a no-op if defaults haven't loaded yet — this
    // can happen if Community is opened directly without ever visiting
    // Quick Build first, since each screen now owns its own lifecycle.
    if (ref.read(homelyBuilderProvider).defaults == null) {
      await ref.read(homelyBuilderProvider.notifier).fetchDefaults();
      if (!mounted) return;
    }
    final nut = meal['nutrition'] ?? {};
    final code = ref.read(homelyBuilderProvider.notifier).addSyntheticBaseMeal(
          mealId: meal['id'],
          name: meal['name'] ?? 'Community Meal',
          calories: (nut['energy_kcal'] ?? 0.0).toDouble(),
          protein: (nut['protein_g'] ?? 0.0).toDouble(),
          carbs: (nut['carb_g'] ?? 0.0).toDouble(),
          fat: (nut['fat_g'] ?? 0.0).toDouble(),
        );
    context.push('/homely-build', extra: {'baseMealCode': code, 'quantity': 1});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${meal['name']}" added to Quick Build — customize it there.')),
    );
  }

  void _logCommunityMealDirect(dynamic meal) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final mealType = await NxMealTypeDialog.show(
      context,
      itemLabel: meal['name']?.toString() ?? 'Community Meal',
      title: 'Log Community Meal',
    );
    if (mealType == null || !mounted) return;

    final nut = meal['nutrition'] ?? {};
    final apiClient = ApiClient();
    final logPayload = {
      'user_id': user.id,
      'meal_type': mealType,
      'source': 'homely',
      'food_name': meal['name'] ?? 'Community Meal',
      'calories': (nut['energy_kcal'] ?? 0.0).toDouble(),
      'protein': (nut['protein_g'] ?? 0.0).toDouble(),
      'carbs': (nut['carb_g'] ?? 0.0).toDouble(),
      'fat': (nut['fat_g'] ?? 0.0).toDouble(),
    };

    try {
      await apiClient.dio.post(ApiEndpoints.mealLogs, data: logPayload);
      ref.read(analyticsProvider.notifier).fetchMealLogs(user.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logged as $mealType!'), backgroundColor: AppColors.primary),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final commState = ref.watch(homelyCommunityProvider);
    final user = ref.watch(authProvider).user;

    List<dynamic> activeList;
    String emptyMessage;
    switch (_tab) {
      case _CommunityTab.pending:
        activeList = commState.pendingReviews;
        emptyMessage = 'No pending reviews found.';
        break;
      case _CommunityTab.mine:
        activeList = commState.myMeals;
        emptyMessage = "You haven't created any homely meals yet.";
        break;
      case _CommunityTab.approved:
        activeList = commState.communityMeals;
        emptyMessage = 'No matching homely meals found.';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Community Kitchen')),
      body: Column(
        children: [
          const HomelySwitcher(current: HomelySection.community),
          Expanded(
            child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NxSegmented<_CommunityTab>(
              values: _CommunityTab.values,
              selected: _tab,
              selectedColor: AppColors.blueAction,
              labelBuilder: (v) => switch (v) {
                _CommunityTab.approved => 'Approved',
                _CommunityTab.pending => 'Pending',
                _CommunityTab.mine => 'My Recipes',
              },
              onChanged: _onTabChanged,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_tab == _CommunityTab.approved) ...[
              TextField(
                controller: _searchCtrl,
                textInputAction: TextInputAction.search,
                onSubmitted: (q) => ref.read(homelyCommunityProvider.notifier).searchMeals(q),
                decoration: InputDecoration(
                  hintText: 'Search approved community meals...',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search_rounded, size: 20),
                    onPressed: () => ref.read(homelyCommunityProvider.notifier).searchMeals(_searchCtrl.text),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            if (commState.isLoading)
              const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl), child: Center(child: CircularProgressIndicator()))
            else if (commState.error != null && activeList.isEmpty)
              NxErrorState(message: commState.error!, onRetry: _reload)
            else if (activeList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                child: Center(child: Text(emptyMessage, style: TextStyle(color: context.textMuted))),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeList.length,
                itemBuilder: (context, index) => _communityMealCard(activeList[index], user),
              ),
          ],
        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _communityMealCard(dynamic meal, dynamic user) {
    final nut = meal['nutrition'] ?? {};
    final isPending = _tab == _CommunityTab.pending;

    return InkWell(
      borderRadius: AppRadius.mdAll,
      onTap: () => context.push('/homely-meal/${meal['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(border: Border.all(color: context.borderColor), borderRadius: AppRadius.mdAll, color: context.cardBg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(meal['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                ),
                Icon(Icons.chevron_right_rounded, size: 18, color: context.textDim),
              ],
            ),
            const SizedBox(height: 4),
            Text('Cuisine: ${meal['cuisine'] ?? '—'} | Region: ${meal['region'] ?? '—'}', style: TextStyle(fontSize: 11, color: context.textMuted)),
            const SizedBox(height: 8),
            Text(
              'Macros: ${(nut['energy_kcal'] ?? 0).round()} kcal | ${(nut['protein_g'] ?? 0).round()}g P | ${(nut['carb_g'] ?? 0).round()}g C | ${(nut['fat_g'] ?? 0).round()}g F',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            if (isPending)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: user == null
                          ? null
                          : () => ref.read(homelyCommunityProvider.notifier).moderateMeal(mealId: meal['id'], status: 'approved', userId: user.id),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Text('Approve', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: user == null
                          ? null
                          : () => ref.read(homelyCommunityProvider.notifier).moderateMeal(mealId: meal['id'], status: 'rejected', userId: user.id),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                      child: const Text('Reject', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _addToMyBuilder(meal),
                      icon: const Icon(Icons.tune_rounded, size: 16),
                      label: const Text('Add to My Builder', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _logCommunityMealDirect(meal),
                      icon: const Icon(Icons.add_task_rounded, size: 16),
                      label: const Text('Log Meal', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
