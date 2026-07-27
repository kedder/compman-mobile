import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/di/providers.dart';
import '../../../domain/entities/pending_download.dart';
import '../../providers/competitions_providers.dart';

/// Which file a download button targets.
enum DownloadKind { task, airspace, waypoints }

/// Dismissible download error messages shown at the bottom of the Competition
/// Detail screen.
final downloadErrorsProvider =
    NotifierProvider.autoDispose<DownloadErrorsNotifier, List<String>>(
      DownloadErrorsNotifier.new,
    );

/// Notifier backing [downloadErrorsProvider].
class DownloadErrorsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => const [];

  /// Appends [message] to the error list.
  void add(String message) => state = [...state, message];

  /// Removes [message] from the error list.
  void dismiss(String message) =>
      state = state.where((e) => e != message).toList();
}

/// Loading flag for the task download button.
final taskDownloadingProvider =
    NotifierProvider.autoDispose<BoolNotifier, bool>(BoolNotifier.new);

/// Loading flag for the airspace download button.
final airspaceDownloadingProvider =
    NotifierProvider.autoDispose<BoolNotifier, bool>(BoolNotifier.new);

/// Loading flag for the waypoints download button.
final waypointsDownloadingProvider =
    NotifierProvider.autoDispose<BoolNotifier, bool>(BoolNotifier.new);

/// Simple boolean flag notifier used by the per-download-kind loading providers.
class BoolNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  // ignore: avoid_setters_without_getters
  set value(bool v) => state = v;
}

/// Provides [navigateToSettings] for [ConsumerState] subclasses that trigger
/// SAF directory setup from a download action.
mixin SafNavigationMixin<W extends ConsumerStatefulWidget> on ConsumerState<W> {
  /// Navigates to `/settings/xcsoar-directory` with [kind] and [competitionId]
  /// encoded as query parameters. On return:
  /// - SAF configured → calls [onConfigured] to resume the download.
  /// - Aborted → appends a cancellation error banner.
  Future<void> navigateToSettings({
    required String competitionId,
    required DownloadKind kind,
    required Future<void> Function() onConfigured,
  }) async {
    final pending = PendingDownload(
      competitionId: competitionId,
      kind: kind.name,
    );
    await context.push<void>(
      '/settings/xcsoar-directory?from=download&${pending.toQueryString()}',
    );
    if (!mounted) return;
    final storedUri = await ref.read(xcsoarDirectoryUriProvider.future);
    if (!mounted) return;
    if (storedUri != null && storedUri.isNotEmpty) {
      await onConfigured();
    } else {
      ref
          .read(downloadErrorsProvider.notifier)
          .add(
            'XCSoar folder setup was cancelled. '
            'Go to Settings → XCSoar Folder to try again.',
          );
    }
  }
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
