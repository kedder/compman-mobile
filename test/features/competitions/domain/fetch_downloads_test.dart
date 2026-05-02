import 'package:compman_mobile/core/error/failures.dart';
import 'package:compman_mobile/features/competitions/domain/entities/downloadable_file_info.dart';
import 'package:compman_mobile/features/competitions/domain/usecases/fetch_downloads.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import 'mock_competitions_repository.mocks.dart';

void main() {
  late MockCompetitionsRepository mockRepository;
  late FetchDownloads useCase;

  setUp(() {
    mockRepository = MockCompetitionsRepository();
    useCase = FetchDownloads(mockRepository);
    provideDummy<Either<Failure, List<DownloadableFileInfo>>>(const Right([]));
  });

  const tCompetitionId = 'wgc2018pl';

  final tFiles = [
    const DownloadableFileInfo(
      filename: 'airspace.txt',
      downloadUrl: 'https://example.com/airspace.txt',
      kind: DownloadableFileKind.airspace,
      publishedVersion: '10/07/2018, 17:44',
    ),
  ];

  test('delegates to repository.fetchDownloads and returns result', () async {
    when(
      mockRepository.fetchDownloads(tCompetitionId),
    ).thenAnswer((_) async => Right(tFiles));

    final result = await useCase(tCompetitionId);

    expect(result, Right(tFiles));
    verify(mockRepository.fetchDownloads(tCompetitionId));
    verifyNoMoreInteractions(mockRepository);
  });

  test('propagates Left as-is', () async {
    const failure = Failure.network('no connection');
    when(
      mockRepository.fetchDownloads(tCompetitionId),
    ).thenAnswer((_) async => const Left(failure));

    final result = await useCase(tCompetitionId);

    expect(result, const Left(failure));
    verify(mockRepository.fetchDownloads(tCompetitionId));
    verifyNoMoreInteractions(mockRepository);
  });
}
