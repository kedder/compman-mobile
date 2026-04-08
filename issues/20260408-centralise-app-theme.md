# Centralise App Theme

## Feature summary

The app currently has all styling (colours, typography weights, spacing) hardcoded
inline across individual widgets and screens. This makes it impossible to make a
global style change without hunting through every file. The goal is to extract all
style values into a single `AppTheme` definition consumed via Flutter's theme
system, so the entire app's look can be changed in one place and the codebase is
ready for a future dark-mode variant.

## Scope

This issue covers:

1. Creating `lib/core/theme/app_theme.dart` — a `ThemeData` factory that encodes
   all design tokens from `docs/ui-guidelines.md`.
2. A `AppColors` `ThemeExtension` for tokens that live outside standard
   `ColorScheme` / `ThemeData` slots (status badge colours, success snackbar
   colour).
3. Replacing every hardcoded style in existing files with theme lookups.
4. Updating `docs/architecture.md` and `docs/ui-guidelines.md` to reflect the new
   pattern.

It does **not** cover dark mode implementation — that comes later. The single
`AppTheme.light()` factory must be structured so a future `AppTheme.dark()` can be
added without touching any widget code.

---

## Design tokens to encode

Source of truth: `docs/ui-guidelines.md`.

### `ColorScheme` / `ThemeData` slots

| Token | Current inline value | Target slot |
|---|---|---|
| Primary / seed | `Color(0xFF0D7FC1)` | `colorScheme.primary` (keep `colorSchemeSeed`) |
| Destructive / error | `Colors.red.shade700` | `colorScheme.error` |
| Secondary text / subdued | `Colors.grey.shade600` | `colorScheme.onSurfaceVariant` |
| Unselected icon | `Colors.grey.shade400` | `colorScheme.outline` |
| Card shadow base | `Colors.black.withValues(alpha: 0.06)` | keep inline but derive from `colorScheme.shadow` |
| Success SnackBar | `Color(0xFF2E7D32)` | `AppColors.success` extension |

### `AppColors` extension (status badge colours + success)

Define a `ThemeExtension<AppColors>` in `lib/core/theme/app_theme.dart`:

```dart
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.badgeLive,
    required this.badgeUpcoming,
    required this.badgePast,
    required this.badgeNew,
    required this.badgeOnDark,   // text on coloured badges (white / black)
  });

  final Color success;
  final Color badgeLive;
  final Color badgeUpcoming;
  final Color badgePast;
  final Color badgeNew;
  final Color badgeOnDark;
  // ...copyWith / lerp as required by ThemeExtension
}
```

Light values:

| Field | Value |
|---|---|
| `success` | `Color(0xFF2E7D32)` |
| `badgeLive` | `Color(0xFF2E7D32)` |
| `badgeUpcoming` | `Color(0xFF1565C0)` |
| `badgePast` | `Color(0xFF757575)` |
| `badgeNew` | `Color(0xFFF9A825)` |
| `badgeOnDark` | `Colors.white` (live/upcoming/past) or `Colors.black` (new) — encode as separate fields if needed |

### `TextTheme` and component themes

- `ElevatedButton` label: bold, 16 sp → set via `ElevatedButtonThemeData`
- `OutlinedButton` + `TextButton` base styles → set via their respective theme datas
- Body text minimum 16 sp is already enforced by `useMaterial3: true` defaults;
  verify it holds and document the verification result in a code comment.

### `CardTheme`

Set `elevation: 2` as the default so individual `Card` widgets don't repeat it.

---

## Files to create

```
lib/core/theme/
  app_theme.dart      # ThemeData factory + AppColors extension
```

---

## Files to modify

| File | Change |
|---|---|
| `lib/app.dart` | Replace inline `ThemeData(...)` with `AppTheme.light()` |
| `lib/core/platform/xcsoar_directory_settings_screen.dart` | Replace `Colors.red.shade700` → `colorScheme.error`; `Color(0xFF2E7D32)` SnackBar → `AppColors.success`; inline `TextStyle(fontWeight: …, fontSize: 16)` → `theme.textTheme.labelLarge` or the ElevatedButton default |
| `lib/core/platform/saf_test_screen.dart` | Replace `Colors.green` → `AppColors.success`; `Colors.red` → `colorScheme.error` |
| `lib/features/competitions/presentation/screens/bookmarks_screen.dart` | Replace `Colors.red.shade700` → `colorScheme.error`; `Colors.grey.shade600` → `colorScheme.onSurfaceVariant` |
| `lib/features/competitions/presentation/screens/competition_detail_screen.dart` | Replace `Colors.grey.shade600` → `colorScheme.onSurfaceVariant`; `Color(0xFF2E7D32)` SnackBar → `AppColors.success`; `Colors.red.shade700` → `colorScheme.error` |
| `lib/features/competitions/presentation/widgets/competition_card.dart` | Replace `Colors.grey.shade600` → `colorScheme.onSurfaceVariant`; `Colors.grey.shade400` → `colorScheme.outline`; `Color(0xFF1565C0)` badge colour → `appColors.badgeUpcoming`; `Colors.white` badge text → `appColors.badgeOnDark` |

---

## Accessing AppColors in widgets

```dart
final appColors = Theme.of(context).extension<AppColors>()!;
```

Add a convenience getter if you find it repeated more than twice:

```dart
// in app_theme.dart
extension AppColorsContext on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
```

---

## Docs to update

- **`docs/architecture.md`** — add `lib/core/theme/` to the folder-structure section
  and a short note: "All visual tokens live in `AppTheme`. Widgets must consume
  colours via `Theme.of(context).colorScheme` or `AppColors`. Hardcoded `Colors.*`
  values are not permitted except for transparent/black/white used as modifiers
  (e.g. shadow alpha)."
- **`docs/ui-guidelines.md`** — replace the raw hex values in the *Visual Theme*
  and *Status Badges* sections with references to the token names (`appColors.success`,
  `colorScheme.error`, etc.). Keep the hex values in parentheses for human reference.
  Add a note: "Always use theme tokens — never hardcode colour literals in widget code."

---

## Acceptance criteria

- `flutter analyze` passes with no warnings.
- `flutter test` passes (no widget test changes expected; update any test that
  constructs a widget tree without a `Theme` ancestor to wrap it in
  `Theme(data: AppTheme.light(), child: …)`).
- A global search for `Colors.red`, `Colors.green`, `Colors.grey`, `Color(0xFF2E7D32)`,
  `Color(0xFF1565C0)`, `Color(0xFF757575)`, `Color(0xFFF9A825)` in `lib/` returns
  **zero hits** outside `app_theme.dart` itself.
- `docs/architecture.md` and `docs/ui-guidelines.md` are updated as described above.
- `docs/plan.md` is updated: mark this task ✅ with a brief note.

---

## General rules

Follow all rules in [CLAUDE.md](../CLAUDE.md). Add `///` doc comments to all public
members of `AppTheme` and `AppColors`. Commit as a single atomic commit with message:

```
feat(theme): centralise app theme tokens into AppTheme and AppColors
```
