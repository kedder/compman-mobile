import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../domain/entities/bookmarked_competition.dart';
import '../../domain/entities/competition.dart';
import '../../domain/usecases/bookmark_competition.dart';
import '../../domain/usecases/fetch_competitions.dart';
import '../../domain/usecases/get_bookmarked_competitions.dart';
import '../../domain/usecases/remove_bookmark.dart';

/// Provider for the full list of competitions fetched from SoaringSpot.
final competitionListProvider =
    AsyncNotifierProvider<CompetitionListNotifier, List<Competition>>(
  CompetitionListNotifier.new,
);

/// Notifier that manages the remote competition list state.
class CompetitionListNotifier extends AsyncNotifier<List<Competition>> {
  @override
  Future<List<Competition>> build() async {
    // Wait for the Hive box to be ready before accessing the repository.
    await ref.watch(bookmarksBoxProvider.future);
    final result =
        await FetchCompetitions(ref.watch(competitionsRepositoryProvider))();
    return result.fold((failure) => throw failure, (list) => list);
  }

  /// Re-fetches competitions from SoaringSpot.
  Future<void> refresh() async => ref.invalidateSelf();
}

/// Provider for the user's bookmarked competitions.
final bookmarkedCompetitionsProvider = AsyncNotifierProvider<
    BookmarkedCompetitionsNotifier, List<BookmarkedCompetition>>(
  BookmarkedCompetitionsNotifier.new,
);

/// Notifier that manages the bookmarked competitions state.
class BookmarkedCompetitionsNotifier
    extends AsyncNotifier<List<BookmarkedCompetition>> {
  @override
  Future<List<BookmarkedCompetition>> build() async {
    // Wait for the Hive box to be ready before accessing the repository.
    await ref.watch(bookmarksBoxProvider.future);
    final result = await GetBookmarkedCompetitions(
      ref.watch(competitionsRepositoryProvider),
    )();
    return result.fold((failure) => throw failure, (list) => list);
  }

  /// Adds [competition] to the user's bookmarks, then refreshes.
  Future<void> bookmark(Competition competition) async {
    await BookmarkCompetition(ref.read(competitionsRepositoryProvider))(
      competition,
    );
    ref.invalidateSelf();
  }

  /// Removes the bookmark identified by [id], then refreshes.
  Future<void> removeBookmark(String id) async {
    await RemoveBookmark(ref.read(competitionsRepositoryProvider))(id);
    ref.invalidateSelf();
  }
}
