# Feature: Competitions

This document describes what pilots can do on each competition-related screen, and why —
not how the code implements it. It should let a reader reason about what's implemented
and the intent behind it without opening the source. Avoid pasting class definitions,
method signatures, or field lists here: they drift out of date every time a property or
method is renamed. Where the code matters, point at a folder or file loosely (e.g. "the
competitions domain layer") rather than an exact symbol — see "Where to look in the code"
at the end of this document.

For the original UI wireframe intent, see **[overview.md](overview.md)**. For app-wide
loading/error/empty/button conventions, see **[docs/ui-guidelines.md](../ui-guidelines.md)**
— screens below only call these out when they deviate from the norm.

---

## What this feature covers

Competitions is the core of Compman: browsing competitions listed on SoaringSpot,
bookmarking the ones a pilot plans to fly, and preparing a bookmarked competition for a
day of flying — picking a class, keeping the task/airspace/waypoints files current, and
handing off to XCSoar.

---

## Concepts

### Competition

A competition as listed on SoaringSpot: a title, a location/date description, and a link
back to the SoaringSpot page. Competitions are fetched live and are not modified by the
app — they only become interesting to a pilot once bookmarked.

### Bookmark

A competition the pilot has chosen to track. Bookmarking is what turns a read-only
listing into something the app manages state for: the pilot's chosen class, whether the
current task/airspace/waypoints files have been installed to XCSoar (so the app can tell
the pilot when the organizer has published something newer), and — for the flight-log
emailing feature — the scoring email address the pilot last sent flight logs to for this
competition. All of this state is local to the device and is not synced anywhere.

### Status

Every competition (bookmarked or not) has a computed status — Live, Upcoming, or Past —
based on its date range and the current date. Status is never stored; it's recalculated
every time it's shown, so it's always correct even if the app hasn't been opened in days.
See **[docs/ui-guidelines.md](../ui-guidelines.md)** for how status badges are styled.

---

## Screens

### Competition List Screen — `/add`

Purpose: let the pilot search all competitions currently listed on SoaringSpot and choose
which ones to bookmark.

- Competitions can be filtered by a search field as the pilot types.
- Selection is multi-select (checkboxes); nothing is bookmarked until the pilot confirms
  with "Done". Backing out without confirming bookmarks nothing.
- Each row shows the competition's title, status badge, and description so the pilot can
  tell live/upcoming competitions apart while choosing.
- Pull-to-refresh re-fetches the list from SoaringSpot.

### Home Screen — `/`

Purpose: the pilot's single landing point, showing only what they've bookmarked.

- Empty state invites the pilot to add their first competition.
- Otherwise, shows bookmarked competitions as a list with status badges.
- Tapping a competition opens its detail screen; long-pressing offers to remove the
  bookmark, guarded by a confirmation dialog since this is a destructive, unrecoverable
  action (all locally tracked state for that competition — chosen class, install history,
  scoring email — is discarded with it).
- Removing or adding a bookmark is reflected on this screen immediately, with no manual
  refresh needed.
- An "Add" action opens the Competition List Screen above.
- On a cold app start, the pilot is taken directly back into the competition they last
  viewed rather than landing on this list — see "Returning to the last-viewed
  competition" below. The home screen is still the base of the back stack, so backing out
  of that competition always lands here, never exits the app unexpectedly.

### Competition Detail Screen — `/competitions/:id`

Purpose: the hub for one bookmarked competition — pick a class, keep the task and
supporting files current, and get into XCSoar with everything it needs.

The header shows the competition's title and a link back to its SoaringSpot page.
Everything else on the screen builds on the class the pilot has selected.

#### Class selection

Most competitions run several classes in parallel, each flying a different task, so the
app needs to know which one the pilot is in before it can show anything else useful.
Until a class is chosen, the screen shows **only** the header and a class picker — no
task, airspace, or waypoints sections at all. This is deliberate: showing unrelated
download cards alongside the picker let pilots miss the class step entirely, so it's kept
as the sole focus until resolved.

Once a class is picked, it's remembered for this competition and the full screen
(described below) appears. The chosen class is shown as a compact row with a "Change"
action, so it can be corrected later without losing anything else.

#### Task

Once a class is set, the screen shows the current task published for that class and lets
the pilot download and install it to XCSoar in one tap. If the organizer has since
published a newer task than the one installed, a badge flags it — see "Keeping files
current" below.

#### Fly XCSoar

Once the current task is installed, a prominent action lets the pilot launch XCSoar
directly, so they don't have to leave Compman to find it. It intentionally does not
appear at all before that point, and disappears again if a newer task is published and
not yet downloaded — flying is only offered when the pilot is certain to launch the exact
task version they most recently installed, so an out-of-date task is never taken flying
by accident.

If XCSoar's folder hasn't been configured yet, or no known XCSoar variant is installed,
the action is shown but disabled with a short explanation instead of just failing
silently on tap. If launching still fails (e.g. XCSoar was uninstalled mid-session), the
pilot sees a dismissible error message rather than nothing happening.

#### Airspace and waypoint files

The screen also offers one-tap download for the competition's airspace and waypoints
files, using the same "keep it current" pattern as the task (see below), since organizers
can re-publish either mid-competition. Like the task, these are hidden until a class is
selected, for the same reason.

Both files are written to XCSoar under **fixed, on-device names**, regardless of what the
organizer originally called them — so XCSoar only needs to be pointed at each file once,
ever, and every later update silently replaces it rather than requiring the pilot to
reconfigure XCSoar per competition. Because the pilot still has to pick the right file by
hand inside XCSoar's own file browser after downloading, the download confirmation states
that fixed on-device name directly, so the pilot knows exactly what to look for. (The
task file needs no such callout — XCSoar loads it automatically on startup, with no
picking step for the pilot to get wrong.)

If a competition hasn't published one of these files, the screen says so in place of a
download action rather than showing a broken or empty card.

#### Keeping files current — the "new version" indicator

The task, airspace, and waypoints sections each independently track whether what's
installed on the device matches what the organizer currently has published. Whenever a
section's installed version is missing or older than what's currently published, it shows
a "new version" badge — this is the one signal a pilot needs to know whether re-downloading
is worthwhile, without having to reason about dates or version numbers themselves.

#### When XCSoar's folder isn't set up yet

Downloading any of the three files for the first time requires Compman to have been
granted access to XCSoar's data folder. If that hasn't happened yet, the pilot is taken
to XCSoar folder setup (see **[configuration.md](configuration.md)**) instead of seeing a
raw error; if they complete setup, the download they originally asked for resumes
automatically so they don't have to remember to retry it themselves. If they back out of
setup without completing it, they're told plainly that setup was cancelled and how to
retry later from Settings — the download itself is not attempted.

#### XCSoar folder indicator

A subdued line at the bottom of the screen always shows whether an XCSoar folder is
currently configured, regardless of class selection — a pilot may want to check or set
this up before ever picking a class.

#### Refreshing

Pulling to refresh, or using the refresh action in the app bar, re-checks for updated
tasks and downloadable files without navigating away or losing the pilot's place.

### XCSoar Directory Settings Screen — `/settings/xcsoar-directory`

Setting up (or changing) the folder Compman uses to exchange files with XCSoar is a
cross-feature concern, not specific to any one competition — see
**[configuration.md](configuration.md)** for the full description of that screen.

---

## Returning to the last-viewed competition

On a cold app start, the pilot is dropped back into the last competition detail screen
they had open, rather than the home screen — since a pilot re-opening Compman on
competition day is almost always coming back to check on the same competition they were
just looking at. The back button from that screen still returns to the home screen, so
the pilot is never trapped one level in with no way back to their full bookmark list.

If the previously-viewed competition is no longer bookmarked (e.g. it was removed since
the last session), or nothing has been viewed yet, the app simply opens on the home
screen as normal.

---

## Where to look in the code

This feature follows the layering described in
**[docs/architecture.md](../architecture.md)**: domain entities, use cases, and the
repository interface live under `lib/features/competitions/domain/`; SoaringSpot scraping
and local (Hive) persistence live under `lib/features/competitions/data/`; screens and
Riverpod providers live under `lib/features/competitions/presentation/`. For the
SoaringSpot HTML structure being scraped, see
**[docs/api/soaringspot.md](../api/soaringspot.md)**. For XCSoar's SAF bridge, see
**[docs/features/xcsoar.md](xcsoar.md)**.

`docs/plan.md` is the authoritative history of what's been built and when — check there
rather than expecting this document to enumerate every class or provider that exists.
