import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/storage/last_viewed_local_datasource.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/icon_meta_row.dart';
import '../../../../core/widgets/two_tone_card.dart';
import '../../domain/entities/bookmarked_competition.dart';
import '../../domain/entities/downloadable_file_info.dart';
import '../../domain/entities/pending_download.dart';
import '../../domain/entities/task_info.dart';
import '../providers/competitions_providers.dart';

/// Screen showing the detail of a single bookmarked competition.
///
/// Allows the user to select a competition class, view and install the
/// latest XCSoar task, and see the current XCSoar data directory.
///
/// On first render, records this competition's ID as the last-viewed entry so
/// that the next cold start can navigate here directly.
class CompetitionDetailScreen extends ConsumerStatefulWidget {
  /// Creates the [CompetitionDetailScreen].
  const CompetitionDetailScreen({super.key, required this.competitionId});

  /// The SoaringSpot slug / SoarScore competition ID.
  final String competitionId;

  @override
  ConsumerState<CompetitionDetailScreen> createState() =>
      _CompetitionDetailScreenState();
}

class _CompetitionDetailScreenState
    extends ConsumerState<CompetitionDetailScreen> {
  @override
  void initState() {
    super.initState();
    // whenData is a no-op when the provider is still AsyncLoading (e.g. in
    // widget tests that do not override settingsBoxProvider), avoiding any
    // platform-channel calls or FakeAsync deadlocks.
    ref.read(settingsBoxProvider).whenData((box) {
      LastViewedLocalDataSource(box).writeLastViewedId(widget.competitionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final competitionAsync = ref.watch(
      competitionDetailProvider(widget.competitionId),
    );

    final isRefreshing =
        competitionAsync.hasValue &&
        competitionAsync.value != null &&
        ref.watch(latestTasksProvider(widget.competitionId)).isLoading;

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
                ref.invalidate(latestTasksProvider(widget.competitionId));
                ref.invalidate(downloadsProvider(widget.competitionId));
              },
            ),
        ],
      ),
      body: competitionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorRetry(
          message: _failureMessage(err),
          onRetry: () =>
              ref.invalidate(competitionDetailProvider(widget.competitionId)),
        ),
        data: (competition) {
          if (competition == null) {
            return const Center(child: Text('Competition not found.'));
          }
          return _CompetitionDetailBody(
            competition: competition,
            competitionId: widget.competitionId,
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

  /// Navigates to the XCSoar directory settings screen with [kind] encoded as a
  /// pending download. On return, auto-resumes the download if SAF was
  /// configured, or shows an error banner if the user aborted.
  Future<void> _navigateToSettings(String kind) async {
    final pending = PendingDownload(
      competitionId: widget.competitionId,
      kind: kind,
    );
    final uri =
        '/settings/xcsoar-directory?from=download&${pending.toQueryString()}';
    await context.push<void>(uri);
    if (!mounted) return;
    final storedUri = await ref.read(xcsoarDirectoryUriProvider.future);
    if (!mounted) return;
    if (storedUri != null && storedUri.isNotEmpty) {
      await _autoResumeDownload(kind);
    } else {
      _appendDownloadError(
        'XCSoar folder setup was cancelled. '
        'Go to Settings → XCSoar Folder to try again.',
      );
    }
  }

  /// Resumes the pending download of [kind] after the SAF directory was
  /// successfully configured. Errors are shown as download error banners.
  Future<void> _autoResumeDownload(String kind) async {
    try {
      if (kind == 'task') {
        final comp = await ref.read(
          competitionDetailProvider(widget.competitionId).future,
        );
        if (!mounted || comp?.selectedClass == null) return;
        final tasks = await ref.read(
          latestTasksProvider(widget.competitionId).future,
        );
        final task = tasks
            .where((t) => t.compClass == comp!.selectedClass)
            .firstOrNull;
        if (!mounted || task == null) return;
        final result = await ref.read(downloadAndInstallTaskProvider)(
          task.taskUrl,
        );
        if (!mounted) return;
        result.fold((f) => _appendDownloadError(_failureMessage(f)), (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Task downloaded'),
              backgroundColor: context.appColors.success,
            ),
          );
          ref.invalidate(xcsoarDirectoryUriProvider);
        });
      } else {
        final downloads = await ref.read(
          downloadsProvider(widget.competitionId).future,
        );
        final kindEnum = kind == 'airspace'
            ? DownloadableFileKind.airspace
            : DownloadableFileKind.waypoints;
        final file = downloads.where((f) => f.kind == kindEnum).firstOrNull;
        if (!mounted || file == null) return;
        final result = await ref
            .read(downloadAndInstallFileProvider)
            .call(competitionId: widget.competitionId, fileInfo: file);
        result.fold(
          (f) {
            if (mounted) _appendDownloadError(_failureMessage(f));
          },
          (_) {
            if (!mounted) return;
            final msg = kind == 'airspace'
                ? 'Airspace downloaded'
                : 'Waypoints downloaded';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg),
                backgroundColor: context.appColors.success,
              ),
            );
            ref.invalidate(bookmarkedCompetitionsProvider);
            ref.invalidate(competitionDetailProvider(widget.competitionId));
          },
        );
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      _appendDownloadError(e.message ?? 'Download failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(latestTasksProvider(widget.competitionId));
        ref.invalidate(downloadsProvider(widget.competitionId));
        await Future.wait([
          ref
              .read(latestTasksProvider(widget.competitionId).future)
              .catchError((_) => <TaskInfo>[]),
          ref
              .read(downloadsProvider(widget.competitionId).future)
              .catchError((_) => <DownloadableFileInfo>[]),
        ]);
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
                onSafNotConfigured: (kind) => _navigateToSettings(kind),
              ),
              const SizedBox(height: 12),
              _AirspaceCard(
                competitionId: widget.competitionId,
                competition: widget.competition,
                onDownloadError: _appendDownloadError,
                onSafNotConfigured: (kind) => _navigateToSettings(kind),
              ),
              const SizedBox(height: 12),
              _WaypointsCard(
                competitionId: widget.competitionId,
                competition: widget.competition,
                onDownloadError: _appendDownloadError,
                onSafNotConfigured: (kind) => _navigateToSettings(kind),
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
          onTap: () => launchUrl(Uri.parse(competition.soaringspotUrl)),
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
    required this.onSafNotConfigured,
  });

  final BookmarkedCompetition competition;
  final String competitionId;
  final ValueChanged<String> onDownloadError;

  /// Called when SAF is not configured; [kind] is `"task"`.
  final ValueChanged<String> onSafNotConfigured;

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
          onSafNotConfigured: onSafNotConfigured,
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
    required this.onSafNotConfigured,
  });

  final String competitionId;
  final String selectedClass;
  final ValueChanged<String> onDownloadError;

  /// Called with `"task"` when SAF is not configured during task install.
  final ValueChanged<String> onSafNotConfigured;

  @override
  ConsumerState<_TaskSection> createState() => _TaskSectionState();
}

class _TaskSectionState extends ConsumerState<_TaskSection> {
  bool _downloading = false;

  Future<void> _installTask(TaskInfo task) async {
    setState(() => _downloading = true);
    try {
      final result = await ref.read(downloadAndInstallTaskProvider)(
        task.taskUrl,
      );
      if (!mounted) return;
      result.fold((f) => widget.onDownloadError(_failureMessage(f)), (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Task downloaded'),
            backgroundColor: context.appColors.success,
          ),
        );
        ref.invalidate(xcsoarDirectoryUriProvider);
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      if (e.code == 'SAF_NOT_CONFIGURED') {
        widget.onSafNotConfigured('task');
      } else {
        widget.onDownloadError(e.message ?? 'Install failed');
      }
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
              label: Text(downloading ? 'Downloading...' : 'Download task'),
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
// Airspace & Waypoints cards
// ---------------------------------------------------------------------------

class _AirspaceCard extends ConsumerWidget {
  const _AirspaceCard({
    required this.competitionId,
    required this.competition,
    required this.onDownloadError,
    required this.onSafNotConfigured,
  });

  final String competitionId;
  final BookmarkedCompetition competition;
  final ValueChanged<String> onDownloadError;

  /// Called when SAF is not configured during airspace download.
  final ValueChanged<String> onSafNotConfigured;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadsAsync = ref.watch(downloadsProvider(competitionId));
    return downloadsAsync.when(
      skipLoadingOnReload: true,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _ErrorRetry(
        message: _failureMessage(err),
        onRetry: () => ref.invalidate(downloadsProvider(competitionId)),
      ),
      data: (files) {
        final file = files
            .where((f) => f.kind == DownloadableFileKind.airspace)
            .firstOrNull;
        if (file == null) {
          return Text(
            'No airspace file available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          );
        }
        return _FileDownloadCard(
          competitionId: competitionId,
          fileInfo: file,
          installedVersion: competition.airspaceVersion,
          onDownloadError: onDownloadError,
          onSafNotConfigured: onSafNotConfigured,
          downloadKind: 'airspace',
          sectionTitle: 'Airspace',
          sectionIcon: Icons.public,
          successMessage: 'Airspace downloaded',
        );
      },
    );
  }
}

class _WaypointsCard extends ConsumerWidget {
  const _WaypointsCard({
    required this.competitionId,
    required this.competition,
    required this.onDownloadError,
    required this.onSafNotConfigured,
  });

  final String competitionId;
  final BookmarkedCompetition competition;
  final ValueChanged<String> onDownloadError;

  /// Called when SAF is not configured during waypoints download.
  final ValueChanged<String> onSafNotConfigured;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadsAsync = ref.watch(downloadsProvider(competitionId));
    return downloadsAsync.when(
      skipLoadingOnReload: true,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _ErrorRetry(
        message: _failureMessage(err),
        onRetry: () => ref.invalidate(downloadsProvider(competitionId)),
      ),
      data: (files) {
        final file = files
            .where((f) => f.kind == DownloadableFileKind.waypoints)
            .firstOrNull;
        if (file == null) {
          return Text(
            'No waypoint file available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          );
        }
        return _FileDownloadCard(
          competitionId: competitionId,
          fileInfo: file,
          installedVersion: competition.waypointsVersion,
          onDownloadError: onDownloadError,
          onSafNotConfigured: onSafNotConfigured,
          downloadKind: 'waypoints',
          sectionTitle: 'Waypoints',
          sectionIcon: Icons.location_on_outlined,
          successMessage: 'Waypoints downloaded',
        );
      },
    );
  }
}

/// Shared download card for a single airspace or waypoints file.
///
/// Shows the file metadata, a "NEW UPDATE" badge when a newer version is
/// available, and a "Download" / "Downloading…" action button.
class _FileDownloadCard extends ConsumerStatefulWidget {
  const _FileDownloadCard({
    required this.competitionId,
    required this.fileInfo,
    required this.installedVersion,
    required this.onDownloadError,
    required this.onSafNotConfigured,
    required this.downloadKind,
    required this.sectionTitle,
    required this.sectionIcon,
    required this.successMessage,
  });

  final String competitionId;
  final DownloadableFileInfo fileInfo;

  /// The version token stored on [BookmarkedCompetition] at last install.
  final String? installedVersion;
  final ValueChanged<String> onDownloadError;

  /// Called with [downloadKind] when SAF is not configured.
  final ValueChanged<String> onSafNotConfigured;

  /// `"airspace"` or `"waypoints"` — passed back via [onSafNotConfigured].
  final String downloadKind;
  final String sectionTitle;
  final IconData sectionIcon;
  final String successMessage;

  @override
  ConsumerState<_FileDownloadCard> createState() => _FileDownloadCardState();
}

class _FileDownloadCardState extends ConsumerState<_FileDownloadCard> {
  bool _downloading = false;

  /// True when the scraped version token differs from the stored install token.
  bool get _hasNewUpdate =>
      widget.fileInfo.publishedVersion != null &&
      widget.fileInfo.publishedVersion != widget.installedVersion;

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final result = await ref.read(downloadAndInstallFileProvider).call(
        competitionId: widget.competitionId,
        fileInfo: widget.fileInfo,
      );
      if (!mounted) return;
      result.fold(
        (f) => widget.onDownloadError(_failureMessage(f)),
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.successMessage),
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
        widget.onSafNotConfigured(widget.downloadKind);
      } else {
        widget.onDownloadError(e.message ?? 'Install failed');
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fileInfo = widget.fileInfo;
    final sizeText = fileInfo.fileSize != null
        ? _formatBytes(fileInfo.fileSize!)
        : null;

    return TwoToneCard(
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.sectionTitle, style: theme.textTheme.headlineSmall),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                widget.sectionIcon,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    Text(
                      fileInfo.filename,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (sizeText != null)
                      Text(
                        ' ($sizeText)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.secondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      footer: Row(
        children: [
          Icon(Icons.history, size: 16, color: colorScheme.secondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              fileInfo.publishedVersion ?? '',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: colorScheme.secondary,
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: _downloading ? null : _download,
            style: AppButtonStyles.ghost(context),
            icon: _downloading
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  )
                : const Icon(Icons.download, size: 16),
            label: Text(_downloading ? 'Downloading...' : 'Download'),
          ),
        ],
      ),
    );
  }

  /// Converts a byte count to a human-readable string (e.g. "134.8 kB").
  static String _formatBytes(int bytes) {
    if (bytes < 1000) return '$bytes B';
    if (bytes < 1000000) return '${(bytes / 1000).toStringAsFixed(1)} kB';
    return '${(bytes / 1000000).toStringAsFixed(1)} MB';
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
