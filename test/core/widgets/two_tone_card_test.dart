import 'package:compman_mobile/core/theme/app_theme.dart';
import 'package:compman_mobile/core/widgets/two_tone_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('renders header and footer widgets', (tester) async {
    await tester.pumpWidget(
      _wrap(const TwoToneCard(header: Text('Header'), footer: Text('Footer'))),
    );

    expect(find.text('Header'), findsOneWidget);
    expect(find.text('Footer'), findsOneWidget);
  });
}
