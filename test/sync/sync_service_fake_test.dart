import 'package:flutter_test/flutter_test.dart';
import 'package:hold_that_thought/notes/note_model.dart';
import 'package:hold_that_thought/sync/fake_sync_service.dart';
import 'package:hold_that_thought/sync/sync_service.dart';

void main() {
  group('FakeSyncService', () {
    test('pushChanges adds new notes to the remote store', () async {
      final service = FakeSyncService();
      final note = Note(
        id: '1',
        title: 't',
        body: 'b',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPinned: false,
      );
      final change =
          NoteChange(type: ChangeType.create, note: note, ts: DateTime.now());
      final result = await service.pushChanges([change]);
      expect(result.ok, isTrue);
      expect(result.appliedIds, ['1']);
      final snapshot =
          await service.pullChanges(DateTime.fromMicrosecondsSinceEpoch(0));
      expect(snapshot.notes.length, 1);
      expect(snapshot.notes.first.id, '1');
    });

    test('pullChanges returns notes modified since the last sync', () async {
      final service = FakeSyncService();
      final note1 = Note(
        id: '1',
        title: 't1',
        body: 'b1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPinned: false,
      );
      await service.pushChanges([
        NoteChange(type: ChangeType.create, note: note1, ts: DateTime.now())
      ]);
      final lastSync = DateTime.now();
      await Future.delayed(const Duration(milliseconds: 10));
      final note2 = Note(
        id: '2',
        title: 't2',
        body: 'b2',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPinned: false,
      );
      await service.pushChanges([
        NoteChange(type: ChangeType.create, note: note2, ts: DateTime.now())
      ]);
      final snapshot = await service.pullChanges(lastSync);
      expect(snapshot.notes.length, 1);
      expect(snapshot.notes.first.id, '2');
    });

    test('conflict resolution prefers newest note', () async {
      final service = FakeSyncService();
      final now = DateTime.now();
      final oldNote = Note(
        id: '1',
        title: 'old',
        body: 'old',
        createdAt: now,
        updatedAt: now,
        isPinned: false,
      );
      await service.pushChanges(
          [NoteChange(type: ChangeType.create, note: oldNote, ts: now)]);

      final newNote = oldNote.copyWith(
          title: 'new', updatedAt: now.add(const Duration(seconds: 1)));
      final result = await service.pushChanges([
        NoteChange(
            type: ChangeType.update, note: newNote, ts: newNote.updatedAt)
      ]);
      expect(result.ok, isTrue);
      expect(result.appliedIds, ['1']);

      final snapshot =
          await service.pullChanges(DateTime.fromMicrosecondsSinceEpoch(0));
      expect(snapshot.notes.first.title, 'new');
    });

    test('simulated failure throws an exception', () async {
      final service = FakeSyncService();
      service.failureRate = 1.0;
      final note = Note(
        id: '1',
        title: 't',
        body: 'b',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPinned: false,
      );
      final change =
          NoteChange(type: ChangeType.create, note: note, ts: DateTime.now());
      expect(service.pushChanges([change]), throwsException);
    });
  });
}
