import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/di/providers.dart';
import 'features/xcsoar/presentation/screens/xcsoar_directory_settings_screen.dart';
import 'core/theme/app_theme.dart';
import 'features/competitions/presentation/screens/bookmarks_screen.dart';
import 'features/competitions/presentation/screens/competition_detail_screen.dart';
import 'features/competitions/presentation/screens/competition_list_screen.dart';

/// Root application widget with GoRouter-based navigation.
class CompmanApp extends StatefulWidget {
  /// Creates the [CompmanApp].
  ///
  /// When [initialCompetitionId] is provided, the app opens the Competition
  /// Detail screen for that ID on cold start, with the home screen seeded
  /// behind it so the back button works.
  const CompmanApp({super.key, this.initialCompetitionId});

  /// If non-null, the app navigates to this competition's detail screen after
  /// the first frame, placing the home screen behind it on the back-stack.
  final String? initialCompetitionId;

  @override
  State<CompmanApp> createState() => _CompmanAppState();
}

class _CompmanAppState extends State<CompmanApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _buildRouter();
    final id = widget.initialCompetitionId;
    if (id != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _router.push('/competitions/$id'),
      );
    }
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Compman Mobile',
      theme: AppTheme.light(),
      routerConfig: _router,
    );
  }
}

GoRouter _buildRouter() => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const BookmarksScreen()),
    GoRoute(
      path: '/add',
      builder: (context, state) => const CompetitionListScreen(),
    ),
    GoRoute(
      path: '/competitions/:id',
      builder: (context, state) =>
          CompetitionDetailScreen(competitionId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
    GoRoute(
      path: '/settings/xcsoar-directory',
      builder: (context, state) => XcsoarDirectorySettingsScreen(
        fromDownloadFlow: state.uri.queryParameters['from'] == 'download',
      ),
    ),
  ],
);

/// About screen shown from the home screen header menu.
class AboutScreen extends ConsumerWidget {
  /// Creates the [AboutScreen].
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageInfoAsync = ref.watch(packageInfoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: Center(
        child: packageInfoAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (_, _) => Text(
            'Version unavailable',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          data: (info) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Compman Mobile',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Version: ${info.version}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Data provided by SoaringSpot',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
