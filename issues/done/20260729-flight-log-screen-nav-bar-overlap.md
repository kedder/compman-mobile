# Fix: Flight Log screen's Send button hidden behind Android system nav bar

## Feature summary

`FlightLogScreen` (`lib/features/competitions/presentation/screens/flight_log_screen.dart`,
route `/competitions/:id/flight-logs`) lets a pilot pick today's `.igc` flight logs, enter a
recipient email, and tap "Send" to hand off to the device's mail app. See
`docs/features/competitions.md`'s "Flight Log Screen" subsection for the full functional spec.

## Bug report (from real-device testing)

On the Flight Logs screen, the "Send" button is partially hidden behind Android's system
navigation bar — both gesture-nav pill and 3-button nav bar are affected. The button is still
technically tappable in the unobscured portion for gesture nav, but on 3-button nav devices the
lower part of the button (and the inline error text below it, when shown) can be fully covered.

## Root cause

This is a well-known Flutter/Android issue: **edge-to-edge display**. Since the Flutter Android
embedding v2 template used by this project (confirmed in
`android/app/src/main/AndroidManifest.xml` / `android/app/src/main/kotlin/.../MainActivity.kt`
— no manual `WindowCompat.setDecorFitsSystemWindows` opt-out, no `styles.xml` override, and no
explicit edge-to-edge configuration anywhere in the repo), the app draws edge-to-edge by
default. On Android 15+ (targetSdk 35) edge-to-edge is enforced by the OS and can no longer be
opted out of at the manifest/theme level — Flutter apps must explicitly inset their own content
away from `MediaQuery` system padding.

`FlightLogScreen.build` (around line 97-186) puts its entire non-empty-state content — the
scrollable file list, the email field, and the Send button — inside a single
`Padding(padding: const EdgeInsets.all(16))` (line 127-128) directly under `Scaffold.body`.
`Scaffold.body` is **not** automatically wrapped in a `SafeArea` by Flutter; only
`bottomNavigationBar`/`persistentFooterButtons` get automatic bottom insetting. Because the
Send button (`ElevatedButton`, lines 164-171) and the row above it are laid out with a fixed
`EdgeInsets.all(16)` bottom padding — not `MediaQuery.of(context).padding.bottom` /
`viewPadding.bottom` — the button sits only 16 logical pixels above the *drawing surface*
bottom edge, which is behind the system nav bar on edge-to-edge devices.

## Existing convention in this codebase

`CompetitionDetailScreen` (`lib/features/competitions/presentation/screens/competition_detail_screen.dart`,
lines 166-189) already solved exactly this problem for its bottom-pinned download-error banners:
it wraps the `Positioned(bottom: 16, ...)` overlay content in `SafeArea(top: false, child: ...)`.
That's the established pattern in this codebase — prefer it over inventing a new mechanism (e.g.
manually reading `MediaQuery.of(context).padding.bottom`, or global edge-to-edge opt-out via
`AndroidManifest.xml`/theme changes, which would fight Android 15's enforced edge-to-edge and is
not how the rest of the app handles this).

No other screen in `lib/features/**/*_screen.dart` uses `SafeArea`. `BookmarksScreen`'s and
`CompetitionListScreen`'s bottom-of-content `ElevatedButton`s (in their `_ErrorView`/
`_EmptyState` widgets) live inside `Center`/scrollable `ListView` bodies without a fixed
bottom-pinned action bar, so they are lower-risk today, but are not proven safe either — see
"Out of scope" below.

## Scope

Fix `FlightLogScreen` only. Do not touch other screens beyond the follow-up note below.

### Fix

In `lib/features/competitions/presentation/screens/flight_log_screen.dart`, in the `data:`
branch of `logsAsync.when(...)` (starting line 108), wrap the bottom, non-scrolling part of the
`Column` — the recipient email field, the Send button, and the conditional inline error text
(currently lines 151-181, i.e. everything after the `Expanded(child: ListView(...))`) in a
`SafeArea(top: false, child: ...)`, mirroring `CompetitionDetailScreen`'s pattern exactly. Do
**not** wrap the whole `Column`/`Padding` in `SafeArea` — only the bottom-pinned action area
needs it; wrapping the `Expanded` list region too would double-inset it unnecessarily and is not
how the existing `CompetitionDetailScreen` precedent does it either (there it's scoped to just
the bottom-pinned overlay).

Concretely: keep the outer `Padding(padding: const EdgeInsets.all(16))` and
`Column(crossAxisAlignment: ..., children: [...])` structure as-is, but change the trailing
non-`Expanded` children (the `SizedBox(height: 8)`, `TextFormField`, `SizedBox(height: 16)`, the
Send `ElevatedButton`, and the conditional error `Text`) to live inside a single `SafeArea(top:
false, child: Column(...))` nested as the last child of the outer `Column`, so the safe-area
bottom inset is added *after* the existing `EdgeInsets.all(16)` padding (additive, not
replacing it — on non-edge-to-edge/no-inset devices the visual result must be unchanged from
today).

Double check the loading/error/empty-state branches (lines 100-116) don't need the same
treatment — they're centered content with no fixed bottom action bar, so no fix required there.

### Follow-up note (do not implement in this issue)

`BookmarksScreen`'s and `CompetitionListScreen`'s `_ErrorView`/`_EmptyState` bottom buttons, and
the `bottom: 96`/`bottom: 16` `ListView` padding used elsewhere in those two screens, were not
found to reproduce this bug during investigation (their action buttons are inside `Center`/
scrollable regions, not pinned to the screen edge like Flight Log's Send button), but they were
not device-tested as part of this issue. If a future bug report surfaces the same symptom on
those screens, apply the same `SafeArea(top: false, ...)` pattern there.

## Acceptance criteria

- `make format` reports no changes.
- `make test` passes, including the existing `test/features/competitions/presentation/screens/flight_log_screen_test.dart` widget tests (update them only if the `SafeArea` wrap breaks an existing `find`/`pump` assumption — the widget tree structure changes slightly).
- `make analyze` is clean.
- On a device/emulator with edge-to-edge enabled (Android 15+, or gesture nav on earlier
  versions), the Send button and the inline error text (when shown) are fully visible above the
  system navigation bar, with no visible layout regression (extra padding) on devices where the
  system nav bar doesn't overlap content.
- No `docs/features/competitions.md` change needed (this is a layout bugfix, not a functional
  change) — but add a `CHANGELOG.md` entry under `## Unreleased` / `### Fixed`, e.g. "Fix Send
  button being hidden behind the system navigation bar on the Flight Logs screen", per
  `AGENTS.md`'s changelog rules (this is a user-visible bug fix).
