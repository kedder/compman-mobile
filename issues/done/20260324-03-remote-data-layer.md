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

## Research Notes (openvario-compman)

The Python TUI app at `/home/dev/openvario-compman/src/compman/soaringspot.py` implements the same scraping logic. Key findings to guide this implementation:

**Selector:** Use `.contest` (any element with that class), not `div.contest` specifically. The `html` package method is `document.querySelectorAll('.contest')`.

**Field extraction logic (per element):**
```
anchor  = element.querySelector('h3 a')       // null → skip element
title   = anchor.text.trim()
href    = anchor.attributes['href']           // always relative on soaringspot.com
url     = 'https://www.soaringspot.com' + href
id      = Uri.parse(href).pathSegments
             .lastWhere((s) => s.isNotEmpty)  // last non-empty segment; strips trailing slash
descr   = element.querySelector('.info')?.text
          normalised: RegExp(r'\s+').replaceAllMapped → single space, trimmed
```

**Malformed elements:** If `querySelector('h3 a')` returns null, skip the element silently and continue — do not throw.

**Empty results:** Return an empty list (do not throw `ParseException`). Matches openvario-compman behaviour.

**`fromElement` signature:** Return `CompetitionModel?` (nullable). The datasource filters out nulls before returning the list.

**Exceptions:** `ServerException` and `ParseException` do not exist yet — create `lib/core/error/exceptions.dart`. These are throw-site types; the repository layer (Session 5) maps them to `Failure`.

**No fixture HTML in openvario-compman:** The Python project uses live API tests, not HTML fixtures. We use a **real snapshot** of the soaringspot.com homepage instead (see Testing section below).

## Tasks

### Model

1. **`lib/features/competitions/data/models/competition_model.dart`**:
   - Plain Dart class (no Hive, no freezed required — but freezed is fine if preferred)
   - Fields: `id` (String), `title` (String), `url` (String), `description` (String)
   - Factory constructor `CompetitionModel.fromElement(Element element)` returning `CompetitionModel?`:
     - Find anchor with `element.querySelector('h3 a')` — return `null` if not found
     - `title` — `anchor.text.trim()`
     - `url` — `href` is always relative; prepend `https://www.soaringspot.com`
     - `id` — last non-empty path segment: `Uri.parse(href).pathSegments.lastWhere((s) => s.isNotEmpty)`
     - `description` — `element.querySelector('.info')?.text`, whitespace-normalised (collapse `\s+` to single space, trim)
   - Method `toEntity()` returning a `Competition`

### Data source

2. **`lib/features/competitions/data/datasources/soaringspot_remote_datasource.dart`**:
   - Abstract class `SoaringSpotRemoteDataSource`:
     - `Future<List<CompetitionModel>> fetchCompetitions()`
   - Concrete class `SoaringSpotRemoteDataSourceImpl`:
     - Constructor receives `Dio dio`
     - Fetches `https://www.soaringspot.com` (GET)
     - Parses the HTML response body using the `html` package
     - Selects all `.contest` elements: `document.querySelectorAll('.contest')`
     - Maps each through `CompetitionModel.fromElement()`, filters nulls
     - Returns the list (may be empty — empty is not an error)
     - Throws `ServerException(message)` on network error (caught from `DioException`)

   Create `lib/core/error/exceptions.dart` with `ServerException` and `ParseException` as plain Dart exception classes (no freezed). These are throw-site types; the repository layer maps them to `Failure`.

### Documentation

3. **Update `docs/plan.md`** — when combined with Session 3, mark "Models" as fully ✅, and mark "Remote datasource" as ✅.
   If Session 3 is not yet done, mark "Remote datasource" as ✅ and note "Models partial — remote model done".

## Tests

> **No network access during tests.** `flutter test` must never make real HTTP requests. `competition_model_test` reads the snapshot from disk; `soaringspot_remote_datasource_test` injects a mock `Dio` that returns the snapshot string. The snapshot is refreshed manually (see `docs/api/soaringspot.md`).

### Snapshot fixture

Before implementing tests, download a real snapshot of the soaringspot.com homepage **manually** and save it as `test/fixtures/soaringspot_home.html`:

```bash
curl -L -A "Mozilla/5.0" https://www.soaringspot.com/ -o test/fixtures/soaringspot_home.html
```

Commit this file to git. Tests read it from disk — no network call is made at test time.

### Test files in `test/features/competitions/data/`:

- **`competition_model_test.dart`**:
  - Load `test/fixtures/soaringspot_home.html`, parse it, and pick the **first** `.contest` element as the subject
  - Test `fromElement()` returns a non-null model with non-empty `id`, `title`, `url`, `description`
  - Test `url` starts with `https://www.soaringspot.com`
  - Test `id` contains no slashes or spaces
  - Test `description` contains no leading/trailing whitespace and no consecutive spaces
  - Test `fromElement()` returns `null` for a hand-crafted malformed element (no `<h3><a>`) — this case cannot come from the snapshot but must still be tested
  - Test `toEntity()` on a parsed element returns a `Competition` with matching fields

- **`soaringspot_remote_datasource_test.dart`**:
  - Mock `Dio` using `mockito` — the mock must return the snapshot HTML string, never make a real HTTP call
  - Happy path: mock returns the snapshot HTML → `fetchCompetitions()` returns a non-empty list; spot-check that each model has non-empty `id`, `title`, `url`
  - Network error: mock throws `DioException` → datasource throws `ServerException`
  - No-contest page: mock returns a minimal HTML string with no `.contest` elements → `fetchCompetitions()` returns empty list

- Run `flutter test` — all tests must pass
- Run `flutter analyze` — must be clean

## Completion Condition

- `flutter test` passes with all remote datasource and model tests green
- `flutter analyze` reports no errors
- `flutter build apk --debug` succeeds
- `docs/plan.md` updated
