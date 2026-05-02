import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/downloadable_file_info.dart';
import '../repositories/competitions_repository.dart';

/// Fetches the list of downloadable airspace and waypoint files from
/// SoaringSpot for a competition.
///
/// Returns a [Right] with a list of [DownloadableFileInfo] on success, or a
/// [Left] with a [Failure] if the request fails.
class FetchDownloads {
  /// The repository used to fetch download listings.
  final CompetitionsRepository _repo;

  /// Creates a [FetchDownloads] use case with the given [repository].
  const FetchDownloads(this._repo);

  /// Fetches downloadable files for the competition identified by [competitionId].
  Future<Either<Failure, List<DownloadableFileInfo>>> call(
    String competitionId,
  ) => _repo.fetchDownloads(competitionId);
}
