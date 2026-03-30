import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/competitions_repository.dart';

/// Downloads the raw bytes of a `.tsk` file from [taskUrl].
///
/// Returns a [Right] with a [Uint8List] on success, or a [Left] with a
/// [Failure] if the download fails.
class DownloadTask {
  /// The repository used to download task files.
  final CompetitionsRepository _repo;

  /// Creates a [DownloadTask] use case with the given [repository].
  const DownloadTask(this._repo);

  /// Downloads the `.tsk` file at [taskUrl] and returns its raw bytes.
  Future<Either<Failure, Uint8List>> call(String taskUrl) =>
      _repo.downloadTask(taskUrl);
}
