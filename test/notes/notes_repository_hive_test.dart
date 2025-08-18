import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hold_that_thought/notes/note_model.dart';
import 'package:hold_that_thought/notes/notes_repository.dart';
import 'package:hold_that_thought/storage/hive_boxes.dart';
import 'package:hold_that_thought/sync/fake_sync_service.dart';
import 'package:hold_that_thought/sync/sync_service.dart';

void main() {
  group('NotesRepository with Hive', () {
    late Box<Note> notesBox;
    late NotesRepository repository;

    setUp(() async {
      Hive.init(null);
      Hive.registerAdapter(NoteAdapter());
      Hive.registerAdapter(ChangeTypeAdapter());
      Hive.registerAdapter(NoteChangeAdapter());
      notesBox = await Hive.openBox<Note>(HiveBoxes.notes);
      final pendingOpsBox = await Hive.openBox<NoteChange>(HiveBoxes.pendingOps);
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

    tearDown(() async {
      await Hive.deleteFromDisk();
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
