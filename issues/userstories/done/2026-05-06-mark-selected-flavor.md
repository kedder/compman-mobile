# Mark Selected XCSoar Flavor in the Picker UI

After picking the xcsoar flavor, we need to mark it as selected in the UI.
Right now it is not clear which flavor is actually being used for installing files. User can tell from the folder, but it not obvious.

## Product Owner Notes

### Problem and user goal

The XCSoar flavor picker (`/settings/xcsoar-directory`) lets users choose which XCSoar
variant Compman writes files to. Once a flavor is picked and the SAF folder is
configured, the screen gives no persistent indication of which flavor is active. The
current directory URI is shown in the header tile, but it is a raw SAF URI — not a
human-readable flavor name. A user who returns to the Settings screen (or who is sent
there from a download error) cannot tell at a glance which flavor they previously
selected.

The goal is to surface the currently-configured flavor clearly so that users can confirm
the right variant is active without having to decode the raw URI string.

### What the feature must do

**Derive the active flavor at runtime — no new persisted value.** The stored SAF URI is
already the single source of truth for the configured directory. The selected flavor is
derived by comparing that URI against each flavor's canonical media-directory URI — the
same comparison already used for auto-detection after a custom folder pick. No new field
needs to be written to the Hive `"settings"` box, and no `packageId` should be persisted
separately.

**Visual selection indicator.** On the `XcsoarDirectorySettingsScreen`, the flavor tile
that corresponds to the currently-configured flavor must be visually distinguished from
the others using a leading icon with a radio-style transition:

- Unselected state: `Icons.radio_button_unchecked` in `colorScheme.outline` color.
- Selected state: `Icons.check_circle` in `colorScheme.primary` color.
- In addition, the existing `ListTile.selected = true` background tint (already wired
  via the `isSelected` field) must remain active for the selected tile, providing a
  second non-color cue (shape change + background tint) to satisfy the accessibility
  rule that color alone must never be the sole indicator.

**Keep the writability badge.** The "Ready" / "Needs setup" / "Not installed" badge must
remain on every tile. The selected-flavor indicator is additive, not a replacement for
the badge. Both pieces of information must coexist on the selected tile.

**Custom folder case.** When the user configured a directory via the "Advanced: choose
custom folder" row (i.e. `pickDirectory` rather than `pickDirectoryForPackage`), and the
stored SAF URI does not match any known flavor's canonical media-directory URI, no known
flavor is resolved. The settings screen header must reflect this with a label such as
"Custom folder" and no flavor tile should be highlighted.

**Header tile improvement.** The existing header `ListTile` currently shows the raw SAF
URI as its subtitle. This tile must be moved to the existing "Advanced" section of the
screen — it is useful for power users who need to verify the exact path, but it is not
primary information. In the flavor list area (above the Advanced section), replace it
with a concise status line that shows either the resolved flavor's `displayName` (e.g.
"XCSoar Jet selected") or "Custom folder" when no known flavor is resolved. The raw SAF
URI must only appear in the Advanced section, visually de-emphasized (e.g. smaller
secondary text), so casual users are not distracted by it.

**Auto-detect flavor from custom folder.** When the user picks a directory via the
"Advanced: choose custom folder" picker, the app must compare the returned SAF URI
against the known canonical media-directory URIs for each XCSoar flavor. If the picked
URI matches a flavor's expected directory, the corresponding flavor tile is immediately
highlighted and the status line shows that flavor's display name — because the derive
step runs on the now-updated stored URI. No additional write is needed. Only if the URI
does not match any known flavor should the "custom folder / no flavor selected" state be
shown.

### Screens affected

1. **XCSoar Directory Settings Screen** (`/settings/xcsoar-directory`) — the only
   affected screen. Three sub-areas change: the primary status display (moved and
   simplified), the flavor list tiles (selection highlight), and the Advanced section
   (now also hosts the raw URI tile).

### UX approach

The selected-flavor indicator should follow the existing `ListTile` conventions already
used in the app. The recommended approach is:

- Place a leading icon on every flavor tile using a radio-style transition: unselected
  tiles show `Icons.radio_button_unchecked` in `colorScheme.outline`; the selected tile
  shows `Icons.check_circle` in `colorScheme.primary`. The existing `ListTile.selected`
  background tint (already wired via `isSelected`) remains active on the selected tile,
  providing a second non-color cue that satisfies the accessibility rule from
  `docs/ui-guidelines.md`.
- Remove the current prominent header `ListTile` that shows the raw URI at the top of
  the list. Replace it with a compact, plain-text status line just above the flavor list
  section header ("XCSOAR APP"), showing the resolved flavor name or "Custom folder".
- Move the raw SAF URI display into the existing "Advanced" section, beneath the
  "Choose custom folder" row. Style it as secondary/caption text so it reads as
  supplementary information rather than a primary label.
- The auto-detect behavior is silent and immediate: no confirmation dialog or extra
  toast is needed beyond the existing "XCSoar folder configured" snackbar. The visual
  highlight on the detected flavor tile serves as confirmation.

The Planner should derive the exact widget-level approach from the existing
`_FlavorTile` implementation in
`lib/features/xcsoar/presentation/screens/xcsoar_directory_settings_screen.dart`.
The existing "ADVANCED" section label in that screen's `ListView` is the correct anchor
point for the URI display and the custom-folder picker row.

### Related stories

- `2025-05-02-flight-comp-selection.md` — the parent story that introduced the flavor
  picker. This story extends it by adding persistent selection state and a visual
  indicator. No conflict; same screen.

### Relevant mockups

None found in `docs/design/` for the XCSoar settings screen.

### Scope estimate

Small — touches one screen and introduces no new persisted state. The active flavor is
derived purely at read time by comparing the already-stored SAF URI against each flavor's
canonical media-directory URI, which the SAF service already computes internally (used by
`pickDirectoryForPackage`). The only incremental work over the base story is: (1)
exposing that canonical URI per flavor so it can be compared at call sites, and (2)
restructuring the screen layout to move the raw URI display into the Advanced section and
add the visual selection indicator. No Hive schema change, no migration. Fits
comfortably in a single issue.
