# Download Latest Task — Issue 3: Competition Class Selection Persistence

## Feature

Each competition may have multiple glider classes (e.g. Club, Open, 15m). The user needs to select their class once per competition, and that choice must be remembered so the app can show the correct task on subsequent visits.

## Scope

Domain entity update, Hive model update, repository interface update, new use case, and DI wiring. No UI changes — the class selection UI is part of issue `20260330-04-competition-detail-ui.md`.

## Dependencies

None. Can be started immediately.

---

## Background

The SoarScore data source (issue `20260330-01-soarscore-data-layer.md`) returns `List<TaskInfo>` where each `TaskInfo` has a `compClass` field. The available classes for a given competition are the distinct `compClass` values in that list.

The selected class must be persisted on the `BookmarkedCompetition` so that on re-opening the Competition Detail screen, the correct task is immediately shown without re-asking the user.

Reference: `/home/dev/openvario-compman/src/compman/storage.py` — `StoredCompetition.selected_class` field.

Read `docs/architecture.md` before starting.

---

## Tasks

### 1. Domain entity — `lib/features/competitions/domain/entities/bookmarked_competition.dart`

Add one nullable field to `BookmarkedCompetition`:

```dart
@freezed
class BookmarkedCompetition with _$BookmarkedCompetition {
  const factory BookmarkedCompetition({
    required String id,
    required String title,
    required String soaringspotUrl,
    required DateTime bookmarkedAt,
    String? selectedClass,   // <-- add this
  }) = _BookmarkedCompetition;
}
```

Re-run `make codegen` to regenerate `bookmarked_competition.freezed.dart`.

### 2. Hive model — `lib/features/competitions/data/models/bookmarked_competition_model.dart`

Add a nullable `@HiveField(4)` field:

```dart
@HiveField(4)
final String? selectedClass;
```

Update the constructor, `toEntity()`, and `fromEntity()` to include `selectedClass`.

**Migration note:** Hive automatically handles missing fields for existing records — the field will be null for old records. No manual migration needed. However, you must re-run codegen so the adapter is regenerated.

Run `make codegen`.

### 3. Repository interface — `lib/features/competitions/domain/repositories/competitions_repository.dart`

Add one method:

```dart
/// Persists the selected competition class for a bookmarked competition.
///
/// A [selectedClass] of null clears the selection.
Future<Either<Failure, Unit>> setCompetitionClass(
  String competitionId,
  String? selectedClass,
);
```

### 4. Use case — `lib/features/competitions/domain/usecases/set_competition_class.dart`

```dart
class SetCompetitionClass {
  final CompetitionsRepository _repo;
  const SetCompetitionClass(this._repo);

  /// Sets or clears the competition class for [competitionId].
  Future<Either<Failure, Unit>> call(String competitionId, String? selectedClass) =>
      _repo.setCompetitionClass(competitionId, selectedClass);
}
```

Add `///` doc comments.

### 5. Repository implementation — `lib/features/competitions/data/repositories/competitions_repository_impl.dart`

Implement `setCompetitionClass`:

```dart
@override
Future<Either<Failure, Unit>> setCompetitionClass(
  String competitionId,
  String? selectedClass,
) async {
  try {
    final existing = await _localDs.getById(competitionId);
    if (existing == null) return left(const StorageFailure('Competition not found'));
    final updated = BookmarkedCompetitionModel(
      id: existing.id,
      title: existing.title,
      soaringspotUrl: existing.soaringspotUrl,
      bookmarkedAt: existing.bookmarkedAt,
      selectedClass: selectedClass,
    );
    await _localDs.save(updated);
    return right(unit);
  } on HiveError catch (e) {
    return left(StorageFailure(e.message));
  }
}
```

If `CompetitionsLocalDataSource` doesn't have a `getById(String id)` method, add it to the abstract interface and the Hive implementation: `Future<BookmarkedCompetitionModel?> getById(String id)` returning `box.get(id)`.

### 6. DI — `lib/core/di/providers.dart`

Add:
```dart
final setCompetitionClassProvider = Provider(
  (ref) => SetCompetitionClass(ref.read(competitionsRepositoryProvider)),
);
```

### 7. Tests

`test/features/competitions/domain/usecases/set_competition_class_test.dart`:
- Sets class: mock repo returns `Right(unit)`, assert `setCompetitionClass("comp-id", "Club")` called on repo
- Clears class: assert `setCompetitionClass("comp-id", null)` works
- Error path: `Left(StorageFailure)` propagated

Update existing `CompetitionsRepositoryImpl` test to pass `null` for `selectedClass` on existing model construction.

---

## Acceptance Criteria

1. `make codegen` succeeds; updated adapter generated.
2. `flutter analyze` passes.
3. `flutter test` passes — existing tests still green, new use case tests pass.
4. `BookmarkedCompetition` has `selectedClass` (nullable `String`).
5. Old Hive records (without `selectedClass`) deserialise with `selectedClass == null`.
6. `SetCompetitionClass` use case exists and is tested.
7. `docs/plan.md` updated.
