import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:compman_mobile/core/platform/xcsoar_saf_service.dart';
import 'package:compman_mobile/features/competitions/domain/usecases/get_todays_flight_logs.dart';

class _FakeSafService extends XcsoarSafService {
  _FakeSafService(this._logs);

  final List<Map<String, String>> _logs;

  @override
  Future<List<Map<String, String>>> listFlightLogs() async => _logs;
}

class _ThrowingSafService extends XcsoarSafService {
  _ThrowingSafService(this._exception);

  final PlatformException _exception;

  @override
  Future<List<Map<String, String>>> listFlightLogs() async {
    throw _exception;
  }
}

void main() {
  DateTime tNow() => DateTime(2018, 2, 26);

  group('GetTodaysFlightLogs', () {
    test('keeps only files matching today\'s date prefix', () async {
      final safService = _FakeSafService([
        {'filename': '2018-02-26-XCS-WUX-01.igc', 'uri': 'content://a'},
        {'filename': '2018-02-25-XCS-WUX-01.igc', 'uri': 'content://b'},
        {'filename': '2018-02-26-XCS-WUX-02.igc', 'uri': 'content://c'},
      ]);
      final useCase = GetTodaysFlightLogs(safService, now: tNow);

      final result = await useCase();

      expect(result, hasLength(2));
      expect(result[0].filename, '2018-02-26-XCS-WUX-01.igc');
      expect(result[1].filename, '2018-02-26-XCS-WUX-02.igc');
    });

    test('excludes entries from other days', () async {
      final safService = _FakeSafService([
        {'filename': '2018-02-25-XCS-WUX-01.igc', 'uri': 'content://a'},
      ]);
      final useCase = GetTodaysFlightLogs(safService, now: tNow);

      final result = await useCase();

      expect(result, isEmpty);
    });

    test('returns empty list for empty input', () async {
      final safService = _FakeSafService([]);
      final useCase = GetTodaysFlightLogs(safService, now: tNow);

      final result = await useCase();

      expect(result, isEmpty);
    });

    test('propagates PlatformException from the SAF service', () async {
      final safService = _ThrowingSafService(
        PlatformException(code: 'SAF_NOT_CONFIGURED'),
      );
      final useCase = GetTodaysFlightLogs(safService, now: tNow);

      expect(() => useCase(), throwsA(isA<PlatformException>()));
    });
  });
}
