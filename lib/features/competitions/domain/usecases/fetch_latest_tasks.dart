import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/task_info.dart';
import '../repositories/competitions_repository.dart';

/// Fetches the list of available task files from SoarScore for a competition.
///
/// Returns a [Right] with a list of [TaskInfo] on success, or a [Left] with
/// a [Failure] if the request fails.
class FetchLatestTasks {
  /// The repository used to fetch task information.
  final CompetitionsRepository _repo;

  /// Creates a [FetchLatestTasks] use case with the given [repository].
  const FetchLatestTasks(this._repo);

  /// Fetches available tasks for the competition identified by [competitionId].
  Future<Either<Failure, List<TaskInfo>>> call(String competitionId) =>
      _repo.fetchLatestTasks(competitionId);
}
