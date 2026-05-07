/// Identifies a download that should be auto-started after SAF directory setup.
///
/// Serialised to/from URL query parameters so it can be passed through GoRouter.
class PendingDownload {
  /// Creates a [PendingDownload].
  const PendingDownload({required this.competitionId, required this.kind});

  /// The SoaringSpot slug of the competition.
  final String competitionId;

  /// The type of file to download: `"task"`, `"airspace"`, or `"waypoints"`.
  final String kind;

  /// Serialises this instance to a URL query-parameter string.
  ///
  /// Format: `competitionId=<id>&kind=<kind>`.
  String toQueryString() =>
      'competitionId=${Uri.encodeComponent(competitionId)}&kind=${Uri.encodeComponent(kind)}';

  /// Parses a [PendingDownload] from [params], or returns `null` if the
  /// required keys are absent.
  static PendingDownload? fromQueryParameters(Map<String, String> params) {
    final id = params['competitionId'];
    final kind = params['kind'];
    if (id == null || kind == null) return null;
    return PendingDownload(competitionId: id, kind: kind);
  }
}
