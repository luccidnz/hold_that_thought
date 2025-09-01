import 'dart:convert';

/// Contains all the metadata needed for encrypting/decrypting a thought
class ThoughtEncryptionMetadata {
  final String algorithm; // e.g., 'AES-GCM'
  final String salt; // Base64 encoded
  final String nonce; // Base64 encoded
  final String encryptedDek; // Base64 encoded, Data Encryption Key wrapped by KEK
  
  const ThoughtEncryptionMetadata({
    required this.algorithm,
    required this.salt,
    required this.nonce,
    required this.encryptedDek,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'algorithm': algorithm,
      'salt': salt,
      'nonce': nonce,
      'encryptedDek': encryptedDek,
    };
  }
  
  factory ThoughtEncryptionMetadata.fromJson(Map<String, dynamic> json) {
    return ThoughtEncryptionMetadata(
      algorithm: json['algorithm'] as String,
      salt: json['salt'] as String,
      nonce: json['nonce'] as String,
      encryptedDek: json['encryptedDek'] as String,
    );
  }
  
  String toJsonString() => jsonEncode(toJson());
  
  factory ThoughtEncryptionMetadata.fromJsonString(String jsonString) {
    return ThoughtEncryptionMetadata.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>
    );
  }
}
