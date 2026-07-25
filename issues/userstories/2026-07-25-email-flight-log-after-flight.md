# Suggest Emailing Today's Flight Logs to Organizers After Flying

After pilot finishes the flight and exits XCSoar, we may suggest to email today's flight
log to competition organizers for scoring. Competitions are typically use pre-defined
email address for the full length of competition (each competition would use different
email for scoring).

XCSoar stores flight logs in its media folder, under `logs/*.igc` files e.g.
`logs/2018-02-26-XCS-WUX-01.igc`. The 2018-02-26 is a date of the flight, the last `-01`
indicates a flight number. Pilot may take off several times, each such flight will be
logged in a separate file. Organizers typically require all flights for the day.

Compman should list all todays flights and provide a button to send them to
user-provided email address as attachments. User should be able to unselect flights they
don't want to send.

## Product Owner Notes

### Intent

Today the pilot's post-flight workflow ends outside Compman entirely: they must leave
XCSoar, find the day's `.igc` file(s) on the device, and attach/send them to the
organizer by hand (usually by digging through a file manager and a generic email app).
This story closes that loop inside Compman: surface today's flight logs whenever the
pilot is on the Competition Detail screen and let them hand the files off to their mail
app, addressed to the organizer's scoring address, in a couple of taps — without ever
needing to locate the files themselves. The suggestion is not tied to having launched
XCSoar from Compman; it simply reacts to today-dated log files being present, so a pilot
can also use it to resend a log an organizer says they never received.

### New concepts this introduces

This story introduces two things that don't exist anywhere in the app today:

1. **A per-competition scoring email address.** Nothing in the current domain model
   (`BookmarkedCompetition`) stores an organizer contact address, and no screen currently
   collects or displays one. Resolved (see Question 1): it is entered manually by the
   pilot, prompted the first time they choose to send a log, remembered for that
   competition thereafter, and editable later.
2. **Reading IGC logs out of XCSoar's data folder.** All existing XCSoar integration
   (see `docs/features/xcsoar.md`) is one-directional: Compman *writes* task, airspace,
   and waypoint files into the granted SAF directory. This story requires the reverse —
   *listing and reading* files XCSoar itself wrote (`logs/*.igc`) — which is a new
   capability on top of the same granted directory, not something already built.

Sending the email itself is *not* a new concept Compman needs to build: per Question 3,
Compman hands the selected files off to the device's own mail app via a standard
share/send intent rather than sending anything itself, so there is no SMTP integration,
credential storage, or server-side email concern to design for.

### Which screens are affected

- **Competition Detail screen** (`/competitions/:id`) — gains a persistent Flight Logs
  panel, shown below the Task section alongside the Airspace/Waypoints download cards,
  that summarizes today's flight logs and provides the entry point into the Flight Log
  screen.
- **A new screen** for reviewing and sending today's flight logs (list of flights with
  checkboxes, recipient email field, send action). No existing mockup covers this. This
  same screen is also where the scoring email address is first entered and later edited
  (see Question 1) — no separate dedicated screen is needed for it.

### Concrete UX proposal

- **Flight Logs panel:** A single, persistent panel on the Competition Detail screen —
  shown below the Task section, alongside (and styled consistently with) the
  Airspace/Waypoints download cards — replaces the two separate entry points from an
  earlier draft of this proposal (a dismissible "suggestion" banner plus a manual
  fallback action). There is no dismiss button and no re-offer state machine to build:
  the panel is simply always there. Whenever the Competition Detail screen for a
  bookmarked competition becomes active (including resuming from the background, not just
  a fresh navigation), it checks the configured XCSoar directory for `logs/*.igc` files
  dated today and shows a concise one-line summary, e.g. "2 flight logs recorded
  [Email]" (singular when there's exactly one: "1 flight log recorded [Email]"), where
  "Email" is an inline button/action that opens the Flight Log screen. This check is
  independent of how or whether XCSoar was launched (see Question 2) — it works equally
  for a pilot who launched XCSoar from Compman's own button (if that feature exists),
  from the home screen directly, or is simply reopening Compman later the same day to
  resend a log an organizer says they missed. **Zero-logs state:** if no `.igc` files are
  dated today, the panel does not hide — it follows the same convention already
  established by the Airspace/Waypoints cards for their own no-data case (muted "No
  airspace file available" / "No waypoints file available" text, per
  `docs/features/competitions.md`), showing a muted "No flight logs recorded today" line
  with no action button, since there's nothing to send yet. (This is a different
  situation from the Airspace/Waypoints cards being hidden entirely before a class is
  selected, per
  `issues/userstories/2026-07-25-hide-download-panels-before-class-selection.md` — that
  is a prerequisite gate unrelated to data availability, whereas "zero logs today" is a
  plain data-availability empty state, so the muted-text convention is the right match
  here, not the hide-entirely one.) Because the panel is always visible, pilots are never
  blocked from opening the Flight Log screen manually — including on a day with no fresh
  `.igc` files, e.g. to review/resend an older log — without needing a separate fallback
  entry point.
- **Flight Log screen:** Lists every `.igc` file dated today for this competition's
  configured XCSoar folder, one row per flight, showing the actual on-disk filename as-is
  (e.g. `2018-02-26-XCS-WUX-01.igc`) rather than a parsed, friendlier label — the pilot
  needs to see exactly what will be attached and sent before it goes out, so the raw
  filename is shown, not a derived name like "Flight 1"/"Flight 2". Each row has a
  checkbox, pre-checked by default — every visit starts
  with all of today's flights freshly selected; Compman does not track or remember which
  flights were sent on a previous visit (see Question 4), since organizers sometimes ask
  for a resend. Below the list, a recipient email field: the first time the pilot sends a
  log for this competition, the field is empty and required; once a value has been
  entered and sent successfully, it is remembered as the competition's scoring address
  and pre-filled (but still editable) on every subsequent visit. Per Question 6, any
  edit to this field that is followed by a successful send overwrites the remembered
  scoring address for this competition going forward — there is no separate "just this
  once" option — since a pilot correcting a wrong address is the common case, not
  sending to a one-off alternate contact. A full-width "Send"
  button is disabled when zero flights are selected or the email field is empty/invalid.
  Pressing "Send" hands off to the device's mail app via a share/send intent, addressed
  to the recipient, with the selected `.igc` files attached; per Question 5, the subject
  is either derived from the attachment filenames (e.g. `XCS-WUX-01, XCS-WUX-02`) or left
  blank for the pilot to fill in inside the mail app, whichever is simpler to build —
  organizers identify the pilot from the attachment filenames, not the subject/body.
- **Flight Log screen empty case:** The Flight Logs panel's own "Email" action only
  appears once there is at least one log to send (see zero-logs state above), so this
  case is mainly a defensive fallback (e.g. today's last log is deleted/moved while the
  screen is open). If the Flight Log screen is ever opened with zero `.igc` files dated
  today, it shows a plain empty state ("No flight logs found for today") consistent with
  other empty states in the app — one sentence, no CTA, since there's nothing to act on.
- **Feedback:** Because Compman hands off to the device's mail app rather than sending
  the email itself (Question 3), there is no in-app send success/failure/retry loop to
  build — the app's job ends once the share/send intent is launched with the recipient,
  attachments, and (optionally) subject filled in; the mail app owns the actual send and
  any further feedback about it. The only in-app failure case worth handling is if no
  mail app is available to receive the intent, which should get a simple inline error
  message consistent with other error messaging in the app.

### Related stories

- `issues/userstories/2026-05-12-fly-button.md` (open, not yet planned) — adds a "Fly
  XCSoar" button that launches the active XCSoar flavor from the Competition Detail
  screen. Previously noted as a natural companion this story might need to sequence
  after. Per the Question 2 answer, that is no longer the case: this story's suggestion
  trigger is a plain check for today-dated `.igc` files and has no dependency on how or
  whether XCSoar was launched, so the two stories can be planned and delivered
  independently. They still share the same screen (Competition Detail), so the Planner
  should just be mindful of not conflicting UI placement if both land close together.
- `issues/userstories/2026-07-25-hide-download-panels-before-class-selection.md` and
  `issues/userstories/2026-07-25-discoverable-download-filenames.md` — touch the same
  Competition Detail screen and, unlike in the earlier draft of this proposal, now do
  share a functional convention with this story: the Flight Logs panel reuses the same
  card styling as the Airspace/Waypoints cards (see Relevant mockups) and, per the
  zero-logs state above, follows the same "muted text instead of hiding" convention those
  cards use for their own no-data case. The hide-until-class-selected behavior from the
  first story is unrelated (a prerequisite gate, not a data-availability empty state) and
  is not something this story's panel needs to replicate. The Planner should just be
  mindful of not conflicting UI placement if these land close together.

### Relevant mockups

None — no `docs/design/` directory covers a flight-log list or a send/email screen, so
the Planner will need new visual design for the Flight Log screen itself. The Flight
Logs panel on the Competition Detail screen, however, should reuse the existing
download-card styling already established for the Airspace/Waypoints cards (`Card` on
`surface-container-lowest` with a 1dp `outline-variant` border and `shadow-sm`, per
`docs/design/design.md` and `docs/features/competitions.md`) rather than introducing a
new visual pattern — the content is simpler than the full `TwoToneCard` header/footer
layout (just a one-line summary plus an inline action), but the surface/elevation/border
treatment should match.

### Scope estimate

Medium — reassessed down from the original Large now that Question 3 rules out any
in-app email sending: there's no SMTP integration, no send success/failure/retry state
machine, and no server-side email concern to build, since Compman only launches a
standard share/send intent and the mail app owns the rest. Replacing the dismissible
banner + separate manual-fallback entry point with a single always-visible panel (reusing
the existing download-card styling, per Relevant mockups) trims a small amount of scope
too — no dismiss/re-offer state machine and no second entry point to build — though this
doesn't change the overall estimate. What remains is still real work spanning multiple
screens/flows — a new Flight Log screen with no existing mockup, a first-time
prompt-and-remember flow for the per-competition scoring email address, and new logic to
list today's `.igc` files out of the XCSoar directory — so this
likely still needs to be broken into 2-4 issues, but no further product breakdown is
needed before planning.

## Questions

1. [x] How is a competition's scoring email address configured? Is it entered manually
   by the pilot (and if so, on which screen, and when are they prompted — at bookmark
   time, at first-flight time, or on demand the first time they try to send a log), or
   is it discovered automatically (e.g. scraped from the competition's SoaringSpot page,
   if organizers publish it there)?

   > Scoring email is entered manually by the pilot. We can ask for it the first time
   > user decides to send logs and remember it for subsequent use. We should allow to
   > change it once it was provided.

2. [x] What should actually trigger the "send today's flight log" suggestion? Should it
   depend on the pilot having launched XCSoar via Compman's own "Fly XCSoar" button (see
   the related fly-button story), so Compman has a reliable signal that a flight likely
   happened — or should it simply check for today-dated `.igc` files whenever the
   Competition Detail screen is opened or resumes, regardless of how XCSoar was
   launched? The latter works even for pilots who launch XCSoar from the home screen
   directly, but can't distinguish "just landed" from "opened the app hours later."

   > It should just check for today .igc files and offer to send them if at least one is
   > found. This way user will not have to rerun xcsoar if they want to resend files.

3. [x] Does Compman send the email itself in-app (owning success/failure/retry
   end-to-end, e.g. via SMTP with credentials configured somewhere), or does it hand off
   to the device's own mail app (e.g. an Android share/send intent) pre-filled with
   recipient, subject, and the selected `.igc` files as attachments, leaving the actual
   send action to the user in their mail app? This changes what "failure" and "retry"
   mean for this feature and significantly affects scope.

   > I would prefer to hand off this task to the mail app if possible. I would really
   > like to avoid the app dealing with SMTP.

4. [x] Should Compman remember which flights were already sent (so a later visit
   pre-deselects or marks them as "already sent"), or does every visit to the Flight Log
   screen start with all of today's flights selected fresh, leaving it to the pilot to
   avoid duplicate sends?

   > No, no need to remember, we should let user to resend them again (sometimes
   > organizers miss the files and ask to resend them).

5. [x] Is any specific email subject/body content expected by organizers (e.g. pilot
   name, competition class, glider registration), or is a generic subject/body
   acceptable for a first version? Note the app currently has no concept of a pilot
   profile/name to draw from.

   > Subject is typically not important. Pilot is identified by organizers by attachment
   > filenames (the `XCS-WUX` part). We can put filenames as subject, or leave it for
   > user to fill in in the mail app - whatever is easier to implement.

6. [x] When the pilot edits the recipient email field on the Flight Log screen after a
   scoring address has already been remembered for this competition (e.g. to send to a
   different organizer contact just once), should that edit also update the remembered
   address for future visits, or only apply to that one send, leaving the originally
   remembered address in place next time?

   > Yes, let's remember the email for next time. I think the more common use case would
   > be "I made a mistake and have sent logs to wrong address, let's fix it". I don't
   > expect "send to different contact just once" use case to be significant enough.

