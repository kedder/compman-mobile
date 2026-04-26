import 'package:compman_mobile/core/error/failures.dart';
import 'package:compman_mobile/features/competitions/domain/entities/bookmarked_competition.dart';
import 'package:compman_mobile/features/competitions/domain/usecases/get_bookmarked_competitions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import 'mock_competitions_repository.mocks.dart';

void main() {
  late MockCompetitionsRepository mockRepository;
  late GetBookmarkedCompetitions useCase;

  setUp(() {
    mockRepository = MockCompetitionsRepository();
    useCase = GetBookmarkedCompetitions(mockRepository);
    provideDummy<Either<Failure, List<BookmarkedCompetition>>>(Right(const []));
  });

  final tBookmarks = [
    BookmarkedCompetition(
      id: 'barron-2024',
      title: 'Barron 2024',
      soaringspotUrl: 'https://www.soaringspot.com/en_gb/barron-2024/',
      bookmarkedAt: DateTime(2024, 1, 1),
    ),
  ];

  test('delegates to repository and returns its result on success', () async {
    when(
      mockRepository.getBookmarkedCompetitions(),
    ).thenAnswer((_) async => Right(tBookmarks));

    final result = await useCase();

    expect(result, Right(tBookmarks));
    verify(mockRepository.getBookmarkedCompetitions());
    verifyNoMoreInteractions(mockRepository);
  });

  test('delegates to repository and returns its failure unchanged', () async {
    const failure = Failure.storage('read error');
    when(
      mockRepository.getBookmarkedCompetitions(),
    ).thenAnswer((_) async => const Left(failure));

    final result = await useCase();

    expect(result, const Left(failure));
    verify(mockRepository.getBookmarkedCompetitions());
    verifyNoMoreInteractions(mockRepository);
  });
}
