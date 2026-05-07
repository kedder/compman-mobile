# Auto-Pop XCSoar Directory Screen After Successful Flavor Selection in Download Flow

## Feature summary

`XcsoarDirectorySettingsScreen` is reached either from the app's Settings menu
(standalone) or via `context.push(...)` inside `_SafNavigationMixin` when a
download is pending and the XCSoar folder has not yet been configured.  In the
download flow the mixin resumes after `context.push` completes (i.e. after the
screen pops), reads the newly stored URI, and auto-starts the download.  The
screen currently never pops itself, so the user must press the system back button
to trigger the download — a confusing and invisible step.

User story: `issues/userstories/2026-05-07-auto-pop-after-flavor-selection.md`

## Scope

This issue covers **one screen, one behavioral change**:

- `XcsoarDirectorySettingsScreen`
  (`lib/features/xcsoar/presentation/screens/xcsoar_directory_settings_screen.dart`)

No other file requires a logic change. The competition detail screen
(`_SafNavigationMixin`) already handles everything correctly once `context.push`
completes.

## Task

### Production code

In `_XcsoarDirectorySettingsScreenState`:

1. **`_pickDirectoryForPackage`** — when `result == 'ok'` and
   `widget.fromDownloadFlow` is `true`:
   - Invalidate `xcsoarDirectoryUriProvider` (keep as-is).
   - Call `context.pop()` instead of `_showPickerSuccess()`.
   - Do **not** show the "XCSoar folder configured" SnackBar (the competition
     screen will show a download-completion SnackBar moments later; an extra
     setup SnackBar is noisy and redundant).

2. **`_pickDirectory`** (custom folder path) — apply the same conditional:
   when `result == 'ok'` and `widget.fromDownloadFlow` is `true`:
   - Invalidate the provider (keep as-is).
   - Call `context.pop()` instead of `_showPickerSuccess()`.
   - Same SnackBar suppression rationale.

3. **`_clearDirectory`** — no change. The user intentionally cleared the
   permission and must stay on-screen to pick again.

4. **Cancelled / error paths** — no change in either mode.

When `fromDownloadFlow` is `false` the existing behavior is correct and must
remain unchanged: stay on screen, show the success SnackBar.

### Tests

Add widget tests to
`test/features/xcsoar/xcsoar_directory_settings_screen_test.dart`.

The current test helper builds the screen inside a plain `MaterialApp` with no
named routes, so `context.pop()` will call `Navigator.pop` on the single-route
stack, removing the route.  Verify the pop by wrapping the screen in a
`MaterialApp` with two routes: a home route that pushes to the screen, and the
screen route itself.  After the picker completes, assert that the screen is no
longer in the widget tree (i.e. the home route is visible again).

Required new tests:

- **`fromDownloadFlow + _pickDirectoryForPackage returns ok` → screen pops**
  - Push `XcsoarDirectorySettingsScreen(fromDownloadFlow: true)` onto a
    Navigator from a dummy home page.
  - Stub `pickDirectoryForPackage` to return `'ok'`.
  - Tap a ready-state flavor tile and `pumpAndSettle`.
  - Assert the screen widget is no longer in the tree (home page is visible).
  - Assert the success SnackBar text `'XCSoar folder configured'` is **not**
    shown.

- **`fromDownloadFlow + _pickDirectory returns ok` → screen pops**
  - Same setup.
  - Stub `pickDirectory` to return `'ok'`.
  - Tap "Choose custom folder" and `pumpAndSettle`.
  - Assert the screen widget is no longer in the tree.
  - Assert the success SnackBar is **not** shown.

- **`fromDownloadFlow false + _pickDirectoryForPackage returns ok` → stays on screen**
  - Build with `fromDownloadFlow: false`.
  - Tap a ready-state flavor tile and `pumpAndSettle`.
  - Assert the `XcsoarDirectorySettingsScreen` is still present.
  - Assert the success SnackBar `'XCSoar folder configured'` is shown.

- **`fromDownloadFlow false + _pickDirectory returns ok` → stays on screen**
  - Build with `fromDownloadFlow: false`, stub `pickDirectory` to `'ok'`.
  - Tap "Choose custom folder" and `pumpAndSettle`.
  - Assert the screen is still present and the success SnackBar is shown.

## Completion condition

- All four new tests pass.
- All pre-existing tests in `xcsoar_directory_settings_screen_test.dart`
  continue to pass.
- `make test` passes with no failures.
- `make analyze` reports no issues.

## Documentation

- Update `docs/features/xcsoar.md` to note that when
  `fromDownloadFlow` is `true` the screen auto-pops on success instead of
  showing a SnackBar.
- Mark the corresponding task done in `docs/plan.md`.
