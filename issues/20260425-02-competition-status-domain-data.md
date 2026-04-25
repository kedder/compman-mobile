# Add CompetitionStatus Enum and Enrich Competition Entities

## Feature summary

The design screens in `docs/design/` show Live/Upcoming/Past status badges on both the
home screen (bookmarked competitions) and the Add Competition screen. Status must be
**computed on the fly** from the competition's start/end dates and the current clock —
never stored. This issue adds `startDate`/`endDate` fields to both domain entities so
status can be derived anywhere without persisting it.

## Scope

Domain entities, data models, Hive adapter codegen, and the SoaringSpot scraper.
No presentation-layer files change in this issue.

---

## Task

Read these files before starting:

- `lib/features/competitions/domain/entities/competition.dart`
- `lib/features/competitions/domain/entities/bookmarked_competition.dart`
- `lib/features/competitions/data/models/competition_model.dart`
- `lib/features/competitions/data/models/bookmarked_competition_model.dart`
- `lib/features/competitions/data/datasources/soaringspot_remote_datasource.dart`
- `test/fixtures/soaringspot_home.html` — understand the HTML structure being parsed

---

### 1 — Add `CompetitionStatus` enum

Create `lib/features/competitions/domain/entities/competition_status.dart`:

```dart
/// Computed status of a gliding competition relative to the current date.
///
/// Never stored — always derived by calling [CompetitionStatus.of].
enum CompetitionStatus {
  /// Competition is currently in progress.
  live,

  /// Competition has not yet started.
  upcoming,

  /// Competition has ended.
  past;

  /// Computes status from [startDate] and [endDate] relative to [now].
  ///
  /// Returns `null` if either date is null (dates could not be parsed).
  static CompetitionStatus? of({
    required DateTime? startDate,
    required DateTime? endDate,
    DateTime? now,
  }) {
    if (startDate == null || endDate == null) return null;
    final today = (now ?? DateTime.now()).toLocal();
    final start = startDate.toLocal();
    final end = endDate.toLocal();
    if (today.isBefore(start)) return CompetitionStatus.upcoming;
    if (today.isAfter(end)) return CompetitionStatus.past;
    return CompetitionStatus.live;
  }
}
```

---

### 2 — Add `startDate` / `endDate` to `Competition` entity

In `lib/features/competitions/domain/entities/competition.dart`, add two nullable
`DateTime` fields. Do **not** add a `status` field:

```dart
@freezed
class Competition with _$Competition {
  const factory Competition({
    required String id,
    required String title,
    required String url,
    required String description,
    DateTime? startDate,
    DateTime? endDate,
  }) = _Competition;
}
```

Add a convenience getter using a `const Competition._()` private constructor:

```dart
// inside the class body (requires adding `const Competition._();`)
/// Computed status based on [startDate], [endDate], and today's date.
/// Returns `null` when dates are unavailable.
CompetitionStatus? get status => CompetitionStatus.of(
      startDate: startDate,
      endDate: endDate,
    );
```

Run `make codegen` to regenerate `competition.freezed.dart`.

---

### 3 — Parse dates in `CompetitionModel`

The SoaringSpot `.info > span` text contains dates in the format:
`"21 March 2026 – 24 March 2026"` (en-dash `\u2013` as separator, preceded by the
`fa-calendar` icon text which is typically empty).

In `CompetitionModel.fromElement()`, extract the info span text, split on `–` (en-dash),
and parse each side using `DateFormat('d MMMM yyyy', 'en')` from `intl`
(already a transitive dependency — check `pubspec.lock`; add `intl: ^0.20.0` to
`pubspec.yaml` if not present).

```dart
// Example parsing helper (add as a private static method):
static DateTime? _parseDate(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  try {
    return DateFormat('d MMMM yyyy', 'en_US').parse(trimmed);
  } catch (_) {
    return null;
  }
}
```

The info span text also contains `fa-calendar` icon characters and location text
before the dates. A reliable extraction strategy: find the `–` separator, take
the right portion as `endDate`, then scan backwards from the `–` to find the
start date by matching `d MMMM yyyy`. Alternatively, split by `–`, trim each
half, and attempt to parse the last space-delimited words as `d MMMM yyyy`.

Update `toEntity()` to include `startDate` and `endDate`.

---

### 4 — Enrich `BookmarkedCompetition` with date fields

In `lib/features/competitions/domain/entities/bookmarked_competition.dart`, add
`startDate` and `endDate`. Do **not** add a `status` field:

```dart
@freezed
class BookmarkedCompetition with _$BookmarkedCompetition {
  const factory BookmarkedCompetition({
    required String id,
    required String title,
    required String soaringspotUrl,
    required DateTime bookmarkedAt,
    String? selectedClass,
    // Display fields — nullable for backward compat with old persisted data
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) = _BookmarkedCompetition;

  const BookmarkedCompetition._();

  /// Computed status based on [startDate], [endDate], and today's date.
  CompetitionStatus? get status => CompetitionStatus.of(
        startDate: startDate,
        endDate: endDate,
      );
}
```

Run `make codegen` to regenerate `bookmarked_competition.freezed.dart` and the Hive
adapter in `bookmarked_competition_model.g.dart`. Hive will store `startDate` and
`endDate` as `DateTime` (already a supported Hive type).

---

### 5 — Populate new fields when saving bookmarks

Find where `BookmarkedCompetition` objects are created when the user adds bookmarks
(likely in a use case or the bookmarks notifier). Pass `description`, `startDate`, and
`endDate` from the source `Competition` object at the point of creation.

---

### 6 — Tests

- Add/update the `CompetitionModel` unit test:
  - Assert that `startDate` and `endDate` are parsed correctly from a sample fixture.
  - Assert that `status` returns `live`, `upcoming`, or `past` based on a mock `now`.
- Add unit tests for `CompetitionStatus.of`:
  - `now` between start and end → `live`
  - `now` before start → `upcoming`
  - `now` after end → `past`
  - null dates → null
- Update the `BookmarkedCompetition` repository test fixture to include the new fields.

---

## Completion condition

`make codegen` completes without errors. `make test` passes. A `Competition` deserialized
from the scraper carries non-null `startDate` / `endDate` for competitions where the HTML
contains a date range. `competition.status` returns the correct value for a known fixture
date. A newly saved `BookmarkedCompetition` carries `description`, `startDate`, and
`endDate` from the source competition, and `.status` computes correctly without
persisting it.
