import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/platform/xcsoar_saf_service.dart';
import '../entities/flight_log_file.dart';
import '../repositories/competitions_repository.dart';

/// Launches the device's share/send intent with [files] attached, addressed
/// to [recipient]. On success (the intent was launched without error — this
/// says nothing about whether the pilot actually completes the send inside
/// their mail app, which Compman has no visibility into), remembers
/// [recipient] as the competition's scoring email for next time.
///
/// [PlatformException] from [XcsoarSafService.shareFlightLogs] (e.g. code
/// `NO_MAIL_APP`) is not caught — it propagates to the caller *before* the
/// email is persisted, matching [DownloadAndInstallFile]'s contract.
class SendFlightLogs {
  /// Creates a [SendFlightLogs] use case backed by [_repo] and [_safService].
  const SendFlightLogs(this._repo, this._safService);

  final CompetitionsRepository _repo;
  final XcsoarSafService _safService;

  /// Sends [files] to [recipient] for [competitionId], then remembers
  /// [recipient] as the scoring email.
  Future<Either<Failure, Unit>> call({
    required String competitionId,
    required List<FlightLogFile> files,
    required String recipient,
  }) async {
    await _safService.shareFlightLogs(
      uris: files.map((f) => f.uri).toList(),
      recipient: recipient,
    );
    return _repo.setCompetitionScoringEmail(competitionId, recipient);
  }
}
