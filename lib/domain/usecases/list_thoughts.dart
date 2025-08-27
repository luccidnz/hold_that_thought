import '../../data/thought_repository.dart';
import '../../models/thought.dart';

class ListThoughts {
  final ThoughtRepository _repository;

  ListThoughts(this._repository);

  Stream<List<Thought>> call({bool includeArchived = false}) {
    return _repository.watchAll(includeArchived: includeArchived);
  }
}
