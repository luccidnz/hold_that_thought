import 'dart:io';
import 'package:hold_that_thought/models/thought.dart';
import 'package:hold_that_thought/services/sync/sync_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseSyncProvider implements SyncProvider {
  SupabaseClient? _client;

  // This needs to be configured from the settings page.
  String? _url;
  String? _anonKey;

  void configure(String url, String anonKey) {
    _url = url;
    _anonKey = anonKey;
  }

  Future<void> _initialize() async {
    if (_client != null) return;
    if (_url == null || _anonKey == null) {
      throw Exception('Supabase URL and anon key must be configured in Settings or .env file.');
    }
    if (_url!.contains('example.supabase.co')) {
      throw Exception('Please replace example.supabase.co with your actual Supabase project URL.');
    }
    await Supabase.initialize(url: _url!, anonKey: _anonKey!);
    _client = Supabase.instance.client;
  }

  @override
  Future<void> ensureSignedIn() async {
    await _initialize();
    if (_client!.auth.currentSession == null) {
      await _client!.auth.signInAnonymously();
    }
  }

  @override
  Stream<double> uploadProgress(String taskId) {
    // Supabase storage client doesn't expose a progress stream directly.
    // This would require a more complex implementation, e.g., using a custom
    // uploader or a different storage solution. For now, we return an empty stream.
    return const Stream.empty();
  }

  @override
  Future<String> uploadAudio(
      {required String localPath, required String objectPath}) async {
    if (_client == null) throw Exception('Supabase client not initialized');
    final file = File(localPath);
    await _client!.storage
        .from('thoughts')
        .upload(objectPath, file, fileOptions: const FileOptions(upsert: true));
    return objectPath;
  }

  @override
  Future<String> uploadTranscript(
      {required String localPath, required String objectPath}) async {
    if (_client == null) throw Exception('Supabase client not initialized');
    final file = File(localPath);
    await _client!.storage
        .from('thoughts')
        .upload(objectPath, file, fileOptions: const FileOptions(upsert: true));
    return objectPath;
  }

  @override
  Future<String> upsertMetadata(Thought t,
      {required String audioPath, required String transcriptPath}) async {
    if (_client == null) throw Exception('Supabase client not initialized');
    final data = {
      'local_thought_id': t.id,
      'user_id': _client!.auth.currentUser!.id,
      'created_at': t.createdAt.toIso8601String(),
      'duration_ms': t.durationMs,
      'title': t.title,
      'tags': t.tags,
      'transcript_path': transcriptPath,
      'audio_path': audioPath,
      'sha256': t.sha256,
    };

    if (t.remoteId != null) {
      data['id'] = t.remoteId!;
    }

    final result =
        await _client!.from('thoughts_meta').upsert(data).select('id');
    return result.first['id'];
  }

  @override
  Future<void> deleteRemote(
      {required String remoteId,
      required String audioPath,
      required String transcriptPath}) async {
    if (_client == null) throw Exception('Supabase client not initialized');
    await _client!.storage.from('thoughts').remove([audioPath, transcriptPath]);
    await _client!.from('thoughts_meta').delete().eq('id', remoteId);
  }

  @override
  Future<void> signOut() async {
    if (_client == null) throw Exception('Supabase client not initialized');
    await _client!.auth.signOut();
  }

  // Helper method to access the client
  SupabaseClient? getClient() {
    return _client;
  }
}
