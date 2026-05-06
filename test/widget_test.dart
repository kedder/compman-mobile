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

  testWidgets(
    'CompmanApp with initialCompetitionId pushes detail on top of home',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [bookmarksBoxProvider.overrideWithValue(_emptyBox)],
          child: const CompmanApp(initialCompetitionId: 'test-id'),
        ),
      );
      // First pump: home screen renders and post-frame callback fires.
      await tester.pump();
      // Second pump: router push settles, CompetitionDetailScreen is shown.
      await tester.pump();

      expect(find.text('Competition Details'), findsOneWidget);
    },
  );
}
