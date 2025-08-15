import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_that_thought/models/thought.dart';
import 'package:hold_that_thought/providers/thought_providers.dart';
import 'package:hold_that_thought/screens/home_screen.dart';
import 'package:hold_that_thought/widgets/add_thought_sheet.dart';

void main() {
  group('HomeScreen Widget Tests', () {
    testWidgets('shows empty state message when there are no thoughts',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Override the provider to return an empty stream
            thoughtsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // Let the stream emit the empty list
      await tester.pump();

      expect(find.text('No thoughts yet. Tap the + button to add one!'),
          findsOneWidget);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('displays a list of thoughts', (WidgetTester tester) async {
      final mockThoughts = [
        Thought.create(text: 'First test thought'),
        Thought.create(text: 'Second test thought'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Override the provider to return a stream with our mock thoughts
            thoughtsProvider.overrideWith((ref) => Stream.value(mockThoughts)),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      await tester.pump();

      expect(find.text('First test thought'), findsOneWidget);
      expect(find.text('Second test thought'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('tapping FAB opens the AddThoughtSheet',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            thoughtsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      await tester.pump();

      // Ensure the sheet is not visible initially
      expect(find.byType(AddThoughtSheet), findsNothing);

      // Tap the FloatingActionButton
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle(); // Wait for the sheet animation

      // Verify the sheet is now visible
      expect(find.byType(AddThoughtSheet), findsOneWidget);
    });
  });
}
