import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/bookmarked_competition.dart';
import '../../domain/entities/competition.dart';
import '../../domain/entities/task_info.dart';
import '../../domain/repositories/competitions_repository.dart';
import '../datasources/competitions_local_datasource.dart';
import '../datasources/soarscore_remote_datasource.dart';
import '../datasources/soaringspot_remote_datasource.dart';
import '../models/bookmarked_competition_model.dart';

/// Concrete implementation of [CompetitionsRepository].
///
/// Orchestrates [SoaringSpotRemoteDataSource] for network fetches and
/// [CompetitionsLocalDataSource] for local bookmark persistence.
/// Exceptions from both sources are mapped to [Failure] subtypes.
class CompetitionsRepositoryImpl implements CompetitionsRepository {
  /// Data source for fetching competitions from SoaringSpot.
  final SoaringSpotRemoteDataSource remote;

  /// Data source for persisting bookmarked competitions locally.
  final CompetitionsLocalDataSource local;

  /// Data source for fetching task files from SoarScore.
  final SoarScoreRemoteDataSource soarScore;

  /// Creates a [CompetitionsRepositoryImpl] with the given data sources.
  CompetitionsRepositoryImpl({
    required this.remote,
    required this.local,
    required this.soarScore,
  });

  @override
  Future<Either<Failure, List<Competition>>> fetchCompetitions() async {
    try {
      final models = await remote.fetchCompetitions();
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ParseException catch (e) {
      return Left(ParseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<BookmarkedCompetition>>>
      getBookmarkedCompetitions() async {
    try {
      final models = await local.getAll();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> bookmarkCompetition(
      Competition competition) async {
    try {
      final model = BookmarkedCompetitionModel(
        id: competition.id,
        title: competition.title,
        soaringspotUrl: competition.url,
        bookmarkedAt: DateTime.now(),
      );
      await local.save(model);
      return const Right(unit);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeBookmark(String competitionId) async {
    try {
      await local.delete(competitionId);
      return const Right(unit);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TaskInfo>>> fetchLatestTasks(
      String competitionId) async {
    try {
      return Right(await soarScore.fetchLatestTasks(competitionId));
    } on ServerException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Uint8List>> downloadTask(String taskUrl) async {
    try {
      return Right(await soarScore.downloadTask(taskUrl));
    } on ServerException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }
}
