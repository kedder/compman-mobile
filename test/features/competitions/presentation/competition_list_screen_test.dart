import 'package:compman_mobile/features/competitions/domain/entities/bookmarked_competition.dart';
import 'package:compman_mobile/features/competitions/domain/entities/competition.dart';
import 'package:compman_mobile/features/competitions/presentation/providers/competitions_providers.dart';
import 'package:compman_mobile/features/competitions/presentation/screens/competition_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Test fixture data
// ---------------------------------------------------------------------------

final _tCompetitions = [
  const Competition(
    id: 'alpha-2026',
    title: 'Alpha Open 2026',
    url: 'https://example.com/alpha',
    description: 'Jun 1 - Jun 10, 2026 · Somewhere, DE',
  ),
  const Competition(
    id: 'beta-2026',
    title: 'Beta Championship',
    url: 'https://example.com/beta',
    description: 'Jul 5 - Jul 15, 2026 · Elsewhere, FR',
  ),
  const Competition(
    id: 'gamma-2026',
    title: 'Gamma Cup',
    url: 'https://example.com/gamma',
    description: 'Aug 1 - Aug 7, 2026 · Nowhere, AT',
  ),
];

// ---------------------------------------------------------------------------
// Fake notifiers
// ---------------------------------------------------------------------------

class _FakeCompetitionListNotifier extends CompetitionListNotifier {
  final List<Competition> _data;

  _FakeCompetitionListNotifier(this._data);

  @override
  Future<List<Competition>> build() async => _data;
}

class _FakeBookmarkedNotifier extends BookmarkedCompetitionsNotifier {
  @override
  Future<List<BookmarkedCompetition>> build() async => [];
}

// ---------------------------------------------------------------------------
// Helper — builds a testable widget with CompetitionListScreen as start
// ---------------------------------------------------------------------------

Widget _buildApp({
  List<Competition> competitions = const [],
  List<Override> extra = const [],
}) {
  final router = GoRouter(
    initialLocation: '/add',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: Text('Home')),
      ),
      GoRoute(
        path: '/add',
        builder: (_, __) => const CompetitionListScreen(),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      competitionListProvider.overrideWith(
        () => _FakeCompetitionListNotifier(competitions),
      ),
      bookmarkedCompetitionsProvider.overrideWith(
        () => _FakeBookmarkedNotifier(),
      ),
      ...extra,
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  testWidgets('shows all competition titles when list loads', (tester) async {
    await tester.pumpWidget(_buildApp(competitions: _tCompetitions));
    await tester.pump();

    expect(find.text('Alpha Open 2026'), findsOneWidget);
    expect(find.text('Beta Championship'), findsOneWidget);
    expect(find.text('Gamma Cup'), findsOneWidget);
  });

  testWidgets('filters competitions when search text is entered',
      (tester) async {
    await tester.pumpWidget(_buildApp(competitions: _tCompetitions));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Beta');
    await tester.pump();

    expect(find.text('Alpha Open 2026'), findsNothing);
    expect(find.text('Beta Championship'), findsOneWidget);
    expect(find.text('Gamma Cup'), findsNothing);
  });

  testWidgets('shows "No competitions found." when search matches nothing',
      (tester) async {
    await tester.pumpWidget(_buildApp(competitions: _tCompetitions));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'zzz-no-match');
    await tester.pump();

    expect(find.text('No competitions found.'), findsOneWidget);
  });

  testWidgets('tapping a competition row selects it (checkmark visible)',
      (tester) async {
    await tester.pumpWidget(_buildApp(competitions: _tCompetitions));
    await tester.pump();

    // Initially no item is selected.
    expect(find.byIcon(Icons.check_circle), findsNothing);

    // Tap the first competition row.
    await tester.tap(find.text('Alpha Open 2026'));
    await tester.pump();

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });
}
