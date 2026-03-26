import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF0D7FC1),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const BookmarksScreen(),
    ),
    GoRoute(
      path: '/add',
      builder: (context, state) => const CompetitionListScreen(),
    ),
    GoRoute(
      path: '/competitions/:id',
      builder: (context, state) => CompetitionDetailScreen(
        competitionId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/about',
      builder: (context, state) => const _AboutScreen(),
    ),
  ],
);

/// Stub About screen shown from the home screen header menu.
class _AboutScreen extends StatelessWidget {
  const _AboutScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Compman Mobile'),
            SizedBox(height: 8),
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('Data provided by SoaringSpot'),
          ],
        ),
      ),
    );
  }
}
