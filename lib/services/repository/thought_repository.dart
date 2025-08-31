import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import '../../models/thought.dart';

class ThoughtRepository {
  static const boxName = 'thoughts';

  Future<Box<Thought>> _open() => Hive.openBox<Thought>(boxName);

  /// Returns all thoughts, newest first (local source of truth).
  Future<List<Thought>> getAll() async {
    final box = await _open();
    final items = box.values.toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<Thought?> getThought(String id) async {
    final box = await _open();
    return box.get(id);
  }

  /// Pending = not uploaded or previously failed (no remoteId).
  Future<List<Thought>> getPendingSync() async {
    final box = await _open();
    return box.values.where((t) => t.remoteId == null).toList();
  }

  /// Compute & cache sha256 for the audio file if missing.
  Future<String?> ensureSha256(Thought t) async {
    if (t.sha256 != null && t.sha256!.isNotEmpty) return t.sha256;
    final file = File(t.path);
    if (!await file.exists()) return null;
    final digest = sha256.convert(await file.readAsBytes()).toString();
    final box = await _open();
    // This part is tricky because the Thought object from the box is not the same instance
    // as the one passed in. We should update the one from the box.
    final thoughtInBox = box.get(t.id);
    if (thoughtInBox != null) {
      final updatedThought = thoughtInBox.copyWith(sha256: digest);
      await box.put(t.id, updatedThought);
    }
    return digest;
  }

  /// Mark a Thought as synced after remote upload+upsert succeeds.
  Future<void> updateAfterSync({
    required Thought thought,
    required String remoteId,
    DateTime? uploadedAt,
  }) async {
    final box = await _open();
    final updatedThought = thought.copyWith(
      remoteId: remoteId,
      uploadedAt: uploadedAt ?? DateTime.now(),
    );
    await box.put(thought.id, updatedThought);
  }

  /// When user edits title/tags/transcript locally.
  Future<void> upsertLocal(Thought t) async {
    final box = await _open();
    await box.put(t.id, t);
  }

  /// Delete locally; optionally used by SyncService after remote delete.
  Future<void> deleteLocal(String thoughtId) async {
    final box = await _open();
    await box.delete(thoughtId);
  }

  /// Helper for “rebuild queue on app start” — find unsynced.
  Future<List<Thought>> reloadUnsynced() => getPendingSync();
}
