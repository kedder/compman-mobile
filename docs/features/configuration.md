# Feature: Configuration

App-level settings that cut across features. Currently this covers the XCSoar
folder setup, which must be completed before any task or file download can reach
XCSoar.

---

## XCSoar Folder Setup (`/settings/xcsoar-directory`)

Before Compman can deliver files to XCSoar it needs write access to XCSoar's
data folder on the device. Android's Storage Access Framework (SAF) requires
the user to grant this access explicitly through the system folder picker.

### User flow

1. The screen opens and probes each known XCSoar variant to determine whether
   it is installed and whether its data folder is accessible.
2. The user taps their installed variant. If the folder is accessible the
   system folder picker opens, pre-navigated to the right location, and the
   user confirms access with one tap.
3. On success the screen shows a confirmation and the app can now write files
   to that folder.

If a variant is installed but its folder is not accessible (this happens when
XCSoar was installed on an older Android version and its data landed in the
restricted `Android/data` path), the screen shows inline recovery guidance
explaining how to move XCSoar to an accessible location.

Users who need to point Compman at a non-standard location can use the
**Advanced → Choose custom folder** option to navigate to any folder manually.

### Known XCSoar variants

| Variant | Package |
|---|---|
| XCSoar | `org.xcsoar` |
| XCSoar Jet | `com.zinuzoid.xcsoar_jet` |
| XCSoar Play | `org.xcsoar.play` |
| XCSoar FOSS | `org.xcsoar.foss` |

### Folder states

Each variant shows one of three states:

| Badge | Meaning |
|---|---|
| **Ready** | Installed and writable — one tap to configure |
| **Needs setup** | Installed but folder is not accessible; shows recovery guidance |
| **Not installed** | Not on this device; row is non-interactive |

Variants are sorted ready → needs setup → not installed so the actionable
choice is always at the top.

### Blocked-writability guidance

When a warning-state flavor tile is tapped, a non-dismissible `Card`
(`_BlockedFlavorGuidanceCard`) appears inline in the `ListView` directly below
the tile. It lists three numbered recovery options for moving XCSoar out of
the restricted `Android/data` path. Tapping the same tile again collapses the
card (toggle). No SAF picker is launched for warning-state flavors.

### Active flavor indicator

When the screen loads (and after every successful directory pick), it calls the
`resolveFlavorPackageId` Kotlin bridge method, passing the stored SAF tree URI
and the list of known package IDs from `kKnownXcsoarFlavors`. Kotlin iterates
the candidates and returns the package ID whose canonical
`content://…/tree/primary%3AAndroid%2Fmedia%2F<pkg>` URI matches the stored
value, or null if none match.

The result drives two visual indicators:

- **Status line** — a compact text line above the "XCSOAR APP" section shows
  `"<DisplayName> selected"` (e.g. "XCSoar Jet selected") when a known flavor
  is active, `"Custom folder"` when a URI is stored but matches no known flavor,
  or `"Not configured"` when no URI is stored.
- **Leading icons** — every flavor tile shows `Icons.check_circle` (in
  `colorScheme.primary`) for the active flavor and `Icons.radio_button_unchecked`
  (in `colorScheme.outline`) for all others, satisfying the color-is-not-the-
  sole-indicator rule from `docs/ui-guidelines.md`.

No new value is persisted; the active flavor is re-derived from the stored SAF
URI on every screen entry.

### Raw URI (Advanced section)

The stored SAF tree URI is shown in the **Advanced** section as a `ListTile`
with title "XCSoar folder". The subtitle is styled in `bodySmall` /
`onSurfaceVariant` to de-emphasize it. This is useful for debugging but not
needed for normal use.

### Entry points

The screen is reachable from the **Settings** menu (title: "XCSoar Folder")
and from the Competition Detail screen when a download fails because no folder
has been configured yet (title: "Set Up XCSoar Folder"). In the latter case
the app resumes the pending download automatically after the user completes
setup.
