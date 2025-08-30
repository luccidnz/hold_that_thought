// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:hold_that_thought/app.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    // Build the app; smoke test that it pumps without errors.
    await tester.pumpWidget(const HoldThatThoughtApp());
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Hold That Thought'), findsOneWidget);
  });
}
