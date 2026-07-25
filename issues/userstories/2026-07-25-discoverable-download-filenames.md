# Show the Downloaded Filename in the Download Confirmation

Currently after user clicks "Download" button for airspace or waypoints, we show green banner saying "Airspace downloaded" or "Waypoints downloaded". User is supposed to select the downloaded files in XCSoar, but they don't know under what filename we download these files. How can we make it more discoverable for users?

## Product Owner Notes

### Clarification from the user

The app writes airspace and waypoints files to the XCSoar SAF directory under **fixed,
hard-coded filenames** — `compman-airspace.txt` and `compman-waypoints.cup` — regardless of
the source filename published by the competition organizer. This is deliberate: a fixed name
means XCSoar only has to be pointed at that file once, and subsequent updates silently
overwrite it, so the pilot never has to reconfigure XCSoar per competition or per update.

This means the filename currently shown on the Airspace/Waypoints card (e.g.
`germany_2026.txt`) is the *source* filename from the organizer — it is **not** what ends up
on disk, and is not what the pilot will see when browsing files inside XCSoar. Surfacing
that source filename more prominently (or making it copyable) would not have solved the
problem and could actively mislead the pilot into looking for the wrong name. A copy action
was also not a fit for a different reason: XCSoar's file picker is a selection list, not a
text-entry field, so pilots need to *recognize* a fixed name in a list, not paste one in.

### Problem being solved

After downloading an airspace or waypoints file, the pilot's next step is to leave Compman,
open XCSoar, and pick the matching file from XCSoar's own file browser/list. The only
feedback Compman gives at that moment is a generic green SnackBar — "Airspace downloaded" or
"Waypoints downloaded" — which confirms success but never states the fixed filename the
pilot needs to recognize in that list.

### UI approach

Concrete proposal, scoped to the existing download confirmation moment (no new screens):

- Change the confirmation SnackBar text to state the fixed on-device filename directly:
  `Airspace downloaded as compman-airspace.txt` / `Waypoints downloaded as
  compman-waypoints.cup`. Since the name is always the same for a given file kind, this is a
  static string per kind, not something read off the downloaded file — the pilot learns the
  one name to look for in XCSoar and it never changes between competitions or updates.
- No copy action, no dynamic filename interpolation — the fix is purely stating the fixed
  name at the moment of confirmation, which is the one moment the pilot is guaranteed to be
  looking at Compman before switching to XCSoar.
- The source-filename text already shown on the Airspace/Waypoints card is unchanged by this
  proposal; it describes the organizer's published file, not the on-device name, and is out
  of scope here.

This keeps the fix scoped to the existing SnackBar per `docs/ui-guidelines.md` ("Snackbars
are appropriate only for transient confirmations").

**Task download confirmation is explicitly out of scope.** The task file (`Default.tsk`) is
also written under a fixed name, but the pilot never selects it by hand in XCSoar — XCSoar
loads `Default.tsk` automatically on startup with no explicit file-picking action. Since
there is no "find this file in a list" moment for the task, stating its filename would not
close any discoverability gap the way it does for airspace/waypoints. The "Task downloaded"
SnackBar text is unchanged.

### Related stories

None — no other open user story touches the download confirmation SnackBars. (Note:
`issues/userstories/2026-05-12-fly-button.md`, an open story, adds a "Fly XCSoar" button to
this same screen, but does not touch the Airspace/Waypoints download flow or its
confirmation messaging.)

### Relevant mockups

`docs/design/competition_details_full_download_suite/` — shows the Competition Detail
screen with the Airspace and Waypoints cards, for layout reference. No mockup depicts the
SnackBar itself; SnackBars are a system-provided transient element and are not typically
mocked up in this project's design docs.

### Scope estimate

Small — text-only change to the two airspace/waypoints SnackBar messages, each naming an
already-fixed, already-known constant. Task download confirmation is unchanged (see above).
No new UI elements, entities, or navigation changes.
