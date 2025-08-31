import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_that_thought/models/thought.dart';
import 'package:hold_that_thought/services/sync/fake/fake_sync_provider.dart';

void main() {
  test('FakeSyncProvider uploads with progress and upserts metadata', () async {
    final p = FakeSyncProvider();
    await p.ensureSignedIn();

    // Create temp "audio" & "transcript"
    final tmp = await Directory.systemTemp.createTemp('htt_fake_sync_');
    final audio = File('${tmp.path}/a.m4a')..writeAsStringSync('aaaabbbbcccc');
    final txt = File('${tmp.path}/a.txt')..writeAsStringSync('hello transcript');

    final audioObj = 'user1/2025/08/31/t1/audio.m4a';
    final txtObj = 'user1/2025/08/31/t1/transcript.txt';

    // Observe progress
    final progressValues = <double>[];
    final sub = p.uploadProgress(audioObj).listen(progressValues.add);

    // Uploads
    await p.uploadAudio(localPath: audio.path, objectPath: audioObj);
    await p.uploadTranscript(localPath: txt.path, objectPath: txtObj);

    expect(p.storage.containsKey(audioObj), isTrue);
    expect(p.storage.containsKey(txtObj), isTrue);

    // Upsert meta
    final thought = Thought(id: 't1', path: audio.path, createdAt: DateTime.now());
    final rid = await p.upsertMetadata(thought, audioPath: audioObj, transcriptPath: txtObj);
    expect(p.table[rid], isNotNull);

    await sub.cancel();
    await tmp.delete(recursive: true);

    // Ensure we saw a 1.0 progress at the end.
    expect(progressValues.last, closeTo(1.0, 1e-9));
  });

  test('FakeSyncProvider can simulate failures', () async {
    final p = FakeSyncProvider()..failUploads = true;

    final tmp = await Directory.systemTemp.createTemp('htt_fake_sync_fail_');
    final audio = File('${tmp.path}/a.m4a')..writeAsStringSync('data');
    expect(
      () => p.uploadAudio(localPath: audio.path, objectPath: 'x/y/z.m4a'),
      throwsA(isA<Exception>()),
    );
    await tmp.delete(recursive: true);
  });
}
