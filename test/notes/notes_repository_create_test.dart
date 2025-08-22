import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hold_that_thought/notes/note_model.dart';
import 'package:hold_that_thought/notes/notes_repository.dart';
import 'package:hold_that_thought/sync/fake_sync_service.dart';
import 'package:hold_that_thought/sync/sync_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'notes_repository_create_test.mocks.dart';

@GenerateMocks([Box])
void main() {
  group('NotesRepository', () {
    late MockBox<Note> mockNotesBox;
    late MockBox<NoteChange> mockPendingOpsBox;
    late ProviderContainer container;

    setUp(() {
      mockNotesBox = MockBox<Note>();
      mockPendingOpsBox = MockBox<NoteChange>();

      container = ProviderContainer(
        overrides: [
          syncServiceProvider.overrideWithValue(FakeSyncService()),
          notesRepositoryProvider.overrideWith(
            (ref) => NotesRepository(
              ref.watch(syncServiceProvider),
              mockNotesBox,
              mockPendingOpsBox,
            ),
          ),
        ],
      );
    });

    test('create returns a note with a unique id', () async {
      when(mockNotesBox.put(any, any)).thenAnswer((_) async => {});
      when(mockPendingOpsBox.add(any)).thenAnswer((_) async => 0);

      final repository = container.read(notesRepositoryProvider);
      final note1 =
          await repository.create(title: 't1', body: 'b1', isPinned: false);
      final note2 =
          await repository.create(title: 't2', body: 'b2', isPinned: false);
      expect(note1.id, isNot(equals(note2.id)));
    });

    test('create respects the isPinned flag', () async {
      when(mockNotesBox.put(any, any)).thenAnswer((_) async => {});
      when(mockPendingOpsBox.add(any)).thenAnswer((_) async => 0);

      final repository = container.read(notesRepositoryProvider);
      final pinnedNote =
          await repository.create(title: 't', body: 'b', isPinned: true);
      expect(pinnedNote.isPinned, isTrue);
      final unpinnedNote =
          await repository.create(title: 't', body: 'b', isPinned: false);
      expect(unpinnedNote.isPinned, isFalse);
    });
  });
}
