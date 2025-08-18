import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/notes/note_model.dart';
import 'package:hold_that_thought/sync/sync_service.dart';
import 'package:uuid/uuid.dart';

class NotesRepository {
  NotesRepository(this._syncService);

  final SyncService _syncService;
  final List<Note> _notes = [
    Note(
      id: '123',
      title: 'Test Note 1',
      body: 'This is a test note about Flutter.',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isPinned: false,
      tags: ['work', 'flutter'],
    ),
    Note(
      id: '456',
      title: 'Test Note 2',
      body: 'This is another test note about personal stuff.',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isPinned: true,
      tags: ['personal'],
    ),
    Note(
      id: '789',
      title: 'Test Note 3',
      body: 'This is a pinned test note about work.',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isPinned: true,
      tags: ['work'],
    ),
  ];
  final List<NoteChange> _pendingOps = [];
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  DateTime _lastSynced = DateTime.fromMicrosecondsSinceEpoch(0);

  Stream<SyncStatus> get syncStatus => _syncStatusController.stream;

  List<Note> getFilteredNotes({
    String? query,
    Set<String> tags = const {},
  }) {
    var notes = _notes;

    if (query != null && query.isNotEmpty) {
      notes = notes
          .where((note) =>
              note.title.toLowerCase().contains(query.toLowerCase()) ||
              (note.body?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();
    }

    if (tags.isNotEmpty) {
      notes = notes
          .where((note) => tags.every((tag) => note.tags.contains(tag)))
          .toList();
    }

    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }

  List<Note> getPinnedNotes() {
    return _notes.where((note) => note.isPinned).toList();
  }

  List<Note> getUnpinnedNotes({
    String? query,
    Set<String> tags = const {},
  }) {
    final unpinned = _notes.where((note) => !note.isPinned).toList();
    var notes = unpinned;

    if (query != null && query.isNotEmpty) {
      notes = notes
          .where((note) =>
              note.title.toLowerCase().contains(query.toLowerCase()) ||
              (note.body?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();
    }

    if (tags.isNotEmpty) {
      notes = notes
          .where((note) => tags.every((tag) => note.tags.contains(tag)))
          .toList();
    }

    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }

  Set<String> getDistinctTags() {
    return _notes.expand((note) => note.tags).toSet();
  }

  bool exists(String id) {
    return _notes.any((note) => note.id == id);
  }

  Note create({
    required String title,
    String? body,
    required bool isPinned,
    List<String> tags = const [],
  }) {
    if (title == 'error') {
      throw Exception('Failed to create note');
    }
    final now = DateTime.now();
    final note = Note(
      id: const Uuid().v4(),
      title: title,
      body: body,
      createdAt: now,
      updatedAt: now,
      isPinned: isPinned,
      tags: tags,
    );
    _notes.add(note);
    _pendingOps.add(NoteChange(type: ChangeType.create, note: note, ts: now));
    return note;
  }

  void delete(String id) {
    final note = _notes.firstWhere((note) => note.id == id);
    _pendingOps.add(NoteChange(type: ChangeType.delete, note: note, ts: DateTime.now()));
    _notes.removeWhere((note) => note.id == id);
  }

  Note update(Note note) {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      final updatedNote = note.copyWith(updatedAt: DateTime.now());
      _notes[index] = updatedNote;
      _pendingOps.add(NoteChange(type: ChangeType.update, note: updatedNote, ts: updatedNote.updatedAt));
      return updatedNote;
    }
    throw Exception('Note not found');
  }

  Future<void> syncOnce() async {
    _syncStatusController.add(SyncStatus.syncing);
    try {
      final pushResult = await _syncService.pushChanges(_pendingOps);
      if (pushResult.ok) {
        _pendingOps.removeWhere((op) => pushResult.appliedIds.contains(op.note.id));
      }

      final pullResult = await _syncService.pullChanges(_lastSynced);
      for (final remoteNote in pullResult.notes) {
        final localNoteIndex = _notes.indexWhere((note) => note.id == remoteNote.id);
        if (localNoteIndex != -1) {
          final localNote = _notes[localNoteIndex];
          if (remoteNote.updatedAt.isAfter(localNote.updatedAt)) {
            _notes[localNoteIndex] = remoteNote;
          }
        } else {
          _notes.add(remoteNote);
        }
      }
      _lastSynced = pullResult.serverTime;
      _syncStatusController.add(SyncStatus.ok);
    } catch (e) {
      _syncStatusController.add(SyncStatus.error);
    }
  }
}

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return NotesRepository(syncService);
});
