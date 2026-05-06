import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'app.dart';
import 'core/di/providers.dart';
import 'core/storage/last_viewed_local_datasource.dart';
import 'features/competitions/data/models/bookmarked_competition_model.dart';

/// Entry point. Opens both Hive boxes, resolves the initial route, then runs
/// the app inside a [ProviderScope] with pre-warmed provider overrides.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(BookmarkedCompetitionModelAdapter());
  }
  final bookmarksBox = await Hive.openBox<BookmarkedCompetitionModel>(
    'bookmarks',
  );
  final settingsBox = await Hive.openBox<String>('settings');

  String initialLocation = '/';
  final lastId = LastViewedLocalDataSource(settingsBox).readLastViewedId();
  if (lastId != null && bookmarksBox.values.any((m) => m.id == lastId)) {
    initialLocation = '/competitions/$lastId';
  }

  runApp(
    ProviderScope(
      overrides: [
        bookmarksBoxProvider.overrideWithValue(AsyncData(bookmarksBox)),
        settingsBoxProvider.overrideWithValue(AsyncData(settingsBox)),
      ],
      child: CompmanApp(initialLocation: initialLocation),
    ),
  );
}
