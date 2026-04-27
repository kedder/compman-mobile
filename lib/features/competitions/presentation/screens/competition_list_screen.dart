import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/bookmarked_competition.dart';
import '../providers/competitions_providers.dart';
import '../widgets/competition_card.dart';

/// Screen for browsing and selecting competitions to bookmark.
class CompetitionListScreen extends ConsumerStatefulWidget {
  /// Creates the [CompetitionListScreen].
  const CompetitionListScreen({super.key});

  @override
  ConsumerState<CompetitionListScreen> createState() =>
      _CompetitionListScreenState();
}

class _CompetitionListScreenState extends ConsumerState<CompetitionListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Set<String> _selectedIds = {};
  bool _initialized = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookmarksAsync = ref.watch(bookmarkedCompetitionsProvider);
    final competitionsAsync = ref.watch(competitionListProvider);

    // Pre-populate selectedIds from bookmarks on first successful load.
    if (!_initialized) {
      bookmarksAsync.whenData((bookmarks) {
        _selectedIds = bookmarks.map((b) => b.id).toSet();
        _initialized = true;
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Competition'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () => _onDone(context),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: SizedBox(
              height: 48,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search competitions...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
          ),
          Expanded(
            child: competitionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => _ErrorView(
                onRetry: () => ref.invalidate(competitionListProvider),
              ),
              data: (competitions) {
                final filtered = _searchQuery.isEmpty
                    ? competitions
                    : competitions
                          .where(
                            (c) => c.title.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ),
                          )
                          .toList();

                if (filtered.isEmpty) {
                  final colorScheme = Theme.of(context).colorScheme;
                  final textTheme = Theme.of(context).textTheme;

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No competitions found.',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final competition = filtered[index];
                    return CompetitionCard(
                      competition: competition,
                      isSelected: _selectedIds.contains(competition.id),
                      onTap: () => setState(() {
                        if (_selectedIds.contains(competition.id)) {
                          _selectedIds.remove(competition.id);
                        } else {
                          _selectedIds.add(competition.id);
                        }
                      }),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onDone(BuildContext context) async {
    final competitions = ref.read(competitionListProvider).value ?? [];
    final alreadyBookmarked =
        ref.read(bookmarkedCompetitionsProvider).value ??
        <BookmarkedCompetition>[];
    final alreadyBookmarkedIds = alreadyBookmarked.map((b) => b.id).toSet();

    final notifier = ref.read(bookmarkedCompetitionsProvider.notifier);
    for (final competition in competitions.where(
      (c) => _selectedIds.contains(c.id),
    )) {
      if (!alreadyBookmarkedIds.contains(competition.id)) {
        await notifier.bookmark(competition);
      }
    }

    if (context.mounted) context.pop();
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Could not load competitions. Check your connection.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
