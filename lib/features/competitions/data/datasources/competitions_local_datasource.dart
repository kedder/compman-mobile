import 'package:hive_flutter/hive_flutter.dart';

import '../models/bookmarked_competition_model.dart';

/// Abstract interface for local persistence of bookmarked competitions.
abstract class CompetitionsLocalDataSource {
  /// Returns all persisted [BookmarkedCompetitionModel] objects.
  Future<List<BookmarkedCompetitionModel>> getAll();

  /// Persists [model], keyed by its [BookmarkedCompetitionModel.id].
  Future<void> save(BookmarkedCompetitionModel model);

  /// Deletes the model with the given [id]. No-op if absent.
  Future<void> delete(String id);
}

/// Hive-backed implementation of [CompetitionsLocalDataSource].
///
/// Expects a [Box] typed to [BookmarkedCompetitionModel] named `"bookmarks"`.
/// Hive exceptions are allowed to propagate — the repository layer converts them
/// to [StorageFailure].
class HiveCompetitionsLocalDataSource implements CompetitionsLocalDataSource {
  /// The Hive box used for storage.
  final Box<BookmarkedCompetitionModel> box;

  /// Creates an instance backed by the provided Hive [box].
  HiveCompetitionsLocalDataSource(this.box);

  @override
  Future<List<BookmarkedCompetitionModel>> getAll() async =>
      box.values.toList();

  @override
  Future<void> save(BookmarkedCompetitionModel model) =>
      box.put(model.id, model);

  @override
  Future<void> delete(String id) => box.delete(id);
}
