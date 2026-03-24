import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/competition.dart';
import '../repositories/competitions_repository.dart';

/// Use case: fetch all competitions from SoaringSpot.
///
/// Delegates directly to [CompetitionsRepository.fetchCompetitions].
class FetchCompetitions {
  /// Creates a [FetchCompetitions] use case.
  const FetchCompetitions(this._repository);

  final CompetitionsRepository _repository;

  /// Execute the use case.
  Future<Either<Failure, List<Competition>>> call() =>
      _repository.fetchCompetitions();
}
