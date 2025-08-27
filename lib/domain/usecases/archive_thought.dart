import '../../data/thought_repository.dart';

class ArchiveThought {
  final ThoughtRepository _repository;

  ArchiveThought(this._repository);

  Future<void> call(String id, {bool archived = true}) {
    return _repository.archive(id, archived: archived);
  }
}
