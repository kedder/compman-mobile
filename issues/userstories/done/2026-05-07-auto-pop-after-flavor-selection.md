# Auto-Dismiss Flavor Picker After Selecting a Flavor in Download Flow

When choosing to download an airspace file, the XCSoar flavor selection screen appears (correctly). However, when I select a flavor, nothing happens — I have to press the back button to return to the competition screen. That triggers the download, but it's very non-intuitive. We need to make switching back to the competition screen happen automatically after selecting a flavor.

## Product Owner Notes

### Problem analysis

The contextual SAF setup flow (implemented in issue `20260503-03`) uses `context.push` to
navigate from Competition Detail to `/settings/xcsoar-directory`. When the user returns
(via the back button), `_navigateToSettings` in `_SafNavigationMixin` resumes after the
`await context.push(...)` call, reads `xcsoarDirectoryUriProvider`, and auto-starts the
pending download.

The issue is that after tapping a ready-state flavor tile on `XcsoarDirectorySettingsScreen`,
`_pickDirectoryForPackage` launches the SAF folder picker, the user grants the permission,
and the method completes with result `'ok'`. At this point:

1. The SAF URI is now stored.
2. `xcsoarDirectoryUriProvider` is invalidated.
3. A "XCSoar folder configured" SnackBar is shown.
4. The screen stays open — nothing pops it.

The user must manually press the back button. Only then does `context.push` complete in
Competition Detail, `_navigateToSettings` reads the now-configured URI, and the download
starts. This is confusing: the user selected a flavor, saw a success message, and the
screen appeared frozen — they have to guess that "back" does something.

The fix is: when `fromDownloadFlow` is `true` and `_pickDirectoryForPackage` completes
with `'ok'`, the screen should pop itself automatically.

The same behavior applies to `_pickDirectory` (the "Choose custom folder" advanced path):
if the user arrives via the download flow and picks a custom folder, the screen should
also auto-pop so the download can resume.

The `_clearDirectory` path must not trigger an auto-pop — the user cleared the permission
intentionally and should stay on the screen to pick again.

### Affected screen

`XcsoarDirectorySettingsScreen`
(`lib/features/xcsoar/presentation/screens/xcsoar_directory_settings_screen.dart`).

No other screen is affected. The Competition Detail screen (`_SafNavigationMixin`) already
handles everything correctly once `context.push` completes — no changes are needed there.

### Proposed UX behavior

When `fromDownloadFlow` is `true`:

- After `_pickDirectoryForPackage` returns `'ok'` → invalidate provider, then call
  `context.pop()`. Do not show the "XCSoar folder configured" SnackBar in this path
  (the competition screen will show a download-completion SnackBar moments later, making
  a setup SnackBar redundant and noisy).
- After `_pickDirectory` (custom folder) returns `'ok'` → same: invalidate provider,
  then call `context.pop()`. Same SnackBar suppression rationale.

When `fromDownloadFlow` is `false` (Settings menu entry):

- Existing behavior is correct: stay on the screen and show the success SnackBar.

The `'cancelled'` result from both pickers and all `PlatformException` paths are
unchanged in both modes — stay on screen, show appropriate SnackBar or error.

### Related stories

- Closed user story `issues/userstories/done/2026-05-06-mark-selected-flavor.md` —
  implemented the active flavor indicator on this same screen; issue
  `20260507-01-mark-selected-xcsoar-flavor.md` (done).
- Closed issue `20260503-03-detail-screen-saf-not-configured-navigation.md` (done) — built
  the `_SafNavigationMixin`/`PendingDownload` flow that this bug affects.
- The bug occurs specifically in the interaction between these two features: the flavor
  picker screen (new) and the download-flow navigation (new), both complete, but the
  handoff between them is missing the auto-pop.

### Relevant mockups

None — this is a navigation behavior fix, not a visual redesign. The screen layout is
unchanged.

### Scope estimate

Small — one screen, one method, a conditional `context.pop()` call, plus widget test
coverage for the two auto-pop paths and a test confirming non-download-flow mode is
unaffected.
