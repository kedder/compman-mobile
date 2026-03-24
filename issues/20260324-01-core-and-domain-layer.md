# Session 2 — Core + Domain Layer

## Feature

We are implementing **bookmarked competitions management** — the core MVP feature of Compman Mobile. Users can browse gliding competitions fetched from SoaringSpot, bookmark the ones they plan to attend, and manage that list from a home screen.

**This session** lays the foundation: shared infrastructure (error types, HTTP client, DI) and the pure-Dart domain layer (entities, repository interface, use cases) that all subsequent layers depend on.

## Context

Read these files before starting:
- `CLAUDE.md` — project rules, architecture dependency rule, test and doc requirements
- `docs/architecture.md` — folder structure and layer rules
- `docs/features/competitions.md` — entities, repository interface, use cases
- `lib/main.dart` and `lib/app.dart` — current state after Session 1

The folder skeleton already exists. Dependencies (`freezed_annotation`, `fpdart`, `flutter_riverpod`, `dio`, `hive_flutter`) are already in `pubspec.yaml`. Do not re-run `flutter pub get` unless you add something new.

## Tasks

### Core layer (`lib/core/`)

1. **`lib/core/error/failures.dart`** — `Failure` sealed class using `freezed`:
   - `NetworkFailure(String message)`
   - `ParseFailure(String message)`
   - `StorageFailure(String message)`
   - Add `part 'failures.freezed.dart';`

2. **`lib/core/network/http_client.dart`** — configure a `Dio` instance:
   - Base URL: `https://www.soaringspot.com`
   - Connect timeout: 10 seconds
   - Receive timeout: 15 seconds
   - Add a `LogInterceptor` in debug mode

3. **`lib/core/di/providers.dart`** — Riverpod providers:
   - `dioProvider` — provides the configured `Dio` instance
   - `hiveBoxProvider` (or a family) — opens and provides the Hive box named `"bookmarks"`; initialise Hive in the provider if not already done

### Domain layer (`lib/features/competitions/domain/`)

4. **`domain/entities/competition.dart`** — freezed immutable entity:
   ```dart
   class Competition {
     final String id;        // URL slug
     final String title;
     final String url;       // full SoaringSpot URL
     final String description; // dates + location string
   }
   ```

5. **`domain/entities/bookmarked_competition.dart`** — freezed immutable entity:
   ```dart
   class BookmarkedCompetition {
     final String id;
     final String title;
     final String soaringspotUrl;
     final DateTime bookmarkedAt;
   }
   ```

6. **`domain/repositories/competitions_repository.dart`** — abstract interface:
   ```dart
   abstract class CompetitionsRepository {
     Future<Either<Failure, List<Competition>>> fetchCompetitions();
     Future<Either<Failure, List<BookmarkedCompetition>>> getBookmarkedCompetitions();
     Future<Either<Failure, Unit>> bookmarkCompetition(Competition competition);
     Future<Either<Failure, Unit>> removeBookmark(String competitionId);
   }
   ```
   Use `Either` and `Unit` from `fpdart`.

7. **Four use cases** in `domain/usecases/`:
   - `fetch_competitions.dart` — calls `repository.fetchCompetitions()`
   - `get_bookmarked_competitions.dart` — calls `repository.getBookmarkedCompetitions()`
   - `bookmark_competition.dart` — calls `repository.bookmarkCompetition(competition)`
   - `remove_bookmark.dart` — calls `repository.removeBookmark(competitionId)`

   Each use case is a class with a single `call` method and a constructor that receives `CompetitionsRepository`.

8. **Run codegen:**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

### Documentation

9. **Update `docs/plan.md`** — mark the following Phase 1 tasks as ✅:
   - "Error types"
   - "HTTP client"
   - "DI root"
   - "Entities"
   - "Repository interface"
   - "Use cases"

## Tests

Write unit tests in `test/features/competitions/domain/`:

- One test file per use case (4 files total)
- Mock `CompetitionsRepository` using `mockito` (`@GenerateMocks([CompetitionsRepository])`)
- Each test verifies the use case delegates correctly to the repository and returns the repository's result unchanged
- Run `dart run build_runner build --delete-conflicting-outputs` again after adding mock annotations if needed
- Run `flutter test` — all tests must pass
- Run `flutter analyze` — must be clean

## Completion Condition

- `flutter test` passes with all use case unit tests green
- `flutter analyze` reports no errors
- Generated `.freezed.dart` and `.g.dart` files exist for all freezed classes
- `docs/plan.md` updated
