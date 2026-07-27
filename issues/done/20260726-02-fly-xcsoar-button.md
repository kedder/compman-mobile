# Fly XCSoar button on the Competition Detail screen

## Feature summary

Add a "Fly XCSoar" button to the Competition Detail screen's Task card, letting the pilot
launch the active XCSoar flavor directly from Compman instead of finding it in the
launcher. Full product context, UX rationale, and edge cases are in
[`issues/userstories/2026-05-12-fly-button.md`](userstories/2026-05-12-fly-button.md) — read
it in full before starting; this issue only restates the concrete build steps.

Read [`AGENTS.md`](../AGENTS.md) for general project rules before starting.

## Dependency

**This issue depends on `20260726-01-task-download-version-tracking.md` being complete.**
It relies on `BookmarkedCompetition.taskVersion` and the Task card's "New" badge logic to
determine button visibility. Confirm that issue has been moved to `issues/done/` (or
implement it first) before starting this one.

## Scope

Only the Competition Detail screen gains new UI — no new screens or routes. This issue
covers: the Android bridge launch method, the Dart service wrapper, an active-flavor
provider, and the button itself with its three visibility/enablement states.

## What to build

### 1. Android bridge: `launchPackage`

In `android/app/src/main/kotlin/lt/lebedev/compman_mobile/MainActivity.kt`, add a new
branch to the `xcsoar.saf` channel's `when (call.method)` block (same block as the existing
`isPackageInstalled` handler, around line 81). Pattern:

```kotlin
"launchPackage" -> {
    val packageId = call.argument<String>("packageId")!!
    val intent = packageManager.getLaunchIntentForPackage(packageId)
    if (intent != null) {
        startActivity(intent)
        result.success(null)
    } else {
        result.error("LAUNCH_FAILED", "No launcher activity for $packageId", null)
    }
}
```

Wrap `startActivity` in a try/catch for `ActivityNotFoundException` and call
`result.error("LAUNCH_FAILED", ...)` in the catch, same as the null-intent branch.

### 2. Dart service wrapper

In `lib/core/platform/xcsoar_saf_service.dart`, add:

```dart
Future<void> launchPackage(String packageId) =>
    _channel.invokeMethod('launchPackage', {'packageId': packageId});
```

Do not catch `PlatformException` here — let it propagate, matching the convention used
elsewhere in this class (see doc comments on `resolveFlavorPackageId`).

### 3. Active-flavor provider

Add a `FutureProvider.autoDispose<String?>` (naming suggestion: `activeFlavorPackageIdProvider`)
in `lib/features/competitions/presentation/providers/competitions_providers.dart`, next to
`xcsoarDirectoryUriProvider` (line 101). It should resolve to the active flavor's package
ID, or `null` if no SAF directory is configured or no known flavor matches. Mirror the
chaining logic in `_XcsoarDirectorySettingsScreenState._resolveActiveFlavor`
(`lib/features/xcsoar/presentation/screens/xcsoar_directory_settings_screen.dart:82-103`):
read the SAF URI (return `null` early if empty/null), then call
`XcsoarSafService.resolveFlavorPackageId(uri, kKnownXcsoarFlavors.map((f) => f.packageId).toList())`.

You will also need to distinguish "no SAF configured" from "SAF configured but no flavor
installed" for the button's two disabled-state messages (see table below) — expose enough
from this provider (or a second small provider/computed value) to tell them apart. The
simplest approach: keep this provider as `String? packageId`, and separately watch
`xcsoarDirectoryUriProvider` in the widget to know whether a directory is configured at
all.

### 4. Button style

`AppButtonStyles.primary` (`lib/core/theme/app_theme.dart:106`) uses a 48dp minimum height,
but `docs/ui-guidelines.md:47` requires full-width CTA buttons to be at least 64dp tall.
Add a new `AppButtonStyles.success(BuildContext context)` static method alongside
`primary`/`ghost`, using `context.appColors.success` as the background color,
`colorScheme.onPrimary` (or another appropriate readable foreground — check contrast) as
foreground, and `minimumSize: const Size.fromHeight(64)`. Keep the same shape/text style as
`primary` otherwise.

### 5. UI: the button itself

In `_TaskCard` (`lib/features/competitions/presentation/screens/competition_detail_screen.dart:590-674`),
add the Fly button directly after the "Download task" `SizedBox` (after line 659, before the
already-commented "Installed state" block). It needs: `competition.taskVersion`,
`task.timestamp` (both already available after issue 01's threading), the active-flavor
provider, and the SAF-directory-configured provider.

**Visibility**: render nothing (not even disabled) unless
`competition.taskVersion != null && competition.taskVersion == task.timestamp` — i.e. a
task has been downloaded for this competition and the "New" badge is not showing. Reuse
issue 01's comparison exactly; do not reintroduce separate logic for it.

**States once visible** — implement exactly this table from the user story:

| Condition | Appearance | On tap |
|---|---|---|
| `activeFlavorPackageIdProvider` resolves a package ID | Enabled. Label `Fly ${flavor.displayName}` (look up the matching `XcsoarFlavor` in `kKnownXcsoarFlavors` by package ID — e.g. "Fly XCSoar Jet"). | Call `XcsoarSafService.launchPackage(packageId)`. |
| SAF directory not configured (`xcsoarDirectoryUriProvider` is null/empty) | Disabled, label "Fly XCSoar", subdued secondary text below: "Set up XCSoar folder first." | Non-interactive. |
| SAF configured but no candidate flavor resolves | Disabled, label "Fly XCSoar", subdued secondary text: "XCSoar is not installed." | Non-interactive. |
| Active-flavor provider still loading | Same as the "no flavor" disabled state, updating once resolved. | Non-interactive. |

- Full-width, `ElevatedButton.icon` with `Icons.flight`, styled with the new
  `AppButtonStyles.success`. Disabled state uses standard Flutter opacity reduction
  (Material default ~38%) — no extra styling needed beyond `onPressed: null`.
- No confirmation dialog, no loading spinner (per story — launching is instantaneous and
  not destructive).
- On `PlatformException` (covers `ActivityNotFoundException` and the `LAUNCH_FAILED`
  bridge error), show a dismissible error banner via the existing
  `_downloadErrorsProvider` mechanism (`.add('Could not launch XCSoar. Is it installed?')`) —
  same pattern as `_installTask`'s error handling at line 541-543. Do not build a new
  banner mechanism.

## Acceptance criteria

- Button is invisible until a task is downloaded for the competition, and hides again when
  a newer task version is published (i.e. exactly when the "New" badge would show).
- Tapping the enabled button launches the resolved XCSoar flavor via the Android intent;
  verify manually on a device/emulator with XCSoar installed.
- All three states in the table above render correctly, including the loading transition.
- A failed launch shows the dismissible error banner and does not crash the screen.
- Button meets the 64dp minimum height requirement.
- Widget tests cover: button hidden pre-download, visible+enabled with a resolved flavor,
  visible+disabled with each of the two "not ready" messages, and the error-banner path on
  a thrown `PlatformException`.
- `make test` passes.
- `make analyze` reports no new issues.
- `make format` reports no changes.
- Update `docs/features/xcsoar.md`'s Android bridge methods table
  (around line 129-142) to add `launchPackage`, and also add the pre-existing
  `resolveFlavorPackageId` if still missing there. Update `docs/features/competitions.md`
  to describe the Fly button and its visibility rule, per the Documentation Maintenance
  table in `AGENTS.md`.

## Notes

- Reference this issue's filename (`20260726-02-fly-xcsoar-button.md`) in every commit, per
  [`issues/AGENTS.md`](AGENTS.md).
- Once both issues are done, move the user story
  `issues/userstories/2026-05-12-fly-button.md` to `issues/userstories/done/`.
