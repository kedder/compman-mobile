# XCSoar App Flavor Picker: Reduce Directory-Setup Friction

Users are having trouble navigating the right XCSoar data directory. Right now the
selection is placed in the Settings screen, which is also not obvious to users: right
now they need to go to Settings and configure the directory before they can download any
tasks, airspace, or waypoints. This is a major friction point and barrier to entry.

Also, there are sevral flavors of XCSoar software (the flight computer) available to
install. Each uses a different data folder (but compatible file formats, so this app can
support all of them).

The flavors I'm aware of are:

- Original XCSoar: `com.xcsoar`
- XCSoar Jet: `com.zunuzoid.xcsoar_jet`
- XCSoar Play: `com.xcsoar.play`
- XCSoar FOSS: `com.xcsoar.foss`

User may have installed one or more of these. We need to allow user to pick which flavor
he wants to use with this app and automatically configure the directory for them.

There are few gotchas surfaced from real-life testing:

- XCSoar's data directory is chosen automatically on startup, not via any user-facing
  setting or menu. On first launch XCSoar checks for `xcsoar.log` in
  `Android/data/<pkg>/files/`. If found, it stays on that path permanently. If not
  found, it defaults to `Android/media/<pkg>/`. There is no XCSoar toggle to change
  this; the only way to migrate is to remove the existing data from `Android/data`.
  On Android 11+, Compman cannot write to another app's `Android/data` directory via
  SAF — Android blocks it explicitly. So if XCSoar is using `Android/data`, Compman
  simply cannot function with that flavor until the user migrates.
- Uninstalling XCSoar does delete `Android/data/<pkg>` (Android clears external
  app-specific storage on uninstall), which is one migration path.
- We should still let user pick arbitrary directory, but it should be reserved for
  advanced users.

## Product Owner Notes

### Problem and user goal

First-time users must visit a non-obvious Settings screen and navigate a raw Android
folder picker before Compman can write any files. Most users do not know the exact path
for their XCSoar variant. This creates a hard blocker: without the directory, every
download silently fails or surfaces a cryptic error. The goal is to get the user through
directory setup in a single, guided step — ideally without ever seeing a file-system path.

Setup is triggered contextually, at the moment the user first attempts a download.
There is no onboarding or setup step on app launch and no prompt before the user has
bookmarked any competitions.

### What the feature must do

**Flavor selection list.** Replace the current "Change Directory" button on the XCSoar
Folder Settings screen with a list of known XCSoar flavors. Each entry shows:
- A display name (e.g. "XCSoar", "XCSoar Jet", "XCSoar Play", "XCSoar FOSS")
- The associated package ID in subdued text (e.g. `com.xcsoar`) as a secondary label
- A visual state badge reflecting the result of two checks: (1) whether the package is
  installed, and (2) whether the associated data directory is writable. The three states
  and their visual treatment are:
  - **Installed and writable** — green/ready badge (e.g. "Ready")
  - **Installed but not writable** — amber/warning badge (e.g. "Needs setup")
  - **Not installed** — muted/grey badge (e.g. "Not installed")

When the user taps a flavor entry, the app automatically constructs the correct data
directory path for that flavor and opens the Android SAF folder picker pre-navigated to
that path, so the user only needs to confirm rather than navigate.

**"Android/data vs Android/media" writability enforcement.** For each flavor the app
checks at runtime whether writes to the detected directory path will actually succeed on
the current Android version:

- If the directory is writable, the flavor is in the **ready** state and the user may
  proceed normally after tapping it.
- If the package is installed but the directory is not writable (because
  `Android/data/<package>` is inaccessible on Android 11+), the flavor is in the
  **warning** state. Tapping it opens the flavor tile's inline guidance panel rather
  than the SAF picker. The user cannot proceed with this flavor until writability is
  confirmed — selection is blocked.
- The inline guidance for the blocked case must not be a dialog. It is a non-dismissible
  `Card` or info banner shown directly below the selected flavor tile.
- The blocked-state guidance panel must honestly explain that there is no quick fix:
  XCSoar chose `Android/data` automatically (based on an existing `xcsoar.log` file)
  and has no in-app setting to change this. It must then present the following recovery
  options as a numbered list, clearly labelled by risk level, in this order from least
  to most destructive:
  1. **Move XCSoarData using a file manager (safest — preserves all data)** — move
     `Android/data/<pkg>/files/XCSoarData/` to `Android/media/<pkg>/XCSoarData/` using
     a file manager that has `Android/data` access, then restart XCSoar. Note that most
     modern Android file managers cannot access `Android/data`, which makes this option
     difficult in practice.
  2. **Clear app data in Android Settings (all XCSoar data lost)** — go to Android
     Settings → Apps → XCSoar → Storage & Cache → Clear Storage. This deletes
     `Android/data/<pkg>` so XCSoar defaults to `Android/media` on next launch. Warning:
     all XCSoar settings and stored data are permanently deleted.
  3. **Back up, then reinstall (XCSoar settings lost)** — manually back up XCSoarData
     first, uninstall XCSoar (which deletes `Android/data/<pkg>`), reinstall, then
     restore the backup. Warning: XCSoar configuration settings are lost unless manually
     saved and restored.
  4. **Uninstall and reinstall without backup (all data permanently lost)** — same as
     option 3 but without backing up first. Warning: all XCSoar settings and data are
     permanently and irrecoverably lost.

#### Verbatim copy for the inline guidance card

The following block is the exact text the implementation must render in the
non-dismissible `Card` shown below a blocked flavor tile. `[Flavor name]` is replaced
at runtime with the human-readable flavor name (e.g. "XCSoar", "XCSoar Jet",
"XCSoar FOSS", "XCSoar Play"). `[pkg]` is replaced with the flavor's package ID
(e.g. `com.xcsoar`).

---

**Card title:** "XCSoar can't be reached in its current location"

**Card body:**

[Flavor name] is installed, but it's storing its files in a folder that Android no longer allows other apps to access (`Android/data`). This happens with older XCSoar installations — XCSoar automatically keeps using the original folder as long as files are found there, and there's no option inside XCSoar to change this.

To use Compman with [Flavor name], you'll need to free it from that folder:

**1. Back up, uninstall, and reinstall** *(preserves files if backed up)*
Copy your `XCSoarData` folder from `Android/data/[pkg]/files/` somewhere safe first. Then uninstall [Flavor name] — this deletes `Android/data/[pkg]` — reinstall, and restore your backup.

**2. Clear XCSoar's app data** *(settings and data lost)*
Settings → Apps → [Flavor name] → Storage & Cache → Clear Storage. XCSoar will create a new accessible folder on next launch. Warning: all profiles, settings, and logbook entries are permanently deleted.

**3. Uninstall and reinstall** *(simplest, data lost)*
Uninstall and reinstall [Flavor name]. Warning: all settings and data are permanently deleted.

---

Notes for the Planner:
- `[Flavor name]` is replaced at runtime with the human-readable name of the selected flavor (e.g. "XCSoar", "XCSoar Jet", "XCSoar FOSS", "XCSoar Play").
- `[pkg]` is replaced with the package ID of the selected flavor (e.g. `com.xcsoar`).
- This card is shown inline on the flavor picker screen below the blocked flavor tile. It is non-dismissible.

**Custom directory fallback.** Keep the ability for users to pick an arbitrary folder via
the native picker. Place it at the bottom of the list as an "Advanced: choose custom
folder" option, visually separated from the flavor list with a divider or section label.
Do not remove the existing "Reset Permission" / "Clear" functionality.

**Entry-point: contextual setup at first download attempt.** The XCSoar folder setup
must not rely solely on the Settings screen and must not appear before the user has
bookmarked competitions. When the user taps any download button (task, airspace, or
waypoints) and no directory is configured yet, the app navigates directly to
`/settings/xcsoar-directory` (the flavor-picker screen) rather than showing an opaque
error. This is the same screen that is reachable from Settings — not a separate flow.

**Post-setup auto-resume.** After the user successfully configures the directory via the
flavor-picker screen (reached from the `SAF_NOT_CONFIGURED` path in Competition Detail),
the app must automatically start the pending download when returning to the detail screen.
The user must not need to tap the download button again.

If the user aborted setup — either by navigating back without completing a selection, or
because no usable (writable) option existed — the app returns to the Competition Detail
screen and restores the error banner in its previous state so the user can try again.
There must be no silent failure: either the download starts automatically or the error
banner is visible.

### Screens affected

There is **one screen, one UI, two entry points.** The existing
`/settings/xcsoar-directory` screen is fully replaced by the flavor-picker UI. There is
no separate "settings mode" vs "first-time setup mode" — the content and interaction
model are identical regardless of how the screen is reached. The only permitted
difference between the two entry points is the AppBar title (e.g. "Set Up XCSoar
Folder" when reached from a download attempt vs "XCSoar Folder" from Settings) or
back-navigation behavior.

1. **XCSoar Directory Settings Screen** (`/settings/xcsoar-directory`) — fully replaced
   by the flavor-picker UI. The current raw directory display and single "Change
   Directory" button is replaced by the flavor-picker list with per-flavor state badges.
   The existing "Reset Permission" / "Clear" functionality is retained. This is the one
   and only flavor-picker screen; the Settings entry point and the contextual entry point
   both lead here.

2. **Competition Detail Screen** (`/competitions/:id`) — the `SAF_NOT_CONFIGURED` error
   path currently appends a dismissible error banner. This path should instead navigate
   the user to the flavor-picker screen (`/settings/xcsoar-directory`), passing enough
   context to auto-resume the pending download on return. After successful configuration
   the download starts automatically; after an aborted or failed setup the error banner
   is restored.

### UX approach

Use a `ListView` of `ListTile` rows for the flavor list, consistent with the existing
Settings screen layout. Flavors in the ready state appear first; warning-state flavors
follow; not-installed flavors are last and de-emphasised with muted label color. A
divider separates the known-flavors section from the "Advanced" custom-picker row at the
bottom.

The inline writability-blocked guidance must not be a dialog — dialogs are reserved for
destructive confirmations per `docs/ui-guidelines.md`. Show it as a non-dismissible
`Card` or info banner directly below the selected flavor tile.

Do not show raw SAF URI strings to the user in the main selection flow. The URI may
still appear in the existing "current folder" display for power users who used the
advanced option, but users on the flavor-picker path should see only the human-readable
app name.

### Related stories

- `2026-05-01-remember-competiton.md` — independent (navigates to last-viewed competition
  on open); no conflict, but both aim to reduce friction at app launch / first use.
  No merge needed.

### Relevant mockups

None found in `docs/design/` for the settings screen. No mockup exists for the flavor
picker.

### Scope estimate

Medium — the feature redesigns one screen (`/settings/xcsoar-directory`) and wires it
into the Competition Detail flow. It requires detecting installed Android packages and
probing directory writability (new native capability), adds conditional navigation logic
with download auto-resume, and adds the blocked-writability guidance path. Likely 3–4
issues: (1) the flavor-picker UI, package detection, and per-flavor writability badges,
(2) the auto-navigation from the detail screen on `SAF_NOT_CONFIGURED` with
pending-download context, (3) the blocked-writability inline guidance and selection
enforcement, and optionally (4) any feature-doc and docs/plan updates.
