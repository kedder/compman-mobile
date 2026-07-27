import 'package:freezed_annotation/freezed_annotation.dart';

import 'competition_status.dart';

part 'bookmarked_competition.freezed.dart';

/// Represents a competition that the user has bookmarked.
///
/// Persisted locally via Hive. [bookmarkedAt] records when the bookmark was added.
@freezed
abstract class BookmarkedCompetition with _$BookmarkedCompetition {
  const BookmarkedCompetition._();

  /// Creates an immutable [BookmarkedCompetition].
  const factory BookmarkedCompetition({
    required String id,
    required String title,
    required String soaringspotUrl,
    required DateTime bookmarkedAt,
    String? selectedClass,
    String? description,
    DateTime? startDate,
    DateTime? endDate,

    /// SoaringSpot version token of the last installed airspace file.
    ///
    /// Stored as the raw timestamp string scraped from SoaringSpot at install
    /// time. Null until an airspace file has been installed.
    String? airspaceVersion,

    /// SoaringSpot version token of the last installed waypoints file.
    String? waypointsVersion,

    /// Version token of the last installed task.
    ///
    /// Stored as the downloaded task's generation timestamp string at install
    /// time. Null until a task has been downloaded.
    String? taskVersion,

    /// Scoring email address for this competition's organizers.
    ///
    /// Entered manually by the pilot the first time they send flight logs;
    /// remembered thereafter. Null until first set.
    String? scoringEmail,
  }) = _BookmarkedCompetition;

  /// Computed status based on [startDate], [endDate], and today's date.
  ///
  /// Returns `null` when dates are unavailable.
  CompetitionStatus? get status =>
      CompetitionStatus.of(startDate: startDate, endDate: endDate);
}
