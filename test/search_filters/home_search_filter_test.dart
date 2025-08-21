import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_that_thought/notes/note_model.dart';
import 'package:hold_that_thought/notes/notes_repository.dart';
import 'package:hold_that_thought/pages/capture_page.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hold_that_thought/sync/sync_service.dart';
import '../test_helpers.dart';

import 'home_search_filter_test.mocks.dart';

@GenerateMocks([NotesRepository])
void main() {
  group('HomeSearchFilter', () {
    late MockNotesRepository mockNotesRepository;
    final note1 = Note(id: '1', title: 'Test Note 1', body: 'flutter', createdAt: DateTime.now(), updatedAt: DateTime.now(), isPinned: false, tags: ['work', 'flutter']);
    final note2 = Note(id: '2', title: 'Test Note 2', body: 'personal', createdAt: DateTime.now(), updatedAt: DateTime.now(), isPinned: true, tags: ['personal']);
    final note3 = Note(id: '3', title: 'Test Note 3', body: 'work note', createdAt: DateTime.now(), updatedAt: DateTime.now(), isPinned: true, tags: ['work']);

    setUp(() {
      mockNotesRepository = MockNotesRepository();
      when(mockNotesRepository.getFilteredNotes(query: anyNamed('query'), tags: anyNamed('tags'))).thenReturn([note1, note2, note3]);
      when(mockNotesRepository.getPinnedNotes()).thenReturn([note2, note3]);
      when(mockNotesRepository.getUnpinnedNotes(query: anyNamed('query'), tags: anyNamed('tags'))).thenReturn([note1]);
      when(mockNotesRepository.getDistinctTags()).thenReturn({'work', 'flutter', 'personal'});
      when(mockNotesRepository.syncStatus).thenAnswer((_) => Stream.value(SyncStatus.ok));
    });

    testWidgets('search query filters results', (WidgetTester tester) async {
      when(mockNotesRepository.getUnpinnedNotes(query: 'Flutter', tags: {})).thenReturn([note1]);
      when(mockNotesRepository.getPinnedNotes()).thenReturn([]); // No pinned notes for this test

      await tester.pumpWidget(buildTestableWidget(
        overrides: [
          notesRepositoryProvider.overrideWith((ref) => mockNotesRepository),
        ],
        child: const CapturePage(),
      ));

      await tester.enterText(find.byType(TextField), 'Flutter');
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      expect(find.text('Test Note 1'), findsOneWidget);
      expect(find.text('Test Note 2'), findsNothing);
    });

    testWidgets('selecting tags filters results', (WidgetTester tester) async {
      when(mockNotesRepository.getUnpinnedNotes(query: '', tags: {'personal'})).thenReturn([]);
      when(mockNotesRepository.getPinnedNotes()).thenReturn([note2, note3]);

      await tester.pumpWidget(buildTestableWidget(
        overrides: [
          notesRepositoryProvider.overrideWith((ref) => mockNotesRepository),
        ],
        child: const CapturePage(),
      ));

      await tester.tap(find.widgetWithText(FilterChip, 'personal'));
      await tester.pumpAndSettle();

      expect(find.text('Test Note 2'), findsOneWidget);
      expect(find.text('Test Note 1'), findsNothing);
    });

    testWidgets('filters are persisted', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'searchQuery': 'personal',
        'selectedTags': ['personal'],
      });
      when(mockNotesRepository.getUnpinnedNotes(query: 'personal', tags: {'personal'})).thenReturn([]);
      when(mockNotesRepository.getPinnedNotes()).thenReturn([note2, note3]);

      await tester.pumpWidget(buildTestableWidget(
        overrides: [
          notesRepositoryProvider.overrideWith((ref) => mockNotesRepository),
        ],
        child: const CapturePage(),
      ));

      await tester.pumpAndSettle();

      expect(find.text('Test Note 2'), findsOneWidget);
      expect(find.text('Test Note 1'), findsNothing);
    });
  });
}
