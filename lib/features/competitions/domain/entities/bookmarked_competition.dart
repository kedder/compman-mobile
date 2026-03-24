import 'package:freezed_annotation/freezed_annotation.dart';

part 'bookmarked_competition.freezed.dart';

/// Represents a competition that the user has bookmarked.
///
/// Persisted locally via Hive. [bookmarkedAt] records when the bookmark was added.
@freezed
class BookmarkedCompetition with _$BookmarkedCompetition {
  /// Creates an immutable [BookmarkedCompetition].
  const factory BookmarkedCompetition({
    required String id,
    required String title,
    required String soaringspotUrl,
    required DateTime bookmarkedAt,
  }) = _BookmarkedCompetition;
}
