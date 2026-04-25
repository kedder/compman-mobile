# Gliding Compman — UI Guidelines

> **Source of truth for visual design:** [`docs/design/design.md`](design/design.md) and [`docs/design/tokens.md`](design/tokens.md).
> This document covers implementation rules, Flutter-specific patterns, and UX constraints that are not expressed in the design files.

## Usage Context

This app is used by glider pilots in competition settings — on the flight line, in the briefing room, and **in the cockpit during flight**. Design for these constraints:

- Interactions are **short and purposeful**: a quick status check or a single button press. The user will close the app within seconds.
- The phone may be mounted on the instrument panel or held in one hand with a glove. Fumbling is not acceptable at altitude.
- Lighting varies from cockpit shade to direct bright sunlight. Contrast must be high enough to remain readable outdoors.
- The user may be task-loaded or stressed. The UI must communicate the most important information instantly, without requiring reading or searching.

**Guiding principle: If the user has to think about what to tap, the design has failed.**

---

## Visual Theme

Specific color values, surface tiers, elevation/shadow rules, shape radii, and spacing tokens are defined in [`docs/design/design.md`](design/design.md) and [`docs/design/tokens.md`](design/tokens.md). Implementation rules:

- Do not use decorative gradients or textures. Flat, clean surfaces only.
- Always derive colors from `Theme.of(context)` — never hard-code color literals in widget code.
- **All tokens are defined in `lib/core/theme/app_theme.dart`.** If a token is missing, add it there rather than using a literal.
- Cards use the `surface-container-lowest` background color with a 1 dp border (`outline-variant`) and `shadow-sm` — do not use `elevation: 2` alone.

---

## Typography

The app uses **Inter** as its primary typeface. Type scale and weights are defined in [`docs/design/design.md`](design/design.md). Implementation rules:

- Body text (`body-lg`): 16 sp, regular weight. This is the minimum size for primary content.
- Secondary metadata (dates, locations, file sizes): `body-sm` (14 sp) or `label-caps` (11 sp, bold, uppercase) as defined in the type scale — use the smallest size only for subordinate labels such as section headers and badge text.
- Button labels: **bold**, minimum 16 sp.
- Do not use more than 3 type sizes on any single screen.
- No prose descriptions. Information must be scannable in under 2 seconds.

---

## Touch Targets

This is the most critical dimension of the design.

- **Minimum touch target: 48 × 48 dp** (Material baseline). Prefer 56 dp for primary actions.
- Full-width action buttons (e.g. primary CTAs on detail screens) must be at least **64 dp tall**.
- Icon buttons must be wrapped in a hit area of at least 48 × 48 dp — the icon itself (24 dp) is not a sufficient target.
- `ListTile` rows are acceptable at their default height (56 dp). Do not reduce list row height.
- Avoid placing two tappable elements within 8 dp of each other.
- The primary CTA in an empty state must be a large, impossible-to-miss button — minimum `ElevatedButton` with 24 dp horizontal padding, or an extended FAB.

---

## Information Density

Show only what the pilot needs right now. Everything else is noise.

- Cards and list rows display a maximum of **three to four data points**. Put only the most critical info at the top level; move the rest to a detail screen.
- Do not dump raw data (scraped text, ISO dates, file paths) directly into list items. Format everything for human readability.
- Timestamps use a human-readable relative format: "today at 14:32", "yesterday at 09:00" — not ISO 8601.
- Empty states must explain what to do next with **one short sentence** and **one call-to-action button**. No more.

---

## Status Badges

Badges convey status at a glance and must be consistent across all screens and features. Colors come from [`docs/design/tokens.md`](design/tokens.md).

| Status | Label | Token | Design token name | Text |
|---|---|---|---|---|
| Live | `Live` | `appColors.badgeLive` | `status-live` | white |
| Upcoming | `Upcoming` | `appColors.badgeUpcoming` | `status-upcoming` | white |
| Past | `Past` | `appColors.badgePast` | `status-past` | white |
| New / Updated | `New` | `appColors.badgeNew` | `status-new` | black (yellow provides insufficient contrast against white) |

Rendering rules:
- `Container` with `BorderRadius.circular(4)`, horizontal padding 8 dp, vertical padding 3 dp.
- Font: `labelSmall`, bold (maps to `status-badge` token: 10 sp, weight 800).
- Placement: to the right of a title on list rows; below the title on detail screens.

These are the only permitted badge styles. Do not introduce ad hoc colored labels.

---

## Navigation and Screen Structure

- Navigation depth is **at most two levels**: root screen → detail or task screen. Do not nest deeper.
- Use `GoRouter` exclusively. Do not call `Navigator.push` directly in new code.
- Every non-root screen has an `AppBar` with a back button. The user can always return in one tap.
- The `AppBar` on any screen carries **at most two action icons**. Overflow additional actions into a `PopupMenuButton`.
- Bottom navigation bars are not used unless a future feature explicitly requires peer-level navigation between distinct areas of the app.

---

## Loading, Error, and Empty States

Every screen backed by async data must handle all three states explicitly. No state may be skipped or silently ignored.

### Loading
- Show a centered `CircularProgressIndicator` in the primary theme color.
- Replace the full content area — do not show partial content alongside a spinner.

### Error
- One short, specific sentence describing what failed (e.g. "Could not load competitions. Check your connection."). No stack traces.
- A **Retry** button immediately below, minimum 48 dp tall, ideally full-width.
- Match the error message to the failure type — do not reuse the same generic string for all errors.

### Empty
- One sentence explaining the state, one CTA button. No decoration required, but a large icon may help orientation.
- "No results for your search" states require no CTA button.

---

## Buttons

Button shape and sizing tokens are defined in [`docs/design/design.md`](design/design.md) (8 dp radius, 48 dp height for primary). Implementation rules:

- **Primary action:** `ElevatedButton` in `colorScheme.primary` (see `tokens.md`). Full-width on detail/action screens; standard width in dialogs.
- **Secondary / cancel action:** `TextButton` or `OutlinedButton`. Always visually lighter than the primary.
- **Destructive action:** Red `TextButton` inside a confirmation dialog. Never a standalone primary button.
- **Disabled state:** Reduce opacity to 38%. Update the label to describe why the button is inactive (e.g. "Downloading…"). Never silently disable without visual and textual feedback.
- Icon-only buttons are acceptable only for universally understood icons (`Icons.add`, `Icons.delete`, `Icons.refresh`) in contexts where a label would clutter the layout. When in doubt, add the label.

---

## Dialogs and Confirmations

- Confirmation dialogs must name the specific item: "Remove **World Gliding Championship 2026**?" — not "Are you sure?".
- Two buttons only: **Cancel** (left, secondary weight) and the action verb (right, primary or destructive weight).
- Do not use dialogs for non-destructive choices or navigation decisions. Navigate instead.

---

## Accessibility

Despite the cockpit use case, the app must meet baseline accessibility requirements.

- **Color is never the sole indicator** of meaning. Status badges carry a text label alongside their color.
- **Contrast ratio:** All text must meet WCAG AA — minimum 4.5:1 for body text, 3:1 for large text (18 sp+). Verify badge text against badge background colors.
- **Semantic labels:** Every icon button must have a `Tooltip` and/or `Semantics(label: ...)`. A screen reader user must be able to operate all actions.
- **Text scaling:** Layouts must not break when the system font scale is 1.3×. Use `Expanded`, `Flexible`, and `TextOverflow.ellipsis` — never fixed-height containers that clip text.
- Do not use color combinations that fail for deuteranopia (red-green color blindness). The Live/Past green-gray distinction is safe; double-check any future color additions.

---

## Interaction and Animation

- Transition animations: **150–300 ms**. Nothing slower. Pilots are not here for choreography.
- `RefreshIndicator` color must match the primary theme color.
- On pull-to-refresh completion, show no success toast if nothing changed. Silence is correct.
- Do not use `showSnackBar` as a substitute for inline error messages. Snackbars are appropriate only for transient confirmations (e.g. "Downloaded").

---

## Do Not

- Do not place critical interactive elements in the bottom 20% of the screen — hard to see in cockpit mounts.
- Do not add splash screens, onboarding flows, or decorative loading screens.
- Do not use more than two typeface weights on a single screen.
- Do not introduce a new color without adding it to [`docs/design/tokens.md`](design/tokens.md) and `lib/core/theme/app_theme.dart`.
