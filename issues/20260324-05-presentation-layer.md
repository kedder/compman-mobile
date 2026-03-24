# Session 6 — Presentation Layer

> **Depends on:** completion of `20260324-04-repository-wiring.md`

## Feature

We are implementing **bookmarked competitions management** — the core MVP feature of Compman Mobile. Users can browse gliding competitions fetched from SoaringSpot, bookmark the ones they plan to attend, and manage that list from a home screen.

**This session** delivers the complete UI: Riverpod state providers, the Home screen (bookmarked competition list with remove/pull-to-refresh), the Add Competition screen (search + checkbox multi-select), a stub Detail screen, and GoRouter-based navigation.

## Context

Read these files before starting:
- `CLAUDE.md` — project rules, architecture dependency rule, test and doc requirements
- `docs/features/overview.md` — **primary UI specification**: screens, user flows, visual states, UX requirements. Read this carefully.
- `docs/features/competitions.md` — providers, screen list, data flows
- `lib/features/competitions/domain/entities/competition.dart`
- `lib/features/competitions/domain/entities/bookmarked_competition.dart`
- `lib/features/competitions/domain/usecases/` — all 4 use cases
- `lib/core/di/providers.dart` — `competitionsRepositoryProvider`

Session 5 must be complete before this session.

## Tasks

### Riverpod providers

1. **`lib/features/competitions/presentation/providers/competitions_providers.dart`**:

   **`competitionListProvider`** (`AsyncNotifier<List<Competition>>`):
   - `build()` calls `FetchCompetitions(ref.watch(competitionsRepositoryProvider))()`
   - Exposes `refresh()` method (calls `ref.invalidateSelf()` or re-runs build)

   **`bookmarkedCompetitionsProvider`** (`AsyncNotifier<List<BookmarkedCompetition>>`):
   - `build()` calls `GetBookmarkedCompetitions(ref.watch(competitionsRepositoryProvider))()`
   - Exposes:
     - `bookmark(Competition competition)` — calls `BookmarkCompetition`, then invalidates self
     - `removeBookmark(String id)` — calls `RemoveBookmark`, then invalidates self

### Screens

2. **`lib/features/competitions/presentation/screens/bookmarks_screen.dart`** — "Your Competitions" (home screen):
   - Watches `bookmarkedCompetitionsProvider`
   - **Loading state:** centered `CircularProgressIndicator`
   - **Error state:** error message text + "Retry" button that calls `ref.invalidate(bookmarkedCompetitionsProvider)`
   - **Empty state:** large "Add Competition" button centered on screen
   - **Data state:** `ListView` of competition cards, each showing:
     - Competition title
     - Location + dates from description (parse or display raw description string)
     - Status badge: "Live" (green), "Upcoming" (blue), "Past" (gray) — derive from description dates or display a placeholder badge for now
     - Trash icon button → shows a `showDialog` confirmation ("Remove [title]?") → on confirm calls `bookmarkedCompetitionsProvider.notifier.removeBookmark(id)`
   - `RefreshIndicator` wrapping the list for pull-to-refresh (calls `ref.invalidate(bookmarkedCompetitionsProvider)`)
   - Tapping a card navigates to `/competitions/:id`
   - Header has an "Add" button (or `+` icon) linking to `/add`
   - Header has a menu icon linking to `/about` (stub route)

3. **`lib/features/competitions/presentation/screens/competition_list_screen.dart`** — "Add Competition":
   - Watches `competitionListProvider`
   - Local state: `Set<String> selectedIds` (tracks which competitions are checked), `String searchQuery`
   - **Loading state:** centered `CircularProgressIndicator`
   - **Error state:** error message + "Retry" button
   - **Search bar** at top: filters displayed competitions by title (case-insensitive)
   - **Empty search state:** "No competitions found" message when search matches nothing
   - `ListView` of competitions showing:
     - Checkbox (or `ListTile` with `leading` checkmark)
     - Title, description, status badge
     - Tapping the row toggles selection; selected rows show a blue border or checkmark
   - Footer: "Back" button (navigates back) + "Done" button
     - "Done" calls `bookmarkedCompetitionsProvider.notifier.bookmark(competition)` for each newly selected competition, then navigates back
   - Pre-populate `selectedIds` from already-bookmarked competition ids so existing bookmarks appear checked

4. **`lib/features/competitions/presentation/screens/competition_detail_screen.dart`** — stub only:
   - Accepts a `competitionId` route parameter
   - Displays `Scaffold` with `AppBar` titled "Competition" and a centered `Text('Coming soon')`

### Routing

5. **`lib/app.dart`** — replace the placeholder `MaterialApp` with a full `GoRouter`-based app:
   - Routes:
     - `/` → `BookmarksScreen` (shell with bottom nav or plain)
     - `/add` → `CompetitionListScreen`
     - `/competitions/:id` → `CompetitionDetailScreen`
     - `/about` → stub `AboutScreen` (`Scaffold` with `AppBar` titled "About" and version placeholder text)
   - Use `GoRouter` with `MaterialApp.router`
   - Bottom navigation bar with two tabs: "My Competitions" (`/`) and a way to reach "Add" — or just a single screen with the Add button in the header (follow `docs/features/overview.md`)

### Update `lib/main.dart`

6. Ensure `main.dart` uses `CompmanApp` from `lib/app.dart` and is wrapped in `ProviderScope`. Also call `Hive.initFlutter()` before `runApp` (or ensure it's handled in the DI provider).

### Documentation

7. **Update `docs/plan.md`** — mark the following Phase 1 tasks as ✅:
   - "Riverpod providers"
   - "Competition List Screen"
   - "My Competitions Screen"
   - "Competition Detail Screen" (note: stub)
   - "Routing"

## Tests

Write widget tests in `test/features/competitions/presentation/`:

- **`bookmarks_screen_test.dart`**:
  - Override `bookmarkedCompetitionsProvider` with a mock/stub returning empty list → verify empty state widget is shown
  - Override with a list of 2 bookmarks → verify titles appear in the widget tree
  - Override with an error → verify error message and Retry button appear
  - Tap trash icon → verify confirmation dialog appears

- **`competition_list_screen_test.dart`**:
  - Override `competitionListProvider` with a stub list of 3 competitions → verify all 3 titles appear
  - Enter search text → verify filtered results
  - Enter non-matching search → verify "No competitions found" message
  - Tap a competition row → verify it becomes selected (checkmark visible)

- Run `flutter test` — all tests must pass
- Run `flutter analyze` — must be clean

## Completion Condition

- `flutter test` passes (all unit + widget tests green)
- `flutter analyze` reports no errors
- App navigates correctly between Home, Add Competition, and Detail stub screens
- `docs/plan.md` updated for all Phase 1 presentation tasks
- Phase 1 is fully complete
