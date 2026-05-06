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

### Entry points

The screen is reachable from the **Settings** menu (title: "XCSoar Folder")
and from the Competition Detail screen when a download fails because no folder
has been configured yet (title: "Set Up XCSoar Folder"). In the latter case
the app resumes the pending download automatically after the user completes
setup.
