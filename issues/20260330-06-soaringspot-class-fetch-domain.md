# Competition Classes from SoaringSpot — Issue 6a: Data + Domain Layer

## Problem

The `_ClassPicker` widget derives available competition classes from SoarScore
task data. SoarScore publishes no tasks before or between contest days, so the
picker is empty whenever tasks haven't been published yet. The user cannot
pre-configure their class.

The fix is to fetch classes from a different source: the SoaringSpot
competition results page (`{soaringspot_url}/results`), which lists classes as
column headers in a `<table class="result-overview">` even before any tasks
exist.

This issue covers the **data and domain layers only** (tasks 1–4). The
presentation layer is handled in issue `20260330-07-soaringspot-class-fetch-presentation.md`,
which depends on this issue being done first.

## Reference

TUI implementation: `/home/dev/openvario-compman/src/compman/soaringspot.py`,
`fetch_classes()`:

```python
async def fetch_classes(comp_url: str) -> List[str]:
    results_url = f"{_sanitize_url(comp_url)}/results"
    # ... HTTP GET ...
    headers = root.xpath("//table[@class='result-overview']/thead/tr/th")
    for hdrel in headers:
        classes.append(_extract_text([hdrel]))
    return classes
```

Expected HTML structure (documented in `docs/api/soaringspot.md`, Competition
Classes section):

```html
<table class="result-overview">
  <thead>
    <tr>
      <th>Standard</th>
      <th>Club</th>
    </tr>
  </thead>
</table>
```

Dart CSS selector: `table.result-overview thead th`

## Files to Read First

- `CLAUDE.md` — project rules and architecture dependency rule
- `docs/api/soaringspot.md` — scraping conventions; update the Competition
  Classes section on completion
- `lib/features/competitions/data/datasources/soaringspot_remote_datasource.dart`
  — existing scraping pattern to follow
- `lib/features/competitions/domain/repositories/competitions_repository.dart`
  — interface to extend
- `lib/features/competitions/data/repositories/competitions_repository_impl.dart`
  — implementation to extend
- `lib/core/di/providers.dart` — where to add the new use-case provider

---

## Task 1 — Data source

In `lib/features/competitions/data/datasources/soaringspot_remote_datasource.dart`:

Add to the abstract class:

```dart
/// Fetches the competition class names from the SoaringSpot results page.
///
/// Scrapes `{competitionUrl}/results` for `table.result-overview thead th`
/// elements. Returns an empty list if no table is found.
/// Throws [ServerException] on network errors.
Future<List<String>> fetchClasses(String competitionUrl);
```

Add the implementation to `SoaringSpotRemoteDataSourceImpl`:

```dart
@override
Future<List<String>> fetchClasses(String competitionUrl) async {
  final url = '${competitionUrl.trimRight('/')}/results';
  try {
    final response = await dio.get<String>(url);
    final document = html_parser.parse(response.data ?? '');
    return document
        .querySelectorAll('table.result-overview thead th')
        .map((e) => e.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  } on DioException catch (e) {
    throw ServerException(e.message ?? 'Network error');
  }
}
```

## Task 2 — Repository interface

In `lib/features/competitions/domain/repositories/competitions_repository.dart`,
add:

```dart
/// Fetches the list of competition class names for a bookmarked competition.
///
/// Looks up [competitionId] in local storage to get its SoaringSpot URL,
/// then scrapes the `/results` page for class names.
/// Returns an empty list (not a failure) if no classes are found.
Future<Either<Failure, List<String>>> fetchCompetitionClasses(
    String competitionId);
```

## Task 3 — Repository implementation

In `lib/features/competitions/data/repositories/competitions_repository_impl.dart`,
implement the method:

1. Call `local.getAll()` to find the bookmarked competition with matching ID
   and read its `soaringspotUrl`.
2. If not found or `soaringspotUrl` is empty, return `Right([])`.
3. Call `remote.fetchClasses(soaringspotUrl)`.
4. Map `ServerException` → `NetworkFailure`, `ParseException` → `ParseFailure`.

## Task 4 — Use case + DI provider

Create `lib/features/competitions/domain/usecases/fetch_competition_classes.dart`:

```dart
/// Returns the list of competition class names scraped from SoaringSpot.
///
/// Returns an empty list (not a failure) when the competition page has no
/// results table — this is normal before the competition begins.
class FetchCompetitionClasses {
  final CompetitionsRepository _repo;
  const FetchCompetitionClasses(this._repo);

  Future<Either<Failure, List<String>>> call(String competitionId) =>
      _repo.fetchCompetitionClasses(competitionId);
}
```

In `lib/core/di/providers.dart`, add a Riverpod provider following the same
pattern as `fetchLatestTasksProvider`.

---

## Tests Required

### Data source unit tests

Add to the existing SoaringSpot datasource test (or a new file at
`test/features/competitions/data/datasources/soaringspot_remote_datasource_test.dart`):

- `fetchClasses` parses two class names from valid fixture HTML.
- `fetchClasses` returns an empty list when the `result-overview` table is absent.
- `fetchClasses` throws `ServerException` on `DioException`.

Fixture HTML (inline string is fine):

```html
<html><body>
<table class="result-overview">
  <thead><tr><th>Standard</th><th>Club</th></tr></thead>
</table>
</body></html>
```

### Use case unit test

`test/features/competitions/domain/usecases/fetch_competition_classes_test.dart`:

- Returns `Right(['Standard', 'Club'])` when repository succeeds.
- Returns `Left(NetworkFailure(...))` when repository fails.

### Repository implementation unit test

Add to the existing repository impl test:

- `fetchCompetitionClasses` calls `remote.fetchClasses` with the correct URL.
- Returns `Right([])` when the competition ID is not bookmarked.

---

## Acceptance Criteria

1. `flutter analyze` passes with no new warnings.
2. `flutter test` passes — all existing tests green, new tests green.
3. `docs/api/soaringspot.md` Competition Classes section updated: remove
   "Phase 4 planned" note, describe the actual selector and URL pattern.
4. `docs/plan.md` updated to note this layer as done.
