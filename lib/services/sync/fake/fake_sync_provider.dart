import 'dart:async';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../../../models/thought.dart';
import '../sync_provider.dart'; // your interface: see Phase 9 doc

/// A deterministic, fileless backend for tests & local dev.
/// Stores "objects" and "rows" in Maps; exposes progress streams.
class FakeSyncProvider implements SyncProvider {
  final _uuid = const Uuid();

  // "Object storage": objectPath -> bytes length.
  final Map<String, int> storage = {};

  // "DB table": id -> row map.
  final Map<String, Map<String, dynamic>> table = {};

  // Task progress by key (we use objectPath as taskId).
  final Map<String, StreamController<double>> _progress = {};

  // Flags to simulate failures.
  bool failUploads = false;
  bool failUpserts = false;
  bool failDeletes = false;

  Duration uploadStepDelay = const Duration(milliseconds: 60);
  int uploadSteps = 6;

  @override
  Future<void> ensureSignedIn() async {
    // no-op; pretend we are always signed in
  }

  Stream<double> _emitProgress(String taskId) {
    _progress.putIfAbsent(taskId, () => StreamController<double>.broadcast());
    return _progress[taskId]!.stream;
  }

  void _updateProgress(String taskId, double v) {
    final c = _progress.putIfAbsent(taskId, () => StreamController<double>.broadcast());
    c.add(v.clamp(0.0, 1.0));
    if (v >= 1.0) c.close();
  }

  @override
  Stream<double> uploadProgress(String taskId) {
    return _emitProgress(taskId);
  }

  @override
  Future<String> uploadAudio({required String localPath, required String objectPath}) async {
    if (failUploads) {
      _updateProgress(objectPath, 0.0);
      throw Exception('Simulated audio upload failure');
    }
    final f = File(localPath);
    final bytes = await f.readAsBytes();

    // Fake stepped progress
    for (var i = 1; i <= uploadSteps; i++) {
      await Future.delayed(uploadStepDelay);
      _updateProgress(objectPath, i / uploadSteps);
    }
    storage[objectPath] = bytes.length;
    return objectPath; // also used as taskId for progress
  }

  @override
  Future<String> uploadTranscript({required String localPath, required String objectPath}) async {
    if (failUploads) {
      _updateProgress(objectPath, 0.0);
      throw Exception('Simulated transcript upload failure');
    }
    final f = File(localPath);
    final bytes = await f.readAsBytes();
    for (var i = 1; i <= uploadSteps; i++) {
      await Future.delayed(uploadStepDelay);
      _updateProgress(objectPath, i / uploadSteps);
    }
    storage[objectPath] = bytes.length;
    return objectPath;
  }

  @override
  Future<String> upsertMetadata(Thought t, {required String audioPath, required String transcriptPath}) async {
    if (failUpserts) throw Exception('Simulated metadata upsert failure');
    final id = t.remoteId ?? _uuid.v4();
    table[id] = {
      'id': id,
      'created_at': t.createdAt.toIso8601String(),
      'duration_ms': t.durationMs,
      'title': t.title,
      'tags': t.tags,
      'audio_path': audioPath,
      'transcript_path': transcriptPath,
      'sha256': t.sha256,
      'local_thought_id': t.id,
    };
    return id;
  }

  @override
  Future<void> deleteRemote({required String remoteId, required String audioPath, required String transcriptPath}) async {
    if (failDeletes) throw Exception('Simulated delete failure');
    table.remove(remoteId);
    storage.remove(audioPath);
    storage.remove(transcriptPath);
  }

  @override
  Future<void> signOut() async {
    // no-op
  }
}
