# XCSoar Flavor Picker: Feature Doc and Plan Updates

## Feature summary

The XCSoar flavor-picker feature spans three implementation issues (01, 02, 03). This
housekeeping issue consolidates all documentation work that spans those issues into one
place: the new `docs/features/xcsoar.md` feature doc, updates to `docs/plan.md`, and
any remaining gaps in `docs/features/competitions.md` or `docs/architecture.md` that the
three implementation issues did not cover.

## Scope

This issue covers **documentation only** — no production code, no tests.

It must be done **after** issues 01, 02, and 03 are merged so the doc reflects the
implemented behaviour rather than intentions.

## What to build

### 1. Create `docs/features/xcsoar.md`

This file documents the XCSoar integration feature end-to-end. Write it after
inspecting the final implementation. It must cover:

#### Overview

One paragraph: what Compman does with XCSoar's data directory, and why the flavor-picker
exists.

#### Known XCSoar Flavors

A table listing the four flavors, their display names, and package IDs. Note the
`kKnownXcsoarFlavors` constant in `lib/core/platform/xcsoar_flavor.dart`.

#### Flavor State Detection

Explain the three states (`ready`, `warning`, `notInstalled`) and how each is
determined:

- `notInstalled` — `XcsoarSafService.isPackageInstalled` returns `false`.
- `warning` — package is installed but `XcsoarSafService.canWriteToMediaDir` returns
  `false` (Android/data path in use).
- `ready` — package is installed and `canWriteToMediaDir` returns `true`.

Explain the Android 11+ restriction: `Android/data/<pkg>/` cannot be accessed by other
apps via SAF; `Android/media/<pkg>/` is the correct target.

#### Screen: XCSoar Directory Settings (`/settings/xcsoar-directory`)

- Describe the flavor list, sort order, badge colors.
- Describe the `fromDownloadFlow` AppBar title variant.
- Describe the blocked-writability guidance card (non-dismissible, inline `Card` below
  the selected warning tile) and its three numbered options.
- Describe the "Advanced: choose custom folder" row.
- Describe the "Reset Permission" button.

#### Flow: Contextual Setup from Competition Detail

Diagram or numbered list describing the full flow:

1. User taps download (task / airspace / waypoints).
2. `PlatformException(code: 'SAF_NOT_CONFIGURED')` is thrown.
3. App navigates to `/settings/xcsoar-directory?from=download&competitionId=<id>&kind=<kind>`.
4. User configures a flavor (or aborts).
5. App returns to Competition Detail.
6. If configured: pending download auto-starts.
7. If aborted: error banner "XCSoar folder setup was cancelled" is shown.

#### Android Bridge Methods

List all methods on the `xcsoar.saf` MethodChannel with a brief description of each:

| Method | Arguments | Return | Description |
|---|---|---|---|
| `pickDirectory` | — | `"ok"` / `"cancelled"` | Launches SAF picker with auto-detected initial path |
| `pickDirectoryForPackage` | `packageId: String` | `"ok"` / `"cancelled"` | Launches SAF picker pre-navigated to `Android/media/<pkg>/` |
| `writeFile` | `bytes: ByteArray, filename: String` | `"ok"` / error | Writes a file to the stored SAF directory |
| `getSafDirectoryUri` | — | `String?` | Returns stored SAF tree URI or null |
| `clearSafPermission` | — | `"ok"` | Releases persisted URI grant and clears stored URI |
| `isPackageInstalled` | `packageId: String` | `Boolean` | Returns true if the package is installed |
| `canWriteToMediaDir` | `packageId: String` | `Boolean` | Returns true if `Android/media/<pkg>/` is writable via SAF |

#### Dart Service: `XcsoarSafService`

One sentence per public method pointing to the table above. Note that the service lives
in `lib/core/platform/xcsoar_saf_service.dart` and is a plain Dart class (no Riverpod
provider wrapping it).

### 2. Update `docs/plan.md`

- Under **Phase 4**, replace the placeholder `📋 XCSoar profile configuration (xcsoar feature)` item with:

  ```
  - ✅ XCSoar flavor picker — flavor-list UI, per-flavor writability badges, blocked-writability guidance card, and auto-navigation from Competition Detail on SAF_NOT_CONFIGURED; see docs/features/xcsoar.md
  ```

  (Mark ✅ only after all three implementation issues are confirmed merged and passing.)

- If `docs/features/xcsoar.md` was listed as a planned doc item (e.g. `📋 docs/features/xcsoar.md`), mark it ✅ as well.

### 3. Verify `docs/features/competitions.md` and `docs/architecture.md`

Check that the three implementation issues left no gaps:

- **competitions.md** — XCSoar Directory Settings Screen section must fully describe
  the flavor-picker (list layout, badge states, blocked-guidance card, `fromDownloadFlow`
  parameter, pending-download auto-resume). If any of this is missing after issues 01–03,
  fill it in.
- **architecture.md** — `lib/core/platform/` must list `xcsoar_flavor.dart` and the two
  new `XcsoarSafService` methods. The `<queries>` manifest change must be noted as the
  package-visibility mechanism.

If the implementation issues already updated these files correctly, a brief review note
in the commit message is sufficient; no rewrite is needed.

### 4. Move the user story to `done/`

Move `issues/userstories/2025-05-02-flight-comp-selection.md` to
`issues/userstories/done/2025-05-02-flight-comp-selection.md`.

## Acceptance criteria

- [ ] `docs/features/xcsoar.md` exists and covers all sections listed above.
- [ ] `docs/plan.md` marks the flavor-picker feature ✅ under Phase 4.
- [ ] `docs/features/competitions.md` accurately describes the final state of the
  XCSoar Directory Settings Screen and the Competition Detail `SAF_NOT_CONFIGURED` flow.
- [ ] `docs/architecture.md` documents `xcsoar_flavor.dart` and the new MethodChannel
  methods.
- [ ] `issues/userstories/2025-05-02-flight-comp-selection.md` has been moved to
  `issues/userstories/done/`.
- [ ] `flutter analyze` still passes after any doc-adjacent changes (e.g. if any
  imports were added in a doc-only file, they must resolve).

## Constraints

- No production code changes in this issue.
- Do not create a separate ADR for the flavor-picker unless a novel architectural pattern
  was introduced that is not already covered by existing ADRs. If a new ADR is needed,
  add it as part of this issue.
- Keep all documentation concise and scannable. No prose longer than three sentences
  per paragraph.

## Reference

User story: `2025-05-02-flight-comp-selection.md`
