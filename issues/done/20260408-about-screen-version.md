# About Screen: Display App Version + Bump to 0.1.0

## Feature summary

The About screen (`/about` route, `_AboutScreen` in `lib/app.dart`) currently shows a
hardcoded version string `"Version: 1.0.0"`. The real version must be read from the
app's package metadata at runtime, so it always stays in sync with `pubspec.yaml`.

## Scope

This issue covers:
1. Bumping the version in `pubspec.yaml` to `0.1.0+1`.
2. Adding `package_info_plus` to read the version at runtime.
3. Updating `_AboutScreen` to display the real version number.

## Task

### 1 — Bump version

In `pubspec.yaml` change:

```yaml
version: 1.0.0+1
```
to:
```yaml
version: 0.1.0+1
```

### 2 — Add `package_info_plus`

Add `package_info_plus: ^8.1.2` (or the latest stable version compatible with the project's
SDK constraint `^3.6.2`) to the `dependencies` block in `pubspec.yaml`, then run `make deps`
to update `pubspec.lock`.

### 3 — Update `_AboutScreen`

`_AboutScreen` lives at the bottom of `lib/app.dart`. Replace the hardcoded
`"Version: 1.0.0"` with a dynamic version loaded via `PackageInfo.fromPlatform()`.

Use a `FutureProvider` (or inline `FutureBuilder`) to fetch
`PackageInfo.fromPlatform()`. The recommended pattern for this project is a Riverpod
`FutureProvider` in `lib/core/di/providers.dart` (or a dedicated file in
`lib/core/di/`) so it is injectable and testable:

```dart
/// Provides the app's [PackageInfo] (version, build number, etc.).
@riverpod
Future<PackageInfo> packageInfo(Ref ref) => PackageInfo.fromPlatform();
```

Then make `_AboutScreen` a `ConsumerWidget` that watches `packageInfoProvider`.
Display:
- Loading state: `CircularProgressIndicator` (centered).
- Error state: a simple error message (`"Version unavailable"`).
- Data state: `"Version: ${info.version}"` — the existing layout can stay, just
  replace the static `Text('Version: 1.0.0')` with the real value.

Keep the existing layout (column with app name, version, SoaringSpot credit).
Follow `docs/ui-guidelines.md` typography rules (min 16 sp body text).

### 4 — Update `docs/plan.md`

Mark the About-screen version task ✅ in `docs/plan.md` under the Presentation Layer
section of Phase 1. Add a brief implementation note.

## Files to read before starting

- `lib/app.dart` — contains `_AboutScreen` and the router
- `lib/core/di/providers.dart` — existing DI providers; add `packageInfoProvider` here
- `pubspec.yaml` — version and dependency list
- `docs/architecture.md` — layer rules
- `docs/ui-guidelines.md` — typography, loading/error state patterns
- `AGENTS.md` — general project rules

## Acceptance criteria

- `pubspec.yaml` version is `0.1.0+1`.
- `package_info_plus` is listed in `pubspec.yaml` dependencies and `pubspec.lock` is updated.
- The About screen shows the version read from `PackageInfo` (not a hardcoded string).
- Loading and error states are handled in the About screen.
- `flutter analyze` reports no issues.
- `make test` passes (add or update any widget test for `_AboutScreen` if one exists).
- `docs/plan.md` updated in the same commit.
