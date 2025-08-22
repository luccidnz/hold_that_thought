import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_that_thought/notes/notes_repository.dart';
import 'package:hold_that_thought/pages/capture_page.dart';
import 'package:hold_that_thought/sync/sync_service.dart';
import 'package:mockito/annotations.dart';
import '../test_helpers.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_text_scale_test.mocks.dart';

@GenerateMocks([NotesRepository])
void main() {
  late MockNotesRepository mockNotesRepository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockNotesRepository = MockNotesRepository();
    when(mockNotesRepository.getDistinctTags()).thenReturn({});
    when(mockNotesRepository.getPinnedNotes()).thenReturn([]);
    when(mockNotesRepository.getUnpinnedNotes(
            query: anyNamed('query'), tags: anyNamed('tags')))
        .thenReturn([]);
    when(mockNotesRepository.syncStatus)
        .thenAnswer((_) => Stream.value(SyncStatus.ok));
  });

  testWidgets('Home screen golden test with different text scales',
      (WidgetTester tester) async {
    // Test at 1.0x text scale
    await tester.pumpWidget(buildTestableWidget(
      overrides: [
        notesRepositoryProvider.overrideWith((ref) => mockNotesRepository),
      ],
      child: const CapturePage(),
    ));
    await expectLater(
      find.byType(CapturePage),
      matchesGoldenFile('goldens/home_1x.png'),
    );

    // Test at 2.0x text scale
    await tester.pumpWidget(buildTestableWidget(
      overrides: [
        notesRepositoryProvider.overrideWith((ref) => mockNotesRepository),
      ],
      child: const MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: CapturePage(),
      ),
    ));
    await expectLater(
      find.byType(CapturePage),
      matchesGoldenFile('goldens/home_2x.png'),
    );
  });
}
