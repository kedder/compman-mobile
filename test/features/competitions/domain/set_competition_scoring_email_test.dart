import 'package:compman_mobile/core/error/failures.dart';
import 'package:compman_mobile/features/competitions/domain/usecases/set_competition_scoring_email.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import 'mock_competitions_repository.mocks.dart';

void main() {
  late MockCompetitionsRepository mockRepository;
  late SetCompetitionScoringEmail useCase;

  setUp(() {
    mockRepository = MockCompetitionsRepository();
    useCase = SetCompetitionScoringEmail(mockRepository);
    provideDummy<Either<Failure, Unit>>(const Right(unit));
  });

  group('SetCompetitionScoringEmail', () {
    test(
      'sets scoring email: delegates to repository and returns unit on success',
      () async {
        when(
          mockRepository.setCompetitionScoringEmail(
            'comp-id',
            'organizer@example.com',
          ),
        ).thenAnswer((_) async => const Right(unit));

        final result = await useCase('comp-id', 'organizer@example.com');

        expect(result, const Right(unit));
        verify(
          mockRepository.setCompetitionScoringEmail(
            'comp-id',
            'organizer@example.com',
          ),
        );
        verifyNoMoreInteractions(mockRepository);
      },
    );

    test('propagates Left(StorageFailure) from repository', () async {
      const failure = Failure.storage('Competition not found');
      when(
        mockRepository.setCompetitionScoringEmail(
          'comp-id',
          'organizer@example.com',
        ),
      ).thenAnswer((_) async => const Left(failure));

      final result = await useCase('comp-id', 'organizer@example.com');

      expect(result, const Left(failure));
      verify(
        mockRepository.setCompetitionScoringEmail(
          'comp-id',
          'organizer@example.com',
        ),
      );
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
