# Competition Class Picker Visual Redesign

## Feature summary

Redesign the `_ClassPicker` widget inside `competition_detail_screen.dart` to match
`docs/design/competition_details_class_selection/code.html`. The picker is shown inline
on the Competition Detail screen when the user has not yet chosen a class. It currently
renders a plain list of text buttons; the new design uses full-width card-style buttons
with a trophy icon and a chevron, and a styled section heading.

## Scope

`_ClassPicker` widget in
`lib/features/competitions/presentation/screens/competition_detail_screen.dart` only.
No routing changes, no domain changes, no new files. Depends on:
- **20260425-01** (theme tokens, `AppColors`)
- **20260425-06** (shared widgets: `AppBadge`, `TwoToneCard`, `IconMetaRow`)

---

## Task

Read these files before starting:

- `lib/features/competitions/presentation/screens/competition_detail_screen.dart`
  (focus on `_ClassPicker` and `classesAsync.when(...)` section)
- `docs/design/competition_details_class_selection/code.html`
- `docs/ui-guidelines.md`

---

### 1 — Section heading

Replace the existing `titleMedium` "Select your class" text with:

```dart
Text(
  'Select your class',
  style: textTheme.headlineMedium,
)
```

(`headlineMedium` — matching the design's `font-headline-md` style.)

---

### 2 — Class list items

Replace each plain `TextButton` (or equivalent) class option with a full-width
`OutlinedButton`-style card:

```dart
InkWell(
  onTap: () => _selectClass(ref, competitionId, className),
  borderRadius: BorderRadius.circular(8),
  child: Container(
    decoration: BoxDecoration(
      color: colorScheme.surface,
      border: Border.all(color: colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        Icon(Icons.emoji_events_outlined, color: colorScheme.outline),
        const SizedBox(width: 12),
        Expanded(
          child: Text(className, style: textTheme.headlineMedium),
        ),
        Icon(Icons.chevron_right, color: colorScheme.outline),
      ],
    ),
  ),
)
```

Use `Icons.emoji_events_outlined` as the trophy icon (`emoji_events` maps to the
`trophy` Material Symbol used in the design). Spacing between cards: `SizedBox(height: 12)`.

---

### 3 — Loading and error states

Keep the existing `CircularProgressIndicator` for loading. Keep the existing `_ErrorRetry`
for the error state. Only the loaded (class list) state changes visually.

---

### 4 — Tests

Update or add widget tests for `_ClassPicker`:
- Each available class name renders as a card with its name and a chevron icon.
- Tapping a card calls the class-selection action.
- The section heading shows "Select your class".

---

## Completion condition

`make format`, `make analyze`, and `make test` all pass. When no class is selected on
the Competition Detail screen, the class picker shows styled card buttons with trophy
icons and chevrons matching `competition_details_class_selection/code.html`.
