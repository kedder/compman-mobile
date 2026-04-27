import 'package:compman_mobile/core/error/failures.dart';
import 'package:compman_mobile/features/competitions/domain/entities/competition.dart';
import 'package:compman_mobile/features/competitions/domain/usecases/fetch_competitions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import 'mock_competitions_repository.mocks.dart';

void main() {
  late MockCompetitionsRepository mockRepository;
  late FetchCompetitions useCase;

  setUp(() {
    mockRepository = MockCompetitionsRepository();
    useCase = FetchCompetitions(mockRepository);
    provideDummy<Either<Failure, List<Competition>>>(Right(const []));
  });

  final tCompetitions = [
    Competition(
      id: 'barron-2024',
      title: 'Barron 2024',
      url: 'https://www.soaringspot.com/en_gb/barron-2024/',
      description: '01 Jan – 07 Jan 2024 · Barron, Australia',
      startDate: DateTime(2024, 1, 1),
      endDate: DateTime(2024, 1, 7),
    ),
  ];

  test('delegates to repository and returns its result on success', () async {
    when(
      mockRepository.fetchCompetitions(),
    ).thenAnswer((_) async => Right(tCompetitions));

    final result = await useCase();

    expect(result, Right(tCompetitions));
    verify(mockRepository.fetchCompetitions());
    verifyNoMoreInteractions(mockRepository);
  });

  test('delegates to repository and returns its failure unchanged', () async {
    const failure = Failure.network('no connection');
    when(
      mockRepository.fetchCompetitions(),
    ).thenAnswer((_) async => const Left(failure));

    final result = await useCase();

    expect(result, const Left(failure));
    verify(mockRepository.fetchCompetitions());
    verifyNoMoreInteractions(mockRepository);
  });
}
