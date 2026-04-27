/// Computed status of a gliding competition relative to the current date.
///
/// Never stored. Always derived from the competition date range.
enum CompetitionStatus {
  /// Competition is currently in progress.
  live,

  /// Competition has not yet started.
  upcoming,

  /// Competition has ended.
  past;

  /// Computes the status from [startDate] and [endDate] relative to [now].
  ///
  /// Returns `null` when either date is unavailable.
  static CompetitionStatus? of({
    required DateTime? startDate,
    required DateTime? endDate,
    DateTime? now,
  }) {
    if (startDate == null || endDate == null) {
      return null;
    }

    final today = _dateOnly((now ?? DateTime.now()).toLocal());
    final start = _dateOnly(startDate.toLocal());
    final end = _dateOnly(endDate.toLocal());

    if (today.isBefore(start)) {
      return CompetitionStatus.upcoming;
    }
    if (today.isAfter(end)) {
      return CompetitionStatus.past;
    }
    return CompetitionStatus.live;
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
