import 'package:compman_mobile/features/competitions/domain/entities/bookmarked_competition.dart';
import 'package:compman_mobile/features/competitions/presentation/providers/competitions_providers.dart';
import 'package:compman_mobile/features/competitions/presentation/screens/bookmarks_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Fake notifiers — override build() without touching the real repository/Hive
// ---------------------------------------------------------------------------

class _EmptyBookmarksNotifier extends BookmarkedCompetitionsNotifier {
  @override
  Future<List<BookmarkedCompetition>> build() async => [];
}

class _DataBookmarksNotifier extends BookmarkedCompetitionsNotifier {
  @override
  Future<List<BookmarkedCompetition>> build() async => [
        BookmarkedCompetition(
          id: 'comp-1',
          title: 'Competition One',
          soaringspotUrl: 'https://example.com/1',
          bookmarkedAt: DateTime(2026, 3, 1),
        ),
        BookmarkedCompetition(
          id: 'comp-2',
          title: 'Competition Two',
          soaringspotUrl: 'https://example.com/2',
          bookmarkedAt: DateTime(2026, 3, 2),
        ),
      ];
}

class _ErrorBookmarksNotifier extends BookmarkedCompetitionsNotifier {
  @override
  Future<List<BookmarkedCompetition>> build() async =>
      throw Exception('Load failed');
}

// ---------------------------------------------------------------------------
// Helper — builds a testable app with BookmarksScreen as the root route
// ---------------------------------------------------------------------------

Widget _buildApp(Override bookmarksOverride) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const BookmarksScreen(),
      ),
      GoRoute(
        path: '/add',
        builder: (_, __) => const Scaffold(body: Text('Add screen')),
      ),
      GoRoute(
        path: '/about',
        builder: (_, __) => const Scaffold(body: Text('About screen')),
      ),
      GoRoute(
        path: '/competitions/:id',
        builder: (_, __) => const Scaffold(body: Text('Detail screen')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [bookmarksOverride],
    child: MaterialApp.router(routerConfig: router),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  testWidgets('shows empty state when bookmarks list is empty', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        bookmarkedCompetitionsProvider.overrideWith(
          () => _EmptyBookmarksNotifier(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Add Competition'), findsOneWidget);
    expect(find.text('No competitions added yet.'), findsOneWidget);
  });

  testWidgets('shows competition titles when bookmarks are loaded',
      (tester) async {
    await tester.pumpWidget(
      _buildApp(
        bookmarkedCompetitionsProvider.overrideWith(
          () => _DataBookmarksNotifier(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Competition One'), findsOneWidget);
    expect(find.text('Competition Two'), findsOneWidget);
  });

  testWidgets('shows error message and Retry button on failure',
      (tester) async {
    await tester.pumpWidget(
      _buildApp(
        bookmarkedCompetitionsProvider.overrideWith(
          () => _ErrorBookmarksNotifier(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('An unexpected error occurred.'), findsOneWidget);
  });

  testWidgets('shows confirmation dialog when trash icon is tapped',
      (tester) async {
    await tester.pumpWidget(
      _buildApp(
        bookmarkedCompetitionsProvider.overrideWith(
          () => _DataBookmarksNotifier(),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();

    expect(find.text('Remove competition?'), findsOneWidget);
  });
}
