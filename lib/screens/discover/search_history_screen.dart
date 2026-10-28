import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/search_history_provider.dart';

class SearchHistoryScreen extends ConsumerStatefulWidget {
  const SearchHistoryScreen({super.key});

  @override
  ConsumerState<SearchHistoryScreen> createState() => _SearchHistoryScreenState();
}

class _SearchHistoryScreenState extends ConsumerState<SearchHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchHistoryProvider.notifier).fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search History'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(searchHistoryProvider.notifier).fetchHistory(),
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(SearchHistoryState state) {
    if (state.isLoading && state.history.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.history.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.error_outline_rounded, size: 48, color: context.textDim),
          const SizedBox(height: 12),
          Center(
            child: Text(state.error!, style: TextStyle(color: context.textMuted), textAlign: TextAlign.center),
          ),
        ],
      );
    }

    if (state.history.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Icon(Icons.history_rounded, size: 48, color: context.textDim),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'No searches yet.\nRecipe searches you make will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textMuted, height: 1.5),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: state.history.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final entry = state.history[index];
        final query = entry['query']?.toString() ?? '';
        String timeLabel = '';
        final searchedAt = entry['searched_at']?.toString();
        if (searchedAt != null) {
          final parsed = DateTime.tryParse(searchedAt);
          if (parsed != null) {
            timeLabel = DateFormat('MMM d, h:mm a').format(parsed.toLocal());
          }
        }

        return Material(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => context.push('/browse', extra: query),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.textDim.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.history_rounded, size: 16, color: context.textMuted),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(query, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        if (timeLabel.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(timeLabel, style: TextStyle(fontSize: 11, color: context.textDim)),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.north_west_rounded, size: 16, color: context.textDim),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
