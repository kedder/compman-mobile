# Fix: Cold-Start Back Button Strands User on Competition Detail

## Feature summary

The "remember last-viewed competition" feature (commit `8081f50`) sets
`initialLocation` to `/competitions/:id` when a remembered competition is found
on cold start. Because `go_router` creates a single-entry history when given that
`initialLocation`, there is no predecessor route on the navigator stack. The AppBar
back button is absent or exits the app instead of returning to the bookmark list.

Every non-root screen in this app must have a working back button. This ticket
restores that invariant for the cold-start code path.

## Scope

Router-only change. No new screens, widgets, or domain logic are needed.

## Task

Ensure the home route (`/`) is always present as a back-stack ancestor of
`/competitions/:id` when the app cold-starts directly on a Competition Detail
screen.

Preferred approach: convert the flat top-level `GoRoute` for `/competitions/:id`
into a **nested route under `/`**, or set `initialLocation` to `'/'` and use
`GoRouter`'s `redirect` / `initialExtra` mechanism so that the router pushes
`/competitions/:id` on top of `/` rather than replacing it. Either way, after the
fix a back-tap from Competition Detail must land on the home screen in all entry
paths.

Implementation is contained in `lib/app.dart` and, if needed, `lib/main.dart`.

Key constraint: the normal navigation path (user taps a row on the home screen →
Competition Detail → back → home) must continue to work exactly as today.

## Acceptance criteria

1. Cold start with a remembered competition ID: the Competition Detail screen opens,
   and the AppBar shows a back button that navigates to the bookmark list (`/`).
2. Normal navigation (home → detail → back): behaviour is unchanged — back returns
   to the bookmark list.
3. Cold start with no remembered competition (or an ID not in bookmarks): app opens
   at the bookmark list as before.
4. `flutter test` passes with no regressions.
5. `flutter analyze` reports no new warnings or errors.

## Relevant files

- `lib/app.dart` — `_buildRouter` function and `CompmanApp.initialLocation`
- `lib/main.dart` — `initialLocation` resolution logic
- `docs/features/competitions.md` — update navigation notes if the route
  structure changes
- `docs/plan.md` — mark the corresponding planned task ✅

## References

- User story: `2025-05-06-back.md`
- Introducing commit: `8081f50` (remember last-viewed competition)
- Closed issue for that feature: `issues/done/20260503-remember-last-viewed-competition.md`
