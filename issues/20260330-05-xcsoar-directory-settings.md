# XCSoar Directory Settings Screen — Fix & Complete

## Feature

Give users a way to view their configured XCSoar data directory, change it to a different folder, or reset it so they can re-grant access. This is surfaced as a Settings screen accessible from the home screen menu.

## Current State

All dependencies are resolved. The following is **already implemented** — do not recreate it:

- `XcsoarSafService` with `getSafDirectoryUri()`, `clearSafPermission()`, and `tryWriteHelloFile()` at `lib/core/platform/xcsoar_saf_service.dart`
- `xcsoarDirectoryUriProvider` (`FutureProvider.autoDispose<String?>`) in `lib/features/competitions/presentation/providers/competitions_providers.dart`
- Route `/settings/xcsoar-directory` wired in `lib/app.dart`
- `XcsoarDirectorySettingsScreen` (`ConsumerStatefulWidget`) at `lib/core/platform/xcsoar_directory_settings_screen.dart`

## Scope

Fix the existing screen and menu to match the spec. Two files only — no domain or data layer changes.

---

## Tasks

### 1. Fix the screen — `lib/core/platform/xcsoar_directory_settings_screen.dart`

Read the file in full before editing. Apply these targeted changes:

#### 1a. AppBar title
Change `'XCSoar Directory'` → `'XCSoar Folder'`.

#### 1b. Body layout — replace Column with ListView + ListTile

Replace the current `Padding > Column` body with a `ListView`. The first item must be a `ListTile`:

```dart
ListTile(
  leading: const Icon(Icons.folder_outlined),
  title: const Text('XCSoar folder'),
  subtitle: uriAsync.when(
    loading: () => const LinearProgressIndicator(),
    error: (_, __) => const Text('Could not read folder'),
    data: (uri) => Text(uri != null && uri.isNotEmpty ? uri : 'Not configured'),
  ),
),
```

The `ElevatedButton`, `OutlinedButton` (see 1d), and info text (see 1f) follow as `ListView` children, each wrapped in a `Padding` with horizontal/vertical spacing as appropriate.

#### 1c. Button label
Change the `ElevatedButton` label from `'Choose XCSoar Folder'` → `'Change Directory'`.

#### 1d. Handle `'cancelled'` result in `_pickDirectory`

The existing `if (result == 'ok')` branch already handles success. Add an `else if (result == 'cancelled')` branch:

```dart
} else if (result == 'cancelled') {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Folder selection cancelled')),
  );
}
```

#### 1e. Correct SnackBar text

- Success SnackBar: `'XCSoar folder configured successfully'` → `'XCSoar folder configured'`
- Reset SnackBar: `'XCSoar folder cleared'` → `'Permission cleared'`

#### 1f. Reset button — change to OutlinedButton with red ButtonStyle

Replace the `TextButton` used for reset with an `OutlinedButton`. The button must always be visible (not gated on the URI being non-null). Use a `ButtonStyle` for the red colour instead of styling the child text:

```dart
OutlinedButton(
  onPressed: _clearDirectory,
  style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700),
  child: const Text('Reset Permission'),
),
```

Remove the `uriAsync.maybeWhen` guard that currently hides this button.

#### 1g. Add info text paragraph

At the bottom of the `ListView`, after both buttons, add:

```dart
Padding(
  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
  child: Text(
    'Compman needs access to XCSoar\'s data folder to install task files. '
    'Tap Change Directory to open the folder picker and grant access. '
    'If XCSoar is not installed or the folder picker shows an unexpected '
    'location, tap Reset Permission and try again.',
  ),
),
```

---

### 2. Add Settings menu entry — `lib/features/competitions/presentation/screens/bookmarks_screen.dart`

The current `PopupMenuButton` itemBuilder has two items: `'Try SAF'` and `'About'`. Add `'Settings'` **before** `'Try SAF'`:

```dart
itemBuilder: (context) => const [
  PopupMenuItem(value: '/settings/xcsoar-directory', child: Text('Settings')),
  PopupMenuItem(value: '/saf-test', child: Text('Try SAF')),
  PopupMenuItem(value: '/about', child: Text('About')),
],
```

The existing `onSelected: (value) => context.push(value)` handler requires no change.

---

## Acceptance Criteria

1. `flutter analyze` passes with no issues.
2. `flutter test` passes — existing tests stay green.
3. A "Settings" item appears **first** in the home screen three-dot menu.
4. Tapping "Settings" navigates to a screen titled **"XCSoar Folder"**.
5. The screen body starts with a `ListTile` showing a folder icon, title "XCSoar folder", and a subtitle that is the SAF URI or "Not configured".
6. Tapping "Change Directory" opens the SAF folder picker; on success SnackBar reads **"XCSoar folder configured"**; on cancel reads **"Folder selection cancelled"**.
7. "Reset Permission" is always visible, uses `OutlinedButton` with a red foreground, and on tap shows SnackBar **"Permission cleared"** and resets the subtitle to "Not configured".
8. Info text paragraph is visible below both buttons.
9. `docs/plan.md` updated — mark the XCSoar Directory Settings task ✅ with a brief implementation note.
