# Hide Airspace and Waypoints cards until a class is selected

Issue derived from: `issues/userstories/2026-07-25-hide-download-panels-before-class-selection.md`

## Feature summary

The Competition Detail screen (`lib/features/competitions/presentation/screens/competition_detail_screen.dart`,
route `/competitions/:id`) shows a header, a class-selection/class-display section, a Task
card, an Airspace download card, a Waypoints download card, a divider, and an XCSoar
directory footer row. See `docs/features/competitions.md` ("Competition Detail Screen"
section) for the full current spec.

## Scope

Visibility-only change: while the competition has no selected class, the Airspace and
Waypoints cards must not render at all (not disabled — absent from the widget tree). Once
a class is selected, both cards render exactly as they do today. No other behavior,
copy, entity, or navigation changes.

Out of scope (must keep rendering regardless of class selection, do not touch their
logic): the `Divider` and the `_XcsoarDirectoryRow` footer row.

Reference mockup for the target "no class selected" state: `docs/design/competition_details_class_selection/screen.png`.

## Current implementation

In `_CompetitionDetailBody.build` (`competition_detail_screen.dart`), the `ListView`
children are built unconditionally:

```dart
children: [
  _HeaderSection(competition: competition),
  const SizedBox(height: 24),
  _ClassSection(
    competition: competition,
    competitionId: competitionId,
  ),
  const SizedBox(height: 12),
  _AirspaceCard(
    competitionId: competitionId,
    competition: competition,
  ),
  const SizedBox(height: 12),
  _WaypointsCard(
    competitionId: competitionId,
    competition: competition,
  ),
  const SizedBox(height: 16),
  const Divider(),
  const SizedBox(height: 16),
  const _XcsoarDirectoryRow(),
],
```

Note the existing pattern this story asks to mirror: `_ClassSection` (same file) already
omits the Task section entirely when no class is selected — it returns early with just
`_ClassPicker(competitionId: competitionId)` when `competition.selectedClass == null`,
and only appends `_TaskSection(...)` to its `Column` once a class is set. Follow the same
"build a conditional list of children" approach for the two cards in
`_CompetitionDetailBody`.

## What to build

In `_CompetitionDetailBody.build`, make the `_AirspaceCard`/`_WaypointsCard` widgets (and
their `SizedBox(height: 12)` spacers) conditional on `competition.selectedClass != null`.
When null, the `ListView` children should go directly from `_ClassSection` to the
`SizedBox(height: 16)` / `Divider` / footer row, i.e.:

- class unset: header, class picker, divider, XCSoar directory row (no Task card either —
  that's already the existing `_ClassSection` behavior, unchanged).
- class set: header, class row + task card (via `_ClassSection`), Airspace card,
  Waypoints card, divider, XCSoar directory row — unchanged from current behavior.

Suggested approach: build the `children` list imperatively (e.g. `[...]` with a spread of
a conditionally-empty sub-list, or an `if (competition.selectedClass != null) ...[ ... ]`
inline block inside the `children` list literal) rather than introducing a new stateless
widget, to keep the change minimal and localized to this one method. Preserve exact
spacing behavior for the "class set" case (no visual change in that state).

Do not change `_AirspaceCard`, `_WaypointsCard`, `_FileDownloadCard`, `_ClassSection`,
`_TaskSection`, `_XcsoarDirectoryRow`, or the `Divider` themselves — only which children
`_CompetitionDetailBody` builds.

## Tests to update

`test/features/competitions/presentation/screens/competition_detail_screen_test.dart` has
an "Airspace & Waypoints card tests" section (starting around the `tAirspaceFile` /
`tWaypointsFile` constants) whose tests currently pump the screen with the default
`_tCompetition` fixture, which has `selectedClass: null`, e.g.:

```dart
await tester.pumpWidget(
  _buildApp(
    _baseOverrides(classes: const [], downloads: const [tAirspaceFile]),
  ),
);
```

With this change, those tests would no longer find the cards (since no class is
selected). Update every test in that section (and the "Download button is disabled while
downloading", "shows on-device filename in ... confirmation", "SAF_NOT_CONFIGURED on
... download navigates to settings", and "aborting settings navigation..." tests, which
also rely on the Airspace card being visible with `classes: const []`) to pass a
`competition:` override with a non-null `selectedClass` (e.g. reuse or extend
`_selectedClassCompetition`/`_tCompetition.copyWith(selectedClass: 'Club')` as
appropriate for each test's existing `installedVersion`/`airspaceVersion`/
`waypointsVersion` assertions — check each test's intent before choosing the fixture, some
already override `competition:` for other reasons and just need `selectedClass` added to
that existing `copyWith`).

Add new test coverage (in the same file) for the visibility rule itself:
- A test asserting the Airspace and Waypoints cards (and their "No airspace/waypoint file
  available" fallback text) are **absent** when `competition.selectedClass` is null,
  regardless of what `downloadsProvider` returns.
- A test asserting both cards **are present** once `competition.selectedClass` is set
  (can reuse/extend an existing "renders airspace/waypoints card" test if convenient).

Run `flutter test` (or `make test` if on the host) for this file specifically first to
confirm the full picture of what breaks, then fix.

## Acceptance criteria

- While `competition.selectedClass` is null, the Airspace card, "No airspace file
  available" text, Waypoints card, and "No waypoint file available" text do not appear
  anywhere in the widget tree of the Competition Detail screen.
- The `Divider` and XCSoar directory row still render in both states (with/without a
  selected class).
- Once a class is selected, the screen's layout and behavior for the Task, Airspace, and
  Waypoints sections is unchanged from before this issue (verify by reviewing existing
  passing tests that exercise the "class selected" state still pass).
- Update `docs/features/competitions.md`: in the "Competition Detail Screen" bullet list,
  note that the Airspace and Waypoints cards (like the Task section) are only rendered
  once a class is selected — mirror the existing wording used for the Task section's
  conditional rendering, and clarify the Divider/XCSoar directory row are unaffected by
  class selection.
- Add a `CHANGELOG.md` entry under `## Unreleased` / `### Changed` describing the
  user-visible effect in plain language, e.g. "Hide airspace and waypoint download options
  until you pick your competition class" (no internal class/file names — see
  `AGENTS.md` changelog style rules).
- `make test` passes.
- `make analyze` reports no issues.
- `make format` reports no changes.

## Related, not in scope

`issues/userstories/2026-05-12-fly-button.md` (open, not yet planned) proposes a "Fly
XCSoar" button inside the Task card. That button's visibility already depends on a
downloaded task, which requires a class to already be selected, so it is unaffected by
this change — no action needed here.
