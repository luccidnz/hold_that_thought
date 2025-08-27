import '../../data/thought_repository.dart';
import '../../models/thought.dart';

class UpdateThought {
  final ThoughtRepository _repository;

  UpdateThought(this._repository);

  Future<Thought> call(Thought thought) {
    return _repository.update(thought);
  }
}
