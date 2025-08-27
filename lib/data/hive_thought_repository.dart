import 'dart:async';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/thought.dart';
import 'thought_repository.dart';

class HiveThoughtRepository implements ThoughtRepository {
  static const _boxName = 'thoughts';
  Box<Thought>? _box;

  @override
  Future<void> init() async {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ThoughtAdapter());
    }
    _box ??= await Hive.openBox<Thought>(_boxName);
  }

  @override
  Future<Thought> create(String content, {List<String> tags = const []}) async {
    final now = DateTime.now();
    final t = Thought(
      id: const Uuid().v4(),
      content: content,
      createdAt: now,
      updatedAt: now,
      tags: tags,
    );
    await _box!.put(t.id, t);
    return t;
  }

  @override
  Future<Thought?> getById(String id) async => _box!.get(id);

  @override
  Stream<List<Thought>> watchAll({bool includeArchived = false}) async* {
    yield _snapshot(includeArchived);
    yield* _box!.watch().map((_) => _snapshot(includeArchived));
  }

  List<Thought> _snapshot(bool includeArchived) {
    final all = _box!.values.toList();
    final filtered = includeArchived ? all : all.where((t) => !t.archived);
    final sorted = filtered.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted;
  }

  @override
  Future<List<Thought>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _snapshot(false);
    return _box!.values
        .where((t) => !t.archived && t.content.toLowerCase().contains(q))
        .toList();
  }

  @override
  Future<Thought> update(Thought t) async {
    final updated = t.copyWith(updatedAt: DateTime.now());
    await _box!.put(updated.id, updated);
    return updated;
  }

  @override
  Future<void> archive(String id, {bool archived = true}) async {
    final t = await getById(id);
    if (t == null) return;
    await _box!.put(id, t.copyWith(archived: archived, updatedAt: DateTime.now()));
  }

  @override
  Future<void> delete(String id) => _box!.delete(id);
}
