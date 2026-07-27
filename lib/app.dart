import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/di/providers.dart';
import 'features/xcsoar/presentation/screens/xcsoar_directory_settings_screen.dart';
import 'core/theme/app_theme.dart';
import 'features/competitions/presentation/screens/bookmarks_screen.dart';
import 'features/competitions/presentation/screens/competition_detail_screen.dart';
import 'features/competitions/presentation/screens/competition_list_screen.dart';
import 'features/competitions/presentation/screens/flight_log_screen.dart';

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
    GoRoute(
      path: '/competitions/:id/flight-logs',
      builder: (context, state) =>
          FlightLogScreen(competitionId: state.pathParameters['id']!),
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
      body: packageInfoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Version unavailable')),
        data: (info) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Semantics(
                      label: 'App icon',
                      excludeSemantics: true,
                      child: Image.asset(
                        'assets/icon/app_icon.png',
                        width: 96,
                        height: 96,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Competition Manager',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'An Android app for glider pilots. Browse competitions, '
                      'bookmark the ones you attend, and download waypoint, '
                      'airspace, and task files directly to XCSoar on your device.',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Version ${info.version}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const ListTile(
                leading: Icon(Icons.person_outline),
                title: Text('Written by Andrey Lebedev'),
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('Source & bug reports'),
                subtitle: const Text('github.com/kedder/compman-mobile'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => launchUrl(
                  Uri.parse('https://github.com/kedder/compman-mobile'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  'Data sources',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Competition data'),
                subtitle: const Text('soaringspot.com'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => launchUrl(
                  Uri.parse('https://www.soaringspot.com/'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('XCSoar tasks'),
                subtitle: const Text('soarscore.com'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => launchUrl(
                  Uri.parse('https://soarscore.com/'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
