import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import 'package:compman_mobile/core/error/failures.dart';
import 'package:compman_mobile/core/platform/xcsoar_saf_service.dart';
import 'package:compman_mobile/features/competitions/domain/entities/flight_log_file.dart';
import 'package:compman_mobile/features/competitions/domain/usecases/send_flight_logs.dart';

import 'mock_competitions_repository.mocks.dart';

// ---------------------------------------------------------------------------
// Manual SAF service mocks
// ---------------------------------------------------------------------------

class _RecordingSafService extends XcsoarSafService {
  final List<({List<String> uris, String recipient})> calls = [];

  @override
  Future<void> shareFlightLogs({
    required List<String> uris,
    required String recipient,
  }) async {
    calls.add((uris: uris, recipient: recipient));
  }
}

class _ThrowingSafService extends XcsoarSafService {
  _ThrowingSafService(this.exception);

  final PlatformException exception;

  @override
  Future<void> shareFlightLogs({
    required List<String> uris,
    required String recipient,
  }) async {
    throw exception;
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockCompetitionsRepository mockRepository;
  late _RecordingSafService recordingSaf;

  const tCompetitionId = 'wgc2018pl';
  const tRecipient = 'organizer@example.com';
  const tFiles = [
    FlightLogFile(
      filename: '2018-02-26-XCS-WUX-01.igc',
      uri: 'content://xcsoar/logs/01.igc',
    ),
    FlightLogFile(
      filename: '2018-02-26-XCS-WUX-02.igc',
      uri: 'content://xcsoar/logs/02.igc',
    ),
  ];

  setUp(() {
    mockRepository = MockCompetitionsRepository();
    recordingSaf = _RecordingSafService();
    provideDummy<Either<Failure, Unit>>(const Right(unit));
  });

  test(
    'calls shareFlightLogs then setCompetitionScoringEmail, returns Right(unit)',
    () async {
      when(
        mockRepository.setCompetitionScoringEmail(tCompetitionId, tRecipient),
      ).thenAnswer((_) async => const Right(unit));

      final useCase = SendFlightLogs(mockRepository, recordingSaf);
      final result = await useCase.call(
        competitionId: tCompetitionId,
        files: tFiles,
        recipient: tRecipient,
      );

      expect(result, const Right<Failure, Unit>(unit));
      expect(recordingSaf.calls, hasLength(1));
      expect(recordingSaf.calls.first.recipient, tRecipient);
      expect(recordingSaf.calls.first.uris, [
        'content://xcsoar/logs/01.igc',
        'content://xcsoar/logs/02.igc',
      ]);
      verify(
        mockRepository.setCompetitionScoringEmail(tCompetitionId, tRecipient),
      ).called(1);
    },
  );

  test('propagates PlatformException from shareFlightLogs and does not call '
      'setCompetitionScoringEmail', () async {
    final throwingSaf = _ThrowingSafService(
      PlatformException(code: 'NO_MAIL_APP'),
    );
    final useCase = SendFlightLogs(mockRepository, throwingSaf);

    expect(
      () => useCase.call(
        competitionId: tCompetitionId,
        files: tFiles,
        recipient: tRecipient,
      ),
      throwsA(isA<PlatformException>()),
    );
    verifyNever(mockRepository.setCompetitionScoringEmail(any, any));
  });

  test('propagates Left(Failure) from setCompetitionScoringEmail', () async {
    const failure = StorageFailure('disk full');
    when(
      mockRepository.setCompetitionScoringEmail(tCompetitionId, tRecipient),
    ).thenAnswer((_) async => const Left(failure));

    final useCase = SendFlightLogs(mockRepository, recordingSaf);
    final result = await useCase.call(
      competitionId: tCompetitionId,
      files: tFiles,
      recipient: tRecipient,
    );

    expect(result, const Left<Failure, Unit>(failure));
  });
}
