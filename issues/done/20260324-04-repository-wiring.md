# Session 5 — Repository Wiring + DI

> **Depends on:** completion of both `20260324-02-local-data-layer.md` and `20260324-03-remote-data-layer.md`

## Feature

We are implementing **bookmarked competitions management** — the core MVP feature of Compman Mobile. Users can browse gliding competitions fetched from SoaringSpot, bookmark the ones they plan to attend, and manage that list from a home screen.

**This session** wires the two data sources (remote scraper and local Hive storage) together behind the `CompetitionsRepository` interface, and registers all dependencies in the Riverpod DI graph.

## Context

Read these files before starting:
- `CLAUDE.md` — project rules, architecture dependency rule, test and doc requirements
- `docs/features/competitions.md` — repository interface and data flow
- `lib/features/competitions/domain/repositories/competitions_repository.dart` — the interface to implement
- `lib/features/competitions/data/datasources/competitions_local_datasource.dart` — from Session 3
- `lib/features/competitions/data/datasources/soaringspot_remote_datasource.dart` — from Session 4
- `lib/core/error/failures.dart` — `NetworkFailure`, `ParseFailure`, `StorageFailure`
- `lib/core/di/providers.dart` — existing Riverpod providers to extend

Sessions 3 and 4 must be complete before this session.

## Tasks

### Repository implementation

1. **`lib/features/competitions/data/repositories/competitions_repository_impl.dart`**:
   - Class `CompetitionsRepositoryImpl` implementing `CompetitionsRepository`
   - Constructor receives `SoaringSpotRemoteDataSource remote` and `CompetitionsLocalDataSource local`
   - Implement all 4 methods:

     **`fetchCompetitions()`**
     - Calls `remote.fetchCompetitions()`
     - Maps `List<CompetitionModel>` → `List<Competition>` via `toEntity()`
     - Catches `ServerException` → returns `Left(NetworkFailure(e.message))`
     - Catches `ParseException` → returns `Left(ParseFailure(e.message))`
     - On success → returns `Right(competitions)`

     **`getBookmarkedCompetitions()`**
     - Calls `local.getAll()`
     - Maps models to entities via `toEntity()`
     - Catches any exception → returns `Left(StorageFailure(e.toString()))`
     - On success → returns `Right(bookmarks)`

     **`bookmarkCompetition(Competition competition)`**
     - Creates a `BookmarkedCompetitionModel` from the competition (`bookmarkedAt: DateTime.now()`)
     - Calls `local.save(model)`
     - Catches any exception → returns `Left(StorageFailure(...))`
     - On success → returns `Right(unit)`

     **`removeBookmark(String competitionId)`**
     - Calls `local.delete(competitionId)`
     - Catches any exception → returns `Left(StorageFailure(...))`
     - On success → returns `Right(unit)`

### DI wiring

2. **Update `lib/core/di/providers.dart`**:
   - Add providers for:
     - `soaringSpotRemoteDataSourceProvider` — provides `SoaringSpotRemoteDataSourceImpl(ref.watch(dioProvider))`
     - `competitionsLocalDataSourceProvider` — provides `HiveCompetitionsLocalDataSource(ref.watch(hiveBoxProvider))`
     - `competitionsRepositoryProvider` — provides `CompetitionsRepositoryImpl(remote, local)`
   - All providers should use `Provider<T>` (not `StateProvider` or `FutureProvider`) since they are synchronous dependencies

### Documentation

3. **Update `docs/plan.md`** — mark the following Phase 1 tasks as ✅:
   - "Repository impl"

## Tests

Write unit tests in `test/features/competitions/data/`:

- **`competitions_repository_impl_test.dart`**:
  - Mock both `SoaringSpotRemoteDataSource` and `CompetitionsLocalDataSource` using `mockito`
  - Test `fetchCompetitions()`:
    - Happy path: remote returns models → returns `Right(List<Competition>)`
    - `ServerException` → returns `Left(NetworkFailure(...))`
    - `ParseException` → returns `Left(ParseFailure(...))`
  - Test `getBookmarkedCompetitions()`:
    - Happy path: local returns models → returns `Right(List<BookmarkedCompetition>)`
    - Exception from local → returns `Left(StorageFailure(...))`
  - Test `bookmarkCompetition()`:
    - Happy path → `local.save()` called, returns `Right(unit)`
    - Exception → returns `Left(StorageFailure(...))`
  - Test `removeBookmark()`:
    - Happy path → `local.delete()` called with correct id, returns `Right(unit)`
    - Exception → returns `Left(StorageFailure(...))`

- Run `flutter test` — all tests must pass
- Run `flutter analyze` — must be clean

## Completion Condition

- `flutter test` passes with all repository tests green
- `flutter analyze` reports no errors
- All 4 `CompetitionsRepository` methods implemented and tested
- DI providers wired in `lib/core/di/providers.dart`
- `docs/plan.md` updated
