import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import 'package:compman_mobile/core/error/failures.dart';
import 'package:compman_mobile/core/platform/xcsoar_saf_service.dart';
import 'package:compman_mobile/features/competitions/domain/usecases/download_and_install_task.dart';

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

  const tTaskUrl = 'https://example.com/task.tsk';
  final tBytes = Uint8List.fromList([0x3C, 0x54, 0x61, 0x73, 0x6B]);

  setUp(() {
    mockRepository = MockCompetitionsRepository();
    recordingSaf = _RecordingSafService();
    provideDummy<Either<Failure, Uint8List>>(Right(Uint8List(0)));
    provideDummy<Either<Failure, Unit>>(const Right(unit));
  });

  test(
    'downloads bytes, writes Default.tsk via SAF, and returns Right(unit)',
    () async {
      when(
        mockRepository.downloadTask(tTaskUrl),
      ).thenAnswer((_) async => Right(tBytes));

      final useCase = DownloadAndInstallTask(mockRepository, recordingSaf);
      final result = await useCase(tTaskUrl);

      expect(result, const Right<Failure, Unit>(unit));
      expect(recordingSaf.calls, hasLength(1));
      expect(recordingSaf.calls.first.$2, 'Default.tsk');
      expect(recordingSaf.calls.first.$1, tBytes);
    },
  );

  test(
    'returns Left(Failure) when download fails without calling writeFile',
    () async {
      const failure = NetworkFailure('connection refused');
      when(
        mockRepository.downloadTask(tTaskUrl),
      ).thenAnswer((_) async => const Left(failure));

      final useCase = DownloadAndInstallTask(mockRepository, recordingSaf);
      final result = await useCase(tTaskUrl);

      expect(result, const Left<Failure, Unit>(failure));
      expect(recordingSaf.calls, isEmpty);
    },
  );

  test('propagates PlatformException from writeFile to the caller', () async {
    when(
      mockRepository.downloadTask(tTaskUrl),
    ).thenAnswer((_) async => Right(tBytes));

    final throwingSaf = _ThrowingSafService(
      PlatformException(code: 'SAF_NOT_CONFIGURED'),
    );
    final useCase = DownloadAndInstallTask(mockRepository, throwingSaf);

    await expectLater(
      () => useCase(tTaskUrl),
      throwsA(isA<PlatformException>()),
    );
  });
}
