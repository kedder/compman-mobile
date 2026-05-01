# Rename Task Download Button to "Download task"

Rename "Install XCSoar task" button to "Download task".

## Product Owner Notes

### Problem being solved

The current button label "Install XCSoar Task" is longer than necessary and uses
technical jargon ("XCSoar", "Install") that a pilot scanning the screen quickly may
not immediately parse as "tap to get the task file". The shorter label "Download task"
is more direct, matches the plain-English intent, and is consistent with the language
already used in `docs/features/overview.md` (which lists the action as "Download Task").
This change also brings the implementation into alignment with the authoritative UI spec.

### Screens affected

**Competition Detail Screen** only. The button appears inside the task `TwoToneCard`
as a full-width primary `ElevatedButton`. No other screen or widget carries this label.

### UX approach

Replace the button label text from "Install XCSoar Task" (current) to "Download task"
(target). No layout, interaction, or behavior changes. The button's disabled/loading
state label ("Downloading…" or equivalent, if one exists) should be reviewed for
consistency at implementation time and updated if it still references "Install".

The confirmation SnackBar shown after a successful download currently reads
"XCSoar task installed". That copy should also be updated to something like
"Task downloaded" so it remains coherent with the new button label.

Note: the Airspace and Waypoints cards added by the waypoints-airspaces story use
"Download" buttons as well — all three buttons on the Competition Detail screen use
consistent "Download" terminology.

### Scope estimate

Small — a single label string change on one button, plus a matching SnackBar copy
update. Fits in a single focused issue with a trivial implementation. The only care
needed is confirming all states of the button (default, loading, done) are updated
consistently.

### Related stories

- `issues/userstories/2026-05-01-waypoints-airspaces.md` — adds Airspace and
  Waypoints cards to the same Competition Detail screen. Both stories touch the same
  screen; the Planner should sequence or coordinate them so the final widget tree is
  coherent and there are no label collisions between the task button and the new
  "Install" buttons on the airspace/waypoint cards.

### Relevant mockups

- `docs/design/competition_details_full_download_suite/` — authoritative visual spec
  for the Competition Detail screen. The mockup currently shows "Install XCSoar Task"
  as the button label; this story changes that label to "Download task". The Planner
  should treat the mockup layout (card structure, placement, size) as the reference
  and apply the new label text.
