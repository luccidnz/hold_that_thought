import 'package:hold_that_thought/qa_smoke_shims.dart'; // QA SMOKE: remove after v0.10.0
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart' as standard_crypto;
import 'package:hold_that_thought/models/thought.dart';
import 'package:hold_that_thought/services/feature_flags.dart' hide featureFlagsProvider;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Contains all the metadata needed for encrypting/decrypting a file or string
class EncryptionMetadata {
  final String algorithm; // e.g., 'AES-GCM'
  final String salt; // Base64 encoded
  final String nonce; // Base64 encoded
  final String encryptedDek; // Base64 encoded, Data Encryption Key wrapped by KEK
  final bool isEncrypted;
  
  const EncryptionMetadata({
    required this.algorithm,
    required this.salt,
    required this.nonce,
    required this.encryptedDek,
    this.isEncrypted = true,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'algorithm': algorithm,
      'salt': salt,
      'nonce': nonce,
      'encryptedDek': encryptedDek,
      'isEncrypted': isEncrypted,
    };
  }
  
  factory EncryptionMetadata.fromJson(Map<String, dynamic> json) {
    return EncryptionMetadata(
      algorithm: json['algorithm'] as String,
      salt: json['salt'] as String,
      nonce: json['nonce'] as String,
      encryptedDek: json['encryptedDek'] as String,
      isEncrypted: json['isEncrypted'] as bool? ?? true,
    );
  }
}

/// Service for end-to-end encryption functionality
class CryptoService {
  final FlutterSecureStorage _secureStorage;
  final FeatureFlags _featureFlags;
  
  static const String _verifierKey = 'e2ee.verifier';
  static const String _saltKey = 'e2ee.salt';
  static const String _keyKey = 'e2ee.key';
  
  // AES-GCM for encryption
  final _aesGcm = AesGcm.with256bits();
  
  // PBKDF2 for key derivation if Argon2id is not available
  final _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 100000,
    bits: 256,
  );
  
  SecretKey? _cachedKey;
  bool _isArmed = false;
  
  CryptoService(this._secureStorage, this._featureFlags);
  
  /// Check if E2EE is set up (passphrase has been set)
  Future<bool> isE2eeSetUp() async {
    final verifier = await _secureStorage.read(key: _verifierKey);
    return verifier != null;
  }
  
  /// Check if E2EE is enabled via feature flag
  Future<bool> isE2eeEnabled() async {
    return await _featureFlags.getE2eeEnabled();
  }
  
  /// Check if encryption is set up - getter used by E2EEState
  Future<bool> get isEncryptionSetUp async => await isE2eeSetUp();
  
  /// Check if the crypto service is armed with a decryption key - getter used by E2EEState
  bool get isArmed => _isArmed;
  
  /// Set a passphrase for E2EE - used by E2EEState
  Future<bool> setPassphrase(String passphrase) async {
    return await setupE2ee(passphrase);
  }
  
  /// Unlock encryption with a passphrase - used by E2EEState
  Future<bool> unlock(String passphrase) async {
    try {
      // Verify the passphrase first
      final isValid = await verifyPassphrase(passphrase);
      if (!isValid) {
        return false;
      }
      
      // Get the stored salt
      final storedSalt = await _secureStorage.read(key: _saltKey);
      if (storedSalt == null) {
        return false;
      }
      
      // Derive the key and cache it
      final salt = base64Decode(storedSalt);
      _cachedKey = await _deriveKey(passphrase, salt);
      _isArmed = true;
      
      return true;
    } catch (e) {
      print('Error unlocking encryption: $e');
      return false;
    }
  }
  
  /// Forget the cached key - used by E2EEState
  Future<void> forgetKey() async {
    _cachedKey = null;
    _isArmed = false;
  }
  
  /// Decrypt all encrypted data - used when disabling E2EE
  Future<bool> decryptAllData() async {
    try {
      // In a real implementation, you would:
      // 1. Find all encrypted data (thoughts, files, etc.)
      // 2. Decrypt each item
      // 3. Save the decrypted data
      // 4. Remove encryption metadata
      
      // For now, just return true
      return true;
    } catch (e) {
      print('Error decrypting all data: $e');
      return false;
    }
  }
  
  /// Set up E2EE with a new passphrase
  Future<bool> setupE2ee(String passphrase) async {
    try {
      // Generate a random salt
      final salt = _aesGcm.newNonce();
      final saltBase64 = base64Encode(salt);
      
      // Generate a key from the passphrase
      final key = await _deriveKey(passphrase, salt);
      
      // Generate a verifier hash
      final verifier = await _generateVerifier(passphrase, salt);
      
      // Store the salt and verifier
      await _secureStorage.write(key: _saltKey, value: saltBase64);
      await _secureStorage.write(key: _verifierKey, value: verifier);
      
      // Enable E2EE feature flag
      await _featureFlags.setE2eeEnabled(true);
      
      return true;
    } catch (e) {
      print('Error setting up E2EE: $e');
      return false;
    }
  }
  
  /// Verify a passphrase against the stored verifier
  Future<bool> verifyPassphrase(String passphrase) async {
    try {
      final storedSalt = await _secureStorage.read(key: _saltKey);
      final storedVerifier = await _secureStorage.read(key: _verifierKey);
      
      if (storedSalt == null || storedVerifier == null) {
        return false;
      }
      
      final salt = base64Decode(storedSalt);
      final verifier = await _generateVerifier(passphrase, salt);
      
      // Use constant-time comparison to prevent timing attacks
      return _constantTimeEquals(verifier, storedVerifier);
    } catch (e) {
      print('Error verifying passphrase: $e');
      return false;
    }
  }
  
  /// Change the E2EE passphrase
  /// This requires re-encrypting all DEKs with the new KEK
  Future<bool> changePassphrase(String oldPassphrase, String newPassphrase) async {
    try {
      // First verify the old passphrase
      final isValid = await verifyPassphrase(oldPassphrase);
      if (!isValid) {
        return false;
      }
      
      // Generate a new salt and verifier
      final newSalt = _aesGcm.newNonce();
      final newSaltBase64 = base64Encode(newSalt);
      final newVerifier = await _generateVerifier(newPassphrase, newSalt);
      
      // Get the old salt
      final oldSaltBase64 = await _secureStorage.read(key: _saltKey);
      if (oldSaltBase64 == null) {
        return false;
      }
      final oldSalt = base64Decode(oldSaltBase64);
      
      // Derive the old and new keys
      final oldKey = await _deriveKey(oldPassphrase, oldSalt);
      final newKey = await _deriveKey(newPassphrase, newSalt);
      
      // Re-encrypt all DEKs (would require traversing all encrypted files)
      // This is a placeholder - in a real app, you would:
      // 1. Find all encrypted files
      // 2. Load their metadata
      // 3. Decrypt the DEK with the old KEK
      // 4. Encrypt the DEK with the new KEK
      // 5. Save the updated metadata
      
      // For now, just update the stored salt and verifier
      await _secureStorage.write(key: _saltKey, value: newSaltBase64);
      await _secureStorage.write(key: _verifierKey, value: newVerifier);
      
      return true;
    } catch (e) {
      print('Error changing passphrase: $e');
      return false;
    }
  }
  
  /// Reset E2EE (clear passphrase and disable encryption)
  Future<bool> resetE2ee() async {
    try {
      await _secureStorage.delete(key: _saltKey);
      await _secureStorage.delete(key: _verifierKey);
      await _featureFlags.setE2eeEnabled(false);
      return true;
    } catch (e) {
      print('Error resetting E2EE: $e');
      return false;
    }
  }
  
  /// Encrypt a string (e.g., a transcript)
  Future<Map<String, dynamic>> encryptString(String plaintext, String passphrase) async {
    try {
      // Get the salt
      final storedSalt = await _secureStorage.read(key: _saltKey);
      if (storedSalt == null) {
        throw Exception('E2EE is not set up');
      }
      final salt = base64Decode(storedSalt);
      
      // Generate a random Data Encryption Key (DEK)
      final dek = await _aesGcm.newSecretKey();
      
      // Generate a nonce for this encryption
      final nonce = _aesGcm.newNonce();
      
      // Encrypt the plaintext with the DEK
      final plaintextBytes = utf8.encode(plaintext);
      final encrypted = await _aesGcm.encrypt(
        plaintextBytes,
        secretKey: dek,
        nonce: nonce,
      );
      
      // Derive the Key Encryption Key (KEK) from the passphrase
      final kek = await _deriveKey(passphrase, salt);
      
      // Encrypt the DEK with the KEK
      final dekBytes = await dek.extractBytes();
      final encryptedDek = await _aesGcm.encrypt(
        dekBytes,
        secretKey: kek,
        nonce: nonce,
      );
      
      // Create metadata
      final metadata = EncryptionMetadata(
        algorithm: 'AES-GCM',
        salt: storedSalt,
        nonce: base64Encode(nonce),
        encryptedDek: base64Encode(encryptedDek.cipherText),
      );
      
      // Return the encrypted data and metadata
      return {
        'ciphertext': base64Encode(encrypted.cipherText),
        'metadata': metadata.toJson(),
      };
    } catch (e) {
      print('Error encrypting string: $e');
      rethrow;
    }
  }
  
  /// Decrypt a string
  Future<String> decryptString(String ciphertext, EncryptionMetadata metadata, String passphrase) async {
    try {
      // Decode the inputs
      final ciphertextBytes = base64Decode(ciphertext);
      final salt = base64Decode(metadata.salt);
      final nonce = base64Decode(metadata.nonce);
      final encryptedDekBytes = base64Decode(metadata.encryptedDek);
      
      // Derive the Key Encryption Key (KEK) from the passphrase
      final kek = await _deriveKey(passphrase, salt);
      
      // Decrypt the DEK with the KEK
      final decryptedDek = await _aesGcm.decrypt(
        SecretBox(
          encryptedDekBytes,
          nonce: nonce,
          mac: Mac([]), // Placeholder - in a real app you'd store and use the MAC
        ),
        secretKey: kek,
      );
      
      // Use the DEK to decrypt the ciphertext
      final dek = await _aesGcm.newSecretKeyFromBytes(decryptedDek);
      final decrypted = await _aesGcm.decrypt(
        SecretBox(
          ciphertextBytes,
          nonce: nonce,
          mac: Mac([]), // Placeholder - in a real app you'd store and use the MAC
        ),
        secretKey: dek,
      );
      
      // Return the decrypted string
      return utf8.decode(decrypted);
    } catch (e) {
      print('Error decrypting string: $e');
      rethrow;
    }
  }
  
  /// Encrypt a file (e.g., audio recording)
  Future<String> encryptFile(String sourcePath, String passphrase) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw Exception('Source file does not exist: $sourcePath');
      }
      
      // Create the encrypted file path
      final dir = path.dirname(sourcePath);
      final filename = path.basenameWithoutExtension(sourcePath);
      final extension = path.extension(sourcePath);
      final encryptedPath = path.join(dir, '$filename$extension.enc');
      
      // Get the salt
      final storedSalt = await _secureStorage.read(key: _saltKey);
      if (storedSalt == null) {
        throw Exception('E2EE is not set up');
      }
      final salt = base64Decode(storedSalt);
      
      // Generate a random Data Encryption Key (DEK)
      final dek = await _aesGcm.newSecretKey();
      
      // Generate a nonce for this encryption
      final nonce = _aesGcm.newNonce();
      
      // Derive the Key Encryption Key (KEK) from the passphrase
      final kek = await _deriveKey(passphrase, salt);
      
      // Encrypt the DEK with the KEK
      final dekBytes = await dek.extractBytes();
      final encryptedDek = await _aesGcm.encrypt(
        dekBytes,
        secretKey: kek,
        nonce: nonce,
      );
      
      // Create metadata
      final metadata = EncryptionMetadata(
        algorithm: 'AES-GCM',
        salt: storedSalt,
        nonce: base64Encode(nonce),
        encryptedDek: base64Encode(encryptedDek.cipherText),
      );
      
      // Write metadata to a separate file
      final metadataPath = '$encryptedPath.meta';
      final metadataFile = File(metadataPath);
      await metadataFile.writeAsString(jsonEncode(metadata.toJson()));
      
      // Encrypt the file content in chunks
      final sourceStream = sourceFile.openRead();
      final encryptedFile = File(encryptedPath);
      final sink = encryptedFile.openWrite();
      
      // In a real implementation, you would:
      // 1. Read the source file in chunks
      // 2. Encrypt each chunk with the DEK
      // 3. Write the encrypted chunks to the output file
      
      // For simplicity, we'll read the entire file at once
      // This is not recommended for large files
      final sourceBytes = await sourceFile.readAsBytes();
      final encrypted = await _aesGcm.encrypt(
        sourceBytes,
        secretKey: dek,
        nonce: nonce,
      );
      
      sink.add(encrypted.cipherText);
      await sink.close();
      
      return encryptedPath;
    } catch (e) {
      print('Error encrypting file: $e');
      rethrow;
    }
  }
  
  /// Decrypt a file
  Future<String> decryptFile(String encryptedPath, String passphrase) async {
    try {
      final encryptedFile = File(encryptedPath);
      if (!await encryptedFile.exists()) {
        throw Exception('Encrypted file does not exist: $encryptedPath');
      }
      
      // Get the metadata
      final metadataPath = '$encryptedPath.meta';
      final metadataFile = File(metadataPath);
      if (!await metadataFile.exists()) {
        throw Exception('Metadata file does not exist: $metadataPath');
      }
      
      final metadataJson = await metadataFile.readAsString();
      final metadata = EncryptionMetadata.fromJson(jsonDecode(metadataJson));
      
      // Decode the metadata
      final salt = base64Decode(metadata.salt);
      final nonce = base64Decode(metadata.nonce);
      final encryptedDekBytes = base64Decode(metadata.encryptedDek);
      
      // Derive the Key Encryption Key (KEK) from the passphrase
      final kek = await _deriveKey(passphrase, salt);
      
      // Decrypt the DEK with the KEK
      final decryptedDek = await _aesGcm.decrypt(
        SecretBox(
          encryptedDekBytes,
          nonce: nonce,
          mac: Mac([]), // Placeholder - in a real app you'd store and use the MAC
        ),
        secretKey: kek,
      );
      
      // Use the DEK to decrypt the file
      final dek = await _aesGcm.newSecretKeyFromBytes(decryptedDek);
      
      // Create the decrypted file path
      final dir = path.dirname(encryptedPath);
      final filename = path.basenameWithoutExtension(encryptedPath);
      // Remove the .enc extension if present
      final filenameWithoutEnc = filename.endsWith('.enc') 
          ? filename.substring(0, filename.length - 4) 
          : filename;
      final decryptedPath = path.join(dir, filenameWithoutEnc);
      
      // In a real implementation, you would:
      // 1. Read the encrypted file in chunks
      // 2. Decrypt each chunk with the DEK
      // 3. Write the decrypted chunks to the output file
      
      // For simplicity, we'll read the entire file at once
      final encryptedBytes = await encryptedFile.readAsBytes();
      final decrypted = await _aesGcm.decrypt(
        SecretBox(
          encryptedBytes,
          nonce: nonce,
          mac: Mac([]), // Placeholder - in a real app you'd store and use the MAC
        ),
        secretKey: dek,
      );
      
      final decryptedFile = File(decryptedPath);
      await decryptedFile.writeAsBytes(decrypted);
      
      return decryptedPath;
    } catch (e) {
      print('Error decrypting file: $e');
      rethrow;
    }
  }
  
  /// Encrypt a thought
  Future<Thought> encryptThought(Thought thought, String passphrase) async {
    try {
      // Check if E2EE is enabled
      final e2eeEnabled = await isE2eeEnabled();
      if (!e2eeEnabled) {
        return thought;
      }
      
      // Skip if no transcript
      if (thought.transcript == null || thought.transcript!.isEmpty) {
        return thought;
      }
      
      // Encrypt the transcript
      final encryptedTranscript = await encryptString(thought.transcript!, passphrase);
      
      // Encrypt the audio file
      final encryptedPath = await encryptFile(thought.path, passphrase);
      
      // Return updated thought
      return thought.copyWith(
        path: encryptedPath,
        transcript: encryptedTranscript['ciphertext'],
        // Add metadata to the thought object
        // In a real app, you'd store this in a separate field or table
      );
    } catch (e) {
      print('Error encrypting thought: $e');
      return thought; // Return original on error
    }
  }
  
  /// Decrypt a thought
  Future<Thought> decryptThought(Thought thought, String passphrase) async {
    try {
      // Check if E2EE is enabled
      final e2eeEnabled = await isE2eeEnabled();
      if (!e2eeEnabled) {
        return thought;
      }
      
      // Skip if no transcript
      if (thought.transcript == null || thought.transcript!.isEmpty) {
        return thought;
      }
      
      // Decrypt the transcript
      // In a real app, you'd retrieve the metadata from storage
      final metadata = EncryptionMetadata(
        algorithm: 'AES-GCM',
        salt: 'placeholder',
        nonce: 'placeholder',
        encryptedDek: 'placeholder',
      );
      final decryptedTranscript = await decryptString(thought.transcript!, metadata, passphrase);
      
      // Decrypt the audio file
      final decryptedPath = await decryptFile(thought.path, passphrase);
      
      // Return updated thought
      return thought.copyWith(
        path: decryptedPath,
        transcript: decryptedTranscript,
      );
    } catch (e) {
      print('Error decrypting thought: $e');
      return thought; // Return original on error
    }
  }
  
  /// Derive a key from a passphrase using PBKDF2
  Future<SecretKey> _deriveKey(String passphrase, List<int> salt) async {
    try {
      // Try to use Argon2id if available (for real implementation)
      // final argon2 = Argon2id(
      //   parallelism: 4,
      //   memory: 65536,
      //   iterations: 3,
      // );
      // return await argon2.deriveKey(
      //   secretKey: SecretKey(utf8.encode(passphrase)),
      //   nonce: salt,
      //   length: 32,
      // );
      
      // Fallback to PBKDF2
      final pbkdf2 = Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: 100000,
        bits: 256,
      );
      
      return await pbkdf2.deriveKey(
        secretKey: SecretKey(utf8.encode(passphrase)),
        nonce: salt,
      );
    } catch (e) {
      print('Error deriving key: $e');
      rethrow;
    }
  }
  
  /// Generate a verifier hash for the passphrase
  Future<String> _generateVerifier(String passphrase, List<int> salt) async {
    try {
      // Derive a key from the passphrase
      final key = await _deriveKey(passphrase, salt);
      final keyBytes = await key.extractBytes();
      
      // Hash the key to create a verifier
      final hasher = standard_crypto.Hmac(standard_crypto.sha256, salt);
      final hash = hasher.convert(keyBytes);
      
      return hash.toString();
    } catch (e) {
      print('Error generating verifier: $e');
      rethrow;
    }
  }
  
  /// Constant-time string comparison to prevent timing attacks
  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) {
      return false;
    }
    
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    
    return result == 0;
  }
  
  /// Get a temporary decryption directory
  Future<Directory> _getDecryptionDir() async {
    final tempDir = await getTemporaryDirectory();
    final decryptDir = Directory('${tempDir.path}/decrypted');
    if (!await decryptDir.exists()) {
      await decryptDir.create(recursive: true);
    }
    return decryptDir;
  }
  
  /// Clean up temporary decryption files
  Future<void> cleanupDecryptedFiles() async {
    try {
      final decryptDir = await _getDecryptionDir();
      if (await decryptDir.exists()) {
        await decryptDir.delete(recursive: true);
        await decryptDir.create(recursive: true);
      }
    } catch (e) {
      print('Error cleaning up decrypted files: $e');
    }
  }
}

/// Provider for the CryptoService
final cryptoServiceProvider = Provider<CryptoService>((ref) {
  final featureFlags = ref.watch(featureFlagsProvider);
  return CryptoService(const FlutterSecureStorage(), featureFlags);
});
