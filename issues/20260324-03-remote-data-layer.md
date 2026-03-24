# Session 4 — Remote Data Layer (SoaringSpot Scraping)

> **Depends on:** completion of `20260324-01-core-and-domain-layer.md`
> Can run in parallel with `20260324-02-local-data-layer.md`.

## Feature

We are implementing **bookmarked competitions management** — the core MVP feature of Compman Mobile. Users can browse gliding competitions fetched from SoaringSpot, bookmark the ones they plan to attend, and manage that list from a home screen.

**This session** implements the HTML scraping layer that fetches and parses the live competition list from soaringspot.com.

## Context

Read these files before starting:
- `CLAUDE.md` — project rules, architecture dependency rule, test and doc requirements
- `docs/api/soaringspot.md` — SoaringSpot HTML structure, scraping approach, expected fields
- `docs/features/competitions.md` — data source interface and model spec
- `lib/features/competitions/domain/entities/competition.dart` — the entity this layer must produce
- `lib/core/error/failures.dart` — `NetworkFailure`, `ParseFailure`
- `lib/core/di/providers.dart` — `dioProvider`

Session 2 must be complete before this session. This session is independent of Session 3 (local data layer) — both can run in parallel.

## Tasks

### Model

1. **`lib/features/competitions/data/models/competition_model.dart`**:
   - Plain Dart class (no Hive, no freezed required — but freezed is fine if preferred)
   - Fields: `id` (String), `title` (String), `url` (String), `description` (String)
   - Factory constructor `CompetitionModel.fromElement(Element element)` — parses a single `div.contest` HTML element using the `html` package
     - `id` — extracted from the href of the `<a>` tag inside the `<h3>` (URL slug, last path segment)
     - `title` — text content of that `<a>` tag
     - `url` — full href (prefix `https://www.soaringspot.com` if the href is relative)
     - `description` — text content of `div.info` or equivalent (see `docs/api/soaringspot.md`)
   - Method `toEntity()` returning a `Competition`

### Data source

2. **`lib/features/competitions/data/datasources/soaringspot_remote_datasource.dart`**:
   - Abstract class `SoaringSpotRemoteDataSource`:
     - `Future<List<CompetitionModel>> fetchCompetitions()`
   - Concrete class `SoaringSpotRemoteDataSourceImpl`:
     - Constructor receives `Dio dio`
     - Fetches `https://www.soaringspot.com` (GET)
     - Parses the HTML response body using the `html` package
     - Selects all `div.contest` elements
     - Maps each to `CompetitionModel.fromElement(element)`
     - Throws `ServerException(message)` on network error (caught from `DioException`)
     - Throws `ParseException(message)` if no competitions are found or parsing fails

   Define `ServerException` and `ParseException` as simple exception classes in a suitable location (e.g. `lib/core/error/exceptions.dart`) if they don't exist yet.

### Documentation

3. **Update `docs/plan.md`** — when combined with Session 3, mark "Models" as fully ✅, and mark "Remote datasource" as ✅.
   If Session 3 is not yet done, mark "Remote datasource" as ✅ and note "Models partial — remote model done".

## Tests

Write unit tests in `test/features/competitions/data/`:

- **`competition_model_test.dart`**:
  - Include a **fixture HTML string** (a representative snippet of the SoaringSpot HTML with 2–3 `div.contest` blocks, realistic but not real scraped data) stored as a constant in the test file or in `test/fixtures/soaringspot_competitions.html`
  - Test that `CompetitionModel.fromElement()` correctly extracts `id`, `title`, `url`, `description` from a single element
  - Test that `toEntity()` returns a `Competition` with matching fields

- **`soaringspot_remote_datasource_test.dart`**:
  - Mock `Dio` using `mockito`
  - Test happy path: mock returns the fixture HTML → `fetchCompetitions()` returns a non-empty list of `CompetitionModel`
  - Test network error: mock throws `DioException` → datasource throws `ServerException`
  - Test parse error: mock returns HTML with no `div.contest` elements → datasource throws `ParseException`

- Run `flutter test` — all tests must pass
- Run `flutter analyze` — must be clean

## Completion Condition

- `flutter test` passes with all remote datasource and model tests green
- `flutter analyze` reports no errors
- `docs/plan.md` updated
