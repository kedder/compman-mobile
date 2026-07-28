import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/icon_meta_row.dart';
import '../../providers/competitions_providers.dart';

/// Summary of today's flight logs shown at the bottom of the Task card, with
/// a full-width "Email flight logs" action to reach the Flight Log screen.
///
/// Errors (including `SAF_NOT_CONFIGURED` when no XCSoar directory has been
/// granted yet) fall back to the same muted empty-state text as zero files —
/// this is a passive background check that should never interrupt the pilot.
class FlightLogsPanel extends ConsumerWidget {
  /// Creates a [FlightLogsPanel] for [competitionId].
  const FlightLogsPanel({super.key, required this.competitionId});

  final String competitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(todaysFlightLogsProvider);
    final theme = Theme.of(context);

    return logsAsync.when(
      skipLoadingOnReload: true,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _EmptyText(theme: theme),
      data: (files) {
        if (files.isEmpty) return _EmptyText(theme: theme);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IconMetaRow(
              icon: Icons.description_outlined,
              text: files.length == 1
                  ? '1 flight log recorded'
                  : '${files.length} flight logs recorded',
              iconSize: 16,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () =>
                  context.push('/competitions/$competitionId/flight-logs'),
              style: AppButtonStyles.outlinedFullWidth(context),
              icon: const Icon(Icons.email_outlined),
              label: const Text('Email flight logs'),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Text(
      'No flight logs recorded today',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.outline,
      ),
    );
  }
}
