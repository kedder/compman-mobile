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
- ✅ `AGENTS.md` — canonical agent rules: context loading, documentation maintenance, dependency rule, test commands
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
- ✅ **Competition List Screen** — redesigned Add Competition flow with body search pill, flat checkbox rows via `CompetitionCard`, inline status badges, AppBar Done action, and pre-populated selections from existing bookmarks
- ✅ **My Competitions Screen** — pull-to-refresh, empty/loading/error states, title + bookmarked date cards, remove with confirmation dialog
- ✅ **Home screen redesign** — `BookmarksScreen` now matches the refreshed "Your Competitions" design with a centered empty-state CTA, flat rows with inline `StatusBadge`, long-press remove, and a floating add action
- ✅ **Competition Detail Screen** — full implementation: class picker (chips from SoarScore task list), task display (day/task/title/timestamp), "Install as XCSoar Default Task" button with SAF write and SnackBar feedback, XCSoar directory info row, pull-to-refresh; new providers: `competitionDetailProvider`, `latestTasksProvider`, `xcsoarDirectoryUriProvider`; new `/settings/xcsoar-directory` route with `XcsoarDirectorySettingsScreen`
- ✅ **Fix: Competition Detail refresh** — pull-to-refresh now awaits `latestTasksProvider` so the spinner shows for the full request duration; AppBar refresh button shows an inline `CircularProgressIndicator` while loading; both paths refresh only `latestTasksProvider` (classes and competition detail not re-fetched)
- ✅ **Routing** — `GoRouter` with named routes `/`, `/add`, `/competitions/:id`, `/about`; no bottom nav per ui-guidelines
- ✅ **About screen version metadata** — bumped app version to `0.1.0+1`, added `package_info_plus`, and changed `/about` to load the displayed version from runtime package metadata with loading/error states
- ✅ **About screen enrichment** — added app icon (96 dp), full app name, description, author row, GitHub link row, and data-source rows (SoaringSpot, SoarScore); registered `assets/icon/app_icon.png` in `pubspec.yaml`; `docs/features/about.md` created
- ✅ **XCSoar Directory Settings Screen** — screen reworked to `ListView`+`ListTile` layout, AppBar title "XCSoar Folder", "Change Directory" button, always-visible `OutlinedButton` "Reset Permission" (red), cancelled-selection SnackBar, info text paragraph; "Settings" entry added first in home screen three-dot menu

- ✅ **Centralise app theme** — `lib/core/theme/app_theme.dart` created with `AppTheme.light()` factory and `AppColors` ThemeExtension; all hardcoded colour literals replaced with `colorScheme.*` or `appColors.*` lookups across all presentation files; `CardTheme` elevation 2, `ElevatedButton` bold 16 sp, and `OutlinedButton`/`TextButton` base styles set centrally; `docs/architecture.md` and `docs/ui-guidelines.md` updated
- ✅ **Design token theme refresh** — aligned `AppTheme.light()` with `docs/design/` tokens: explicit sky-blue `ColorScheme`, Inter via `google_fonts`, per-badge foreground tokens, shared AppBar/Divider themes, and `AppButtonStyles.ghost()`; updated badge guidance in `docs/ui-guidelines.md`
- ✅ **Shared presentation widgets** — added reusable `AppBadge`, `StatusBadge`, `TwoToneCard`, and `IconMetaRow` primitives with focused widget tests; documented `lib/core/widgets/` in the architecture guide

### Tests
- ✅ **Use case tests** — unit tests for all 4 use cases with mocked repository
- ✅ **Repository impl tests** — unit tests with mocked datasources
- ✅ **Widget tests** — BookmarksScreen (5 tests: empty/data/error/fab navigation/dialog) and CompetitionListScreen (4 tests: list/search/no-results/selection)

---

- ✅ **Remember last-viewed competition** — `LastViewedLocalDataSource` in `lib/core/storage/` reads/writes the last-viewed competition ID to a `"settings"` Hive `Box<String>`; `settingsBoxProvider` added to `core/di/providers.dart`; `CompetitionDetailScreen` converted to `ConsumerStatefulWidget` with a `whenData`-guarded `initState` write; `main()` opens both Hive boxes before `runApp`, resolves `initialLocation`, and overrides both box providers; `CompmanApp` gains an `initialLocation` constructor parameter; widget tests and docs updated
- ✅ **Fix cold-start back-stack** — `CompmanApp` converted to `StatefulWidget`; always starts at `'/'`; `addPostFrameCallback` pushes `/competitions/<id>` on top so back button always returns to the bookmark list; `initialLocation` parameter replaced with `initialCompetitionId`; widget tests and docs updated

---

## Phase 2: Download Files to XCSoarData *(In Progress)*

*Goal: Download waypoint (.cup) and airspace (.txt) files from a bookmarked competition and write them to `/sdcard/XCSoarData/`.*

- 📋 `MANAGE_EXTERNAL_STORAGE` permission (Android 11+) + permission request flow
- ✅ **Airspace & Waypoints domain and data layer** — `DownloadableFileInfo` entity (freezed, `DownloadableFileKind` enum); `fetchDownloads`, `downloadFile`, `recordFileInstall` on repository interface and impl; `FetchDownloads`, `DownloadFile`, `RecordFileInstall` use cases; `fetchDownloads`+`downloadFile` on `SoaringSpotRemoteDataSource` (scrapes `div`+`ul.contest-downloads`, extracts timestamp from second `<span>`, file size from `(NNN.NNN kB)` text); `airspaceVersion`+`waypointsVersion` HiveFields 8–9 on `BookmarkedCompetitionModel`; same fields on `BookmarkedCompetition` entity; DI providers for all three use cases; HTML fixture committed; unit tests for datasource, use cases, and repository methods; `docs/api/soaringspot.md` updated with real HTML structure
- ✅ **Airspace & Waypoints SAF write** — `DownloadAndInstallFile` orchestration use case (download → SAF write as `compman-airspace.txt`/`compman-waypoints.cup` → record install timestamp); `downloadAndInstallFileProvider` DI provider; unit tests covering success for both kinds, download failure propagation, and `PlatformException` propagation
- ✅ **Airspace & Waypoints presentation layer** — `downloadsProvider` (autoDispose family); `_AirspaceCard` and `_WaypointsCard` widgets backed by a shared `_FileDownloadCard` (ConsumerStatefulWidget); "NEW UPDATE" badge shown when `publishedVersion` differs from stored install version or when never installed; "No airspace / waypoint file available" fallback text; pull-to-refresh and AppBar refresh also invalidate `downloadsProvider`; 8 widget tests added; `docs/features/competitions.md` updated
- 📋 `docs/features/downloads.md`

---

## Phase 3: Generate XCSoar Task Files *(In Progress)*

*Goal: Fetch today's task from soarscore.com and generate a `.tsk` file for XCSoar.*

- ✅ `docs/adr/005-soarscore-html-scraping.md` — why HTML scraping is used for SoarScore task downloads
- ✅ **SoarScore data layer** — `TaskInfo` entity (freezed), `fetchLatestTasks` + `downloadTask` on `CompetitionsRepository`, `FetchLatestTasks` + `DownloadTask` use cases, `DioSoarScoreRemoteDataSource` (HTML scraping of `#Downloads` tab), repository impl + DI wired; `docs/api/soarscore.md` created; unit tests for datasource, use cases, and repository methods
- ✅ **SAF bridge extended** — `writeFile`, `getSafDirectoryUri`, `clearSafPermission` added to Kotlin `MainActivity.kt` and `XcsoarSafService` Dart wrapper
- 📋 `.tsk` XML file writer (write bytes to XCSoar data directory as `Default.tsk`)
- ✅ **Competition class selection persistence** — `selectedClass` field added to `BookmarkedCompetition` (freezed) and `BookmarkedCompetitionModel` (HiveField 4); `getById` on local datasource; `setCompetitionClass` on repository interface and impl; `SetCompetitionClass` use case; DI wired; unit tests for use case and repository; old records deserialise with `selectedClass == null`
- ✅ **Competition classes from SoaringSpot (data + domain)** — `fetchClasses(String competitionUrl)` added to `SoaringSpotRemoteDataSource`; scrapes `table.result-overview thead th` from `{url}/results`; `fetchCompetitionClasses(String competitionId)` on repository interface and impl (looks up bookmark URL, delegates to remote, returns `Right([])` if not bookmarked); `FetchCompetitionClasses` use case; DI provider added; unit tests for datasource (3), use case (2), and repository (2)
- ✅ **Competition classes presentation** — `competitionClassesProvider` added to presentation providers; `_ClassPicker` updated to watch `competitionClassesProvider` instead of deriving classes from `latestTasksProvider`; pull-to-refresh and AppBar refresh also invalidate `competitionClassesProvider`; the no-class state now uses full-width class cards with trophy icons and chevrons; 4 widget tests cover cards visible, selection action, empty state, and error+retry
- ✅ **Competition status domain/data enrichment** — added computed `CompetitionStatus`, nullable `startDate`/`endDate` on competition entities and bookmark storage, parsed SoaringSpot date ranges from listing HTML, and preserved those fields when saving bookmarks
- ✅ **Competition detail screen redesign** — updated `CompetitionDetailScreen` to use the static "Competition Details" AppBar, large-title URL header, inline selected-class row, two-tone task card, subdued XCSoar directory footer, and stacked dismissible download error banners; widget coverage added for selected-class and error-banner states
- ✅ **Rename task download button** — button label changed from "Install XCSoar Task" to "Download task", loading state from "Installing..." to "Downloading...", and success SnackBar from "Default.tsk installed in XCSoar folder" to "Task downloaded"; widget tests and docs updated
- 📋 `docs/features/tasks.md`

---

## Phase 4: Daily Task Refresh & XCSoar Integration *(Planned)*

*Goal: Automatic daily refresh; configure XCSoar profile to use downloaded files.*

- 📋 Background refresh / manual refresh on app open
- 📋 XCSoar profile configuration (`xcsoar` feature)
- ✅ **XCSoar flavor picker** — flavor-list UI with per-flavor writability badges (`_FlavorState.ready/warning/notInstalled`), `XcsoarFlavor` value type, `kKnownXcsoarFlavors` constant, `isPackageInstalled`/`canWriteToMediaDir`/`pickDirectoryForPackage` MethodChannel additions, `xcsoarSafServiceProvider` in DI, `fromDownloadFlow` AppBar variant; blocked-writability guidance card (`_BlockedFlavorGuidanceCard`) with toggle and 3 recovery options added
- ✅ **Active flavor indicator** — `resolveFlavorPackageId` MethodChannel method (Kotlin iterates caller-supplied candidate package IDs, returns match against stored SAF tree URI); status line above flavor list; `check_circle`/`radio_button_unchecked` leading icons on every tile; raw URI moved to ADVANCED section
- ✅ **SAF_NOT_CONFIGURED navigation** — `PendingDownload` entity encodes download context; tapping any download button when SAF is unconfigured navigates to `/settings/xcsoar-directory?from=download&competitionId=<id>&kind=<kind>`; on return, if SAF is configured the download auto-resumes, otherwise a cancellation error banner appears; `_CompetitionDetailBodyState._navigateToSettings` / `_autoResumeDownload` implement the flow
- ✅ `docs/features/xcsoar.md` — XCSoar flavor picker feature doc; see docs/features/xcsoar.md
- ✅ **Auto-pop after flavor selection** — `XcsoarDirectorySettingsScreen` now calls `context.pop()` instead of showing the success SnackBar when `fromDownloadFlow` is `true` and a SAF picker returns `'ok'`; competition detail screen resumes immediately and auto-starts the download without requiring the user to press back
