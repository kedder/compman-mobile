# Flight Log screen: review, select, and send today's `.igc` flight logs

Derived from `issues/userstories/2026-07-25-email-flight-log-after-flight.md` ("Suggest
Emailing Today's Flight Logs to Organizers After Flying"). Read that file in full — it has
already been through Product Owner refinement, including six resolved open questions and a
detailed UX proposal (the "Flight Log screen" bullet under "Concrete UX proposal" is the
primary spec for this issue). **One correction:** ignore the "review/resend an older log"
sentence in the "Zero-logs state" paragraph — it is stale. This screen only ever lists
**today's** `.igc` files; it is never reachable when there are zero of them (confirmed with
the user during planning — see `20260727-03-flight-logs-panel.md` for how the entry point
works).

This is issue 2 of 3 in this batch. **This issue depends on
`20260727-01-flight-log-domain-and-saf-read.md`** — read that issue and the code it
produced (`FlightLogFile`, `todaysFlightLogsProvider`,
`SetCompetitionScoringEmail`/`setCompetitionScoringEmailProvider`,
`XcsoarSafService.listFlightLogs`) before starting. Do not start this issue until issue 1 is
merged/complete.

## Feature summary

See `20260727-01-flight-log-domain-and-saf-read.md`'s "Feature summary" for the full
3-issue batch context.

## Scope

This issue builds a new, self-contained screen: list today's `.igc` files with checkboxes, a
recipient email field, and a Send button that hands off to the device's mail app via a
share/send intent. It is reachable directly at its route for testing purposes in this issue;
wiring the actual navigation entry point from Competition Detail is
`20260727-03-flight-logs-panel.md`'s job, not this one's.

### 1. Route

Register a new route in `lib/app.dart`: `GoRoute(path: '/competitions/:id/flight-logs',
builder: (context, state) => FlightLogScreen(competitionId: state.pathParameters['id']!))`,
following the existing pattern for `/competitions/:id`.

### 2. `FlightLogScreen`

New file: `lib/features/competitions/presentation/screens/flight_log_screen.dart`.

`ConsumerStatefulWidget` taking a required `competitionId`. Reads:

- `competitionDetailProvider(competitionId)` — for the currently-stored
  `BookmarkedCompetition.scoringEmail` (to pre-fill the email field).
- `todaysFlightLogsProvider` (from issue 1) — for the list of today's `FlightLogFile`s.

**AppBar:** static title, e.g. `"Flight Logs"` (match the static-title convention used by
`CompetitionDetailScreen`'s `"Competition Details"` AppBar — no dynamic content in the
title).

**Empty state** (zero files in `todaysFlightLogsProvider`): per the story, this is a
defensive fallback only (the panel never links here with zero files, but a race is possible
— e.g. the last log is deleted while the screen is open). Show a single centered sentence,
`"No flight logs found for today."`, no CTA — no list, no email field, no Send button.
Mirror the plain, no-CTA empty-state style already used elsewhere in the app (see
`docs/ui-guidelines.md`'s empty-state guidance).

**Loading/error states** for `todaysFlightLogsProvider`: mirror the `_ErrorRetry` pattern
already used throughout `competition_detail_screen.dart` (message + retry button that
invalidates the provider).

**Non-empty state:**

- A scrollable list of `CheckboxListTile` rows, one per `FlightLogFile`, in the order
  returned by `todaysFlightLogsProvider` (already sorted by filename). `title` is the raw
  `filename` as-is (e.g. `2018-02-26-XCS-WUX-01.igc`) — **do not** parse or reformat it.
  **All rows start checked** on every visit (initialize local selection state to "all
  filenames selected" the first time the data loads — follow the same
  `bool _initialized` guard pattern `CompetitionListScreen` uses in
  `lib/features/competitions/presentation/screens/competition_list_screen.dart` to seed
  local state exactly once from async provider data).
- Below the list, a recipient email `TextFormField`: initial value is
  `competition.scoringEmail ?? ''` (seeded once, same guard pattern as the checkbox
  selection). Required; validate as non-empty and matching a basic email shape (a simple
  regex is sufficient — no need for full RFC 5322 validation).
- A full-width `ElevatedButton` labelled `"Send"`, styled with `AppButtonStyles.primary`
  (see `lib/core/theme/app_theme.dart` for the existing style helpers used elsewhere on
  Competition Detail). **Disabled** when zero checkboxes are selected, or the email field is
  empty/invalid.
- Below the Send button: a local, non-dismissible inline error message (plain `Text` styled
  with `colorScheme.error`, no banner/snackbar/retry loop — per the story, Compman's job
  ends once the intent is launched, so there is no send success/failure/retry state machine
  to build beyond this one failure case) shown only when the most recent Send attempt failed
  because no mail app is available. Clear it whenever the user changes the selection or the
  email field, or retries Send.

### 3. `SendFlightLogs` use case

New domain use case,
`lib/features/competitions/domain/usecases/send_flight_logs.dart`, mirroring the shape of
`DownloadAndInstallFile`
(`lib/features/competitions/domain/usecases/download_and_install_file.dart` — read it first,
this follows the same "call a platform action, then persist via the repository" pattern):

```dart
class SendFlightLogs {
  const SendFlightLogs(this._repo, this._safService);

  final CompetitionsRepository _repo;
  final XcsoarSafService _safService;

  /// Launches the device's share/send intent with [files] attached, addressed
  /// to [recipient]. On success (the intent was launched without error — this
  /// says nothing about whether the pilot actually completes the send inside
  /// their mail app, which Compman has no visibility into), remembers
  /// [recipient] as the competition's scoring email for next time.
  ///
  /// [PlatformException] from [XcsoarSafService.shareFlightLogs] (e.g. code
  /// `NO_MAIL_APP`) is not caught — it propagates to the caller *before* the
  /// email is persisted, matching [DownloadAndInstallFile]'s contract.
  Future<Either<Failure, Unit>> call({
    required String competitionId,
    required List<FlightLogFile> files,
    required String recipient,
  }) async {
    await _safService.shareFlightLogs(
      uris: files.map((f) => f.uri).toList(),
      recipient: recipient,
    );
    return _repo.setCompetitionScoringEmail(competitionId, recipient);
  }
}
```

Subject: per the story's Question 5 answer, leave the subject blank (do not pass a
`subject` argument/parameter at all — the simplest option the PO explicitly signed off on).
Do not build filename-derived subject logic; it is unnecessary scope.

Wire `sendFlightLogsProvider` in `lib/core/di/providers.dart`, mirroring
`downloadAndInstallFileProvider`'s construction (`SendFlightLogs(ref.read(competitionsRepositoryProvider),
ref.read(xcsoarSafServiceProvider))`).

### 4. Android bridge: `shareFlightLogs`

Add a new method to the `xcsoar.saf` channel handler in `MainActivity.kt`: `shareFlightLogs`,
taking arguments `uris: List<String>` and `recipient: String`.

Requirements (Kotlin implementation details are your judgment call, but the intent must
satisfy these):

- Build an `Intent(Intent.ACTION_SEND_MULTIPLE)` with `type = "message/rfc822"` (biases the
  system chooser toward mail apps) and `putExtra(Intent.EXTRA_EMAIL, arrayOf(recipient))`.
- Attach the parsed `uris` (each already a full `content://...` document URI string produced
  by issue 1's `listFlightLogs`) as `EXTRA_STREAM` — since there can be more than one
  attachment from potentially the same SAF provider, also set `intent.clipData` listing every
  URI and add `Intent.FLAG_GRANT_READ_URI_PERMISSION`, so the receiving mail app gets a
  temporary read grant for each attachment regardless of whether it holds SAF access itself.
- Wrap with `Intent.createChooser(intent, "Send flight logs")` and `startActivity(...)`.
- No `<queries>` manifest changes are needed: implicit intents started via `startActivity()`
  resolve regardless of package-visibility filtering — only `PackageManager` *query* methods
  are restricted by `<queries>`. (Confirmed against Android's package-visibility docs during
  planning.)
- Catch `android.content.ActivityNotFoundException` and call
  `result.error("NO_MAIL_APP", "No email app available", null)` — mirror exactly how the
  existing `launchPackage` handler in the same file catches
  `ActivityNotFoundException` for `LAUNCH_FAILED`.
- On success, `result.success(null)`.

### 5. `XcsoarSafService.shareFlightLogs`

In `lib/core/platform/xcsoar_saf_service.dart`:

```dart
/// Launches the device's share/send intent (typically resolving to the
/// user's mail app) with [uris] attached and addressed to [recipient].
///
/// Throws [PlatformException] with code `NO_MAIL_APP` if no app can handle
/// the intent.
Future<void> shareFlightLogs({
  required List<String> uris,
  required String recipient,
}) => _channel.invokeMethod<void>('shareFlightLogs', {
  'uris': uris,
  'recipient': recipient,
});
```

### 6. Wiring it together on `FlightLogScreen`

On Send: read the currently-checked `FlightLogFile`s and the (possibly edited) email field
value, call `ref.read(sendFlightLogsProvider)(competitionId: ..., files: ..., recipient:
...)`.

- `Right(unit)` → the intent was launched and the email was persisted. Invalidate
  `bookmarkedCompetitionsProvider` and `competitionDetailProvider(competitionId)` (mirrors
  the invalidation pattern after every other successful write on Competition Detail) so a
  future visit pre-fills the newly-remembered address. No navigation/pop and no
  snackbar/confirmation — the story is explicit that Compman's job ends once the intent is
  launched.
- `Left(Failure)` from the repository step (i.e. the intent launched fine, but persisting the
  email failed — e.g. `StorageFailure`) — show the same local inline error text area used for
  `NO_MAIL_APP`, with the failure's message.
- `PlatformException(code: 'NO_MAIL_APP')` thrown before the repository step runs — show the
  inline error `"No email app available to send flight logs."` and leave the stored scoring
  email untouched (it was never reached).

## Documentation

Per `AGENTS.md`'s documentation-maintenance table:

- `docs/features/competitions.md` — add a new "Flight Log Screen (`/competitions/:id/flight-logs`)"
  subsection under "Screens", following the existing per-screen documentation style (see how
  "XCSoar Directory Settings Screen" is documented as a short pointer, or write it inline —
  your judgment based on how much detail fits).
- `docs/features/xcsoar.md` — add `shareFlightLogs` to the "Android Bridge Methods" table and
  the "Dart Service" table.
- `docs/plan.md` — add an entry noting the Flight Log screen is done.
- Do **not** add a `CHANGELOG.md` entry in this issue — the screen is not yet reachable by
  users (no navigation entry point exists until `20260727-03-flight-logs-panel.md` adds the
  panel). That issue adds the changelog entry once the full flow is user-reachable.

## Testing

- `SendFlightLogs`: new unit test file mirroring
  `test/features/competitions/domain/download_and_install_file_test.dart` — use a
  mocked/faked `CompetitionsRepository` and a mocked/faked `XcsoarSafService`. Cover: success
  path calls both in order and returns `Right(unit)`; a `PlatformException` from
  `shareFlightLogs` propagates and `setCompetitionScoringEmail` is **not** called
  (`verifyNever`/no interaction); a `Left(Failure)` from `setCompetitionScoringEmail`
  propagates.
- `FlightLogScreen` widget tests, new file under
  `test/features/competitions/presentation/screens/flight_log_screen_test.dart`, mirroring
  the provider-override conventions in
  `test/features/competitions/presentation/screens/competition_detail_screen_test.dart`
  (including its `_FakeStringBox` pattern if you need `settingsBoxProvider`). Cover at least:
  - All today's files render, pre-checked.
  - Unchecking all files disables Send.
  - Empty/invalid email disables Send; a valid pre-filled email (from
    `competition.scoringEmail`) enables it once at least one file is checked.
  - Successful send invalidates `competitionDetailProvider` (verify indirectly, e.g. that a
    re-fetch reflects the new email) — or verify at the use-case-call level via a provider
    override that records invocations.
  - `NO_MAIL_APP` failure shows the inline error text and does not crash.
  - Zero-files state shows the empty-state sentence and no list/email field/Send button.

## Acceptance criteria

- `make format` reports no changes.
- `make test` passes, including all new/updated unit and widget tests.
- `make analyze` is clean.
- New route reachable at `/competitions/:id/flight-logs` and manually verified to render all
  states described above.
- `docs/features/competitions.md`, `docs/features/xcsoar.md`, and `docs/plan.md` updated as
  described above. No `CHANGELOG.md` entry in this issue.
