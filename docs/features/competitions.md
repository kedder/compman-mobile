# Feature: Competitions

This document describes the Competitions feature — the core MVP feature of Compman Mobile.

---

## Overview

Users can browse all gliding competitions currently listed on SoaringSpot, view basic details, and bookmark competitions they plan to attend. Bookmarked competitions appear on the home screen for quick access.

For the full UI specification — screens, user flows, visual states, error handling, and UX requirements — see **[overview.md](overview.md)**.

---

## Domain Entities

### `Competition`

Represents a competition fetched from SoaringSpot. Immutable.

```dart
class Competition {
  final String id;           // URL slug, e.g. "barron-2024"
  final String title;        // Display name, e.g. "Barron 2024"
  final String url;          // Full SoaringSpot URL
  final String description;  // Dates and location string
  final DateTime? startDate; // Parsed from the listing when available
  final DateTime? endDate;   // Parsed from the listing when available
}
```

`Competition.status` is a computed getter returning `CompetitionStatus.live`, `.upcoming`, `.past`, or `null` when dates could not be parsed. The status is never persisted.

### `BookmarkedCompetition`

Represents a competition the user has bookmarked. Persisted locally.

```dart
class BookmarkedCompetition {
  final String id;
  final String title;
  final String soaringspotUrl;
  final DateTime bookmarkedAt;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? airspaceVersion; // version token of the last installed airspace file
  final String? waypointsVersion; // version token of the last installed waypoints file
  final String? taskVersion; // version token (task timestamp) of the last downloaded task
}
```

Bookmarks copy `description`, `startDate`, and `endDate` from the source `Competition` when saved so the UI can render status badges and date text offline. `BookmarkedCompetition.status` is also computed on the fly and never stored.

---

## Repository Interface

`CompetitionsRepository` (abstract, in `domain/repositories/`):

```dart
abstract class CompetitionsRepository {
  /// Fetch all competitions from SoaringSpot.
  Future<Either<Failure, List<Competition>>> fetchCompetitions();

  /// Return all bookmarked competitions from local storage.
  Future<Either<Failure, List<BookmarkedCompetition>>> getBookmarkedCompetitions();

  /// Add a competition to bookmarks.
  Future<Either<Failure, Unit>> bookmarkCompetition(Competition competition);

  /// Remove a competition from bookmarks.
  Future<Either<Failure, Unit>> removeBookmark(String competitionId);
}
```

---

## Use Cases

| Class | Input | Output | Description |
|---|---|---|---|
| `FetchCompetitions` | — | `List<Competition>` | Fetch all competitions from SoaringSpot |
| `GetBookmarkedCompetitions` | — | `List<BookmarkedCompetition>` | Load bookmarks from local storage |
| `BookmarkCompetition` | `Competition` | `Unit` | Add to bookmarks |
| `RemoveBookmark` | `String competitionId` | `Unit` | Remove from bookmarks |

---

## Data Sources

### Remote: `SoaringSpotRemoteDataSource`

Scrapes `https://www.soaringspot.com`. See [docs/api/soaringspot.md](../api/soaringspot.md) for HTML structure.

Returns `List<CompetitionModel>`. Throws `ServerException` on network or parse failure.

### Local: `CompetitionsLocalDataSource`

Persists `BookmarkedCompetitionModel` objects in a **Hive** box named `"bookmarks"`.

Operations: `getAll()`, `getById(id)`, `save(model)`, `delete(id)`.

---

## Riverpod Providers

| Provider | Type | Description |
|---|---|---|
| `competitionListProvider` | `AsyncNotifier<List<Competition>>` | Fetches and caches competition list; exposes loading/error/data |
| `bookmarkedCompetitionsProvider` | `AsyncNotifier<List<BookmarkedCompetition>>` | Loads bookmarks; refreshed after bookmark/unbookmark actions |
| `competitionDetailProvider(id)` | `FutureProvider.autoDispose.family<BookmarkedCompetition?, String>` | Looks up a single bookmarked competition by ID |
| `latestTasksProvider(id)` | `FutureProvider.autoDispose.family<List<TaskInfo>, String>` | Fetches task list from SoarScore for a given competition |
| `xcsoarDirectoryUriProvider` | `FutureProvider.autoDispose<String?>` | Returns the stored SAF tree URI, or null if not configured |

---

## Screens

### Competition List Screen (`/add`)

- **State:** Watches `competitionListProvider`
- Shows a body search field with a pill-shaped outline and a scrollable list of flat
  checkbox rows via `CompetitionCard`
- Pull-to-refresh triggers `competitionListProvider.refresh()`
- Each row shows: checkbox, title, inline status badge, and description text
- AppBar includes the completion action (`Done`); the back button cancels without a footer
- Shows loading spinner while fetching, error message with retry on failure

### Home Screen (`/`)

- **State:** Watches `bookmarkedCompetitionsProvider`
- Shows only bookmarked competitions
- Empty state: centered headline + supporting text + "Add Competition" CTA button
- Non-empty state: body header, flat list rows, inline status badges, and an add `FloatingActionButton`
- Each item: title, description/date-location text, chevron affordance; tap opens detail and long-press opens the remove confirmation dialog

### Competition Detail Screen (`/competitions/:id`)

- **AppBar:** Static title "Competition Details" with a refresh action that re-fetches the latest task list and the downloads list.
- **Header:** Competition title in the large headline style and a primary-coloured `IconMetaRow` showing the SoaringSpot URL.
- **Class selection:** If no class is chosen, fetches available class names from SoarScore and renders them as full-width tappable cards with a trophy icon and chevron. Tapping a class card persists the selection via `SetCompetitionClass` and refreshes the task section.
- **Class display:** If a class is already set, shows a streamlined inline row with a `Class:` label, the selected class name, and a bordered "Change" button that clears the selection.
- **Task section:** Fetches `FetchLatestTasks` and filters by the selected class. Renders the selected task in a `TwoToneCard`: header with `Day X - Task Y` and an optional "NEW UPDATE" badge, primary `IconMetaRow` route/title text, and footer metadata plus a full-width "Download task" button. Tapping "Download task" calls `DownloadAndInstallTask` via `downloadAndInstallTaskProvider`, writing `Default.tsk` and recording the task's timestamp as `BookmarkedCompetition.taskVersion`. On success, invalidates `bookmarkedCompetitionsProvider` + `competitionDetailProvider` so the badge disappears immediately.
- **Fly XCSoar button:** Rendered directly below "Download task" inside the Task card, styled with `AppButtonStyles.success` (green, 64dp full-width `ElevatedButton.icon` with `Icons.flight`). **Visibility:** only shown when a task is installed for the current version, i.e. exactly when the "NEW UPDATE" badge is *not* showing (`task.timestamp == BookmarkedCompetition.taskVersion`) — hidden before the first download and hidden again once a newer task is published. **States once visible:** (1) enabled and labelled `Fly ${flavor.displayName}` when `activeFlavorPackageIdProvider` resolves a package ID — tapping calls `XcsoarSafService.launchPackage(packageId)`; (2) disabled with subdued text "Set up XCSoar folder first." when `xcsoarDirectoryUriProvider` is null/empty; (3) disabled with subdued text "XCSoar is not installed." when a SAF directory is configured but no known flavor resolves, including while `activeFlavorPackageIdProvider` is still loading. A thrown `PlatformException` (e.g. `LAUNCH_FAILED`, or `ActivityNotFoundException` on the Android side) appends the dismissible error banner "Could not launch XCSoar. Is it installed?" via the same `_downloadErrorsProvider` mechanism used by downloads. No confirmation dialog and no loading spinner — launching is instantaneous.
- **Airspace card:** Watches `downloadsProvider` and renders a `TwoToneCard` for the `.txt` (airspace) file. Header shows the section title "Airspace", an optional "NEW UPDATE" badge (`AppBadge` with error colour), and the filename + file size. Footer shows the last-published timestamp and a ghost "Download" / "Downloading…" button. Shows "No airspace file available" in muted text when no `.txt` entry is present.
- **Waypoints card:** Same layout as the Airspace card but for the `.cup` (waypoints) file, with section title "Waypoints" and a location-pin icon.
- **"NEW UPDATE" badge logic:** Shown when `DownloadableFileInfo.publishedVersion` is non-null and differs from the corresponding `airspaceVersion` / `waypointsVersion` stored on `BookmarkedCompetition` (string equality). Also shown when the stored version is `null`, meaning the file has never been installed. The Task card badge follows the same rule using `TaskInfo.timestamp` compared against `BookmarkedCompetition.taskVersion`.
- **File download flow:** Tapping "Download" calls `DownloadAndInstallFile` via `downloadAndInstallFileProvider`. On success, shows a green SnackBar ("Airspace downloaded" / "Waypoints downloaded") and invalidates `bookmarkedCompetitionsProvider` + `competitionDetailProvider` so the badge disappears. Non-SAF `Failure` errors append stacked dismissible error banners.
- **SAF_NOT_CONFIGURED flow:** When any download throws `PlatformException(code: 'SAF_NOT_CONFIGURED')`, the app navigates to `/settings/xcsoar-directory` (see **[docs/features/xcsoar.md](xcsoar.md)**) passing `?from=download&competitionId=<id>&kind=<kind>`. On return, if a SAF directory is now configured the pending download auto-resumes without user action; otherwise a dismissible error banner "XCSoar folder setup was cancelled" is shown.
- **Download feedback:** Successful installs show a green confirmation SnackBar. Non-SAF download/install failures append stacked dismissible error banners fixed to the bottom of the screen.
- **XCSoar directory row:** Shows the current SAF directory URI from `XcsoarSafService.getSafDirectoryUri()` as a subdued footer `IconMetaRow`, or "XCSoar folder not configured" when no SAF directory has been chosen.
- **Providers used:** `competitionDetailProvider`, `latestTasksProvider`, `downloadsProvider`, `xcsoarDirectoryUriProvider`, `activeFlavorPackageIdProvider`.
- Pull-to-refresh awaits both `latestTasksProvider` and `downloadsProvider` (errors are swallowed; child widgets show their own error states).
- AppBar refresh icon invalidates `latestTasksProvider` and `downloadsProvider`, and replaces itself with a small inline `CircularProgressIndicator` (20×20, strokeWidth 2) while loading.

### XCSoar Directory Settings Screen (`/settings/xcsoar-directory`)

See **[docs/features/xcsoar.md](xcsoar.md)**.

---

## Data Flow: Fetching Competitions

```
CompetitionListScreen
  └─ watches competitionListProvider
       └─ CompetitionListNotifier.build()
            └─ FetchCompetitions.call()
                 └─ CompetitionsRepositoryImpl.fetchCompetitions()
                      └─ SoaringSpotRemoteDataSource.fetchCompetitions()
                           └─ Dio GET https://www.soaringspot.com
                                └─ Parse HTML → List<CompetitionModel>
                                     └─ map to List<Competition> (domain entities)
```

---

## Last-Viewed Competition

When the user opens `CompetitionDetailScreen`, the screen writes the competition's ID to a Hive `Box<String>` named `"settings"` under the key `lastViewedCompetitionId`. On the next cold start, `main()` reads that ID, checks whether it still matches a bookmarked competition, and — if so — passes `initialCompetitionId` to `CompmanApp`. The app always starts at `'/'` (home screen) and then uses `addPostFrameCallback` to push `/competitions/<id>` on top, so the back button always returns to the bookmark list.

### Key components

| Component | Location | Role |
|---|---|---|
| `LastViewedLocalDataSource` | `lib/core/storage/last_viewed_local_datasource.dart` | Reads/writes the last-viewed ID in the settings box |
| `settingsBoxProvider` | `lib/core/di/providers.dart` | `FutureProvider<Box<String>>` for the settings Hive box |
| `CompetitionDetailScreen.initState` | competition detail screen | Fire-and-forget write via `whenData` guard |
| `main()` startup redirect | `lib/main.dart` | Opens both boxes, resolves `initialCompetitionId`, overrides providers |
| `_CompmanAppState.initState` | `lib/app.dart` | Pushes detail screen via post-frame callback to seed back-stack |

### Guard pattern in `initState`

`initState` reads `settingsBoxProvider` and calls `whenData`. In production, `main()` overrides the provider with `AsyncData(settingsBox)` before `runApp`, so `whenData` fires synchronously on the first frame. In widget tests that do not override `settingsBoxProvider`, the provider stays in `AsyncLoading` and `whenData` is a no-op — no Hive I/O, no platform-channel calls, no `FakeAsync` deadlock.

### Edge cases

- **No stored ID** (first launch) → `lastId` is `null` → home screen.
- **Stored ID not bookmarked** → `any()` returns `false` → home screen.
- **Only one bookmark** → redirect always fires.

---

## Data Flow: Bookmarking

```
User taps bookmark button
  └─ ref.read(competitionListProvider.notifier).toggleBookmark(competition)
       ├─ BookmarkCompetition.call(competition)  [if not bookmarked]
       │    └─ CompetitionsRepositoryImpl.bookmarkCompetition()
       │         └─ CompetitionsLocalDataSource.save(BookmarkedCompetitionModel)
       └─ bookmarkedCompetitionsProvider.invalidate()  [triggers reload]
```
