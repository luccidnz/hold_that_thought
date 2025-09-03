import 'package:flutter_test/flutter_test.dart';
import 'package:hold_that_thought/utils/log_redactor.dart';

void main() {
  group('LogRedactor', () {
    test('redacts email addresses', () {
      final input = 'Email address is user@example.com for testing';
      final redacted = LogRedactor.redact(input);
      expect(redacted, 'Email address is [REDACTED_EMAIL] for testing');
    });

    test('redacts audio file paths', () {
      final input = 'Audio file at /path/to/recording.m4a and another at C:\\files\\audio.wav';
      final redacted = LogRedactor.redact(input);
      expect(redacted.contains('[REDACTED_AUDIO_PATH]'), true);
      expect(redacted.contains('recording.m4a'), false);
      expect(redacted.contains('audio.wav'), false);
    });

    test('redacts passphrases', () {
      final input = 'passphrase: "secret123";';
      final redacted = LogRedactor.redact(input);
      expect(redacted.contains('[REDACTED_PASSPHRASE]'), true);
      expect(redacted.contains('secret123'), false);
    });

    test('redacts transcripts', () {
      final input = 'transcript: "This is a very long transcript that should be redacted";';
      final redacted = LogRedactor.redact(input);
      expect(redacted.contains('[REDACTED_TRANSCRIPT]'), true);
      expect(redacted.contains('This is a very long transcript'), false);
    });

    test('redactPath handles audio files', () {
      expect(LogRedactor.redactPath('/path/to/file.m4a'), '[REDACTED_AUDIO_PATH]');
      expect(LogRedactor.redactPath('/path/to/file.wav'), '[REDACTED_AUDIO_PATH]');
      expect(LogRedactor.redactPath('/path/to/file.mp3'), '[REDACTED_AUDIO_PATH]');
      expect(LogRedactor.redactPath('/path/to/file.enc'), '[REDACTED_AUDIO_PATH]');
      expect(LogRedactor.redactPath('/path/to/file.txt'), '/path/to/file.txt');
    });

    test('redactTranscript handles various transcript lengths', () {
      expect(LogRedactor.redactTranscript(null), '[NO_TRANSCRIPT]');
      expect(LogRedactor.redactTranscript(''), '[NO_TRANSCRIPT]');
      expect(LogRedactor.redactTranscript('Short'), 'Short');
      expect(
        LogRedactor.redactTranscript('This is a very long transcript that should be redacted'),
        '[REDACTED_TRANSCRIPT]'
      );
    });
  });
}
