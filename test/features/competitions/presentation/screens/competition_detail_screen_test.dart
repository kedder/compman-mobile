import 'dart:async';

import 'package:compman_mobile/core/di/providers.dart';
import 'package:compman_mobile/core/error/failures.dart';
import 'package:compman_mobile/core/platform/xcsoar_saf_service.dart';
import 'package:compman_mobile/core/theme/app_theme.dart';
import 'package:compman_mobile/features/competitions/domain/entities/bookmarked_competition.dart';
import 'package:compman_mobile/features/competitions/domain/entities/downloadable_file_info.dart';
import 'package:compman_mobile/features/competitions/domain/entities/flight_log_file.dart';
import 'package:compman_mobile/features/competitions/domain/entities/task_info.dart';
import 'package:compman_mobile/features/competitions/domain/usecases/download_and_install_file.dart';
import 'package:compman_mobile/features/competitions/domain/usecases/download_and_install_task.dart';
import 'package:compman_mobile/features/competitions/domain/usecases/set_competition_class.dart';
import 'package:compman_mobile/features/competitions/presentation/providers/competitions_providers.dart';
import 'package:compman_mobile/features/competitions/presentation/screens/competition_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../../domain/mock_competitions_repository.dart';

// ---------------------------------------------------------------------------
// In-memory Box<String> fake — avoids Hive platform channels and FakeAsync
// timer deadlocks inside testWidgets bodies.
// ---------------------------------------------------------------------------

class _FakeStringBox extends Fake implements Box<String> {
  final Map<String, String> store = {};

  @override
  Future<void> put(dynamic key, String value) async {
    store[key as String] = value;
  }
}

// ---------------------------------------------------------------------------
// Test fixtures
// ---------------------------------------------------------------------------

const _competitionId = 'test-comp-2026';

final _tCompetition = BookmarkedCompetition(
  id: _competitionId,
  title: 'Test Open 2026',
  soaringspotUrl: 'https://example.com/test',
  bookmarkedAt: DateTime(2026, 3, 1),
  selectedClass: null,
  startDate: DateTime(2026, 3, 1),
  endDate: DateTime(2026, 3, 7),
);

const _clubTask = TaskInfo(
  compClass: 'Club',
  title: '500km Triangle',
  dayNo: 4,
  taskNo: 1,
  timestamp: '2026-07-14 09:30',
  taskUrl: 'https://example.com/task.tsk',
);

final _selectedClassCompetition = _tCompetition.copyWith(
  selectedClass: 'Club',
  taskVersion: _clubTask.timestamp,
);

// ---------------------------------------------------------------------------
// Helper — builds a testable widget tree
// ---------------------------------------------------------------------------

Widget _buildApp(List<Override> overrides) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) =>
            const CompetitionDetailScreen(competitionId: _competitionId),
      ),
      GoRoute(
        path: '/settings/xcsoar-directory',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('XCSoar dir settings')),
          body: Text('kind=${state.uri.queryParameters['kind'] ?? ''}'),
        ),
      ),
      GoRoute(
        path: '/competitions/:id/flight-logs',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Flight Logs')),
          body: Text('flight-logs-for=${state.pathParameters['id']}'),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(routerConfig: router, theme: AppTheme.light()),
  );
}

/// Returns the base overrides needed for every test: competition detail,
/// xcsoar dir, latest tasks, and downloads.
List<Override> _baseOverrides({
  required List<String> classes,
  BookmarkedCompetition? competition,
  List<TaskInfo> tasks = const <TaskInfo>[],
  List<DownloadableFileInfo> downloads = const <DownloadableFileInfo>[],
  String? xcsoarDirectoryUri,
  List<FlightLogFile> flightLogs = const <FlightLogFile>[],
  Object? flightLogsError,
  void Function()? onFlightLogsFetch,
}) {
  final resolvedCompetition = competition ?? _tCompetition;

  return [
    competitionDetailProvider(
      _competitionId,
    ).overrideWith((ref) async => resolvedCompetition),
    competitionClassesProvider(
      _competitionId,
    ).overrideWith((ref) async => classes),
    xcsoarDirectoryUriProvider.overrideWith((ref) async => xcsoarDirectoryUri),
    latestTasksProvider(_competitionId).overrideWith((ref) async => tasks),
    downloadsProvider(_competitionId).overrideWith((ref) async => downloads),
    todaysFlightLogsProvider.overrideWith((ref) async {
      onFlightLogsFetch?.call();
      if (flightLogsError != null) throw flightLogsError;
      return flightLogs;
    }),
  ];
}

/// Use case stub that resolves after the given future completes — used to
/// pause mid-download so the button disabled state can be asserted.
class _CompleterDownloadAndInstallFile extends DownloadAndInstallFile {
  _CompleterDownloadAndInstallFile(this._future)
    : super(MockCompetitionsRepository(), _NoOpSafService());

  final Future<Either<Failure, String>> _future;

  @override
  Future<Either<Failure, String>> call({
    required String competitionId,
    required DownloadableFileInfo fileInfo,
  }) => _future;
}

class _ThrowingSafDownloadAndInstallFile extends DownloadAndInstallFile {
  _ThrowingSafDownloadAndInstallFile(this._exception)
    : super(MockCompetitionsRepository(), _NoOpSafService());

  final PlatformException _exception;

  @override
  Future<Either<Failure, String>> call({
    required String competitionId,
    required DownloadableFileInfo fileInfo,
  }) async {
    throw _exception;
  }
}

/// SAF service that does nothing (for stub use cases that bypass real logic).
class _NoOpSafService extends XcsoarSafService {
  @override
  Future<void> writeFile(Uint8List bytes, String filename) async {}
}

/// SAF service whose [launchPackage] always throws [_exception].
class _ThrowingLaunchSafService extends XcsoarSafService {
  _ThrowingLaunchSafService(this._exception);

  final PlatformException _exception;

  @override
  Future<void> launchPackage(String packageId) async => throw _exception;
}

/// [DownloadAndInstallTask] that throws [PlatformException].
class _ThrowingSafDownloadAndInstallTask extends DownloadAndInstallTask {
  _ThrowingSafDownloadAndInstallTask(this._exception)
    : super(MockCompetitionsRepository(), _NoOpSafService());

  final PlatformException _exception;

  @override
  Future<Either<Failure, Unit>> call({
    required String competitionId,
    required String taskUrl,
    required String version,
  }) async => throw _exception;
}

/// [DownloadAndInstallTask] that returns [Left(Failure)].
class _FailingDownloadAndInstallTask extends DownloadAndInstallTask {
  _FailingDownloadAndInstallTask(this._failure)
    : super(MockCompetitionsRepository(), _NoOpSafService());

  final Failure _failure;

  @override
  Future<Either<Failure, Unit>> call({
    required String competitionId,
    required String taskUrl,
    required String version,
  }) async => Left(_failure);
}

class _RecordingSetCompetitionClass extends SetCompetitionClass {
  _RecordingSetCompetitionClass(this.onCall)
    : super(MockCompetitionsRepository());

  final void Function(String competitionId, String? selectedClass) onCall;

  @override
  Future<Either<Failure, Unit>> call(
    String competitionId,
    String? selectedClass,
  ) async {
    onCall(competitionId, selectedClass);
    return right(unit);
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  testWidgets('shows class cards with heading and chevrons when classes load', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(_baseOverrides(classes: ['Standard', 'Club'])),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Select your class'), findsOneWidget);
    expect(find.text('Standard'), findsOneWidget);
    expect(find.text('Club'), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events_outlined), findsNWidgets(2));
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
  });

  testWidgets('tapping a class card calls the class-selection action', (
    tester,
  ) async {
    String? tappedCompetitionId;
    String? tappedClass;

    await tester.pumpWidget(
      _buildApp([
        ..._baseOverrides(classes: ['Standard', 'Club']),
        setCompetitionClassProvider.overrideWith(
          (ref) =>
              _RecordingSetCompetitionClass((competitionId, selectedClass) {
                tappedCompetitionId = competitionId;
                tappedClass = selectedClass;
              }),
        ),
      ]),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Club'));
    await tester.pump();

    expect(tappedCompetitionId, _competitionId);
    expect(tappedClass, 'Club');
  });

  testWidgets(
    'shows "No classes found" message when competitionClassesProvider returns empty list',
    (tester) async {
      await tester.pumpWidget(_buildApp(_baseOverrides(classes: [])));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('No classes found'), findsOneWidget);
    },
  );

  testWidgets('shows error and Retry when competitionClassesProvider throws', (
    tester,
  ) async {
    final overrides = [
      competitionDetailProvider(
        _competitionId,
      ).overrideWith((ref) async => _tCompetition),
      competitionClassesProvider(_competitionId).overrideWith(
        (ref) =>
            Future<List<String>>.error(const NetworkFailure('Network error')),
      ),
      xcsoarDirectoryUriProvider.overrideWith((ref) async => null),
      latestTasksProvider(
        _competitionId,
      ).overrideWith((ref) async => <TaskInfo>[]),
      downloadsProvider(
        _competitionId,
      ).overrideWith((ref) async => <DownloadableFileInfo>[]),
      todaysFlightLogsProvider.overrideWith((ref) async => <FlightLogFile>[]),
    ];

    await tester.pumpWidget(_buildApp(overrides));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('No classes found'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('shows the competition title with headlineLarge styling', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        _baseOverrides(
          classes: const ['Club'],
          competition: _selectedClassCompetition,
          tasks: const [_clubTask],
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final title = tester.widget<Text>(find.text('Test Open 2026'));
    expect(title.style?.fontSize, 32);
    expect(title.style?.fontWeight, FontWeight.bold);
    expect(title.style?.color, AppTheme.light().colorScheme.onSurface);
  });

  testWidgets('shows inline class selector row when a class is selected', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        _baseOverrides(
          classes: const ['Club'],
          competition: _selectedClassCompetition,
          tasks: const [_clubTask],
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Class: '), findsOneWidget);
    expect(find.text('Club'), findsOneWidget);
    expect(find.text('Change'), findsOneWidget);
  });

  testWidgets('renders the task card without a new-update badge', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        _baseOverrides(
          classes: const ['Club'],
          competition: _selectedClassCompetition,
          tasks: const [_clubTask],
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Day 4 - Task 1'), findsOneWidget);
    expect(find.text('Download task'), findsOneWidget);
    expect(find.text('NEW UPDATE'), findsNothing);
  });

  testWidgets('shows NEW UPDATE badge on task card when never downloaded', (
    tester,
  ) async {
    // taskVersion is null → user has never downloaded a task.
    final competition = _tCompetition.copyWith(selectedClass: 'Club');
    await tester.pumpWidget(
      _buildApp(
        _baseOverrides(
          classes: const ['Club'],
          competition: competition,
          tasks: const [_clubTask],
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('NEW UPDATE'), findsOneWidget);
  });

  testWidgets(
    'shows NEW UPDATE badge on task card when a newer task is published',
    (tester) async {
      final competition = _tCompetition.copyWith(
        selectedClass: 'Club',
        taskVersion: 'stale-version',
      );
      await tester.pumpWidget(
        _buildApp(
          _baseOverrides(
            classes: const ['Club'],
            competition: competition,
            tasks: const [_clubTask],
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('NEW UPDATE'), findsOneWidget);
    },
  );

  testWidgets('appends a dismissible error banner when task download fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp([
        ..._baseOverrides(
          classes: const ['Club'],
          competition: _selectedClassCompetition,
          tasks: const [_clubTask],
        ),
        downloadAndInstallTaskProvider.overrideWithValue(
          _FailingDownloadAndInstallTask(
            const NetworkFailure('Task download failed'),
          ),
        ),
      ]),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Download task'));
    await tester.pumpAndSettle();

    expect(find.text('Task download failed'), findsOneWidget);
    expect(find.byTooltip('Dismiss error'), findsOneWidget);
  });

  testWidgets('dismissing an error banner removes it from the screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp([
        ..._baseOverrides(
          classes: const ['Club'],
          competition: _selectedClassCompetition,
          tasks: const [_clubTask],
        ),
        downloadAndInstallTaskProvider.overrideWithValue(
          _FailingDownloadAndInstallTask(
            const NetworkFailure('Task download failed'),
          ),
        ),
      ]),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Download task'));
    await tester.pumpAndSettle();
    expect(find.text('Task download failed'), findsOneWidget);

    await tester.tap(find.byTooltip('Dismiss error'));
    await tester.pumpAndSettle();

    expect(find.text('Task download failed'), findsNothing);
  });

  // ---------------------------------------------------------------------------
  // Airspace & Waypoints card tests
  // ---------------------------------------------------------------------------

  const tAirspaceFile = DownloadableFileInfo(
    filename: 'airspace_2026.txt',
    downloadUrl: 'https://example.com/airspace.txt',
    kind: DownloadableFileKind.airspace,
    fileSize: 154000,
    publishedVersion: '10/07/2026, 17:44',
  );

  const tWaypointsFile = DownloadableFileInfo(
    filename: 'waypoints_2026.cup',
    downloadUrl: 'https://example.com/waypoints.cup',
    kind: DownloadableFileKind.waypoints,
    fileSize: 48000,
    publishedVersion: '04/07/2026, 13:22',
  );

  testWidgets('renders airspace card with filename and Download button', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        _baseOverrides(
          classes: const [],
          competition: _selectedClassCompetition,
          downloads: const [tAirspaceFile],
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Airspace'), findsOneWidget);
    expect(find.text('airspace_2026.txt'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);
  });

  testWidgets('renders waypoints card with filename and Download button', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        _baseOverrides(
          classes: const [],
          competition: _selectedClassCompetition,
          downloads: const [tWaypointsFile],
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Waypoints'), findsOneWidget);
    expect(find.text('waypoints_2026.cup'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);
  });

  testWidgets(
    'shows NEW UPDATE badge when publishedVersion differs from installedVersion',
    (tester) async {
      final competition = _tCompetition.copyWith(
        selectedClass: 'Club',
        airspaceVersion: 'old-version',
      );
      await tester.pumpWidget(
        _buildApp(
          _baseOverrides(
            classes: const [],
            competition: competition,
            downloads: const [tAirspaceFile],
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('NEW UPDATE'), findsOneWidget);
    },
  );

  testWidgets(
    'shows NEW UPDATE badge when competition is freshly bookmarked (no file installed yet)',
    (tester) async {
      // airspaceVersion is null → user has never installed the file
      await tester.pumpWidget(
        _buildApp(
          _baseOverrides(
            classes: const [],
            // airspaceVersion is null; selectedClass set so the card renders
            competition: _tCompetition.copyWith(selectedClass: 'Club'),
            downloads: const [tAirspaceFile], // has a publishedVersion
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('NEW UPDATE'), findsOneWidget);
    },
  );

  testWidgets('hides NEW UPDATE badge when already up to date', (tester) async {
    final competition = _tCompetition.copyWith(
      selectedClass: 'Club',
      airspaceVersion: tAirspaceFile.publishedVersion,
    );
    await tester.pumpWidget(
      _buildApp(
        _baseOverrides(
          classes: const [],
          competition: competition,
          downloads: const [tAirspaceFile],
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('NEW UPDATE'), findsNothing);
  });

  testWidgets(
    'shows "No airspace file available" when downloads list has no airspace entry',
    (tester) async {
      await tester.pumpWidget(
        _buildApp(
          _baseOverrides(
            classes: const [],
            competition: _selectedClassCompetition,
            downloads: const [],
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('No airspace file available'), findsOneWidget);
      expect(find.text('No waypoint file available'), findsOneWidget);
    },
  );

  testWidgets('hides Airspace and Waypoints cards when no class is selected', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        _baseOverrides(
          classes: const [],
          downloads: const [tAirspaceFile, tWaypointsFile],
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Airspace'), findsNothing);
    expect(find.text('Waypoints'), findsNothing);
    expect(find.text('No airspace file available'), findsNothing);
    expect(find.text('No waypoint file available'), findsNothing);
    expect(find.byType(Divider), findsOneWidget);
    expect(find.text('XCSoar folder not configured'), findsOneWidget);
  });

  testWidgets('shows Airspace and Waypoints cards once a class is selected', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        _baseOverrides(
          classes: const [],
          competition: _selectedClassCompetition,
          downloads: const [tAirspaceFile, tWaypointsFile],
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Airspace'), findsOneWidget);
    expect(find.text('Waypoints'), findsOneWidget);
  });

  testWidgets('Download button is disabled while downloading', (tester) async {
    final completer = Completer<Either<Failure, String>>();

    final stubbedUseCase = _CompleterDownloadAndInstallFile(completer.future);
    await tester.pumpWidget(
      _buildApp([
        ..._baseOverrides(
          classes: const [],
          competition: _selectedClassCompetition,
          downloads: const [tAirspaceFile],
        ),
        downloadAndInstallFileProvider.overrideWithValue(stubbedUseCase),
      ]),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Download'));
    await tester.pump();

    expect(find.text('Downloading...'), findsOneWidget);
    final button = tester.widget<OutlinedButton>(
      find
          .ancestor(
            of: find.text('Downloading...'),
            matching: find.byType(OutlinedButton),
          )
          .first,
    );
    expect(button.onPressed, isNull);

    completer.complete(const Right('compman-airspace.txt'));
    await tester.pumpAndSettle();
  });

  testWidgets('shows on-device filename in airspace download confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp([
        ..._baseOverrides(
          classes: const [],
          competition: _selectedClassCompetition,
          downloads: const [tAirspaceFile],
        ),
        downloadAndInstallFileProvider.overrideWithValue(
          _CompleterDownloadAndInstallFile(
            Future.value(const Right('compman-airspace.txt')),
          ),
        ),
      ]),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();

    expect(
      find.text('Airspace downloaded as compman-airspace.txt'),
      findsOneWidget,
    );
  });

  testWidgets('shows on-device filename in waypoints download confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp([
        ..._baseOverrides(
          classes: const [],
          competition: _selectedClassCompetition,
          downloads: const [tWaypointsFile],
        ),
        downloadAndInstallFileProvider.overrideWithValue(
          _CompleterDownloadAndInstallFile(
            Future.value(const Right('compman-waypoints.cup')),
          ),
        ),
      ]),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();

    expect(
      find.text('Waypoints downloaded as compman-waypoints.cup'),
      findsOneWidget,
    );
  });

  testWidgets('SAF_NOT_CONFIGURED on airspace download navigates to settings', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp([
        ..._baseOverrides(
          classes: const [],
          competition: _selectedClassCompetition,
          downloads: const [tAirspaceFile],
        ),
        downloadAndInstallFileProvider.overrideWithValue(
          _ThrowingSafDownloadAndInstallFile(
            PlatformException(code: 'SAF_NOT_CONFIGURED'),
          ),
        ),
      ]),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();

    expect(find.text('kind=airspace'), findsOneWidget);
    expect(
      find.textContaining('XCSoar directory not configured'),
      findsNothing,
    );
  });

  testWidgets(
    'SAF_NOT_CONFIGURED on waypoints download navigates to settings',
    (tester) async {
      await tester.pumpWidget(
        _buildApp([
          ..._baseOverrides(
            classes: const [],
            competition: _selectedClassCompetition,
            downloads: const [tWaypointsFile],
          ),
          downloadAndInstallFileProvider.overrideWithValue(
            _ThrowingSafDownloadAndInstallFile(
              PlatformException(code: 'SAF_NOT_CONFIGURED'),
            ),
          ),
        ]),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Download'));
      await tester.pumpAndSettle();

      expect(find.text('kind=waypoints'), findsOneWidget);
    },
  );

  testWidgets('SAF_NOT_CONFIGURED on task download navigates to settings', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp([
        ..._baseOverrides(
          classes: const ['Club'],
          competition: _selectedClassCompetition,
          tasks: const [_clubTask],
        ),
        downloadAndInstallTaskProvider.overrideWithValue(
          _ThrowingSafDownloadAndInstallTask(
            PlatformException(code: 'SAF_NOT_CONFIGURED'),
          ),
        ),
      ]),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Download task'));
    await tester.pumpAndSettle();

    expect(find.text('kind=task'), findsOneWidget);
    expect(
      find.textContaining('XCSoar directory not configured'),
      findsNothing,
    );
  });

  testWidgets('aborting settings navigation shows cancellation error banner', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp([
        ..._baseOverrides(
          classes: const [],
          competition: _selectedClassCompetition,
          downloads: const [tAirspaceFile],
        ),
        downloadAndInstallFileProvider.overrideWithValue(
          _ThrowingSafDownloadAndInstallFile(
            PlatformException(code: 'SAF_NOT_CONFIGURED'),
          ),
        ),
      ]),
    );
    await tester.pump();
    await tester.pump();

    // Navigate to settings screen.
    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();
    expect(find.text('kind=airspace'), findsOneWidget);

    // Go back without configuring (xcsoarDirectoryUri stays null).
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.textContaining('setup was cancelled'), findsOneWidget);
  });

  testWidgets(
    'initState writes competitionId to settings box via settingsBoxProvider',
    (tester) async {
      final fakeBox = _FakeStringBox();

      await tester.pumpWidget(
        _buildApp([
          ..._baseOverrides(classes: const []),
          settingsBoxProvider.overrideWithValue(AsyncData(fakeBox)),
        ]),
      );
      await tester.pump(); // let initState run

      expect(fakeBox.store['lastViewedCompetitionId'], _competitionId);
    },
  );

  // ---------------------------------------------------------------------------
  // Fly XCSoar button tests
  // ---------------------------------------------------------------------------

  testWidgets('Fly button is hidden before a task has been downloaded', (
    tester,
  ) async {
    final competition = _tCompetition.copyWith(selectedClass: 'Club');
    await tester.pumpWidget(
      _buildApp(
        _baseOverrides(
          classes: const ['Club'],
          competition: competition,
          tasks: const [_clubTask],
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byIcon(Icons.flight), findsNothing);
    expect(find.textContaining('Fly'), findsNothing);
  });

  testWidgets('Fly button hides again when a newer task version is published', (
    tester,
  ) async {
    final competition = _tCompetition.copyWith(
      selectedClass: 'Club',
      taskVersion: 'stale-version',
    );
    await tester.pumpWidget(
      _buildApp(
        _baseOverrides(
          classes: const ['Club'],
          competition: competition,
          tasks: const [_clubTask],
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byIcon(Icons.flight), findsNothing);
  });

  testWidgets(
    'Fly button is enabled and labelled with the active flavor once resolved',
    (tester) async {
      await tester.pumpWidget(
        _buildApp([
          ..._baseOverrides(
            classes: const ['Club'],
            competition: _selectedClassCompetition,
            tasks: const [_clubTask],
            xcsoarDirectoryUri: 'content://tree/some-uri',
          ),
          activeFlavorPackageIdProvider.overrideWith(
            (ref) async => 'org.xcsoar.play',
          ),
        ]),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('Fly XCSoar Play'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(
        find
            .ancestor(
              of: find.text('Fly XCSoar Play'),
              matching: find.byType(ElevatedButton),
            )
            .first,
      );
      expect(button.onPressed, isNotNull);
    },
  );

  testWidgets(
    'Fly button is disabled with "Set up XCSoar folder first" when no SAF directory is configured',
    (tester) async {
      await tester.pumpWidget(
        _buildApp([
          ..._baseOverrides(
            classes: const ['Club'],
            competition: _selectedClassCompetition,
            tasks: const [_clubTask],
          ),
          activeFlavorPackageIdProvider.overrideWith((ref) async => null),
        ]),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('Fly XCSoar'), findsOneWidget);
      expect(find.text('Set up XCSoar folder first.'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(
        find
            .ancestor(
              of: find.text('Fly XCSoar'),
              matching: find.byType(ElevatedButton),
            )
            .first,
      );
      expect(button.onPressed, isNull);
    },
  );

  testWidgets(
    'Fly button is disabled with "XCSoar is not installed" when SAF is configured but no flavor resolves',
    (tester) async {
      await tester.pumpWidget(
        _buildApp([
          ..._baseOverrides(
            classes: const ['Club'],
            competition: _selectedClassCompetition,
            tasks: const [_clubTask],
            xcsoarDirectoryUri: 'content://tree/some-uri',
          ),
          activeFlavorPackageIdProvider.overrideWith((ref) async => null),
        ]),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('Fly XCSoar'), findsOneWidget);
      expect(find.text('XCSoar is not installed.'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(
        find
            .ancestor(
              of: find.text('Fly XCSoar'),
              matching: find.byType(ElevatedButton),
            )
            .first,
      );
      expect(button.onPressed, isNull);
    },
  );

  testWidgets(
    'tapping the Fly button shows a dismissible error banner on PlatformException',
    (tester) async {
      await tester.pumpWidget(
        _buildApp([
          ..._baseOverrides(
            classes: const ['Club'],
            competition: _selectedClassCompetition,
            tasks: const [_clubTask],
            xcsoarDirectoryUri: 'content://tree/some-uri',
          ),
          activeFlavorPackageIdProvider.overrideWith(
            (ref) async => 'org.xcsoar',
          ),
          xcsoarSafServiceProvider.overrideWithValue(
            _ThrowingLaunchSafService(PlatformException(code: 'LAUNCH_FAILED')),
          ),
        ]),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Fly XCSoar'));
      await tester.pumpAndSettle();

      expect(
        find.text('Could not launch XCSoar. Is it installed?'),
        findsOneWidget,
      );
      expect(find.byTooltip('Dismiss error'), findsOneWidget);
    },
  );

  // ---------------------------------------------------------------------------
  // Flight Logs panel tests
  //
  // The panel lives inside the Task card footer (below the Fly button), so
  // it only renders once a class is selected and that class's task has
  // loaded — see _baseOverrides(classes: ['Club'], competition:
  // _selectedClassCompetition, tasks: [_clubTask]) below.
  // ---------------------------------------------------------------------------

  const tFlightLog1 = FlightLogFile(
    filename: '2026-07-28-XCS-WUX-01.igc',
    uri: 'content://tree/logs%2F2026-07-28-XCS-WUX-01.igc',
  );

  const tFlightLog2 = FlightLogFile(
    filename: '2026-07-28-XCS-WUX-02.igc',
    uri: 'content://tree/logs%2F2026-07-28-XCS-WUX-02.igc',
  );

  /// Base overrides for a competition with a selected class and loaded task,
  /// so the Task card (and the [FlightLogsPanel] embedded in its footer)
  /// renders.
  List<Override> baseOverridesWithTask({
    List<FlightLogFile> flightLogs = const <FlightLogFile>[],
    Object? flightLogsError,
    void Function()? onFlightLogsFetch,
  }) => _baseOverrides(
    classes: const ['Club'],
    competition: _selectedClassCompetition,
    tasks: const [_clubTask],
    flightLogs: flightLogs,
    flightLogsError: flightLogsError,
    onFlightLogsFetch: onFlightLogsFetch,
  );

  testWidgets('shows singular text for a single flight log', (tester) async {
    await tester.pumpWidget(
      _buildApp(baseOverridesWithTask(flightLogs: const [tFlightLog1])),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('1 flight log recorded'), findsOneWidget);
    expect(find.text('Email flight logs'), findsOneWidget);
  });

  testWidgets('shows plural text for multiple flight logs', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        baseOverridesWithTask(flightLogs: const [tFlightLog1, tFlightLog2]),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('2 flight logs recorded'), findsOneWidget);
  });

  testWidgets(
    'shows muted empty-state text and no Email button for zero flight logs',
    (tester) async {
      await tester.pumpWidget(_buildApp(baseOverridesWithTask()));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('No flight logs recorded today'), findsOneWidget);
      expect(find.text('Email flight logs'), findsNothing);
    },
  );

  testWidgets(
    'shows muted empty-state text (no error banner) when todaysFlightLogsProvider throws',
    (tester) async {
      await tester.pumpWidget(
        _buildApp(
          baseOverridesWithTask(
            flightLogsError: PlatformException(code: 'SAF_NOT_CONFIGURED'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('No flight logs recorded today'), findsOneWidget);
      expect(find.text('Email flight logs'), findsNothing);
      expect(find.byTooltip('Dismiss error'), findsNothing);
    },
  );

  testWidgets('tapping Email navigates to the Flight Log screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(baseOverridesWithTask(flightLogs: const [tFlightLog1])),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Email flight logs'));
    await tester.pumpAndSettle();

    expect(find.text('flight-logs-for=$_competitionId'), findsOneWidget);
  });

  testWidgets('Flight log summary is hidden before a class is selected', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        _baseOverrides(
          classes: const [],
          competition: _tCompetition,
          flightLogs: const [tFlightLog1],
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('1 flight log recorded'), findsNothing);
  });

  /// [baseOverridesWithTask] overrides, counting [todaysFlightLogsProvider]
  /// fetches via [onCall].
  List<Override> overridesCountingFlightLogsCalls(void Function() onCall) =>
      baseOverridesWithTask(onFlightLogsFetch: onCall);

  testWidgets('pull-to-refresh invalidates todaysFlightLogsProvider', (
    tester,
  ) async {
    var callCount = 0;
    await tester.pumpWidget(
      _buildApp(overridesCountingFlightLogsCalls(() => callCount++)),
    );
    await tester.pump();
    await tester.pump();
    expect(callCount, 1);

    await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    expect(callCount, 2);
  });

  testWidgets('app resume invalidates todaysFlightLogsProvider', (
    tester,
  ) async {
    var callCount = 0;
    await tester.pumpWidget(
      _buildApp(overridesCountingFlightLogsCalls(() => callCount++)),
    );
    await tester.pump();
    await tester.pump();
    expect(callCount, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();

    expect(callCount, 2);
  });
}
