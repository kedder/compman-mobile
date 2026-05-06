import 'package:hive_ce_flutter/hive_ce_flutter.dart';

const _kLastViewedId = 'lastViewedCompetitionId';

/// Reads and writes the last-viewed competition ID in the shared settings box.
///
/// The caller is responsible for opening the box before constructing this
/// data source. No adapter registration is required for a [Box<String>].
class LastViewedLocalDataSource {
  /// Creates a [LastViewedLocalDataSource] backed by [box].
  const LastViewedLocalDataSource(this._box);

  final Box<String> _box;

  /// Returns the stored last-viewed competition ID, or [null] if none is set.
  String? readLastViewedId() => _box.get(_kLastViewedId);

  /// Stores [id] as the last-viewed competition ID.
  Future<void> writeLastViewedId(String id) => _box.put(_kLastViewedId, id);
}
