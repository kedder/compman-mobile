import 'package:freezed_annotation/freezed_annotation.dart';

part 'competition.freezed.dart';

/// Represents a competition fetched from SoaringSpot.
///
/// [id] is the URL slug (e.g. `"barron-2024"`).
/// [description] contains dates and location as a human-readable string.
@freezed
class Competition with _$Competition {
  /// Creates an immutable [Competition].
  const factory Competition({
    required String id,
    required String title,
    required String url,
    required String description,
  }) = _Competition;
}
