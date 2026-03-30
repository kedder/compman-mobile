import 'package:compman_mobile/core/error/failures.dart';
import 'package:compman_mobile/features/competitions/domain/usecases/set_competition_class.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import 'mock_competitions_repository.mocks.dart';

void main() {
  late MockCompetitionsRepository mockRepository;
  late SetCompetitionClass useCase;

  setUp(() {
    mockRepository = MockCompetitionsRepository();
    useCase = SetCompetitionClass(mockRepository);
    provideDummy<Either<Failure, Unit>>(const Right(unit));
  });

  group('SetCompetitionClass', () {
    test('sets class: delegates to repository and returns unit on success',
        () async {
      when(mockRepository.setCompetitionClass('comp-id', 'Club'))
          .thenAnswer((_) async => const Right(unit));

      final result = await useCase('comp-id', 'Club');

      expect(result, const Right(unit));
      verify(mockRepository.setCompetitionClass('comp-id', 'Club'));
      verifyNoMoreInteractions(mockRepository);
    });

    test('clears class: delegates with null selectedClass', () async {
      when(mockRepository.setCompetitionClass('comp-id', null))
          .thenAnswer((_) async => const Right(unit));

      final result = await useCase('comp-id', null);

      expect(result, const Right(unit));
      verify(mockRepository.setCompetitionClass('comp-id', null));
      verifyNoMoreInteractions(mockRepository);
    });

    test('propagates Left(StorageFailure) from repository', () async {
      const failure = Failure.storage('Competition not found');
      when(mockRepository.setCompetitionClass('comp-id', 'Club'))
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase('comp-id', 'Club');

      expect(result, const Left(failure));
      verify(mockRepository.setCompetitionClass('comp-id', 'Club'));
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
