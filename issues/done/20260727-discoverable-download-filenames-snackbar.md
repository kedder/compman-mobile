# State the fixed on-device filename in the Airspace/Waypoints download confirmation

## Feature summary

After downloading an airspace or waypoints file, Compman shows a green success `SnackBar`
confirming the download. The pilot's next step is to leave Compman, open XCSoar, and pick the
matching file from XCSoar's own file browser — but the current SnackBar text ("Airspace
downloaded" / "Waypoints downloaded") never states the filename to look for. This issue
implements the approved fix from
`issues/userstories/2026-07-25-discoverable-download-filenames.md`: change the two SnackBar
messages to state the fixed on-device filename directly.

## Scope

This issue covers the two airspace/waypoints success SnackBar messages, plus making the domain
use case the single source of truth for the on-device filenames it writes, so the presentation
layer never hard-codes `compman-airspace.txt` / `compman-waypoints.cup` as a separate literal.

Explicitly out of scope (do not touch):
- The "Task downloaded" SnackBar (`lib/features/competitions/presentation/screens/competition_detail_screen.dart`,
  in `_TaskSectionState._installTask`) — the user story marks task download confirmation as
  out of scope because XCSoar loads `Default.tsk` automatically with no file-picking step. Do
  not change `DownloadAndInstallTask` or its return type.
- The source-filename text shown on the Airspace/Waypoints card body (`fileInfo.filename`) —
  this describes the organizer's published file and is unchanged.
- No copy action, no new UI elements.

## Design: use case is the single source of truth for the filename

`DownloadAndInstallFile.call()` already computes `outputName` (`compman-airspace.txt` /
`compman-waypoints.cup`) in a `switch` on `fileInfo.kind` and writes it via
`XcsoarSafService.writeFile`. Instead of duplicating those two filename literals as a second,
separate pair of strings in the presentation layer, the use case now **returns** the filename it
wrote, and the presentation layer builds the SnackBar text from that returned value. This keeps
exactly one place in the codebase (`download_and_install_file.dart`) that knows the fixed
on-device names; the SnackBar text is derived, not duplicated.

## What to build

### 1. `lib/features/competitions/domain/usecases/download_and_install_file.dart`

- Change `call()`'s return type from `Future<Either<Failure, Unit>>` to
  `Future<Either<Failure, String>>`.
- Keep the existing `switch (fileInfo.kind) { ... }` that computes `outputName` exactly as-is —
  it remains the single place deciding the fixed filename per kind.
- On the success path, return `Right(outputName)` instead of `Right(unit)` (i.e. call
  `_repo.recordFileInstall(...)` as today, then `return Right(outputName);`).
- Update the class-level and `call()` doc comments to mention that the returned `String` on
  success is the on-device filename that was written (still `compman-airspace.txt` /
  `compman-waypoints.cup`).
- The failure path (`Left(bytesResult.getLeft().toNullable()!)`) and the uncaught
  `PlatformException` propagation from `writeFile` are unchanged in behavior — only the success
  `Right` value's type changes.

### 2. `lib/features/competitions/presentation/screens/competition_detail_screen.dart`

- `_FileDownloadCard` currently takes a `successMessage: String` field, rendered verbatim in the
  confirmation `SnackBar`. Replace it with a field that lets each card supply only the
  kind-specific wording, while the actual filename comes from the use case's `Right` value at
  download time — the widget itself must stay generic and must not hard-code "Airspace" /
  "Waypoints" wording. The simplest option: rename the field to `successMessagePrefix` (e.g.
  `'Airspace downloaded as '` / `'Waypoints downloaded as '`), then in
  `_FileDownloadCardState._download`, build the SnackBar text as
  `'${widget.successMessagePrefix}$filename'` where `filename` is the `String` from the
  use case's `Right(filename)`. (A callback such as
  `String Function(String filename) buildSuccessMessage` is an acceptable alternative if it
  reads more cleanly once written — use your judgment, but keep `_FileDownloadCard` itself free
  of the words "Airspace"/"Waypoints".)
- `_AirspaceCard.build` (around line 813): change `successMessage: 'Airspace downloaded'` to the
  new field/prefix, e.g. `successMessagePrefix: 'Airspace downloaded as '`.
- `_WaypointsCard.build` (around line 858): change `successMessage: 'Waypoints downloaded'`
  similarly, e.g. `successMessagePrefix: 'Waypoints downloaded as '`.
- `_FileDownloadCardState._download` (around line 910–930) currently does:
  ```dart
  result.fold(
    (f) => ref.read(_downloadErrorsProvider.notifier).add(_failureMessage(f)),
    (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.successMessage),
          backgroundColor: context.appColors.success,
        ),
      );
      ref.invalidate(bookmarkedCompetitionsProvider);
      ref.invalidate(competitionDetailProvider(widget.competitionId));
    },
  );
  ```
  Change the `Right` branch's parameter from `(_)` to the returned filename (e.g. `(filename)`)
  and use it to build the `Text` content as described above. No other logic in `_download`
  changes.
- Result: final SnackBar text is `'Airspace downloaded as compman-airspace.txt'` /
  `'Waypoints downloaded as compman-waypoints.cup'`, but the filename part now flows from the
  use case's return value rather than being re-typed in the presentation layer.

### 3. Provider wiring — check, but no codegen expected

`downloadAndInstallFileProvider` in `lib/core/di/providers.dart` is a plain
`Provider<DownloadAndInstallFile>((ref) => DownloadAndInstallFile(...))` — it is **not**
riverpod-codegen-generated (no `@riverpod` annotation, no `part '....g.dart'` in that file), so
changing `DownloadAndInstallFile.call()`'s return type requires no `build_runner` regeneration
for this provider. Just confirm `lib/core/di/providers.dart` still compiles unchanged (it should
— it only constructs the use case, it doesn't reference the return type).

### 4. `lib/features/competitions/domain/usecases/download_and_install_task.dart`

Do not change this file — it is the separate task-download use case, out of scope per the "Task
downloaded" exclusion above.

## Tests to update

Grep-checked call sites of `DownloadAndInstallFile` outside `lib/`:
`test/features/competitions/domain/download_and_install_file_test.dart` and
`test/features/competitions/presentation/screens/competition_detail_screen_test.dart`. Update
both:

### `test/features/competitions/domain/download_and_install_file_test.dart`

- `'downloads bytes, writes compman-airspace.txt, records install, returns Right(unit)'` test:
  rename the test description to reflect the new return value (e.g. "...returns
  Right('compman-airspace.txt')") and change
  `expect(result, const Right<Failure, Unit>(unit));` to
  `expect(result, const Right<Failure, String>('compman-airspace.txt'));`.
- `'writes compman-waypoints.cup for waypoints file'` test: change
  `expect(result, const Right<Failure, Unit>(unit));` to
  `expect(result, const Right<Failure, String>('compman-waypoints.cup'));`.
- `'returns Left(NetworkFailure) when downloadFile fails'` test: change
  `expect(result, const Left<Failure, Unit>(failure));` to
  `expect(result, const Left<Failure, String>(failure));`.
- The `setUp()`'s `provideDummy<Either<Failure, Unit>>(const Right(unit));` line was providing a
  Mockito dummy value for `recordFileInstall`'s return type (`CompetitionsRepository.recordFileInstall`
  still returns `Either<Failure, Unit>` — that method is unchanged). Re-check whether it's still
  needed for that mock and keep it if so; separately add
  `provideDummy<Either<Failure, String>>(const Right(''));` only if Mockito complains about the
  new `DownloadAndInstallFile.call()` return type being mocked/dummied anywhere in this file (it
  likely isn't, since this test exercises the real use case, not a mock of it — verify by running
  the tests rather than adding dummies speculatively).

### `test/features/competitions/presentation/screens/competition_detail_screen_test.dart`

- `_CompleterDownloadAndInstallFile` (around line 124–135) and
  `_ThrowingSafDownloadAndInstallFile` (around line 137–150) both `extends DownloadAndInstallFile`
  and `@override Future<Either<Failure, Unit>> call(...)`. Change both overrides' return type to
  `Future<Either<Failure, String>>`, and change `_CompleterDownloadAndInstallFile`'s `_future`
  field type to `Future<Either<Failure, String>>` accordingly.
- `'Download button is disabled while downloading'` test (around line 590–619): the `Completer`
  is typed `Completer<Either<Failure, Unit>>` — change to `Completer<Either<Failure, String>>`,
  and change `completer.complete(const Right(unit));` to
  `completer.complete(const Right('compman-airspace.txt'));` (this test uses `tAirspaceFile`,
  confirm around line 596).
- Any other place in this file constructing `Right(unit)` / `Either<Failure, Unit>` in connection
  with `DownloadAndInstallFile` (not `DownloadAndInstallTask`, which is untouched) needs the same
  type change — grep the file for `Right(unit)` and `Either<Failure, Unit>` after editing and
  confirm each remaining occurrence belongs to the task-download flow, not the file-download flow.

### New widget tests (still required)

`test/features/competitions/presentation/screens/competition_detail_screen_test.dart` has no
existing test asserting the success SnackBar text for airspace/waypoints downloads (checked via
`grep -n "downloaded\|SnackBar" test/features/competitions/presentation/screens/competition_detail_screen_test.dart`).
Add one widget test per kind (airspace and waypoints) that:

1. Pumps the screen with a stubbed `downloadAndInstallFileProvider` that resolves to
   `Right('compman-airspace.txt')` (or the waypoints equivalent) — reuse
   `_CompleterDownloadAndInstallFile` (completing immediately) or add a similarly simple stub
   returning the filename synchronously, following the file's existing conventions.
2. Taps the `'Download'` button for that card and settles.
3. Asserts `find.text('Airspace downloaded as compman-airspace.txt')` (or the waypoints
   equivalent) finds one widget.

These tests now exercise the filename flowing end-to-end from the use case's `Right` value
through to the rendered SnackBar text, not a hard-coded `successMessage` string.

## Acceptance criteria

- `DownloadAndInstallFile.call()` returns `Future<Either<Failure, String>>`; on success it
  returns the on-device filename it wrote (`compman-airspace.txt` / `compman-waypoints.cup`).
  There is exactly one place in the codebase that spells out these two filename literals: the
  `switch` inside `download_and_install_file.dart`.
- Airspace download success SnackBar reads exactly `Airspace downloaded as
  compman-airspace.txt`; waypoints reads exactly `Waypoints downloaded as
  compman-waypoints.cup` — both derived at runtime from the use case's returned filename, not
  from a second hard-coded string.
- `_FileDownloadCard` does not hard-code "Airspace"/"Waypoints" wording internally; that wording
  is supplied per-card by `_AirspaceCard`/`_WaypointsCard`.
- Task download SnackBar text (`'Task downloaded'`) and `DownloadAndInstallTask` are unchanged.
- The source-filename text on the Airspace/Waypoints card body is unchanged.
- `test/features/competitions/domain/download_and_install_file_test.dart` and
  `test/features/competitions/presentation/screens/competition_detail_screen_test.dart` are
  updated for the new `Either<Failure, String>` return type, per "Tests to update" above.
- New widget test coverage exists for both SnackBar strings, per "New widget tests" above.
- `flutter test` (or `make test`) passes.
- `flutter analyze` (or `make analyze`) reports no issues.
- `make format` (or `dart format lib test`) reports no changes.
- Add a `CHANGELOG.md` entry under `## Unreleased` / `### Changed` per `AGENTS.md`'s changelog
  rules — plain-language, pilot-facing, e.g. "Show the on-device filename when an airspace or
  waypoints file finishes downloading" (adjust wording as needed, no trailing period, no
  internal jargon).

## References

- `issues/userstories/2026-07-25-discoverable-download-filenames.md` — the enriched user story
  with full product rationale for this change, including why a copy action and dynamic filename
  interpolation from the *source* filename were rejected.
- `AGENTS.md` — general project rules, Docker/Makefile commands, commit message format, and
  changelog maintenance rules.
- `lib/features/competitions/presentation/screens/competition_detail_screen.dart` — `_AirspaceCard`,
  `_WaypointsCard`, `_FileDownloadCard`/`_FileDownloadCardState` (the SnackBar call sites).
- `lib/features/competitions/domain/usecases/download_and_install_file.dart` — the use case to
  change, and the single source of truth for the fixed on-device filenames.
- `lib/core/di/providers.dart` — `downloadAndInstallFileProvider` wiring (plain `Provider`, no
  codegen involved).
- `test/features/competitions/domain/download_and_install_file_test.dart` — use case unit tests
  to update for the new return type.
- `test/features/competitions/presentation/screens/competition_detail_screen_test.dart` —
  existing download-flow widget tests to update, plus new tests to add.
