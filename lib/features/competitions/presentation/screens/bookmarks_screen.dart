import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/bookmarked_competition.dart';
import '../providers/competitions_providers.dart';

/// Home screen showing the user's bookmarked competitions.
class BookmarksScreen extends ConsumerWidget {
  /// Creates the [BookmarksScreen].
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarkedCompetitionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Competitions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add competition',
            onPressed: () => context.push('/add'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => context.push(value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: '/settings/xcsoar-directory', child: Text('Settings')),
              PopupMenuItem(value: '/saf-test', child: Text('Try SAF')),
              PopupMenuItem(value: '/about', child: Text('About')),
            ],
          ),
        ],
      ),
      body: bookmarksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => _ErrorView(
          message: _errorMessage(err),
          onRetry: () => ref.invalidate(bookmarkedCompetitionsProvider),
        ),
        data: (bookmarks) => bookmarks.isEmpty
            ? _EmptyState(onAdd: () => context.push('/add'))
            : RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(bookmarkedCompetitionsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: bookmarks.length,
                  itemBuilder: (context, index) {
                    final bookmark = bookmarks[index];
                    return _BookmarkCard(
                      bookmark: bookmark,
                      onTap: () => context.push('/competitions/${bookmark.id}'),
                      onRemove: () => _confirmRemove(context, ref, bookmark),
                    );
                  },
                ),
              ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No competitions added yet.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('Add Competition'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  const _BookmarkCard({
    required this.bookmark,
    required this.onTap,
    required this.onRemove,
  });

  final BookmarkedCompetition bookmark;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 2,
      child: ListTile(
        title: Text(
          bookmark.title,
          style: Theme.of(context).textTheme.titleMedium,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatBookmarkedDate(bookmark.bookmarkedAt),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        trailing: Semantics(
          label: 'Remove ${bookmark.title}',
          child: IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            tooltip: 'Remove ${bookmark.title}',
            onPressed: onRemove,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

String _formatBookmarkedDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return 'Bookmarked ${months[date.month - 1]} ${date.day}, ${date.year}';
}
