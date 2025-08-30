import 'dart:io';
import 'package:open_filex/open_filex.dart';

Future<void> openWithSystemPlayer(String path) async {
  try { await OpenFilex.open(path); } catch (_) {}
}

Future<void> openLocation(String path) async {
  try {
    if (Platform.isWindows) {
      await Process.start('explorer.exe', ['/select,', path]);
    } else {
      // best-effort: open parent folder
      await OpenFilex.open(File(path).parent.path);
    }
  } catch (_) {}
}
