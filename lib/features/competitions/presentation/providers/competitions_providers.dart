import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../xcsoar/domain/xcsoar_flavor.dart';
import '../../domain/entities/bookmarked_competition.dart';
import '../../domain/entities/competition.dart';
import '../../domain/entities/downloadable_file_info.dart';
import '../../domain/entities/task_info.dart';
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
    final result = await FetchCompetitions(
      ref.watch(competitionsRepositoryProvider),
    )();
    return result.fold((failure) => throw failure, (list) => list);
  }

  /// Re-fetches competitions from SoaringSpot.
  Future<void> refresh() async => ref.invalidateSelf();
}

/// Provider for the user's bookmarked competitions.
final bookmarkedCompetitionsProvider =
    AsyncNotifierProvider<
      BookmarkedCompetitionsNotifier,
      List<BookmarkedCompetition>
    >(BookmarkedCompetitionsNotifier.new);

/// Notifier that manages the bookmarked competitions state.
class BookmarkedCompetitionsNotifier
    extends AsyncNotifier<List<BookmarkedCompetition>> {
  @override
  Future<List<BookmarkedCompetition>> build() async {
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

/// Provider that looks up a single [BookmarkedCompetition] by its ID.
///
/// Returns `null` if the competition is not in the user's bookmarks.
final competitionDetailProvider = FutureProvider.autoDispose
    .family<BookmarkedCompetition?, String>((ref, competitionId) async {
      final bookmarks = await ref.watch(bookmarkedCompetitionsProvider.future);
      try {
        return bookmarks.firstWhere((b) => b.id == competitionId);
      } catch (_) {
        return null;
      }
    });

/// Provider that fetches the latest task list from SoarScore for a competition.
///
/// Throws the [Failure] if the use case returns a [Left].
final latestTasksProvider = FutureProvider.autoDispose
    .family<List<TaskInfo>, String>((ref, competitionId) async {
      final useCase = ref.read(fetchLatestTasksProvider);
      final result = await useCase(competitionId);
      return result.fold((f) => throw f, (tasks) => tasks);
    });

/// Fetches the available competition class names from SoaringSpot.
///
/// Used by the class picker on the competition detail screen.
/// Throws [Failure] on network error; returns empty list when none found.
final competitionClassesProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, competitionId) async {
      final useCase = ref.read(fetchCompetitionClassesProvider);
      final result = await useCase(competitionId);
      return result.fold((f) => throw f, (classes) => classes);
    });

/// Provider that returns the stored SAF directory URI, or null if not set.
final xcsoarDirectoryUriProvider = FutureProvider.autoDispose<String?>((ref) {
  return ref.read(xcsoarSafServiceProvider).getSafDirectoryUri();
});

/// Resolves the package ID of the currently active XCSoar flavor.
///
/// Returns `null` if no SAF directory is configured, or if the configured
/// directory does not match any [kKnownXcsoarFlavors] package ID. Mirrors
/// `_XcsoarDirectorySettingsScreenState._resolveActiveFlavor`.
final activeFlavorPackageIdProvider = FutureProvider.autoDispose<String?>((
  ref,
) async {
  final uri = await ref.watch(xcsoarDirectoryUriProvider.future);
  if (uri == null || uri.isEmpty) return null;
  return ref
      .read(xcsoarSafServiceProvider)
      .resolveFlavorPackageId(
        uri,
        kKnownXcsoarFlavors.map((f) => f.packageId).toList(),
      );
});

/// Fetches the list of downloadable airspace and waypoints files for a
/// competition from the SoaringSpot downloads page.
///
/// Throws the [Failure] if the use case returns a [Left].
final downloadsProvider = FutureProvider.autoDispose
    .family<List<DownloadableFileInfo>, String>((ref, competitionId) async {
      final useCase = ref.read(fetchDownloadsProvider);
      final result = await useCase(competitionId);
      return result.fold((f) => throw f, (files) => files);
    });
