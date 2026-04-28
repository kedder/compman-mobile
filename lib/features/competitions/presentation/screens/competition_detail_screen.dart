import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/platform/xcsoar_saf_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/icon_meta_row.dart';
import '../../../../core/widgets/two_tone_card.dart';
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

    final isRefreshing =
        competitionAsync.hasValue &&
        competitionAsync.value != null &&
        ref.watch(latestTasksProvider(competitionId)).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Competition Details'),
        actions: [
          if (isRefreshing)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () {
                ref.invalidate(latestTasksProvider(competitionId));
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

class _CompetitionDetailBody extends ConsumerStatefulWidget {
  const _CompetitionDetailBody({
    required this.competition,
    required this.competitionId,
  });

  final BookmarkedCompetition competition;
  final String competitionId;

  @override
  ConsumerState<_CompetitionDetailBody> createState() =>
      _CompetitionDetailBodyState();
}

class _CompetitionDetailBodyState
    extends ConsumerState<_CompetitionDetailBody> {
  final List<String> _downloadErrors = <String>[];

  void _appendDownloadError(String message) {
    setState(() {
      _downloadErrors.add(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(latestTasksProvider(widget.competitionId));
        await ref
            .read(latestTasksProvider(widget.competitionId).future)
            .catchError((_) => <TaskInfo>[]);
      },
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 128),
            children: [
              _HeaderSection(competition: widget.competition),
              const SizedBox(height: 24),
              _ClassSection(
                competition: widget.competition,
                competitionId: widget.competitionId,
                onDownloadError: _appendDownloadError,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              const _XcsoarDirectoryRow(),
            ],
          ),
          if (_downloadErrors.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var index = 0; index < _downloadErrors.length; index++)
                      Padding(
                        padding: EdgeInsets.only(top: index == 0 ? 0 : 4),
                        child: _ErrorBanner(
                          message: _downloadErrors[index],
                          onDismiss: () {
                            final message = _downloadErrors[index];
                            setState(() {
                              _downloadErrors.remove(message);
                            });
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
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
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Class selection / task section
// ---------------------------------------------------------------------------

class _ClassSection extends ConsumerWidget {
  const _ClassSection({
    required this.competition,
    required this.competitionId,
    required this.onDownloadError,
  });

  final BookmarkedCompetition competition;
  final String competitionId;
  final ValueChanged<String> onDownloadError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (competition.selectedClass == null) {
      return _ClassPicker(competitionId: competitionId);
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
                  competitionId,
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
        _TaskSection(
          competitionId: competitionId,
          selectedClass: competition.selectedClass!,
          onDownloadError: onDownloadError,
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

// ---------------------------------------------------------------------------
// Task section
// ---------------------------------------------------------------------------

class _TaskSection extends ConsumerStatefulWidget {
  const _TaskSection({
    required this.competitionId,
    required this.selectedClass,
    required this.onDownloadError,
  });

  final String competitionId;
  final String selectedClass;
  final ValueChanged<String> onDownloadError;

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
        widget.onDownloadError(
          'XCSoar directory not configured — set it in Settings',
        );
      } else {
        widget.onDownloadError(e.message ?? 'Install failed');
      }
    } on Failure catch (f) {
      if (!mounted) return;
      widget.onDownloadError(_failureMessage(f));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(latestTasksProvider(widget.competitionId));

    return tasksAsync.when(
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
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return TwoToneCard(
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Day ${task.dayNo} - Task ${task.taskNo}',
                  style: textTheme.headlineSmall,
                ),
              ),
              // TODO(new-update): show when newer version available
              // AppBadge(
              //   label: 'NEW UPDATE',
              //   backgroundColor: colorScheme.error,
              //   foregroundColor: colorScheme.onError,
              // ),
            ],
          ),
          const SizedBox(height: 8),
          IconMetaRow(
            icon: Icons.route,
            text: task.title,
            color: colorScheme.primary,
            style: textTheme.titleMedium,
          ),
        ],
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IconMetaRow(
            icon: Icons.update,
            text: 'Generated ${task.timestamp}',
            iconSize: 16,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: downloading ? null : onInstall,
              style: AppButtonStyles.primary(context),
              icon: downloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: Text(
                downloading ? 'Installing...' : 'Install XCSoar Task',
              ),
            ),
          ),
          // Installed state (when installed):
          // SizedBox(
          //   width: double.infinity,
          //   child: ElevatedButton.icon(
          //     onPressed: null,
          //     style: ElevatedButton.styleFrom(backgroundColor: context.appColors.success),
          //     icon: const Icon(Icons.check_circle),
          //     label: const Text('Installed'),
          //   ),
          // ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// XCSoar directory row
// ---------------------------------------------------------------------------

class _XcsoarDirectoryRow extends ConsumerWidget {
  const _XcsoarDirectoryRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uriAsync = ref.watch(xcsoarDirectoryUriProvider);

    return uriAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (uri) {
        final color = Theme.of(
          context,
        ).colorScheme.secondary.withValues(alpha: 0.6);
        final xcsoarPath = uri != null && uri.isNotEmpty
            ? uri
            : 'XCSoar folder not configured';

        return IconMetaRow(
          icon: Icons.folder_open,
          text: xcsoarPath,
          iconSize: 14,
          color: color,
        );
      },
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.warning, color: colorScheme.onError),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onError,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              tooltip: 'Dismiss error',
              color: colorScheme.onError,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
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
