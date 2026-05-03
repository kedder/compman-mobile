# XCSoar Flavor Picker: Platform Detection, Writability Badges, and Screen Redesign

## Feature summary

Users need to configure an XCSoar data directory before any download can succeed.
Today the Settings screen shows a single "Change Directory" button and a raw SAF URI —
which gives first-time users no guidance at all. This issue replaces that screen with a
structured flavor-picker list showing each known XCSoar variant, its install state, and
its writability status, so users can configure the correct directory in one tap without
ever seeing a file-system path.

## Scope

This issue covers:

1. Adding two new MethodChannel calls to `MainActivity.kt` for package detection and
   writability probing (`isPackageInstalled`, `canWriteToMediaDir`).
2. Extending `XcsoarSafService` with the new Dart-side wrappers and a
   `pickDirectoryForPackage` variant that pre-navigates the picker to the correct path.
3. Defining the `XcsoarFlavor` value type (display name + package ID).
4. Fully replacing the `XcsoarDirectorySettingsScreen` body with the flavor-picker
   `ListView`, including per-flavor `ListTile` rows with state badges, sorting (ready →
   warning → not-installed), the custom-folder "Advanced" row at the bottom, and the
   retained "Reset Permission" / "Clear" button.
5. Widget tests and documentation updates.

This issue does **not** cover: the inline blocked-writability guidance card (issue 02),
or the auto-navigation from Competition Detail (issue 03).

## What to build

### 1. Android bridge — new MethodChannel calls

Add two new methods to the `xcsoar.saf` MethodChannel in `MainActivity.kt`.

#### `isPackageInstalled`

```kotlin
"isPackageInstalled" -> {
    val pkg = call.argument<String>("packageId")!!
    val installed = try {
        packageManager.getPackageInfo(pkg, 0)
        true
    } catch (_: android.content.pm.PackageManager.NameNotFoundException) {
        false
    }
    result.success(installed)
}
```

#### `canWriteToMediaDir`

Checks whether `Android/media/<pkg>/` is accessible for writing. On Android 11+ the
`Android/data/<pkg>/` path is blocked by the OS, so the only writable path is
`Android/media/<pkg>/`. The check builds the media-dir SAF tree URI for the package and
queries whether the content resolver can list children from it (a proxy for write
access). If the directory does not exist or cannot be listed, the package is considered
not writable.

```kotlin
"canWriteToMediaDir" -> {
    val pkg = call.argument<String>("packageId")!!
    val writable = checkMediaDirWritable(pkg)
    result.success(writable)
}
```

Add the helper:

```kotlin
private fun checkMediaDirWritable(pkg: String): Boolean {
    return try {
        val path = "primary:Android/media/$pkg"
        val encoded = Uri.encode(path)
        val docUri = Uri.parse(
            "content://com.android.externalstorage.documents/document/$encoded"
        )
        val treeUri = DocumentsContract.buildTreeDocumentUri(
            "com.android.externalstorage.documents", encoded
        )
        val childUri = DocumentsContract.buildChildDocumentsUriUsingTree(
            treeUri, DocumentsContract.getTreeDocumentId(treeUri)
        )
        contentResolver.query(childUri, arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID),
            null, null, null)?.use { it.count >= 0 } ?: false
    } catch (_: Exception) {
        false
    }
}
```

Also add a `pickDirectoryForPackage` method that launches the SAF picker pre-navigated
to `Android/media/<pkg>/`, identical to the existing `pickDirectory` logic but
constructing the initial URI from the supplied package ID rather than calling
`getXcsoarMediaPath()`:

```kotlin
"pickDirectoryForPackage" -> {
    val pkg = call.argument<String>("packageId")!!
    val path = "primary:Android/media/$pkg"
    val encoded = Uri.encode(path)
    val initialUri = Uri.parse(
        "content://com.android.externalstorage.documents/document/$encoded"
    )
    pendingResult = result
    safLauncher.launch(initialUri)
}
```

Note: `QUERY_ALL_PACKAGES` is not needed for these four known packages. Use
`<queries>` in `AndroidManifest.xml` instead:

```xml
<queries>
  <package android:name="com.xcsoar" />
  <package android:name="com.zunuzoid.xcsoar_jet" />
  <package android:name="com.xcsoar.play" />
  <package android:name="com.xcsoar.foss" />
</queries>
```

Add these `<package>` entries inside the existing `<queries>` block in
`android/app/src/main/AndroidManifest.xml`.

### 2. Dart-side platform service additions

In `lib/core/platform/xcsoar_saf_service.dart`, add:

```dart
/// Returns true if the given Android package is installed on the device.
Future<bool> isPackageInstalled(String packageId) async {
  final result = await _channel.invokeMethod<bool>('isPackageInstalled', {
    'packageId': packageId,
  });
  return result ?? false;
}

/// Returns true if [Android/media/<packageId>/] is writable via SAF.
///
/// Returns false if the package is not installed, the directory does not
/// exist, or the OS blocks access (e.g. because XCSoar is using
/// Android/data instead).
Future<bool> canWriteToMediaDir(String packageId) async {
  final result = await _channel.invokeMethod<bool>('canWriteToMediaDir', {
    'packageId': packageId,
  });
  return result ?? false;
}

/// Launches the Android folder picker pre-navigated to [Android/media/<packageId>/].
///
/// Returns `"ok"` on success or `"cancelled"` if the user dismissed the picker.
Future<String> pickDirectoryForPackage(String packageId) async {
  final result = await _channel.invokeMethod<String>('pickDirectoryForPackage', {
    'packageId': packageId,
  });
  return result!;
}
```

### 3. XcsoarFlavor value type

Create `lib/core/platform/xcsoar_flavor.dart`:

```dart
/// Describes a known XCSoar application variant.
///
/// Each flavor has a [displayName] shown to the user and a [packageId]
/// used to detect installation and construct the data directory path.
class XcsoarFlavor {
  /// Creates an [XcsoarFlavor].
  const XcsoarFlavor({required this.displayName, required this.packageId});

  /// Human-readable name shown in the flavor picker list.
  final String displayName;

  /// Android package identifier, e.g. `com.xcsoar`.
  final String packageId;
}

/// The canonical list of known XCSoar variants, in display order.
const List<XcsoarFlavor> kKnownXcsoarFlavors = [
  XcsoarFlavor(displayName: 'XCSoar',      packageId: 'com.xcsoar'),
  XcsoarFlavor(displayName: 'XCSoar Jet',  packageId: 'com.zunuzoid.xcsoar_jet'),
  XcsoarFlavor(displayName: 'XCSoar Play', packageId: 'com.xcsoar.play'),
  XcsoarFlavor(displayName: 'XCSoar FOSS', packageId: 'com.xcsoar.foss'),
];
```

### 4. Replace XcsoarDirectorySettingsScreen body

Fully replace the widget body in
`lib/core/platform/xcsoar_directory_settings_screen.dart`. Retain the class name and
the route (`/settings/xcsoar-directory`) so existing navigation is unchanged.

#### State model

Add `_FlavorState` as a private enum to the file:

```dart
enum _FlavorState { ready, warning, notInstalled }
```

#### Screen state

- In `initState`, call `_loadFlavorStates()` — an async method that calls
  `XcsoarSafService().isPackageInstalled(pkg)` and
  `XcsoarSafService().canWriteToMediaDir(pkg)` for each flavor and builds a
  `Map<String, _FlavorState>` keyed by `packageId`. Store as `_flavorStates`.
- Track `_loading` (bool) during the async load. While loading, show a centered
  `CircularProgressIndicator`.
- Track `_selectedBlockedPackage` (nullable `String`) — the package ID of the currently
  expanded blocked tile (issue 02 renders the guidance card; this issue just stores the
  variable and expands the tile visually with a selected highlight).

#### Sorting

Sort the `kKnownXcsoarFlavors` list for display:

```
ready → warning → notInstalled
```

Flavors with the same state appear in their canonical order from `kKnownXcsoarFlavors`.

#### ListView layout

Replace the existing `ListView` body with:

```
[current-folder ListTile — unchanged]
[Divider]
[section label: "XCSoar App" in labelSmall/caps style]
[for each flavor in sorted order: _FlavorTile]
[Divider]
[section label: "Advanced" in labelSmall/caps style]
[ListTile: "Choose custom folder", subtitle: "Use any folder on your device", trailing: Icon(Icons.folder_open), onTap: _pickDirectory (existing)]
[Padding: OutlinedButton "Reset Permission" / "Clear" — existing, red foreground]
[Padding: info text — existing]
```

#### `_FlavorTile` widget

A private `StatelessWidget` accepting:
- `XcsoarFlavor flavor`
- `_FlavorState state`
- `bool isSelected`
- `VoidCallback? onTap`

Renders a `ListTile` with:
- `title`: `Text(flavor.displayName)`
- `subtitle`: `Text(flavor.packageId)` in `bodySmall` with `colorScheme.secondary`
- `trailing`: A badge using `AppBadge` widget with the correct label and colors per
  state:

  | State | Label | `AppBadge` backgroundColor | foregroundColor |
  |---|---|---|---|
  | `ready` | `"Ready"` | `appColors.badgeLive` (green) | `appColors.badgeLiveText` |
  | `warning` | `"Needs setup"` | `colorScheme.error` (amber substitute) | `colorScheme.onError` |
  | `notInstalled` | `"Not installed"` | `colorScheme.surfaceContainerHighest` | `colorScheme.onSurfaceVariant` |

  Use `appColors.badgeUpcoming` and its text token for `warning` if amber is unavailable
  in `AppColors`. Check `lib/core/theme/app_theme.dart` and use the closest available
  warning-level token; do not introduce new color literals.

- `enabled`: `state != _FlavorState.notInstalled`
- `selected`: `isSelected`
- `onTap`: calls `onTap` callback — nil when `notInstalled`.

#### onTap behavior for each state

In `XcsoarDirectorySettingsScreen`:

- `ready`: Call `XcsoarSafService().pickDirectoryForPackage(flavor.packageId)`. On `"ok"`,
  invalidate `xcsoarDirectoryUriProvider` and show the same SnackBar as today. On
  `"cancelled"`, show "Folder selection cancelled".
- `warning`: Set `_selectedBlockedPackage = flavor.packageId` (setState). The guidance
  card rendered by issue 02 will expand below the tile. For this issue, just store the
  state — the screen expands correctly once issue 02 is implemented.
- `notInstalled`: `onTap` is `null` (tile is not interactive).

#### AppBar title variant

The AppBar title is determined by a `fromDownloadFlow` boolean constructor parameter
(default `false`) passed to `XcsoarDirectorySettingsScreen`:

- `fromDownloadFlow: false` → title `"XCSoar Folder"` (Settings entry point)
- `fromDownloadFlow: true` → title `"Set Up XCSoar Folder"` (contextual entry point)

Update the route builder in `app.dart` to read `state.uri.queryParameters['from']` and
pass `fromDownloadFlow: state.uri.queryParameters['from'] == 'download'` to the screen.

### 5. Widget tests

Add widget tests in `test/core/platform/xcsoar_directory_settings_screen_test.dart`:

- Mocking strategy: mock `XcsoarSafService` with `mockito`; inject via a `ProviderScope`
  override on `xcsoarDirectoryUriProvider`.
- Test 1: When all flavors are `notInstalled`, all four flavor tiles are present and each
  shows the "Not installed" badge.
- Test 2: When one flavor is `ready`, its tile shows the "Ready" badge; tapping it calls
  `pickDirectoryForPackage` with the correct package ID.
- Test 3: When one flavor is `warning`, tapping its tile does not call
  `pickDirectoryForPackage` but sets `_selectedBlockedPackage` (observable via state).
- Test 4: The "Choose custom folder" Advanced row is visible and calls the existing
  `pickDirectory` on tap.
- Test 5: `fromDownloadFlow: true` renders AppBar title "Set Up XCSoar Folder".
- Test 6: `fromDownloadFlow: false` renders AppBar title "XCSoar Folder".

### 6. Documentation updates

- **`docs/features/competitions.md`** — update the XCSoar Directory Settings Screen
  section to describe the flavor-picker list, the `XcsoarFlavor` type, and the
  `fromDownloadFlow` parameter.
- **`docs/architecture.md`** — note the `xcsoar_flavor.dart` value type in
  `lib/core/platform/` and the two new MethodChannel calls.
- **`docs/plan.md`** — add a 📋 item for the flavor-picker feature under Phase 4.

## Acceptance criteria

- [ ] `AndroidManifest.xml` declares `<package>` visibility for all four XCSoar
  package IDs inside the `<queries>` block.
- [ ] `XcsoarSafService` exposes `isPackageInstalled`, `canWriteToMediaDir`, and
  `pickDirectoryForPackage`.
- [ ] `kKnownXcsoarFlavors` is defined in `lib/core/platform/xcsoar_flavor.dart`.
- [ ] The Settings screen shows a `ListView` with all four known flavors, each with the
  correct badge for its current state.
- [ ] Flavors are sorted: ready first, then warning, then not-installed.
- [ ] Tapping a `ready` flavor launches the SAF picker pre-navigated to the correct
  `Android/media/<pkg>/` path.
- [ ] Tapping a `warning` flavor does not launch the picker; `_selectedBlockedPackage`
  is updated.
- [ ] Tapping a `notInstalled` flavor has no effect.
- [ ] The "Advanced" custom-folder row and "Reset Permission" button are present and
  functional.
- [ ] `fromDownloadFlow: true` renders a different AppBar title than the default.
- [ ] `flutter analyze` reports no issues.
- [ ] `flutter test` passes including all six new widget tests.

## Constraints

- Do not introduce new color literals. Use existing `AppColors` tokens or
  `colorScheme.*` values from `app_theme.dart`.
- Do not remove or rename the `/settings/xcsoar-directory` route path.
- Do not rename `XcsoarSafService` or `XcsoarDirectorySettingsScreen`.
- The `XcsoarFlavor` class must be a plain Dart class (not freezed) — it carries no
  mutable state and needs no serialisation.
- Add `///` doc comments to every new public symbol.

## Reference

User story: `2025-05-02-flight-comp-selection.md`
