import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Use an isolated temp dir for Hive in CI
  final tmp = Directory.systemTemp.createTempSync('hive_test_');
  Hive.init(tmp.path);

  await testMain();

  try {
    tmp.deleteSync(recursive: true);
  } catch (_) {}
}
