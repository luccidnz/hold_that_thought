import 'package:flutter/material.dart';
import 'package:hold_that_thought/notes/note_data.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/notes/notes_repository.dart';

class CreateNotePage extends ConsumerStatefulWidget {
  const CreateNotePage({super.key, this.prefilledData});

  final CreateNoteData? prefilledData;

  @override
  ConsumerState<CreateNotePage> createState() => _CreateNotePageState();
}

class _CreateNotePageState extends ConsumerState<CreateNotePage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.prefilledData != null) {
      _titleController.text = widget.prefilledData!.title;
    }
    _titleController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Note'),
        actions: [
          TextButton(
            key: const Key('saveButton'),
            onPressed: _titleController.text.isNotEmpty
                ? () async {
                    final navigator = Navigator.of(context);
                    await ref.read(notesRepositoryProvider).create(
                          title: _titleController.text,
                          body: _bodyController.text,
                          isPinned: false,
                        );
                    navigator.pop();
                  }
                : null,
            child: const Text('Save'),
          )
        ],
      ),
      body: Column(
        children: [
          TextField(
            key: const Key('titleField'),
            controller: _titleController,
            decoration: const InputDecoration(hintText: 'Title'),
          ),
          TextField(
            key: const Key('bodyField'),
            controller: _bodyController,
            decoration: const InputDecoration(hintText: 'Body'),
          ),
        ],
      ),
    );
  }
}
