import 'package:compman_mobile/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: CompmanApp()));
    // GoRouter renders; give it a frame to settle the initial route.
    await tester.pump();

    expect(find.text('Your competitions'), findsOneWidget);
  });
}
