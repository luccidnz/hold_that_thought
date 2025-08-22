import 'package:flutter/material.dart';
import 'package:hold_that_thought/notes/note_data.dart';

class CreateNotePage extends StatelessWidget {
  const CreateNotePage({super.key, this.prefilledData});

  final CreateNoteData? prefilledData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Note'),
      ),
      body: Center(
        child: Text(
          prefilledData == null
              ? 'Create Note Page'
              : 'Create Note Page (Prefilled: ${prefilledData!.title})',
        ),
      ),
    );
  }
}
