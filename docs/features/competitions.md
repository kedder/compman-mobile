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

- **Header:** Competition title and SoaringSpot URL.
- **Class selection:** If no class is chosen, fetches available class names from SoarScore and renders them as full-width tappable cards with a trophy icon and chevron. Tapping a class card persists the selection via `SetCompetitionClass` and refreshes the task section.
- **Class display:** If a class is already set, shows the name and a "Change" button that clears the selection.
- **Task section:** Fetches `FetchLatestTasks` and filters by the selected class. Displays day/task number, title, and generation timestamp. "Install as XCSoar Default Task" button calls `DownloadTask` then `XcsoarSafService.writeFile(bytes, 'Default.tsk')`. Shows a green SnackBar on success; if `SAF_NOT_CONFIGURED`, shows a SnackBar with a Settings action button.
- **XCSoar directory row:** Shows the current SAF directory URI from `XcsoarSafService.getSafDirectoryUri()`, or a "Set up" link to `/settings/xcsoar-directory` if not configured.
- **Providers used:** `competitionDetailProvider`, `latestTasksProvider`, `xcsoarDirectoryUriProvider`.
- Pull-to-refresh awaits `latestTasksProvider` completion (errors are swallowed; child widgets show their own error states). Only `latestTasksProvider` is refreshed — classes and competition details are stable and not re-fetched.
- AppBar refresh icon invalidates `latestTasksProvider` and replaces itself with a small inline `CircularProgressIndicator` (20×20, strokeWidth 2) while loading; the icon is restored once the provider settles.

### XCSoar Directory Settings Screen (`/settings/xcsoar-directory`)

- Displays the current SAF directory URI or "Not configured".
- "Choose XCSoar Folder" button triggers `XcsoarSafService.pickDirectory()` which opens the Android folder picker and stores the selected URI permission.
- "Clear configured folder" button calls `XcsoarSafService.clearSafPermission()`.

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

## Data Flow: Bookmarking

```
User taps bookmark button
  └─ ref.read(competitionListProvider.notifier).toggleBookmark(competition)
       ├─ BookmarkCompetition.call(competition)  [if not bookmarked]
       │    └─ CompetitionsRepositoryImpl.bookmarkCompetition()
       │         └─ CompetitionsLocalDataSource.save(BookmarkedCompetitionModel)
       └─ bookmarkedCompetitionsProvider.invalidate()  [triggers reload]
```
