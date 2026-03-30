# Compman Mobile — Implementation Plan

## Status Legend

| Symbol | Meaning |
|---|---|
| ✅ | Done |
| 🚧 | In Progress |
| 📋 | Planned |

---

## Phase 0: Project Foundation

*Goal: Establish documentation and project structure before writing any Flutter code.*

- ✅ `README.md` — concise project description, quick start, docs index
- ✅ `CLAUDE.md` — AI model rules: context loading, documentation maintenance, dependency rule, test commands
- ✅ `docs/architecture.md` — layer overview, folder structure, state management, navigation, error handling
- ✅ `docs/adr/001-flutter-dart.md` — why Flutter
- ✅ `docs/adr/002-riverpod.md` — why Riverpod
- ✅ `docs/adr/003-html-scraping.md` — why HTML scraping instead of REST API
- ✅ `docs/adr/004-clean-architecture.md` — why Clean Architecture
- ✅ `docs/features/competitions.md` — competitions feature: entities, use cases, screens, data flows
- ✅ `docs/api/soaringspot.md` — SoaringSpot HTML structure and scraping approach
- ✅ `docs/plan.md` — this file

---

## Phase 1: MVP — Browse & Bookmark Competitions

*Goal: A working Android app that fetches competitions from SoaringSpot and lets users bookmark the ones they plan to attend.*

### Project Setup
- ✅ **Project bootstrap** — added all deps to `pubspec.yaml`, created full `lib/` folder skeleton with stub files, wrapped `runApp` in `ProviderScope`, created `lib/app.dart` stub, added `INTERNET` permission to `AndroidManifest.xml`; `flutter analyze` clean

### Core Layer (`lib/core/`)
- ✅ **Error types** — `Failure` sealed class (`NetworkFailure`, `ParseFailure`, `StorageFailure`) using `freezed`
- ✅ **HTTP client** — `Dio` instance configured with base URL, timeouts, logging interceptor
- ✅ **DI root** — Riverpod providers for `Dio` instance and Hive box

### Domain Layer (`lib/features/competitions/domain/`)
- ✅ **Entities** — `Competition`, `BookmarkedCompetition` (freezed, immutable)
- ✅ **Repository interface** — `CompetitionsRepository` abstract class
- ✅ **Use cases** — `FetchCompetitions`, `GetBookmarkedCompetitions`, `BookmarkCompetition`, `RemoveBookmark`

### Data Layer (`lib/features/competitions/data/`)
- ✅ **Remote datasource** — `SoaringSpotRemoteDataSource`: scrapes `.contest` elements from soaringspot.com homepage; `ServerException` on network error; empty result not an error; HTML fixture committed to `test/fixtures/`
- ✅ **Local datasource** — `CompetitionsLocalDataSource`: Hive CRUD for bookmarked competitions (`getAll`, `save`, `delete`); `HiveCompetitionsLocalDataSource` backed by typed `Box<BookmarkedCompetitionModel>`
- ✅ **Models** — `BookmarkedCompetitionModel` (Hive TypeAdapter typeId:0, `toEntity()`, `fromEntity()`; `.g.dart` generated); `CompetitionModel` (`fromElement()` parses `.contest` DOM element, `toEntity()`)
- ✅ **Repository impl** — `CompetitionsRepositoryImpl` wiring remote + local, wrapping exceptions in `Failure`; DI providers for remote datasource, local datasource, and repository wired in `lib/core/di/providers.dart`; 9 unit tests covering all 4 methods and both success/failure paths

### Presentation Layer (`lib/features/competitions/presentation/`)
- ✅ **Riverpod providers** — `competitionListProvider` (AsyncNotifier), `bookmarkedCompetitionsProvider` (AsyncNotifier); both await Hive box before accessing repository
- ✅ **Competition List Screen** — search bar, checkbox multi-select via `CompetitionCard` widget, pre-populated from existing bookmarks, footer Back/Done actions
- ✅ **My Competitions Screen** — pull-to-refresh, empty/loading/error states, title + bookmarked date cards, remove with confirmation dialog
- ✅ **Competition Detail Screen** — stub only ("Coming soon"); full implementation planned for Phase 2
- ✅ **Routing** — `GoRouter` with named routes `/`, `/add`, `/competitions/:id`, `/about`; no bottom nav per ui-guidelines

### Tests
- ✅ **Use case tests** — unit tests for all 4 use cases with mocked repository
- ✅ **Repository impl tests** — unit tests with mocked datasources
- ✅ **Widget tests** — BookmarksScreen (4 tests: empty/data/error/dialog) and CompetitionListScreen (4 tests: list/search/no-results/selection)

---

## Phase 2: Download Files to XCSoarData *(Planned)*

*Goal: Download waypoint (.cup) and airspace (.txt) files from a bookmarked competition and write them to `/sdcard/XCSoarData/`.*

- 📋 `MANAGE_EXTERNAL_STORAGE` permission (Android 11+) + permission request flow
- 📋 `downloads` feature: domain, data, presentation layers
- 📋 `docs/features/downloads.md`
- 📋 `docs/api/soaringspot.md` — add downloads section (already documented)

---

## Phase 3: Generate XCSoar Task Files *(In Progress)*

*Goal: Fetch today's task from soarscore.com and generate a `.tsk` file for XCSoar.*

- ✅ `docs/adr/005-soarscore-html-scraping.md` — why HTML scraping is used for SoarScore task downloads
- ✅ **SoarScore data layer** — `TaskInfo` entity (freezed), `fetchLatestTasks` + `downloadTask` on `CompetitionsRepository`, `FetchLatestTasks` + `DownloadTask` use cases, `DioSoarScoreRemoteDataSource` (HTML scraping of `#Downloads` tab), repository impl + DI wired; `docs/api/soarscore.md` created; unit tests for datasource, use cases, and repository methods
- 📋 `.tsk` XML file writer (write bytes to XCSoar data directory as `Default.tsk`)
- 📋 Competition class selection
- 📋 `docs/features/tasks.md`

---

## Phase 4: Daily Task Refresh & XCSoar Integration *(Planned)*

*Goal: Automatic daily refresh; configure XCSoar profile to use downloaded files.*

- 📋 Background refresh / manual refresh on app open
- 📋 XCSoar profile configuration (`xcsoar` feature)
- 📋 `docs/features/xcsoar.md`
