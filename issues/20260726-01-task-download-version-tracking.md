# Task download version tracking and "New" badge on the Task card

## Feature summary

This is the first of two issues implementing the "Fly XCSoar" button described in
[`issues/userstories/2026-05-12-fly-button.md`](userstories/2026-05-12-fly-button.md). The
Fly button (issue 2) must be hidden until a task has been downloaded for the current
competition, and hidden again once a newer task version is published. That requires
knowing, per competition, which task version was last downloaded — which the app does not
currently track.

Read [`AGENTS.md`](../AGENTS.md) for general project rules before starting.

## Scope

This issue is **only** about persisting the installed task version and showing a real
"New" badge on the Task card. It does **not** touch the Fly button, the Android
`launchPackage` bridge method, or any XCSoar-launch UI — that is issue
`20260726-02-fly-xcsoar-button.md`, which depends on this one being done first.

## Context: the existing pattern to mirror

Airspace and waypoints files already track an installed-version token per competition,
stored on `BookmarkedCompetition`, and show a real "NEW UPDATE" `AppBadge` when the
SoaringSpot-published version differs from what's installed. Tasks have none of this yet —
the "NEW UPDATE" badge on the Task card is a commented-out `// TODO(new-update)` stub. You
are implementing the same pattern for tasks, using `TaskInfo.timestamp` as the version
token (tasks have no separate `publishedVersion` field; the generation timestamp already
uniquely identifies a task revision).

Read these existing implementations before starting, since you are replicating their shape
almost exactly:

- `lib/features/competitions/domain/entities/bookmarked_competition.dart` — `airspaceVersion`/`waypointsVersion` fields on the domain entity.
- `lib/features/competitions/data/models/bookmarked_competition_model.dart` — the Hive model, `@HiveField(8)`/`@HiveField(9)` for those two fields. **The next free field index is 10.**
- `lib/features/competitions/domain/repositories/competitions_repository.dart` — the abstract `recordFileInstall(competitionId, kind, version)` method.
- `lib/features/competitions/data/repositories/competitions_repository_impl.dart` (around line 186) — its implementation, which reads the existing model, copies it with the new version field set, and saves it back.
- `lib/features/competitions/domain/usecases/download_and_install_file.dart` — how the use case calls `_repo.recordFileInstall(...)` after a successful write, for the airspace/waypoints flow.
- `lib/features/competitions/presentation/screens/competition_detail_screen.dart`, `_FileDownloadCard._hasNewUpdate` (around line 801) and its `AppBadge` usage (around line 869-875) — the exact "New" comparison and badge rendering to replicate for the Task card.

## What to build

1. **Domain entity**: add `String? taskVersion` to `BookmarkedCompetition`
   (`lib/features/competitions/domain/entities/bookmarked_competition.dart`), doc-commented
   like the existing version fields. Regenerate freezed code (`make codegen`).

2. **Hive model**: add `@HiveField(10) final String? taskVersion` to
   `BookmarkedCompetitionModel`, threaded through the constructor, `toEntity()`, and
   `fromEntity()`. Regenerate the Hive adapter (`make codegen`). Do not renumber existing
   fields.

3. **Repository**: add a new abstract method to `CompetitionsRepository`, e.g.
   `Future<Either<Failure, Unit>> recordTaskInstall(String competitionId, String version)`.
   Tasks have no `DownloadableFileKind`, so this is a dedicated method, not a reuse of
   `recordFileInstall`. Implement it in `CompetitionsRepositoryImpl` by mirroring
   `recordFileInstall`, but only setting `taskVersion`.

4. **Use case**: update `DownloadAndInstallTask`
   (`lib/features/competitions/domain/usecases/download_and_install_task.dart`) to accept
   `competitionId` and a `version` string alongside the existing `taskUrl`, and call
   `_repo.recordTaskInstall(competitionId, version)` after a successful SAF write, mirroring
   `DownloadAndInstallFile.call`. Update its doc comment accordingly.

5. **Call site**: in `_TaskSectionState._installTask`
   (`lib/features/competitions/presentation/screens/competition_detail_screen.dart:515`),
   pass `widget.competitionId` and `task.timestamp` into the use case call.

6. **"New" badge on the Task card**: `_TaskSection` currently only receives `competitionId`
   and `selectedClass` (see `_ClassSection` at line 346, which already holds `competition:
   BookmarkedCompetition` but doesn't pass it down). Thread `competition.taskVersion`
   through `_TaskSection` down to `_TaskCard` (or thread the whole `competition` object, if
   that reads more naturally alongside the existing `task`/`downloading`/`onInstall`
   params — your call). In `_TaskCard.build`, replace the commented-out block at lines
   619-624 with a real `AppBadge`, shown when `task.timestamp != installedTaskVersion`
   (same shape as `_FileDownloadCard._hasNewUpdate`, using `colorScheme.error` /
   `colorScheme.onError` and `label: 'NEW UPDATE'`, `hasRing: true` — copy the existing
   badge invocation at line 869-875 exactly).

## Acceptance criteria

- After downloading a task, `BookmarkedCompetition.taskVersion` for that competition equals
  the downloaded task's `timestamp`, and this persists across app restarts (Hive).
- The Task card shows a "NEW UPDATE" badge when the currently-fetched task's `timestamp`
  differs from the stored `taskVersion` (including when nothing has been downloaded yet,
  i.e. `taskVersion` is null — same semantics as the existing airspace/waypoints badge).
- The badge disappears immediately after a successful download of the current task
  version.
- Existing airspace/waypoints version tracking and badges are unaffected.
- A unit test exists for `DownloadAndInstallTask` covering that a successful download
  calls `recordTaskInstall` with the right competition ID and version, and for
  `CompetitionsRepositoryImpl.recordTaskInstall`.
- A widget test covers the Task card showing/hiding the "NEW UPDATE" badge based on
  `taskVersion` vs. the fetched task's `timestamp`.
- `make test` passes.
- `make analyze` reports no new issues.
- `make format` reports no changes.
- Update `docs/features/competitions.md` to describe task version tracking and the "New"
  badge, per the Documentation Maintenance table in `AGENTS.md`.

## Notes

- Do not implement the Fly button, the `launchPackage` bridge method, or any
  active-flavor-resolution provider in this issue — those belong to
  `20260726-02-fly-xcsoar-button.md`.
- Reference this issue's filename (`20260726-01-task-download-version-tracking.md`) in
  every commit, per [`issues/AGENTS.md`](AGENTS.md).
