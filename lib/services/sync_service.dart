import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/models/thought.dart';
import 'package:hold_that_thought/services/repository/thought_repository.dart';
import 'package:hold_that_thought/services/sync/sync_provider.dart';
import 'package:hold_that_thought/state/repository_providers.dart';
import 'package:hold_that_thought/state/sync_events.dart';
import 'package:hold_that_thought/state/sync_providers.dart';

class SyncService {
  final SyncProvider _provider;
  final ThoughtRepository _repo;
  final Ref _ref;
  String? _userId;

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  List<Thought> _queue = [];
  bool _isProcessing = false;

  SyncService({
    required SyncProvider provider,
    required ThoughtRepository repository,
    required Ref ref,
  })  : _provider = provider,
        _repo = repository,
        _ref = ref;

  void setUserId(String? userId) {
    _userId = userId;
  }

  void start() {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((_) => processQueue());
    // Initial check
    processQueue();
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  Future<void> processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _isProcessing = false;
      return;
    }

    _queue = await _repo.getPendingSync();
    if (_queue.isNotEmpty) {
      _ref.read(syncEventBusProvider.notifier).emit(SyncEvent(SyncEventType.queueStarted));
    }

    while (_queue.isNotEmpty) {
      final thought = _queue.first;
      final success = await _uploadThoughtWithRetries(thought);
      if (success) {
        _queue.removeAt(0);
      } else {
        // If a thought fails, stop processing to avoid head-of-line blocking.
        break;
      }
    }

    if (_queue.isEmpty) {
      _ref.read(syncEventBusProvider.notifier).emit(SyncEvent(SyncEventType.bulkCompleted));
    }

    _isProcessing = false;
  }

  Future<void> retry(String thoughtId) async {
    final thought = await _repo.getThought(thoughtId);
    if (thought != null) {
      await _uploadThoughtWithRetries(thought);
    }
  }

  String _getAudioStoragePath(String thoughtId) {
    if (_userId == null) throw Exception("User not signed in for sync.");
    return '$_userId/$thoughtId/audio.m4a';
  }

  String _getTranscriptStoragePath(String thoughtId) {
    if (_userId == null) throw Exception("User not signed in for sync.");
    return '$_userId/$thoughtId/transcript.txt';
  }

  Future<bool> _uploadThoughtWithRetries(Thought thought) async {
    _ref.read(syncEventBusProvider.notifier).emit(SyncEvent(SyncEventType.itemUploadStarted, thoughtId: thought.id));
    int attempts = 0;
    while (attempts < 3) {
      attempts++;
      try {
        await _provider.ensureSignedIn();

        await _repo.ensureSha256(thought);

        final audioPath = _getAudioStoragePath(thought.id);
        await _provider.uploadAudio(localPath: thought.path, objectPath: audioPath);

        // For now, we assume transcript is part of metadata or not a separate file.
        // The interface supports it if we add it later.
        final transcriptPath = _getTranscriptStoragePath(thought.id);

        final remoteId = await _provider.upsertMetadata(thought,
            audioPath: audioPath, transcriptPath: transcriptPath);

        await _repo.updateAfterSync(thought: thought, remoteId: remoteId);

        _ref.invalidate(thoughtsListProvider);
        _ref.invalidate(syncStatsProvider);

        _ref.read(syncEventBusProvider.notifier).emit(SyncEvent(SyncEventType.itemUploadSucceeded, thoughtId: thought.id));

        return true; // Success
      } catch (e) {
        print('Attempt $attempts: Failed to upload thought ${thought.id}: $e');
        if (attempts >= 3) {
          _ref.read(syncEventBusProvider.notifier).emit(SyncEvent(SyncEventType.itemUploadFailed, thoughtId: thought.id, message: e.toString()));
          print('Max retries reached for thought ${thought.id}.');
          return false; // Failure
        }
        await Future.delayed(Duration(seconds: 5 * attempts));
      }
    }
    return false;
  }

  Future<void> deleteThoughtFromCloud(Thought thought) async {
    if (thought.remoteId == null) return;
    try {
      await _provider.deleteRemote(
        remoteId: thought.remoteId!,
        audioPath: _getAudioStoragePath(thought.id),
        transcriptPath: _getTranscriptStoragePath(thought.id),
      );
    } catch (e) {
      print('Failed to delete thought from cloud: $e');
      // Optionally, re-throw or handle more gracefully (e.g., add to a failed-delete queue)
    }
  }
}
