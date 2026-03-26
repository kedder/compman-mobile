import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../features/competitions/data/datasources/competitions_local_datasource.dart';
import '../../features/competitions/data/datasources/soaringspot_remote_datasource.dart';
import '../../features/competitions/data/models/bookmarked_competition_model.dart';
import '../../features/competitions/data/repositories/competitions_repository_impl.dart';
import '../../features/competitions/domain/repositories/competitions_repository.dart';
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

/// Provides the [SoaringSpotRemoteDataSource] implementation.
final soaringSpotRemoteDataSourceProvider =
    Provider<SoaringSpotRemoteDataSource>(
  (ref) => SoaringSpotRemoteDataSourceImpl(ref.watch(dioProvider)),
);

/// Provides the [CompetitionsLocalDataSource] implementation.
///
/// Depends on [bookmarksBoxProvider]; resolves only when the Hive box is open.
final competitionsLocalDataSourceProvider =
    Provider<CompetitionsLocalDataSource>((ref) {
  final box = ref.watch(bookmarksBoxProvider).requireValue;
  return HiveCompetitionsLocalDataSource(box);
});

/// Provides the [CompetitionsRepository] implementation.
final competitionsRepositoryProvider = Provider<CompetitionsRepository>((ref) {
  return CompetitionsRepositoryImpl(
    remote: ref.watch(soaringSpotRemoteDataSourceProvider),
    local: ref.watch(competitionsLocalDataSourceProvider),
  );
});
