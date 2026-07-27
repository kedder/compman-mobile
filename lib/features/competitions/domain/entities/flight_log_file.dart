import 'package:freezed_annotation/freezed_annotation.dart';

part 'flight_log_file.freezed.dart';

/// A single `.igc` flight log file found in XCSoar's SAF-granted directory.
///
/// Transient — always freshly fetched from [XcsoarSafService.listFlightLogs],
/// never persisted locally.
@freezed
abstract class FlightLogFile with _$FlightLogFile {
  /// Creates an immutable [FlightLogFile].
  const factory FlightLogFile({
    /// Raw on-disk name, e.g. `"2018-02-26-XCS-WUX-01.igc"`.
    required String filename,

    /// SAF `content://` URI string for this document.
    required String uri,
  }) = _FlightLogFile;
}
