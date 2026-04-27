import 'package:flutter/material.dart';

import '../../domain/entities/competition.dart';
import 'status_badge.dart';

/// Reusable card widget displaying a [Competition] in the Add Competition screen.
///
/// Shows the title, raw description string, a placeholder status badge, and
/// a leading icon to indicate selection state. Used by [CompetitionListScreen].
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

    return Semantics(
      label:
          '${competition.title}, ${isSelected ? 'selected' : 'not selected'}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? colorScheme.primary : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? colorScheme.primary : colorScheme.outline,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        competition.title,
                        style: textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        competition.description,
                        style: textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (competition.status != null) ...[
                  const SizedBox(width: 8),
                  StatusBadge(status: competition.status!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
