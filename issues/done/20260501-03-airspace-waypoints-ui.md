# Airspace & Waypoints — Competition Detail UI

User story: `2026-05-01-waypoints-airspaces.md`

## Feature summary

The Competition Detail screen gains two new download cards — one for airspace
and one for waypoints — matching the visual design in
`docs/design/competition_details_full_download_suite/`. Each card shows the
filename, file size, last-published timestamp, a "NEW UPDATE" badge when a
newer version is available, and a "Download" button. The cards appear below
the task card and respect the existing layout (scroll view, error banners,
XCSoar directory footer).

## Scope

This issue covers only the **presentation layer**. Domain and data work must
be done first via:

- `20260501-01-airspace-waypoints-domain-data.md` — entities, scraper,
  repository methods, use cases, install-timestamp Hive fields.
- `20260501-02-airspace-waypoints-saf-write.md` — `DownloadAndInstallFile`
  use case and DI provider.

**Depends on both of the above being merged.**

---

## Reference design

Authoritative visual spec: `docs/design/competition_details_full_download_suite/`
(view `screen.png` and `code.html`).

Key visual details from the mockup:
- Each card uses the existing `TwoToneCard` shell (white header, tinted footer).
- **Card header:** Section title ("Airspace" / "Waypoints"), optional "NEW
  UPDATE" badge (red, `AppBadge`), filename in bold with file size in
  muted text on the same line, and an appropriate icon (globe for airspace,
  location pin for waypoints).
- **Card footer:** History icon + last-published timestamp on the left; ghost
  "Download" button on the right. While downloading, the button shows a
  `CircularProgressIndicator` and is disabled (same pattern as the task card).
  After a successful install the button reflects the installed state.
- **No file available:** When SoaringSpot returns no airspace or no waypoints
  file, the card shows "No airspace file available" / "No waypoint file
  available" in subdued text with no download button.
- **"NEW UPDATE" badge:** Shown when `fileInfo.publishedVersion` is not null
  and differs from the stored `airspaceVersion` / `waypointsVersion` string on
  the `BookmarkedCompetition` (string equality, not datetime comparison).
  Hidden otherwise.
- The "Download" button label follows the same pattern as the task button:
  "Download" at rest, "Downloading..." while in progress.

---

## Tasks

### 1. Riverpod provider: `downloadsProvider`

In `lib/features/competitions/presentation/providers/competitions_providers.dart`,
add:

```dart
/// Fetches the list of downloadable airspace and waypoints files for a
/// competition from the SoaringSpot downloads page.
final downloadsProvider = FutureProvider.autoDispose
    .family<List<DownloadableFileInfo>, String>((ref, competitionId) async {
  final useCase = ref.read(fetchDownloadsProvider);
  final result = await useCase(competitionId);
  return result.fold((f) => throw f, (files) => files);
});
```

### 2. Refresh on pull-to-refresh and AppBar refresh

The existing pull-to-refresh in `_CompetitionDetailBodyState` and the AppBar
refresh button currently only invalidate `latestTasksProvider`. Extend both to
also invalidate `downloadsProvider(competitionId)` so that airspace/waypoints
data is refreshed at the same time.

### 3. New widget: `_AirspaceCard` and `_WaypointsCard`

Add these as private widgets in `competition_detail_screen.dart` (or extract
to `lib/features/competitions/presentation/widgets/` if they grow complex).

Each card widget:
- Takes a `BookmarkedCompetition competition` and `String competitionId`.
- Watches `downloadsProvider(competitionId)` and `competitionDetailProvider(competitionId)`.
- On `loading`: shows a `CircularProgressIndicator` inside the card area.
- On `error`: shows an inline error message + Retry button (reusing
  `_ErrorRetry`).
- On `data`:
  - Finds the relevant `DownloadableFileInfo` from the list
    (kind == airspace or waypoints).
  - If not found: shows "No airspace file available" / "No waypoint file
    available" in muted body text (no card shell needed, just a `Text` widget).
  - If found: renders the full `TwoToneCard` layout as described in the design.

**Shared stateful download widget:** Both cards share the same download
interaction pattern. Consider a shared `_FileDownloadCard` stateful widget
parameterised by `DownloadableFileInfo`, `DownloadableFileKind`, and the
install timestamp from `BookmarkedCompetition`:

```dart
class _FileDownloadCard extends ConsumerStatefulWidget {
  const _FileDownloadCard({
    required this.competitionId,
    required this.fileInfo,
    required this.installedVersion,   // String? from BookmarkedCompetition
    required this.onDownloadError,
    required this.sectionTitle,
    required this.sectionIcon,
  });
  // ...
}
```

The download button tap handler:
1. Sets local `_downloading = true`.
2. Calls `DownloadAndInstallFile` via the provider.
3. On success: shows a green SnackBar ("Airspace downloaded" or "Waypoints
   downloaded"); invalidates `bookmarkedCompetitionsProvider` and
   `competitionDetailProvider(competitionId)` so the installed version
   updates and the badge disappears.
4. On `PlatformException` with code `SAF_NOT_CONFIGURED`: appends an error
   banner ("XCSoar directory not configured — set it in Settings") via
   `onDownloadError`.
5. On `Failure`: appends the failure message as an error banner.
6. Sets `_downloading = false` in `finally`.

### 4. Wire cards into `_CompetitionDetailBody`

In `_CompetitionDetailBodyState.build`, after the `_ClassSection` (which
contains the task card), add:

```dart
const SizedBox(height: 12),
_AirspaceCard(
  competitionId: widget.competitionId,
  competition: widget.competition,
  onDownloadError: _appendDownloadError,
),
const SizedBox(height: 12),
_WaypointsCard(
  competitionId: widget.competitionId,
  competition: widget.competition,
  onDownloadError: _appendDownloadError,
),
```

These go inside the `ListView`, before the `Divider` that precedes the
`_XcsoarDirectoryRow`.

### 5. Update `docs/features/competitions.md`

In the **Competition Detail Screen** section, update the description to mention
the two new Airspace and Waypoints cards, the "NEW UPDATE" badge logic, and the
`downloadsProvider`.

---

## Tests

**`test/features/competitions/presentation/screens/competition_detail_screen_test.dart`**

Add the following widget test cases (all using mocked providers, same pattern
as existing tests in that file):

1. **`renders airspace card with filename and Download button`**
   — `downloadsProvider` returns one airspace `DownloadableFileInfo`; widget
   shows the filename and a "Download" button.

2. **`renders waypoints card with filename and Download button`**
   — `downloadsProvider` returns one waypoints `DownloadableFileInfo`; widget
   shows the filename and a "Download" button.

3. **`shows NEW UPDATE badge when publishedVersion differs from installedVersion`**
   — `fileInfo.publishedVersion` is a non-null string that differs from
   `competition.airspaceVersion`; "NEW UPDATE" badge is visible.

4. **`shows NEW UPDATE badge when competition is freshly bookmarked (no file installed yet)`**
   — `competition.airspaceVersion` is `null` and `fileInfo.publishedVersion`
   is a non-null string; "NEW UPDATE" badge is visible. This ensures the badge
   prompts the user to install files they have never downloaded.

5. **`hides NEW UPDATE badge when already up to date`**
   — `fileInfo.publishedVersion` equals `competition.airspaceVersion`;
   no badge visible.

6. **`shows "No airspace file available" when downloads list has no airspace entry`**
   — `downloadsProvider` returns an empty list; airspace section shows the
   "no file" message and no Download button.

7. **`Download button is disabled while downloading`**
   — Tap Download; before the future resolves the button is disabled.

8. **`appends error banner when SAF not configured`**
   — `DownloadAndInstallFile` throws `PlatformException(code: 'SAF_NOT_CONFIGURED')`;
   error banner appears with appropriate text.

Use `ProviderScope` overrides to provide stub values for `downloadsProvider`,
`competitionDetailProvider`, `downloadAndInstallFileProvider`, and
`bookmarkedCompetitionsProvider`.

---

## Acceptance criteria

- `make format` reports no changes.
- `make test` passes.
- `make analyze` reports no issues.
- The Competition Detail screen shows an Airspace card and a Waypoints card
  below the task card.
- Each card renders the filename, file size, published timestamp, and a
  "Download" button.
- "NEW UPDATE" badge appears when `publishedVersion != installedVersion`; absent otherwise.
- "No airspace / waypoint file available" text is shown when no file is listed.
- Download button is disabled during download; shows "Downloading..." label.
- A green SnackBar confirms success; error banners are appended for failures.
- Pull-to-refresh and the AppBar refresh also refresh `downloadsProvider`.
- `docs/features/competitions.md` is updated.
- `docs/plan.md`: mark Phase 2 entry ✅ or update 📋 items appropriately.

## Constraints

- Reuse `TwoToneCard`, `AppBadge`, `IconMetaRow` from `lib/core/widgets/`.
- All colours via `Theme.of(context).colorScheme` or `context.appColors`.
- No `setState` for data loading — use Riverpod providers.
- `_downloading` is local widget state (allowed for transient UI state).
- Follow `AGENTS.md` commit conventions; include the issue filename trailer.
- `docs/ui-guidelines.md` and `docs/design/competition_details_full_download_suite/`
  are the authoritative visual references.
