import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/notes/note_model.dart';
import 'package:uuid/uuid.dart';

class NotesRepository {
  final List<Note> _notes = [
    Note(
      id: '123',
      title: 'Test Note 1',
      body: 'This is a test note.',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isPinned: false,
    ),
    Note(
      id: '456',
      title: 'Test Note 2',
      body: 'This is another test note.',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isPinned: true,
    ),
  ];

  bool exists(String id) {
    return _notes.any((note) => note.id == id);
  }

  Note create({
    required String title,
    required String body,
    required bool isPinned,
  }) {
    if (title == 'error') {
      throw Exception('Failed to create note');
    }
    final now = DateTime.now();
    final note = Note(
      id: const Uuid().v4(),
      title: title,
      body: body,
      createdAt: now,
      updatedAt: now,
      isPinned: isPinned,
    );
    _notes.add(note);
    return note;
  }

  void delete(String id) {
    _notes.removeWhere((note) => note.id == id);
  }
}

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository();
});
