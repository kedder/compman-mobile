import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/bookmarked_competition.dart';
import '../providers/competitions_providers.dart';
import '../widgets/status_badge.dart';

/// Home screen showing the user's bookmarked competitions.
class BookmarksScreen extends ConsumerWidget {
  /// Creates the [BookmarksScreen].
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarkedCompetitionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your competitions'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => context.push(value),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: '/settings/xcsoar-directory',
                child: Text('Settings'),
              ),
              PopupMenuItem(value: '/about', child: Text('About')),
            ],
          ),
        ],
      ),
      floatingActionButton: switch (bookmarksAsync) {
        AsyncData(:final value) when value.isNotEmpty => FloatingActionButton(
          onPressed: () => context.push('/add'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          tooltip: 'Add competition',
          child: const Icon(Icons.add),
        ),
        _ => null,
      },
      body: bookmarksAsync.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => _ErrorView(
          message: _errorMessage(err),
          onRetry: () {
            ref.invalidate(bookmarkedCompetitionsProvider);
          },
        ),
        data: (bookmarks) {
          if (bookmarks.isEmpty) {
            return _EmptyState(onAdd: () => context.push('/add'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              final _ = await ref.refresh(
                bookmarkedCompetitionsProvider.future,
              );
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: bookmarks.length,
              itemBuilder: (context, index) {
                final bookmark = bookmarks[index];
                return _BookmarkRow(
                  bookmark: bookmark,
                  onTap: () => context.push('/competitions/${bookmark.id}'),
                  onRemove: () => _confirmRemove(context, ref, bookmark),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    BookmarkedCompetition bookmark,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove competition?'),
        content: Text('Remove "${bookmark.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(bookmarkedCompetitionsProvider.notifier)
          .removeBookmark(bookmark.id);
    }
  }
}

String _errorMessage(Object err) {
  if (err is NetworkFailure) {
    return 'Could not load competitions. Check your connection.';
  }
  if (err is StorageFailure) {
    return 'Could not load saved data.';
  }
  return 'An unexpected error occurred.';
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add your first competition',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Start tracking tasks and waypoint downloads.',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add Competition'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookmarkRow extends StatelessWidget {
  const _BookmarkRow({
    required this.bookmark,
    required this.onTap,
    required this.onRemove,
  });

  final BookmarkedCompetition bookmark;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          onLongPress: onRemove,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bookmark.title,
                                  style: textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.visible,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  bookmark.description ?? '',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.tertiary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (bookmark.status != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: StatusBadge(status: bookmark.status!),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.chevron_right, color: colorScheme.outline),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
