import 'package:flutter_test/flutter_test.dart';
import 'package:hold_that_thought/notes/notes_repository.dart';

void main() {
  group('NotesRepository', () {
    test('create returns a note with a unique id', () {
      final repository = NotesRepository();
      final note1 = repository.create(title: 't1', body: 'b1', isPinned: false);
      final note2 = repository.create(title: 't2', body: 'b2', isPinned: false);
      expect(note1.id, isNot(equals(note2.id)));
    });

    test('create respects the isPinned flag', () {
      final repository = NotesRepository();
      final pinnedNote = repository.create(title: 't', body: 'b', isPinned: true);
      expect(pinnedNote.isPinned, isTrue);
      final unpinnedNote = repository.create(title: 't', body: 'b', isPinned: false);
      expect(unpinnedNote.isPinned, isFalse);
    });
  });
}
