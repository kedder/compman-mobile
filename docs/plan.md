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
- 📋 **Error types** — `Failure` sealed class (`NetworkFailure`, `ParseFailure`, `StorageFailure`) using `freezed`
- 📋 **HTTP client** — `Dio` instance configured with base URL, timeouts, logging interceptor
- 📋 **DI root** — Riverpod providers for `Dio` instance and Hive box

### Domain Layer (`lib/features/competitions/domain/`)
- 📋 **Entities** — `Competition`, `BookmarkedCompetition` (freezed, immutable)
- 📋 **Repository interface** — `CompetitionsRepository` abstract class
- 📋 **Use cases** — `FetchCompetitions`, `GetBookmarkedCompetitions`, `BookmarkCompetition`, `RemoveBookmark`

### Data Layer (`lib/features/competitions/data/`)
- 📋 **Remote datasource** — `SoaringSpotRemoteDataSource`: scrape competition list from soaringspot.com (parse `div.contest` elements)
- 📋 **Local datasource** — `CompetitionsLocalDataSource`: Hive CRUD for bookmarked competitions
- 📋 **Models** — `CompetitionModel` (fromHtml), `BookmarkedCompetitionModel` (Hive adapter + `toEntity()`)
- 📋 **Repository impl** — `CompetitionsRepositoryImpl` wiring remote + local, wrapping exceptions in `Failure`

### Presentation Layer (`lib/features/competitions/presentation/`)
- 📋 **Riverpod providers** — `competitionListProvider` (AsyncNotifier), `bookmarkedCompetitionsProvider` (AsyncNotifier)
- 📋 **Competition List Screen** — scrollable list, pull-to-refresh, bookmark toggle, loading/error states
- 📋 **My Competitions Screen** — bookmarked competitions tab, empty state, remove bookmark
- 📋 **Competition Detail Screen** — title, description, URL, bookmark button, placeholder sections for Phase 2+
- 📋 **Routing** — `go_router` with bottom navigation shell, named routes

### Tests
- 📋 **Use case tests** — unit tests for all 4 use cases with mocked repository
- 📋 **Repository impl tests** — unit tests with mocked datasources
- 📋 **Widget tests** — Competition List Screen, Bookmarks Screen

---

## Phase 2: Download Files to XCSoarData *(Planned)*

*Goal: Download waypoint (.cup) and airspace (.txt) files from a bookmarked competition and write them to `/sdcard/XCSoarData/`.*

- 📋 `MANAGE_EXTERNAL_STORAGE` permission (Android 11+) + permission request flow
- 📋 `downloads` feature: domain, data, presentation layers
- 📋 `docs/features/downloads.md`
- 📋 `docs/api/soaringspot.md` — add downloads section (already documented)

---

## Phase 3: Generate XCSoar Task Files *(Planned)*

*Goal: Fetch today's task from soarscore.com and generate a `.tsk` file for XCSoar.*

- 📋 SoarScore API integration (`soarscore.com`)
- 📋 `.tsk` XML file generator
- 📋 Competition class selection
- 📋 `docs/features/tasks.md`
- 📋 `docs/api/soarscore.md`

---

## Phase 4: Daily Task Refresh & XCSoar Integration *(Planned)*

*Goal: Automatic daily refresh; configure XCSoar profile to use downloaded files.*

- 📋 Background refresh / manual refresh on app open
- 📋 XCSoar profile configuration (`xcsoar` feature)
- 📋 `docs/features/xcsoar.md`
