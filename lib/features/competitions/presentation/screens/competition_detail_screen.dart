import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/platform/xcsoar_saf_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/bookmarked_competition.dart';
import '../../domain/entities/task_info.dart';
import '../providers/competitions_providers.dart';

/// Screen showing the detail of a single bookmarked competition.
///
/// Allows the user to select a competition class, view and install the
/// latest XCSoar task, and see the current XCSoar data directory.
class CompetitionDetailScreen extends ConsumerWidget {
  /// Creates the [CompetitionDetailScreen].
  const CompetitionDetailScreen({super.key, required this.competitionId});

  /// The SoaringSpot slug / SoarScore competition ID.
  final String competitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competitionAsync = ref.watch(
      competitionDetailProvider(competitionId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Competition'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(latestTasksProvider(competitionId));
              ref.invalidate(competitionClassesProvider(competitionId));
              ref.invalidate(xcsoarDirectoryUriProvider);
            },
          ),
        ],
      ),
      body: competitionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorRetry(
          message: _failureMessage(err),
          onRetry: () =>
              ref.invalidate(competitionDetailProvider(competitionId)),
        ),
        data: (competition) {
          if (competition == null) {
            return const Center(child: Text('Competition not found.'));
          }
          return _CompetitionDetailBody(
            competition: competition,
            competitionId: competitionId,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _CompetitionDetailBody extends ConsumerWidget {
  const _CompetitionDetailBody({
    required this.competition,
    required this.competitionId,
  });

  final BookmarkedCompetition competition;
  final String competitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(latestTasksProvider(competitionId));
        ref.invalidate(competitionClassesProvider(competitionId));
        ref.invalidate(xcsoarDirectoryUriProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderSection(competition: competition),
          const SizedBox(height: 24),
          _ClassSection(competition: competition, competitionId: competitionId),
          const SizedBox(height: 24),
          _XcsoarDirectoryRow(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.competition});

  final BookmarkedCompetition competition;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          competition.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              Icons.link,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                competition.soaringspotUrl,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Class selection / task section
// ---------------------------------------------------------------------------

class _ClassSection extends ConsumerWidget {
  const _ClassSection({required this.competition, required this.competitionId});

  final BookmarkedCompetition competition;
  final String competitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (competition.selectedClass == null) {
      return _ClassPicker(competitionId: competitionId);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Class: ${competition.selectedClass}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () async {
                await SetCompetitionClassAction.execute(
                  ref,
                  competitionId,
                  null,
                );
              },
              child: const Text('Change'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _TaskSection(
          competitionId: competitionId,
          selectedClass: competition.selectedClass!,
        ),
      ],
    );
  }
}

class _ClassPicker extends ConsumerWidget {
  const _ClassPicker({required this.competitionId});

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
          error: (err, _) => _ErrorRetry(
            message:
                'No classes found — tasks may not be available for this competition.',
            onRetry: () =>
                ref.invalidate(competitionClassesProvider(competitionId)),
          ),
          data: (classes) {
            if (classes.isEmpty) {
              return _ErrorRetry(
                message:
                    'No classes found — tasks may not be available for this competition.',
                onRetry: () =>
                    ref.invalidate(competitionClassesProvider(competitionId)),
              );
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: classes
                  .map(
                    (cls) => _ClassChip(
                      label: cls,
                      onTap: () async {
                        await SetCompetitionClassAction.execute(
                          ref,
                          competitionId,
                          cls,
                        );
                      },
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ClassChip extends StatelessWidget {
  const _ClassChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Task section
// ---------------------------------------------------------------------------

class _TaskSection extends ConsumerStatefulWidget {
  const _TaskSection({
    required this.competitionId,
    required this.selectedClass,
  });

  final String competitionId;
  final String selectedClass;

  @override
  ConsumerState<_TaskSection> createState() => _TaskSectionState();
}

class _TaskSectionState extends ConsumerState<_TaskSection> {
  bool _downloading = false;

  Future<void> _installTask(TaskInfo task) async {
    setState(() => _downloading = true);
    try {
      final downloadUseCase = ref.read(downloadTaskProvider);
      final result = await downloadUseCase(task.taskUrl);
      final bytes = result.fold((f) => throw f, (b) => b);
      await XcsoarSafService().writeFile(bytes, 'Default.tsk');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Default.tsk installed in XCSoar folder'),
          backgroundColor: context.appColors.success,
        ),
      );
      ref.invalidate(xcsoarDirectoryUriProvider);
    } on PlatformException catch (e) {
      if (!mounted) return;
      if (e.code == 'SAF_NOT_CONFIGURED') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'XCSoar directory not configured — set it in Settings',
            ),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => context.push('/settings/xcsoar-directory'),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Install failed'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } on Failure catch (f) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_failureMessage(f)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(latestTasksProvider(widget.competitionId));
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Today's Task", style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        tasksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => _ErrorRetry(
            message: _failureMessage(err),
            onRetry: () =>
                ref.invalidate(latestTasksProvider(widget.competitionId)),
          ),
          data: (tasks) {
            final TaskInfo? task = _findTask(tasks, widget.selectedClass);
            if (task == null) {
              return _ErrorRetry(
                message: 'No task available today for ${widget.selectedClass}.',
                onRetry: () =>
                    ref.invalidate(latestTasksProvider(widget.competitionId)),
                retryLabel: 'Refresh',
              );
            }
            return _TaskCard(
              task: task,
              downloading: _downloading,
              onInstall: () => _installTask(task),
            );
          },
        ),
      ],
    );
  }

  TaskInfo? _findTask(List<TaskInfo> tasks, String cls) {
    try {
      return tasks.firstWhere((t) => t.compClass == cls);
    } catch (_) {
      return null;
    }
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.downloading,
    required this.onInstall,
  });

  final TaskInfo task;
  final bool downloading;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Day ${task.dayNo} · Task ${task.taskNo} · ${task.title}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Generated ${task.timestamp}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 64,
              child: downloading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: onInstall,
                      child: const Text('Install as XCSoar Default Task'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// XCSoar directory row
// ---------------------------------------------------------------------------

class _XcsoarDirectoryRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uriAsync = ref.watch(xcsoarDirectoryUriProvider);

    return uriAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (uri) {
        if (uri != null && uri.isNotEmpty) {
          return Row(
            children: [
              Icon(
                Icons.folder_open,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'XCSoar folder: $uri',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        }
        return Row(
          children: [
            Icon(
              Icons.folder_off,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              'XCSoar folder: Not configured',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            TextButton(
              onPressed: () => context.push('/settings/xcsoar-directory'),
              child: const Text('Set up'),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

/// Shared error + retry widget used inline throughout this screen.
class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({
    required this.message,
    required this.onRetry,
    this.retryLabel = 'Retry',
  });

  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
      ],
    );
  }
}

String _failureMessage(Object err) {
  if (err is Failure) {
    return switch (err) {
      NetworkFailure(:final message) => message,
      ParseFailure(:final message) => message,
      StorageFailure(:final message) => message,
    };
  }
  return err.toString();
}

/// Namespace for the set-competition-class action (avoids duplicating
/// provider access boilerplate in multiple widgets).
abstract final class SetCompetitionClassAction {
  /// Calls [SetCompetitionClass] and then invalidates affected providers.
  static Future<void> execute(
    WidgetRef ref,
    String competitionId,
    String? selectedClass,
  ) async {
    final useCase = ref.read(setCompetitionClassProvider);
    await useCase(competitionId, selectedClass);
    ref.invalidate(bookmarkedCompetitionsProvider);
    ref.invalidate(competitionDetailProvider(competitionId));
    ref.invalidate(latestTasksProvider(competitionId));
  }
}
