# Rename Task Download Button and SnackBar Copy

User story: `2026-05-01-rename-button.md`

## Feature summary

The Competition Detail screen has a task download button whose label reads
"Install XCSoar Task" and a success SnackBar that reads "Default.tsk installed
in XCSoar folder". Both use technical jargon that does not match the plain-English
"Download task" language specified in `docs/features/overview.md`.

## Scope

Update the copy for the task download button and success SnackBar in
`competition_detail_screen.dart`, and update the widget tests that assert on
those strings. No layout, behavior, or architecture changes are needed.

## Task

### File to modify

`lib/features/competitions/presentation/screens/competition_detail_screen.dart`

Locate the `_TaskCard` widget (around line 482). Inside the `ElevatedButton.icon`
in `_TaskSectionState._installTask` and `_TaskCard.build`:

1. **Button label — default state**
   - Current: `'Install XCSoar Task'`
   - Target: `'Download task'`

2. **Button label — loading/downloading state**
   - Current: `'Installing...'`
   - Target: `'Downloading...'`

3. **SnackBar message — success**
   Locate `ScaffoldMessenger.of(context).showSnackBar(...)` in
   `_TaskSectionState._installTask` (around line 419).
   - Current: `'Default.tsk installed in XCSoar folder'`
   - Target: `'Task downloaded'`

### Test file to update

`test/features/competitions/presentation/screens/competition_detail_screen_test.dart`

Two tests reference the old button label; update both:

- Test `'renders the task card without a new-update badge'`:
  - `find.text('Install XCSoar Task')` → `find.text('Download task')`

- Test `'appends a dismissible error banner when task download fails'`:
  - `find.text('Install XCSoar Task')` (the tap target) → `find.text('Download task')`

- Test `'dismissing an error banner removes it from the screen'`:
  - `find.text('Install XCSoar Task')` (the tap target) → `find.text('Download task')`

## Acceptance criteria

- Running `make test` passes with no failures.
- `make analyze` reports no issues.
- The button on the Competition Detail screen shows "Download task" in its idle
  state and "Downloading..." while a download is in progress.
- The SnackBar shown after a successful download reads "Task downloaded".
- No other behavior, layout, or file is changed.

## Constraints

- Follow all rules in `AGENTS.md` (commit message format, documentation
  maintenance).
- The `docs/features/competitions.md` description of the Competition Detail
  Screen currently says `"Install XCSoar Task"` — update that phrase to
  `"Download task"` in the same commit so documentation stays accurate.
- `docs/features/overview.md` already uses "Download Task" language and does
  not need to change.
- `docs/plan.md`: mark the relevant task ✅ with a brief implementation note
  once the change is complete (or add a 📋 item if no matching entry exists).
- No ADR needed — this is a copy change with no architectural implications.

## Reference

The three string literals to change all live in a single file. Confirm there
are no other occurrences of "Install XCSoar Task" elsewhere in `lib/` or
`test/` before finishing.
