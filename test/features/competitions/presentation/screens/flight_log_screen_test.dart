import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:compman_mobile/core/di/providers.dart';
import 'package:compman_mobile/core/error/failures.dart';
import 'package:compman_mobile/core/platform/xcsoar_saf_service.dart';
import 'package:compman_mobile/core/theme/app_theme.dart';
import 'package:compman_mobile/features/competitions/domain/entities/bookmarked_competition.dart';
import 'package:compman_mobile/features/competitions/domain/entities/flight_log_file.dart';
import 'package:compman_mobile/features/competitions/domain/usecases/send_flight_logs.dart';
import 'package:compman_mobile/features/competitions/presentation/providers/competitions_providers.dart';
import 'package:compman_mobile/features/competitions/presentation/screens/flight_log_screen.dart';

import '../../domain/mock_competitions_repository.dart';

// ---------------------------------------------------------------------------
// Test fixtures
// ---------------------------------------------------------------------------

const _competitionId = 'test-comp-2026';

final _tCompetition = BookmarkedCompetition(
  id: _competitionId,
  title: 'Test Open 2026',
  soaringspotUrl: 'https://example.com/test',
  bookmarkedAt: DateTime(2026, 3, 1),
);

const _tFiles = [
  FlightLogFile(
    filename: '2026-07-27-XCS-WUX-01.igc',
    uri: 'content://xcsoar/logs/01.igc',
  ),
  FlightLogFile(
    filename: '2026-07-27-XCS-WUX-02.igc',
    uri: 'content://xcsoar/logs/02.igc',
  ),
];

// ---------------------------------------------------------------------------
// Stub use cases
// ---------------------------------------------------------------------------

class _RecordingSendFlightLogs extends SendFlightLogs {
  _RecordingSendFlightLogs(this._result)
    : super(MockCompetitionsRepository(), _NoOpSafService());

  final Either<Failure, Unit> Function() _result;
  final List<
    ({String competitionId, List<FlightLogFile> files, String recipient})
  >
  calls = [];

  @override
  Future<Either<Failure, Unit>> call({
    required String competitionId,
    required List<FlightLogFile> files,
    required String recipient,
  }) async {
    calls.add((
      competitionId: competitionId,
      files: files,
      recipient: recipient,
    ));
    return _result();
  }
}

class _ThrowingSendFlightLogs extends SendFlightLogs {
  _ThrowingSendFlightLogs(this._exception)
    : super(MockCompetitionsRepository(), _NoOpSafService());

  final PlatformException _exception;

  @override
  Future<Either<Failure, Unit>> call({
    required String competitionId,
    required List<FlightLogFile> files,
    required String recipient,
  }) async {
    throw _exception;
  }
}

/// SAF service that does nothing (unused by the stub use cases above, which
/// override `call` directly).
class _NoOpSafService extends XcsoarSafService {}

// ---------------------------------------------------------------------------
// Helper — builds a testable widget tree
// ---------------------------------------------------------------------------

Widget _buildApp(List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: AppTheme.light(),
      home: const FlightLogScreen(competitionId: _competitionId),
    ),
  );
}

List<Override> _baseOverrides({
  BookmarkedCompetition? competition,
  List<FlightLogFile> files = _tFiles,
  SendFlightLogs? sendFlightLogs,
}) {
  return [
    competitionDetailProvider(
      _competitionId,
    ).overrideWith((ref) async => competition ?? _tCompetition),
    todaysFlightLogsProvider.overrideWith((ref) async => files),
    if (sendFlightLogs != null)
      sendFlightLogsProvider.overrideWithValue(sendFlightLogs),
  ];
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  testWidgets('renders all of today\'s files, pre-checked', (tester) async {
    await tester.pumpWidget(_buildApp(_baseOverrides()));
    await tester.pump();
    await tester.pump();

    expect(find.text('2026-07-27-XCS-WUX-01.igc'), findsOneWidget);
    expect(find.text('2026-07-27-XCS-WUX-02.igc'), findsOneWidget);

    final tiles = tester
        .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
        .toList();
    expect(tiles, hasLength(2));
    expect(tiles.every((t) => t.value == true), isTrue);
  });

  testWidgets('unchecking all files disables Send', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        _baseOverrides(
          competition: _tCompetition.copyWith(scoringEmail: 'a@b.com'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    for (final finder in find.byType(CheckboxListTile).evaluate().toList()) {
      await tester.tap(find.byWidget(finder.widget));
      await tester.pump();
    }

    final sendButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Send'),
    );
    expect(sendButton.onPressed, isNull);
  });

  testWidgets(
    'empty/invalid email disables Send; valid pre-filled email enables it',
    (tester) async {
      await tester.pumpWidget(
        _buildApp(
          _baseOverrides(
            competition: _tCompetition.copyWith(
              scoringEmail: 'organizer@example.com',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      var sendButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Send'),
      );
      expect(sendButton.onPressed, isNotNull);

      await tester.enterText(find.byType(TextFormField), 'not-an-email');
      await tester.pump();

      sendButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Send'),
      );
      expect(sendButton.onPressed, isNull);

      await tester.enterText(find.byType(TextFormField), '');
      await tester.pump();

      sendButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Send'),
      );
      expect(sendButton.onPressed, isNull);
    },
  );

  testWidgets('successful send invalidates competitionDetailProvider', (
    tester,
  ) async {
    final recording = _RecordingSendFlightLogs(() => const Right(unit));
    await tester.pumpWidget(
      _buildApp(
        _baseOverrides(
          competition: _tCompetition.copyWith(
            scoringEmail: 'organizer@example.com',
          ),
          sendFlightLogs: recording,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Send'));
    await tester.pump();
    await tester.pump();

    expect(recording.calls, hasLength(1));
    expect(recording.calls.first.competitionId, _competitionId);
    expect(recording.calls.first.recipient, 'organizer@example.com');
    expect(recording.calls.first.files, _tFiles);
  });

  testWidgets('NO_MAIL_APP failure shows inline error and does not crash', (
    tester,
  ) async {
    final throwing = _ThrowingSendFlightLogs(
      PlatformException(code: 'NO_MAIL_APP'),
    );
    await tester.pumpWidget(
      _buildApp(
        _baseOverrides(
          competition: _tCompetition.copyWith(
            scoringEmail: 'organizer@example.com',
          ),
          sendFlightLogs: throwing,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Send'));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('No email app available to send flight logs.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'zero-files state shows empty sentence and no list/field/button',
    (tester) async {
      await tester.pumpWidget(_buildApp(_baseOverrides(files: const [])));
      await tester.pump();
      await tester.pump();

      expect(find.text('No flight logs found for today.'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Send'), findsNothing);
    },
  );
}
