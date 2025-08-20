import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hold_that_thought/notes/note_model.dart';
import 'package:hold_that_thought/sync/fake_sync_service.dart';

part 'sync_service.g.dart';

abstract class SyncService {
  Future<SyncResult> pushChanges(List<NoteChange> ops);
  Future<RemoteSnapshot> pullChanges(DateTime since);
  ConflictStrategy get strategy; // preferNewest
}

@HiveType(typeId: 1)
enum ChangeType {
  @HiveField(0)
  create,
  @HiveField(1)
  update,
  @HiveField(2)
  delete,
}

@HiveType(typeId: 2)
class NoteChange {
  const NoteChange({
    required this.type,
    required this.note,
    required this.ts,
  });

  @HiveField(0)
  final ChangeType type;

  @HiveField(1)
  final Note note;

  @HiveField(2)
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

final syncServiceProvider = Provider<SyncService>((ref) {
  return FakeSyncService();
});
