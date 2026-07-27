import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../../domain/entities/bookmarked_competition.dart';

part 'bookmarked_competition_model.freezed.dart';
part 'bookmarked_competition_model.g.dart';

/// Hive-persisted representation of a [BookmarkedCompetition].
///
/// The [typeId] is 0 — do not reuse this value for other adapters.
@freezed
@HiveType(typeId: 0)
abstract class BookmarkedCompetitionModel with _$BookmarkedCompetitionModel {
  const BookmarkedCompetitionModel._();

  /// Creates a [BookmarkedCompetitionModel].
  const factory BookmarkedCompetitionModel({
    /// SoaringSpot competition slug used as storage key.
    @HiveField(0) required String id,

    /// Human-readable competition title.
    @HiveField(1) required String title,

    /// Full SoaringSpot URL for the competition.
    @HiveField(2) required String soaringspotUrl,

    /// Timestamp when the user bookmarked this competition.
    @HiveField(3) required DateTime bookmarkedAt,

    /// The competition class the user has selected (e.g. "Club", "Open").
    @HiveField(4) String? selectedClass,

    /// Competition listing description used for bookmark display.
    @HiveField(5) String? description,

    /// Competition start date parsed from the SoaringSpot listing.
    @HiveField(6) DateTime? startDate,

    /// Competition end date parsed from the SoaringSpot listing.
    @HiveField(7) DateTime? endDate,

    /// SoaringSpot version token of the last installed airspace file.
    ///
    /// Stored as the raw timestamp string scraped from SoaringSpot at install
    /// time. Null until an airspace file has been installed.
    /// Old records without this field deserialise with null.
    @HiveField(8) String? airspaceVersion,

    /// SoaringSpot version token of the last installed waypoints file.
    ///
    /// Old records without this field deserialise with null.
    @HiveField(9) String? waypointsVersion,

    /// Version token of the last installed task.
    ///
    /// Old records without this field deserialise with null.
    @HiveField(10) String? taskVersion,

    /// Scoring email address for this competition's organizers.
    ///
    /// Old records without this field deserialise with null.
    @HiveField(11) String? scoringEmail,
  }) = _BookmarkedCompetitionModel;

  /// Converts this model to the domain [BookmarkedCompetition] entity.
  BookmarkedCompetition toEntity() => BookmarkedCompetition(
    id: id,
    title: title,
    soaringspotUrl: soaringspotUrl,
    bookmarkedAt: bookmarkedAt,
    selectedClass: selectedClass,
    description: description,
    startDate: startDate,
    endDate: endDate,
    airspaceVersion: airspaceVersion,
    waypointsVersion: waypointsVersion,
    taskVersion: taskVersion,
    scoringEmail: scoringEmail,
  );

  /// Creates a [BookmarkedCompetitionModel] from a domain [BookmarkedCompetition].
  factory BookmarkedCompetitionModel.fromEntity(BookmarkedCompetition entity) =>
      BookmarkedCompetitionModel(
        id: entity.id,
        title: entity.title,
        soaringspotUrl: entity.soaringspotUrl,
        bookmarkedAt: entity.bookmarkedAt,
        selectedClass: entity.selectedClass,
        description: entity.description,
        startDate: entity.startDate,
        endDate: entity.endDate,
        airspaceVersion: entity.airspaceVersion,
        waypointsVersion: entity.waypointsVersion,
        taskVersion: entity.taskVersion,
        scoringEmail: entity.scoringEmail,
      );
}
