import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_that_thought/notes/note_model.dart';
import 'package:hold_that_thought/notes/notes_repository.dart';
import 'package:hold_that_thought/pages/capture_page.dart';
import 'package:hold_that_thought/quick_capture/quick_capture_sheet.dart';
import 'package:hold_that_thought/routing/app_router.dart';

class FakeNotesRepository implements NotesRepository {
  Note? lastCreatedNote;
  String? lastDeletedNoteId;

  @override
  bool exists(String id) {
    return true; // Assume all notes exist for this test
  }

  @override
  Note create({
    required String title,
    required String body,
    required bool isPinned,
  }) {
    final note = Note(
      id: 'new-id',
      title: title,
      body: body,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isPinned: isPinned,
    );
    lastCreatedNote = note;
    return note;
  }

  @override
  void delete(String id) {
    lastDeletedNoteId = id;
  }
}

void main() {
  testWidgets('QuickCaptureSheet widget test', (WidgetTester tester) async {
    final fakeNotesRepository = FakeNotesRepository();
    final container = ProviderContainer(
      overrides: [
        notesRepositoryProvider.overrideWithValue(fakeNotesRepository),
      ],
    );
    final router = container.read(appRouterProvider);

    await tester.pumpWidget(
      ProviderScope(
        parent: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    // Open the sheet
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(QuickCaptureSheet), findsOneWidget);

    // Enter title and save
    await tester.enterText(find.byType(TextField).first, 'Test Title');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Verify SnackBar and repository call
    expect(find.text('Saved'), findsOneWidget);
    expect(fakeNotesRepository.lastCreatedNote?.title, 'Test Title');

    // Tap View
    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();
    expect(find.text('Note ID: new-id'), findsOneWidget);

    // Go back to capture page to test Undo
    router.go(AppRoutes.home());
    await tester.pumpAndSettle();

    // Re-open sheet and save to show SnackBar again
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Test Title 2');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Tap Undo
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(fakeNotesRepository.lastDeletedNoteId, 'new-id');
  });
}
