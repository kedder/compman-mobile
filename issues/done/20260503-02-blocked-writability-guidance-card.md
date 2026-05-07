# XCSoar Flavor Picker: Blocked-Writability Inline Guidance Card

## Feature summary

When XCSoar is installed but its data directory is in `Android/data/<pkg>/` (inaccessible
on Android 11+), Compman cannot write files. There is no quick fix: XCSoar chose
`Android/data` automatically and has no in-app setting to change it. Users who tap a
warning-state flavor must see honest, step-by-step recovery guidance — inline, not in a
dialog — before they can proceed.

## Scope

This issue builds directly on issue `20260503-01-xcsoar-flavor-picker-ui.md`, which
introduced the `_FlavorState.warning` state, the `_selectedBlockedPackage` field, and the
flavor tile tap handler. This issue adds:

1. The non-dismissible `Card` shown inline below the selected warning-state flavor tile.
2. The exact body copy as specified in the user story (verbatim, including runtime
   substitutions of `[Flavor name]` and `[pkg]`).
3. Selection enforcement: a `warning`-state flavor tile cannot proceed to the SAF picker
   — tapping it only opens or closes this guidance card.
4. Unit-like widget tests for the card content.

This issue does **not** cover the auto-navigation from Competition Detail (issue 03).

## Prerequisite

Issue `20260503-01-xcsoar-flavor-picker-ui.md` must be merged first. This issue
modifies `xcsoar_directory_settings_screen.dart` produced by that issue.

## What to build

### 1. Inline guidance card widget

Create a private widget `_BlockedFlavorGuidanceCard` in
`lib/core/platform/xcsoar_directory_settings_screen.dart`.

Constructor:
```dart
const _BlockedFlavorGuidanceCard({
  required this.flavorName,
  required this.packageId,
});
```

Render a `Card` with:

- `margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4)` — placed directly below
  the selected flavor tile.
- `color: colorScheme.errorContainer` (or closest available surface-with-warning token
  in `AppColors`; do not introduce new literals).
- No dismiss button — this card is non-dismissible.

#### Card title

```
XCSoar can't be reached in its current location
```

Render as `Text(title, style: theme.textTheme.titleMedium)`.

#### Card body

The body is a sequence of `Text` and `RichText` spans. Render the following block,
replacing `[Flavor name]` with `flavorName` and `[pkg]` with `packageId` at runtime:

---

[Flavor name] is installed, but it's storing its files in a folder that Android no
longer allows other apps to access (`Android/data`). This happens with older XCSoar
installations — XCSoar automatically keeps using the original folder as long as files
are found there, and there's no option inside XCSoar to change this.

To use Compman with [Flavor name], you'll need to free it from that folder:

**1. Back up, uninstall, and reinstall** *(preserves files if backed up)*
Copy your `XCSoarData` folder from `Android/data/[pkg]/files/` somewhere safe first.
Then uninstall [Flavor name] — this deletes `Android/data/[pkg]` — reinstall, and
restore your backup.

**2. Clear XCSoar's app data** *(settings and data lost)*
Settings → Apps → [Flavor name] → Storage & Cache → Clear Storage. XCSoar will create
a new accessible folder on next launch. Warning: all profiles, settings, and logbook
entries are permanently deleted.

**3. Uninstall and reinstall** *(simplest, data lost)*
Uninstall and reinstall [Flavor name]. Warning: all settings and data are permanently
deleted.

---

Implement the body as a `Column` of `Text` widgets. Use `RichText` / `TextSpan` with
`FontWeight.bold` only for the numbered-option headers (e.g. "1. Back up, uninstall, and
reinstall"). Use `TextStyle(fontStyle: FontStyle.italic)` for the parenthetical risk
labels (e.g. "*(preserves files if backed up)*"). Use `TextStyle(fontFamily: 'monospace')`
or wrap in backticks in the text for inline code snippets (e.g. `Android/data/[pkg]/files/`);
alternatively use `fontWeight: FontWeight.w600` and a slightly different text color from
`colorScheme.onSurfaceVariant` for monospace spans. Choose the approach that compiles
cleanest with the existing theme; do not introduce new color tokens.

Spacing between paragraphs: `SizedBox(height: 12)`.

### 2. Integrate the card into the screen

In `_XcsoarDirectorySettingsScreenState.build`, for each flavor tile in the sorted list:

- Render the `_FlavorTile` for the flavor as before.
- Immediately after the tile, check: if `_selectedBlockedPackage == flavor.packageId`
  and `_flavorStates[flavor.packageId] == _FlavorState.warning`, render
  `_BlockedFlavorGuidanceCard(flavorName: flavor.displayName, packageId: flavor.packageId)`.

This means the card is placed in the `ListView` immediately below the selected tile, not
in an overlay or bottom sheet.

### 3. Selection toggle behavior

Modify the `warning` tile's `onTap` in the screen:

- If `_selectedBlockedPackage != flavor.packageId` → set
  `_selectedBlockedPackage = flavor.packageId` (expand the card).
- If `_selectedBlockedPackage == flavor.packageId` → set
  `_selectedBlockedPackage = null` (collapse the card).

The card is the only UI change: no SAF picker is launched, no navigation occurs, no
SnackBar is shown. This enforces that the user cannot proceed with a blocked flavor
until writability is resolved.

### 4. Widget tests

Add tests in `test/core/platform/xcsoar_directory_settings_screen_test.dart` (extend
the file created by issue 01):

- **Test 7:** When a `warning`-state flavor tile is tapped, the guidance card appears
  below it with the correct flavor name, package ID, and card title text.
- **Test 8:** The guidance card contains the exact numbered option headers:
  "1. Back up, uninstall, and reinstall", "2. Clear XCSoar's app data",
  "3. Uninstall and reinstall".
- **Test 9:** Tapping the same `warning`-state tile again collapses the guidance card
  (card is no longer in the widget tree).
- **Test 10:** `pickDirectoryForPackage` is **not** called when a `warning`-state tile
  is tapped.
- **Test 11:** When a `ready`-state tile is tapped while a guidance card is open, the
  guidance card is dismissed (the `ready` tile's SAF picker flow proceeds normally and
  `_selectedBlockedPackage` is cleared after the picker returns).

### 5. Documentation updates

- **`docs/features/competitions.md`** — add a "Blocked-Writability Guidance" subsection
  under the XCSoar Directory Settings Screen description. Note that the card is
  non-dismissible and explain the collapse toggle.
- **`docs/ui-guidelines.md`** — add a short note in the "Dialogs and Confirmations"
  section: "For non-dismissible recovery guidance (e.g. the XCSoar blocked-writability
  card), use a `Card` widget placed inline in the `ListView`. Do not use a dialog."

## Acceptance criteria

- [ ] Tapping a `warning` flavor tile shows `_BlockedFlavorGuidanceCard` inline below
  the tile.
- [ ] The card title is exactly "XCSoar can't be reached in its current location".
- [ ] The card body contains the three numbered recovery options with the correct
  heading text (no dialog is shown).
- [ ] `[Flavor name]` and `[pkg]` are replaced at runtime with the correct strings.
- [ ] Tapping the same tile again hides the card.
- [ ] No SAF picker is launched when a `warning` tile is tapped.
- [ ] `flutter analyze` reports no issues.
- [ ] `flutter test` passes including all five new widget tests.

## Constraints

- The guidance card must be a `Card` in the `ListView` — not a bottom sheet, dialog,
  overlay, or `Positioned` widget.
- Do not introduce new color tokens. Use `colorScheme.errorContainer` or existing
  `AppColors` tokens.
- Add `///` doc comments to `_BlockedFlavorGuidanceCard`.
- All `Text` content must not be hardcoded as constants in the test — tests must read
  the rendered text from the widget tree (use `find.text(...)` or `find.richText`).

## Reference

User story: `2025-05-02-flight-comp-selection.md`
