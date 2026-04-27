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
  }) = _BookmarkedCompetition;

  /// Computed status based on [startDate], [endDate], and today's date.
  ///
  /// Returns `null` when dates are unavailable.
  CompetitionStatus? get status =>
      CompetitionStatus.of(startDate: startDate, endDate: endDate);
}
