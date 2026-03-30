# Download Latest Task — Issue 1: SoarScore Data Layer

## Feature

Enable the app to fetch the latest task files from soarscore.com for a bookmarked competition. This issue delivers the domain entities, repository interface, use case, remote data source, and tests. No UI and no Kotlin changes.

## Scope

This issue is **data and domain only**. UI is in issue `20260330-04-competition-detail-ui.md`. No changes to existing competitions feature files except the repository interface and impl.

## Dependencies

None. Can be started immediately.

---

## Background

SoarScore publishes XCSoar `.tsk` files for active competitions. The URL pattern is:

```
https://soarscore.com/competitions/{competition_id}/
```

where `competition_id` is the same slug as `BookmarkedCompetition.id` (the SoaringSpot URL slug — e.g. `celje-cup-2020-drzavno-...`).

The Downloads tab (`#Downloads`) of the SoarScore competition page contains `<a download href="...">` links. Each link's flattened inner text matches:

```
{Class} Day{N} Task{M} {description} .tsk generated: {timestamp}
```

Example: `"Club Day6 Task5 AAT 159/361km .tsk generated: 01-07-2020 21:35:04"`

Reference TUI implementation: `/home/dev/openvario-compman/src/compman/soarscore.py`
Fixture HTML files: `/home/dev/openvario-compman/tests/fixtures/soarscore/`
  — copy both `two-classes.html` and `no-tasks.html` to `test/fixtures/`

Read `docs/architecture.md` for layer rules before starting.

---

## Tasks

### 1. Domain entity — `lib/features/competitions/domain/entities/task_info.dart`

Create a `freezed` entity:

```dart
@freezed
class TaskInfo with _$TaskInfo {
  const factory TaskInfo({
    required String compClass,   // e.g. "Club"
    required String title,       // e.g. "AAT 159/361km"
    required int dayNo,
    required int taskNo,
    required String timestamp,   // e.g. "01-07-2020 21:35:04"
    required String taskUrl,     // absolute URL to the .tsk file
  }) = _TaskInfo;
}
```

Run `make codegen` to generate the `.freezed.dart` file.

### 2. Repository interface — `lib/features/competitions/domain/repositories/competitions_repository.dart`

Add two methods:

```dart
/// Fetch available tasks for a competition from SoarScore.
Future<Either<Failure, List<TaskInfo>>> fetchLatestTasks(String competitionId);

/// Download the raw bytes of a .tsk file from [taskUrl].
Future<Either<Failure, Uint8List>> downloadTask(String taskUrl);
```

Import `dart:typed_data` and `task_info.dart`.

### 3. Use cases

`lib/features/competitions/domain/usecases/fetch_latest_tasks.dart`:

```dart
class FetchLatestTasks {
  final CompetitionsRepository _repo;
  const FetchLatestTasks(this._repo);
  Future<Either<Failure, List<TaskInfo>>> call(String competitionId) =>
      _repo.fetchLatestTasks(competitionId);
}
```

`lib/features/competitions/domain/usecases/download_task.dart`:

```dart
class DownloadTask {
  final CompetitionsRepository _repo;
  const DownloadTask(this._repo);
  Future<Either<Failure, Uint8List>> call(String taskUrl) =>
      _repo.downloadTask(taskUrl);
}
```

Add `///` doc comments to all public members.

### 4. Remote data source — `lib/features/competitions/data/datasources/soarscore_remote_datasource.dart`

Abstract interface `SoarScoreRemoteDataSource`:

```dart
abstract class SoarScoreRemoteDataSource {
  Future<List<TaskInfo>> fetchLatestTasks(String competitionId);
  Future<Uint8List> downloadTask(String taskUrl);
}
```

`DioSoarScoreRemoteDataSource` implementing it:

- **`fetchLatestTasks`:** GET `https://soarscore.com/competitions/{competitionId}/`, parse HTML with `package:html/parser.dart`:
  - Selector: `querySelectorAll('#Downloads a[download]')`
  - For each element: `href` attribute (make absolute if relative — prepend `https://soarscore.com`) + `element.text.trim()` as description
  - Parse with static `_parseTaskInfo(String href, String description) → TaskInfo?` using regex:
    ```
    ^(.*)\s+Day(\d+)\s+Task(\d+)\s+(.*)\s+\.tsk generated:\s+(.*)$
    ```  
  - Return only non-null results; skip non-matching entries silently
  - Throw `ServerException` on non-2xx or network error; check `response.statusCode`
- **`downloadTask`:** GET `taskUrl`, `options: Options(responseType: ResponseType.bytes)`, return `Uint8List.fromList(response.data)`; throw `ServerException` on error

`html` package is already in `pubspec.yaml`.

### 5. Repository implementation — `lib/features/competitions/data/repositories/competitions_repository_impl.dart`

Add `_soarScore` field of type `SoarScoreRemoteDataSource` and a constructor parameter for it. Implement:

```dart
@override
Future<Either<Failure, List<TaskInfo>>> fetchLatestTasks(String competitionId) async {
  try {
    return right(await _soarScore.fetchLatestTasks(competitionId));
  } on ServerException catch (e) {
    return left(NetworkFailure(e.message));
  }
}

@override
Future<Either<Failure, Uint8List>> downloadTask(String taskUrl) async {
  try {
    return right(await _soarScore.downloadTask(taskUrl));
  } on ServerException catch (e) {
    return left(NetworkFailure(e.message));
  }
}
```

### 6. DI — `lib/core/di/providers.dart`

Add:
- `soarScoreRemoteDataSourceProvider` → `DioSoarScoreRemoteDataSource(ref.read(dioProvider))`
- Update `competitionsRepositoryProvider` to pass the new data source
- `fetchLatestTasksProvider` → `FetchLatestTasks(ref.read(competitionsRepositoryProvider))`
- `downloadTaskProvider` → `DownloadTask(ref.read(competitionsRepositoryProvider))`

### 7. Test fixture files

Copy:
- `/home/dev/openvario-compman/tests/fixtures/soarscore/two-classes.html` → `test/fixtures/soarscore_competition.html`
- `/home/dev/openvario-compman/tests/fixtures/soarscore/no-tasks.html` → `test/fixtures/soarscore_no_tasks.html`

### 8. Tests

`test/features/competitions/data/datasources/soarscore_remote_datasource_test.dart`:
- Two-classes fixture: mock Dio GET returning fixture HTML; assert 2 tasks, class names `"Club"` and `"Open"`, `dayNo == 6`, `taskNo == 5`, `timestamp == "01-07-2020 21:35:04"`, `taskUrl` starts with `http`
- No-tasks fixture: assert empty list returned
- HTTP error (statusCode 500): assert `ServerException` thrown

`test/features/competitions/domain/usecases/fetch_latest_tasks_test.dart`:
- Happy path: `Right(List<TaskInfo>)` from mocked repository
- Error path: `Left(NetworkFailure)` from mocked repository

`test/features/competitions/domain/usecases/download_task_test.dart`:
- Happy path: `Right(Uint8List)` from mocked repository
- Error path: `Left(NetworkFailure)` from mocked repository

### 9. API doc — `docs/api/soarscore.md`

Create documenting:
- Base URL and competition page URL pattern
- How `competition_id` maps to the SoaringSpot slug (`BookmarkedCompetition.id`)
- CSS selector pattern for download links (`#Downloads a[download]`)
- Task description regex and the fields captured
- `.tsk` file format (XCSoar XML, downloaded verbatim, written as `Default.tsk`)
- Known caveats: SoarScore may have no page for a competition; no-tasks state is normal during off-season

---

## Acceptance Criteria

1. `make codegen` succeeds; `task_info.freezed.dart` generated.
2. `flutter analyze` passes.
3. `flutter test` passes — all new tests green.
4. `CompetitionsRepository` has `fetchLatestTasks` and `downloadTask`.
5. `DioSoarScoreRemoteDataSource` parses 2 tasks from `soarscore_competition.html` fixture.
6. `docs/api/soarscore.md` exists.
7. `docs/plan.md` updated.
