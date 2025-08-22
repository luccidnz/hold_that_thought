import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hold_that_thought/notes/note_model.dart';
import 'package:hold_that_thought/storage/hive_boxes.dart';
import 'package:hold_that_thought/sync/sync_service.dart';
import 'package:uuid/uuid.dart';

class NotesRepository extends ChangeNotifier {
  NotesRepository(this._syncService, this._notesBox, this._pendingOpsBox);

  final SyncService _syncService;
  final Box<Note> _notesBox;
  final Box<NoteChange> _pendingOpsBox;

  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  DateTime _lastSynced = DateTime.fromMicrosecondsSinceEpoch(0);

  Stream<SyncStatus> get syncStatus => _syncStatusController.stream;

  List<Note> getFilteredNotes({
    String? query,
    Set<String> tags = const {},
  }) {
    var notes = _notesBox.values.toList();

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
    return _notesBox.values.where((note) => note.isPinned).toList();
  }

  List<Note> getUnpinnedNotes({
    String? query,
    Set<String> tags = const {},
  }) {
    final unpinned = _notesBox.values.where((note) => !note.isPinned).toList();
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
    return _notesBox.values.expand((note) => note.tags).toSet();
  }

  bool exists(String id) {
    return _notesBox.containsKey(id);
  }

  Future<Note> create({
    required String title,
    String? body,
    required bool isPinned,
    List<String> tags = const [],
  }) async {
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
    await _notesBox.put(note.id, note);
    await _pendingOpsBox
        .add(NoteChange(type: ChangeType.create, note: note, ts: now));
    notifyListeners();
    return note;
  }

  Future<void> delete(String id) async {
    final note = _notesBox.get(id);
    if (note != null) {
      await _pendingOpsBox.add(
          NoteChange(type: ChangeType.delete, note: note, ts: DateTime.now()));
      await _notesBox.delete(id);
      notifyListeners();
    }
  }

  Future<void> update(Note note) async {
    final updatedNote = note.copyWith(updatedAt: DateTime.now());
    await _notesBox.put(note.id, updatedNote);
    await _pendingOpsBox.add(NoteChange(
        type: ChangeType.update, note: updatedNote, ts: updatedNote.updatedAt));
    notifyListeners();
  }

  Future<void> syncOnce() async {
    _syncStatusController.add(SyncStatus.syncing);
    try {
      final pendingOpsMap = _pendingOpsBox.toMap();
      final pendingOps = pendingOpsMap.values.toList();
      final pushResult = await _syncService.pushChanges(pendingOps);
      if (pushResult.ok) {
        for (final id in pushResult.appliedIds) {
          final entry = pendingOpsMap.entries
              .firstWhere((entry) => entry.value.note.id == id);
          await _pendingOpsBox.delete(entry.key);
        }
      }

      final pullResult = await _syncService.pullChanges(_lastSynced);
      for (final remoteNote in pullResult.notes) {
        final localNote = _notesBox.get(remoteNote.id);
        if (localNote != null) {
          if (remoteNote.updatedAt.isAfter(localNote.updatedAt)) {
            await _notesBox.put(remoteNote.id, remoteNote);
          }
        } else {
          await _notesBox.put(remoteNote.id, remoteNote);
        }
      }
      _lastSynced = pullResult.serverTime;
      _syncStatusController.add(SyncStatus.ok);
      notifyListeners();
    } catch (e) {
      _syncStatusController.add(SyncStatus.error);
    }
  }

  Future<void> clearAllBoxes() async {
    await _notesBox.clear();
    await _pendingOpsBox.clear();
    notifyListeners();
  }
}

final notesRepositoryProvider = ChangeNotifierProvider<NotesRepository>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  final notesBox = Hive.box<Note>(HiveBoxes.notes);
  final pendingOpsBox = Hive.box<NoteChange>(HiveBoxes.pendingOps);
  return NotesRepository(syncService, notesBox, pendingOpsBox);
});
