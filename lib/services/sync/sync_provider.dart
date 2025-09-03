import '../../models/thought.dart';

abstract class SyncProvider {
  Future<void> ensureSignedIn();

  Stream<double> uploadProgress(String taskId);

  Future<String> uploadAudio({
    required String localPath,
    required String objectPath,
  });

  Future<String> uploadTranscript({
    required String localPath,
    required String objectPath,
  });

  Future<String> upsertMetadata(
    Thought t, {
    required String audioPath,
    required String transcriptPath,
  });

  Future<void> deleteRemote({
    required String remoteId,
    required String audioPath,
    required String transcriptPath,
  });

  Future<void> signOut();
}
