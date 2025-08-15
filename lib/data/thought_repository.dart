import 'package:hive/hive.dart';
import 'package:hold_that_thought/models/thought.dart';

abstract class ThoughtRepository {
  Future<Thought> create(String text);
  Stream<List<Thought>> watchAll({bool includeArchived = false});
  Future<void> update(Thought thought);
  Future<void> delete(String id);
  Future<void> togglePin(String id);
  Future<void> init();
}

class HiveThoughtRepository implements ThoughtRepository {
  static const String _boxName = 'thoughts';
  late Box<Thought> _box;

  @override
  Future<void> init() async {
    // This check is to prevent re-opening the box in a hot-reload scenario
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<Thought>(_boxName);
    } else {
      _box = Hive.box<Thought>(_boxName);
    }
  }

  @override
  Future<Thought> create(String text) async {
    final thought = Thought.create(text: text);
    await _box.put(thought.id, thought);
    return thought;
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> togglePin(String id) async {
    final thought = _box.get(id);
    if (thought != null) {
      thought.pinned = !thought.pinned;
      thought.updatedAt = DateTime.now();
      await thought.save();
    }
  }

  @override
  Future<void> update(Thought thought) async {
    thought.updatedAt = DateTime.now();
    await _box.put(thought.id, thought);
  }

  @override
  Stream<List<Thought>> watchAll({bool includeArchived = false}) {
    return _box.watch().map((event) {
      final thoughts = _box.values.where((t) {
        return includeArchived ? true : !t.archived;
      }).toList();

      // Sort the list: pinned thoughts first, then by creation date descending
      thoughts.sort((a, b) {
        if (a.pinned && !b.pinned) return -1;
        if (!a.pinned && b.pinned) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });

      return thoughts;
    });
  }
}
