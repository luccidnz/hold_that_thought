import '../models/thought.dart';

abstract class ThoughtRepository {
  Future<void> init();
  Future<Thought> create(String content, {List<String> tags});
  Future<Thought?> getById(String id);
  Stream<List<Thought>> watchAll({bool includeArchived = false});
  Future<List<Thought>> search(String query);
  Future<Thought> update(Thought t);
  Future<void> archive(String id, {bool archived = true});
  Future<void> delete(String id);
}
