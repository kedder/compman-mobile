import 'package:flutter_test/flutter_test.dart';

import 'package:compman_mobile/features/competitions/domain/entities/competition_status.dart';

void main() {
  group('CompetitionStatus.of', () {
    test('returns live when now is between start and end dates', () {
      final result = CompetitionStatus.of(
        startDate: DateTime(2026, 3, 21),
        endDate: DateTime(2026, 3, 24),
        now: DateTime(2026, 3, 22, 18),
      );

      expect(result, CompetitionStatus.live);
    });

    test('returns upcoming when now is before the start date', () {
      final result = CompetitionStatus.of(
        startDate: DateTime(2026, 3, 21),
        endDate: DateTime(2026, 3, 24),
        now: DateTime(2026, 3, 20, 23, 59),
      );

      expect(result, CompetitionStatus.upcoming);
    });

    test('returns past when now is after the end date', () {
      final result = CompetitionStatus.of(
        startDate: DateTime(2026, 3, 21),
        endDate: DateTime(2026, 3, 24),
        now: DateTime(2026, 3, 25),
      );

      expect(result, CompetitionStatus.past);
    });

    test('returns null when either date is unavailable', () {
      expect(
        CompetitionStatus.of(
          startDate: null,
          endDate: DateTime(2026, 3, 24),
          now: DateTime(2026, 3, 22),
        ),
        isNull,
      );
      expect(
        CompetitionStatus.of(
          startDate: DateTime(2026, 3, 21),
          endDate: null,
          now: DateTime(2026, 3, 22),
        ),
        isNull,
      );
    });
  });
}
