import 'package:flutter_test/flutter_test.dart';

import 'package:compman_mobile/main.dart';

void main() {
  testWidgets('App renders hello screen', (WidgetTester tester) async {
    await tester.pumpWidget(const CompmanApp());

    expect(find.text('Compman Mobile'), findsWidgets);
    expect(find.text('Hello, World!'), findsOneWidget);
  });
}
