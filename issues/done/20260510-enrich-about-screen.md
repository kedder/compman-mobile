# Enrich About Screen with App Info, Attribution, and GitHub Link

## Feature summary

The `/about` route (`AboutScreen` in `lib/app.dart`) is currently minimal: it shows only the
app name, runtime version, and a single "Data provided by SoaringSpot" line.  The goal is to
make it a complete, informative page that communicates app identity, authorship, and data-source
transparency — no new navigation, no new domain layer, no async complexity beyond the existing
`packageInfoProvider`.

User story: `issues/userstories/2026-05-10-about.md`

## Scope

This issue covers **one screen and its surrounding setup work**:

- Register `assets/icon/app_icon.png` in `pubspec.yaml`.
- Add the `url_launcher` dependency to `pubspec.yaml` (already present — verify it is not
  accidentally missing, and add if needed).
- Rewrite `AboutScreen` in `lib/app.dart` with the full layout described below.
- Create `docs/features/about.md`.
- Update `docs/plan.md`.

No other screens, routes, providers, or domain files require changes.

## Task

### 1. Register the app-icon asset

In `pubspec.yaml`, uncomment/replace the commented-out `assets:` block under `flutter:`:

```yaml
flutter:
  assets:
    - assets/icon/app_icon.png
```

`app_icon_foreground.png` is consumed by the Android build toolchain only — do **not** add it
to the Flutter asset bundle.

### 2. Verify `url_launcher` dependency

`url_launcher: ^6.3.2` is already listed in `pubspec.yaml` dependencies.  Confirm it is
present; if somehow missing, add it.  No additional Android/iOS manifest changes are needed
for this package at `^6.3.2`.

### 3. Rewrite `AboutScreen`

Replace the current `AboutScreen` implementation in `lib/app.dart` with the layout below.
Keep `AboutScreen` in `app.dart` — do not move it to a separate file.

#### Overall structure

`Scaffold` with `AppBar(title: const Text('About'))` and a `body` of
`ListView` (or `SingleChildScrollView` wrapping a `Column`). The list has no interactive
items at the top level; it contains the sections described below.

#### Section 1 — App identity block

A centered `Column` with `EdgeInsets.symmetric(vertical: 24, horizontal: 16)` padding.
Content from top to bottom:

1. **App icon** — `Semantics(label: 'App icon', excludeSemantics: true, child: Image.asset('assets/icon/app_icon.png', width: 96, height: 96))`.
2. `SizedBox(height: 16)`
3. **App name** — `Text('Competition Manager Mobile', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center)`.
   `headlineMedium` maps to ~24 sp bold in the Material 3 scale, satisfying the "headline-lg"
   token from the design tokens.
4. **Short description** — `Text` (centered, `bodyLarge`, 16 sp):
   > "An Android app for glider pilots. Browse competitions, bookmark the ones you attend, and
   > download waypoint, airspace, and task files directly to XCSoar on your device."
5. `SizedBox(height: 8)`
6. **Version string** — `Text('Version ${info.version}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant), textAlign: TextAlign.center)`.

The entire identity block should be wrapped in a widget that is `padding`-ed with
`EdgeInsets.symmetric(vertical: 24, horizontal: 16)`.  All text is center-aligned.

The version string comes from the existing `packageInfoProvider`.  Keep the existing
`AsyncValue.when` pattern; during loading show a `CircularProgressIndicator` in the body;
on error show `Text('Version unavailable')`.

#### Section 2 — Author row

```dart
ListTile(
  leading: const Icon(Icons.person_outline),
  title: const Text('Written by Andrey Lebedev'),
)
```

#### Section 3 — Source code / support row

A tappable `ListTile` that opens `https://github.com/kedder/compman-mobile` in the device
browser via `url_launcher`:

```dart
ListTile(
  leading: const Icon(Icons.code),
  title: const Text('Source & bug reports'),
  subtitle: const Text('github.com/kedder/compman-mobile'),
  trailing: const Icon(Icons.open_in_new),
  onTap: () => launchUrl(
    Uri.parse('https://github.com/kedder/compman-mobile'),
    mode: LaunchMode.externalApplication,
  ),
)
```

Import `package:url_launcher/url_launcher.dart`.

#### Section 4 — Data sources

A section header followed by two tappable `ListTile` rows.

Section header (use a `Padding`-wrapped `Text` styled as `titleSmall` or `labelLarge` with
`colorScheme.onSurfaceVariant` color, with `EdgeInsets.fromLTRB(16, 16, 16, 4)` padding):

```dart
Padding(
  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
  child: Text(
    'Data sources',
    style: Theme.of(context).textTheme.labelLarge?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  ),
)
```

Competition data row:

```dart
ListTile(
  leading: const Icon(Icons.language),
  title: const Text('Competition data'),
  subtitle: const Text('soaringspot.com'),
  trailing: const Icon(Icons.open_in_new),
  onTap: () => launchUrl(
    Uri.parse('https://www.soaringspot.com/'),
    mode: LaunchMode.externalApplication,
  ),
)
```

XCSoar tasks row:

```dart
ListTile(
  leading: const Icon(Icons.language),
  title: const Text('XCSoar tasks'),
  subtitle: const Text('soarscore.com'),
  trailing: const Icon(Icons.open_in_new),
  onTap: () => launchUrl(
    Uri.parse('https://soarscore.com/'),
    mode: LaunchMode.externalApplication,
  ),
)
```

#### Design rules to enforce

- Colors from `Theme.of(context)` only; no hard-coded literals.
- No more than three type sizes on-screen (`headlineMedium`, `bodyLarge`, `labelSmall`/
  `labelLarge` — these count as three).
- All `ListTile` rows meet the 48 dp touch-target requirement by default.
- All tappable URL rows have `Icons.open_in_new` as their trailing icon.

### 4. Widget tests

Add a new test file `test/about_screen_test.dart` (or
`test/features/about/about_screen_test.dart` if you prefer feature-scoped layout).

The `packageInfoProvider` must be overridden in tests; use the same pattern as other screen
tests in the project (`ProviderScope` override with a pre-resolved `AsyncData`).

Required tests:

1. **Renders identity block** — pump `AboutScreen`, override `packageInfoProvider` to
   `AsyncData(fakeInfo)`. Assert:
   - `Image.asset` with `'assets/icon/app_icon.png'` is present in the tree.
   - `Text('Competition Manager Mobile')` is present.
   - The description text is present.
   - `Text('Version 1.0.0')` (or whatever the fake version is) is present.

2. **Renders author row** — assert `Text('Written by Andrey Lebedev')` is present.

3. **Renders source-code row** — assert `Text('Source & bug reports')` is present and the
   `Icons.open_in_new` trailing icon exists.

4. **Renders data-source rows** — assert `Text('Competition data')` and `Text('XCSoar tasks')`
   are both present.

5. **Version loading state** — override `packageInfoProvider` to `AsyncLoading()`. Assert a
   `CircularProgressIndicator` is present and `Text('Competition Manager Mobile')` is absent.

For tests that verify URL tapping, stub `url_launcher`'s channel if desired but it is
acceptable to simply assert the `ListTile` exists and is tappable (i.e., `onTap` is non-null).
Do not block on implementing a full `url_launcher` channel mock.

### 5. Documentation

#### `docs/features/about.md` (new file)

Create this file. It must cover:
- Purpose of the About screen.
- Route: `/about`, widget: `AboutScreen` in `lib/app.dart`.
- Sections displayed: identity block, author, source code link, data sources.
- Dependencies: `package_info_plus` (existing), `url_launcher` (existing).
- Asset: `assets/icon/app_icon.png` (registered in `pubspec.yaml`).

#### `docs/plan.md`

- Add a ✅ entry under Phase 1 (or at the end of Phase 1's presentation section) for the
  About screen enrichment, with a brief implementation note.

## Completion condition

- `pubspec.yaml` declares `assets/icon/app_icon.png` under `flutter: assets:`.
- `AboutScreen` renders the full layout (identity block, author row, GitHub row, data-source
  rows) as described.
- All five new widget tests pass.
- `make test` passes with no failures.
- `make analyze` reports no issues.
- `docs/features/about.md` exists and covers the points listed above.
- `docs/plan.md` is updated.
- The user story file `issues/userstories/2026-05-10-about.md` is moved to
  `issues/userstories/done/`.
