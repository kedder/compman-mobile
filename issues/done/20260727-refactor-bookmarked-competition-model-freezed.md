# Convert `BookmarkedCompetitionModel` to freezed and use `copyWith` for partial updates

## Feature summary

`BookmarkedCompetitionModel` (`lib/features/competitions/data/models/bookmarked_competition_model.dart`)
is the only `@HiveType` model in the codebase (verified via `grep -rln "@HiveType" lib`). Unlike every
other data structure in this project, it is a plain Dart class rather than a `freezed` class, which
violates the "Use freezed for all domain entities and data models" rule in `AGENTS.md`. Because it has
no generated `copyWith`, three methods in `CompetitionsRepositoryImpl`
(`lib/features/competitions/data/repositories/competitions_repository_impl.dart`) update a single field
by manually reconstructing the entire object field-by-field from an `existing` instance:
`setCompetitionClass`, `recordFileInstall`, and `recordTaskInstall`. This is repetitive and error-prone
(a new field added to the model requires every one of these call sites to be updated by hand).

## Resolved technical question — freezed + Hive codegen compatibility

This project uses **`hive_ce`** / **`hive_ce_generator`** (Hive Community Edition — see `pubspec.yaml`:
`hive_ce: ^2.19.3`, `hive_ce_generator: ^1.10.1`), not the original unmaintained `hive`/`hive_generator`.
This matters because the combination of `freezed` and Hive codegen has a poor reputation with the
original `hive_generator`, but **`hive_ce` explicitly added support for this**:

- `hive_ce` changelog 2.6.0: "Adds `TargetKind.parameter` to `HiveField` to support `freezed`" — lets
  `@HiveField` be placed directly on a `const factory` constructor's parameters instead of on
  directly-declared fields.
- `hive_ce` changelog 2.11.0: "Supports `freezed` default values" (`@Default(...)`).
- `hive_ce_generator` changelog 1.6.0: "Adds `.freezed.dart` to `required_inputs` to support `freezed`"
  — this makes `build_runner` run `freezed` on the file *before* `hive_ce_generator`, so there is no
  manual build-order configuration to worry about.
- `hive_ce_generator` changelog 1.9.0: "Adds support for `@Default` annotation from `freezed`" (robust
  freezed support baseline).

The versions pinned in this project (`hive_ce_generator ^1.10.1`) are well past all of the above, so
**no fallback hand-written `copyWith` is needed** — go with the freezed conversion directly. Do not
introduce a `build.yaml` for generator ordering; it is unnecessary given the `required_inputs` fix
above.

The codebase already has one precedent for a `@freezed` class carrying doc comments on individual
constructor parameters (the domain entity `lib/features/competitions/domain/entities/bookmarked_competition.dart`),
so putting `@HiveField(n)` (plus the existing `///` doc comment) on each parameter of the new factory
constructor is consistent with existing style, not a novel pattern.

## Scope

This issue covers:

1. Converting `BookmarkedCompetitionModel` to a `@freezed` class with a real generated `copyWith`,
   while keeping it a valid `@HiveType` Hive adapter.
2. Updating `setCompetitionClass`, `recordFileInstall`, and `recordTaskInstall` in
   `CompetitionsRepositoryImpl` to use `existing.copyWith(...)` instead of manual field-by-field
   reconstruction.
3. Optionally tidying up the one test helper that reconstructs a model field-by-field for the same
   reason (see "Test note" below) — not required, but do it if trivial, for consistency.

No other instances of this "manually reconstruct the whole object to change one field" pattern exist
elsewhere in `lib/` (checked via `grep -rn "existing\."` across `lib/`) — this issue's three
`competitions_repository_impl.dart` methods and the model itself are the only production-code targets.

## What to build

### 1. `lib/features/competitions/data/models/bookmarked_competition_model.dart`

Convert to freezed, following the same shape already used by the domain entity
`lib/features/competitions/domain/entities/bookmarked_competition.dart` (abstract class + private
constructor + `with _$BookmarkedCompetitionModel`), but keep the Hive annotations and the existing
`toEntity()` / `fromEntity()` conversion methods:

- Add `import 'package:freezed_annotation/freezed_annotation.dart';`.
- Keep `import 'package:hive_ce_flutter/hive_ce_flutter.dart';` and the entity import.
- Add `part 'bookmarked_competition_model.freezed.dart';` alongside the existing
  `part 'bookmarked_competition_model.g.dart';`.
- Annotate the class with both `@freezed` and `@HiveType(typeId: 0)` (keep the existing "do not reuse
  typeId 0" doc comment).
- Make the class `abstract class BookmarkedCompetitionModel with _$BookmarkedCompetitionModel`, with a
  private `const BookmarkedCompetitionModel._();` constructor (needed because the class defines
  `toEntity()` as an instance method).
- Move every field into a `const factory BookmarkedCompetitionModel({...}) = _BookmarkedCompetitionModel;`
  constructor, keeping each field's existing `///` doc comment and moving each field's `@HiveField(n)`
  annotation onto the corresponding constructor parameter (same field indices as today — do not renumber,
  since renumbering would break deserialization of already-persisted Hive records).
- Keep `toEntity()` as an instance method on the class body (after the private constructor / factory,
  same as `bookmarked_competition.dart`'s `status` getter is placed).
- Keep `fromEntity(BookmarkedCompetition entity)` as a plain (non-`const`) named factory constructor on
  the class — this is not a freezed union member since it isn't declared `const factory`, so freezed
  leaves it untouched (same pattern as a hand-written `fromJson` factory alongside a freezed class).

Run codegen (`make codegen`, or `dart run build_runner build --delete-conflicting-outputs` inside the
dev container) to regenerate `bookmarked_competition_model.g.dart` and the new
`bookmarked_competition_model.freezed.dart`. Confirm the generated Hive adapter still reads/writes
fields 0–10 with the same types as the current `bookmarked_competition_model.g.dart` (re-read that file
before editing, as a reference for what the generator should reproduce).

### 2. `lib/features/competitions/data/repositories/competitions_repository_impl.dart`

Replace the manual reconstructions in these three methods with `copyWith`:

- `setCompetitionClass`: `final updated = existing.copyWith(selectedClass: selectedClass);`
- `recordFileInstall`: build the updated model with `copyWith`, still keyed on `kind`, e.g.
  ```dart
  final updated = kind == DownloadableFileKind.airspace
      ? existing.copyWith(airspaceVersion: version)
      : existing.copyWith(waypointsVersion: version);
  ```
  (Preserve the current behavior exactly: only the field matching `kind` changes; the other version
  field is untouched — `copyWith` naturally does this since omitted parameters keep the existing value.)
- `recordTaskInstall`: `final updated = existing.copyWith(taskVersion: version);`

Do not change any other method in this file.

### Test note (optional, do if trivial)

`test/features/competitions/data/competitions_local_datasource_test.dart` has one spot (in the `save`
test group, building `updated` from `tModel` with only `title` changed) that uses the same
field-by-field reconstruction. Since `copyWith` now exists, you may simplify it to
`tModel.copyWith(title: 'Updated Title')` for consistency. This is not required for the issue to be
considered complete.

Existing tests in `test/features/competitions/data/competitions_repository_impl_test.dart` for
`setCompetitionClass`, `recordFileInstall`, and `recordTaskInstall` use `predicate<BookmarkedCompetitionModel>`
matchers, not equality — they should continue to pass unmodified. Re-run them to confirm.

## Acceptance criteria

- `BookmarkedCompetitionModel` is a `@freezed` class with a generated `copyWith`, still annotated
  `@HiveType(typeId: 0)`, with all `@HiveField` indices unchanged (0 through 10).
- `setCompetitionClass`, `recordFileInstall`, and `recordTaskInstall` in
  `competitions_repository_impl.dart` use `existing.copyWith(...)` instead of manual field-by-field
  object construction.
- `bookmarked_competition_model.g.dart` and the new `bookmarked_competition_model.freezed.dart` are
  regenerated and committed.
- `make test` passes (or `flutter test` inside the dev container).
- `make analyze` reports no issues.
- `make format` reports no changes.
- No behavior change: existing bookmarked competitions persisted under the current Hive schema must
  still deserialize correctly (field indices unchanged guarantees this — do not add a manual migration
  test unless you have reason to believe indices shifted).

## References

- `AGENTS.md` — "Use freezed for all domain entities and data models" rule; general project rules,
  Docker/Makefile commands, and commit message format.
- `lib/features/competitions/domain/entities/bookmarked_competition.dart` — reference freezed shape
  (abstract class, private constructor, doc comments on individual constructor parameters) to mirror.
- Prior issue: `issues/done/20260726-01-task-download-version-tracking.md` (added `recordTaskInstall`,
  the method that most recently introduced this anti-pattern).
