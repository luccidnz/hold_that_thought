import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hold_that_thought/audio/audio_engine.dart';

void main() {
  group('AudioEngine', () {
    late AudioEngine engine;

    setUp(() {
      engine = AudioEngine();
    });

    test('addPcmData adds data to buffer', () {
      final data = Uint8List.fromList([1, 2, 3, 4]);
      engine.addPcmData(data);
      expect(engine.getPreRollData(), equals(data));
    });

    test('addPcmData handles buffer wrap-around', () {
      final firstChunk = Uint8List(engine.bufferSize - 50);
      engine.addPcmData(firstChunk);
      final secondChunk = Uint8List(100);
      engine.addPcmData(secondChunk);

      expect(engine.writeIndex, 50);
      expect(engine.bufferFilled, isTrue);
    });

    test('getPreRollData returns correct data before buffer is full', () {
      final data = Uint8List.fromList([1, 2, 3, 4]);
      engine.addPcmData(data);
      expect(engine.getPreRollData(), equals(data));
    });

    test('getPreRollData returns correct data after buffer is full', () {
      final fullBuffer = Uint8List(engine.bufferSize);
      for (var i = 0; i < engine.bufferSize; i++) {
        fullBuffer[i] = i % 256;
      }
      engine.addPcmData(fullBuffer);
      final extraData = Uint8List.fromList([10, 20, 30, 40]);
      engine.addPcmData(extraData);

      final preRoll = engine.getPreRollData();
      expect(preRoll.length, engine.bufferSize);
      // The end of the pre-roll should be the extra data we added.
      expect(preRoll.sublist(preRoll.length - 4), equals(extraData));
    });

    test('buildWavBytesWithPreRoll creates valid WAV header', () async {
      final livePcm = Uint8List.fromList([1, 2, 3, 4]);
      final wavBytes = await engine.buildWavBytesWithPreRoll(livePcm);

      // Check for RIFF header
      expect(wavBytes.sublist(0, 4),
          equals(Uint8List.fromList([0x52, 0x49, 0x46, 0x46])));
      // Check for WAVE format
      expect(wavBytes.sublist(8, 12),
          equals(Uint8List.fromList([0x57, 0x41, 0x56, 0x45])));
      // Check for 'fmt ' chunk
      expect(wavBytes.sublist(12, 16),
          equals(Uint8List.fromList([0x66, 0x6d, 0x74, 0x20])));
      // Check for 'data' chunk
      expect(wavBytes.sublist(36, 40),
          equals(Uint8List.fromList([0x64, 0x61, 0x74, 0x61])));
    });
  });
}
