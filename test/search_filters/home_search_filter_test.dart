import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_that_thought/notes/notes_repository.dart';
import 'package:hold_that_thought/pages/capture_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeNotesRepository extends NotesRepository {
  // Use the default notes from the real repository
}

void main() {
  group('HomeSearchFilter', () {
    testWidgets('search query filters results', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notesRepositoryProvider.overrideWithValue(FakeNotesRepository()),
          ],
          child: const MaterialApp(home: CapturePage()),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Flutter');
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
      expect(find.text('Test Note 1'), findsOneWidget);
      expect(find.text('Test Note 2'), findsNothing);
    });

    testWidgets('selecting tags filters results', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notesRepositoryProvider.overrideWithValue(FakeNotesRepository()),
          ],
          child: const MaterialApp(home: CapturePage()),
        ),
      );

      await tester.tap(find.widgetWithText(FilterChip, 'personal'));
      await tester.pumpAndSettle();
      expect(find.text('Test Note 2'), findsOneWidget);
      expect(find.text('Test Note 1'), findsNothing);
    });

    testWidgets('search and tags combine correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notesRepositoryProvider.overrideWithValue(FakeNotesRepository()),
          ],
          child: const MaterialApp(home: CapturePage()),
        ),
      );

      await tester.enterText(find.byType(TextField), 'note');
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
      await tester.tap(find.widgetWithText(FilterChip, 'work'));
      await tester.pumpAndSettle();

      expect(find.text('Test Note 1'), findsOneWidget);
      expect(find.text('Test Note 3'), findsOneWidget);
      expect(find.text('Test Note 2'), findsNothing);
    });

    testWidgets('pinned notes are always shown', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notesRepositoryProvider.overrideWithValue(FakeNotesRepository()),
          ],
          child: const MaterialApp(home: CapturePage()),
        ),
      );

      // Note 2 and 3 are pinned
      expect(find.text('Test Note 2'), findsOneWidget);
      expect(find.text('Test Note 3'), findsOneWidget);

      // Filter by a tag that only unpinned notes have
      await tester.tap(find.widgetWithText(FilterChip, 'flutter'));
      await tester.pumpAndSettle();

      // Pinned notes should still be visible
      expect(find.text('Test Note 2'), findsOneWidget);
      expect(find.text('Test Note 3'), findsOneWidget);
    });

    testWidgets('filters are persisted', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'searchQuery': 'personal',
        'selectedTags': ['personal'],
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notesRepositoryProvider.overrideWithValue(FakeNotesRepository()),
          ],
          child: const MaterialApp(home: CapturePage()),
        ),
      );

      await tester.pumpAndSettle(); // wait for filters to load

      expect(find.text('Test Note 2'), findsOneWidget);
      expect(find.text('Test Note 1'), findsNothing);
    });
  });
}
