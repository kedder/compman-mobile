# Launch XCSoar from the Competition Detail Screen

when task is downloaded, I want a "Fly" button to start the selected xcsoar flavor.

## Product Owner Notes

### Intent

The pilot's final step before a task is to open XCSoar with the task loaded. Right now
they must leave Compman, find XCSoar in the launcher, and launch it manually. A "Fly"
button eliminates that hand-off friction. The app already knows which XCSoar flavor is
active (the flavor whose SAF directory has been granted); it just needs to launch it.

### Existing infrastructure to build on

- `XcsoarSafService.resolveFlavorPackageId(candidatePackageIds)` already identifies the
  active flavor's package ID by matching the stored SAF tree URI against
  `kKnownXcsoarFlavors`. This is the mechanism used to show the "active" indicator on the
  XCSoar Directory Settings screen.
- `kKnownXcsoarFlavors` already enumerates all four known variants with their package IDs.
- The Android bridge already has `isPackageInstalled(packageId)` on the `xcsoar.saf`
  MethodChannel.

### Which screens are affected

Only the Competition Detail screen (`/competitions/:id`) gains new UI. No new screens are
required.

### Concrete UX proposal

Place a full-width "Fly XCSoar" filled `ElevatedButton` (with a flight/rocket icon,
e.g. `Icons.flight`) directly below the **"Download task"** button, inside the Task
card — above the Airspace and Waypoints cards, not below them.

**Color:** Use the app's existing green "success" semantic color (`appColors.success`),
not the primary blue used by "Download task" — the same green already used elsewhere in
the app for confirmed/ready states (success messages, the "Installed" indicator). This
gives the Fly button a visually distinct, unmistakable "cleared to go" appearance rather
than blending in with the download actions above it.

This matches the pilot's actual morning routine: download the task, then fly. Airspace
and waypoint files are updated rarely (weeks or the whole season apart) and are not part
of the immediate pre-flight action, so the Fly button must not sit behind them.

**Visibility:** The button does not exist in a disabled "not ready yet" state before the
task is downloaded — it is **not rendered at all** until the task has been successfully
downloaded for this competition. This replaces the earlier decision to show the button
unconditionally (see "What 'task is downloaded' means for scope" below, which is now
superseded).

Once a task has been downloaded successfully, the button keeps showing on every later
visit to this Competition Detail screen, including after an app restart — **unless a
newer task version becomes available**. If the Task card is showing its "New" badge (a
newer version exists than the one downloaded), the Fly button is hidden again. Flying is
only offered when the pilot is certain to launch the exact task version they most
recently downloaded; if the organizer republishes the task, the pilot must download the
update before the Fly button reappears. This prevents a pilot from accidentally flying a
stale task without realizing a newer one was published. (The app already tracks whether a
task version has been installed per competition, to drive the "New" badge — the Fly
button's visibility reuses that same knowledge, not a new concept.)

**Button states (once visible):**

| Condition | Button appearance | On tap |
|---|---|---|
| Active flavor detected (`resolveFlavorPackageId` returns a package ID) | Enabled. Label: "Fly XCSoar" (or "Fly XCSoar Jet" etc. if the flavor name is known). | Launch the flavor via `android.intent.action.MAIN` + `android.intent.category.LAUNCHER` intent. |
| No SAF directory configured (`resolveFlavorPackageId` returns null, no flavor `ready`) | Disabled. Label: "Fly XCSoar". Subdued secondary text below the button: "Set up XCSoar folder first." | Non-interactive. |
| SAF is configured but no XCSoar flavor is installed | Disabled. Label: "Fly XCSoar". Subdued secondary text: "XCSoar is not installed." | Non-interactive. |

The button must meet the 64 dp minimum height for full-width CTA buttons per
ui-guidelines, styled as a filled `ElevatedButton` using the green success color instead
of the primary blue (see "Color" above).

The disabled state reduces opacity to 38% and the label remains readable, giving the
pilot an immediate explanation without navigating away (consistent with how the download
button handles `SAF_NOT_CONFIGURED` banners, but simpler because launching is not
retryable in the same flow).

**No confirmation dialog** — launching an app is not destructive.

**No loading spinner** — launching is instantaneous on Android; the OS handles it.

### What "task is downloaded" means for scope

**Revised:** "when task is downloaded" is a gating condition, not just motivating context.
The Fly button is hidden until the task has been successfully downloaded for this
competition on this device; see "Visibility" above. This was reconsidered from an earlier
version of this story that treated download state as irrelevant — the pilot's actual
workflow is download-then-fly in immediate succession, so surfacing the button only once
that first step is done keeps the screen uncluttered and reinforces the sequence.

This does mean the button will not appear if the pilot downloaded the task on a different
device (Compman does not sync download state across devices). This is accepted as a minor
edge case: the pilot can re-download the task on this device, which is a low-cost action
they'd likely want to confirm anyway before flying from a new device.

### Edge cases

- If the intent fails (XCSoar uninstalled mid-session, or a custom flavor with no
  launcher activity), catch the `PlatformException` / `ActivityNotFoundException` and
  show a dismissible error banner consistent with the existing download-error banner
  pattern ("Could not launch XCSoar. Is it installed?").
- The active-flavor detection (`resolveFlavorPackageId`) is an async call. Once the task
  has been downloaded and the button becomes visible, it should render in the disabled
  "no flavor" state while the check is in flight, then update once resolved. This is
  consistent with how `xcsoarDirectoryUriProvider` already drives the directory footer
  row.
- While a "New" badge is showing (a newer task version is available), the Fly button
  stays hidden even though a previously downloaded task is technically still installed
  and launchable — the pilot must tap "Download task" again to bring the Fly button back,
  now pointing at the current version.

### Implementation path (for the Planner — not prescriptive)

This is a single-screen UI addition backed by one new Android bridge method
(`launchPackage(packageId)`) and a small provider to expose the resolved active-flavor
package ID. Visibility relies on the existing per-competition installed-task-version
tracking that already powers the "New" badge — no new persistence concept. No new
screens, no new entities, no domain model changes.

### Related stories

None — no other open user stories touch XCSoar launch or the Fly workflow.

### Relevant mockups

`docs/design/competition_details_full_download_suite/` — shows the Competition Detail
screen layout and the Task card containing the task download button (labeled "Install
XCSoar Task" in this older mockup; the current app label is "Download task" — see
`docs/plan.md`). The Fly button is placed directly below that button, inside the same
card. The mockup predates the Fly button and does not depict it.

### Scope estimate

Small — one new button on an existing screen, one new Android bridge method, one new
provider. No new screens, entities, or navigation routes.
