import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/di/providers.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/app_badge.dart';
import '../../../../../core/widgets/error_retry.dart';
import '../../../../../core/widgets/two_tone_card.dart';
import '../../../domain/entities/bookmarked_competition.dart';
import '../../../domain/entities/downloadable_file_info.dart';
import '../../providers/competitions_providers.dart';
import 'shared.dart';

/// Airspace download card for [competition], or a muted "not available"
/// message if the competition hasn't published one.
class AirspaceCard extends ConsumerWidget {
  /// Creates an [AirspaceCard].
  const AirspaceCard({super.key, required this.competition});

  final BookmarkedCompetition competition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadsAsync = ref.watch(downloadsProvider(competition.id));
    return downloadsAsync.when(
      skipLoadingOnReload: true,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => ErrorRetry(
        message: failureMessage(err),
        onRetry: () => ref.invalidate(downloadsProvider(competition.id)),
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
        return FileDownloadCard(
          competitionId: competition.id,
          fileInfo: file,
          installedVersion: competition.airspaceVersion,
          downloadKind: DownloadKind.airspace,
          sectionTitle: 'Airspace',
          sectionIcon: Icons.public,
          successMessagePrefix: 'Airspace downloaded as ',
        );
      },
    );
  }
}

/// Waypoints download card for [competition], or a muted "not available"
/// message if the competition hasn't published one.
class WaypointsCard extends ConsumerWidget {
  /// Creates a [WaypointsCard].
  const WaypointsCard({super.key, required this.competition});

  final BookmarkedCompetition competition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadsAsync = ref.watch(downloadsProvider(competition.id));
    return downloadsAsync.when(
      skipLoadingOnReload: true,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => ErrorRetry(
        message: failureMessage(err),
        onRetry: () => ref.invalidate(downloadsProvider(competition.id)),
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
        return FileDownloadCard(
          competitionId: competition.id,
          fileInfo: file,
          installedVersion: competition.waypointsVersion,
          downloadKind: DownloadKind.waypoints,
          sectionTitle: 'Waypoints',
          sectionIcon: Icons.location_on_outlined,
          successMessagePrefix: 'Waypoints downloaded as ',
        );
      },
    );
  }
}

/// Shared download card for a single airspace or waypoints file.
///
/// Shows the file metadata, a "NEW UPDATE" badge when a newer version is
/// available, and a "Download" / "Downloading…" action button.
class FileDownloadCard extends ConsumerStatefulWidget {
  /// Creates a [FileDownloadCard].
  const FileDownloadCard({
    super.key,
    required this.competitionId,
    required this.fileInfo,
    required this.installedVersion,
    required this.downloadKind,
    required this.sectionTitle,
    required this.sectionIcon,
    required this.successMessagePrefix,
  });

  final String competitionId;
  final DownloadableFileInfo fileInfo;

  /// The version token stored on [BookmarkedCompetition] at last install.
  final String? installedVersion;

  /// Scopes the correct downloading-flag provider and SAF navigation kind.
  final DownloadKind downloadKind;
  final String sectionTitle;
  final IconData sectionIcon;

  /// Prefixed to the on-device filename returned by
  /// [downloadAndInstallFileProvider] to build the confirmation SnackBar
  /// text, e.g. `'Airspace downloaded as '` + `'compman-airspace.txt'`.
  final String successMessagePrefix;

  @override
  ConsumerState<FileDownloadCard> createState() => _FileDownloadCardState();
}

class _FileDownloadCardState extends ConsumerState<FileDownloadCard>
    with SafNavigationMixin<FileDownloadCard> {
  /// True when the scraped version token differs from the stored install token.
  bool get _hasNewUpdate =>
      widget.fileInfo.publishedVersion != null &&
      widget.fileInfo.publishedVersion != widget.installedVersion;

  // Selects the correct downloading-flag provider for this card's kind.
  get _downloadingProvider => switch (widget.downloadKind) {
    DownloadKind.airspace => airspaceDownloadingProvider,
    DownloadKind.waypoints => waypointsDownloadingProvider,
    DownloadKind.task => taskDownloadingProvider,
  };

  Future<void> _download() async {
    ref.read(_downloadingProvider.notifier).value = true;
    try {
      final result = await ref
          .read(downloadAndInstallFileProvider)
          .call(competitionId: widget.competitionId, fileInfo: widget.fileInfo);
      if (!mounted) return;
      result.fold(
        (f) => ref.read(downloadErrorsProvider.notifier).add(failureMessage(f)),
        (filename) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.successMessagePrefix}$filename'),
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
          kind: widget.downloadKind,
          onConfigured: _download,
        );
      } else {
        ref
            .read(downloadErrorsProvider.notifier)
            .add(e.message ?? 'Install failed');
      }
    } finally {
      if (mounted) ref.read(_downloadingProvider.notifier).value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final downloading = ref.watch(_downloadingProvider);
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
            onPressed: downloading ? null : _download,
            style: AppButtonStyles.ghost(context),
            icon: downloading
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  )
                : const Icon(Icons.download, size: 16),
            label: Text(downloading ? 'Downloading...' : 'Download'),
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
