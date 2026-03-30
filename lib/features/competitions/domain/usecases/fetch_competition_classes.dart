import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/competitions_repository.dart';

/// Returns the list of competition class names scraped from SoaringSpot.
///
/// Returns an empty list (not a failure) when the competition page has no
/// results table — this is normal before the competition begins.
class FetchCompetitionClasses {
  /// The repository used to fetch competition classes.
  final CompetitionsRepository _repo;

  /// Creates a [FetchCompetitionClasses] use case with the given [repository].
  const FetchCompetitionClasses(this._repo);

  /// Fetches class names for the competition identified by [competitionId].
  Future<Either<Failure, List<String>>> call(String competitionId) =>
      _repo.fetchCompetitionClasses(competitionId);
}
