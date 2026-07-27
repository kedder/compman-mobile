# Flight Logs panel on Competition Detail screen

Derived from `issues/userstories/2026-07-25-email-flight-log-after-flight.md` ("Suggest
Emailing Today's Flight Logs to Organizers After Flying"). Read that file in full — it has
already been through Product Owner refinement, including six resolved open questions and a
detailed UX proposal (the "Flight Logs panel" bullet under "Concrete UX proposal" is the
primary spec for this issue). **One correction, confirmed with the user during planning:**
ignore the "review/resend an older log" sentence inside the "Zero-logs state" paragraph — it
is stale/inconsistent with the rest of the document. The zero-logs state has **no** action
button at all; the Flight Log screen is reachable **only** via this panel's "Email" action,
which itself only appears when at least one log exists for today.

This is issue 3 of 3 in this batch, and completes the user-reachable flow. **This issue
depends on both**:

- `20260727-01-flight-log-domain-and-saf-read.md` (`todaysFlightLogsProvider`)
- `20260727-02-flight-log-screen.md` (the `/competitions/:id/flight-logs` route this panel
  navigates to)

Do not start until both are merged/complete.

## Feature summary

See `20260727-01-flight-log-domain-and-saf-read.md`'s "Feature summary" for the full
3-issue batch context.

## Scope

Add a persistent, always-visible "Flight Logs" panel to `CompetitionDetailScreen`
(`lib/features/competitions/presentation/screens/competition_detail_screen.dart`), and make
it refresh when the app resumes from the background (not just on fresh navigation).

### 1. Placement

Read the current `_CompetitionDetailBody.build` method first — its `ListView` currently
renders, in order: `_HeaderSection`, `_ClassSection` (which internally renders the Task
card), then, only `if (competition.selectedClass != null)`, `_AirspaceCard` and
`_WaypointsCard`, then a `Divider` and `_XcsoarDirectoryRow`.

Insert the new Flight Logs panel **after** that `if (competition.selectedClass != null)`
block (i.e. it is a sibling of that block, not inside its `if`), and **before** the final
`Divider`/`_XcsoarDirectoryRow`. Unlike the Airspace/Waypoints cards, the Flight Logs panel
is **not** gated by class selection — it always renders regardless of whether a class has
been picked yet. (This is intentionally different from the class-selection gate implemented
per `issues/userstories/2026-07-25-hide-download-panels-before-class-selection.md` — that
gate is unrelated to this panel; see the story's "Related stories" section for why.)

### 2. Panel widget

New private widget in `competition_detail_screen.dart` (or split into its own file under
`lib/features/competitions/presentation/widgets/` if you find that cleaner — follow whichever
convention keeps the file sizes reasonable; other cards for this screen currently live
inline as private widgets in the screen file itself, so inline is the path of least
resistance).

Watches `todaysFlightLogsProvider` (from issue 1 — do not create a duplicate/local version of
this provider).

**Visual treatment:** the story asks for the same surface/border/elevation treatment as the
Airspace/Waypoints cards (`Card` on `surface-container-lowest` with a 1dp `outline-variant`
border and `shadow-sm`, per `docs/design/design.md`), but *not* the full `TwoToneCard`
header/white-body/tinted-footer split — this panel is "just a one-line summary plus an inline
action". Read `lib/core/widgets/two_tone_card.dart` first: build a new, simpler container
that reuses the *same* `BoxDecoration` (white/`Colors.white` background, `BorderRadius.circular(12)`,
`Border.all(color: colorScheme.outlineVariant)`, and the same `boxShadow` values) but with a
single `Padding(EdgeInsets.all(12))` around the content — no `Divider`, no tinted footer
region, no separate section-title header row (the story's own example is just
`"2 flight logs recorded [Email]"` — no "Flight Logs" title text above it).

**States:**

- **Loading:** small `Center(child: CircularProgressIndicator())`, matching how
  `_AirspaceCard`/`_WaypointsCard` handle their own `downloadsProvider` loading state
  (`skipLoadingOnReload: true` on the `.when(...)` so pull-to-refresh/app-resume reloads
  don't flash a spinner over existing content).
- **Error (including `SAF_NOT_CONFIGURED`):** unlike the Airspace/Waypoints download errors
  (which append a dismissible bottom error banner because they're the direct result of a
  user tapping "Download"), this panel's fetch is a passive background check with no user
  action behind it. On **any** error from `todaysFlightLogsProvider` — including a thrown
  `PlatformException(code: 'SAF_NOT_CONFIGURED')` when no XCSoar directory has been granted
  yet — fall back to the same muted empty-state text as the zero-files case below (do not
  show a dismissible error banner or force navigation to XCSoar folder setup; this panel
  should never interrupt the pilot).
- **Zero files:** muted text, exact style/color already used for `"No airspace file
  available"` / `"No waypoint file available"` in `_AirspaceCard`/`_WaypointsCard` (`Text`
  with `theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)`). Copy:
  `"No flight logs recorded today"`. **No button, no tappable action** — this state has no
  way into the Flight Log screen (confirmed decision; see the correction note at the top of
  this issue).
- **Non-zero files:** a single `Row` (or `Wrap`, if needed for narrow screens) containing:
  1. A small leading icon (pick something sensible, e.g. `Icons.description_outlined`).
  2. Body text: `"${files.length} flight log recorded"` when `files.length == 1`, else
     `"${files.length} flight logs recorded"` — exact singular/plural wording from the
     story's own example.
  3. An inline `TextButton` (or similar low-emphasis tappable text, consistent with
     `docs/ui-guidelines.md`'s button-hierarchy guidance for an inline non-primary action)
     labelled `"Email"`, which does `context.push('/competitions/$competitionId/flight-logs')`
     (the route built in `20260727-02-flight-log-screen.md`).

### 3. Refresh on app resume

The story requires the panel to reflect reality "whenever the Competition Detail screen for
a bookmarked competition becomes active (including resuming from the background, not just a
fresh navigation)" — a pilot lands, backgrounds Compman (or switches to XCSoar and back), and
returns to find the summary already updated, with no manual pull-to-refresh needed.

`_CompetitionDetailScreenState` is already a `ConsumerState`. Add `WidgetsBindingObserver` to
its mixins, register it in `initState` (`WidgetsBinding.instance.addObserver(this)`) and
unregister in `dispose` (`WidgetsBinding.instance.removeObserver(this)`, remembering to
still call `super.dispose()`). Override `didChangeAppLifecycleState`: when the new state is
`AppLifecycleState.resumed`, call `ref.invalidate(todaysFlightLogsProvider)` (guard with a
`mounted` check, matching the existing guard style used elsewhere in this file, e.g. in
`_navigateToSettings`).

Do not touch any other providers in this lifecycle callback — only
`todaysFlightLogsProvider` needs the resume-triggered refresh; the rest of the screen
(tasks, downloads) already has its own pull-to-refresh/AppBar-refresh mechanism and is out of
scope here.

### 4. Pull-to-refresh / AppBar refresh parity (optional but recommended)

`_CompetitionDetailBody`'s existing `RefreshIndicator.onRefresh` and the AppBar's manual
refresh `IconButton` both currently invalidate `latestTasksProvider` and `downloadsProvider`.
Add `todaysFlightLogsProvider` to both invalidation lists so a manual pull-to-refresh also
picks up newly-landed flight logs, not just app-resume.

## Documentation

Per `AGENTS.md`'s documentation-maintenance table:

- `docs/features/competitions.md` — add a "Flight Logs panel" bullet to the "Competition
  Detail Screen" section, following the existing bullet style used for the Airspace/Waypoints
  cards (placement, visibility rule, empty-state copy, and the app-resume refresh behavior).
- `docs/plan.md` — mark this 3-issue batch as done with a brief implementation note, per the
  existing entry style (this can be a single combined entry covering all three issues, since
  this is the issue that completes the user-visible feature).
- `CHANGELOG.md` — add an entry under `## Unreleased` → `### Added`, plain-language, e.g.
  "Show today's flight logs on the competition screen, with a one-tap way to email them to
  organizers for scoring" (or similar — keep it a pilot-facing sentence per the changelog
  style rules in `AGENTS.md`, no internal terms like "SAF" or "panel").

## Testing

New/extended widget tests in
`test/features/competitions/presentation/screens/competition_detail_screen_test.dart` (read
its existing structure and provider-override conventions first — in particular how
`todaysFlightLogsProvider` will need to be overridden or backed by a fake
`XcsoarSafService`/`GetTodaysFlightLogs`, mirroring how `downloadsProvider`/`xcsoarSafServiceProvider`
are already faked in that file). Cover:

- `files.length == 1` → singular "1 flight log recorded" text.
- `files.length > 1` → plural "N flight logs recorded" text.
- Zero files → muted "No flight logs recorded today" text, and no "Email" button present.
- A `SAF_NOT_CONFIGURED`/other error from the provider → same muted empty-state text (no
  error banner appended to `_downloadErrorsProvider`).
- Tapping "Email" navigates to `/competitions/:id/flight-logs` (register a stub route in the
  test's `GoRouter`, matching how the test file already stubs `/settings/xcsoar-directory`).
- Panel renders regardless of whether `competition.selectedClass` is null or set (i.e. not
  gated by class selection, unlike the Airspace/Waypoints cards).
- App-resume triggers a refresh: simulate via
  `tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed)` (or the
  equivalent available on the Flutter/test SDK version in use — check what's already
  available in `flutter_test` for this project's Flutter version) and confirm the provider is
  invalidated/re-fetched. If this proves awkward to simulate reliably in a widget test, it is
  acceptable to test the `didChangeAppLifecycleState` invalidation logic more directly (e.g.
  by calling the state's lifecycle callback through a `GlobalKey`), but attempt the full
  widget-level simulation first.

## Acceptance criteria

- `make format` reports no changes.
- `make test` passes, including all new/updated widget tests.
- `make analyze` is clean.
- Manually verified on Competition Detail: panel is visible before and after class selection,
  updates its count on pull-to-refresh, AppBar refresh, and app resume, and "Email" opens the
  Flight Log screen from issue 2.
- `docs/features/competitions.md` and `docs/plan.md` updated; `CHANGELOG.md` has a new entry
  under `## Unreleased`.
