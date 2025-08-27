import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/data/thought_provider.dart';
import 'package:hold_that_thought/domain/usecases/update_thought.dart';
import 'package:hold_that_thought/models/thought.dart';

class ViewThoughtPage extends ConsumerStatefulWidget {
  final String id;
  const ViewThoughtPage({super.key, required this.id});

  @override
  ConsumerState<ViewThoughtPage> createState() => _ViewThoughtPageState();
}

class _ViewThoughtPageState extends ConsumerState<ViewThoughtPage> {
  final _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(thoughtRepositoryProvider);

    return FutureBuilder<Thought?>(
      future: repository.getById(widget.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            body: Center(child: Text('Thought not found.')),
          );
        }
        final thought = snapshot.data!;
        _textController.text = thought.content;

        return Scaffold(
          appBar: AppBar(
            title: const Text('View Thought'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _textController,
              maxLines: null,
              decoration: const InputDecoration(
                border: InputBorder.none,
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              final content = _textController.text;
              if (content.isNotEmpty) {
                final updatedThought = thought.copyWith(content: content);
                final updateThought = UpdateThought(repository);
                updateThought(updatedThought);
                Navigator.of(context).pop();
              }
            },
            child: const Icon(Icons.save),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
