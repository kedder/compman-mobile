import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/platform/xcsoar_saf_service.dart';
import '../entities/downloadable_file_info.dart';
import '../repositories/competitions_repository.dart';

/// Orchestrates downloading a [DownloadableFileInfo] and writing it to the
/// XCSoar SAF directory with a fixed output filename.
///
/// Steps: (1) download raw bytes via [CompetitionsRepository.downloadFile],
/// (2) write to the SAF directory via [XcsoarSafService.writeFile],
/// (3) record the install version token via
/// [CompetitionsRepository.recordFileInstall].
///
/// Returns [Right] with the on-device filename that was written
/// (`compman-airspace.txt` or `compman-waypoints.cup`) on success. This is
/// the single source of truth for those fixed filenames — callers should
/// read the name off the returned value rather than hard-coding it again.
/// Returns [Left(Failure)] if the file download fails. [PlatformException]
/// from [XcsoarSafService] is **not** caught — it propagates to the caller,
/// matching the existing task-install pattern in the presentation layer.
class DownloadAndInstallFile {
  /// Creates a [DownloadAndInstallFile] with the given [repository] and
  /// [safService].
  const DownloadAndInstallFile(this._repo, this._safService);

  final CompetitionsRepository _repo;
  final XcsoarSafService _safService;

  /// Downloads and installs [fileInfo] for competition [competitionId].
  ///
  /// Airspace files are written as `compman-airspace.txt`; waypoints files as
  /// `compman-waypoints.cup`. The fixed names mean XCSoar only needs to be
  /// configured once — subsequent updates overwrite the same file.
  Future<Either<Failure, String>> call({
    required String competitionId,
    required DownloadableFileInfo fileInfo,
  }) async {
    final bytesResult = await _repo.downloadFile(fileInfo.downloadUrl);
    if (bytesResult.isLeft()) {
      return Left(bytesResult.getLeft().toNullable()!);
    }
    final bytes = bytesResult.getRight().toNullable()!;

    final outputName = switch (fileInfo.kind) {
      DownloadableFileKind.airspace => 'compman-airspace.txt',
      DownloadableFileKind.waypoints => 'compman-waypoints.cup',
    };
    await _safService.writeFile(bytes, outputName);

    await _repo.recordFileInstall(
      competitionId,
      fileInfo.kind,
      fileInfo.publishedVersion,
    );

    return Right(outputName);
  }
}
