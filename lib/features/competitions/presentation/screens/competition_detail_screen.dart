import 'package:flutter/material.dart';

/// Stub detail screen for a competition.
///
/// Full implementation is planned for a future session.
class CompetitionDetailScreen extends StatelessWidget {
  /// Creates the [CompetitionDetailScreen].
  const CompetitionDetailScreen({
    super.key,
    required this.competitionId,
  });

  /// The identifier of the competition to display.
  final String competitionId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Competition')),
      body: const Center(child: Text('Coming soon')),
    );
  }
}
