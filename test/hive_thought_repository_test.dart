import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;

/// This test validates Hive can init, open, and perform CRUD + simple search
/// in the CI/container environment. It uses only Hive primitives so it
/// compiles even if your app repository isn’t wired yet.
///
/// Later, replace the "direct box usage" section with your actual
/// HiveThoughtRepository calls (see skeleton at bottom).

void main() {
  late Directory tmpDir;
  const boxName = 'thoughts_test';

  setUp(() {
    tmpDir = Directory.systemTemp.createTempSync('hive_env_');
    Hive.init(tmpDir.path);
  });

  tearDown(() async {
    if (Hive.isBoxOpen(boxName)) {
      await Hive.box(boxName).close();
    }
    if (await tmpDir.exists()) {
      // Clean up temp files
      await tmpDir.delete(recursive: true);
    }
  });

  group('Hive CRUD smoke', () {
    test('create/read/update/archive/search', () async {
      // Open a box of Maps so no custom adapters are required.
      final box = await Hive.openBox<Map>(boxName);

      // --- Create
      final id1 = 't1';
      final t1 = <String, dynamic>{
        'id': id1,
        'text': 'Hold that thought',
        'archived': false,
        'createdAt': DateTime.now().toIso8601String(),
      };
      await box.put(id1, t1);
      expect(box.containsKey(id1), isTrue);

      // --- Read
      final read1 = box.get(id1);
      expect(read1?['text'], 'Hold that thought');
      expect(read1?['archived'], isFalse);

      // --- List
      final all = box.values.toList(growable: false);
      expect(all.length, 1);

      // --- Update
      final t1Updated = Map<String, dynamic>.from(read1!);
      t1Updated['text'] = 'Hold that thought (edited)';
      await box.put(id1, t1Updated);
      expect(box.get(id1)?['text'], contains('(edited)'));

      // --- Archive (soft delete)
      final t1Archived = Map<String, dynamic>.from(box.get(id1)!);
      t1Archived['archived'] = true;
      await box.put(id1, t1Archived);
      expect(box.get(id1)?['archived'], isTrue);

      // --- Search (simple contains)
      final query = 'hold that';
      final results = box.values.where((m) {
        final txt = (m['text'] ?? '').toString().toLowerCase();
        final isArchived = (m['archived'] ?? false) == true;
        return txt.contains(query) && !isArchived;
      }).toList();
      // Since archived=true, search should be empty
      expect(results, isEmpty);

      await box.close();
    });
  });
}

/// -------------------------------------------------------------------------
/// SKELETON for real repository tests (commented):
///
/// import 'package:hold_that_thought/data/hive_thought_repository.dart';
/// import 'package:hold_that_thought/domain/thought.dart';
///
/// late HiveThoughtRepository repo;
///
/// setUp(() async {
///   tmpDir = Directory.systemTemp.createTempSync('hive_repo_');
///   Hive.init(tmpDir.path);
///   repo = HiveThoughtRepository(); // or inject box name
///   await repo.initForTests(tmpDir.path); // if you expose a test init helper
/// });
///
/// test('create returns persisted Thought', () async {
///   final t = Thought(id: 'x', text: 'hello');
///   await repo.create(t);
///   final got = await repo.getById('x');
///   expect(got?.text, 'hello');
/// });
///
/// // add: list(), update(), archive(), search() …
/// -------------------------------------------------------------------------
