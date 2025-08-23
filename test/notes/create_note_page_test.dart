import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_that_thought/notes/create_note_page.dart';
import 'package:hold_that_thought/notes/note_model.dart';
import 'package:hold_that_thought/notes/notes_repository.dart';
import 'package:hold_that_thought/sync/sync_service.dart';

class FakeNotesRepo extends ChangeNotifier implements NotesRepository {
  Note? saved;

  @override
  Future<Note> create({
    required String title,
    String? body,
    required bool isPinned,
    List<String>? tags,
  }) async {
    saved = Note(
      id: '123',
      title: title,
      body: body,
      isPinned: isPinned,
      tags: tags ?? [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return saved!;
  }

  @override
  Stream<SyncStatus> get syncStatus => Stream.value(SyncStatus.ok);

  @override
  List<Note> getFilteredNotes({String? query, Set<String> tags = const {}}) =>
      [];

  @override
  List<Note> getPinnedNotes() => [];

  @override
  List<Note> getUnpinnedNotes({String? query, Set<String> tags = const {}}) =>
      [];

  @override
  Set<String> getDistinctTags() => {};

  @override
  bool exists(String id) => false;

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> update(Note note) async {}

  @override
  Future<void> syncOnce() async {}

  @override
  Future<void> clearAllBoxes() async {}
}

void main() {
  testWidgets('saves note and navigates back', (tester) async {
    final fakeRepo = FakeNotesRepo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [notesRepositoryProvider.overrideWith((ref) => fakeRepo)],
        child: const MaterialApp(home: CreateNotePage()),
      ),
    );
    await tester.enterText(find.byKey(const Key('titleField')), 'Hello');
    await tester.enterText(find.byKey(const Key('bodyField')), 'World');
    await tester.tap(find.byKey(const Key('saveButton')));
    await tester.pump();

    expect(fakeRepo.saved?.title, 'Hello');
    expect(fakeRepo.saved?.body, 'World');
  });

  testWidgets('save button is disabled when title is empty', (tester) async {
    final fakeRepo = FakeNotesRepo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [notesRepositoryProvider.overrideWith((ref) => fakeRepo)],
        child: const MaterialApp(home: CreateNotePage()),
      ),
    );

    final saveButton =
        tester.widget<TextButton>(find.byKey(const Key('saveButton')));
    expect(saveButton.onPressed, isNull);
  });
}
