# Design Tokens: Update App Theme to Match Design System

## Feature summary

New design screens and a full design token specification have been added in `docs/design/`.
This issue brings `lib/core/theme/app_theme.dart` into alignment with those tokens: correct
color palette, Inter typography, updated card/button shapes, and revised status-badge colors.
All subsequent screen redesign issues (20260425-03 through 20260425-05) depend on this
foundation being in place first.

## Scope

Only `lib/core/theme/app_theme.dart`, `pubspec.yaml`, and
`docs/ui-guidelines.md` (badge color table). No screen or widget files.

---

## Task

Read `docs/design/design.md` and `docs/design/tokens.md` before starting.

### 1 — Add Inter font via `google_fonts`

Add to `pubspec.yaml` dependencies:

```yaml
google_fonts: ^6.2.1
```

Run `make deps` to update `pubspec.lock`.

In `AppTheme.light()` set the text theme using Inter:

```dart
import 'package:google_fonts/google_fonts.dart';

// Inside ThemeData(...)
textTheme: GoogleFonts.interTextTheme(),
```

### 2 — Update ColorScheme

Replace the current `colorSchemeSeed` approach with an explicit `ColorScheme` built from
the design token values in `docs/design/design.md`. Key values:

| Token | Hex |
|---|---|
| primary | `#006591` |
| onPrimary | `#ffffff` |
| primaryContainer | `#0ea5e9` |
| onPrimaryContainer | `#003751` |
| secondary | `#505f76` |
| onSecondary | `#ffffff` |
| secondaryContainer | `#d0e1fb` |
| onSecondaryContainer | `#54647a` |
| tertiary | `#5c5f61` |
| onTertiary | `#ffffff` |
| tertiaryContainer | `#999c9e` |
| onTertiaryContainer | `#303436` |
| error | `#ba1a1a` |
| onError | `#ffffff` |
| errorContainer | `#ffdad6` |
| onErrorContainer | `#93000a` |
| surface / background | `#f9f9ff` |
| onSurface / onBackground | `#111c2d` |
| onSurfaceVariant | `#3e4850` |
| outline | `#6e7881` |
| outlineVariant | `#bec8d2` |
| surfaceContainerLowest | `#ffffff` |
| surfaceContainerLow | `#f0f3ff` |
| surfaceContainer | `#e7eeff` |
| surfaceContainerHigh | `#dee8ff` |
| surfaceContainerHighest | `#d8e3fb` |

Use `ColorScheme.fromSeed(seedColor: const Color(0xFF006591)).copyWith(...)` and override
with the values above. Keep `useMaterial3: true`.

### 3 — Update `AppColors` badge tokens

The new design changes badge colors significantly. Status badges now use the standard
Material 3 color-role pairs from the updated ColorScheme (Live → primary,
Upcoming → secondaryContainer, Past → tertiaryContainer, New Update → error).

Update `AppColors` to add per-badge text colors and correct backgrounds:

```dart
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    // Badge backgrounds
    required this.badgeLive,
    required this.badgeUpcoming,
    required this.badgePast,
    required this.badgeNew,
    // Badge foreground text colors
    required this.badgeLiveText,
    required this.badgeUpcomingText,
    required this.badgePastText,
    required this.badgeNewText,
  });

  final Color success;
  final Color badgeLive;
  final Color badgeUpcoming;
  final Color badgePast;
  final Color badgeNew;
  final Color badgeLiveText;
  final Color badgeUpcomingText;
  final Color badgePastText;
  final Color badgeNewText;
  // ... copyWith / lerp updated accordingly
}
```

Set values in `AppTheme.light()`:

| Field | Value | Note |
|---|---|---|
| `success` | `Color(0xFF059669)` | Emerald 600 |
| `badgeLive` | `Color(0xFF006591)` | primary |
| `badgeLiveText` | `Colors.white` | |
| `badgeUpcoming` | `Color(0xFFD0E1FB)` | secondary-container |
| `badgeUpcomingText` | `Color(0xFF54647A)` | on-secondary-container |
| `badgePast` | `Color(0xFF999C9E)` | tertiary-container |
| `badgePastText` | `Color(0xFF303436)` | on-tertiary-container |
| `badgeNew` | `Color(0xFFBA1A1A)` | error (design uses error color for "NEW UPDATE") |
| `badgeNewText` | `Colors.white` | |

Remove the old `badgeOnDark` field. Fix any compilation errors in widget files that
referenced it — at this stage the only user is `competition_card.dart`; update its
`_StatusBadge` to use `appColors.badgeUpcomingText` instead of `appColors.badgeOnDark`.

### 4 — Update card and button themes

Cards (per design: white background, 1px `outlineVariant` border, 12px radius, minimal shadow):

```dart
cardTheme: CardThemeData(
  elevation: 0,
  color: Colors.white,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: const BorderSide(color: Color(0xFFBEC8D2)),
  ),
),
```

Primary `ElevatedButton` (48px height, 8px radius per design):

```dart
elevatedButtonTheme: ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
    minimumSize: const Size.fromHeight(48),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
  ),
),
```

`OutlinedButton` and `TextButton` — update `shape` to `BorderRadius.circular(8)`.

### 5 — Update `docs/ui-guidelines.md`

In the Status Badges table, update the **Text** column to reflect per-badge text colors:

| Status | Label | Token | Text |
|---|---|---|---|
| Live | `Live` | `appColors.badgeLive` | `appColors.badgeLiveText` (white) |
| Upcoming | `Upcoming` | `appColors.badgeUpcoming` | `appColors.badgeUpcomingText` (dark) |
| Past | `Past` | `appColors.badgePast` | `appColors.badgePastText` (dark) |
| New / Updated | `New Update` | `appColors.badgeNew` | `appColors.badgeNewText` (white) |

---

### 6 — Add `AppBarTheme`

All screens share the same AppBar style. Define it once in `AppTheme.light()` so no
screen needs to set AppBar colors individually:

```dart
appBarTheme: AppBarTheme(
  backgroundColor: Colors.white,          // surfaceContainerLowest
  foregroundColor: const Color(0xFF111C2D), // onSurface
  elevation: 0,
  scrolledUnderElevation: 0,
  shape: Border(
    bottom: BorderSide(color: const Color(0xFFBEC8D2)), // outlineVariant
  ),
),
```

### 7 — Add `DividerTheme`

Standardize the hairline divider used between list rows and inside cards. Define once:

```dart
dividerTheme: const DividerThemeData(
  color: Color(0xFFBEC8D2),  // outlineVariant — full opacity, no per-site withOpacity
  thickness: 1,
  space: 1,
),
```

All `Divider()` widgets across the app will now pick up this style automatically.
No widget code should pass a custom `color` or `thickness` to `Divider()` unless it
genuinely deviates from the standard.

### 8 — Add `AppButtonStyles` helper

Add an `AppButtonStyles` class to `lib/core/theme/app_theme.dart` for named button
styles that don't map to the standard elevated/outlined/text button hierarchy:

```dart
/// Named button style helpers for non-standard button variants.
abstract final class AppButtonStyles {
  /// Ghost/utility button: white background, primary-colored border and text,
  /// compact 11sp bold text. Use for secondary file-operation actions
  /// (e.g. "Install" on airspace/waypoints cards).
  static ButtonStyle ghost(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return OutlinedButton.styleFrom(
      foregroundColor: primary,
      backgroundColor: Colors.white,
      side: BorderSide(color: primary.withValues(alpha: 0.3)),
      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
```

Usage: `OutlinedButton(style: AppButtonStyles.ghost(context), onPressed: ..., child: const Text('INSTALL'))`.

---

## Completion condition

`make analyze` passes with no errors. `make test` passes. The app renders with an
Inter font, a sky-blue primary color, white AppBars with a bottom border, and the
updated badge token values visible in the competition card widget.
