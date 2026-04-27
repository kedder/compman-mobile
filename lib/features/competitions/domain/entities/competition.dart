import 'package:freezed_annotation/freezed_annotation.dart';

import 'competition_status.dart';

part 'competition.freezed.dart';

/// Represents a competition fetched from SoaringSpot.
///
/// [id] is the URL slug (e.g. `"barron-2024"`).
/// [description] contains dates and location as a human-readable string.
@freezed
abstract class Competition with _$Competition {
  const Competition._();

  /// Creates an immutable [Competition].
  const factory Competition({
    required String id,
    required String title,
    required String url,
    required String description,
    DateTime? startDate,
    DateTime? endDate,
  }) = _Competition;

  /// Computed status based on [startDate], [endDate], and today's date.
  ///
  /// Returns `null` when dates are unavailable.
  CompetitionStatus? get status =>
      CompetitionStatus.of(startDate: startDate, endDate: endDate);
}
