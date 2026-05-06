import 'package:compman_mobile/app.dart';
import 'package:compman_mobile/core/di/providers.dart';
import 'package:compman_mobile/features/competitions/data/models/bookmarked_competition_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// In-memory fake — satisfies [bookmarksBoxProvider] without touching Hive.
class _EmptyBookmarksBox extends Fake
    implements Box<BookmarkedCompetitionModel> {
  @override
  Iterable<BookmarkedCompetitionModel> get values => const [];

  @override
  BookmarkedCompetitionModel? get(
    dynamic key, {
    BookmarkedCompetitionModel? defaultValue,
  }) => null;
}

final _emptyBox = _EmptyBookmarksBox();

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: CompmanApp()));
    // GoRouter renders; give it a frame to settle the initial route.
    await tester.pump();

    expect(find.text('Your competitions'), findsOneWidget);
  });

  testWidgets('CompmanApp with initialLocation "/" renders BookmarksScreen', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: CompmanApp(initialLocation: '/')),
    );
    await tester.pump();

    expect(find.text('Your competitions'), findsOneWidget);
  });

  testWidgets(
    'CompmanApp with initialLocation "/competitions/:id" renders CompetitionDetailScreen',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [bookmarksBoxProvider.overrideWithValue(_emptyBox)],
          child: const CompmanApp(initialLocation: '/competitions/test-id'),
        ),
      );
      await tester.pump();

      expect(find.text('Competition Details'), findsOneWidget);
    },
  );
}
