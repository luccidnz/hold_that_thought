import '../../data/thought_repository.dart';
import '../../models/thought.dart';

class CreateThought {
  final ThoughtRepository _repository;

  CreateThought(this._repository);

  Future<Thought> call(String content, {List<String> tags = const []}) {
    return _repository.create(content, tags: tags);
  }
}
