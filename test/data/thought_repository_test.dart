import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hold_that_thought/data/thought_repository.dart';
import 'package:hold_that_thought/models/thought.dart';
import 'dart:io';

void main() {
  group('HiveThoughtRepository', () {
    late HiveThoughtRepository repository;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('test_hive');
      Hive.init(tempDir.path);
      Hive.registerAdapter(ThoughtAdapter());
      repository = HiveThoughtRepository();
      await repository.init();
    });

    tearDown(() async {
      await Hive.deleteFromDisk();
      await tempDir.delete(recursive: true);
    });

    test('create() adds a thought to the box', () async {
      final thought = await repository.create('Test thought');
      final thoughtsStream = repository.watchAll();

      final thoughts = await thoughtsStream.first;
      expect(thoughts.length, 1);
      expect(thoughts.first.id, thought.id);
      expect(thoughts.first.text, 'Test thought');
    });

    test('delete() removes a thought from the box', () async {
      final thought = await repository.create('To be deleted');
      await repository.delete(thought.id);

      final thoughts = await repository.watchAll().first;
      expect(thoughts.isEmpty, isTrue);
    });

    test('togglePin() updates the pinned status and sorts correctly', () async {
      final thought1 = await repository.create('Thought 1');
      await Future.delayed(const Duration(milliseconds: 10)); // ensure different timestamps
      final thought2 = await repository.create('Thought 2');

      await repository.togglePin(thought1.id);

      final thoughts = await repository.watchAll().first;
      expect(thoughts.length, 2);
      expect(thoughts.first.id, thought1.id); // Pinned thought should be first
      expect(thoughts.first.pinned, isTrue);
      expect(thoughts.last.id, thought2.id);
    });

    test('watchAll() stream emits sorted thoughts', () async {
      final thought1 = await repository.create('First thought');
      await Future.delayed(const Duration(milliseconds: 10));
      final thought2 = await repository.create('Second thought');
      await Future.delayed(const Duration(milliseconds: 10));
      final thought3 = await repository.create('Third thought');

      await repository.togglePin(thought2.id);

      final thoughts = await repository.watchAll().first;

      expect(thoughts.length, 3);
      expect(thoughts[0].id, thought2.id); // Pinned
      expect(thoughts[1].id, thought3.id); // Most recent
      expect(thoughts[2].id, thought1.id); // Oldest
    });
  });
}
