# Download Latest Task — Issue 4: Competition Detail Screen UI

## Feature

Implement the Competition Detail screen so users can see competition info, select their glider class, view the latest task from SoarScore, download and install it as XCSoar's default task, and be informed of the current XCSoar data directory.

## Scope

This issue is **presentation layer only**: Riverpod providers, the `CompetitionDetailScreen` widget, and any supporting widgets. No new Kotlin, no new domain or data code.

This replaces the existing stub `competition_detail_screen.dart`.

## Dependencies

All three must be done before this issue:
- `20260330-01-soarscore-data-layer.md` — `TaskInfo` entity, `FetchLatestTasks`, `DownloadTask` use cases, DI providers
- `20260330-02-saf-task-writer.md` — `XcsoarSafService.writeFile`, `getSafDirectoryUri`
- `20260330-03-competition-class-selection.md` — `BookmarkedCompetition.selectedClass`, `SetCompetitionClass` use case

---

## Background

Read these before starting:

- `docs/features/overview.md` — authoritative UI spec for this screen
- `docs/ui-guidelines.md` — theme, touch targets, loading/error/empty states, status badges
- `docs/architecture.md` — layer rules; presentation must not import from data

The screen is reached by tapping a competition card on the home screen: route `/competitions/:id`. The `competitionId` parameter is `BookmarkedCompetition.id` (SoaringSpot slug), which is also the SoarScore competition ID.

---

## Screen Sections

### Header

- Competition title (large text)
- Location with pin icon
- Date range derived from `BookmarkedCompetition` — if `bookmarkedAt` is not enough, note that we only have `id`, `title`, `soaringspotUrl`, `bookmarkedAt`, `selectedClass` on the entity; use `title` and `soaringspotUrl` for display
- Status badge (Live / Upcoming / Past) — derive from the competition's date range if available; if not derivable, omit the badge gracefully

### Competition Class Section

A `selectedClass` can be null (not yet chosen) or set (previously chosen).

**If `selectedClass` is null:** show a class-picker UI:
- Fetch task list from SoarScore to get available class names (distinct `compClass` values)
- Display each class as a tappable chip/card
- On tap: call `SetCompetitionClass(competitionId, chosenClass)`, then invalidate providers to refresh the task section
- While fetching classes: show inline `CircularProgressIndicator`
- If SoarScore returns empty or error: show "No classes found — tasks may not be available for this competition" and a Retry button

**If `selectedClass` is set:** show the class name with a small "Change" button that resets it to null (calls `SetCompetitionClass(competitionId, null)`) and triggers re-fetch.

### Task Section (visible only when `selectedClass` is set)

- Show section title: "Today's Task"
- Fetch `FetchLatestTasks(competitionId)` and filter to the entry matching `selectedClass`
- **If a matching task exists:**
  - Show task info: "Day {dayNo} · Task {taskNo} · {title}"
  - Show generation timestamp: "Generated {timestamp}"
  - Show a prominent `ElevatedButton` — "Install as XCSoar Default Task"
  - While download is in progress: replace button with `CircularProgressIndicator`
  - On success: show green `SnackBar` — "Default.tsk installed in XCSoar folder"
  - On `PlatformException` with code `SAF_NOT_CONFIGURED`: show `SnackBar` — "XCSoar directory not configured — set it in Settings" with an action button "Settings" that pushes `/settings/xcsoar-directory`
  - On other `PlatformException` or `Left(Failure)`: show red `SnackBar` with error message
- **If no task for the selected class:** show "No task available today" with a Refresh button
- **If SoarScore fetch failed:** show error message + Retry button
- **While fetching:** show inline `CircularProgressIndicator`

### XCSoar Directory Display

Below the task section, show a small info row:
- "XCSoar folder: {uri}" where `{uri}` comes from `XcsoarSafService().getSafDirectoryUri()`
- If null: "XCSoar folder: Not configured" with a "Set up" link that pushes `/settings/xcsoar-directory`
- Update this display after any directory change (watch the provider)

### Refresh

- Pull-to-refresh on the whole screen invalidates the task list provider and re-fetches
- A refresh `IconButton` in the `AppBar` also triggers this

---

## Providers to create in `lib/features/competitions/presentation/providers/competitions_providers.dart`

### `competitionDetailProvider(String competitionId)`

`FutureProvider.family` that returns `BookmarkedCompetition?` by looking up the competition from the bookmarked list. Needed for the header section.

### `latestTasksProvider(String competitionId)`

`FutureProvider.family` wrapping `FetchLatestTasks(competitionId)`:

```dart
final latestTasksProvider = FutureProvider.autoDispose.family<List<TaskInfo>, String>(
  (ref, competitionId) async {
    final useCase = ref.read(fetchLatestTasksProvider);
    final result = await useCase(competitionId);
    return result.fold((f) => throw f, (tasks) => tasks);
  },
);
```

### `xcsoarDirectoryUriProvider`

`FutureProvider.autoDispose` fetching `XcsoarSafService().getSafDirectoryUri()`. Used by the directory display row and by the settings screen.

---

## Files to Change

- `lib/features/competitions/presentation/screens/competition_detail_screen.dart` — replace stub with full implementation
- `lib/features/competitions/presentation/providers/competitions_providers.dart` — add new providers above
- No new routes needed (`/competitions/:id` already exists in `app.dart`)

---

## Acceptance Criteria

1. `flutter analyze` passes.
2. `flutter test` passes — existing tests still green.
3. Tapping a competition card on the home screen navigates to the detail screen with the correct competition title.
4. If no class selected: class chips are shown after loading; tapping one saves and shows the task.
5. If a task is available for the selected class: "Install as XCSoar Default Task" button is shown.
6. Tapping the button (with SAF configured) downloads and writes `Default.tsk`; green SnackBar shown.
7. With SAF not configured: tapping the button shows SnackBar directing the user to Settings.
8. XCSoar directory row shows the current URI or "Not configured".
9. Pull-to-refresh re-fetches the task list.
10. Loading, error, and empty states follow `docs/ui-guidelines.md` patterns.
11. `docs/features/competitions.md` updated to reflect the new screen behaviour.
12. `docs/plan.md` updated.
