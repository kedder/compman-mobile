# Mark the Active XCSoar Flavor in the Picker UI

## Feature summary

The XCSoar flavor picker (`/settings/xcsoar-directory`) lets users choose which XCSoar
variant Compman writes files to. Once a flavor is picked via `pickDirectoryForPackage`,
the screen gives no persistent indication of which flavor is active. A user who returns
to the screen cannot tell at a glance which variant they previously selected.

This issue adds a visual selection indicator and restructures the screen layout so the
active flavor is immediately obvious, while the raw SAF URI (useful only for debugging)
is moved into the existing "ADVANCED" section.

## Scope

This issue covers a single screen: `XcsoarDirectorySettingsScreen` in
`lib/features/xcsoar/presentation/screens/xcsoar_directory_settings_screen.dart`.

Three changes are bundled together because they are tightly coupled (they all depend on
deriving the active flavor from the stored URI) and the total diff is well within one
session:

1. Derive the active flavor at runtime from the stored SAF URI.
2. Add radio-style leading icons to every flavor tile.
3. Restructure the screen layout: replace the current prominent URI header tile with a
   compact status line, and move the raw URI display into the "ADVANCED" section.

This issue adds one new MethodChannel method (`resolveFlavorPackageId`) to
`MainActivity.kt`. No new Hive field is written. No new persisted value is introduced.

## Read first

- `lib/features/xcsoar/presentation/screens/xcsoar_directory_settings_screen.dart` —
  the file to modify. Read it in full before starting.
- `lib/core/platform/xcsoar_saf_service.dart` — to understand the existing Dart-side
  SAF methods, especially `getSafDirectoryUri()` and `pickDirectoryForPackage()`.
- `android/app/src/main/kotlin/lt/lebedev/compman_mobile/MainActivity.kt` — read the
  `mediaPath`, `externalStorageDocUri`, and `pickDirectoryForPackage` implementations
  to understand how the stored SAF tree URI is formed (see "Active flavor derivation"
  below).
- `lib/features/xcsoar/domain/xcsoar_flavor.dart` — the `XcsoarFlavor` type and
  `kKnownXcsoarFlavors` constant.
- `lib/core/di/providers.dart` — where `xcsoarDirectoryUriProvider` is defined.
- `test/features/xcsoar/xcsoar_directory_settings_screen_test.dart` — the existing
  widget test file to extend.
- `test/features/xcsoar/mock_xcsoar_saf_service.dart` — the mock for the SAF service.
- `docs/ui-guidelines.md` — accessibility rule: color must never be the sole indicator.
- General project rules: `AGENTS.md`.

## Active flavor derivation

When the user taps a `ready`-state flavor tile, `pickDirectoryForPackage(packageId)` is
called on the Kotlin side. Kotlin launches the SAF folder picker pre-navigated to the
document URI `content://com.android.externalstorage.documents/document/primary%3AAndroid%2Fmedia%2F<pkg>`.
After the user confirms, the SAF launcher returns a **tree URI** of the form:

```
content://com.android.externalstorage.documents/tree/primary%3AAndroid%2Fmedia%2F<pkg>
```

This tree URI is persisted to `SharedPreferences` under `xcsoar_tree_uri` and is what
`getSafDirectoryUri()` returns.

**URI construction must remain in Kotlin only.** `MainActivity.kt` already owns
`mediaPath()` and `externalStorageDocUri()`. Dart currently never constructs SAF URIs —
introducing `_canonicalTreeUriForPackage` in Dart would duplicate that knowledge.
Instead, expose a single new Kotlin method `resolveFlavorPackageId` that Dart calls once
to obtain the active `packageId`.

**Kotlin is framework glue; Dart owns the flavor list.** Rather than duplicating
`kKnownXcsoarFlavors` in Kotlin as a hardcoded `kKnownXcsoarPackages` list, Dart passes
the candidate package IDs with each call. Kotlin iterates the supplied list and returns
whichever ID's canonical URI matches. This keeps `kKnownXcsoarFlavors` as the single
source of truth for flavor identity and `MainActivity.kt` free of business logic.

### Kotlin changes — `MainActivity.kt`

Add a private tree-URI builder alongside the existing document-URI builder:

```kotlin
/** Returns a SAF tree URI for [path] on the external storage provider. */
private fun externalStorageTreeUri(path: String): Uri =
    Uri.parse("content://com.android.externalstorage.documents/tree/${Uri.encode(path)}")
```

Wire the resolver directly into the `MethodChannel` handler alongside the existing cases.
No `kKnownXcsoarPackages` constant is added — the candidates arrive from Dart:

```kotlin
"resolveFlavorPackageId" -> {
    val uri = call.argument<String>("uri")!!
    @Suppress("UNCHECKED_CAST")
    val candidates = call.argument<List<String>>("candidates")!!
    result.success(candidates.firstOrNull { pkg ->
        externalStorageTreeUri(mediaPath(pkg)).toString().equals(uri, ignoreCase = true)
    })
}
```

### Dart changes — `XcsoarSafService`

Add one new method to `lib/core/platform/xcsoar_saf_service.dart`:

```dart
/// Returns the [XcsoarFlavor.packageId] from [candidates] whose canonical
/// media-directory tree URI matches [storedUri], or null if none match.
Future<String?> resolveFlavorPackageId(String storedUri, List<String> candidates) =>
    _channel.invokeMethod<String>('resolveFlavorPackageId', {
      'uri': storedUri,
      'candidates': candidates,
    });
```

### Screen usage

In `XcsoarDirectorySettingsScreen`, read the stored URI once (already done via
`xcsoarDirectoryUriProvider`) and call `resolveFlavorPackageId` with it to get the
active `packageId`. No URI construction in Dart; no new persisted value.

Because `resolveFlavorPackageId` is async, derive the active flavor as a second
`FutureProvider` (or inline `AsyncValue`) alongside `xcsoarDirectoryUriProvider`, or
simply read `uriAsync.valueOrNull` and invoke `resolveFlavorPackageId` inside the same
`build` flow where the screen already awaits the URI.

A `_flavorForUri` helper in the screen file is still useful as a synchronous cache:

```dart
/// Active flavor resolved from the stored URI; null until loaded or if unrecognised.
XcsoarFlavor? _activeFlavor;
```

Call `_resolveActiveFlavor()` in `initState` and after any successful `_pickDirectory`
or `_pickDirectoryForPackage`:

```dart
Future<void> _resolveActiveFlavor() async {
  final uri = await ref.read(xcsoarDirectoryUriProvider.future);
  if (uri == null || uri.isEmpty) {
    if (mounted) setState(() => _activeFlavor = null);
    return;
  }
  final packageId = await ref.read(xcsoarSafServiceProvider).resolveFlavorPackageId(
    uri,
    kKnownXcsoarFlavors.map((f) => f.packageId).toList(),
  );
  if (mounted) {
    setState(() {
      _activeFlavor = packageId == null
          ? null
          : kKnownXcsoarFlavors.firstWhereOrNull((f) => f.packageId == packageId);
    });
  }
}
```

This keeps all URI knowledge in Kotlin and the Dart side purely maps a packageId to a
display model. `kKnownXcsoarFlavors` remains the single source of truth for the set of
known flavors.

## What to build

### 1. Extend Kotlin and `XcsoarSafService`

Follow the Kotlin and Dart changes described in "Active flavor derivation" above:
add `externalStorageTreeUri` and the `resolveFlavorPackageId` channel handler to
`MainActivity.kt` (no `kKnownXcsoarPackages` constant); add
`resolveFlavorPackageId(String, List<String>)` to `XcsoarSafService`; add
`_activeFlavor` state and `_resolveActiveFlavor()` to the screen.

Do **not** add any URI-construction logic to Dart or to `XcsoarFlavor`.

### 2. Restructure the `XcsoarDirectorySettingsScreen` layout

The current `ListView` order is:
1. Header `ListTile` (folder icon + raw URI as subtitle)
2. `Divider`
3. "XCSOAR APP" section label
4. Flavor tiles
5. `Divider`
6. "ADVANCED" section label
7. "Choose custom folder" tile
8. "Reset Permission" button
9. Help text paragraph

Change it to:

1. **Status line** — a `Padding`-wrapped `Text` widget just above the "XCSOAR APP"
   section label. Shows either `"<displayName> selected"` (e.g. "XCSoar Jet selected")
   when a flavor is active, or `"Custom folder"` when no known flavor matches. Use
   `theme.textTheme.bodyMedium` in `theme.colorScheme.onSurfaceVariant`. No icon.
2. "XCSOAR APP" section label (unchanged).
3. Flavor tiles (with updated leading icons — see §3).
4. `Divider` (unchanged).
5. "ADVANCED" section label (unchanged).
6. **Raw URI tile** — a `ListTile` with `leading: const Icon(Icons.folder_outlined)`,
   `title: const Text('XCSoar folder')`, and `subtitle` showing the stored URI string
   (or "Not configured"). Style the subtitle with `theme.textTheme.bodySmall` and
   `theme.colorScheme.onSurfaceVariant` to visually de-emphasize it. This is the current
   header tile moved here.
7. "Choose custom folder" tile (unchanged).
8. "Reset Permission" button (unchanged).
9. Help text paragraph (unchanged).

Remove the old `Divider` that previously separated the header tile from the flavor list;
a single `Divider` between the flavor list and the ADVANCED section is sufficient.

The status line `Padding` should use `EdgeInsets.fromLTRB(16, 8, 16, 4)` so it sits
snugly above the "XCSOAR APP" label.

Derive the status text inside `build()` using the cached `_activeFlavor` field and the
watched `uriAsync`:

```dart
final uriAsync = ref.watch(xcsoarDirectoryUriProvider);
final statusText = _activeFlavor != null
    ? '${_activeFlavor!.displayName} selected'
    : (uriAsync.valueOrNull?.isNotEmpty == true ? 'Custom folder' : 'Not configured');
```

Show the status line unconditionally (even during URI loading), but while the URI is
still loading it will display "Not configured" — that is acceptable because the flavor
tiles themselves are guarded by the `_loading` flag.

### 3. Add radio-style leading icons to `_FlavorTile`

Modify `_FlavorTile` to accept a new named parameter:

```dart
final bool isActiveFlavor;
```

In `_FlavorTile.build`, add a `leading` icon before the title:

```dart
leading: Icon(
  isActiveFlavor ? Icons.check_circle : Icons.radio_button_unchecked,
  color: isActiveFlavor
      ? theme.colorScheme.primary
      : theme.colorScheme.outline,
),
```

The existing `ListTile.selected` background tint (already wired via the `isSelected`
field) must remain active. `isSelected` and `isActiveFlavor` serve different purposes:

- `isSelected` — true when the user tapped a `warning`-state tile to reveal the
  blocked-writability guidance card (unchanged behavior).
- `isActiveFlavor` — true when this flavor's canonical URI matches the stored SAF URI.

A `ready`-state tile that was picked previously will have `isActiveFlavor = true` and
`isSelected = false`. Both conditions can coexist on the same tile without conflict.

Update `_buildFlavorTile` in the state class to pass `isActiveFlavor` using the cached
`_activeFlavor` field (populated by `_resolveActiveFlavor()`):

```dart
Widget _buildFlavorTile(XcsoarFlavor flavor) {
  final state = _flavorStates[flavor.packageId] ?? _FlavorState.notInstalled;
  return _FlavorTile(
    flavor: flavor,
    state: state,
    isSelected: _selectedBlockedPackage == flavor.packageId,
    isActiveFlavor: _activeFlavor?.packageId == flavor.packageId,
    onTap: switch (state) {
      _FlavorState.ready => () => _pickDirectoryForPackage(flavor),
      _FlavorState.warning => () => setState(
        () => _selectedBlockedPackage = flavor.packageId,
      ),
      _FlavorState.notInstalled => null,
    },
  );
}
```

Add `///` doc comments to `isActiveFlavor` on `_FlavorTile`.

### 4. Auto-detect behavior after custom folder pick

After `_pickDirectory()` or `_pickDirectoryForPackage()` completes with result `'ok'`,
call `_resolveActiveFlavor()` in addition to the existing
`ref.invalidate(xcsoarDirectoryUriProvider)`. `_resolveActiveFlavor` will invoke
`resolveFlavorPackageId` on the Kotlin side with the new URI and update `_activeFlavor`,
triggering a `setState` rebuild. If the picked URI matches a known flavor, the tile shows
`Icons.check_circle` and the status line updates immediately.

### 5. Widget tests

Extend `test/features/xcsoar/xcsoar_directory_settings_screen_test.dart`.

The mock `_mockService` already stubs `getSafDirectoryUri()`. Also stub the new
`resolveFlavorPackageId` method. Add an optional `activePackageId` parameter to
`_buildScreen` that controls what the mock returns:

```dart
Widget _buildScreen({
  bool fromDownloadFlow = false,
  Set<String> installedPackages = const {},
  Set<String> writablePackages = const {},
  String? storedUri,
  String? activePackageId,   // new — null means custom folder / not configured
}) {
  when(_mockService.getSafDirectoryUri()).thenAnswer((_) async => storedUri);
  when(_mockService.resolveFlavorPackageId(any, any))
      .thenAnswer((_) async => activePackageId);
  // ...
}
```

Add the following tests:

**Test: status line shows "Not configured" when no URI is stored**
- `_buildScreen()` with no `storedUri` and no `activePackageId`.
- After settle, `find.text('Not configured')` finds one widget.

**Test: status line shows flavor display name when resolver returns a known packageId**
- `_buildScreen(storedUri: 'content://any', activePackageId: 'org.xcsoar',
  installedPackages: {'org.xcsoar'}, writablePackages: {'org.xcsoar'})`.
- After settle, `find.text('XCSoar selected')` finds one widget.

**Test: status line shows "Custom folder" when resolver returns null for a non-empty URI**
- `_buildScreen(storedUri: 'content://custom', activePackageId: null)`.
- After settle, `find.text('Custom folder')` finds one widget.

**Test: selected flavor tile shows check_circle icon**
- Same setup as the "flavor display name" test above.
- After settle, `find.byIcon(Icons.check_circle)` finds exactly one widget.

**Test: unselected flavor tiles show radio_button_unchecked icon**
- Same setup. After settle, `find.byIcon(Icons.radio_button_unchecked)` finds exactly
  three widgets (the other three flavors, assuming all four tiles are rendered).

**Test: raw URI tile appears in the ADVANCED section**
- `_buildScreen(storedUri: 'content://example')`.
- After settle, verify that the "XCSoar folder" title text appears once and that the
  raw URI text "content://example" appears as a subtitle.

**Test: no flavor tile shows check_circle when no URI is stored**
- `_buildScreen()` with no `storedUri`.
- After settle, `find.byIcon(Icons.check_circle)` finds nothing (`findsNothing`).

### 6. Documentation updates

- **`docs/features/configuration.md`** — update the "XCSoar Folder Setup" section:
  - Add a "Active flavor indicator" sub-section explaining that the active flavor is
    derived at runtime by comparing the stored SAF URI to each flavor's canonical media-
    directory tree URI. Note the status line, leading icons, and custom-folder behavior.
  - Note that the raw URI is shown in the Advanced section for power users.
- **`docs/plan.md`** — mark the XCSoar flavor picker item (Phase 4) as ✅ with a brief
  implementation note. Add a new 📋 item for `docs/features/xcsoar.md` if it does not
  already exist.

## Acceptance criteria

- [ ] `MainActivity.kt` exposes a `resolveFlavorPackageId` method channel call that
  accepts a stored URI and a list of candidate package IDs from Dart, and returns the
  first candidate whose canonical tree URI matches, or null. No `kKnownXcsoarPackages`
  list is added to Kotlin; no URI-construction logic is added to Dart.
- [ ] `XcsoarSafService` exposes `resolveFlavorPackageId(String storedUri, List<String> candidates)`.
- [ ] The flavor picker screen calls `resolveFlavorPackageId` (via `_resolveActiveFlavor`)
  on load and after every successful directory pick to determine the active flavor. No new
  value is persisted; no `packageId` is written to Hive.
- [ ] Every flavor tile has a leading icon: `Icons.check_circle` in
  `colorScheme.primary` for the active flavor, `Icons.radio_button_unchecked` in
  `colorScheme.outline` for all others.
- [ ] The existing `ListTile.selected` background tint on `warning`-state tiles is
  preserved unchanged.
- [ ] The status line above the "XCSOAR APP" section label shows the active flavor's
  `displayName` followed by " selected" (e.g. "XCSoar Jet selected") or "Custom folder"
  if no known flavor matches, or "Not configured" if no URI is stored.
- [ ] The raw SAF URI `ListTile` (folder icon, "XCSoar folder" title, URI as subtitle)
  appears inside the "ADVANCED" section, not at the top of the list.
- [ ] No flavor tile is highlighted (no `check_circle`) when the stored URI is null or
  empty or matches no known flavor.
- [ ] After `_pickDirectory()` succeeds, the screen re-derives the active flavor from
  the newly stored URI and updates both the status line and the tile leading icon without
  any additional user action.
- [ ] All new and existing widget tests pass: `make test`.
- [ ] `make analyze` reports no issues.
- [ ] `make format` reports no changes.

## Constraints

- **No new persisted state.** Do not write `packageId` or any flavor identifier to the
  Hive `"settings"` box.
- **URI construction stays in Kotlin.** Do not add any SAF URI construction to Dart or
  to `XcsoarFlavor`. All URI format knowledge lives in `MainActivity.kt`.
- **The flavor list is owned by Dart.** Do not add any hardcoded list of flavor package
  IDs to `MainActivity.kt`. `kKnownXcsoarFlavors` in Dart is the single source of truth
  for flavor identity; Kotlin receives the candidate IDs as a call argument.
- **No new color tokens.** Use `colorScheme.primary`, `colorScheme.outline`,
  `colorScheme.onSurfaceVariant` — all already in use on this screen.
- **Color is not the sole indicator.** The `Icons.check_circle` / `Icons.radio_button_unchecked`
  icon change provides the non-color cue required by `docs/ui-guidelines.md`.
- Add `///` doc comments to all new public and private symbols.
- The `isSelected` field on `_FlavorTile` must not be repurposed for flavor selection —
  its meaning (warning-state guidance card toggle) must remain unchanged.

## Reference

User story: `2026-05-06-mark-selected-flavor.md`
