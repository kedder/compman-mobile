import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/bookmarked_competition.dart';

part 'bookmarked_competition_model.g.dart';

/// Hive-persisted representation of a [BookmarkedCompetition].
///
/// The [typeId] is 0 — do not reuse this value for other adapters.
@HiveType(typeId: 0)
class BookmarkedCompetitionModel {
  /// SoaringSpot competition slug used as storage key.
  @HiveField(0)
  final String id;

  /// Human-readable competition title.
  @HiveField(1)
  final String title;

  /// Full SoaringSpot URL for the competition.
  @HiveField(2)
  final String soaringspotUrl;

  /// Timestamp when the user bookmarked this competition.
  @HiveField(3)
  final DateTime bookmarkedAt;

  /// The competition class the user has selected (e.g. "Club", "Open").
  @HiveField(4)
  final String? selectedClass;

  /// Creates a [BookmarkedCompetitionModel].
  BookmarkedCompetitionModel({
    required this.id,
    required this.title,
    required this.soaringspotUrl,
    required this.bookmarkedAt,
    this.selectedClass,
  });

  /// Converts this model to the domain [BookmarkedCompetition] entity.
  BookmarkedCompetition toEntity() => BookmarkedCompetition(
        id: id,
        title: title,
        soaringspotUrl: soaringspotUrl,
        bookmarkedAt: bookmarkedAt,
        selectedClass: selectedClass,
      );

  /// Creates a [BookmarkedCompetitionModel] from a domain [BookmarkedCompetition].
  factory BookmarkedCompetitionModel.fromEntity(BookmarkedCompetition entity) =>
      BookmarkedCompetitionModel(
        id: entity.id,
        title: entity.title,
        soaringspotUrl: entity.soaringspotUrl,
        bookmarkedAt: entity.bookmarkedAt,
        selectedClass: entity.selectedClass,
      );
}
