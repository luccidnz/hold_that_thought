import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/data/thought_provider.dart';
import 'package:hold_that_thought/domain/usecases/create_thought.dart';

class CreateNotePage extends ConsumerStatefulWidget {
  const CreateNotePage({super.key});

  @override
  ConsumerState<CreateNotePage> createState() => _CreateNotePageState();
}

class _CreateNotePageState extends ConsumerState<CreateNotePage> {
  final _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Note'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _textController,
          autofocus: true,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: 'What are you thinking?',
            border: InputBorder.none,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final content = _textController.text;
          if (content.isNotEmpty) {
            final repository = ref.read(thoughtRepositoryProvider);
            final createThought = CreateThought(repository);
            createThought(content);
            Navigator.of(context).pop();
          }
        },
        child: const Icon(Icons.save),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
