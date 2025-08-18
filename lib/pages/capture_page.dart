import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hold_that_thought/notes/notes_repository.dart';
import 'package:hold_that_thought/quick_capture/quick_capture_sheet.dart';
import 'package:hold_that_thought/routing/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CapturePage extends ConsumerStatefulWidget {
  const CapturePage({Key? key}) : super(key: key);

  @override
  ConsumerState<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends ConsumerState<CapturePage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  Set<String> _selectedTags = {};
  String _searchQuery = '';

  static const _searchQueryKey = 'searchQuery';
  static const _selectedTagsKey = 'selectedTags';

  @override
  void initState() {
    super.initState();
    _loadFilters();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadFilters() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchQuery = prefs.getString(_searchQueryKey) ?? '';
      _searchController.text = _searchQuery;
      _selectedTags = (prefs.getStringList(_selectedTagsKey) ?? []).toSet();
    });
  }

  Future<void> _saveFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_searchQueryKey, _searchQuery);
    await prefs.setStringList(_selectedTagsKey, _selectedTags.toList());
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = _searchController.text;
        _saveFilters();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final notesRepository = ref.watch(notesRepositoryProvider);
    final distinctTags = notesRepository.getDistinctTags();
    final pinnedNotes = notesRepository.getPinnedNotes();
    final unpinnedNotes = notesRepository.getUnpinnedNotes(
      query: _searchQuery,
      tags: _selectedTags,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hold That Thought'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () => context.go(AppRoutes.list()),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go(AppRoutes.settings()),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: distinctTags.map((tag) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: FilterChip(
                    label: Text(tag),
                    tooltip: 'Filter by $tag',
                    selected: _selectedTags.contains(tag),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                        _saveFilters();
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                if (pinnedNotes.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Pinned',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ),
                if (pinnedNotes.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final note = pinnedNotes[index];
                        return ListTile(
                          title: Text(note.title),
                          subtitle: note.body != null ? Text(note.body!) : null,
                        );
                      },
                      childCount: pinnedNotes.length,
                    ),
                  ),
                if (unpinnedNotes.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'All Notes',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final note = unpinnedNotes[index];
                      return ListTile(
                        title: Text(note.title),
                        subtitle: note.body != null ? Text(note.body!) : null,
                      );
                    },
                    childCount: unpinnedNotes.length,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => const QuickCaptureSheet(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
