import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/widgets/icon_meta_row.dart';
import '../../../domain/entities/bookmarked_competition.dart';

/// Title + SoaringSpot link header shown at the top of Competition Detail.
class HeaderSection extends StatelessWidget {
  /// Creates a [HeaderSection] for [competition].
  const HeaderSection({super.key, required this.competition});

  final BookmarkedCompetition competition;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          competition.title,
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        IconMetaRow(
          icon: Icons.language,
          text: competition.soaringspotUrl,
          color: colorScheme.primary,
          onTap: () => launchUrl(Uri.parse(competition.soaringspotUrl)),
        ),
      ],
    );
  }
}
