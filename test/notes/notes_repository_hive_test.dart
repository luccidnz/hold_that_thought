import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hold_that_thought/notes/note_model.dart';
import 'package:hold_that_thought/notes/notes_repository.dart';
import 'package:hold_that_thought/storage/hive_boxes.dart';
import 'package:hold_that_thought/sync/fake_sync_service.dart';
import 'package:hold_that_thought/sync/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('NotesRepository with Hive', () {
    late Box<Note> notesBox;
    late Box<NoteChange> pendingOpsBox;
    late NotesRepository repository;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      try {
        Hive.registerAdapter(NoteAdapter());
        Hive.registerAdapter(ChangeTypeAdapter());
        Hive.registerAdapter(NoteChangeAdapter());
      } catch (e) {
        // Adapters already registered, safe to ignore.
      }
      notesBox = await Hive.openBox<Note>(HiveBoxes.notes);
      pendingOpsBox = await Hive.openBox<NoteChange>(HiveBoxes.pendingOps);
    });

    setUp(() async {
      await notesBox.clear();
      await pendingOpsBox.clear();
      final syncService = FakeSyncService();
      repository = NotesRepository(syncService, notesBox, pendingOpsBox);

      // Seed data
      final now = DateTime.now();
      await notesBox.put(
        '1',
        Note(id: '1', title: 'Flutter work', body: '', createdAt: now, updatedAt: now, isPinned: false, tags: ['work', 'flutter']),
      );
      await notesBox.put(
        '2',
        Note(id: '2', title: 'Personal note', body: '', createdAt: now, updatedAt: now, isPinned: true, tags: ['personal']),
      );
    });

    test('search filters notes', () {
      final results = repository.getUnpinnedNotes(query: 'Flutter');
      expect(results.length, 1);
      expect(results.first.id, '1');
    });

    test('tag filters notes', () {
      final results = repository.getUnpinnedNotes(tags: {'work'});
      expect(results.length, 1);
      expect(results.first.id, '1');
    });
  });
}
