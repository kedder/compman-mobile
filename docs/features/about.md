# About Screen

## Purpose

Communicates app identity, authorship, version, and data-source attribution to the user.

## Route and widget

| Property | Value |
|---|---|
| Route | `/about` |
| Widget | `AboutScreen` in `lib/app.dart` |

Navigated to from the three-dot menu on the home (`BookmarksScreen`) screen.

## Layout

The screen is a `ListView` with four sections:

1. **Identity block** — centered column with app icon (96 dp), app name (`headlineMedium`), one-sentence description (`bodyLarge`), and runtime version string (`labelSmall`).
2. **Author row** — non-tappable `ListTile`: "Written by Andrey Lebedev".
3. **Source & bug reports row** — tappable `ListTile` that opens `https://github.com/kedder/compman-mobile` in an external browser.
4. **Data sources section** — section header label followed by two tappable `ListTile` rows:
   - *Competition data* → `https://www.soaringspot.com/`
   - *XCSoar tasks* → `https://soarscore.com/`

All tappable rows carry `Icons.open_in_new` as the trailing icon.

## State

The version string is loaded from `packageInfoProvider` (`package_info_plus`).  
While loading, a `CircularProgressIndicator` is shown in place of the full body.  
On error, `"Version unavailable"` is shown instead.

## Dependencies

| Package | Purpose |
|---|---|
| `package_info_plus` | Runtime app version |
| `url_launcher` | Open external URLs |

## Assets

`assets/icon/app_icon.png` is registered under `flutter: assets:` in `pubspec.yaml` and displayed at 96 × 96 dp in the identity block.
