import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/competitions_repository.dart';

/// Use case: remove a competition from the user's bookmarks.
///
/// Delegates directly to [CompetitionsRepository.removeBookmark].
class RemoveBookmark {
  /// Creates a [RemoveBookmark] use case.
  const RemoveBookmark(this._repository);

  final CompetitionsRepository _repository;

  /// Execute the use case for the competition identified by [competitionId].
  Future<Either<Failure, Unit>> call(String competitionId) =>
      _repository.removeBookmark(competitionId);
}
