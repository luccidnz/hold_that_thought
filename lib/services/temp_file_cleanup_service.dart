import 'dart:async';
import 'package:hold_that_thought/utils/temp_file_manager.dart';
import 'package:logging/logging.dart';

/// A service that periodically cleans up temporary files
class TemporaryFileCleanupService {
  final Logger _logger = Logger('TemporaryFileCleanupService');
  Timer? _cleanupTimer;

  /// Start the periodic cleanup service
  void start() {
    // Clean up immediately on start
    _cleanupTempFiles();

    // Schedule periodic cleanup
    _cleanupTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _cleanupTempFiles();
    });

    _logger.info('Temporary file cleanup service started');
  }

  /// Stop the periodic cleanup service
  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _logger.info('Temporary file cleanup service stopped');
  }

  /// Clean up temporary files
  Future<void> _cleanupTempFiles() async {
    try {
      final count = await TempFileManager.getTempFileCount();
      if (count > 0) {
        _logger.info('Cleaning up $count temporary files');
        await TempFileManager.cleanupTempFiles();
      }
    } catch (e) {
      _logger.warning('Error cleaning up temporary files: $e');
    }
  }
}
