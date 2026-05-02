# Airspace & Waypoints — SAF File Write

User story: `2026-05-01-waypoints-airspaces.md`

## Feature summary

Pilots need airspace and waypoint files written to the XCSoar data directory
so that XCSoar picks them up automatically. This issue extends the SAF
(Storage Access Framework) bridge to write airspace and waypoints files with
fixed output names (`compman.txt` and `compman.cup`) alongside the existing
task file write. It also wires the `DownloadFile` use case through the
repository for files fetched from SoaringSpot.

## Scope

This issue covers the **file I/O path** from raw bytes to the device storage:

- Extending `XcsoarSafService` with a convenience method (or verifying that
  the existing `writeFile(bytes, filename)` already handles arbitrary
  filenames, which it does).
- Implementing `downloadFile` on the data layer if it was not fully
  implemented in issue `20260501-01-…` (coordinate with that issue).
- Adding a `DownloadAndInstallFile` orchestration use case (domain) that
  chains download → SAF write → record install timestamp.
- Wiring a Riverpod provider for that orchestration use case.

**Depends on:** `20260501-01-airspace-waypoints-domain-data.md` (must be
merged first so `DownloadableFileInfo`, `DownloadFile`, and `RecordFileInstall`
use cases exist).

---

## Background

The existing `XcsoarSafService.writeFile(Uint8List bytes, String filename)`
(in `lib/core/platform/xcsoar_saf_service.dart`) already handles writing any
file by name into the SAF-granted XCSoar data directory. It throws a
`PlatformException` with code `SAF_NOT_CONFIGURED` when no directory is
configured.

The user story specifies fixed filenames:

| File type | Output filename |
|---|---|
| Airspace | `compman.txt` |
| Waypoints | `compman.cup` |

Fixed filenames mean XCSoar only needs to be configured once; subsequent
updates overwrite the same file and are picked up automatically.

---

## Tasks

### 1. Verify `downloadFile` on `CompetitionsRepository`

Confirm that `CompetitionsRepositoryImpl.downloadFile(String fileUrl)` returns
`Right<Uint8List>` (implemented in issue `20260501-01-…`). If it delegates
to `SoaringSpotRemoteDataSource`, the implementation should do a binary GET
using the `Dio` instance:

```dart
// In SoaringSpotRemoteDataSourceImpl:
@override
Future<Uint8List> downloadFile(String fileUrl) async {
  try {
    final response = await dio.get<List<int>>(
      fileUrl,
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data!);
  } on DioException catch (e) {
    throw ServerException(e.message ?? 'Download failed');
  }
}
```

If `downloadFile` is already on the abstract `SoaringSpotRemoteDataSource`
interface from the previous issue, just confirm the implementation is correct.
Otherwise add it now and update the interface and the repository impl.

### 2. Domain use case: `DownloadAndInstallFile`

Create
`lib/features/competitions/domain/usecases/download_and_install_file.dart`.

This use case orchestrates the full download-and-install sequence for a single
airspace or waypoints file. It is called from the presentation layer and takes
care of:

1. Downloading the raw bytes via `DownloadFile`.
2. Writing the bytes to the SAF directory via `XcsoarSafService.writeFile`.
3. Recording the install timestamp via `RecordFileInstall`.

```dart
/// Orchestrates downloading a [DownloadableFileInfo] and writing it to the
/// XCSoar SAF directory with a fixed output filename.
///
/// Returns [Right(unit)] on success or [Left(Failure)] if the download fails.
/// SAF errors (e.g. [PlatformException]) are **not** caught here — they
/// propagate to the presentation layer which converts them to error banners
/// (matching the existing task-install pattern).
class DownloadAndInstallFile {
  const DownloadAndInstallFile(this._repo, this._safService);

  final CompetitionsRepository _repo;
  final XcsoarSafService _safService;

  Future<Either<Failure, Unit>> call({
    required String competitionId,
    required DownloadableFileInfo fileInfo,
  }) async {
    // 1. Download
    final bytesResult = await _repo.downloadFile(fileInfo.downloadUrl);
    final bytes = bytesResult.fold((f) => throw f, (b) => b);

    // 2. Write to SAF directory with fixed name
    final outputName = switch (fileInfo.kind) {
      DownloadableFileKind.airspace  => 'compman.txt',
      DownloadableFileKind.waypoints => 'compman.cup',
    };
    await _safService.writeFile(bytes, outputName);   // may throw PlatformException

    // 3. Record installed version token (the raw string from SoaringSpot)
    await _repo.recordFileInstall(competitionId, fileInfo.kind, fileInfo.publishedVersion);

    return const Right(unit);
  }
}
```

Note: The `throw f` inside `fold` when `bytesResult` is a `Left` will propagate
the `Failure` out of `call` as a thrown exception, not as a `Left`. Adjust the
return type and error handling to be consistent with the project's existing
style. Look at `_installTask` in `competition_detail_screen.dart` for the
pattern: the presentation layer catches both `Failure` (from `fold`) and
`PlatformException` (from SAF) separately. Use the same approach.

### 3. DI provider

In `lib/core/di/providers.dart`, add:

```dart
/// Provides a [DownloadAndInstallFile] use case instance.
final downloadAndInstallFileProvider = Provider<DownloadAndInstallFile>(
  (ref) => DownloadAndInstallFile(
    ref.read(competitionsRepositoryProvider),
    XcsoarSafService(),
  ),
);
```

---

## Tests

### Unit tests

**`test/features/competitions/domain/download_and_install_file_test.dart`**

Mock both `CompetitionsRepository` and `XcsoarSafService` (the SAF service
can be tested with a simple manual mock or a Mockito mock — see how
`XcsoarSafService` is used in existing tests for the task download).

Test cases:
1. On success: `downloadFile` returns bytes → `writeFile` called with
   `'compman.txt'` (airspace) or `'compman.cup'` (waypoints) → `recordFileInstall`
   called with the correct `kind` and a non-null `DateTime` → returns
   `Right(unit)`.
2. When `downloadFile` returns `Left(NetworkFailure)`: the call propagates the
   failure (either as `Left` or as a thrown `Failure` — match the project's
   pattern).
3. When `writeFile` throws `PlatformException`: it propagates to the caller
   unwrapped.

---

## Acceptance criteria

- `make format` reports no changes.
- `make test` passes.
- `make analyze` reports no issues.
- `DownloadAndInstallFile.call` writes `compman.txt` for airspace files and
  `compman.cup` for waypoints files to the SAF directory.
- On success, `recordFileInstall` is called so the install timestamp is
  persisted.
- `PlatformException` from `XcsoarSafService` propagates to the caller
  (presentation layer handles it).
- `docs/plan.md` updated (mark Phase 2 entry or add a 📋 item).

## Constraints

- Use `XcsoarSafService` from `lib/core/platform/` — do not duplicate SAF
  logic.
- `domain` must not import from `data`. `XcsoarSafService` lives in `core/`
  which is importable from all layers.
- Follow the commit message format from `AGENTS.md`, including the issue
  filename trailer.
