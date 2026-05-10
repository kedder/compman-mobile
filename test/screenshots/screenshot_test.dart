@Tags(['screenshots'])
library;

import 'dart:io';

import 'package:compman_mobile/core/theme/app_theme.dart';
import 'package:compman_mobile/features/competitions/domain/entities/bookmarked_competition.dart';
import 'package:compman_mobile/features/competitions/domain/entities/downloadable_file_info.dart';
import 'package:compman_mobile/features/competitions/domain/entities/task_info.dart';
import 'package:compman_mobile/features/competitions/presentation/providers/competitions_providers.dart';
import 'package:compman_mobile/features/competitions/presentation/screens/bookmarks_screen.dart';
import 'package:compman_mobile/features/competitions/presentation/screens/competition_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Device profiles: physical size + realistic DPR.
// Physical pixels determine PNG dimensions; DPR sets logical dp canvas.
//   Phone  1080×2400 @ 2.625 dpr → 411×914 dp  (Pixel-class xxhdpi)
//   7-in   800×1280  @ 1.5   dpr → 533×853 dp  (hdpi tablet)
//   10-in  2560×1600 @ 2.0   dpr → 1280×800 dp (xhdpi tablet)
// ---------------------------------------------------------------------------

const _phoneSz = Size(1080, 2400);
const _phoneDpr = 2.625;
const _tablet7Sz = Size(800, 1280);
const _tablet7Dpr = 1.5;
const _tablet10Sz = Size(2560, 1600);
const _tablet10Dpr = 2.0;

// ---------------------------------------------------------------------------
// Fixture data
// ---------------------------------------------------------------------------

final _fmt = DateFormat('d MMM yyyy');
String _range(DateTime s, DateTime e) =>
    '${_fmt.format(s)} – ${_fmt.format(e)}';

final _now = DateTime.now();

// Live:     started 5 days ago, ends in 7 days
final _liveStart = _now.subtract(const Duration(days: 5));
final _liveEnd = _now.add(const Duration(days: 7));
// Upcoming: starts in 7 weeks
final _upcomingStart = _now.add(const Duration(days: 49));
final _upcomingEnd = _now.add(const Duration(days: 58));
// Past:     ended 10 days ago
final _pastStart = _now.subtract(const Duration(days: 30));
final _pastEnd = _now.subtract(const Duration(days: 10));

final _bookmarks = [
  BookmarkedCompetition(
    id: 'alpine-open',
    title: 'Alpine Open',
    soaringspotUrl: 'https://www.soaringspot.com/en_gb/alpine-open/',
    bookmarkedAt: _liveStart.subtract(const Duration(days: 15)),
    startDate: _liveStart,
    endDate: _liveEnd,
    selectedClass: 'Standard',
    description:
        'Zell am See, Austria, ${_range(_liveStart, _liveEnd)} 87 competitors in 3 classes',
  ),
  BookmarkedCompetition(
    id: 'bavarian-championship',
    title: 'Bavarian Championship',
    soaringspotUrl: 'https://www.soaringspot.com/en_gb/bavarian-championship/',
    bookmarkedAt: _now.subtract(const Duration(days: 5)),
    startDate: _upcomingStart,
    endDate: _upcomingEnd,
    description:
        'Straubing, Germany, ${_range(_upcomingStart, _upcomingEnd)} 42 competitors in 2 classes',
  ),
  BookmarkedCompetition(
    id: 'spring-cup-nitra',
    title: 'Spring Cup Nitra',
    soaringspotUrl: 'https://www.soaringspot.com/en_gb/spring-cup-nitra/',
    bookmarkedAt: _pastStart.subtract(const Duration(days: 15)),
    startDate: _pastStart,
    endDate: _pastEnd,
    description:
        'Nitra, Slovakia, ${_range(_pastStart, _pastEnd)} 24 competitors in 1 class',
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
    child: MaterialApp.router(routerConfig: router, theme: AppTheme.light(), debugShowCheckedModeBanner: false),
  );
}

Widget _buildDetailApp() {
  final router = GoRouter(
    initialLocation: '/competitions/$_compId',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: Text('Home')),
      ),
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
      competitionDetailProvider(
        _compId,
      ).overrideWith((ref) async => _competition),
      competitionClassesProvider(
        _compId,
      ).overrideWith((ref) async => ['Standard', 'Club']),
      xcsoarDirectoryUriProvider.overrideWith(
        (ref) async => 'content://com.example.xcsoar/XCSoarData',
      ),
      latestTasksProvider(_compId).overrideWith((ref) async => const [_task]),
      downloadsProvider(
        _compId,
      ).overrideWith((ref) async => const [_airspaceFile, _waypointsFile]),
    ],
    child: MaterialApp.router(routerConfig: router, theme: AppTheme.light(), debugShowCheckedModeBanner: false),
  );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

void _setSize(WidgetTester tester, Size size, double dpr) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = dpr;
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

Future<void> _loadFonts() async {
  final interLoader = FontLoader('Inter');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    final bytes = File(
      'assets/fonts/Inter/Inter-$weight.ttf',
    ).readAsBytesSync();
    interLoader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await interLoader.load();

  final iconLoader = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await iconLoader.load();
}

void main() {
  setUpAll(_loadFonts);

  group('phone (1080×2400)', () {
    testWidgets('phone-1 · bookmarks list', (tester) async {
      _setSize(tester, _phoneSz, _phoneDpr);
      await tester.pumpWidget(_buildBookmarksApp());
      await tester.pump();
      await _capture(tester, 'phone-1');
    });

    testWidgets('phone-2 · competition detail', (tester) async {
      _setSize(tester, _phoneSz, _phoneDpr);
      await tester.pumpWidget(_buildDetailApp());
      await tester.pump();
      await tester.pump();
      await _capture(tester, 'phone-2');
    });
  });

  group('7-inch tablet (800×1280)', () {
    testWidgets('tablet-7in-1 · bookmarks list', (tester) async {
      _setSize(tester, _tablet7Sz, _tablet7Dpr);
      await tester.pumpWidget(_buildBookmarksApp());
      await tester.pump();
      await _capture(tester, 'tablet-7in-1');
    });

    testWidgets('tablet-7in-2 · competition detail', (tester) async {
      _setSize(tester, _tablet7Sz, _tablet7Dpr);
      await tester.pumpWidget(_buildDetailApp());
      await tester.pump();
      await tester.pump();
      await _capture(tester, 'tablet-7in-2');
    });
  });

  group('10-inch tablet (2560×1600)', () {
    testWidgets('tablet-10in-1 · bookmarks list', (tester) async {
      _setSize(tester, _tablet10Sz, _tablet10Dpr);
      await tester.pumpWidget(_buildBookmarksApp());
      await tester.pump();
      await _capture(tester, 'tablet-10in-1');
    });

    testWidgets('tablet-10in-2 · competition detail', (tester) async {
      _setSize(tester, _tablet10Sz, _tablet10Dpr);
      await tester.pumpWidget(_buildDetailApp());
      await tester.pump();
      await tester.pump();
      await _capture(tester, 'tablet-10in-2');
    });
  });
}
