import 'dart:io';
import 'package:test/test.dart';
import 'package:hive/hive.dart';

import 'package:hold_that_thought/models/thought.dart';
import 'package:hold_that_thought/data/hive_thought_repository.dart';

void main() {
  late Directory tempDir;
  late HiveThoughtRepository repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('htt_hive_test_');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(1)) { // My typeId is 1
      Hive.registerAdapter(ThoughtAdapter());
    }

    repo = HiveThoughtRepository();
    await repo.init();
  });

  tearDown(() async {
    await Hive.close();
    try { await tempDir.delete(recursive: true); } catch (_) {}
  });

  test('capture → list → recall → archive loop', () async {
    // 1) Capture
    final created = await repo.create(
      content: 'Kōrero test thought',
    );
    expect(created.id, isNotEmpty);

    // 2) List
    final all = await repo.watchAll(includeArchived: false).first;
    expect(all.any((t) => t.id == created.id), isTrue);

    // 3) Recall by id
    final recalled = await repo.getById(created.id);
    expect(recalled?.content, 'Kōrero test thought');

    // 4) Archive, then ensure it disappears from active list
    await repo.archive(created.id, archived: true);
    final active = await repo.watchAll(includeArchived: false).first;
    expect(active.any((t) => t.id == created.id), isFalse);

    // 5) Ensure it’s still present if we include archived
    final withArchived = await repo.watchAll(includeArchived: true).first;
    expect(withArchived.any((t) => t.id == created.id), isTrue);
  });
}
