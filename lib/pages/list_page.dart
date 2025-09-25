import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:hold_that_thought/state/encrypted_repo_providers.dart';
import 'package:hold_that_thought/state/encrypted_sync_providers.dart';
import 'package:hold_that_thought/state/repository_providers.dart';
import 'package:hold_that_thought/state/sync_providers.dart';
import 'package:hold_that_thought/widgets/daily_digest_card.dart';
import 'package:hold_that_thought/widgets/encryption_badge.dart';
import 'package:hold_that_thought/widgets/thought_detail_bottom_sheet.dart';
import 'package:share_plus/share_plus.dart';
import '../models/thought.dart';
import '../state/providers.dart';
import '../services/embedding_service.dart';
import '../services/open_file_helper.dart';
import '../utils/highlight.dart';
import '../utils/cosine.dart';

class ListPage extends ConsumerStatefulWidget {
  const ListPage({super.key});
  @override
  ConsumerState<ListPage> createState() => _ListPageState();
}

class _ListPageState extends ConsumerState<ListPage> {
  late TextEditingController _searchCtl;
  Timer? _deb;
  String? _semanticQuery;
  List<double>? _semanticEmbedding;

  bool _selectionMode = false;
  final Set<String> _selected = {};

  Future<void> _play(String path) async {
    await openWithSystemPlayer(path);
  }

  Future<void> _deleteThought(Thought t) async {
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Thought?'),
        content: const Text('This will permanently delete the recording. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    final repo = ref.read(thoughtRepositoryProvider);
    await repo.deleteLocal(t.id);
    if (ref.read(syncEnabledProvider)) {
      // Use encrypted sync service if it's encrypted
      if (t.isEncrypted) {
        await ref.read(encryptedSyncServiceProvider).deleteThoughtFromCloud(t);
      } else {
        await ref.read(syncServiceProvider).deleteThoughtFromCloud(t);
      }
    }
    ref.invalidate(thoughtsListProvider);
    ref.invalidate(encryptedThoughtsListProvider);
    ref.invalidate(syncStatsProvider);

    try { final f = File(t.path); if (await f.exists()) await f.delete(); } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thought deleted')));
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${_selected.length} selected?'),
        content: const Text('This will permanently delete the selected recordings.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    final repo = ref.read(thoughtRepositoryProvider);
    final syncService = ref.read(syncServiceProvider);
    final syncEnabled = ref.read(syncEnabledProvider);

    final allThoughts = (await repo.getAll()).where((t) => _selected.contains(t.id)).toList();

    for (final t in allThoughts) {
      await repo.deleteLocal(t.id);
      if (syncEnabled) {
        await syncService.deleteThoughtFromCloud(t);
      }
      try { final f = File(t.path); if (await f.exists()) await f.delete(); } catch (_) {}
    }

    _selected.clear();
    setState(() { _selectionMode = false; });
    ref.invalidate(thoughtsListProvider);
    ref.invalidate(syncStatsProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted selected')));
  }

  Future<void> _clearAll() async {
    final repo = ref.read(thoughtRepositoryProvider);
    final allThoughts = await repo.getAll();
    if (allThoughts.isEmpty) return;

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete ALL Thoughts?'),
        content: const Text('This will permanently delete every recording. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete All', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    final syncService = ref.read(syncServiceProvider);
    final syncEnabled = ref.read(syncEnabledProvider);

    for (final t in allThoughts) {
      await repo.deleteLocal(t.id);
       if (syncEnabled) {
        await syncService.deleteThoughtFromCloud(t);
      }
      try { final f = File(t.path); if (await f.exists()) await f.delete(); } catch (_) {}
    }

    ref.invalidate(thoughtsListProvider);
    ref.invalidate(syncStatsProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All thoughts deleted')));
  }

  @override
  void initState() {
    super.initState();
    _searchCtl = TextEditingController(text: ref.read(searchQueryProvider));
  }

  @override
  void dispose() {
    _deb?.cancel();
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _ensureSemanticEmbedding(String query) async {
    if (query.isEmpty) return;
    if (_semanticQuery == query && _semanticEmbedding != null) return;
    try {
      final svc = EmbeddingService();
      final emb = await svc.embed(query);
      setState(() { _semanticQuery = query; _semanticEmbedding = emb; });
    } catch (e) {
      // ignore: avoid_print
      print('Semantic embed failed: $e');
      setState(() { _semanticQuery = query; _semanticEmbedding = null; });
    }
  }

  Future<void> _copyTranscript(Thought t) async {
    final txt = (t.transcript ?? '').trim();
    await Clipboard.setData(ClipboardData(text: txt));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied transcript')));
  }

  Future<void> _copyPath(String path) async {
    await Clipboard.setData(ClipboardData(text: path));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied path')));
  }

  Future<void> _exportTranscript(Thought t) async {
    final dir = File(t.path).parent.path;
    final base = t.path.split(Platform.pathSeparator).last.replaceAll(RegExp(r'\.m4a\$', caseSensitive: false), '');
    final out = '$dir${Platform.pathSeparator}$base.txt';
    final content = (t.transcript ?? '').isEmpty ? '(no transcript)' : t.transcript!;
    try {
      await File(out).writeAsString(content);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved $base.txt')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _shareTranscript(Thought t) async {
    final transcript = t.transcript ?? '';
    if (transcript.isNotEmpty) {
      await Share.share(transcript);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No transcript to share')));
    }
  }

  Future<void> _shareAudio(Thought t) async {
    final file = XFile(t.path);
    await Share.shareXFiles([file]);
  }

  @override
  Widget build(BuildContext context) {
    final thoughtsAsync = ref.watch(encryptedThoughtsListProvider);
    final currentQuery = ref.watch(searchQueryProvider);
    final tagFilters = ref.watch(tagFilterProvider);
    if (_searchCtl.text != currentQuery) _searchCtl.text = currentQuery;

    return Scaffold(
      appBar: AppBar(
        title: _selectionMode ? Text('${_selected.length} selected') : const Text('Thoughts'),
        actions: [
          if (_selectionMode)
            IconButton(onPressed: _deleteSelected, icon: const Icon(Icons.delete)),
          if (!_selectionMode)
            IconButton(tooltip: 'Clear all', onPressed: _clearAll, icon: const Icon(Icons.delete_sweep)),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(88.0),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchCtl,
                decoration: InputDecoration(
                  hintText: 'Search…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(icon: const Icon(Icons.clear), onPressed: () { ref.read(searchQueryProvider.notifier).state = ''; _searchCtl.clear(); }),
                ),
                onChanged: (v) {
                  _deb?.cancel();
                  _deb = Timer(const Duration(milliseconds: 250), () {
                    ref.read(searchQueryProvider.notifier).state = v;
                    if (v.isNotEmpty) { unawaited(_ensureSemanticEmbedding(v)); }
                  });
                },
              ),
            ),
            SizedBox(
              height: 28,
              child: thoughtsAsync.when(
                data: (thoughts) {
                  final all = <String, int>{};
                  for (final t in thoughts) { for (final tg in t.tags ?? []) { all[tg] = (all[tg] ?? 0) + 1; } }
                  final top = all.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
                  final shown = top.take(20).map((e) => e.key).toList();
                  return ListView(scrollDirection: Axis.horizontal, children: shown.map((tag) {
                    final selected = tagFilters.contains(tag);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: FilterChip(
                        label: Text(tag),
                        selected: selected,
                        onSelected: (sel) {
                          final cur = List<String>.from(ref.read(tagFilterProvider));
                          if (sel) { if (!cur.contains(tag)) cur.add(tag); } else { cur.remove(tag); }
                          ref.read(tagFilterProvider.notifier).state = cur;
                        },
                      ),
                    );
                  }).toList());
                },
                loading: () => const SizedBox(),
                error: (e, s) => const SizedBox(),
              )
            ),
          ]),
        ),
      ),
      body: thoughtsAsync.when(
        data: (items) {
          final query = ref.watch(searchQueryProvider).trim();
          final sortMode = ref.watch(sortModeProvider);
          final tagFilters = ref.watch(tagFilterProvider);

          var filtered = items.where((t) {
            if (tagFilters.isEmpty) return true;
            final ts = (t.tags ?? []).map((e) => e.toLowerCase()).toSet();
            for (final f in tagFilters) {
              if (!ts.contains(f.toLowerCase())) return false;
            }
            return true;
          }).toList();

          if (query.isNotEmpty) {
            final mode = ref.watch(searchModeProvider);
            if (mode == SearchMode.keyword) {
              final lcQ = query.toLowerCase();
              filtered = filtered.where((t) {
                final fname = t.path.split(Platform.pathSeparator).last.toLowerCase();
                final inName = fname.contains(lcQ);
                final inTranscript = (t.transcript ?? '').toLowerCase().contains(lcQ);
                return inName || inTranscript;
              }).toList();
            } else {
              if (_semanticQuery != query || _semanticEmbedding == null) { unawaited(_ensureSemanticEmbedding(query)); }
              if (_semanticEmbedding != null) {
                final withScore = <MapEntry<Thought, double>>[];
                final noEmb = <Thought>[];
                for (final t in filtered) {
                  if (t.embedding != null) {
                    final score = cosine(_semanticEmbedding!, t.embedding!);
                    withScore.add(MapEntry(t, score));
                  } else {
                    noEmb.add(t);
                  }
                }
                withScore.sort((a,b) => b.value.compareTo(a.value));
                filtered = withScore.map((e) => e.key).followedBy(noEmb).toList();
              }
            }
          }

          // Sorting
          final mode = ref.watch(searchModeProvider);
          filtered.sort((a, b) {
            switch (sortMode) {
              case SortMode.newest:
                return b.createdAt.compareTo(a.createdAt);
              case SortMode.oldest:
                return a.createdAt.compareTo(b.createdAt);
              case SortMode.longest:
                final la = a.durationMs ?? 0;
                final lb = b.durationMs ?? 0;
                return lb.compareTo(la);
              case SortMode.bestMatch:
                if (mode == SearchMode.semantic && query.isNotEmpty && _semanticEmbedding != null) {
                  final sa = a.embedding == null ? double.negativeInfinity : cosine(_semanticEmbedding!, a.embedding!);
                  final sb = b.embedding == null ? double.negativeInfinity : cosine(_semanticEmbedding!, b.embedding!);
                  return sb.compareTo(sa);
                }
                if (query.isEmpty) return b.createdAt.compareTo(a.createdAt);
                final q = query.toLowerCase();
                final an = a.path.split(Platform.pathSeparator).last.toLowerCase().contains(q) ? 1 : 0;
                final bn = b.path.split(Platform.pathSeparator).last.toLowerCase().contains(q) ? 1 : 0;
                return bn.compareTo(an);
            }
          });

          if (filtered.isEmpty) {
            if (query.isEmpty) return const Center(child: Text('No thoughts yet'));
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text("No matches for '$query'"), const SizedBox(height: 8), ElevatedButton(onPressed: () { ref.read(searchQueryProvider.notifier).state = ''; _searchCtl.clear(); }, child: const Text('Clear'))]));
          }

          return ListView.separated(
            itemCount: filtered.length + 1, // +1 for the daily digest card
            separatorBuilder: (_, index) {
              // No separator after the digest card
              if (index == 0) return const SizedBox.shrink();
              return const Divider(height: 1);
            },
            itemBuilder: (context, i) {
              // Show the daily digest card at the top
              if (i == 0) {
                return DailyDigestCard(
                  date: DateTime.now(),
                  onRefresh: () {
                    // Refresh the list
                    ref.invalidate(thoughtsListProvider);
                  },
                );
              }
              
              // Adjust index for the actual thoughts
              final t = filtered[i - 1];
              final fileName = t.path.split(Platform.pathSeparator).last;
              final when = '${t.createdAt.toLocal()}'.split('.').first;
              final dur = t.durationMs != null ? ' • ${(t.durationMs! / 1000).toStringAsFixed(1)}s' : '';
              final inSelection = _selected.contains(t.id);
              final syncEnabled = ref.watch(syncEnabledProvider);

              Widget leadingIcon;
              if (_selectionMode) {
                leadingIcon = Checkbox(
                    value: inSelection,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selected.add(t.id);
                        } else {
                          _selected.remove(t.id);
                        }
                      });
                    });
              } else if (syncEnabled) {
                leadingIcon = t.remoteId != null
                    ? const Icon(Icons.cloud_done, color: Colors.green)
                    : const Icon(Icons.cloud_upload);
              } else {
                leadingIcon = const Icon(Icons.mic);
              }

              return ListTile(
                leading: leadingIcon,
                title: Row(
                  children: [
                    Expanded(
                        child: GestureDetector(
                            onLongPress: () {
                              setState(() {
                                _selectionMode = true;
                                _selected.add(t.id);
                              });
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                    text: highlightSpan(context, t.title?.isNotEmpty == true ? t.title! : fileName, ref.watch(searchQueryProvider)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                if (t.isEncrypted)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: EncryptionBadge(thought: t),
                                  ),
                              ],
                            ))),
                    IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () async {
                          final ctl = TextEditingController(text: t.title ?? fileName);
                          final res = await showDialog<String?>(
                              context: context,
                              builder: (ctx) => AlertDialog(title: const Text('Edit title'), content: TextField(controller: ctl, autofocus: true), actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
                                    TextButton(onPressed: () => Navigator.pop(ctx, ctl.text.trim()), child: const Text('Save'))
                                  ]));
                          if (res != null) {
                            final updated = t.copyWith(title: res.isEmpty ? null : res);
                            
                            // Use the encrypted repository for updating thoughts
                            if (t.isEncrypted) {
                              await ref.read(encryptedThoughtRepositoryProvider).upsertLocal(updated);
                            } else {
                              await ref.read(thoughtRepositoryProvider).upsertLocal(updated);
                            }
                            
                            ref.invalidate(thoughtsListProvider);
                            ref.invalidate(encryptedThoughtsListProvider);
                          }
                        })
                  ],
                ),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text('$when$dur', style: Theme.of(context).textTheme.bodySmall),
                  if (t.transcript != null && t.transcript!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                        onTap: () async {
                          final ctl = TextEditingController(text: t.transcript);
                          final res = await showDialog<String?>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                  title: const Text('Edit transcript'),
                                  content: SizedBox(height: 300, child: TextField(controller: ctl, maxLines: null, expands: true)),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
                                    TextButton(onPressed: () => Navigator.pop(ctx, ctl.text), child: const Text('Save'))
                                  ]));
                          if (res != null) {
                            final updated = t.copyWith(transcript: res, embedding: null);
                            
                            // Use the encrypted repository for updating thoughts
                            if (t.isEncrypted) {
                              await ref.read(encryptedThoughtRepositoryProvider).upsertLocal(updated);
                            } else {
                              await ref.read(thoughtRepositoryProvider).upsertLocal(updated);
                            }
                            
                            ref.invalidate(thoughtsListProvider);
                            ref.invalidate(encryptedThoughtsListProvider);
                          }
                        },
                        child: RichText(
                            text: highlightSpan(context, t.transcript!.replaceAll('\n', ' '), ref.watch(searchQueryProvider)),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis)),
                  ],
                  if (t.tags != null && t.tags!.isNotEmpty) ...[const SizedBox(height: 6), Wrap(spacing: 6, children: t.tags!.map((tg) => Chip(label: Text(tg))).toList())]
                ]),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.play_arrow), onPressed: () => _play(t.path)),
                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteThought(t)),
                  PopupMenuButton<String>(
                      onSelected: (choice) async {
                        if (choice == 'copy_transcript') {
                          await _copyTranscript(t);
                        } else if (choice == 'copy_path') {
                          await _copyPath(t.path);
                        } else if (choice == 'open_location') {
                          await openLocation(t.path);
                        } else if (choice == 'export') {
                          await _exportTranscript(t);
                        } else if (choice == 'open') {
                          await openWithSystemPlayer(t.path);
                        } else if (choice == 'share_transcript') {
                          await _shareTranscript(t);
                        } else if (choice == 'share_audio') {
                          await _shareAudio(t);
                        }
                      },
                      itemBuilder: (context) => [
                            const PopupMenuItem(value: 'share_transcript', child: Text('Share transcript')),
                            const PopupMenuItem(value: 'share_audio', child: Text('Share audio file')),
                             const PopupMenuDivider(),
                            const PopupMenuItem(value: 'copy_transcript', child: Text('Copy transcript')),
                            const PopupMenuItem(value: 'copy_path', child: Text('Copy file path')),
                            const PopupMenuItem(value: 'open_location', child: Text('Open location')),
                            const PopupMenuItem(value: 'open', child: Text('Open with system player')),
                            const PopupMenuItem(value: 'export', child: Text('Export transcript (.txt)')),
                          ]),
                ]),
                onTap: () {
                  if (_selectionMode) {
                    setState(() {
                      if (inSelection) {
                        _selected.remove(t.id);
                      } else {
                        _selected.add(t.id);
                      }
                    });
                    return;
                  }
                  
                  // Set the selected thought ID
                  ref.read(selectedThoughtIdProvider.notifier).state = t.id;
                  
                  // Show the thought detail bottom sheet
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => ThoughtDetailBottomSheet(thought: t),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
