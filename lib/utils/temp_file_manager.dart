import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:logging/logging.dart';

/// Utility class for managing temporary files
class TempFileManager {
  static final Logger _logger = Logger('TempFileManager');
  static Directory? _testTempDir;

  /// Set a test directory for unit testing
  static void setTestTempDir(Directory dir) {
    _testTempDir = dir;
  }

  /// Reset test directory
  static void resetTestTempDir() {
    _testTempDir = null;
  }

  /// Temporary directory for decrypted files
  static Future<Directory> get _tempDir async {
    // Use test directory if set
    if (_testTempDir != null) {
      return _testTempDir!;
    }

    // Use actual temp directory
    final appTempDir = await getTemporaryDirectory();
    final decryptedDir = Directory(path.join(appTempDir.path, 'decrypted'));
    if (!await decryptedDir.exists()) {
      await decryptedDir.create(recursive: true);
    }
    return decryptedDir;
  }

  /// Cleans up all temporary decrypted files
  static Future<void> cleanupTempFiles() async {
    try {
      final dir = await _tempDir;
      if (await dir.exists()) {
        final files = await dir.list().toList();
        _logger.info('Cleaning up ${files.length} temporary files');

        for (final file in files) {
          if (file is File) {
            try {
              await file.delete();
            } catch (e) {
              _logger.warning('Failed to delete temporary file: ${file.path}', e);
            }
          }
        }
      }
    } catch (e) {
      _logger.severe('Error cleaning up temporary files', e);
    }
  }

  /// Creates a temporary file for storing decrypted content
  static Future<File> createTempFile(String extension) async {
    final dir = await _tempDir;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'temp_$timestamp.$extension';
    return File(path.join(dir.path, fileName));
  }

  /// Deletes a specific temporary file
  static Future<void> deleteTempFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      _logger.warning('Failed to delete temporary file: ${file.path}', e);
    }
  }

  /// Gets the number of temporary files
  static Future<int> getTempFileCount() async {
    try {
      final dir = await _tempDir;
      if (await dir.exists()) {
        final files = await dir.list().where((entity) => entity is File).toList();
        return files.length;
      }
    } catch (e) {
      _logger.severe('Error counting temporary files', e);
    }
    return 0;
  }
}
