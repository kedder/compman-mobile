import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/di/providers.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/app_badge.dart';
import '../../../../../core/widgets/error_retry.dart';
import '../../../../../core/widgets/icon_meta_row.dart';
import '../../../../../core/widgets/two_tone_card.dart';
import '../../../../xcsoar/domain/xcsoar_flavor.dart';
import '../../../domain/entities/task_info.dart';
import '../../providers/competitions_providers.dart';
import 'flight_logs_panel.dart';
import 'shared.dart';

/// Shows the current task for [selectedClass] and lets the pilot download and
/// install it to XCSoar.
class TaskSection extends ConsumerStatefulWidget {
  /// Creates a [TaskSection].
  const TaskSection({
    super.key,
    required this.competitionId,
    required this.selectedClass,
    required this.installedTaskVersion,
  });

  final String competitionId;
  final String selectedClass;

  /// The version token stored on [BookmarkedCompetition] at last install.
  final String? installedTaskVersion;

  @override
  ConsumerState<TaskSection> createState() => _TaskSectionState();
}

class _TaskSectionState extends ConsumerState<TaskSection>
    with SafNavigationMixin<TaskSection> {
  Future<void> _installTask(TaskInfo task) async {
    ref.read(taskDownloadingProvider.notifier).value = true;
    try {
      final result = await ref.read(downloadAndInstallTaskProvider)(
        competitionId: widget.competitionId,
        taskUrl: task.taskUrl,
        version: task.timestamp,
      );
      if (!mounted) return;
      result.fold(
        (f) => ref.read(downloadErrorsProvider.notifier).add(failureMessage(f)),
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Task downloaded'),
              backgroundColor: context.appColors.success,
            ),
          );
          ref.invalidate(bookmarkedCompetitionsProvider);
          ref.invalidate(competitionDetailProvider(widget.competitionId));
        },
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      if (e.code == 'SAF_NOT_CONFIGURED') {
        await navigateToSettings(
          competitionId: widget.competitionId,
          kind: DownloadKind.task,
          onConfigured: () => _installTask(task),
        );
      } else {
        ref
            .read(downloadErrorsProvider.notifier)
            .add(e.message ?? 'Install failed');
      }
    } finally {
      if (mounted) ref.read(taskDownloadingProvider.notifier).value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(latestTasksProvider(widget.competitionId));
    final downloading = ref.watch(taskDownloadingProvider);

    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => ErrorRetry(
        message: failureMessage(err),
        onRetry: () =>
            ref.invalidate(latestTasksProvider(widget.competitionId)),
      ),
      data: (tasks) {
        final TaskInfo? task = _findTask(tasks, widget.selectedClass);
        if (task == null) {
          return ErrorRetry(
            message: 'No task available today for ${widget.selectedClass}.',
            onRetry: () =>
                ref.invalidate(latestTasksProvider(widget.competitionId)),
            retryLabel: 'Refresh',
          );
        }
        return _TaskCard(
          competitionId: widget.competitionId,
          task: task,
          downloading: downloading,
          installedTaskVersion: widget.installedTaskVersion,
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

class _TaskCard extends ConsumerWidget {
  const _TaskCard({
    required this.competitionId,
    required this.task,
    required this.downloading,
    required this.installedTaskVersion,
    required this.onInstall,
  });

  final String competitionId;
  final TaskInfo task;
  final bool downloading;

  /// The version token stored on [BookmarkedCompetition] at last install.
  final String? installedTaskVersion;
  final VoidCallback onInstall;

  /// True when the fetched task's timestamp differs from the stored install token.
  bool get _hasNewUpdate => task.timestamp != installedTaskVersion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              if (_hasNewUpdate)
                AppBadge(
                  label: 'NEW UPDATE',
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                  hasRing: true,
                ),
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
              label: Text(downloading ? 'Downloading...' : 'Download task'),
            ),
          ),
          if (!_hasNewUpdate) ...[
            const SizedBox(height: 8),
            const _FlyButton(),
          ],
          const SizedBox(height: 8),
          FlightLogsPanel(competitionId: competitionId),
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

/// Full-width "Fly XCSoar" CTA shown by [_TaskCard] once a task has been
/// downloaded for the current version and no newer one is pending.
///
/// Enabled and labelled with the active flavor's name once
/// [activeFlavorPackageIdProvider] resolves a package ID; otherwise disabled
/// with subdued guidance text explaining what's missing.
class _FlyButton extends ConsumerWidget {
  const _FlyButton();

  Future<void> _launch(WidgetRef ref, String packageId) async {
    try {
      await ref.read(xcsoarSafServiceProvider).launchPackage(packageId);
    } on PlatformException {
      ref
          .read(downloadErrorsProvider.notifier)
          .add('Could not launch XCSoar. Is it installed?');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFlavorAsync = ref.watch(activeFlavorPackageIdProvider);
    final directoryUriAsync = ref.watch(xcsoarDirectoryUriProvider);

    var label = 'Fly XCSoar';
    String? helperText;
    VoidCallback? onTap;

    if (activeFlavorAsync.isLoading) {
      helperText = 'XCSoar is not installed.';
    } else {
      final packageId = activeFlavorAsync.value;
      if (packageId != null) {
        final flavor = kKnownXcsoarFlavors.firstWhereOrNull(
          (f) => f.packageId == packageId,
        );
        label = 'Fly ${flavor?.displayName ?? 'XCSoar'}';
        onTap = () => _launch(ref, packageId);
      } else {
        final directoryConfigured = (directoryUriAsync.value ?? '').isNotEmpty;
        helperText = directoryConfigured
            ? 'XCSoar is not installed.'
            : 'Set up XCSoar folder first.';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onTap,
            style: AppButtonStyles.success(context),
            icon: const Icon(Icons.flight),
            label: Text(label),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
