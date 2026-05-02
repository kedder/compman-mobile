# Airspace & Waypoints — Domain and Data Layer

User story: `2026-05-01-waypoints-airspaces.md`

## Feature summary

Pilots need to download airspace (.txt) and waypoint (.cup) files from a
competition's SoaringSpot downloads page. This issue implements the full
domain and data stack for that feature: scraping the downloads page, a new
`DownloadableFileInfo` entity, repository methods, use cases, and local
tracking of install timestamps (for the "NEW UPDATE" badge).

## Scope

This issue covers only the **domain and data layers**. No UI code. The
presentation issue (`20260501-03-…`) depends on this one being merged first.

---

## Background: SoaringSpot downloads page

The SoaringSpot downloads page URL is `{competition_url}/downloads` (strip any
trailing slash from the competition URL first).

Before implementing, fetch a real downloads page (e.g.
`https://www.soaringspot.com/en_gb/wgc2018pl/downloads`) and commit an HTML
fixture to `test/fixtures/soaringspot_downloads.html`. The reference Python
implementation in
`/home/andrey/projects/openvario/openvario-compman/src/compman/soaringspot.py`
(`fetch_downloads`) does **not** capture a publish timestamp — the Python
version only checks whether a file is already present. The mobile version
**must** also capture the file's last-published timestamp for the badge logic.
Inspect the real HTML to determine the selector for that timestamp and document
it in `docs/api/soaringspot.md`.

### Known HTML structure (basic)

The existing `docs/api/soaringspot.md` documents a simplified form:

```html
<ul class="contest-downloads">
  <li><a href="/downloads/barron-2024/airspace.txt">airspace.txt</a></li>
  <li><a href="/downloads/barron-2024/waypoints.cup">waypoints.cup</a></li>
</ul>
```

The real page almost certainly contains additional elements with a last-modified
or published timestamp. Fetch the live page to confirm the selector, then
document it and implement accordingly. If no timestamp is present in the HTML,
record `null` for `publishedAt` and the "NEW UPDATE" badge will never fire
(acceptable graceful degradation).

### File classification

| Extension | Kind |
|---|---|
| `.txt` | airspace |
| `.cup` | waypoints |

Entries with any other extension are ignored.

---

## Tasks

### 1. Domain entity: `DownloadableFileInfo`

Create
`lib/features/competitions/domain/entities/downloadable_file_info.dart`.

```dart
/// Represents a downloadable file (airspace or waypoints) listed on the
/// SoaringSpot competition downloads page.
@freezed
abstract class DownloadableFileInfo with _$DownloadableFileInfo {
  const factory DownloadableFileInfo({
    /// Original filename on SoaringSpot (e.g. `"germany_2026.txt"`).
    required String filename,

    /// Absolute download URL.
    required String downloadUrl,

    /// File kind — airspace (.txt) or waypoints (.cup).
    required DownloadableFileKind kind,

    /// File size in bytes, if advertised in the HTML. Null when not present.
    int? fileSize,

    /// Raw modification timestamp string scraped from SoaringSpot (e.g.
    /// `"19/04/2026, 12:53"`). Treated as an opaque version token — never
    /// parsed into a [DateTime]. Null when the HTML carries no timestamp.
    ///
    /// **Why String, not DateTime?** Parsing the timestamp into a DateTime
    /// would require knowing the server's timezone, which SoaringSpot does
    /// not advertise in the HTML. Comparing parsed datetimes across timezones
    /// risks false positives or missed badges. Storing the raw string and
    /// comparing for equality avoids that entirely: the badge fires when the
    /// scraped string differs from the string stored at last install,
    /// regardless of what the string represents as a point in time.
    String? publishedVersion,
  }) = _DownloadableFileInfo;
}

/// Distinguishes airspace from waypoint files.
enum DownloadableFileKind { airspace, waypoints }
```

Run `make codegen` after creating the file.

### 2. Repository interface additions

Add two methods to
`lib/features/competitions/domain/repositories/competitions_repository.dart`:

```dart
/// Fetches the list of downloadable airspace and waypoint files from the
/// SoaringSpot downloads page for the competition identified by
/// [competitionId].
///
/// Looks up [competitionId] in local bookmarks to obtain the SoaringSpot URL.
/// Returns an empty list (not a failure) if no relevant files are found.
Future<Either<Failure, List<DownloadableFileInfo>>> fetchDownloads(
  String competitionId,
);

/// Downloads the raw bytes of an airspace or waypoint file from [fileUrl].
Future<Either<Failure, Uint8List>> downloadFile(String fileUrl);
```

### 3. New use cases

Create in `lib/features/competitions/domain/usecases/`:

**`fetch_downloads.dart`** — calls `repository.fetchDownloads(competitionId)`.

**`download_file.dart`** — calls `repository.downloadFile(fileUrl)`.

Both follow the same pattern as the existing `FetchLatestTasks` and
`DownloadTask` use cases.

### 4. Scraper: `fetchDownloads` on `SoaringSpotRemoteDataSource`

Add to the abstract class and its implementation
(`lib/features/competitions/data/datasources/soaringspot_remote_datasource.dart`):

```dart
/// Fetches downloadable files listed on `{competitionUrl}/downloads`.
///
/// Returns only `.txt` (airspace) and `.cup` (waypoints) entries.
/// Throws [ServerException] on network errors.
Future<List<DownloadableFileInfo>> fetchDownloads(String competitionUrl);
```

Implementation steps:
1. Build URL: `'${competitionUrl.trimRight('/')}/downloads'`.
2. `GET` the page via `dio`.
3. Parse with the `html` package.
4. Find `ul.contest-downloads li a` anchors.
5. For each anchor:
   - Extract `filename` from anchor text content (trimmed).
   - Extract `href`; prefix with `https://www.soaringspot.com` if relative.
   - Determine `kind` from extension (`.txt` → airspace, `.cup` → waypoints).
   - Extract `fileSize` in bytes if the HTML contains size text (may be `null`).
   - Extract `publishedVersion` as a raw trimmed string using whatever timestamp
     selector you find in the real HTML (may be `null`).
   - Skip entries with unknown extensions.
6. Return the filtered list.

### 5. Repository implementation: wire `fetchDownloads` and `downloadFile`

In `lib/features/competitions/data/repositories/competitions_repository_impl.dart`:

- `fetchDownloads`: look up the competition's SoaringSpot URL from local
  storage, call `remote.fetchDownloads(url)`, wrap exceptions in `Failure`.
  Return `Right([])` if the competition is not bookmarked.
- `downloadFile`: call the Dio client directly (or delegate to a simple helper
  on `SoaringSpotRemoteDataSource`) to `GET` the file URL and return the raw
  bytes as `Uint8List`. Wrap `DioException` in `NetworkFailure`.

### 6. Local timestamp tracking

The "NEW UPDATE" badge requires knowing when the airspace/waypoints file was
last installed on this device. Store that as a `DateTime?` in
`BookmarkedCompetitionModel`.

Add two new `@HiveField` entries to
`lib/features/competitions/data/models/bookmarked_competition_model.dart`:

```dart
/// SoaringSpot version token of the last installed airspace file.
///
/// Stored as the raw timestamp string scraped from SoaringSpot at install
/// time (see [DownloadableFileInfo.publishedVersion]). Null until an airspace
/// file has been installed.
@HiveField(8)
final String? airspaceVersion;

/// SoaringSpot version token of the last installed waypoints file.
@HiveField(9)
final String? waypointsVersion;
```

Propagate through `toEntity()` and `fromEntity()`. Add the same two optional
fields to the `BookmarkedCompetition` freezed entity. Old Hive records without
these fields deserialise with both as `null`.

Add a new repository method (interface + impl) to update these timestamps:

```dart
/// Records the installed version token for an airspace or waypoints file.
///
/// [version] is the raw [DownloadableFileInfo.publishedVersion] string
/// captured at install time. [kind] determines which field to update.
Future<Either<Failure, Unit>> recordFileInstall(
  String competitionId,
  DownloadableFileKind kind,
  String? version,
);
```

Add a corresponding use case `RecordFileInstall`.

Run `make codegen` after modifying the model.

### 7. DI wiring

In `lib/core/di/providers.dart`, add Riverpod providers for the two new use
cases (`FetchDownloads`, `DownloadFile`, `RecordFileInstall`), following the
same pattern as `fetchLatestTasksProvider` and `downloadTaskProvider`.

### 8. Update `docs/api/soaringspot.md`

In the **Competition Downloads** section, update the HTML structure
documentation to reflect what you actually found in the live page (including
the timestamp element and its selector). Document the `fileSize` extraction
approach and the `publishedAt` parsing logic.

---

## Tests

### Unit tests required

**`test/features/competitions/data/soaringspot_remote_datasource_downloads_test.dart`**

Add a fixture `test/fixtures/soaringspot_downloads.html` (committed snapshot of
a real downloads page, same approach as `soaringspot_home.html`).

Write tests:
- Parses one airspace file and one waypoints file from the fixture.
- Returns an empty list when no `ul.contest-downloads` is found (e.g. no
  downloads page).
- Throws `ServerException` on network error.
- Correctly extracts `publishedVersion` as a raw string (or `null` if not present in the HTML).

**`test/features/competitions/domain/fetch_downloads_test.dart`**

- `call` delegates to `repository.fetchDownloads(id)` and returns the result.
- `Left` propagates as-is.

**`test/features/competitions/domain/download_file_test.dart`**

- `call` delegates to `repository.downloadFile(url)` and returns the bytes.
- `Left` propagates as-is.

**`test/features/competitions/domain/record_file_install_test.dart`**

- `call` delegates to `repository.recordFileInstall(...)`.

**`test/features/competitions/data/competitions_repository_impl_test.dart`**

Add test groups for:
- `fetchDownloads` — returns Right on success, NetworkFailure on
  ServerException, returns Right([]) when competition not found.
- `downloadFile` — returns Right(bytes) on success, NetworkFailure on error.
- `recordFileInstall` — updates airspace or waypoints timestamp; returns
  StorageFailure when competition not bookmarked.

**Update mock file**

`test/features/competitions/data/mock_datasources.dart` — add
`fetchDownloads(String)` and `downloadFile(String)` to the
`MockSoaringSpotRemoteDataSource` annotation.

`test/features/competitions/domain/mock_competitions_repository.dart` — add the
three new repository methods.

---

## Acceptance criteria

- `make codegen` completes without errors.
- `make format` reports no changes.
- `make test` passes with no failures.
- `make analyze` reports no issues.
- `DownloadableFileInfo` entity exists and is immutable (freezed).
- `fetchDownloads(competitionId)` correctly returns a list for a known
  competition and `Right([])` for an unknown one.
- `downloadFile(url)` returns raw bytes.
- `recordFileInstall` persists the version string and is readable back through
  `getById` / `toEntity`.
- `BookmarkedCompetitionModel` HiveFields 8 and 9 are present; old records
  without them deserialise cleanly.
- `docs/api/soaringspot.md` is updated with the real downloads-page HTML
  structure.
- `docs/plan.md` has a new 📋 item for this feature under Phase 2, or marks an
  existing entry ✅ if appropriate.

## Constraints

- `domain` must not import from `data`.
- Use `freezed` for `DownloadableFileInfo`.
- Follow the commit message format from `AGENTS.md`, including the issue
  filename trailer.
