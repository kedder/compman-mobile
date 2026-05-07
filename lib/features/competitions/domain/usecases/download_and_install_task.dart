import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/platform/xcsoar_saf_service.dart';
import '../repositories/competitions_repository.dart';

/// Orchestrates downloading a `.tsk` file and writing it to the XCSoar SAF
/// directory as `Default.tsk`.
///
/// Steps: (1) download raw bytes via [CompetitionsRepository.downloadTask],
/// (2) write to the SAF directory via [XcsoarSafService.writeFile].
///
/// Returns [Right(unit)] on success. Returns [Left(Failure)] if the download
/// fails. [PlatformException] from [XcsoarSafService] propagates to the
/// caller, matching the convention in [DownloadAndInstallFile].
class DownloadAndInstallTask {
  /// Creates a [DownloadAndInstallTask] with the given [repository] and
  /// [safService].
  const DownloadAndInstallTask(this._repo, this._safService);

  final CompetitionsRepository _repo;
  final XcsoarSafService _safService;

  /// Downloads the task at [taskUrl] and writes it as `Default.tsk`.
  Future<Either<Failure, Unit>> call(String taskUrl) async {
    final bytesResult = await _repo.downloadTask(taskUrl);
    if (bytesResult.isLeft()) {
      return Left(bytesResult.getLeft().toNullable()!);
    }
    await _safService.writeFile(
      bytesResult.getRight().toNullable()!,
      'Default.tsk',
    );
    return const Right(unit);
  }
}
