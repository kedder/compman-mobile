# Home Screen (Bookmarks) Visual Redesign

## Feature summary

Redesign `BookmarksScreen` (`lib/features/competitions/presentation/screens/bookmarks_screen.dart`)
to match the design screens in `docs/design/your_competitions_empty/` and
`docs/design/your_competitions_text_only/`. The screen gains a text-and-button empty
state, a flat list layout replacing the current `Card`/`ListTile` approach, inline
status badges, and a Floating Action Button for "Add Competition".

## Scope

`bookmarks_screen.dart` only. All other screens, providers, and data-layer files are
unchanged. Depends on:
- **20260425-01** (theme tokens and `AppColors` with per-badge text colors)
- **20260425-02** (`CompetitionStatus` on `BookmarkedCompetition`)
- **20260425-06** (shared widgets: `StatusBadge`, `AppBadge`, `TwoToneCard`, `IconMetaRow`)

---

## Task

Read these files before starting:

- `lib/features/competitions/presentation/screens/bookmarks_screen.dart`
- `docs/design/your_competitions_empty/code.html`
- `docs/design/your_competitions_text_only/code.html`
- `docs/ui-guidelines.md` (badge and spacing rules)

---

### 1 — Use shared `StatusBadge`

`StatusBadge` is created in issue **20260425-06**. Import and use it directly:

```dart
import 'package:compman/features/competitions/presentation/widgets/status_badge.dart';

// In _BookmarkRow:
if (bookmark.status != null) StatusBadge(status: bookmark.status!),
```

Do not redefine badge colors or the badge container structure here.

---

### 2 — Empty state redesign

Replace the current `_EmptyState` widget. No illustration. Content is vertically and
horizontally centered on the screen:

```dart
Center(
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Add your first competition',
          style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Start tracking tasks and waypoint downloads.',
          style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => context.push('/add'),
          icon: const Icon(Icons.add),
          label: const Text('Add Competition'),
        ),
      ],
    ),
  ),
)
```

The `ElevatedButton` inherits the 48px height and 8px radius from the app theme.

---

### 3 — List state redesign

Replace `_BookmarkCard` (Card + ListTile) with a new `_BookmarkRow` flat list item.

**Screen structure** (when list is non-empty):
- A `Padding` header above the list:
  - Title: `"Your Competitions"` — `textTheme.headlineLarge`, bold
  - Subtitle: `"View and manage your gliding events."` — `textTheme.bodySmall` in `onSurfaceVariant`
  - Spacing: 24px below header before the first list item.
- `ListView.builder` with no extra padding between items.
- Each `_BookmarkRow`:
  - `InkWell` with `onTap` to navigate to detail, `onLongPress` triggers remove confirm.
  - Vertical padding: 16px top+bottom.
  - No border-radius on the row itself (flat list).
  - **Leading content** (left):
    - Row: `[Title text]` + `[StatusBadge if status != null]` with 8px gap.
    - Title: `textTheme.bodyLarge` bold, `onBackground` color.
    - Below title: `bookmark.description ?? ''` — `textTheme.bodySmall` in `tertiary` color.
  - **Trailing**: `Icon(Icons.chevron_right, color: outline)`.
  - Bottom: `Divider()` — uses `DividerTheme` from the app theme. No custom color.
  - Trigger the existing remove confirm dialog on long-press.

**Floating Action Button** (replaces the header `IconButton` for "Add"):
- `FloatingActionButton` with `Icons.add`, `backgroundColor: colorScheme.primary`, placed at `bottom-right`.
- Keep the existing `PopupMenuButton` in the AppBar for Settings/About access.
- Remove the `Icons.add` `IconButton` from the AppBar actions (replaced by FAB).

---

### 4 — Tests

Update or add a widget test for `BookmarksScreen`:
- Empty state renders headline "Add your first competition" and CTA button.
- List state renders at least one `_BookmarkRow` with a `StatusBadge`.
- Tapping the FAB navigates to `/add`.

---

## Completion condition

`make test` passes. The home screen shows the centered text-and-button empty state when
there are no bookmarks, and flat list rows with status badges when bookmarks exist.
