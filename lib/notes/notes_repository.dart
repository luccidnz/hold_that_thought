import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotesRepository {
  final List<String> _notes = ['123', '456'];

  bool exists(String id) {
    return _notes.contains(id);
  }
}

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository();
});
