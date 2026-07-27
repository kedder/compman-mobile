# Flight log domain/data layer: scoring email field + read `.igc` logs from XCSoar's SAF directory

Derived from `issues/userstories/2026-07-25-email-flight-log-after-flight.md` ("Suggest
Emailing Today's Flight Logs to Organizers After Flying"). Read that file in full — it has
already been through Product Owner refinement, including six resolved open questions and a
detailed UX proposal. **One correction to note while reading it:** the "review/resend an
older log" sentence inside the "Zero-logs state" paragraph of the "Concrete UX proposal"
section is stale/inconsistent with the rest of the document and must be ignored — the
zero-logs state has **no** action button, and the Flight Log screen only ever lists
**today's** `.igc` files (never older ones). This was confirmed with the user during
planning.

## Feature summary

Compman is gaining the ability to let a pilot email today's XCSoar flight log(s)
(`.igc` files) to a competition's scoring email address, via a persistent "Flight Logs"
panel on the Competition Detail screen and a new Flight Log screen. This is a batch of
(currently) 3 issues:

1. **This issue** — domain/data layer: a new per-competition scoring email field, and new
   read-only access to `.igc` files inside XCSoar's existing SAF-granted directory (Compman
   currently only *writes* into that directory — see `docs/features/xcsoar.md` — this adds
   the first *read* capability).
2. `20260727-02-flight-log-screen.md` — the new Flight Log screen (list + checkboxes,
   recipient email field, Send button wired to a share/send intent).
3. `20260727-03-flight-logs-panel.md` — the persistent Flight Logs summary panel on
   Competition Detail, which is the entry point into the Flight Log screen.

Issues 2 and 3 both depend on this issue. Read this issue's code fully even if you are
assigned issue 2 or 3 later — it defines the entities, use cases, and providers they build
on.

## Scope

This issue is domain/data/platform layer only. **No screens or widgets.** Concretely:

### 1. `BookmarkedCompetition.scoringEmail` field

Add a new nullable `scoringEmail` field to the `BookmarkedCompetition` domain entity
(`lib/features/competitions/domain/entities/bookmarked_competition.dart`) and to
`BookmarkedCompetitionModel` (`lib/features/competitions/data/models/bookmarked_competition_model.dart`,
next free `@HiveField` index is `11` — the model currently goes up to `@HiveField(10)
taskVersion`). Follow the exact pattern already used for `taskVersion`/`airspaceVersion`
(freezed field, doc comment noting old records deserialise with `null`, wired through
`toEntity()`/`fromEntity()`). Regenerate `.freezed.dart`/`.g.dart` via `make codegen`.

### 2. Repository method to persist the scoring email

Add to `CompetitionsRepository`
(`lib/features/competitions/domain/repositories/competitions_repository.dart`):

```dart
/// Persists the scoring email address for a bookmarked competition. Called
/// after the pilot successfully sends flight logs so the address is
/// remembered and pre-filled next time (see docs/features/competitions.md).
Future<Either<Failure, Unit>> setCompetitionScoringEmail(
  String competitionId,
  String email,
);
```

Implement in `CompetitionsRepositoryImpl` by mirroring `setCompetitionClass` exactly (read
via `local.getById`, `Left(StorageFailure('Competition not found'))` if absent, `copyWith`,
`local.save`, catch → `StorageFailure`).

Add a `SetCompetitionScoringEmail` use case
(`lib/features/competitions/domain/usecases/set_competition_scoring_email.dart`) that is a
thin wrapper delegating to the repository — mirror `SetCompetitionClass`
(`lib/features/competitions/domain/usecases/set_competition_class.dart`) exactly, including
its doc comments.

Wire a `setCompetitionScoringEmailProvider` in `lib/core/di/providers.dart`, mirroring
`setCompetitionClassProvider`.

**Note:** this issue only builds the plumbing. Nothing calls
`SetCompetitionScoringEmail`/`setCompetitionScoringEmailProvider` yet — issue 2
(`20260727-02-flight-log-screen.md`) is where it gets used, as part of a combined
"share + remember email" use case described there.

### 3. `FlightLogFile` domain entity

New freezed entity, `lib/features/competitions/domain/entities/flight_log_file.dart`:

```dart
class FlightLogFile {
  final String filename; // raw on-disk name, e.g. "2018-02-26-XCS-WUX-01.igc"
  final String uri;      // SAF content:// URI string for this document
}
```

No Hive persistence needed — this is a transient, always-freshly-fetched value, not stored.

### 4. Android bridge: list `.igc` files under `logs/` in the granted SAF tree

Add a new method to the existing `xcsoar.saf` `MethodChannel` handler in
`android/app/src/main/kotlin/lt/lebedev/compman_mobile/MainActivity.kt`: `listFlightLogs`
(no arguments).

Read the existing `handleWriteFile` implementation in the same file first — it already
demonstrates the query pattern you need (checking the stored/granted tree URI, and querying
a `DocumentsContract` children URI, filtering by display name in-process because
`ExternalStorageProvider` ignores selection args).

Behaviour:

- Same "not configured" check as `writeFile`: if no `xcsoar_tree_uri` is stored, or the
  stored tree URI does not have a current read+write persisted permission grant, return
  `result.error("SAF_NOT_CONFIGURED", ...)` (same code `writeFile` uses, so Dart callers can
  reuse existing `SAF_NOT_CONFIGURED` handling conventions if they choose to).
- Otherwise, look for a child of the tree root named `logs` (case-sensitive match on
  `COLUMN_DISPLAY_NAME`, ideally also checking `COLUMN_MIME_TYPE ==
  DocumentsContract.Document.MIME_TYPE_DIR`, but a plain name match is acceptable if
  simpler). **If no `logs` folder exists, return `result.success(emptyList<Map<String,
  String>>())` — this is not an error, it just means XCSoar hasn't logged any flights yet.**
- If a `logs` folder is found, query *its* children (build a child-documents URI from the
  `logs` folder's own document ID, the same way `handleWriteFile` builds one from the tree's
  root document ID) and collect every child whose display name ends with `.igc`
  (case-insensitive).
- Return `result.success(...)` with a `List<Map<String, String>>`, each entry
  `{"filename": <display name>, "uri": <document URI as string, built via
  DocumentsContract.buildDocumentUriUsingTree(treeUri, childDocId)>}`.
- Wrap file-system access in `try`/`catch` and return `result.error("SAF_ERROR", ...)` on
  unexpected failure, matching `handleWriteFile`'s error handling.

Feel free to extract a small private helper for "find a child document ID by display name
under a parent" since both `handleWriteFile` and this new method need the same query
pattern — but this is not mandatory if duplicating the ~15-line loop is simpler.

### 5. `XcsoarSafService.listFlightLogs()`

In `lib/core/platform/xcsoar_saf_service.dart`, add:

```dart
/// Returns every `.igc` file found under `logs/` in the granted XCSoar SAF
/// directory, regardless of date. Callers filter by date themselves (see
/// [GetTodaysFlightLogs]).
///
/// Returns an empty list if the `logs/` folder does not exist yet (XCSoar
/// has not logged any flights). Throws [PlatformException] with code
/// `SAF_NOT_CONFIGURED` if no XCSoar directory has been granted.
Future<List<FlightLogFile>> listFlightLogs() async { ... }
```

Map the raw `List<Map>` channel result to `List<FlightLogFile>`.

### 6. `GetTodaysFlightLogs` use case (pure Dart, testable without a platform channel)

New file `lib/features/competitions/domain/usecases/get_todays_flight_logs.dart`:

```dart
/// Fetches all flight logs via [XcsoarSafService.listFlightLogs] and filters
/// to today's date, matching the `yyyy-MM-dd` prefix XCSoar uses when naming
/// `.igc` files (e.g. `2018-02-26-XCS-WUX-01.igc`).
class GetTodaysFlightLogs {
  const GetTodaysFlightLogs(this._safService, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final XcsoarSafService _safService;
  final DateTime Function() _now;

  Future<List<FlightLogFile>> call() async {
    final all = await _safService.listFlightLogs();
    final todayPrefix = DateFormat('yyyy-MM-dd').format(_now());
    final todays = all.where((f) => f.filename.startsWith(todayPrefix)).toList()
      ..sort((a, b) => a.filename.compareTo(b.filename));
    return todays;
  }
}
```

(`intl`'s `DateFormat` is already a project dependency — see `pubspec.yaml`.) This use case
intentionally does **not** go through `CompetitionsRepository` — it only depends on
`XcsoarSafService` (from `core/platform/`, which all layers may import per
`docs/architecture.md`), mirroring how `DownloadAndInstallFile` combines a repository with
`XcsoarSafService`. `PlatformException` (e.g. `SAF_NOT_CONFIGURED`) is **not** caught — it
propagates to the caller.

Wire a `getTodaysFlightLogsProvider` in `lib/core/di/providers.dart`:
`Provider<GetTodaysFlightLogs>((ref) => GetTodaysFlightLogs(ref.read(xcsoarSafServiceProvider)))`.

### 7. Shared presentation provider

Add to `lib/features/competitions/presentation/providers/competitions_providers.dart`:

```dart
/// Fetches today's flight log files from the XCSoar SAF directory. Shared by
/// the Flight Logs panel and the Flight Log screen — not scoped to a
/// competition ID, since the XCSoar log folder is global to the device and
/// "today" is the only relevant filter (see docs/features/xcsoar.md).
final todaysFlightLogsProvider = FutureProvider.autoDispose<List<FlightLogFile>>((
  ref,
) {
  return ref.read(getTodaysFlightLogsProvider)();
});
```

This one provider is the single source both later issues watch — do not create per-issue
duplicates of it.

## Out of scope for this issue

- Any UI (screens, widgets, routes). Issues 2 and 3 build those.
- The share/send intent itself (`shareFlightLogs` Kotlin method) — that belongs to issue 2,
  since it's only used from the Flight Log screen's Send button.
- `docs/features/overview.md` UI-flow updates and `CHANGELOG.md` — nothing user-visible
  ships in this issue; leave those to issue 3, which completes the user-reachable flow (see
  that issue for the note on why).

## Documentation

Per `AGENTS.md`'s documentation-maintenance table, update in the same commit(s):

- `docs/features/competitions.md` — add `scoringEmail` to the `BookmarkedCompetition`
  entity listing, add the new `SetCompetitionScoringEmail` use case to the use-case table,
  and add `todaysFlightLogsProvider` to the providers table.
- `docs/features/xcsoar.md` — add `listFlightLogs` to the "Android Bridge Methods" table and
  `listFlightLogs()` to the "Dart Service: `XcsoarSafService`" table, following the existing
  row format.
- `docs/plan.md` — add a new entry (or extend Phase 4) noting this domain/data layer is
  done, per the existing entry style.

## Testing

- `SetCompetitionScoringEmail`: unit test mirroring
  `test/features/competitions/domain/set_competition_class_test.dart` (success, and
  propagation of a `Left(StorageFailure(...))` from the repository). Use the existing
  generated mock at `test/features/competitions/domain/mock_competitions_repository.mocks.dart`.
- `CompetitionsRepositoryImpl.setCompetitionScoringEmail`: unit test mirroring the existing
  `setCompetitionClass` repository-impl test (find it under
  `test/features/competitions/data/`) — competition-not-found path and success path.
- `GetTodaysFlightLogs`: new unit test with a mocked/faked `XcsoarSafService` and an injected
  fixed `now`. Cover: only same-day-prefixed filenames are kept; non-`.igc`-dated entries
  from other days are excluded; empty input list produces an empty result; a thrown
  `PlatformException` from the service propagates unchanged.
- `BookmarkedCompetitionModel`: extend/add the Hive round-trip test to cover `scoringEmail`
  (find the existing model test under `test/features/competitions/data/models/`), and
  confirm old records without the field deserialise with `scoringEmail == null`.
- No Kotlin/instrumentation tests exist in this repo (confirmed: none under `android/`) — do
  not add any; the Kotlin change is validated manually/by the reviewer, consistent with all
  other SAF bridge methods.

## Acceptance criteria

- `make format` reports no changes.
- `make test` passes, including all new/updated unit tests listed above.
- `make analyze` is clean.
- `make codegen` has been run and generated files are committed.
- `docs/features/competitions.md`, `docs/features/xcsoar.md`, and `docs/plan.md` updated as
  described above.
