import 'package:flutter/material.dart';
import 'package:hold_that_thought/notes/note_model.dart';

class NoteList extends StatelessWidget {
  const NoteList({super.key, required this.notes});

  final List<Note> notes;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return ListTile(
          title: Text(note.title),
          subtitle: note.body != null ? Text(note.body!) : null,
        );
      },
    );
  }
}
