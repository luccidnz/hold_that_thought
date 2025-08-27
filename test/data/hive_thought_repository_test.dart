import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hold_that_thought/data/hive_thought_repository.dart';
import 'package:hold_that_thought/models/thought.dart';

void main() {
  late Directory dir;
  late HiveThoughtRepository repo;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ThoughtAdapter());
    }
    repo = HiveThoughtRepository();
    await repo.init();
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('create and fetch', () async {
    final t = await repo.create('hello');
    final fetched = await repo.getById(t.id);
    expect(fetched?.content, 'hello');
  });

  test('watchAll returns updates', () async {
    final thoughtsStream = repo.watchAll();
    expect(thoughtsStream, emitsInOrder([
      emits([]),
    ]));

    await repo.create('first');
    await Future.delayed(const Duration(milliseconds: 100));
    expect(
        thoughtsStream,
        emitsInOrder([
          emits([isA<Thought>()..having((t) => t.content, 'content', 'first')])
        ]));

    await repo.create('second');
    await Future.delayed(const Duration(milliseconds: 100));
    expect(
        thoughtsStream,
        emitsInOrder([
          emits([
            isA<Thought>()..having((t) => t.content, 'content', 'second'),
            isA<Thought>()..having((t) => t.content, 'content', 'first')
          ])
        ]));
  });

  test('search finds thoughts', () async {
    await repo.create('hello world');
    await repo.create('hello there');
    await repo.create('another thought');

    final results = await repo.search('hello');
    expect(results.length, 2);
    expect(results.any((t) => t.content == 'hello world'), isTrue);
    expect(results.any((t) => t.content == 'hello there'), isTrue);
  });

  test('update modifies a thought', () async {
    final t = await repo.create('original content');
    final updated = t.copyWith(content: 'updated content');
    await repo.update(updated);

    final fetched = await repo.getById(t.id);
    expect(fetched?.content, 'updated content');
  });

  test('archive and unarchive a thought', () async {
    final t = await repo.create('a thought to archive');
    await repo.archive(t.id);

    final thoughts = await repo.watchAll().first;
    expect(thoughts.isEmpty, isTrue);

    final thoughtsWithArchived = await repo.watchAll(includeArchived: true).first;
    expect(thoughtsWithArchived.length, 1);
    expect(thoughtsWithArchived.first.archived, isTrue);

    await repo.archive(t.id, archived: false);
    final unarchivedThoughts = await repo.watchAll().first;
    expect(unarchivedThoughts.length, 1);
    expect(unarchivedThoughts.first.archived, isFalse);
  });

  test('delete removes a thought', () async {
    final t = await repo.create('a thought to delete');
    await repo.delete(t.id);

    final fetched = await repo.getById(t.id);
    expect(fetched, isNull);
  });
}
