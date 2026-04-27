import 'package:flutter/material.dart';

import '../../../../core/widgets/app_badge.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/competition_status.dart';

/// Displays a competition status badge using [AppBadge].
class StatusBadge extends StatelessWidget {
  /// Creates a [StatusBadge].
  const StatusBadge({super.key, required this.status});

  /// Status to render.
  final CompetitionStatus status;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final (background, foreground, label) = switch (status) {
      CompetitionStatus.live => (
        appColors.badgeLive,
        appColors.badgeLiveText,
        'LIVE',
      ),
      CompetitionStatus.upcoming => (
        appColors.badgeUpcoming,
        appColors.badgeUpcomingText,
        'UPCOMING',
      ),
      CompetitionStatus.past => (
        appColors.badgePast,
        appColors.badgePastText,
        'PAST',
      ),
    };

    return AppBadge(
      label: label,
      backgroundColor: background,
      foregroundColor: foreground,
    );
  }
}
