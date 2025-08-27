import '../../data/thought_repository.dart';
import '../../models/thought.dart';

class SearchThoughts {
  final ThoughtRepository _repository;

  SearchThoughts(this._repository);

  Future<List<Thought>> call(String query) {
    return _repository.search(query);
  }
}
