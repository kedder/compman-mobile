import 'package:compman_mobile/core/error/failures.dart';
import 'package:compman_mobile/features/competitions/domain/usecases/remove_bookmark.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import 'mock_competitions_repository.mocks.dart';

void main() {
  late MockCompetitionsRepository mockRepository;
  late RemoveBookmark useCase;

  setUp(() {
    mockRepository = MockCompetitionsRepository();
    useCase = RemoveBookmark(mockRepository);
    provideDummy<Either<Failure, Unit>>(const Right(unit));
  });

  const tId = 'barron-2024';

  test('delegates to repository and returns unit on success', () async {
    when(mockRepository.removeBookmark(tId))
        .thenAnswer((_) async => const Right(unit));

    final result = await useCase(tId);

    expect(result, const Right(unit));
    verify(mockRepository.removeBookmark(tId));
    verifyNoMoreInteractions(mockRepository);
  });

  test('delegates to repository and returns its failure unchanged', () async {
    const failure = Failure.storage('delete error');
    when(mockRepository.removeBookmark(tId))
        .thenAnswer((_) async => const Left(failure));

    final result = await useCase(tId);

    expect(result, const Left(failure));
    verify(mockRepository.removeBookmark(tId));
    verifyNoMoreInteractions(mockRepository);
  });
}
