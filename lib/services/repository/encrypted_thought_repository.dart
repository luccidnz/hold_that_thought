import 'dart:convert';
import 'dart:io';
import 'package:hold_that_thought/models/encryption_metadata.dart';
import 'package:hold_that_thought/models/thought.dart';
import 'package:hold_that_thought/services/crypto_service.dart';
import 'package:hold_that_thought/services/feature_flags.dart';
import 'package:hold_that_thought/services/repository/thought_repository.dart';
import 'package:hold_that_thought/utils/log_redactor.dart';
import 'package:hold_that_thought/utils/temp_file_manager.dart';
import 'package:path/path.dart' as path;
import 'package:logging/logging.dart';

/// A wrapper around ThoughtRepository that handles encryption/decryption
class EncryptedThoughtRepository {
  final ThoughtRepository _repository;
  final CryptoService _cryptoService;
  final FeatureFlags _featureFlags;
  final Logger _logger = Logger('EncryptedThoughtRepository');

  EncryptedThoughtRepository(this._repository, this._cryptoService, this._featureFlags);

  /// Get a thought by ID and decrypt if needed
  Future<Thought?> getThought(String id) async {
    final thought = await _repository.getThought(id);
    if (thought == null) return null;

    // If the thought is not encrypted, return it as is
    if (!thought.isEncrypted) return thought;

    // If E2EE is not enabled or not armed, return with encrypted content
    final isE2eeEnabled = await _featureFlags.getE2eeEnabled();
    if (!isE2eeEnabled || !_cryptoService.isArmed) return thought;

    // Decrypt the content
    return await _decryptThought(thought);
  }

  /// Get all thoughts and decrypt those that are encrypted
  Future<List<Thought>> getAll() async {
    final thoughts = await _repository.getAll();

    // If E2EE is not enabled or not armed, return as is
    final isE2eeEnabled = await _featureFlags.getE2eeEnabled();
    if (!isE2eeEnabled || !_cryptoService.isArmed) return thoughts;

    // Decrypt all encrypted thoughts
    final decryptedThoughts = <Thought>[];
    for (final thought in thoughts) {
      if (thought.isEncrypted) {
        try {
          final decryptedThought = await _decryptThought(thought);
          decryptedThoughts.add(decryptedThought);
        } catch (e) {
          _logger.warning('Error decrypting thought ${thought.id}: $e');
          // Add the encrypted thought if decryption fails
          decryptedThoughts.add(thought);
        }
      } else {
        decryptedThoughts.add(thought);
      }
    }

    return decryptedThoughts;
  }

  /// Get pending sync thoughts (may be encrypted)
  Future<List<Thought>> getPendingSync() => _repository.getPendingSync();

  /// Ensure SHA256 hash is computed for a thought
  Future<String?> ensureSha256(Thought thought) => _repository.ensureSha256(thought);

  /// Update a thought after sync
  Future<void> updateAfterSync({
    required Thought thought,
    required String remoteId,
    DateTime? uploadedAt,
  }) => _repository.updateAfterSync(
    thought: thought,
    remoteId: remoteId,
    uploadedAt: uploadedAt,
  );

  /// Save or update a thought locally, encrypting if needed
  Future<void> upsertLocal(Thought thought) async {
    final isE2eeEnabled = await _featureFlags.getE2eeEnabled();

    // If E2EE is not enabled or the thought is already in the desired state, save as is
    if (!isE2eeEnabled || !_cryptoService.isArmed ||
        (thought.isEncrypted && isE2eeEnabled) ||
        (!thought.isEncrypted && !isE2eeEnabled)) {
      return _repository.upsertLocal(thought);
    }

    // If E2EE is enabled and the thought is not encrypted, encrypt it
    if (isE2eeEnabled && !thought.isEncrypted) {
      final encryptedThought = await _encryptThought(thought);
      return _repository.upsertLocal(encryptedThought);
    }

    // If E2EE is disabled and the thought is encrypted, decrypt it
    if (!isE2eeEnabled && thought.isEncrypted) {
      final decryptedThought = await _decryptThought(thought);
      final unencryptedThought = decryptedThought.copyWith(
        encryptionMetadata: null,
        isEncrypted: false,
      );
      return _repository.upsertLocal(unencryptedThought);
    }

    // Default case - just save the thought
    return _repository.upsertLocal(thought);
  }

  /// Delete a thought locally
  Future<void> deleteLocal(String thoughtId) => _repository.deleteLocal(thoughtId);

  /// Helper for "rebuild queue on app start" — find unsynced.
  Future<List<Thought>> reloadUnsynced() => _repository.reloadUnsynced();

  /// Encrypt the audio file associated with a thought
  Future<String> encryptAudioFile(Thought thought) async {
    try {
      // Encrypt the audio file
      final encryptedPath = await _cryptoService.encryptFile(thought.path, '');
      _logger.info('Encrypted audio file: ${LogRedactor.redactPath(encryptedPath)}');
      return encryptedPath;
    } catch (e) {
      _logger.severe('Error encrypting audio file: ${LogRedactor.redactPath(thought.path)}', e);
      rethrow;
    }
  }

  /// Decrypt the audio file associated with a thought
  /// Returns the path to the decrypted temporary file
  Future<String> decryptAudioFile(String encryptedPath) async {
    try {
      // Create a temporary file for the decrypted content
      final tempFile = await TempFileManager.createTempFile(
        path.extension(encryptedPath.replaceAll('.enc', '')).replaceAll('.', '')
      );

      // Decrypt the file to a new location
      final decryptedPath = await _cryptoService.decryptFile(encryptedPath, '');

      // Copy to temp file location so we can manage its lifecycle
      await File(decryptedPath).copy(tempFile.path);

      // Delete the original decrypted file
      await File(decryptedPath).delete();

      _logger.info('Decrypted audio file to temp location: ${LogRedactor.redactPath(tempFile.path)}');
      return tempFile.path;
    } catch (e) {
      _logger.severe('Error decrypting audio file: ${LogRedactor.redactPath(encryptedPath)}', e);
      rethrow;
    }
  }

  /// Cleanup temporary decrypted files
  Future<void> cleanupTempFiles() async {
    try {
      await TempFileManager.cleanupTempFiles();
      _logger.info('Cleaned up temporary decrypted files');
    } catch (e) {
      _logger.warning('Error cleaning up temporary files', e);
    }
  }

  /// Encrypt a thought's sensitive fields
  Future<Thought> _encryptThought(Thought thought) async {
    // Only encrypt if there's something to encrypt
    if (thought.transcript == null && thought.title == null) {
      return thought;
    }

    // Encrypt the transcript if it exists
    String? encryptedTranscript;
    String? encryptedTitle;
    ThoughtEncryptionMetadata? metadata;

    if (thought.transcript != null) {
      final result = await _cryptoService.encryptString(thought.transcript!, '');
      encryptedTranscript = result['ciphertext'];
      metadata = ThoughtEncryptionMetadata.fromJson(result['metadata']);
    }

    // Encrypt the title if it exists
    if (thought.title != null) {
      final result = await _cryptoService.encryptString(thought.title!, '');
      encryptedTitle = result['ciphertext'];
      // Use the same metadata for both fields
      if (metadata == null) {
        metadata = ThoughtEncryptionMetadata.fromJson(result['metadata']);
      }
    }

    // Return the encrypted thought
    return thought.copyWith(
      transcript: encryptedTranscript ?? thought.transcript,
      title: encryptedTitle ?? thought.title,
      encryptionMetadata: metadata?.toJsonString(),
      isEncrypted: true,
    );
  }

  /// Decrypt a thought's sensitive fields
  Future<Thought> _decryptThought(Thought thought) async {
    // If not encrypted or no metadata, return as is
    if (!thought.isEncrypted || thought.encryptionMetadata == null) {
      return thought;
    }

    try {
      final metadata = ThoughtEncryptionMetadata.fromJsonString(thought.encryptionMetadata!);

      // Decrypt the transcript if it exists
      String? decryptedTranscript;
      if (thought.transcript != null) {
        decryptedTranscript = await _cryptoService.decryptString(
          thought.transcript!,
          EncryptionMetadata.fromJson(metadata.toJson()),
          '',
        );
      }

      // Decrypt the title if it exists
      String? decryptedTitle;
      if (thought.title != null) {
        decryptedTitle = await _cryptoService.decryptString(
          thought.title!,
          EncryptionMetadata.fromJson(metadata.toJson()),
          '',
        );
      }

      // Return the decrypted thought with original metadata preserved
      return thought.copyWith(
        transcript: decryptedTranscript ?? thought.transcript,
        title: decryptedTitle ?? thought.title,
        // Keep the metadata and encrypted flag for re-encryption
        encryptionMetadata: thought.encryptionMetadata,
        isEncrypted: thought.isEncrypted,
      );
    } catch (e) {
      _logger.warning('Error decrypting thought: $e');
      // Return the original thought if decryption fails
      return thought;
    }
  }

  /// Encrypt all thoughts in the repository
  Future<void> encryptAllThoughts() async {
    final thoughts = await _repository.getAll();
    for (final thought in thoughts) {
      if (!thought.isEncrypted) {
        final encryptedThought = await _encryptThought(thought);
        await _repository.upsertLocal(encryptedThought);
      }
    }
  }

  /// Decrypt all thoughts in the repository
  Future<void> decryptAllThoughts() async {
    final thoughts = await _repository.getAll();
    for (final thought in thoughts) {
      if (thought.isEncrypted) {
        final decryptedThought = await _decryptThought(thought);
        final unencryptedThought = decryptedThought.copyWith(
          encryptionMetadata: null,
          isEncrypted: false,
        );
        await _repository.upsertLocal(unencryptedThought);
      }
    }
  }
}
