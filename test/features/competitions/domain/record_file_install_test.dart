import 'package:compman_mobile/core/error/failures.dart';
import 'package:compman_mobile/features/competitions/domain/entities/downloadable_file_info.dart';
import 'package:compman_mobile/features/competitions/domain/usecases/record_file_install.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import 'mock_competitions_repository.mocks.dart';

void main() {
  late MockCompetitionsRepository mockRepository;
  late RecordFileInstall useCase;

  setUp(() {
    mockRepository = MockCompetitionsRepository();
    useCase = RecordFileInstall(mockRepository);
    provideDummy<Either<Failure, Unit>>(const Right(unit));
  });

  const tCompetitionId = 'wgc2018pl';
  const tVersion = '10/07/2018, 17:44';

  test('delegates to repository.recordFileInstall for airspace', () async {
    when(
      mockRepository.recordFileInstall(
        tCompetitionId,
        DownloadableFileKind.airspace,
        tVersion,
      ),
    ).thenAnswer((_) async => const Right(unit));

    final result = await useCase(
      tCompetitionId,
      DownloadableFileKind.airspace,
      tVersion,
    );

    expect(result, const Right(unit));
    verify(
      mockRepository.recordFileInstall(
        tCompetitionId,
        DownloadableFileKind.airspace,
        tVersion,
      ),
    );
    verifyNoMoreInteractions(mockRepository);
  });

  test('delegates to repository.recordFileInstall for waypoints', () async {
    when(
      mockRepository.recordFileInstall(
        tCompetitionId,
        DownloadableFileKind.waypoints,
        tVersion,
      ),
    ).thenAnswer((_) async => const Right(unit));

    final result = await useCase(
      tCompetitionId,
      DownloadableFileKind.waypoints,
      tVersion,
    );

    expect(result, const Right(unit));
    verify(
      mockRepository.recordFileInstall(
        tCompetitionId,
        DownloadableFileKind.waypoints,
        tVersion,
      ),
    );
    verifyNoMoreInteractions(mockRepository);
  });

  test('propagates Left as-is', () async {
    const failure = Failure.storage('Competition not found');
    when(
      mockRepository.recordFileInstall(any, any, any),
    ).thenAnswer((_) async => const Left(failure));

    final result = await useCase(
      tCompetitionId,
      DownloadableFileKind.airspace,
      tVersion,
    );

    expect(result, const Left(failure));
  });
}
