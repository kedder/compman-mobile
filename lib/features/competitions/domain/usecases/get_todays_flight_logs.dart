import 'package:intl/intl.dart';

import '../../../../core/platform/xcsoar_saf_service.dart';
import '../entities/flight_log_file.dart';

/// Fetches all flight logs via [XcsoarSafService.listFlightLogs] and filters
/// to today's date, matching the `yyyy-MM-dd` prefix XCSoar uses when naming
/// `.igc` files (e.g. `2018-02-26-XCS-WUX-01.igc`).
class GetTodaysFlightLogs {
  /// Creates a [GetTodaysFlightLogs] backed by [_safService].
  ///
  /// [now] may be injected for testing; defaults to [DateTime.now].
  const GetTodaysFlightLogs(this._safService, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final XcsoarSafService _safService;
  final DateTime Function() _now;

  /// Returns today's `.igc` flight logs, sorted by filename.
  ///
  /// [PlatformException] (e.g. code `SAF_NOT_CONFIGURED`) is not caught — it
  /// propagates to the caller.
  Future<List<FlightLogFile>> call() async {
    final all = await _safService.listFlightLogs();
    final todayPrefix = DateFormat('yyyy-MM-dd').format(_now());
    final todays =
        all
            .map((m) => FlightLogFile(filename: m['filename']!, uri: m['uri']!))
            .where((f) => f.filename.startsWith(todayPrefix))
            .toList()
          ..sort((a, b) => a.filename.compareTo(b.filename));
    return todays;
  }
}
