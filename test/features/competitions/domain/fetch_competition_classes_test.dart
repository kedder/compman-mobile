import 'package:compman_mobile/core/error/failures.dart';
import 'package:compman_mobile/features/competitions/domain/usecases/fetch_competition_classes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import 'mock_competitions_repository.mocks.dart';

void main() {
  late MockCompetitionsRepository mockRepository;
  late FetchCompetitionClasses useCase;

  setUp(() {
    mockRepository = MockCompetitionsRepository();
    useCase = FetchCompetitionClasses(mockRepository);
    provideDummy<Either<Failure, List<String>>>(const Right([]));
  });

  const tCompetitionId = 'barron-2024';

  test('returns Right(["Standard", "Club"]) when repository succeeds',
      () async {
    when(mockRepository.fetchCompetitionClasses(tCompetitionId))
        .thenAnswer((_) async => const Right(['Standard', 'Club']));

    final result = await useCase(tCompetitionId);

    expect(result, const Right(['Standard', 'Club']));
    verify(mockRepository.fetchCompetitionClasses(tCompetitionId));
    verifyNoMoreInteractions(mockRepository);
  });

  test('returns Left(NetworkFailure) when repository fails', () async {
    const failure = Failure.network('connection refused');
    when(mockRepository.fetchCompetitionClasses(tCompetitionId))
        .thenAnswer((_) async => const Left(failure));

    final result = await useCase(tCompetitionId);

    expect(result, const Left(failure));
    verify(mockRepository.fetchCompetitionClasses(tCompetitionId));
    verifyNoMoreInteractions(mockRepository);
  });
}
