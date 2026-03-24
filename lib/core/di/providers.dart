import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../features/competitions/data/models/bookmarked_competition_model.dart';
import '../network/http_client.dart';

/// Provides the configured [Dio] instance.
final dioProvider = Provider<Dio>((ref) => createDioClient());

/// Provides the Hive [Box] used to persist bookmarked competitions.
///
/// Registers [BookmarkedCompetitionModelAdapter] (typeId 0) before opening the
/// box so that Hive can serialise and deserialise the stored objects.
final bookmarksBoxProvider =
    FutureProvider<Box<BookmarkedCompetitionModel>>((ref) async {
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(BookmarkedCompetitionModelAdapter());
  }
  return Hive.openBox<BookmarkedCompetitionModel>('bookmarks');
});
