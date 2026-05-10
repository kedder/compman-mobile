@Tags(['screenshots'])
library;

import 'package:compman_mobile/core/theme/app_theme.dart';
import 'package:compman_mobile/features/competitions/domain/entities/bookmarked_competition.dart';
import 'package:compman_mobile/features/competitions/domain/entities/downloadable_file_info.dart';
import 'package:compman_mobile/features/competitions/domain/entities/task_info.dart';
import 'package:compman_mobile/features/competitions/presentation/providers/competitions_providers.dart';
import 'package:compman_mobile/features/competitions/presentation/screens/bookmarks_screen.dart';
import 'package:compman_mobile/features/competitions/presentation/screens/competition_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Device sizes (physical pixels, DPR set to 1.0 so PNG dimensions match)
// ---------------------------------------------------------------------------

const _phoneSz    = Size(1080, 2400);
const _tablet7Sz  = Size(800, 1280);
const _tablet10Sz = Size(2560, 1600);

// ---------------------------------------------------------------------------
// Fixture data
// ---------------------------------------------------------------------------

final _bookmarks = [
  BookmarkedCompetition(
    id: 'alpine-2026',
    title: 'Alpine Open 2026',
    soaringspotUrl: 'https://www.soaringspot.com/en_gb/alpine-open-2026/',
    bookmarkedAt: DateTime(2026, 5, 1),
    startDate: DateTime(2026, 7, 1),
    endDate: DateTime(2026, 7, 10),
    selectedClass: 'Standard',
  ),
  BookmarkedCompetition(
    id: 'bavarian-2026',
    title: 'Bavarian Championship 2026',
    soaringspotUrl: 'https://www.soaringspot.com/en_gb/bavarian-2026/',
    bookmarkedAt: DateTime(2026, 5, 5),
    startDate: DateTime(2026, 8, 5),
    endDate: DateTime(2026, 8, 15),
  ),
  BookmarkedCompetition(
    id: 'nordic-cup-2026',
    title: 'Nordic Cup 2026',
    soaringspotUrl: 'https://www.soaringspot.com/en_gb/nordic-cup-2026/',
    bookmarkedAt: DateTime(2026, 5, 8),
    startDate: DateTime(2026, 6, 20),
    endDate: DateTime(2026, 6, 28),
  ),
];

const _compId = 'alpine-2026';

final _competition = BookmarkedCompetition(
  id: _compId,
  title: 'Alpine Open 2026',
  soaringspotUrl: 'https://www.soaringspot.com/en_gb/alpine-open-2026/',
  bookmarkedAt: DateTime(2026, 5, 1),
  startDate: DateTime(2026, 7, 1),
  endDate: DateTime(2026, 7, 10),
  selectedClass: 'Standard',
);

const _task = TaskInfo(
  compClass: 'Standard',
  title: '250km FAI Triangle',
  dayNo: 3,
  taskNo: 1,
  timestamp: '2026-07-03 09:15',
  taskUrl: 'https://example.com/task.tsk',
);

const _airspaceFile = DownloadableFileInfo(
  filename: 'airspace_alpine_2026.txt',
  downloadUrl: 'https://example.com/airspace.txt',
  kind: DownloadableFileKind.airspace,
  fileSize: 154000,
  publishedVersion: '01/07/2026, 08:00',
);

const _waypointsFile = DownloadableFileInfo(
  filename: 'waypoints_alpine_2026.cup',
  downloadUrl: 'https://example.com/waypoints.cup',
  kind: DownloadableFileKind.waypoints,
  fileSize: 48000,
  publishedVersion: '01/07/2026, 08:00',
);

// ---------------------------------------------------------------------------
// Fake notifiers
// ---------------------------------------------------------------------------

class _BookmarksNotifier extends BookmarkedCompetitionsNotifier {
  @override
  Future<List<BookmarkedCompetition>> build() async => _bookmarks;
}

// ---------------------------------------------------------------------------
// App builders
// ---------------------------------------------------------------------------

Widget _buildBookmarksApp() {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => const BookmarksScreen()),
      GoRoute(
        path: '/add',
        builder: (_, __) => const Scaffold(body: Text('Add')),
      ),
      GoRoute(
        path: '/about',
        builder: (_, __) => const Scaffold(body: Text('About')),
      ),
      GoRoute(
        path: '/competitions/:id',
        builder: (_, __) => const Scaffold(body: Text('Detail')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      bookmarkedCompetitionsProvider.overrideWith(() => _BookmarksNotifier()),
    ],
    child: MaterialApp.router(routerConfig: router, theme: AppTheme.light()),
  );
}

Widget _buildDetailApp() {
  final router = GoRouter(
    initialLocation: '/competitions/$_compId',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const Scaffold(body: Text('Home'))),
      GoRoute(
        path: '/competitions/:id',
        builder: (_, __) =>
            const CompetitionDetailScreen(competitionId: _compId),
      ),
      GoRoute(
        path: '/settings/xcsoar-directory',
        builder: (_, __) => const Scaffold(body: Text('Settings')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      competitionDetailProvider(_compId).overrideWith((ref) async => _competition),
      competitionClassesProvider(_compId).overrideWith(
        (ref) async => ['Standard', 'Club'],
      ),
      xcsoarDirectoryUriProvider.overrideWith(
        (ref) async => 'content://com.example.xcsoar/XCSoarData',
      ),
      latestTasksProvider(_compId).overrideWith(
        (ref) async => const [_task],
      ),
      downloadsProvider(_compId).overrideWith(
        (ref) async => const [_airspaceFile, _waypointsFile],
      ),
    ],
    child: MaterialApp.router(routerConfig: router, theme: AppTheme.light()),
  );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> _capture(WidgetTester tester, String name) async {
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('../../assets/google-play/$name.png'),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {

  group('phone (1080×2400)', () {
    testWidgets('phone-1 · bookmarks list', (tester) async {
      _setSize(tester, _phoneSz);
      await tester.pumpWidget(_buildBookmarksApp());
      await tester.pump();
      await _capture(tester, 'phone-1');
    });

    testWidgets('phone-2 · competition detail', (tester) async {
      _setSize(tester, _phoneSz);
      await tester.pumpWidget(_buildDetailApp());
      await tester.pump();
      await tester.pump();
      await _capture(tester, 'phone-2');
    });
  });

  group('7-inch tablet (800×1280)', () {
    testWidgets('tablet-7in-1 · bookmarks list', (tester) async {
      _setSize(tester, _tablet7Sz);
      await tester.pumpWidget(_buildBookmarksApp());
      await tester.pump();
      await _capture(tester, 'tablet-7in-1');
    });

    testWidgets('tablet-7in-2 · competition detail', (tester) async {
      _setSize(tester, _tablet7Sz);
      await tester.pumpWidget(_buildDetailApp());
      await tester.pump();
      await tester.pump();
      await _capture(tester, 'tablet-7in-2');
    });
  });

  group('10-inch tablet (2560×1600)', () {
    testWidgets('tablet-10in-1 · bookmarks list', (tester) async {
      _setSize(tester, _tablet10Sz);
      await tester.pumpWidget(_buildBookmarksApp());
      await tester.pump();
      await _capture(tester, 'tablet-10in-1');
    });

    testWidgets('tablet-10in-2 · competition detail', (tester) async {
      _setSize(tester, _tablet10Sz);
      await tester.pumpWidget(_buildDetailApp());
      await tester.pump();
      await tester.pump();
      await _capture(tester, 'tablet-10in-2');
    });
  });
}
