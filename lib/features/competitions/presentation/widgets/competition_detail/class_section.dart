import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/error_retry.dart';
import '../../../domain/entities/bookmarked_competition.dart';
import '../../providers/competitions_providers.dart';
import 'shared.dart';
import 'task_section.dart';

/// Shows the selected class (with a "Change" action) and the [TaskSection]
/// for it, or a [ClassPicker] if no class has been selected yet.
class ClassSection extends ConsumerWidget {
  /// Creates a [ClassSection].
  const ClassSection({super.key, required this.competition});

  final BookmarkedCompetition competition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (competition.selectedClass == null) {
      return ClassPicker(competitionId: competition.id);
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Class: ',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.secondary,
              ),
            ),
            Text(
              competition.selectedClass!,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            OutlinedButton(
              onPressed: () async {
                await SetCompetitionClassAction.execute(
                  ref,
                  competition.id,
                  null,
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side: BorderSide(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                ),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                textStyle: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Change'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TaskSection(
          competitionId: competition.id,
          selectedClass: competition.selectedClass!,
          installedTaskVersion: competition.taskVersion,
        ),
      ],
    );
  }
}

/// Full-width class cards letting the pilot pick their competition class.
class ClassPicker extends ConsumerWidget {
  /// Creates a [ClassPicker].
  const ClassPicker({super.key, required this.competitionId});

  final String competitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(competitionClassesProvider(competitionId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select your class',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        classesAsync.when(
          skipLoadingOnReload: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => ErrorRetry(
            message:
                'No classes found — tasks may not be available for this competition.',
            onRetry: () =>
                ref.invalidate(competitionClassesProvider(competitionId)),
          ),
          data: (classes) {
            if (classes.isEmpty) {
              return ErrorRetry(
                message:
                    'No classes found — tasks may not be available for this competition.',
                onRetry: () =>
                    ref.invalidate(competitionClassesProvider(competitionId)),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < classes.length; index++) ...[
                  if (index > 0) const SizedBox(height: 12),
                  _ClassCard(
                    label: classes[index],
                    onTap: () async {
                      await SetCompetitionClassAction.execute(
                        ref,
                        competitionId,
                        classes[index],
                      );
                    },
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.emoji_events_outlined, color: colorScheme.outline),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: theme.textTheme.titleLarge)),
            Icon(Icons.chevron_right, color: colorScheme.outline),
          ],
        ),
      ),
    );
  }
}
