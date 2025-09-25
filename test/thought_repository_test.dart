import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import 'hive_test_utils.dart';
import 'package:hold_that_thought/models/thought.dart';
import 'package:hold_that_thought/services/repository/thought_repository.dart';

void main() {
  group('ThoughtRepository', () {
    late Cleanup cleanup;

    setUpAll(() async {
      final init = await initHiveForTest();
      cleanup = init.$2;
      // Register your adapter (generated or handwritten)
      if (!Hive.isAdapterRegistered(7)) {
        Hive.registerAdapter(ThoughtAdapter());
      }
    });

    tearDownAll(() async {
      await cleanup();
    });

    test('ensureSha256() computes and persists digest', () async {
      final repo = ThoughtRepository();

      // Create a temp audio file with known contents.
      final tmp = await Directory.systemTemp.createTemp('htt_audio_');
      final audio = File('${tmp.path}/a.m4a');
      await audio.writeAsBytes(utf8.encode('hello-audio')); // deterministic bytes

      // Seed a Thought into Hive.
      final box = await Hive.openBox<Thought>(ThoughtRepository.boxName);
      final t = Thought(
        id: 't1',
        path: audio.path,
        createdAt: DateTime.now(),
      );
      await box.put(t.id, t);

      // Act
      final digest = await repo.ensureSha256(t);

      // Assert
      final expected = sha256.convert(utf8.encode('hello-audio')).toString();
      expect(digest, equals(expected));

      // Re-read from Hive to ensure it persisted.
      final reloaded = box.get('t1');
      expect(reloaded!.sha256, expected);
    });

    test('updateAfterSync() sets remoteId & uploadedAt and persists', () async {
      final repo = ThoughtRepository();
      final box = await Hive.openBox<Thought>(ThoughtRepository.boxName);

      final t = Thought(
        id: 't2',
        path: '/tmp/doesntmatter.m4a',
        createdAt: DateTime.now(),
      );
      await box.put(t.id, t);

      final before = box.get('t2')!;
      expect(before.remoteId, isNull);
      expect(before.uploadedAt, isNull);

      await repo.updateAfterSync(thought: before, remoteId: 'remote-123');

      final after = box.get('t2')!;
      expect(after.remoteId, 'remote-123');
      expect(after.uploadedAt, isNotNull);
    });
  });
}
