# Remove "Try SAF" Feature and Related Code

## Feature Summary

During early development a "Try SAF" debug screen (`SafTestScreen`) was added to manually test that Android's Storage Access Framework (SAF) bridge could write a file into XCSoar's data folder. This PoC screen is now obsolete — the SAF infrastructure is proven and the production task-install flow is in place. The screen and its supporting code should be removed.

The SAF infrastructure itself (folder picker, `writeFile`, `getSafDirectoryUri`, `clearSafPermission`) is **production code and must be kept**. Only the "hello file" PoC scaffolding is removed.

## Scope

Remove all "Try SAF" PoC code in a single atomic commit. Do **not** remove the real SAF functionality that underpins task installation and directory settings.

## What to Do

### 1. Delete file
- `lib/core/platform/saf_test_screen.dart` — delete entirely.

### 2. `lib/app.dart`
- Remove `import 'core/platform/saf_test_screen.dart';`
- Remove the `/saf-test` `GoRoute` entry.

### 3. `lib/features/competitions/presentation/screens/bookmarks_screen.dart`
- Remove the `PopupMenuItem(value: '/saf-test', child: Text('Try SAF'))` entry from the three-dot menu (line ~32).

### 4. `lib/core/platform/xcsoar_saf_service.dart`
- Remove the `tryWriteHelloFile()` method entirely.
- Add a new `/// Launches the Android folder picker…` doc-commented `pickDirectory()` method that calls a new `'pickDirectory'` channel method and returns `"ok"` or `"cancelled"`.

### 5. `android/app/src/main/kotlin/lt/lebedev/compman_mobile/MainActivity.kt`
- Remove the `"tryWriteHelloFile"` branch from the `MethodChannel` handler.
- Remove the `handleTryWriteHelloFile()` private function.
- Remove the `writeHelloFile()` private function.
- Keep `safLauncher` and `pendingResult` — they are reused by the new `pickDirectory` handler.
- Add a `"pickDirectory"` branch to the `MethodChannel` handler that calls a new `handlePickDirectory(result)` function.
- `handlePickDirectory` should: store `result` in `pendingResult`, then call `safLauncher.launch(Uri.parse("content://org.xcsoar.allfiles/document/root:"))`. The existing `safLauncher` callback already calls `writeHelloFile` after saving the URI — replace that call with `result.success("ok")` so it just saves the permission and returns without writing anything.

### 6. `lib/core/platform/xcsoar_directory_settings_screen.dart`
- In `_pickDirectory()`, replace the call to `XcsoarSafService().tryWriteHelloFile()` with `XcsoarSafService().pickDirectory()`. The return value and downstream logic (`"ok"` / `"cancelled"` branching) remain identical.

### 7. Documentation
- `docs/features/competitions.md` line ~137: update the description of "Choose XCSoar Folder" button to say it calls `XcsoarSafService.pickDirectory()` (not `tryWriteHelloFile()`).
- `docs/plan.md` Phase 3 SAF bridge bullet: remove mention of `tryWriteHelloFile` from the ✅ note.
- `docs/architecture.md` Android bridge pattern section (~line 157): the code sample references `safLauncher` — update any inline comments that describe the hello-file flow to describe the directory-picker flow instead, if needed for accuracy.

## Acceptance Criteria

1. `lib/core/platform/saf_test_screen.dart` does not exist.
2. No file in `lib/` or `android/` references `tryWriteHelloFile`, `SafTestScreen`, `/saf-test`, or `writeHelloFile`.
3. The "Try SAF" menu item no longer appears in the three-dot menu on the home screen.
4. The XCSoar Directory Settings screen still works: tapping "Change Directory" opens the folder picker and saves the URI; tapping "Reset Permission" clears it.
5. The "Install as XCSoar Default Task" button on the competition detail screen still works.
6. `make analyze` reports no issues.
7. `make test` passes.

## Context

- Read `AGENTS.md` for project rules (architecture, doc maintenance, commit format).
- Real SAF files to keep: `lib/core/platform/xcsoar_saf_service.dart`, `lib/core/platform/xcsoar_directory_settings_screen.dart`, and the corresponding Kotlin handlers.
- The `safLauncher` + `pendingResult` pattern is documented in `docs/architecture.md` (~line 157) — keep it, just repurpose it for `pickDirectory` only.
- Reference the issue filename in every commit message as a trailer (see `issues/AGENTS.md`).
