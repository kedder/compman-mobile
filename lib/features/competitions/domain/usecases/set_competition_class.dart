import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/competitions_repository.dart';

/// Sets or clears the selected competition class for a bookmarked competition.
///
/// The selected class is persisted locally so that the correct task is shown
/// on subsequent visits without re-asking the user.
class SetCompetitionClass {
  final CompetitionsRepository _repo;

  /// Creates a [SetCompetitionClass] use case backed by [repo].
  const SetCompetitionClass(this._repo);

  /// Sets or clears the competition class for [competitionId].
  ///
  /// Pass null for [selectedClass] to clear the selection.
  Future<Either<Failure, Unit>> call(
    String competitionId,
    String? selectedClass,
  ) => _repo.setCompetitionClass(competitionId, selectedClass);
}
