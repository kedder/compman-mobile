import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/competition_status.dart';

/// Badge widget that renders a competition [CompetitionStatus].
class StatusBadge extends StatelessWidget {
  /// Creates a [StatusBadge].
  const StatusBadge({super.key, required this.status});

  /// Status to render.
  final CompetitionStatus status;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final theme = Theme.of(context);
    final (background, foreground, label) = switch (status) {
      CompetitionStatus.live => (
        appColors.badgeLive,
        appColors.badgeLiveText,
        'Live',
      ),
      CompetitionStatus.upcoming => (
        appColors.badgeUpcoming,
        appColors.badgeUpcomingText,
        'Upcoming',
      ),
      CompetitionStatus.past => (
        appColors.badgePast,
        appColors.badgePastText,
        'Past',
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
