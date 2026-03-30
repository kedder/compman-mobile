# Competition Classes from SoaringSpot — Issue 7: Presentation Layer

## Dependency

**This issue requires `20260330-06-soaringspot-class-fetch-domain.md` to be
done first.** That issue adds `FetchCompetitionClasses`, the repository method,
and `fetchCompetitionClassesProvider` in `lib/core/di/providers.dart`.

## Problem

The `_ClassPicker` widget watches `latestTasksProvider` to derive class names.
Now that `competitionClassesProvider` exists (delivered in issue 06), connect
it to the UI.

## Files to Read First

- `CLAUDE.md` — project rules
- `lib/features/competitions/presentation/screens/competition_detail_screen.dart`
  — `_ClassPicker` widget to update
- `lib/features/competitions/presentation/providers/competitions_providers.dart`
  — where to add the new provider

---

## Task 5 — Presentation provider

In `lib/features/competitions/presentation/providers/competitions_providers.dart`,
add:

```dart
/// Fetches the available competition class names from SoaringSpot.
///
/// Used by the class picker on the competition detail screen.
/// Throws [Failure] on network error; returns empty list when none found.
final competitionClassesProvider =
    FutureProvider.autoDispose.family<List<String>, String>(
  (ref, competitionId) async {
    final useCase = ref.read(fetchCompetitionClassesProvider);
    final result = await useCase(competitionId);
    return result.fold((f) => throw f, (classes) => classes);
  },
);
```

## Task 6 — Update `_ClassPicker`

In `competition_detail_screen.dart`, change `_ClassPicker.build` to watch
`competitionClassesProvider(competitionId)` **instead of**
`latestTasksProvider(competitionId)`.

The chip-rendering and empty/error/loading state logic stays the same. Remove
the `.map((t) => t.compClass).toSet()` step — the provider now returns
`List<String>` directly.

The `_TaskSection` still watches `latestTasksProvider` — do not change it.

Also update the `onRefresh` callback and the `AppBar` refresh `IconButton` in
`_CompetitionDetailBody` to also invalidate
`competitionClassesProvider(competitionId)`.

---

## Tests Required

Widget test in
`test/features/competitions/presentation/screens/competition_detail_screen_test.dart`
(add or extend):

- When `competitionClassesProvider` returns `['Standard', 'Club']`, both chips
  are visible.
- When `competitionClassesProvider` returns an empty list, the "No classes
  found" message is shown.
- When `competitionClassesProvider` throws, the error + Retry state is shown.

---

## Acceptance Criteria

1. `flutter analyze` passes with no new warnings.
2. `flutter test` passes — all existing tests green, new tests green.
3. Class chips appear on the detail screen even when SoarScore has no tasks
   published yet.
4. Pull-to-refresh and the AppBar refresh button both re-fetch classes.
5. `docs/plan.md` updated to mark both class-fetch issues done.
