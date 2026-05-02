import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/competitions_repository.dart';

/// Downloads the raw bytes of an airspace or waypoint file from a URL.
///
/// Returns a [Right] with a [Uint8List] on success, or a [Left] with a
/// [Failure] if the download fails.
class DownloadFile {
  /// The repository used to download files.
  final CompetitionsRepository _repo;

  /// Creates a [DownloadFile] use case with the given [repository].
  const DownloadFile(this._repo);

  /// Downloads the file at [fileUrl] and returns its raw bytes.
  Future<Either<Failure, Uint8List>> call(String fileUrl) =>
      _repo.downloadFile(fileUrl);
}
