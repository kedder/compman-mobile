import 'package:compman_mobile/core/theme/app_theme.dart';
import 'package:compman_mobile/core/widgets/app_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('renders uppercase label text', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const AppBadge(
          label: 'live',
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
    );

    expect(find.text('LIVE'), findsOneWidget);
  });

  testWidgets('renders ring container when hasRing is true', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const AppBadge(
          label: 'new update',
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          hasRing: true,
        ),
      ),
    );

    final ringFinder = find.descendant(
      of: find.byType(AppBadge),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).border != null,
      ),
    );

    expect(ringFinder, findsOneWidget);
  });
}
