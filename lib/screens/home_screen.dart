import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/thought_providers.dart';
import '../models/thought.dart';
import '../repos/thought_repo.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thoughtsAsync = ref.watch(thoughtsProvider); // simple stream
    final repo = ref.read(thoughtRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Hold That Thought')),
      body: thoughtsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('Nothing yet — hit + to add a thought'),
            );
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final t = items[i];
              return Dismissible(
                key: ValueKey(t.id),
                direction: DismissDirection.horizontal,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                secondaryBackground: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => _deleteWithUndo(context, repo, t),
                child: ListTile(
                  title: Text(t.text),
                  subtitle: Text(_fmtTime(t.createdAt)),
                  leading: IconButton(
                    icon: Icon(t.pinned ? Icons.push_pin : Icons.push_pin_outlined),
                    onPressed: () => repo.togglePin(t.id),
                    tooltip: t.pinned ? 'Unpin' : 'Pin',
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit',
                        onPressed: () => _editThought(context, repo, t),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete',
                        onPressed: () => _deleteWithUndo(context, repo, t),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),

      // 🔥 Bring back the big + button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addThought(context, repo),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  static String _fmtTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
           '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// Delete with UNDO
void _deleteWithUndo(BuildContext context, ThoughtRepo repo, Thought t) async {
  await repo.delete(t.id);
  final sb = SnackBar(
    content: const Text('Thought deleted'),
    action: SnackBarAction(
      label: 'UNDO',
      onPressed: () => repo.upsert(t),
    ),
    duration: const Duration(seconds: 4),
  );
  // ignore: use_build_context_synchronously
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(sb);
}

// Bottom-sheet: Add
void _addThought(BuildContext context, ThoughtRepo repo) {
  final ctrl = TextEditingController();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('New thought', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              maxLength: 1000,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Type your thought…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () async {
                final text = ctrl.text.trim();
                if (text.isEmpty) return;
                await repo.create(text);
                // ignore: use_build_context_synchronously
                Navigator.of(ctx).pop();
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thought saved')),
                );
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save'),
            ),
          ],
        ),
      );
    },
  );
}

// Bottom-sheet: Edit
void _editThought(BuildContext context, ThoughtRepo repo, Thought t) {
  final ctrl = TextEditingController(text: t.text);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Edit thought', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              maxLength: 1000,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Edit thought',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () async {
                final newText = ctrl.text.trim();
                if (newText.isEmpty) return;
                await repo.upsert(t.copyWith(
                  text: newText,
                  updatedAt: DateTime.now(),
                ));
                // ignore: use_build_context_synchronously
                Navigator.of(ctx).pop();
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thought updated')),
                );
              },
              icon: const Icon(Icons.check),
              label: const Text('Save changes'),
            ),
          ],
        ),
      );
    },
  );
}