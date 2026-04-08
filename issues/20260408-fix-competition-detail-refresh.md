# Fix: Pull-to-refresh and AppBar refresh button do nothing on Competition Detail screen

## Feature summary

The Competition Detail screen lets users view the latest XCSoar task for a bookmarked competition. It supports two refresh entry points: a pull-to-refresh gesture and an AppBar refresh icon button. Both are supposed to reload the task list (and optionally the class list and XCSoar directory URI), but neither gives the user any visible feedback that a refresh occurred.

## Scope

This issue is limited to fixing the refresh behaviour on `CompetitionDetailScreen` and `_CompetitionDetailBody`. No other screens, use cases, or data-layer code need changes.

## Root cause

Read `lib/features/competitions/presentation/screens/competition_detail_screen.dart` before implementing.

### 1. Pull-to-refresh — `onRefresh` returns immediately

`_CompetitionDetailBody.build` wraps the `ListView` in a `RefreshIndicator`. The `onRefresh` callback is:

```dart
onRefresh: () async {
  ref.invalidate(latestTasksProvider(competitionId));
  ref.invalidate(competitionClassesProvider(competitionId));
  ref.invalidate(xcsoarDirectoryUriProvider);
},
```

`ref.invalidate` is synchronous; the `async` function body contains no `await`. The returned `Future<void>` therefore completes in microseconds. `RefreshIndicator` keeps its spinner alive only while the returned future is pending — so the spinner flashes for ~1 frame and is gone before the user notices. From the user's perspective, pulling to refresh does nothing.

**Fix:** after invalidating, await the future of the provider that is currently active:

- If `competition.selectedClass != null` → await `latestTasksProvider(competitionId).future`
- If `competition.selectedClass == null` → await `competitionClassesProvider(competitionId).future`

Also await `xcsoarDirectoryUriProvider.future` in both branches (it is cheap).

Errors must be swallowed (use `.catchError((_) {})` or `ignore()`) so a network failure doesn't crash the `onRefresh` future — the child widgets already show their own error states.

`_CompetitionDetailBody` already receives `competition: BookmarkedCompetition` as a constructor parameter, so you can branch on `competition.selectedClass` directly.

### 2. AppBar refresh button — no feedback during reload

The AppBar `IconButton` in `CompetitionDetailScreen` invalidates the same providers:

```dart
onPressed: () {
  ref.invalidate(latestTasksProvider(competitionId));
  ref.invalidate(competitionClassesProvider(competitionId));
  ref.invalidate(xcsoarDirectoryUriProvider);
},
```

Provider invalidation does work — `_TaskSection` and `_ClassPicker` will rebuild into their loading states. However, if the network is fast the loading flash is imperceptible, and the button itself gives no indication that something is happening.

**Fix:** watch the loading state of the relevant active provider and swap the `IconButton` for a small `CircularProgressIndicator` (constrained to icon size, ~20 × 20) while it loads. Use `competitionClassesProvider` or `latestTasksProvider` depending on `competition.selectedClass`, just like the pull-to-refresh fix above.

Because `competitionAsync` is already resolved by the time the AppBar actions are reachable (the screen shows the AppBar regardless of `competitionAsync` state), you should watch the task/class provider inside `CompetitionDetailScreen.build` only to drive the button state — not to rebuild the whole body. A clean approach is:

```dart
// Inside CompetitionDetailScreen.build, after resolving competitionAsync to a non-null competition:
final isRefreshing = competition.selectedClass != null
    ? ref.watch(latestTasksProvider(competitionId)).isLoading
    : ref.watch(competitionClassesProvider(competitionId)).isLoading;
```

Then show a `SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))` (wrapped in the standard 48 × 48 padding via `Padding` or an `IconButton` with a disabled `onPressed`) when `isRefreshing` is true, and the `Icons.refresh` button when it is false.

> **Important:** watching these providers in the outer `CompetitionDetailScreen` is safe because they are `autoDispose.family` — they will be created/alive as long as the detail body is shown. But only watch them when `competition != null`; guard accordingly to avoid creating the provider for competitions that are not bookmarked.

## Acceptance criteria

1. Pulling down on the Competition Detail screen shows the `RefreshIndicator` spinner for the full duration of the network request, then dismisses when the data (or error) arrives.
2. Tapping the AppBar refresh icon replaces the icon with a small inline spinner for the duration of the reload, then restores the icon.
3. Both refresh paths reload the currently-relevant provider (tasks if a class is selected, classes if not) plus `xcsoarDirectoryUriProvider`.
4. If the reload fails, the error is surfaced through the existing `_ErrorRetry` widgets inside the body; the spinner/icon restore to normal state.
5. `flutter analyze` reports no issues. `make test` (or `flutter test`) passes.

## Files to read before implementing

- `lib/features/competitions/presentation/screens/competition_detail_screen.dart` — the screen and all private widgets
- `lib/features/competitions/presentation/providers/competitions_providers.dart` — provider definitions
- `docs/features/competitions.md` — domain model and provider table
- `CLAUDE.md` — project rules (doc maintenance, commit format, tests)

## Documentation

Update `docs/features/competitions.md` — the "Competition Detail Screen" section describes pull-to-refresh and AppBar refresh. Update it to reflect that both now properly await provider completion and that the AppBar button shows an inline loading indicator.

Mark the fix as ✅ in `docs/plan.md`.
