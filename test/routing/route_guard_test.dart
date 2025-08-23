import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart' as m;
import 'package:mockito/annotations.dart';
import 'package:hold_that_thought/notes/notes_repository.dart';
import 'package:hold_that_thought/routing/app_router.dart';

import 'route_guard_test.mocks.dart';

@GenerateMocks([NotesRepository])
void main() {
  group('NoteIdGuard', () {
    late MockNotesRepository mockRepo;
    late NoteIdGuard guard;

    setUp(() {
      mockRepo = MockNotesRepository();
      guard = NoteIdGuard(mockRepo);
    });

    test('allows navigation when id exists', () async {
      m.when(mockRepo.exists('123')).thenReturn(true);

      final result = await guard.canActivate('123');

      expect(result, isTrue);
      m.verify(mockRepo.exists('123')).called(1);
    });

    test('blocks navigation when id does not exist', () async {
      m.when(mockRepo.exists('123')).thenReturn(false);

      final result = await guard.canActivate('123');

      expect(result, isFalse);
      m.verify(mockRepo.exists('123')).called(1);
    });
  });
}
