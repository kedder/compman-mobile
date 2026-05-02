import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/downloadable_file_info.dart';
import '../repositories/competitions_repository.dart';

/// Records the installed version token for an airspace or waypoints file.
///
/// Returns a [Right] with [Unit] on success, or a [Left] with a [Failure]
/// if the competition is not bookmarked or storage fails.
class RecordFileInstall {
  /// The repository used to persist the version token.
  final CompetitionsRepository _repo;

  /// Creates a [RecordFileInstall] use case with the given [repository].
  const RecordFileInstall(this._repo);

  /// Records [version] as the installed version for the file of [kind] in
  /// the competition identified by [competitionId].
  Future<Either<Failure, Unit>> call(
    String competitionId,
    DownloadableFileKind kind,
    String? version,
  ) => _repo.recordFileInstall(competitionId, kind, version);
}
