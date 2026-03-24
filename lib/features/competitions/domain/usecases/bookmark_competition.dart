import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/competition.dart';
import '../repositories/competitions_repository.dart';

/// Use case: bookmark a competition so it appears in the user's list.
///
/// Delegates directly to [CompetitionsRepository.bookmarkCompetition].
class BookmarkCompetition {
  /// Creates a [BookmarkCompetition] use case.
  const BookmarkCompetition(this._repository);

  final CompetitionsRepository _repository;

  /// Execute the use case with the given [competition].
  Future<Either<Failure, Unit>> call(Competition competition) =>
      _repository.bookmarkCompetition(competition);
}
