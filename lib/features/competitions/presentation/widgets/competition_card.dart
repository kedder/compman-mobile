import 'package:flutter/material.dart';

import '../../domain/entities/competition.dart';
import 'status_badge.dart';

/// Reusable flat row widget displaying a [Competition] in the Add Competition
/// screen.
class CompetitionCard extends StatelessWidget {
  /// Creates a [CompetitionCard].
  const CompetitionCard({
    super.key,
    required this.competition,
    required this.isSelected,
    required this.onTap,
  });

  /// The competition to display.
  final Competition competition;

  /// Whether this card is currently selected.
  final bool isSelected;

  /// Called when the card is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final titleStyle = textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.bold,
      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
    );

    return Semantics(
      label:
          '${competition.title}, ${isSelected ? 'selected' : 'not selected'}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (_) => onTap(),
                        activeColor: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                competition.title,
                                style: titleStyle,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (competition.status != null)
                                StatusBadge(status: competition.status!),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            competition.description,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.tertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
            ],
          ),
        ),
      ),
    );
  }
}
