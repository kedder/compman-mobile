import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import 'package:compman_mobile/core/error/failures.dart';
import 'package:compman_mobile/core/platform/xcsoar_saf_service.dart';
import 'package:compman_mobile/features/competitions/domain/entities/downloadable_file_info.dart';
import 'package:compman_mobile/features/competitions/domain/usecases/download_and_install_file.dart';

import 'mock_competitions_repository.mocks.dart';

// ---------------------------------------------------------------------------
// Manual SAF service mocks
// ---------------------------------------------------------------------------

class _RecordingSafService extends XcsoarSafService {
  final List<(Uint8List, String)> calls = [];

  @override
  Future<void> writeFile(Uint8List bytes, String filename) async {
    calls.add((bytes, filename));
  }
}

class _ThrowingSafService extends XcsoarSafService {
  final PlatformException exception;
  _ThrowingSafService(this.exception);

  @override
  Future<void> writeFile(Uint8List bytes, String filename) async {
    throw exception;
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockCompetitionsRepository mockRepository;
  late _RecordingSafService recordingSaf;

  final tBytes = Uint8List.fromList([0x47, 0x52, 0x49, 0x44]);

  const tAirspaceFile = DownloadableFileInfo(
    filename: 'airspace.txt',
    downloadUrl: 'https://example.com/airspace.txt',
    kind: DownloadableFileKind.airspace,
    publishedVersion: '10/07/2018, 17:44',
  );

  const tWaypointsFile = DownloadableFileInfo(
    filename: 'waypoints.cup',
    downloadUrl: 'https://example.com/waypoints.cup',
    kind: DownloadableFileKind.waypoints,
    publishedVersion: '04/07/2018, 13:22',
  );

  const tCompetitionId = 'wgc2018pl';

  setUp(() {
    mockRepository = MockCompetitionsRepository();
    recordingSaf = _RecordingSafService();
    provideDummy<Either<Failure, Uint8List>>(Right(Uint8List(0)));
    provideDummy<Either<Failure, Unit>>(const Right(unit));
  });

  group('DownloadAndInstallFile — airspace', () {
    test(
      'downloads bytes, writes compman-airspace.txt, records install, returns Right(unit)',
      () async {
        when(
          mockRepository.downloadFile(tAirspaceFile.downloadUrl),
        ).thenAnswer((_) async => Right(tBytes));
        when(
          mockRepository.recordFileInstall(
            tCompetitionId,
            DownloadableFileKind.airspace,
            tAirspaceFile.publishedVersion,
          ),
        ).thenAnswer((_) async => const Right(unit));

        final useCase = DownloadAndInstallFile(mockRepository, recordingSaf);
        final result = await useCase.call(
          competitionId: tCompetitionId,
          fileInfo: tAirspaceFile,
        );

        expect(result, const Right<Failure, Unit>(unit));
        expect(recordingSaf.calls, hasLength(1));
        expect(recordingSaf.calls.first.$2, 'compman-airspace.txt');
        expect(recordingSaf.calls.first.$1, tBytes);
        verify(
          mockRepository.recordFileInstall(
            tCompetitionId,
            DownloadableFileKind.airspace,
            tAirspaceFile.publishedVersion,
          ),
        ).called(1);
      },
    );
  });

  group('DownloadAndInstallFile — waypoints', () {
    test('writes compman-waypoints.cup for waypoints file', () async {
      when(
        mockRepository.downloadFile(tWaypointsFile.downloadUrl),
      ).thenAnswer((_) async => Right(tBytes));
      when(
        mockRepository.recordFileInstall(any, any, any),
      ).thenAnswer((_) async => const Right(unit));

      final useCase = DownloadAndInstallFile(mockRepository, recordingSaf);
      final result = await useCase.call(
        competitionId: tCompetitionId,
        fileInfo: tWaypointsFile,
      );

      expect(result, const Right<Failure, Unit>(unit));
      expect(recordingSaf.calls.first.$2, 'compman-waypoints.cup');
      verify(
        mockRepository.recordFileInstall(
          tCompetitionId,
          DownloadableFileKind.waypoints,
          tWaypointsFile.publishedVersion,
        ),
      ).called(1);
    });
  });

  group('DownloadAndInstallFile — failure cases', () {
    test('returns Left(NetworkFailure) when downloadFile fails', () async {
      const failure = NetworkFailure('connection refused');
      when(
        mockRepository.downloadFile(tAirspaceFile.downloadUrl),
      ).thenAnswer((_) async => const Left(failure));

      final useCase = DownloadAndInstallFile(mockRepository, recordingSaf);
      final result = await useCase.call(
        competitionId: tCompetitionId,
        fileInfo: tAirspaceFile,
      );

      expect(result, const Left<Failure, Unit>(failure));
      expect(recordingSaf.calls, isEmpty);
      verifyNever(mockRepository.recordFileInstall(any, any, any));
    });

    test('propagates PlatformException from writeFile to the caller', () async {
      when(
        mockRepository.downloadFile(tAirspaceFile.downloadUrl),
      ).thenAnswer((_) async => Right(tBytes));

      final throwingSaf = _ThrowingSafService(
        PlatformException(code: 'SAF_NOT_CONFIGURED'),
      );
      final useCase = DownloadAndInstallFile(mockRepository, throwingSaf);

      expect(
        () => useCase.call(
          competitionId: tCompetitionId,
          fileInfo: tAirspaceFile,
        ),
        throwsA(isA<PlatformException>()),
      );
      verifyNever(mockRepository.recordFileInstall(any, any, any));
    });
  });
}
