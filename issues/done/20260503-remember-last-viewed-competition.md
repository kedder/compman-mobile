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
2. A new `settingsBoxProvider` (`FutureProvider<Box<String>>`) in
   `lib/core/di/providers.dart` for the settings Hive box.
3. Converting `CompetitionDetailScreen` from a `ConsumerWidget` to a
   `ConsumerStatefulWidget` so `initState` can fire-and-forget write the ID.
4. Extending `main()` to open both Hive boxes before `runApp`, compute
   `initialLocation`, and pass it to `CompmanApp` as a constructor parameter.
   `CompmanApp` stays a `StatelessWidget`.
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

No `lastViewedLocalDataSourceProvider` or `lastViewedIdProvider` is needed.
Both `main()` and `CompetitionDetailScreen.initState` use `LastViewedLocalDataSource`
directly (see sections 3 and 4). `settingsBoxProvider` is overridden with
`AsyncData(settingsBox)` in `main()` before `runApp`, so its async body never
executes in production.

### 3. Write last-viewed ID from the detail screen

Convert `CompetitionDetailScreen` from `ConsumerWidget` to
`ConsumerStatefulWidget`. In `initState`, use a **guarded** write that only
acts when the settings box is already open:

```dart
@override
void initState() {
  super.initState();
  ref.read(settingsBoxProvider).whenData((box) {
    LastViewedLocalDataSource(box).writeLastViewedId(widget.competitionId);
  });
}
```

The guard is critical for testability: in production, `main()` opens the
settings box before `runApp` and overrides `settingsBoxProvider` with
`AsyncData(settingsBox)`, so `whenData` fires immediately on the first frame.
In any widget test that does not override `settingsBoxProvider`, the provider
stays in `AsyncLoading` and `whenData` silently no-ops — no platform channel,
no Hive timer, no deadlock.

Note that `ref` is available in `ConsumerState.initState` as `this.ref`.
The rest of `CompetitionDetailScreen.build` is unchanged.

### 4. Resolve the initial route in `main()`

Instead of refactoring `CompmanApp` into a stateful widget, move all startup
logic into `main()` before `runApp`. Both Hive boxes open in single-digit
milliseconds on subsequent launches (they are already on disk), so no spinner
is needed.

Extend `main.dart` as follows:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(BookmarkedCompetitionModelAdapter());
  }
  final bookmarksBox =
      await Hive.openBox<BookmarkedCompetitionModel>('bookmarks');
  final settingsBox = await Hive.openBox<String>('settings');

  String initialLocation = '/';
  final lastId = LastViewedLocalDataSource(settingsBox).readLastViewedId();
  if (lastId != null && bookmarksBox.values.any((m) => m.id == lastId)) {
    initialLocation = '/competitions/$lastId';
  }

  runApp(ProviderScope(
    overrides: [
      bookmarksBoxProvider.overrideWithValue(AsyncData(bookmarksBox)),
      settingsBoxProvider.overrideWithValue(AsyncData(settingsBox)),
    ],
    child: CompmanApp(initialLocation: initialLocation),
  ));
}
```

`CompmanApp` gains an `initialLocation` constructor parameter and stays a
`StatelessWidget`. Its `build` method passes `initialLocation` to the router:

```dart
class CompmanApp extends StatelessWidget {
  const CompmanApp({super.key, required this.initialLocation});

  final String initialLocation;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Compman Mobile',
      theme: AppTheme.light(),
      routerConfig: _buildRouter(initialLocation),
    );
  }
}
```

Move the `GoRouter` definition (routes list) into a private top-level function
`_buildRouter(String initialLocation)` so routes are defined once and the
module-level `_router` constant is removed.

The `overrideWithValue(AsyncData(...))` calls ensure that every downstream
provider that watches `bookmarksBoxProvider` or `settingsBoxProvider`
(including `competitionsLocalDataSourceProvider`) resolves synchronously for
the entire lifetime of the app.

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

### 7. Testing patterns and constraints

> **Background:** the first implementation attempt produced tests that hung
> indefinitely. Two root causes were identified. The design in sections 3 and 4
> above structurally prevents both.

#### Root cause 1 — FakeAsync + Hive write timer = deadlock

`testWidgets` wraps every test body in Flutter's `FakeAsync` zone. `FakeAsync`
intercepts all `Timer` objects — they only advance when the test explicitly calls
`tester.pump(Duration)` or `tester.pumpAndSettle()`. Hive's `box.put()` uses an
internal debounce timer to batch writes:

```
await box.put(key, value)   // inside a testWidgets body
  └─ waits for a Future
       └─ whose completion depends on a Timer
            └─ that will never fire  ← FakeAsync freezes it
                 └─ DEADLOCK — test hangs forever
```

**Mitigation:** the `initState` guard (section 3) uses `whenData` which fires
synchronously when the provider already holds `AsyncData`. In any widget test
that does not override `settingsBoxProvider`, the provider stays in
`AsyncLoading` and `whenData` never fires — Hive is never touched at all.
For the one test that deliberately exercises the write path, `settingsBoxProvider`
is overridden with `AsyncData(_FakeStringBox())` (an in-memory implementation)
so no real Hive write occurs inside the `testWidgets` body.

#### Root cause 2 — `initState` silently acquires a new Hive dependency

If `initState` reads a provider that transitively calls `Hive.initFlutter()`,
every widget test that renders that screen acquires an unexpected platform-channel
dependency, leading to `MissingPluginException` or unpredictable latency.

**Mitigation:** the `whenData` guard (section 3) never triggers the provider to
*start* loading — it only acts on a value that is already present. Tests without
an override see `AsyncLoading`; `whenData` is a no-op.

#### Unit tests for `LastViewedLocalDataSource`

Separate unit tests are not required. The two one-liner methods are covered
indirectly by the `CompetitionDetailScreen` widget test that verifies the write
(see below). If the implementer wishes to add plain `test()` (not `testWidgets`)
tests with a real temp-directory Hive box, that is acceptable — but not
mandated.

#### Widget tests — `CompetitionDetailScreen`

Pre-existing tests require **no changes**: the `whenData` guard silently no-ops
when `settingsBoxProvider` is not overridden.

For the new test that asserts the write happened, define `_FakeStringBox` once
at the top of `competition_detail_screen_test.dart`:

```dart
/// In-memory fake — no Hive, no timer, no platform channel.
class _FakeStringBox extends Fake implements Box<String> {
  final Map<String, String> store = {};

  @override
  Future<void> put(dynamic key, String value) async {
    store[key as String] = value;
  }
}
```

Then in the write-verification test:

```dart
final fakeBox = _FakeStringBox();
await tester.pumpWidget(_buildApp([
  ...baseOverrides,
  settingsBoxProvider.overrideWithValue(AsyncData(fakeBox)),
]));
await tester.pump(); // let initState run
expect(fakeBox.store['lastViewedCompetitionId'], _competitionId);
```

#### Widget tests — `CompmanApp`

Because `CompmanApp` now accepts `initialLocation` as a constructor parameter,
tests simply construct the widget with the desired value — no provider overrides,
no Hive I/O:

```dart
await tester.pumpWidget(
  ProviderScope(child: CompmanApp(initialLocation: '/competitions/test-id')),
);
// assert CompetitionDetailScreen is rendered

await tester.pumpWidget(
  ProviderScope(child: const CompmanApp(initialLocation: '/')),
);
// assert BookmarksScreen is rendered
```

---

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
  - A widget test for `CompetitionDetailScreen` overrides `settingsBoxProvider`
    with `AsyncData(_FakeStringBox())` and asserts that `fakeBox.store` contains
    the correct competition ID after pumping. Pre-existing tests need no changes —
    the `whenData` guard silently no-ops when `settingsBoxProvider` is not
    overridden.
  - Widget tests for `CompmanApp` construct `CompmanApp(initialLocation: '/competitions/<id>')`
    and `CompmanApp(initialLocation: '/')` directly and assert the correct screen
    is rendered. No provider overrides or Hive I/O are involved.

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
- **Widget-test rule — Hive:** Never `await` a real `Box.put()` / `Box.clear()`
  inside a `testWidgets` body. `FakeAsync` intercepts Hive's internal
  write-batching `Timer`, creating a deadlock. Supply a `_FakeStringBox`
  (`class _FakeStringBox extends Fake implements Box<String>`, implementing only
  the methods the test uses) via
  `settingsBoxProvider.overrideWithValue(AsyncData(fakeBox))`.

## Reference

User story: `2026-05-01-remember-competiton.md`
