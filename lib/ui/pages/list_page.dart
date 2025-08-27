import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hold_that_thought/data/thought_provider.dart';
import 'package:hold_that_thought/domain/usecases/list_thoughts.dart';
import 'package:hold_that_thought/domain/usecases/search_thoughts.dart';
import 'package:hold_that_thought/models/thought.dart';

class ListPage extends ConsumerStatefulWidget {
  const ListPage({super.key});

  @override
  ConsumerState<ListPage> createState() => _ListPageState();
}

class _ListPageState extends ConsumerState<ListPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(thoughtRepositoryProvider);
    final listThoughts = ListThoughts(repository);
    final searchThoughts = SearchThoughts(repository);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thoughts'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Search...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _searchQuery.isEmpty
                ? StreamBuilder<List<Thought>>(
                    stream: listThoughts(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      final thoughts = snapshot.data ?? [];
                      return ListView.builder(
                        itemCount: thoughts.length,
                        itemBuilder: (context, index) {
                          final thought = thoughts[index];
                          return ListTile(
                            title: Text(thought.content),
                            onTap: () {
                              context.go('/t/${thought.id}');
                            },
                          );
                        },
                      );
                    },
                  )
                : FutureBuilder<List<Thought>>(
                    future: searchThoughts(_searchQuery),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      final thoughts = snapshot.data ?? [];
                      return ListView.builder(
                        itemCount: thoughts.length,
                        itemBuilder: (context, index) {
                          final thought = thoughts[index];
                          return ListTile(
                            title: Text(thought.content),
                            onTap: () {
                              context.go('/t/${thought.id}');
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.go('/new');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
