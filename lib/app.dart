import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/di/providers.dart';
import 'core/platform/xcsoar_directory_settings_screen.dart';
import 'core/theme/app_theme.dart';
import 'features/competitions/presentation/screens/bookmarks_screen.dart';
import 'features/competitions/presentation/screens/competition_detail_screen.dart';
import 'features/competitions/presentation/screens/competition_list_screen.dart';

/// Root application widget with GoRouter-based navigation.
class CompmanApp extends StatelessWidget {
  /// Creates the [CompmanApp].
  const CompmanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Compman Mobile',
      theme: AppTheme.light(),
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
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
        fromDownloadFlow:
            state.uri.queryParameters['from'] == 'download',
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
