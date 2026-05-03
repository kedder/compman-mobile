# Remember Last-Viewed Competition and Auto-Navigate on App Open

## Feature summary

When the user opens a Competition Detail screen, record that competition's ID
locally. On the next cold start, if that ID still matches a bookmarked
competition, navigate directly to the detail screen instead of showing the home
screen. This removes a redundant tap for pilots who attend the same competition
all week.

## Scope

This issue covers the complete implementation of the feature:

1. A new local data source (`LastViewedLocalDataSource`) that reads and writes
   the last-viewed competition ID to a dedicated Hive box.
2. A new Riverpod provider (`lastViewedBoxProvider`) for that box.
3. Converting `CompetitionDetailScreen` from a `ConsumerWidget` to a
   `ConsumerStatefulWidget` so `initState` can fire-and-forget write the ID.
4. Refactoring `CompmanApp` from `StatelessWidget` to `ConsumerStatefulWidget`
   so the router can be constructed with the correct `initialLocation` after
   reading the persisted ID synchronously against the already-loaded bookmarks.
5. Unit tests, widget tests, and documentation updates.

## What to build

### 1. Settings / last-viewed Hive box

Create `lib/core/storage/last_viewed_local_datasource.dart`.

- Use a plain `Box<String>` named `"settings"`. No type adapter is needed for
  primitive `String` values — call `Hive.openBox<String>('settings')`.
- Define the storage key as a private constant: `const _kLastViewedId =
  'lastViewedCompetitionId';`.
- Expose two methods:
  - `String? readLastViewedId()` — returns the stored value or `null`.
  - `Future<void> writeLastViewedId(String id)` — stores the value; errors are
    not caught here (they are silent at call sites).
- Add Dart doc comments to the class and both methods.

### 2. New DI provider

In `lib/core/di/providers.dart`, add:

```dart
/// Provides the Hive [Box] used to store cross-feature settings (plain strings).
///
/// No type adapter registration is required for a [Box<String>].
final settingsBoxProvider = FutureProvider<Box<String>>((ref) async {
  await Hive.initFlutter();
  return Hive.openBox<String>('settings');
});
```

Also add a provider for the data source:

```dart
/// Provides the [LastViewedLocalDataSource] once the settings box is ready.
final lastViewedLocalDataSourceProvider =
    Provider<LastViewedLocalDataSource>((ref) {
  final box = ref.watch(settingsBoxProvider).requireValue;
  return LastViewedLocalDataSource(box);
});
```

### 3. Write last-viewed ID from the detail screen

Convert `CompetitionDetailScreen` from `ConsumerWidget` to
`ConsumerStatefulWidget`. In `initState`, call:

```dart
final dataSource = ref.read(lastViewedLocalDataSourceProvider);
dataSource.writeLastViewedId(widget.competitionId);
```

The call is fire-and-forget — do not `await` it, do not show any UI feedback,
and do not catch errors (a write failure is acceptable to swallow silently).

`initState` fires exactly once per screen entry, which is the correct semantics.
Note that `ref` is available in `ConsumerState.initState` as `this.ref` (not
passed as a parameter).

The rest of `CompetitionDetailScreen.build` is unchanged.

### 4. Resolve the initial route in `CompmanApp`

The current `CompmanApp` is a `StatelessWidget` and the router is a module-level
`final _router`. That design cannot read from async Hive before the first frame.

Refactor as follows:

- Change `CompmanApp` to a `ConsumerStatefulWidget`.
- In `State.initState`, trigger loading of both `bookmarksBoxProvider` and
  `settingsBoxProvider` by calling `ref.read(bookmarksBoxProvider.future)` and
  `ref.read(settingsBoxProvider.future)`.
- In `build`, watch both providers:

  ```dart
  final bookmarksBoxAsync = ref.watch(bookmarksBoxProvider);
  final settingsBoxAsync  = ref.watch(settingsBoxProvider);
  ```

  - While either is loading, return a minimal `MaterialApp` with a
    `CircularProgressIndicator` centered on a white background (consistent with
    the existing loading pattern already implied by the bookmarks provider).
  - If either errors, fall through to the normal home screen (use
    `GoRouter(initialLocation: '/')` and log nothing).
  - When both are ready, compute `initialLocation`:

    ```dart
    String initialLocation = '/';
    final lastId = LastViewedLocalDataSource(settingsBox).readLastViewedId();
    if (lastId != null) {
      final bookmarks = bookmarksBox.values;
      final stillBookmarked = bookmarks.any((m) => m.id == lastId);
      if (stillBookmarked) {
        initialLocation = '/competitions/$lastId';
      }
    }
    ```

    Then create and cache the router as `_GoRouterCache(initialLocation)` in
    state so it is not rebuilt on every frame.

- Move the `GoRouter` definition (routes list) into a private factory function
  `_buildRouter(String initialLocation)` so the routes are not duplicated.

This approach guarantees no visible home-screen flash: the app shows a spinner
until both boxes are open (which takes milliseconds on subsequent launches
because Hive boxes are already on disk), then renders the correct screen
directly.

### 5. Route list (unchanged)

The route list stays the same as today:

| Path | Screen |
|---|---|
| `/` | `BookmarksScreen` |
| `/add` | `CompetitionListScreen` |
| `/competitions/:id` | `CompetitionDetailScreen` |
| `/about` | `AboutScreen` |
| `/settings/xcsoar-directory` | `XcsoarDirectorySettingsScreen` |

### 6. Edge cases

All edge cases are handled by the logic in step 4:

- **No stored ID** (first launch): `lastId` is `null` → home screen.
- **Stored ID no longer bookmarked**: `stillBookmarked` is `false` → home
  screen silently.
- **Box open error**: either `AsyncError` branch → home screen silently.
- **Only one bookmark**: the stored ID matches → auto-navigate always fires.

## Acceptance criteria

- [ ] Opening the Competition Detail screen for the first time writes its ID to
  the `"settings"` Hive box under key `lastViewedCompetitionId`.
- [ ] On the next cold start, if that competition is still bookmarked, the app
  opens directly on the Competition Detail screen with no visible flash of the
  home screen.
- [ ] If the competition has been un-bookmarked between sessions, the app opens
  on the home screen with no error, toast, or log output related to the stale
  ID.
- [ ] If no ID has ever been stored, the app behaves exactly as before (home
  screen).
- [ ] `flutter analyze` reports no issues.
- [ ] `flutter test` passes, including:
  - Unit tests for `LastViewedLocalDataSource.readLastViewedId` (returns `null`
    when empty, returns stored value when set) and
    `LastViewedLocalDataSource.writeLastViewedId` (value is readable after
    write).
  - A widget test asserting that navigating to `CompetitionDetailScreen` causes
    `lastViewedLocalDataSourceProvider` to be called with the correct ID.
  - A widget test for the `CompmanApp` startup behavior: when both boxes are
    loaded and a matching bookmark exists, the router is created with
    `initialLocation = '/competitions/<id>'`; when no match exists, with
    `initialLocation = '/'`.

## Documentation to update

- **`docs/features/competitions.md`** — add a "Last-Viewed Competition" section
  describing the `LastViewedLocalDataSource`, the `settingsBoxProvider`, the
  write in `CompetitionDetailScreen`, and the startup redirect logic.
- **`docs/plan.md`** — mark the new item as done (add it under Phase 1 or as a
  Phase 1.5 QoL item, whichever fits the existing structure, and mark ✅).
- **`docs/architecture.md`** — note that `lib/core/storage/` is the location
  for non-feature-specific local persistence helpers, and that the settings Hive
  box is opened alongside the bookmarks box in `core/di/providers.dart`.

## Constraints

- Do not add any new pub dependencies.
- Do not store the last-viewed ID inside `BookmarkedCompetitionModel` or as a
  new `HiveField` on that model (the next free field index is 10; reserve it for
  bookmarks-feature data).
- The write in `CompetitionDetailScreen` must be fire-and-forget — never block
  the UI or show a loading/error state.
- All router-level decisions must be silent on error — no snackbars, no toasts,
  no print statements.
- Follow all rules in `AGENTS.md`: Dart doc on every new public symbol, no
  `setState` in feature screens, `///` comments on providers.

## Reference

User story: `2026-05-01-remember-competiton.md`
