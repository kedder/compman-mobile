import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../features/competitions/data/datasources/competitions_local_datasource.dart';
import '../../features/competitions/data/datasources/soarscore_remote_datasource.dart';
import '../../features/competitions/data/datasources/soaringspot_remote_datasource.dart';
import '../../features/competitions/data/models/bookmarked_competition_model.dart';
import '../../features/competitions/data/repositories/competitions_repository_impl.dart';
import '../../features/competitions/domain/repositories/competitions_repository.dart';
import '../../features/competitions/domain/usecases/download_and_install_file.dart';
import '../../features/competitions/domain/usecases/download_file.dart';
import '../../features/competitions/domain/usecases/download_task.dart';
import '../../features/competitions/domain/usecases/fetch_competition_classes.dart';
import '../../features/competitions/domain/usecases/fetch_downloads.dart';
import '../../features/competitions/domain/usecases/fetch_latest_tasks.dart';
import '../../features/competitions/domain/usecases/record_file_install.dart';
import '../../features/competitions/domain/usecases/set_competition_class.dart';
import '../network/http_client.dart';
import '../platform/xcsoar_saf_service.dart';

/// Provides the configured [Dio] instance.
final dioProvider = Provider<Dio>((ref) => createDioClient());

/// Provides the Hive [Box] used to persist bookmarked competitions.
///
/// Registers [BookmarkedCompetitionModelAdapter] (typeId 0) before opening the
/// box so that Hive can serialise and deserialise the stored objects.
final bookmarksBoxProvider = FutureProvider<Box<BookmarkedCompetitionModel>>((
  ref,
) async {
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
    soarScore: ref.watch(soarScoreRemoteDataSourceProvider),
  );
});

/// Provides the [SoarScoreRemoteDataSource] implementation.
final soarScoreRemoteDataSourceProvider = Provider<SoarScoreRemoteDataSource>(
  (ref) => DioSoarScoreRemoteDataSource(ref.watch(dioProvider)),
);

/// Provides a [FetchLatestTasks] use case instance.
final fetchLatestTasksProvider = Provider<FetchLatestTasks>(
  (ref) => FetchLatestTasks(ref.read(competitionsRepositoryProvider)),
);

/// Provides a [DownloadTask] use case instance.
final downloadTaskProvider = Provider<DownloadTask>(
  (ref) => DownloadTask(ref.read(competitionsRepositoryProvider)),
);

/// Provides a [SetCompetitionClass] use case instance.
final setCompetitionClassProvider = Provider<SetCompetitionClass>(
  (ref) => SetCompetitionClass(ref.read(competitionsRepositoryProvider)),
);

/// Provides a [FetchCompetitionClasses] use case instance.
final fetchCompetitionClassesProvider = Provider<FetchCompetitionClasses>(
  (ref) => FetchCompetitionClasses(ref.read(competitionsRepositoryProvider)),
);

/// Provides a [FetchDownloads] use case instance.
final fetchDownloadsProvider = Provider<FetchDownloads>(
  (ref) => FetchDownloads(ref.read(competitionsRepositoryProvider)),
);

/// Provides a [DownloadFile] use case instance.
final downloadFileProvider = Provider<DownloadFile>(
  (ref) => DownloadFile(ref.read(competitionsRepositoryProvider)),
);

/// Provides a [RecordFileInstall] use case instance.
final recordFileInstallProvider = Provider<RecordFileInstall>(
  (ref) => RecordFileInstall(ref.read(competitionsRepositoryProvider)),
);

/// Provides a [DownloadAndInstallFile] use case instance.
final downloadAndInstallFileProvider = Provider<DownloadAndInstallFile>(
  (ref) => DownloadAndInstallFile(
    ref.read(competitionsRepositoryProvider),
    XcsoarSafService(),
  ),
);

/// Provides the app's [PackageInfo] metadata from the host platform.
final packageInfoProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);
