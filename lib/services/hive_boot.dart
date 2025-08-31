import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/thought.dart';

Future<Box<Thought>> openThoughtsBoxRobust() async {
  await Hive.initFlutter();
  final support = await getApplicationSupportDirectory();
  final hivePath = '${support.path}${Platform.pathSeparator}hive_boxes';
  await Directory(hivePath).create(recursive: true);
  Hive.init(hivePath);
  if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(ThoughtAdapter());

  Future<Box<Thought>> openAttempt() => Hive.openBox<Thought>('thoughts');
  try {
    return await openAttempt();
  } catch (_) {
    for (final name in const ['thoughts.hive', 'thoughts.lock', 'thoughts.log']) {
      final f = File('$hivePath${Platform.pathSeparator}$name');
      if (await f.exists()) {
        try {
          await f.delete();
        } catch (_) {}
      }
    }
  return await openAttempt();
  }
}
