import 'dart:io';
import 'package:hive/hive.dart';

typedef Cleanup = Future<void> Function();

Future<(Directory tempDir, Cleanup cleanup)> initHiveForTest() async {
  final tempDir = await Directory.systemTemp.createTemp('htt_hive_test_');
  Hive.init(tempDir.path);
  Future<void> cleanup() async {
    try { await tempDir.delete(recursive: true); } catch (_) {}
  }
  return (tempDir, cleanup);
}
