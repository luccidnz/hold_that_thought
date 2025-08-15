import 'package:hive_flutter/hive_flutter.dart';
import '../models/thought.dart';

class ThoughtRepo {
  static const boxName = 'thoughts';
  late Box<Thought> _box;

  /// Must be called before using the repo (you already call this in main.dart).
  Future<void> init() async {
    _box = await Hive.openBox<Thought>(boxName);
  }

  /// Emits an initial snapshot immediately, then updates on any box change.
  Stream<List<Thought>> watchAll({bool includeArchived = false}) async* {
    yield _snapshot(includeArchived: includeArchived);
    yield* _box.watch().map((_) => _snapshot(includeArchived: includeArchived));
  }

  List<Thought> _snapshot({required bool includeArchived}) {
    final items = _box.values
        .where((t) => includeArchived || !t.archived)
        .toList()
      ..sort((a, b) {
        final pa = a.pinned ? 1 : 0;
        final pb = b.pinned ? 1 : 0;
        if (pa != pb) return pb.compareTo(pa); // pinned first
        return b.createdAt.compareTo(a.createdAt); // newest first
      });
    return items;
  }

  Future<Thought> create(String text) async {
    final t = Thought(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text.trim(),
      createdAt: DateTime.now(),
    );
    await _box.put(t.id, t);
    return t;
  }

  Future<void> delete(String id) => _box.delete(id);

  /// Used by the Undo snackbar to restore a deleted item.
  Future<void> upsert(Thought t) async {
    await _box.put(t.id, t);
  }

  Future<void> togglePin(String id) async {
    final t = _box.get(id);
    if (t == null) return;
    await _box.put(id, t.copyWith(
      pinned: !t.pinned,
      updatedAt: DateTime.now(),
    ));
  }
}