# Add Competition Screen Visual Redesign

## Feature summary

Redesign `CompetitionListScreen`
(`lib/features/competitions/presentation/screens/competition_list_screen.dart`)
to match `docs/design/add_competition_updated/`. The screen gets a pill-shaped search
bar, flat checkbox list rows separated by hairline dividers, inline status badges, and
the Done action moves fully into the AppBar.

## Scope

`competition_list_screen.dart` and `competition_card.dart` only. Depends on:
- **20260425-01** (theme tokens)
- **20260425-02** (`CompetitionStatus` on `Competition`)
- **20260425-06** (shared widgets: `StatusBadge`, `AppBadge`, `TwoToneCard`, `IconMetaRow`)

---

## Task

Read these files before starting:

- `lib/features/competitions/presentation/screens/competition_list_screen.dart`
- `lib/features/competitions/presentation/widgets/competition_card.dart`
- `docs/design/add_competition_updated/code.html`

---

### 1 — AppBar changes

- Remove the `bottom: PreferredSize(...)` search bar from the `AppBar`.
- Keep the back arrow (default via `AppBar`).
- Add a `Done` `TextButton` (or `ElevatedButton`) as an AppBar `action`:
  ```dart
  TextButton(
    onPressed: _onDone,
    child: const Text('Done'),
    style: TextButton.styleFrom(foregroundColor: Colors.white),
  )
  ```
- Remove the bottom navigation bar (`bottomNavigationBar`) entirely. The Back button
  in the AppBar handles cancellation; Done is in the AppBar action.

### 2 — Pill search bar in body

Add the search bar as the first element in the body `Column` (or as a `Padding` widget
above the `ListView`):

```
16px horizontal margin
height: 48
background: white
border: 1px outlineVariant (via InputDecoration border)
borderRadius: full (e.g. 999px / 24px minimum)
prefixIcon: Icons.search (onSurfaceVariant color)
hintText: 'Search competitions...'
```

Preserve existing `onChanged` filtering logic.

### 3 — Replace `CompetitionCard` with flat checkbox rows

Replace the existing card-based layout in `competition_card.dart` with a flat row:

- No `Card` wrapping, no margin.
- `InkWell` tap area covering the full row (16px horizontal, 16px vertical padding).
- Leading `Checkbox` widget, `value: isSelected`, `onChanged: (_) => onTap()`,
  `activeColor: colorScheme.primary`.
- Content column:
  - Row: title (`textTheme.bodyLarge` bold) + `StatusBadge` (if `competition.status != null`), 8px gap.
    - `StatusBadge` is imported from issue **20260425-06**. Do not redefine it here.
  - Below: `competition.description` — `textTheme.bodySmall` in `tertiary` color.
- No trailing chevron (checkbox is the selection affordance).
- Bottom `Divider()` — uses `DividerTheme` from the app theme. No custom color.
- Selected state: title changes to `colorScheme.primary` color (per design: selected items
  show title in primary blue).

Remove the private `_StatusBadge` widget from `competition_card.dart` — use
`StatusBadge` from `lib/features/competitions/presentation/widgets/status_badge.dart` instead.

### 4 — Empty search state

If `filtered.isEmpty`, show:
```dart
Center(
  child: Padding(
    padding: const EdgeInsets.all(32),
    child: Text(
      'No competitions found.',
      style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
      textAlign: TextAlign.center,
    ),
  ),
)
```
(This already exists; ensure it uses the updated style.)

### 5 — Tests

Update the `CompetitionListScreen` widget test (or `CompetitionCard` test):
- Renders a `Checkbox` for each item.
- Tapping an item toggles selection and updates the checkbox.
- Done button appears in AppBar.
- Search filters items correctly.

---

## Completion condition

`make test` passes. The Add Competition screen shows a pill search bar, flat checkbox
rows with status badges, and a Done button in the AppBar with no bottom navigation bar.
