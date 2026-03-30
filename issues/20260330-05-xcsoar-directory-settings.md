# XCSoar Directory Settings Screen

## Feature

Give users a way to view their configured XCSoar data directory, change it to a different folder, or reset it so they can re-grant access. This is surfaced as a Settings screen accessible from the home screen menu.

## Scope

New screen `XcsoarDirectorySettingsScreen`, a new route `/settings/xcsoar-directory`, and a "Settings" entry in the home screen PopupMenuButton. No domain or data layer changes.

## Dependencies

- `20260330-02-saf-task-writer.md` must be done first (`XcsoarSafService.getSafDirectoryUri`, `clearSafPermission`, and `tryWriteHelloFile` for the picker flow).

Issue `20260330-04-competition-detail-ui.md` depends on this screen existing (it links to it from the SAF_NOT_CONFIGURED error path), but the two issues can be developed in parallel by agreeing on the route path `/settings/xcsoar-directory` in advance.

---

## Background

After the SAF PoC, the stored tree URI is opaque (`content://...`). This screen makes it visible and manageable. Read `docs/architecture.md` — Platform Services section — to understand `XcsoarSafService`.

---

## Tasks

### 1. Settings screen — `lib/core/platform/xcsoar_directory_settings_screen.dart`

Create `XcsoarDirectorySettingsScreen` (`ConsumerStatefulWidget`).

**AppBar:** title `"XCSoar Folder"`

**Body:** `ListView` with the following sections:

#### Current directory

A `ListTile`:
- Leading: `Icon(Icons.folder_outlined)`
- Title: `"XCSoar folder"`
- Subtitle: the URI string from `XcsoarSafService().getSafDirectoryUri()`, or `"Not configured"` if null
- Load the URI in `initState` (call `getSafDirectoryUri()` and store in state); show `CircularProgressIndicator` in subtitle while loading

#### Change directory button

`ElevatedButton` labelled `"Change Directory"`:
- Calls `XcsoarSafService().tryWriteHelloFile()` — this triggers the SAF folder picker (if needed) AND writes the hello file to verify the grant works
- Wait state: show `CircularProgressIndicator` while the picker / write is in progress
- On success (`"ok"` or `"cancelled"`):
  - If `"ok"`: update the displayed URI by calling `getSafDirectoryUri()` again; invalidate `xcsoarDirectoryUriProvider` (from issue 04 providers); show green `SnackBar` — `"XCSoar folder configured"`
  - If `"cancelled"`: show neutral `SnackBar` — `"Folder selection cancelled"`
- On `PlatformException`: show red `SnackBar` with error message

#### Reset permission button

`OutlinedButton` labelled `"Reset Permission"` (destructive, uses `ButtonStyle` with red foreground):
- Calls `XcsoarSafService().clearSafPermission()`
- On success: update state to show `"Not configured"`; invalidate `xcsoarDirectoryUriProvider`; show `SnackBar` — `"Permission cleared"`
- On error: show red `SnackBar`

#### Info text

Below the buttons, a descriptive paragraph:

> "Compman needs access to XCSoar's data folder to install task files. Tap Change Directory to open the folder picker and grant access. If XCSoar is not installed or the folder picker shows an unexpected location, tap Reset Permission and try again."

### 2. Route — `lib/app.dart`

Add:
```dart
GoRoute(
  path: '/settings/xcsoar-directory',
  builder: (context, state) => const XcsoarDirectorySettingsScreen(),
),
```

Import `lib/core/platform/xcsoar_directory_settings_screen.dart`.

### 3. Home screen menu — `lib/features/competitions/presentation/screens/bookmarks_screen.dart`

Add `"Settings"` item to the `PopupMenuButton` **before** the `"Try SAF"` item:

```dart
PopupMenuItem(value: '/settings/xcsoar-directory', child: Text('Settings')),
PopupMenuItem(value: '/saf-test', child: Text('Try SAF')),
PopupMenuItem(value: '/about', child: Text('About')),
```

---

## Acceptance Criteria

1. `flutter analyze` passes.
2. `flutter test` passes — existing tests still green.
3. A "Settings" item appears in the home screen three-dot menu.
4. Tapping "Settings" navigates to the XCSoar Folder screen.
5. The screen shows the current SAF URI (or "Not configured") loaded from `XcsoarSafService`.
6. "Change Directory" opens the SAF folder picker; on success the displayed URI updates.
7. "Reset Permission" clears the stored URI and the display shows "Not configured".
8. All loading and error states are visible.
9. `docs/plan.md` updated.
