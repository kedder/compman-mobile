# Download Airspace and Waypoint Files from SoaringSpot

I want to download airspaces and waypoints from soaringspot when new ones are
published. Just like text-based compman did
(https://github.com/kedder/openvario-compman).

## Product Owner Notes

### Problem being solved

Glider pilots competing with XCSoar need up-to-date airspace and waypoint files
loaded onto their flight computer before each competition day. These files are
published on the competition's SoaringSpot downloads page and can be updated
during the event (e.g. revised airspace on day 3). Currently pilots must
download them manually via a browser and copy them to the device. This story
closes that gap.

### UI approach

The design mockup at `docs/design/competition_details_full_download_suite/` is
the authoritative visual specification.

The Competition Detail screen gains two new download cards below the existing
task card:

**Airspace card**
- Shows the airspace filename, file size, and the last-published timestamp
  sourced from SoaringSpot (e.g. "Updated: 19/04/2026, 12:53")
- Has an "Install" button to download and install the file onto the device
- Displays a "NEW UPDATE" badge when the SoaringSpot timestamp is newer than
  the timestamp recorded at last install
- If no airspace file is listed on SoaringSpot, shows "No airspace file
  available" instead

**Waypoints card**
- Same layout and behaviour as the Airspace card
- If no waypoint file is listed, shows "No waypoint file available"

Both buttons should be disabled while a download is in progress. Once a file is
installed the button should reflect the installed state (e.g. "Downloaded"
label or checkmark).

Files are saved with fixed names (`compman.txt` for airspace, `compman.cup` for
waypoints) into the same folder as the task file. Fixed names mean the user
only needs to configure XCSoar once and subsequent updates are picked up
automatically.

Refreshing the Competition Detail screen (pull-to-refresh or the AppBar action)
should also refresh the downloads data.

### Scope estimate

Medium — two new file types, two new cards, and timestamp-based tracking for
installed versions. Likely 3–4 issues.

### Related stories

- `issues/userstories/2026-05-01-rename-button.md` — renames the task install
  button; overlaps with the Competition Detail screen but is independent in
  scope. Plan both stories together to avoid conflicts.

### Relevant mockups

- `docs/design/competition_details_full_download_suite/` — authoritative visual
  spec for the full Competition Detail screen including Airspace and Waypoints
  cards with "NEW UPDATE" badges, filenames, file sizes, timestamps, and
  "Install" buttons
