import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:compman_mobile/app.dart';

void main() {
  testWidgets('App renders placeholder screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: CompmanApp()));

    expect(find.text('Compman Mobile'), findsWidgets);
    expect(find.text('Ready to build!'), findsOneWidget);
  });
}
