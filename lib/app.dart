import 'package:flutter/material.dart';

/// Root application widget. Will be updated in a future session to configure
/// GoRouter and bottom navigation once feature screens are implemented.
class CompmanApp extends StatelessWidget {
  /// Creates the [CompmanApp].
  const CompmanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Compman Mobile',
      home: _PlaceholderScreen(),
    );
  }
}

/// Temporary placeholder home screen. Will be replaced by the competition list
/// screen with bottom navigation in a future session.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compman Mobile')),
      body: const Center(
        child: Text('Ready to build!'),
      ),
    );
  }
}
