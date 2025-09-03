import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/services/repository/encrypted_thought_repository.dart';
import 'package:hold_that_thought/state/encrypted_repo_providers.dart';
import 'package:hold_that_thought/utils/log_redactor.dart';
import 'package:logging/logging.dart';
import 'package:open_filex/open_filex.dart';

final Logger _logger = Logger('OpenFileHelper');

/// Opens a file with the system player
/// If the file is encrypted (.enc extension), it will be decrypted first
Future<void> openWithSystemPlayer(String path, {WidgetRef? ref}) async {
  try {
    String fileToOpen = path;
    bool isTemp = false;

    // Handle encrypted files
    if (path.endsWith('.enc') && ref != null) {
      try {
        _logger.info('Decrypting encrypted file for playback: ${LogRedactor.redactPath(path)}');
        final repo = ref.read(encryptedThoughtRepositoryProvider);
        fileToOpen = await repo.decryptAudioFile(path);
        isTemp = true;
        _logger.info('Opening decrypted temp file: ${LogRedactor.redactPath(fileToOpen)}');
      } catch (e) {
        _logger.severe('Failed to decrypt file for playback: ${LogRedactor.redactPath(path)}', e);
        // Try to open the encrypted file as a fallback
      }
    }

    // Open the file
    await OpenFilex.open(fileToOpen);

    // Schedule cleanup after a delay to ensure the file is no longer in use
    if (isTemp && ref != null) {
      Future.delayed(const Duration(minutes: 10), () async {
        try {
          final repo = ref.read(encryptedThoughtRepositoryProvider);
          await repo.cleanupTempFiles();
          _logger.info('Cleaned up temporary files after playback');
        } catch (e) {
          _logger.warning('Failed to clean up temporary files: $e');
        }
      });
    }
  } catch (e) {
    _logger.warning('Failed to open file with system player: ${LogRedactor.redactPath(path)}', e);
  }
}

/// Opens the location of a file in the file explorer
Future<void> openLocation(String path) async {
  try {
    if (Platform.isWindows) {
      await Process.start('explorer.exe', ['/select,', path]);
    } else {
      // best-effort: open parent folder
      await OpenFilex.open(File(path).parent.path);
    }
  } catch (e) {
    _logger.warning('Failed to open location: ${LogRedactor.redactPath(path)}', e);
  }
}
