# Auto-Navigate to Last Viewed Competition on App Open

Let's remember the last competition the user viewed and when app opens, navigate to it
automatically. User typically participates in one competition at a time and picking the
same competition from a list is redundant friction. This is a quality-of-life
improvement to save a tap on every app open.

## Product Owner Notes

### Problem and user goal

Every time the user opens Compman they land on the "Your Competitions" home screen and
must tap their competition card before they can check tasks, airspace, or waypoints. For
a pilot who has been attending the same competition all week, this extra tap adds up —
and in a pre-flight or briefing-room context, speed matters. The user wants the app to
"remember where they were" and open there directly.

### What the feature must do

**Persist the last-viewed competition.** Whenever the user opens a Competition Detail
screen (`/competitions/:id`), the app records that competition's ID as the "last viewed"
value. This value is stored locally and survives app restarts.

**Auto-navigate on cold start.** When the app launches:
1. Read the persisted last-viewed competition ID.
2. If a competition ID is stored and that competition is still in the user's bookmarks,
   skip the home screen and navigate directly to `/competitions/:id`.
3. If no ID is stored, the ID no longer corresponds to a bookmarked competition (it was
   removed), or any error occurs reading the value, fall through to the normal home
   screen. The fallback must be silent — no error message or toast.

**Home screen is always reachable.** The user can still return to the full bookmark list
via the AppBar back button on the Competition Detail screen, and can navigate away to add
other competitions as normal. No navigation path is blocked.

**No explicit opt-in or opt-out.** Auto-navigation is always on. There is no setting to
disable it. The behavior is implicit and unobtrusive — if it gets in the way the user
taps Back.

### Affected screens and flows

- **App startup / routing** — the initial route decision must happen before the first
  frame is shown to avoid a visible flash of the home screen followed by a push to the
  detail screen. The redirect must be handled at the router level (e.g. a GoRouter
  redirect or an initial-location resolution) so no intermediate screen is rendered.
- **Competition Detail Screen (`/competitions/:id`)** — must trigger "record as last
  viewed" whenever it is built/entered, without user interaction.
- **Home Screen (`/`)** — no visible change; it simply may be bypassed on launch.
- **Remove competition flow** — when the user removes a bookmarked competition that is
  currently the stored last-viewed ID, that stored ID becomes stale. The fallback logic
  (point 3 above) already handles this correctly: the next cold start finds no matching
  bookmark and shows the home screen.

### Concrete UX approach

Implement as a GoRouter redirect evaluated once at app startup. Before the router
resolves the initial route, read the stored last-viewed ID from Hive (the same local
storage already used for bookmarks). If a valid bookmark is found, set the initial
location to `/competitions/<id>` directly. Because this happens synchronously before
navigation is committed, there is no visible home-screen flash.

Recording the last-viewed competition is a single write to Hive when the Competition
Detail screen is entered (e.g. in `initState` or the provider's `build` method). The
write is fire-and-forget — do not show any UI feedback.

Use the existing Hive box infrastructure. A single string key (e.g. `"lastViewedId"`)
in the bookmarks box, or a separate single-entry box, is sufficient. No new dependency
is required.

### Edge cases

- **Only one bookmark:** auto-navigate always goes to it. This is the primary use case.
- **Multiple bookmarks, one recently viewed:** auto-navigate to the last viewed one.
  The user can go back to pick a different one.
- **Bookmark removed while app is closed:** the stale ID is found but no matching
  bookmark exists — fall through to home screen silently.
- **No bookmarks at all:** stored ID will never exist; home screen shows the empty state
  as today.
- **First launch (no stored ID):** no change from current behavior.

### Related stories

- `2025-05-02-flight-comp-selection.md` (XCSoar flavor picker) — independent, no
  conflict. Both reduce launch friction but via different mechanisms. No merge needed.

### Relevant mockups

None in `docs/design/` cover the startup routing path. Existing Competition Detail and
Home screen mockups are unchanged by this feature.

### Scope estimate

Small — this is a single, focused behavioral change: one write (record last-viewed ID)
and one read (resolve initial route). All storage, navigation, and screen infrastructure
already exists. Fits comfortably in a single issue.
