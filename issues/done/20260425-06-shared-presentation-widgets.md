# Shared Presentation Widgets

## Feature summary

Several screens in the redesign share repeated visual patterns. This issue extracts
them into reusable components in `lib/core/widgets/` so they are defined once and
evolve consistently. All screen redesign issues (20260425-03, 20260425-04,
20260425-05) depend on this issue being done first.

## Scope

Only `lib/core/widgets/`. No screen files, no feature-layer files. Depends on
**20260425-01** (theme tokens, `AppColors`, `AppButtonStyles`).

---

## Task

Read `lib/core/theme/app_theme.dart` and `docs/ui-guidelines.md` before starting.

---

### 1 — `AppBadge` — generic labelled badge primitive

Create `lib/core/widgets/app_badge.dart`:

```dart
/// A small coloured label badge used for status and update indicators.
///
/// All badge variants in the app are built on this widget. Colors must come
/// from the `ColorScheme` or `AppColors` — never hardcoded literals.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.hasRing = false,
  });

  /// The uppercase text shown inside the badge.
  final String label;

  /// Badge background color.
  final Color backgroundColor;

  /// Badge text color.
  final Color foregroundColor;

  /// When true, adds a subtle ring around the badge (used for "NEW UPDATE").
  final bool hasRing;
}
```

Rendering spec (consistent with `docs/ui-guidelines.md` badge rules):
- `Container` with `BorderRadius.circular(4)`, horizontal padding 8, vertical padding 3.
- `Text` style: 10 sp, weight 800, uppercase.
- `hasRing: true`: wrap in an additional transparent `Container` with a 2px border of
  `backgroundColor.withValues(alpha: 0.2)` and `BorderRadius.circular(6)`, 2px padding,
  to create the ring glow effect from the design.

---

### 2 — `StatusBadge` — competition status wrapper

Create `lib/features/competitions/presentation/widgets/status_badge.dart`:

```dart
/// Displays a competition status badge using [AppBadge].
///
/// Colors are sourced from [AppColors]. Label text is uppercase.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final CompetitionStatus status;
}
```

Map each `CompetitionStatus` value to an `AppBadge`:

| Status | label | backgroundColor | foregroundColor |
|---|---|---|---|
| `live` | `"LIVE"` | `appColors.badgeLive` | `appColors.badgeLiveText` |
| `upcoming` | `"UPCOMING"` | `appColors.badgeUpcoming` | `appColors.badgeUpcomingText` |
| `past` | `"PAST"` | `appColors.badgePast` | `appColors.badgePastText` |

---

### 3 — `TwoToneCard` — white-header + tinted-footer card

Create `lib/core/widgets/two_tone_card.dart`:

```dart
/// A card with a white header region and a tinted footer region, separated by
/// a hairline divider.
///
/// Follows the card spec from `docs/ui-guidelines.md`: white background,
/// 12px radius, 1px `outlineVariant` border, small shadow.
class TwoToneCard extends StatelessWidget {
  const TwoToneCard({
    super.key,
    required this.header,
    required this.footer,
  });

  /// Widget shown in the white header area (padding 12px).
  final Widget header;

  /// Widget shown in the tinted footer area (padding 12px).
  final Widget footer;
}
```

Structure:
```
ClipRRect(borderRadius: 12px,
  child: Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: colorScheme.outlineVariant),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: Offset(0, 2))],
    ),
    child: Column([
      Padding(all: 12, child: header),
      Divider(),          // picks up DividerTheme from issue 01
      ColoredBox(
        color: colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
        child: Padding(all: 12, child: footer),
      ),
    ]),
  ),
)
```

---

### 4 — `IconMetaRow` — icon + small metadata text

Create `lib/core/widgets/icon_meta_row.dart`:

```dart
/// A row pairing a small icon with a single line of metadata text.
///
/// Used for: URLs, timestamps, file names, directory paths.
/// Defaults to [colorScheme.secondary] if no [color] is provided.
class IconMetaRow extends StatelessWidget {
  const IconMetaRow({
    super.key,
    required this.icon,
    required this.text,
    this.iconSize = 16.0,
    this.color,
  });

  final IconData icon;
  final String text;
  final double iconSize;

  /// Icon and text color. Defaults to `colorScheme.secondary`.
  final Color? color;
}
```

Structure: `Row([Icon(icon, size: iconSize, color: resolved), SizedBox(width: 4), Expanded(Text(text, style: textTheme.bodySmall?.copyWith(color: resolved), overflow: ellipsis))])`.

---

### 5 — Tests

- Unit/widget test for `AppBadge`: renders label text; `hasRing: true` renders ring container.
- Widget test for `StatusBadge`: each `CompetitionStatus` renders the correct label.
- Widget test for `TwoToneCard`: header widget and footer widget both appear.
- Widget test for `IconMetaRow`: icon and text both appear; custom color is applied.

---

## Completion condition

`make test` passes. All four widgets exist, are exported, and have passing tests.
