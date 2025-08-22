import 'package:hold_that_thought/notes/notes_repository.dart';

class StubNotesRepository implements NotesRepository {
  final bool _existsResult;

  StubNotesRepository({bool existsResult = true}) : _existsResult = existsResult;

  @override
  bool exists(String id) => _existsResult;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // This is a stub, so we don't need to implement other methods.
    // We can return a default value or throw an error if an unexpected
    // method is called.
    return super.noSuchMethod(invocation);
  }
}
