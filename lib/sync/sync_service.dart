import 'package:hold_that_thought/notes/note_model.dart';

abstract class SyncService {
  Future<SyncResult> pushChanges(List<NoteChange> ops);
  Future<RemoteSnapshot> pullChanges(DateTime since);
  ConflictStrategy get strategy; // preferNewest
}

enum ChangeType { create, update, delete }

class NoteChange {
  const NoteChange({
    required this.type,
    required this.note,
    required this.ts,
  });

  final ChangeType type;
  final Note note;
  final DateTime ts;
}

class SyncResult {
  const SyncResult({
    required this.ok,
    this.appliedIds = const [],
    this.conflicts = const [],
  });

  final bool ok;
  final List<String> appliedIds;
  final List<NoteConflict> conflicts;
}

class NoteConflict {
  const NoteConflict({
    required this.id,
    required this.local,
    required this.remote,
  });

  final String id;
  final Note local;
  final Note remote;
}

class RemoteSnapshot {
  const RemoteSnapshot({
    required this.notes,
    required this.serverTime,
  });

  final List<Note> notes;
  final DateTime serverTime;
}

enum ConflictStrategy { preferNewest }

enum SyncStatus { idle, syncing, ok, error }

class SyncError {
  const SyncError({required this.count});
  final int count;
}
