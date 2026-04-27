import 'package:compman_mobile/core/theme/app_theme.dart';
import 'package:compman_mobile/core/widgets/app_badge.dart';
import 'package:compman_mobile/features/competitions/domain/entities/competition_status.dart';
import 'package:compman_mobile/features/competitions/presentation/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('renders correct labels for each competition status', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusBadge(status: CompetitionStatus.live),
            StatusBadge(status: CompetitionStatus.upcoming),
            StatusBadge(status: CompetitionStatus.past),
          ],
        ),
      ),
    );

    expect(find.byType(AppBadge), findsNWidgets(3));
    expect(find.text('LIVE'), findsOneWidget);
    expect(find.text('UPCOMING'), findsOneWidget);
    expect(find.text('PAST'), findsOneWidget);
  });
}
