# Adjust Status Badge Positioning

## Feature Summary
The competition cards currently display status badges ("Live", "Upcoming", "Past") inline with the competition title. This causes visual issues when titles are long, as the badges can wrap to a new line.

## Scope
This issue focuses on adjusting the visual layout of status badges in competition cards to make them stick to the top right corner instead of being placed inline after the title.

## Task
1. Modify the competition card layout in `lib/features/competitions/presentation/widgets/competition_card.dart` to position the status badge in the top right corner
2. Update the bookmarks screen layout in `lib/features/competitions/presentation/screens/bookmarks_screen.dart` to maintain consistent positioning
3. Ensure the status badge remains visible and properly aligned regardless of title length

## Current Implementation
- `CompetitionCard` uses a `Wrap` widget with `StatusBadge` inline after the title text
- `BookmarksScreen` uses a `Row` with `StatusBadge` inline after the title text
- Both approaches can cause the badge to wrap to a new line when the title is long

## Desired Implementation
- Position the status badge in the top right corner of the competition card
- Maintain consistent positioning across both competition card and bookmarks screen
- Ensure the badge doesn't overlap with other content
- Keep the badge visible even when title text is long

## Acceptance Criteria
- Status badges appear in the top right corner of competition cards
- Badges maintain consistent positioning across all competition lists
- No visual overlap with other card content
- Badges remain visible regardless of title length
- Changes follow existing code style and architecture patterns
- All code checks pass: `flutter analyze`, `flutter format`, and `flutter test`

## References
- Competition card: `lib/features/competitions/presentation/widgets/competition_card.dart`
- Bookmarks screen: `lib/features/competitions/presentation/screens/bookmarks_screen.dart`
- Status badge: `lib/features/competitions/presentation/widgets/status_badge.dart`
- Project rules: `AGENTS.md`