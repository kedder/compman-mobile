# Feature: XCSoar Integration

Compman manages the XCSoar data directory so it can deliver downloaded task, airspace, and
waypoint files directly to the flight computer app. Because multiple XCSoar variants exist
on Android, and because Android 11+ blocks direct access to another app's `Android/data`
folder, the flavor-picker screen guides the user through a one-tap SAF permission grant for
the right directory — without exposing raw file-system paths.

---

## Known XCSoar Flavors

Defined in `lib/features/xcsoar/domain/xcsoar_flavor.dart` as `kKnownXcsoarFlavors`.

| Display Name | Package ID |
|---|---|
| XCSoar | `org.xcsoar` |
| XCSoar Jet | `com.zinuzoid.xcsoar_jet` |
| XCSoar Play | `org.xcsoar.play` |
| XCSoar FOSS | `org.xcsoar.foss` |

All four package IDs are declared in the `<queries>` element of `AndroidManifest.xml` so
`PackageManager.getPackageInfo` returns results on Android 11+ (package-visibility
enforcement requires explicit `<queries>` declarations since API 30).

---

## Flavor State Detection

Each flavor is probed at screen-open time via two `XcsoarSafService` calls:

| State | Condition |
|---|---|
| `notInstalled` | `isPackageInstalled` returns `false` |
| `warning` | Package installed **and** `canWriteToMediaDir` returns `false` |
| `ready` | Package installed **and** `canWriteToMediaDir` returns `true` |

**Android 11+ restriction:** `Android/data/<pkg>/` cannot be accessed by other apps via
SAF. XCSoar defaults to `Android/data` when its `xcsoar.log` is found there (set on
older installs). `Android/media/<pkg>/` is writable and is the correct SAF target; a
`true` result from `canWriteToMediaDir` confirms this path exists and is usable.

---

## Screen: XCSoar Directory Settings (`/settings/xcsoar-directory`)

**Class:** `XcsoarDirectorySettingsScreen` in
`lib/features/xcsoar/presentation/screens/xcsoar_directory_settings_screen.dart`.

### Flavor list

A `ListView` of `ListTile` rows, one per entry in `kKnownXcsoarFlavors`, sorted
ready → warning → notInstalled so the actionable choice appears first. Each tile shows
the display name, the package ID in subdued secondary text, and an `AppBadge` trailing
widget:

| Badge label | Background | Meaning |
|---|---|---|
| Ready | `AppColors.badgeLive` (green) | Tap to open the SAF picker |
| Needs setup | `colorScheme.error` (red) | Tap to expand the guidance card |
| Not installed | `colorScheme.surfaceContainerHighest` (grey) | Non-interactive |

### AppBar title variant

`fromDownloadFlow: false` → title is **"XCSoar Folder"** (reached from Settings menu).
`fromDownloadFlow: true` → title is **"Set Up XCSoar Folder"** (reached from a pending
download that failed with `SAF_NOT_CONFIGURED`).

### Auto-pop on success (download flow)

When `fromDownloadFlow` is `true`, a successful SAF picker result (either
`_pickDirectoryForPackage` or `_pickDirectory` returning `'ok'`) calls
`context.pop()` instead of showing the "XCSoar folder configured" SnackBar.
The competition detail screen resumes immediately and auto-starts the download.
The suppression of the SnackBar is intentional — the download-completion
SnackBar shown moments later makes a setup SnackBar redundant and noisy.

When `fromDownloadFlow` is `false`, the existing behaviour is unchanged: the
screen stays open and the success SnackBar is shown.

### Blocked-writability guidance card (`_BlockedFlavorGuidanceCard`)

Tapping a `warning`-state tile toggles an inline non-dismissible `Card` shown directly
below that tile in the `ListView`. The card uses `colorScheme.errorContainer` and lists
three numbered recovery options:

1. **Back up, uninstall, and reinstall** *(preserves files if backed up)*
2. **Clear XCSoar's app data** *(settings and data lost)*
3. **Uninstall and reinstall** *(simplest, data lost)*

Tapping the same warning tile again collapses the card. No SAF picker is launched for
warning-state flavors.

### Advanced: Choose custom folder

A `ListTile` below a `ADVANCED` section header opens the generic SAF folder picker
(`pickDirectory`) for users who need a non-standard location.

### Reset Permission button

An `OutlinedButton` styled with `colorScheme.error` foreground. Calls
`XcsoarSafService.clearSafPermission()`, invalidates `xcsoarDirectoryUriProvider`, and
shows a SnackBar "Permission cleared".

---

## Flow: Contextual Setup from Competition Detail

```
1. User taps "Download task / Airspace / Waypoints"
2. XcsoarSafService.writeFile() throws PlatformException(code: 'SAF_NOT_CONFIGURED')
3. Competition Detail navigates to:
     /settings/xcsoar-directory
       ?from=download
       &competitionId=<id>
       &kind=<kind>         ("task" | "airspace" | "waypoints")
4. User configures a flavor — or navigates back without completing setup
5. context.push() future resolves; Competition Detail reads xcsoarDirectoryUriProvider
6a. URI non-null → _autoResumeDownload(kind) re-runs the download automatically
6b. URI null/empty → dismissible error banner: "XCSoar folder setup was cancelled. Go to Settings → XCSoar Folder to try again."
```

The pending-download context is captured in `PendingDownload`
(`lib/features/competitions/domain/entities/pending_download.dart`) which serialises the
`competitionId` and `kind` into the URI query string.

---

## Android Bridge Methods (`xcsoar.saf` MethodChannel)

Kotlin implementation lives in `android/app/src/main/kotlin/.../MainActivity.kt`.

| Method | Arguments | Return | Description |
|---|---|---|---|
| `pickDirectory` | — | `"ok"` / `"cancelled"` | Launches SAF picker with auto-detected initial path |
| `pickDirectoryForPackage` | `packageId: String` | `"ok"` / `"cancelled"` | Launches SAF picker pre-navigated to `Android/media/<pkg>/` |
| `writeFile` | `bytes: ByteArray, filename: String` | `"ok"` / error | Writes a file to the stored SAF directory |
| `getSafDirectoryUri` | — | `String?` | Returns stored SAF tree URI or `null` |
| `clearSafPermission` | — | `"ok"` | Releases persisted URI grant and clears stored URI |
| `isPackageInstalled` | `packageId: String` | `Boolean` | Returns `true` if the package is installed |
| `canWriteToMediaDir` | `packageId: String` | `Boolean` | Returns `true` if `Android/media/<pkg>/` is writable via SAF |
| `resolveFlavorPackageId` | `uri: String, candidates: List<String>` | `String?` | Returns the candidate package ID whose canonical media-directory tree URI matches `uri`, or `null` if none match |
| `launchPackage` | `packageId: String` | `null` / error | Launches the package's default launcher activity; errors with `LAUNCH_FAILED` if there is no launcher activity or the intent cannot be started |
| `listFlightLogs` | — | `List<Map<String, String>>` / error | Lists `.igc` files under `logs/` in the stored SAF directory as `{filename, uri}` maps; returns an empty list if no `logs/` folder exists yet; errors with `SAF_NOT_CONFIGURED` if no directory is granted |
| `shareFlightLogs` | `uris: List<String>, recipient: String` | `null` / error | Launches an `ACTION_SEND_MULTIPLE` share/send intent (biased toward mail apps) with `uris` attached and `recipient` pre-filled; errors with `NO_MAIL_APP` if no app can handle the intent |

SAF tree URI grants are stored in Android `SharedPreferences` (not Hive) so they are
accessible from Kotlin before Flutter initialises.

---

## Dart Service: `XcsoarSafService`

Located at `lib/core/platform/xcsoar_saf_service.dart`. Plain Dart class — no Riverpod
provider wrapping inside the class itself. Exposed for injection via
`xcsoarSafServiceProvider` (`Provider<XcsoarSafService>`) in `lib/core/di/providers.dart`.

| Method | Bridge method |
|---|---|
| `pickDirectory()` | `pickDirectory` |
| `pickDirectoryForPackage(packageId)` | `pickDirectoryForPackage` |
| `writeFile(bytes, filename)` | `writeFile` |
| `getSafDirectoryUri()` | `getSafDirectoryUri` |
| `clearSafPermission()` | `clearSafPermission` |
| `isPackageInstalled(packageId)` | `isPackageInstalled` |
| `canWriteToMediaDir(packageId)` | `canWriteToMediaDir` |
| `resolveFlavorPackageId(storedUri, candidates)` | `resolveFlavorPackageId` |
| `launchPackage(packageId)` | `launchPackage` |
| `listFlightLogs()` | `listFlightLogs` |
| `shareFlightLogs({uris, recipient})` | `shareFlightLogs` |

`listFlightLogs()` returns raw `List<Map<String, String>>` rather than a domain
entity — `core/platform/` classes must not import feature `domain/` types (see
the dependency rule above). `GetTodaysFlightLogs`
(`lib/features/competitions/domain/usecases/get_todays_flight_logs.dart`) maps
each map to a `FlightLogFile` entity and filters to today's date.
