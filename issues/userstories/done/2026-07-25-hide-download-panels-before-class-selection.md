# Hide Airspace and Waypoints Panels Until a Class Is Selected

When user opens up a fresh competition window and class is not selected yet, let's hide
the waypoint and airspace panels. Some users do not notice that they have to select the
class.

## Product Owner Notes

### Problem being solved

On the Competition Detail screen, the Airspace and Waypoints download cards currently
render unconditionally, even before the pilot has picked their competition class. Since
class selection is the first required step, showing unrelated download cards above/around
it buries the "Select your class" prompt and lets users miss it — they see cards to
interact with (or ignore) and never notice the class picker needs their attention first.
Hiding the Airspace and Waypoints cards until a class is chosen makes the class-selection
step the sole focus of the screen when it's outstanding, which is also what the existing
`competition_details_class_selection` mockup depicts.

### UI approach

The design mockup at `docs/design/competition_details_class_selection/` already shows
this intended state: when no class is selected, the screen shows only the header and the
"Select your class" picker — no Airspace card, no Waypoints card.

Concrete proposal:

- While `competition.selectedClass` is unset, the Competition Detail screen shows the
  header section and the class picker only. The Airspace card and Waypoints card do not
  render at all (not a disabled/placeholder state — fully absent, consistent with how the
  Task section already behaves in this case).
- The `Divider` and the XCSoar directory footer row are **not** part of this change and
  keep showing regardless of class selection — that row is unrelated to class or task
  state (it just reports the configured XCSoar SAF folder), and pilots may want to check
  or set it up before picking a class.
- Once a class is selected, the screen reverts to today's full layout: class row, task
  section, Airspace card, Waypoints card, divider, XCSoar directory row — unchanged from
  current behavior.

This is a visibility-only change; no new states, copy, or interactions are introduced for
the cards themselves.

### Related stories

- `issues/userstories/2026-05-12-fly-button.md` (open, not yet planned) — proposes a "Fly
  XCSoar" button placed inside the Task card, above the Airspace/Waypoints cards. That
  button's visibility already depends on a task being downloaded, which itself requires a
  class to be selected, so it is naturally unaffected by this change. No conflict, but the
  Planner should be aware both stories touch the same screen section.

### Relevant mockups

- `docs/design/competition_details_class_selection/` — authoritative visual reference for
  the screen state before a class is selected: header + class picker only, no download
  cards.

### Scope estimate

Small — a single visibility condition on two existing widgets on one screen; no new
states, entities, or navigation changes.
