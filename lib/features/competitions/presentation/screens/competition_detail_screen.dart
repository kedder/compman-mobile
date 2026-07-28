import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/storage/last_viewed_local_datasource.dart';
import '../../../../core/widgets/error_retry.dart';
import '../../domain/entities/bookmarked_competition.dart';
import '../../domain/entities/downloadable_file_info.dart';
import '../../domain/entities/task_info.dart';
import '../providers/competitions_providers.dart';
import '../widgets/competition_detail/class_section.dart';
import '../widgets/competition_detail/error_banner.dart';
import '../widgets/competition_detail/file_download_card.dart';
import '../widgets/competition_detail/header_section.dart';
import '../widgets/competition_detail/shared.dart';
import '../widgets/competition_detail/xcsoar_directory_row.dart';

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
    extends ConsumerState<CompetitionDetailScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // whenData is a no-op when the provider is still AsyncLoading (e.g. in
    // widget tests that do not override settingsBoxProvider), avoiding any
    // platform-channel calls or FakeAsync deadlocks.
    ref.read(settingsBoxProvider).whenData((box) {
      LastViewedLocalDataSource(box).writeLastViewedId(widget.competitionId);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref.invalidate(todaysFlightLogsProvider);
    }
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
                ref.invalidate(todaysFlightLogsProvider);
              },
            ),
        ],
      ),
      body: competitionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorRetry(
          message: failureMessage(err),
          onRetry: () =>
              ref.invalidate(competitionDetailProvider(widget.competitionId)),
        ),
        data: (competition) {
          if (competition == null) {
            return const Center(child: Text('Competition not found.'));
          }
          return _CompetitionDetailBody(competition: competition);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _CompetitionDetailBody extends ConsumerWidget {
  const _CompetitionDetailBody({required this.competition});

  final BookmarkedCompetition competition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competitionId = competition.id;
    final downloadErrors = ref.watch(downloadErrorsProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(latestTasksProvider(competitionId));
        ref.invalidate(downloadsProvider(competitionId));
        ref.invalidate(todaysFlightLogsProvider);
        await Future.wait([
          ref
              .read(latestTasksProvider(competitionId).future)
              .catchError((_) => <TaskInfo>[]),
          ref
              .read(downloadsProvider(competitionId).future)
              .catchError((_) => <DownloadableFileInfo>[]),
        ]);
      },
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 128),
            children: [
              HeaderSection(competition: competition),
              const SizedBox(height: 24),
              ClassSection(competition: competition),
              if (competition.selectedClass != null) ...[
                const SizedBox(height: 12),
                AirspaceCard(competition: competition),
                const SizedBox(height: 12),
                WaypointsCard(competition: competition),
              ],
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              const XcsoarDirectoryRow(),
            ],
          ),
          if (downloadErrors.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var index = 0; index < downloadErrors.length; index++)
                      Padding(
                        padding: EdgeInsets.only(top: index == 0 ? 0 : 4),
                        child: ErrorBanner(
                          message: downloadErrors[index],
                          onDismiss: () => ref
                              .read(downloadErrorsProvider.notifier)
                              .dismiss(downloadErrors[index]),
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
