import 'package:compman_mobile/core/theme/app_theme.dart';
import 'package:compman_mobile/core/widgets/icon_meta_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('renders icon and text and applies custom color', (tester) async {
    const customColor = Colors.orange;

    await tester.pumpWidget(
      _wrap(
        const IconMetaRow(
          icon: Icons.link,
          text: 'https://example.com',
          color: customColor,
        ),
      ),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.link));
    final text = tester.widget<Text>(find.text('https://example.com'));

    expect(icon.color, customColor);
    expect(text.style?.color, customColor);
  });
}
