# Feature: Competitions

This document describes the Competitions feature — the core MVP feature of Compman Mobile.

---

## Overview

Users can browse all gliding competitions currently listed on SoaringSpot, view basic details, and bookmark competitions they plan to attend. Bookmarked competitions appear in a dedicated "My Competitions" tab for quick access.

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
}
```

### `BookmarkedCompetition`

Represents a competition the user has bookmarked. Persisted locally.

```dart
class BookmarkedCompetition {
  final String id;
  final String title;
  final String soaringspotUrl;
  final DateTime bookmarkedAt;
}
```

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

Operations: `getAll()`, `save(model)`, `delete(id)`.

---

## Riverpod Providers

| Provider | Type | Description |
|---|---|---|
| `competitionListProvider` | `AsyncNotifier<List<Competition>>` | Fetches and caches competition list; exposes loading/error/data |
| `bookmarkedCompetitionsProvider` | `AsyncNotifier<List<BookmarkedCompetition>>` | Loads bookmarks; refreshed after bookmark/unbookmark actions |

---

## Screens

### Competition List Screen (`/`)

- **State:** Watches `competitionListProvider`
- Shows a scrollable list of `CompetitionCard` widgets
- Pull-to-refresh triggers `competitionListProvider.refresh()`
- Each card shows: title, description, bookmark toggle button
- Tap card → navigate to Competition Detail Screen
- Shows loading spinner while fetching, error message with retry on failure

### My Competitions Screen (`/bookmarks`)

- **State:** Watches `bookmarkedCompetitionsProvider`
- Shows only bookmarked competitions
- Empty state: "No bookmarked competitions yet."
- Each item: title, bookmarked date, remove button

### Competition Detail Screen (`/competitions/:id`)

- Shows competition title, description, full SoaringSpot URL (tappable)
- Bookmark/unbookmark button
- Placeholder sections for future features:
  - "Waypoints & Airspace" (Phase 2)
  - "Task" (Phase 3)

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
