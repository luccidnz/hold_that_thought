# Testing

## How to test storage with Hive

When testing code that uses Hive for storage, it's important to initialize Hive in a temporary directory to avoid conflicts with your development database. You also need to make sure that the necessary `TypeAdapter`s are registered.

Here is an example of how to set up a test for a Hive-based repository:

```dart
// test/data/hive_thought_repository_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:your_app/data/hive_thought_repository.dart';
import 'package:your_app/models/thought.dart';

void main() {
  late Directory dir;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(ThoughtAdapter());
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('create and fetch', () async {
    final repo = HiveThoughtRepository();
    await repo.init();
    final t = await repo.create('hello');
    final fetched = await repo.getById(t.id);
    expect(fetched?.content, 'hello');
  });
}
```

### Running build_runner

If you make changes to your Hive models (the classes annotated with `@HiveType`), you will need to run `build_runner` to regenerate the `TypeAdapter`s.

You can run `build_runner` with the following command:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```
