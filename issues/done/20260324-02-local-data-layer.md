# Session 3 — Local Data Layer (Hive)

> **Depends on:** completion of `20260324-01-core-and-domain-layer.md`

## Feature

We are implementing **bookmarked competitions management** — the core MVP feature of Compman Mobile. Users can browse gliding competitions fetched from SoaringSpot, bookmark the ones they plan to attend, and manage that list from a home screen.

**This session** implements the Hive-backed local persistence layer that stores and retrieves bookmarked competitions on the device.

## Context

Read these files before starting:
- `CLAUDE.md` — project rules, architecture dependency rule, test and doc requirements
- `docs/features/competitions.md` — data source interface and model spec
- `lib/features/competitions/domain/entities/bookmarked_competition.dart` — the entity this layer must produce
- `lib/core/error/failures.dart` — `StorageFailure` for error wrapping

Session 2 must be complete before this session. The domain entities and `CompetitionsRepository` interface are already implemented.

This session covers **only** the Hive-backed local persistence. The remote scraping layer is a separate issue.

## Tasks

### Model

1. **`lib/features/competitions/data/models/bookmarked_competition_model.dart`**:
   - A Hive `TypeAdapter` class for `BookmarkedCompetitionModel`
   - Fields: `id` (String), `title` (String), `soaringspotUrl` (String), `bookmarkedAt` (DateTime)
   - Annotate with `@HiveType(typeId: 0)` and `@HiveField(n)` for each field
   - Add `part 'bookmarked_competition_model.g.dart';`
   - Add a `toEntity()` method returning a `BookmarkedCompetition`
   - Add a `fromEntity(BookmarkedCompetition)` factory constructor

### Data source

2. **`lib/features/competitions/data/datasources/competitions_local_datasource.dart`**:
   - Abstract class `CompetitionsLocalDataSource` with three methods:
     - `Future<List<BookmarkedCompetitionModel>> getAll()`
     - `Future<void> save(BookmarkedCompetitionModel model)`
     - `Future<void> delete(String id)`
   - Concrete class `HiveCompetitionsLocalDataSource` implementing it
   - Constructor receives `Box<BookmarkedCompetitionModel> box`
   - Throws a typed `StorageException` (or just rethrows) on Hive errors — the repository impl (Session 5) will convert these to `StorageFailure`

### Codegen

3. Run:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
   Confirm `bookmarked_competition_model.g.dart` is generated.

### Hive initialisation

4. Update **`lib/core/di/providers.dart`** — ensure the `hiveBoxProvider` registers the `BookmarkedCompetitionModelAdapter` before opening the box. If the provider was left as a stub, implement it now.

### Documentation

5. **Update `docs/plan.md`** — mark the following Phase 1 tasks as ✅:
   - "Local datasource"
   - "Models" (partial — mark as partially done, note Hive model done, remote model pending)

## Tests

Write unit tests in `test/features/competitions/data/`:

- **`competitions_local_datasource_test.dart`** — test `HiveCompetitionsLocalDataSource`
  - Use an in-memory Hive setup (e.g. `Hive.init(Directory.systemTemp.path)` or `hive_test` package if available)
  - Test `getAll()` returns empty list initially
  - Test `save()` persists a model and `getAll()` returns it
  - Test `delete()` removes the model by id
  - Test `toEntity()` returns a correct `BookmarkedCompetition`

- Run `flutter test` — all tests must pass
- Run `flutter analyze` — must be clean

## Completion Condition

- `flutter test` passes with all local datasource tests green
- `flutter analyze` reports no errors
- `bookmarked_competition_model.g.dart` generated
- `docs/plan.md` updated
