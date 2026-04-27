# Competition Detail Screen Visual Redesign

## Feature summary

Redesign `CompetitionDetailScreen`
(`lib/features/competitions/presentation/screens/competition_detail_screen.dart`)
to match `docs/design/competition_details_full_download_suite/` and
`docs/design/competition_details_stacked_errors/`. Cards become two-tone (white header +
tinted footer), the class selector becomes a simple inline row, and download errors are
surfaced as stacked dismissible banners at the bottom of the screen instead of inline
error states.

## Scope

`competition_detail_screen.dart` only. Depends on:
- **20260425-01** (theme tokens, `AppColors`)
- **20260425-06** (shared widgets: `AppBadge`, `TwoToneCard`, `IconMetaRow`)

The `_ClassPicker` widget (shown when no class is selected) is redesigned in a separate
issue **20260427-01-competition-class-picker-redesign.md**. This issue covers only the
state where a class has already been selected.

---

## Task

Read these files before starting:

- `lib/features/competitions/presentation/screens/competition_detail_screen.dart`
- `docs/design/competition_details_full_download_suite/code.html`
- `docs/design/competition_details_stacked_errors/code.html`
- `docs/ui-guidelines.md`

`competition_details_full_download_suite` is the primary reference for the normal state.
`competition_details_stacked_errors` is the reference for the error banner overlay.

---

### 1 — AppBar

- Title: `"Competition Details"` (static string, not the competition title).
- Leading: back arrow (default).
- Trailing: refresh `IconButton` (already exists).
- AppBar background and bottom border come from `AppBarTheme` defined in issue **20260425-01**.
  Do not set `AppBar.backgroundColor` or add a custom bottom border here.

### 2 — Header section

Replace `_HeaderSection` content:

- Competition title: `textTheme.headlineLarge` bold, `onSurface` color.
- SoaringSpot URL row: use `IconMetaRow` from `lib/core/widgets/icon_meta_row.dart`:
  ```dart
  IconMetaRow(
    icon: Icons.language,
    text: competition.url,
    color: colorScheme.primary,
  )
  ```
  Replace the current `Icons.link` approach.

### 3 — Class selector (`_ClassSection` when class is selected)

Replace the current `Row([Text, TextButton])` with a streamlined inline row:

```dart
Row(
  children: [
    Text('Class: ', style: textTheme.bodyMedium?.copyWith(color: colorScheme.secondary)),
    Text(competition.selectedClass!, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
    const Spacer(),
    OutlinedButton(
      onPressed: _onChangeClass,
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3)),
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        textStyle: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text('Change'),
    ),
  ],
)
```

No container box or label heading above the row. `_onChangeClass` calls
`SetCompetitionClassAction.execute(ref, competitionId, null)` (existing behaviour).

### 4 — Two-tone download cards

The Task download section uses the `TwoToneCard` widget from `lib/core/widgets/two_tone_card.dart`
(created in issue **20260425-06**). Airspace and Waypoints file fetching are not yet implemented
and should be omitted from this redesign.

---

**Task card**:

The header row shows only the task name in the normal state. An `AppBadge` with label
`'NEW UPDATE'` and error colours is shown only when a newer task version is detected
(reserved for a future issue — leave the conditional commented-out placeholder as shown).

```dart
TwoToneCard(
  header: Column([
    Row([
      Expanded(Text(taskName, style: textTheme.headlineMedium)),
      // TODO(new-update): show when newer version available
      // AppBadge(label: 'NEW UPDATE', backgroundColor: colorScheme.error, foregroundColor: colorScheme.onError),
    ]),
    SizedBox(height: 8),
    IconMetaRow(icon: Icons.route, text: distanceLabel, color: colorScheme.primary),
  ]),
  footer: Column([
    IconMetaRow(icon: Icons.update, text: generatedAt, iconSize: 16),
    SizedBox(height: 8),
    SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _onInstallTask,
        icon: const Icon(Icons.download),
        label: const Text('Install XCSoar Task'),
      ),
    ),
    // Installed state (when installed):
    // SizedBox(width: double.infinity,
    //   child: ElevatedButton.icon(
    //     onPressed: null,
    //     style: ElevatedButton.styleFrom(backgroundColor: appColors.success),
    //     icon: const Icon(Icons.check_circle), label: const Text('Installed'),
    //   ),
    // ),
  ]),
)
```

`AppBadge` is imported from `lib/core/widgets/app_badge.dart`. Do not inline the badge
Container.

---

### 5 — XCSoar directory footer

Replace the current `_XcsoarDirectoryRow` rendering using `IconMetaRow`:

```dart
IconMetaRow(
  icon: Icons.folder_open,
  text: xcsoarPath,
  iconSize: 14,
  color: colorScheme.secondary.withValues(alpha: 0.6),
)
```

Place below the cards inside the `ListView`, separated by a `Divider()` with 16px top
padding.

### 6 — Stacked dismissible error banners

The `competition_details_stacked_errors` design shows per-operation download errors as
stacked red banners at the fixed bottom of the screen (not inline, not in a `SnackBar`).

Add a state list `_downloadErrors` (list of strings) to `_CompetitionDetailBody` (convert
to `ConsumerStatefulWidget`). When a task/airspace/waypoints download fails, append an
error message to this list. Render errors as a fixed `Positioned` overlay at the bottom:

```dart
Stack(children: [
  ListView(...),   // existing scrollable content
  Positioned(
    left: 16, right: 16, bottom: 16,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: _downloadErrors.map((msg) => _ErrorBanner(
        message: msg,
        onDismiss: () => setState(() => _downloadErrors.remove(msg)),
      )).toList(),
    ),
  ),
])
```

`_ErrorBanner`: red (`colorScheme.error`) background, `onError` text, `Icons.warning`
leading icon, message text, `Icons.close` trailing `IconButton` to dismiss, 12px border
radius, 4px gap between stacked banners.

Keep the existing full-screen `_ErrorRetry` for the initial competition-load failure (the
`competitionAsync.when(error:...)` branch). Only download-operation errors use banners.

### 7 — Tests

Update or add widget tests for `CompetitionDetailScreen`:
- Header shows competition title in `headlineLarge`.
- Class selector row shows `"Class:"` label, selected class name, and `"Change"` button.
- Task card renders task name and install button (no badge in normal state).
- A simulated download error (task) appends a dismissible error banner.
- Dismissing a banner removes it.

---

## Completion condition

`make test` passes. The competition detail screen shows the `TwoToneCard` Task card,
a plain task-name header row (no badge), the inline class selector row, `IconMetaRow`
metadata rows, and dismissible stacked error banners for download failures. Airspace and
Waypoints cards are not included.
