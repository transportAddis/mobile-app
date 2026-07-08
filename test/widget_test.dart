import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_app/main.dart';

void main() {
  testWidgets('App boots and renders LoginScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartTransitApp());
    await tester.pump();

    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
