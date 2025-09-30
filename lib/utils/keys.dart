import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Keys {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _openAiKeyKey = 'OPENAI_API_KEY';
  
  /// Get OpenAI API key from the most secure source available
  /// Order of precedence:
  /// 1. Secure storage (for mobile)
  /// 2. .env file
  /// 3. Platform environment (desktop only)
  static Future<String?> get openaiApiKey async {
    // Try secure storage first (best for mobile)
    try {
      final secureKey = await _secureStorage.read(key: _openAiKeyKey);
      if (secureKey != null && secureKey.isNotEmpty) {
        return secureKey.trim();
      }
    } catch (e) {
      // Secure storage might not be available on all platforms
    }
    
    // Try .env file
    final envKey = dotenv.env['OPENAI_API_KEY'];
    if (envKey != null && envKey.isNotEmpty) {
      return envKey.trim();
    }
    
    // Fallback to platform environment (desktop only)
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final platformKey = Platform.environment['OPENAI_API_KEY'];
      if (platformKey != null && platformKey.isNotEmpty) {
        return platformKey.trim();
      }
    }
    
    return null;
  }
  
  /// Save OpenAI API key to secure storage
  static Future<void> saveOpenaiApiKey(String key) async {
    await _secureStorage.write(key: _openAiKeyKey, value: key.trim());
  }
  
  /// Delete OpenAI API key from secure storage
  static Future<void> deleteOpenaiApiKey() async {
    await _secureStorage.delete(key: _openAiKeyKey);
  }
  
  /// Check if OpenAI API key is configured
  static Future<bool> get hasOpenaiApiKey async {
    final key = await openaiApiKey;
    return key != null && key.isNotEmpty;
  }
}