import 'package:compman_mobile/core/error/failures.dart';
import 'package:compman_mobile/features/competitions/domain/entities/competition.dart';
import 'package:compman_mobile/features/competitions/domain/usecases/bookmark_competition.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import 'mock_competitions_repository.mocks.dart';

void main() {
  late MockCompetitionsRepository mockRepository;
  late BookmarkCompetition useCase;

  setUp(() {
    mockRepository = MockCompetitionsRepository();
    useCase = BookmarkCompetition(mockRepository);
    provideDummy<Either<Failure, Unit>>(const Right(unit));
  });

  const tCompetition = Competition(
    id: 'barron-2024',
    title: 'Barron 2024',
    url: 'https://www.soaringspot.com/en_gb/barron-2024/',
    description: '01 Jan – 07 Jan 2024 · Barron, Australia',
  );

  test('delegates to repository and returns unit on success', () async {
    when(
      mockRepository.bookmarkCompetition(tCompetition),
    ).thenAnswer((_) async => const Right(unit));

    final result = await useCase(tCompetition);

    expect(result, const Right(unit));
    verify(mockRepository.bookmarkCompetition(tCompetition));
    verifyNoMoreInteractions(mockRepository);
  });

  test('delegates to repository and returns its failure unchanged', () async {
    const failure = Failure.storage('write error');
    when(
      mockRepository.bookmarkCompetition(tCompetition),
    ).thenAnswer((_) async => const Left(failure));

    final result = await useCase(tCompetition);

    expect(result, const Left(failure));
    verify(mockRepository.bookmarkCompetition(tCompetition));
    verifyNoMoreInteractions(mockRepository);
  });
}
