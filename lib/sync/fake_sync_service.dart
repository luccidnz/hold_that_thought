import 'dart:math';
import 'package:hold_that_thought/notes/note_model.dart';
import 'package:hold_that_thought/sync/sync_service.dart';

class FakeSyncService implements SyncService {
  Duration latency = const Duration(milliseconds: 300);
  double failureRate = 0.0;

  final Map<String, Note> _remoteStore = {};
  DateTime _lastSync = DateTime.now();

  @override
  ConflictStrategy get strategy => ConflictStrategy.preferNewest;

  @override
  Future<RemoteSnapshot> pullChanges(DateTime since) async {
    await Future.delayed(latency);
    if (Random().nextDouble() < failureRate) {
      throw Exception('Failed to pull changes');
    }
    final changes = _remoteStore.values
        .where((note) => note.updatedAt.isAfter(since))
        .toList();
    _lastSync = DateTime.now();
    return RemoteSnapshot(notes: changes, serverTime: _lastSync);
  }

  @override
  Future<SyncResult> pushChanges(List<NoteChange> ops) async {
    await Future.delayed(latency);
    if (Random().nextDouble() < failureRate) {
      throw Exception('Failed to push changes');
    }

    final appliedIds = <String>[];
    final conflicts = <NoteConflict>[];

    for (final op in ops) {
      final remoteNote = _remoteStore[op.note.id];
      if (remoteNote != null &&
          remoteNote.updatedAt.isAfter(op.note.updatedAt)) {
        conflicts.add(NoteConflict(
          id: op.note.id,
          local: op.note,
          remote: remoteNote,
        ));
      } else {
        _remoteStore[op.note.id] = op.note;
        appliedIds.add(op.note.id);
      }
    }

    return SyncResult(ok: true, appliedIds: appliedIds, conflicts: conflicts);
  }

  void clearRemoteStore() {
    _remoteStore.clear();
  }
}
