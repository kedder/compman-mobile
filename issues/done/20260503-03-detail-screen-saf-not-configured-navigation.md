# Competition Detail: Auto-Navigate to Flavor Picker on SAF_NOT_CONFIGURED with Pending-Download Context

## Feature summary

When a user taps any download button (task, airspace, or waypoints) on the Competition
Detail screen and no SAF directory is configured, the app currently appends a dismissible
error banner that says "XCSoar directory not configured — set it in Settings". That
message is easy to miss and gives no actionable path forward.

This issue changes the `SAF_NOT_CONFIGURED` path to navigate the user directly to the
XCSoar Folder screen (the flavor picker built in issues 01 and 02), carrying enough
context to auto-resume the pending download on return. After a successful configuration
the download starts automatically; after an aborted or failed setup the original error
banner is restored.

## Scope

This issue covers:

1. A `PendingDownload` value type for carrying download context through navigation.
2. Encoding `PendingDownload` as a query parameter when navigating to
   `/settings/xcsoar-directory`.
3. Decoding `PendingDownload` from the route and triggering the download
   automatically when `CompetitionDetailScreen` regains focus after a successful
   configuration.
4. Restoring the error banner when the user aborts setup (navigates back without
   completing configuration).
5. Widget tests for both the success and abort flows.

## Prerequisite

Issues `20260503-01` and `20260503-02` must be merged first. This issue modifies
`CompetitionDetailScreen` and the `GoRouter` configuration, and depends on the
`fromDownloadFlow` AppBar title variant added in issue 01.

## What to build

### 1. PendingDownload value type

Create `lib/features/competitions/domain/entities/pending_download.dart`:

```dart
/// Identifies a download that should be auto-started after SAF directory setup.
///
/// Serialised to/from URL query parameters so it can be passed through GoRouter.
class PendingDownload {
  /// Creates a [PendingDownload].
  const PendingDownload({
    required this.competitionId,
    required this.kind,
  });

  /// The SoaringSpot slug of the competition.
  final String competitionId;

  /// The type of file to download: `"task"`, `"airspace"`, or `"waypoints"`.
  final String kind;

  /// Serialises this instance to a URL query-parameter string.
  ///
  /// Format: `competitionId=<id>&kind=<kind>`.
  String toQueryString() =>
      'competitionId=${Uri.encodeComponent(competitionId)}&kind=${Uri.encodeComponent(kind)}';

  /// Parses a [PendingDownload] from [params], or returns `null` if the
  /// required keys are absent.
  static PendingDownload? fromQueryParameters(Map<String, String> params) {
    final id   = params['competitionId'];
    final kind = params['kind'];
    if (id == null || kind == null) return null;
    return PendingDownload(competitionId: id, kind: kind);
  }
}
```

`kind` uses the string constants `"task"`, `"airspace"`, `"waypoints"` — no enum is
needed; the strings map directly to the three download types.

### 2. Update the GoRouter route for `/settings/xcsoar-directory`

In `app.dart`, update the route builder:

```dart
GoRoute(
  path: '/settings/xcsoar-directory',
  builder: (context, state) {
    final params = state.uri.queryParameters;
    final fromDownloadFlow = params['from'] == 'download';
    return XcsoarDirectorySettingsScreen(
      fromDownloadFlow: fromDownloadFlow,
    );
  },
),
```

The `PendingDownload` data is carried in the URL query parameters; the settings screen
itself does not need to know about it.

### 3. Navigate on SAF_NOT_CONFIGURED instead of showing a banner

In `competition_detail_screen.dart`, replace the `SAF_NOT_CONFIGURED` error handling in
**all three download paths** (`_TaskSectionState._installTask`,
`_FileDownloadCardState._download` for airspace, and
`_FileDownloadCardState._download` for waypoints):

**Before** (current code):
```dart
if (e.code == 'SAF_NOT_CONFIGURED') {
  widget.onDownloadError(
    'XCSoar directory not configured — set it in Settings',
  );
}
```

**After:**
```dart
if (e.code == 'SAF_NOT_CONFIGURED') {
  final pending = PendingDownload(
    competitionId: widget.competitionId,
    kind: _downloadKind, // "task", "airspace", or "waypoints"
  );
  final uri = '/settings/xcsoar-directory'
      '?from=download&${pending.toQueryString()}';
  if (context.mounted) context.push(uri);
}
```

Each of the three download paths already knows which kind it is:
- `_TaskSectionState` → `kind = "task"`
- `_AirspaceCard` / `_FileDownloadCard` with airspace → `kind = "airspace"`
- `_WaypointsCard` / `_FileDownloadCard` with waypoints → `kind = "waypoints"`

Because `_FileDownloadCard` is shared, pass `downloadKind` as a new required `String`
constructor parameter and thread it from `_AirspaceCard` and `_WaypointsCard`:

```dart
// In _AirspaceCard.build:
_FileDownloadCard(
  ...
  downloadKind: 'airspace',
)

// In _WaypointsCard.build:
_FileDownloadCard(
  ...
  downloadKind: 'waypoints',
)
```

The `_TaskSectionState` is a separate widget; add a direct `context.push` call there.

### 4. Auto-resume download on return

Convert `CompetitionDetailScreen` (or its stateful inner body `_CompetitionDetailBody`)
to read the `PendingDownload` from the current route when the screen regains focus and
the SAF directory is now configured.

The flow is:

1. When `CompetitionDetailScreen` builds (on initial load and on return from the settings
   screen), check `xcsoarDirectoryUriProvider`. If non-null and non-empty, a directory
   has been configured.
2. Read the `PendingDownload` from the navigation entry's query parameters. GoRouter
   exposes the current URI via `GoRouterState.of(context).uri`; read the query params
   from there in a `RouteAware` listener or — simpler — in a `didChangeDependencies`
   override on `_CompetitionDetailBodyState`.
3. If both conditions hold (directory configured, pending download present), consume the
   pending download once (clear it so the trigger does not fire again), then dispatch the
   appropriate download action:

   - `"task"` → call `_TaskSectionState._installTask` indirectly via a callback or by
     exposing a `GlobalKey<_TaskSectionState>` and calling the method on it. The simplest
     approach: add a `VoidCallback? onAutoStartTask` parameter to `_TaskSection` and call
     it from `_CompetitionDetailBodyState.didChangeDependencies` when triggered.
   - `"airspace"` / `"waypoints"` → expose `autoStart` bool parameters on `_AirspaceCard`
     and `_WaypointsCard`; when `true` and the widget builds for the first time, kick off
     `_download()` in `initState`.

4. If the directory is **not** yet configured after returning (user aborted setup),
   restore the error banner by calling `_appendDownloadError` with the message:
   `"XCSoar folder setup was cancelled. Tap here or go to Settings to try again."`

   The existing `_downloadErrors` list and `_ErrorBanner` widget handle rendering.

#### Detecting "returned from settings, directory still not configured"

Use a `ref.listen` on `xcsoarDirectoryUriProvider` inside `_CompetitionDetailBodyState`:

```dart
ref.listen<AsyncValue<String?>>(xcsoarDirectoryUriProvider, (previous, next) {
  next.whenData((uri) {
    if (uri == null || uri.isEmpty) {
      // User returned without configuring — if we had navigated away, restore banner.
      if (_navigatedToSettings) {
        _appendDownloadError(
          'XCSoar folder setup was cancelled. Go to Settings → XCSoar Folder to try again.',
        );
        _navigatedToSettings = false;
      }
    }
  });
});
```

Add `bool _navigatedToSettings = false;` to the state. Set it to `true` immediately
before `context.push('/settings/xcsoar-directory...')`.

When `xcsoarDirectoryUriProvider` emits a non-null, non-empty URI and `_navigatedToSettings`
is true: that is the "success" path — start the pending download and set
`_navigatedToSettings = false`.

**Note:** `xcsoarDirectoryUriProvider` is `autoDispose`. Invalidate it from the settings
screen when a new URI is stored (already done in issue 01 — `ref.invalidate(xcsoarDirectoryUriProvider)`
on successful picker return). The `ref.listen` in the detail screen will receive the
updated value when the provider is rebuilt after navigating back.

### 5. Widget tests

Add tests to
`test/features/competitions/presentation/screens/competition_detail_screen_test.dart`
(extend the existing test file):

- **Test: SAF_NOT_CONFIGURED on task download navigates to settings.**
  Mock `XcsoarSafService.writeFile` to throw
  `PlatformException(code: 'SAF_NOT_CONFIGURED')`. Tap the "Download task" button.
  Assert that `GoRouter` navigated to `/settings/xcsoar-directory?from=download&competitionId=...&kind=task`.
  Assert that no error banner is shown (the old inline error message must not appear).

- **Test: SAF_NOT_CONFIGURED on airspace download navigates to settings with correct kind.**
  Same as above for the "Download" button on the airspace card. Assert `kind=airspace`.

- **Test: SAF_NOT_CONFIGURED on waypoints download navigates to settings with correct kind.**
  Assert `kind=waypoints`.

- **Test: Auto-resume on return after successful configuration.**
  Use a `MockGoRouter` / `NavigatorObserver` approach or a widget test with a real
  `GoRouter`. Simulate: (1) tap airspace download → SAF_NOT_CONFIGURED → navigate to
  settings. (2) Simulate configuring the directory (update the mock for
  `xcsoarDirectoryUriProvider` to return a non-null URI). (3) Navigate back. Assert that
  `downloadAndInstallFileProvider` was called without a second tap.

- **Test: Abort path restores error banner.**
  Simulate navigating to settings and back without configuring. Assert that the error
  banner "XCSoar folder setup was cancelled" appears.

### 6. Documentation updates

- **`docs/features/competitions.md`** — update the Competition Detail Screen section:
  - Replace the `SAF_NOT_CONFIGURED` bullet with the new navigation behavior.
  - Add a "Pending-download auto-resume" paragraph describing `PendingDownload` and the
    `ref.listen` pattern.
- **`docs/plan.md`** — add a 📋 item for the contextual SAF navigation under Phase 4,
  or mark it as part of the flavor-picker feature.

## Acceptance criteria

- [ ] Tapping any download button when SAF is not configured navigates to
  `/settings/xcsoar-directory?from=download&competitionId=<id>&kind=<kind>`.
- [ ] The settings screen AppBar title is "Set Up XCSoar Folder" when reached this way.
- [ ] No error banner is shown at the moment of `SAF_NOT_CONFIGURED` — navigation
  replaces it.
- [ ] After successfully configuring the directory and returning, the pending download
  starts automatically without the user tapping again.
- [ ] After aborting setup (returning without configuring), the error banner
  "XCSoar folder setup was cancelled" is visible.
- [ ] There is no silent failure path: after navigation back, either the download starts
  or the error banner is visible.
- [ ] `flutter analyze` reports no issues.
- [ ] `flutter test` passes including all five new tests.

## Constraints

- `PendingDownload` must live in the domain layer (`domain/entities/`). It must not
  import from `presentation` or `data`.
- Do not store `PendingDownload` in Hive or any persistent storage — it lives only in
  the navigation URI for the duration of one navigation transaction.
- The auto-resume trigger must fire at most once per navigation return (guard with a
  consumed flag). Do not auto-start the download on every provider rebuild.
- Use `context.push` (go_router) not `Navigator.push`. The back button from the settings
  screen must return to Competition Detail, not to the home screen.
- Add `///` doc comments to `PendingDownload`.

## Reference

User story: `2025-05-02-flight-comp-selection.md`
