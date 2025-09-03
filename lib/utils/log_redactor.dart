/// Utility class for redacting sensitive information from logs
class LogRedactor {
  static final RegExp _emailPattern = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
  static final RegExp _pathPattern = RegExp(r'(\/|\\)[^\/\\]*\.(m4a|wav|mp3|enc)');

  /// Redacts sensitive information from a string for logging
  static String redact(String input) {
    String result = input;

    // Redact email addresses
    result = result.replaceAllMapped(_emailPattern, (match) => '[REDACTED_EMAIL]');

    // Redact file paths with audio extensions
    result = result.replaceAllMapped(_pathPattern, (match) => '[REDACTED_AUDIO_PATH]');

    // Simple string-based redaction for passphrases
    if (result.contains('passphrase')) {
      result = result.replaceAll(RegExp(r'passphrase.*?[;,]'), 'passphrase: "[REDACTED_PASSPHRASE]";');
    }

    // Simple string-based redaction for transcripts
    if (result.contains('transcript')) {
      result = result.replaceAll(RegExp(r'transcript.*?[;,]'), 'transcript: "[REDACTED_TRANSCRIPT]";');
    }

    return result;
  }

  /// Redact file paths for sensitive audio files
  static String redactPath(String path) {
    if (path.endsWith('.m4a') || path.endsWith('.wav') ||
        path.endsWith('.mp3') || path.endsWith('.enc')) {
      return '[REDACTED_AUDIO_PATH]';
    }
    return path;
  }

  /// Redact transcript content
  static String redactTranscript(String? transcript) {
    if (transcript == null || transcript.isEmpty) {
      return '[NO_TRANSCRIPT]';
    }
    if (transcript.length <= 20) {
      return transcript;
    }
    return '[REDACTED_TRANSCRIPT]';
  }
}
