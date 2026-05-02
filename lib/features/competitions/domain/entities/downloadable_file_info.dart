import 'package:freezed_annotation/freezed_annotation.dart';

part 'downloadable_file_info.freezed.dart';

/// Distinguishes airspace from waypoint files.
enum DownloadableFileKind { airspace, waypoints }

/// Represents a downloadable file (airspace or waypoints) listed on the
/// SoaringSpot competition downloads page.
@freezed
abstract class DownloadableFileInfo with _$DownloadableFileInfo {
  /// Creates an immutable [DownloadableFileInfo].
  const factory DownloadableFileInfo({
    /// Original filename on SoaringSpot (e.g. `"germany_2026.txt"`).
    required String filename,

    /// Absolute download URL.
    required String downloadUrl,

    /// File kind — airspace (.txt) or waypoints (.cup).
    required DownloadableFileKind kind,

    /// File size in bytes, if advertised in the HTML. Null when not present.
    int? fileSize,

    /// Raw modification timestamp string scraped from SoaringSpot (e.g.
    /// `"19/04/2026, 12:53"`). Treated as an opaque version token — never
    /// parsed into a [DateTime]. Null when the HTML carries no timestamp.
    ///
    /// **Why String, not DateTime?** Parsing the timestamp into a DateTime
    /// would require knowing the server's timezone, which SoaringSpot does
    /// not advertise in the HTML. Comparing parsed datetimes across timezones
    /// risks false positives or missed badges. Storing the raw string and
    /// comparing for equality avoids that entirely: the badge fires when the
    /// scraped string differs from the string stored at last install,
    /// regardless of what the string represents as a point in time.
    String? publishedVersion,
  }) = _DownloadableFileInfo;
}
