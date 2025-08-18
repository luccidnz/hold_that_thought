import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hold_that_thought/notes/note_model.dart';
import 'package:hold_that_thought/storage/hive_boxes.dart';
import 'package:hold_that_thought/sync/sync_service.dart';

void main() {
  group('HiveNotesTest', () {
    setUp(() async {
      Hive.init(null);
      Hive.registerAdapter(NoteAdapter());
      Hive.registerAdapter(ChangeTypeAdapter());
      Hive.registerAdapter(NoteChangeAdapter());
      await Hive.openBox<Note>(HiveBoxes.notes);
    });

    tearDown(() async {
      await Hive.deleteFromDisk();
    });

    test('create/update/delete persists', () async {
      final box = Hive.box<Note>(HiveBoxes.notes);
      final note = Note(
        id: '1',
        title: 't',
        body: 'b',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPinned: false,
      );
      await box.put(note.id, note);
      expect(box.get(note.id)?.title, 't');

      final updatedNote = note.copyWith(title: 'new title');
      await box.put(note.id, updatedNote);
      expect(box.get(note.id)?.title, 'new title');

      await box.delete(note.id);
      expect(box.get(note.id), isNull);
    });

    test('restart keeps data', () async {
      var box = Hive.box<Note>(HiveBoxes.notes);
      final note = Note(
        id: '1',
        title: 't',
        body: 'b',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPinned: false,
      );
      await box.put(note.id, note);

      await box.close();
      box = await Hive.openBox<Note>(HiveBoxes.notes);

      expect(box.get(note.id)?.title, 't');
    });
  });
}
