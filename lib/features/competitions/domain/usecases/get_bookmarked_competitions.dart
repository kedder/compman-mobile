import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/bookmarked_competition.dart';
import '../repositories/competitions_repository.dart';

/// Use case: load all bookmarked competitions from local storage.
///
/// Delegates directly to [CompetitionsRepository.getBookmarkedCompetitions].
class GetBookmarkedCompetitions {
  /// Creates a [GetBookmarkedCompetitions] use case.
  const GetBookmarkedCompetitions(this._repository);

  final CompetitionsRepository _repository;

  /// Execute the use case.
  Future<Either<Failure, List<BookmarkedCompetition>>> call() =>
      _repository.getBookmarkedCompetitions();
}
