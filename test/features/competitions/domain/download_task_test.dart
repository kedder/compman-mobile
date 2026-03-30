import 'dart:typed_data';

import 'package:compman_mobile/core/error/failures.dart';
import 'package:compman_mobile/features/competitions/domain/usecases/download_task.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import 'mock_competitions_repository.mocks.dart';

void main() {
  late MockCompetitionsRepository mockRepository;
  late DownloadTask useCase;

  setUp(() {
    mockRepository = MockCompetitionsRepository();
    useCase = DownloadTask(mockRepository);
    provideDummy<Either<Failure, Uint8List>>(Right(Uint8List(0)));
  });

  const tTaskUrl =
      'http://soarscore.com/competitions/celje-cup-2020/club-task5.tsk';
  final tBytes = Uint8List.fromList([0x3C, 0x3F, 0x78, 0x6D, 0x6C]);

  test('delegates to repository and returns Right(Uint8List) on success',
      () async {
    when(mockRepository.downloadTask(tTaskUrl))
        .thenAnswer((_) async => Right(tBytes));

    final result = await useCase(tTaskUrl);

    expect(result, Right(tBytes));
    verify(mockRepository.downloadTask(tTaskUrl));
    verifyNoMoreInteractions(mockRepository);
  });

  test('delegates to repository and returns Left(NetworkFailure) on failure',
      () async {
    const failure = Failure.network('download failed');
    when(mockRepository.downloadTask(tTaskUrl))
        .thenAnswer((_) async => const Left(failure));

    final result = await useCase(tTaskUrl);

    expect(result, const Left(failure));
    verify(mockRepository.downloadTask(tTaskUrl));
    verifyNoMoreInteractions(mockRepository);
  });
}
