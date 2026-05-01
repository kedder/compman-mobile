import 'dart:typed_data';

import 'package:compman_mobile/core/di/providers.dart';
import 'package:compman_mobile/core/error/failures.dart';
import 'package:compman_mobile/core/theme/app_theme.dart';
import 'package:compman_mobile/features/competitions/domain/entities/bookmarked_competition.dart';
import 'package:compman_mobile/features/competitions/domain/entities/competition.dart';
import 'package:compman_mobile/features/competitions/domain/entities/task_info.dart';
import 'package:compman_mobile/features/competitions/domain/repositories/competitions_repository.dart';
import 'package:compman_mobile/features/competitions/domain/usecases/download_task.dart';
import 'package:compman_mobile/features/competitions/domain/usecases/set_competition_class.dart';
import 'package:compman_mobile/features/competitions/presentation/providers/competitions_providers.dart';
import 'package:compman_mobile/features/competitions/presentation/screens/competition_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';

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

final _selectedClassCompetition = _tCompetition.copyWith(selectedClass: 'Club');

const _clubTask = TaskInfo(
  compClass: 'Club',
  title: '500km Triangle',
  dayNo: 4,
  taskNo: 1,
  timestamp: '2026-07-14 09:30',
  taskUrl: 'https://example.com/task.tsk',
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
        builder: (_, __) => const Scaffold(body: Text('XCSoar dir settings')),
      ),
    ],
  );

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(routerConfig: router, theme: AppTheme.light()),
  );
}

/// Returns the base overrides needed for every test: competition detail,
/// xcsoar dir, and latest tasks.
List<Override> _baseOverrides({
  required List<String> classes,
  BookmarkedCompetition? competition,
  List<TaskInfo> tasks = const <TaskInfo>[],
  String? xcsoarDirectoryUri,
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
  ];
}

class _RecordingSetCompetitionClass extends SetCompetitionClass {
  _RecordingSetCompetitionClass(this.onCall) : super(const _DummyRepository());

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

class _FailingDownloadTask extends DownloadTask {
  _FailingDownloadTask(this.failure) : super(const _DummyRepository());

  final Failure failure;

  @override
  Future<Either<Failure, Uint8List>> call(String taskUrl) async =>
      left(failure);
}

class _DummyRepository implements CompetitionsRepository {
  const _DummyRepository();

  @override
  Future<Either<Failure, Unit>> bookmarkCompetition(Competition competition) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, Uint8List>> downloadTask(String taskUrl) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, List<Competition>>> fetchCompetitions() =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, List<String>>> fetchCompetitionClasses(
    String competitionId,
  ) => throw UnimplementedError();

  @override
  Future<Either<Failure, List<TaskInfo>>> fetchLatestTasks(
    String competitionId,
  ) => throw UnimplementedError();

  @override
  Future<Either<Failure, List<BookmarkedCompetition>>>
  getBookmarkedCompetitions() => throw UnimplementedError();

  @override
  Future<Either<Failure, Unit>> removeBookmark(String competitionId) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, Unit>> setCompetitionClass(
    String competitionId,
    String? selectedClass,
  ) => throw UnimplementedError();
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
        downloadTaskProvider.overrideWith(
          (ref) => _FailingDownloadTask(
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
        downloadTaskProvider.overrideWith(
          (ref) => _FailingDownloadTask(
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
}
