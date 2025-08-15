import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/models/thought.dart';
import 'package:hold_that_thought/providers/thought_providers.dart';
import 'package:hold_that_thought/widgets/add_thought_sheet.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thoughtsAsync = ref.watch(thoughtsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hold That Thought'),
      ),
      body: thoughtsAsync.when(
        data: (thoughts) {
          if (thoughts.isEmpty) {
            return const Center(
              child: Text(
                'No thoughts yet. Tap the + button to add one!',
                style: TextStyle(fontSize: 18, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.builder(
            itemCount: thoughts.length,
            itemBuilder: (context, index) {
              final thought = thoughts[index];
              return _ThoughtTile(thought: thought);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => const AddThoughtSheet(),
            isScrollControlled: true,
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ThoughtTile extends ConsumerWidget {
  const _ThoughtTile({required this.thought});

  final Thought thought;

  String _relativeTime(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);
    if (difference.inSeconds < 60) return '${difference.inSeconds}s ago';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return DateFormat.yMMMd().format(dt);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(thoughtRepositoryProvider);

    return Dismissible(
      key: ValueKey(thought.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        repo.delete(thought.id);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Thought deleted')));
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ListTile(
        title: Text(thought.text),
        subtitle: Text('Saved: ${_relativeTime(thought.createdAt)}'),
        trailing: IconButton(
          icon: Icon(
            thought.pinned ? Icons.push_pin : Icons.push_pin_outlined,
            color: thought.pinned ? Colors.blue : null,
          ),
          onPressed: () => repo.togglePin(thought.id),
        ),
        onTap: () {
          // Optional: Implement edit functionality here
        },
      ),
    );
  }
}
