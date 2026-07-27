import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/competitions_repository.dart';

/// Sets the scoring email address for a bookmarked competition.
///
/// The scoring email is persisted locally so organizers' scoring address is
/// remembered and pre-filled on subsequent visits without re-asking the user.
class SetCompetitionScoringEmail {
  final CompetitionsRepository _repo;

  /// Creates a [SetCompetitionScoringEmail] use case backed by [repo].
  const SetCompetitionScoringEmail(this._repo);

  /// Sets the scoring email for [competitionId] to [email].
  Future<Either<Failure, Unit>> call(String competitionId, String email) =>
      _repo.setCompetitionScoringEmail(competitionId, email);
}
