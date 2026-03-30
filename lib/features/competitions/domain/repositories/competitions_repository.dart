import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/bookmarked_competition.dart';
import '../entities/competition.dart';
import '../entities/task_info.dart';

/// Abstract repository interface for the competitions feature.
///
/// Implementations are in `data/repositories/`. Domain code depends only on
/// this interface — never on concrete implementations.
abstract class CompetitionsRepository {
  /// Fetch all competitions from SoaringSpot.
  Future<Either<Failure, List<Competition>>> fetchCompetitions();

  /// Return all bookmarked competitions from local storage.
  Future<Either<Failure, List<BookmarkedCompetition>>>
      getBookmarkedCompetitions();

  /// Add [competition] to the user's bookmarks.
  Future<Either<Failure, Unit>> bookmarkCompetition(Competition competition);

  /// Remove the bookmark for the competition identified by [competitionId].
  Future<Either<Failure, Unit>> removeBookmark(String competitionId);

  /// Fetch available tasks for a competition from SoarScore.
  Future<Either<Failure, List<TaskInfo>>> fetchLatestTasks(
      String competitionId);

  /// Download the raw bytes of a `.tsk` file from [taskUrl].
  Future<Either<Failure, Uint8List>> downloadTask(String taskUrl);
}
