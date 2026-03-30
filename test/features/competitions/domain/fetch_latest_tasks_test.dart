import 'package:compman_mobile/core/error/failures.dart';
import 'package:compman_mobile/features/competitions/domain/entities/task_info.dart';
import 'package:compman_mobile/features/competitions/domain/usecases/fetch_latest_tasks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import 'mock_competitions_repository.mocks.dart';

void main() {
  late MockCompetitionsRepository mockRepository;
  late FetchLatestTasks useCase;

  setUp(() {
    mockRepository = MockCompetitionsRepository();
    useCase = FetchLatestTasks(mockRepository);
    provideDummy<Either<Failure, List<TaskInfo>>>(const Right([]));
  });

  const tCompetitionId = 'celje-cup-2020';
  const tTasks = [
    TaskInfo(
      compClass: 'Club',
      title: 'AAT 159/361km',
      dayNo: 6,
      taskNo: 5,
      timestamp: '01-07-2020 21:35:04',
      taskUrl:
          'http://soarscore.com/competitions/celje-cup-2020/club-task5.tsk',
    ),
  ];

  test('delegates to repository and returns Right(List<TaskInfo>) on success',
      () async {
    when(mockRepository.fetchLatestTasks(tCompetitionId))
        .thenAnswer((_) async => const Right(tTasks));

    final result = await useCase(tCompetitionId);

    expect(result, const Right(tTasks));
    verify(mockRepository.fetchLatestTasks(tCompetitionId));
    verifyNoMoreInteractions(mockRepository);
  });

  test('delegates to repository and returns Left(NetworkFailure) on failure',
      () async {
    const failure = Failure.network('connection refused');
    when(mockRepository.fetchLatestTasks(tCompetitionId))
        .thenAnswer((_) async => const Left(failure));

    final result = await useCase(tCompetitionId);

    expect(result, const Left(failure));
    verify(mockRepository.fetchLatestTasks(tCompetitionId));
    verifyNoMoreInteractions(mockRepository);
  });
}
