# Task Panel Font Size Adjustments

The task panel in the competition detail screen currently has an inverted visual hierarchy. The "Day X - Task Y" header is very large, while the actual task details (like "Racing Task 320km") are small metadata. Following the design principles in `docs/design/design.md` and the visual hierarchy seen in `docs/design/your_competitions_text_only/code.html`, we need to flip this.

## Summary
Adjust the typography in the `_TaskCard` widget to emphasize the task details (the specific task title/length) and de-emphasize the day/task number.

## Scope
- **Modify `lib/core/widgets/icon_meta_row.dart`**:
    - Support an optional `TextStyle? style` parameter.
    - If provided, this style should override the default `bodySmall`.
- **Update `lib/features/competitions/presentation/screens/competition_detail_screen.dart`**:
    - In `_TaskCard`, change the "Day ${task.dayNo} - Task ${task.taskNo}" style from `headlineMedium` to `titleMedium` (or `titleSmall`).
    - In `_TaskCard`, update the `IconMetaRow` for `task.title` to use `headlineSmall` (or `titleLarge`) and ensure it remains `colorScheme.primary`.
    - Adjust spacing (e.g., `SizedBox(height: 8)`) as needed to maintain a clean layout with the new sizes.

## Design Reference
- `docs/design/your_competitions_text_only/code.html`: Shows bold, prominent titles for primary information.
- `docs/design/your_competitions_empty/screen.png`: Illustrates the intended clear hierarchy between primary titles and secondary descriptions.
- `docs/design/design.md`: "Hierarchy through Weight: High-contrast weights (400 vs 700) are used instead of massive scale shifts to maintain density."

## Rules & Constraints
- **Do not** hardcode font sizes. Use `Theme.of(context).textTheme` styles.
- The task title/length is the most important information in this card and should be the most prominent.
- Follow all standards in `AGENTS.md`.

## Acceptance Criteria
- [ ] `IconMetaRow` text style can be customized via a `style` parameter.
- [ ] In `_TaskCard`, the "Racing Task..." (or similar) text is significantly larger and more prominent than the "Day X - Task Y" text.
- [ ] The "Day X - Task Y" text uses a "Title" or "Body" level style rather than a "Headline" level style.
- [ ] The layout remains balanced and fits within the `TwoToneCard` header area without clipping.
- [ ] Code is formatted according to project standards (`make format`).
- [ ] All tests pass (`make test`).
- [ ] Static analysis (`make analyze`) is clean.
