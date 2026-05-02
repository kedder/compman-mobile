import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/bookmarked_competition.dart';
import '../entities/competition.dart';
import '../entities/downloadable_file_info.dart';
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
    String competitionId,
  );

  /// Download the raw bytes of a `.tsk` file from [taskUrl].
  Future<Either<Failure, Uint8List>> downloadTask(String taskUrl);

  /// Persists the selected competition class for a bookmarked competition.
  ///
  /// A [selectedClass] of null clears the selection.
  Future<Either<Failure, Unit>> setCompetitionClass(
    String competitionId,
    String? selectedClass,
  );

  /// Fetches the list of competition class names for a bookmarked competition.
  ///
  /// Looks up [competitionId] in local storage to get its SoaringSpot URL,
  /// then scrapes the `/results` page for class names.
  /// Returns an empty list (not a failure) if no classes are found.
  Future<Either<Failure, List<String>>> fetchCompetitionClasses(
    String competitionId,
  );

  /// Fetches the list of downloadable airspace and waypoint files from the
  /// SoaringSpot downloads page for the competition identified by
  /// [competitionId].
  ///
  /// Looks up [competitionId] in local bookmarks to obtain the SoaringSpot URL.
  /// Returns an empty list (not a failure) if no relevant files are found.
  Future<Either<Failure, List<DownloadableFileInfo>>> fetchDownloads(
    String competitionId,
  );

  /// Downloads the raw bytes of an airspace or waypoint file from [fileUrl].
  Future<Either<Failure, Uint8List>> downloadFile(String fileUrl);

  /// Records the installed version token for an airspace or waypoints file.
  ///
  /// [version] is the raw [DownloadableFileInfo.publishedVersion] string
  /// captured at install time. [kind] determines which field to update.
  Future<Either<Failure, Unit>> recordFileInstall(
    String competitionId,
    DownloadableFileKind kind,
    String? version,
  );
}
