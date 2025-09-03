import 'package:flutter_test/flutter_test.dart';
import 'package:hold_that_thought/services/crypto_service.dart';
import 'package:hold_that_thought/services/feature_flags.dart';

// Fake secure storage implementation for testing
class FakeSecureStorage {
  final Map<String, String> _storage = {};

  Future<String?> read({required String key}) async {
    return _storage[key];
  }

  Future<void> write({required String key, required String value}) async {
    _storage[key] = value;
  }

  Future<void> delete({required String key}) async {
    _storage.remove(key);
  }
}

// Fake feature flags implementation for testing
class FakeFeatureFlags implements FeatureFlags {
  bool _e2eeEnabled = false;
  bool _ragEnabled = false;
  bool _authEnabled = false;
  bool _telemetryEnabled = false;

  @override
  Future<bool> getAuthEnabled() async {
    return _authEnabled;
  }

  @override
  Future<void> setAuthEnabled(bool value) async {
    _authEnabled = value;
  }

  @override
  Future<bool> getE2eeEnabled() async {
    return _e2eeEnabled;
  }

  @override
  Future<void> setE2eeEnabled(bool value) async {
    _e2eeEnabled = value;
  }

  @override
  Future<bool> getRagEnabled() async {
    return _ragEnabled;
  }

  @override
  Future<void> setRagEnabled(bool value) async {
    _ragEnabled = value;
  }

  @override
  Future<bool> getTelemetryEnabled() async {
    return _telemetryEnabled;
  }

  @override
  Future<void> setTelemetryEnabled(bool value) async {
    _telemetryEnabled = value;
  }
}

void main() {
  late FakeSecureStorage secureStorage;
  late FakeFeatureFlags featureFlags;
  late CryptoService cryptoService;
  final testPassphrase = 'test_passphrase';

  setUp(() {
    secureStorage = FakeSecureStorage();
    featureFlags = FakeFeatureFlags();
    cryptoService = CryptoService(secureStorage as dynamic, featureFlags);
  });

  group('CryptoService Basics', () {
    test('isEncryptionSetUp returns false when not set up', () async {
      final result = await cryptoService.isEncryptionSetUp;
      expect(result, false);
    });

    test('isE2eeEnabled returns feature flag value', () async {
      await featureFlags.setE2eeEnabled(true);
      final result = await cryptoService.isE2eeEnabled();
      expect(result, true);
    });

    test('setupE2ee sets up encryption', () async {
      final result = await cryptoService.setupE2ee(testPassphrase);
      expect(result, true);

      // Check if values were stored
      final salt = await secureStorage.read(key: 'e2ee.salt');
      final verifier = await secureStorage.read(key: 'e2ee.verifier');

      expect(salt, isNotNull);
      expect(verifier, isNotNull);

      // Check if feature flag was enabled
      final isEnabled = await featureFlags.getE2eeEnabled();
      expect(isEnabled, true);
    });

    test('isEncryptionSetUp returns true after setup', () async {
      await cryptoService.setupE2ee(testPassphrase);
      final result = await cryptoService.isEncryptionSetUp;
      expect(result, true);
    });

    test('unlock works with correct passphrase', () async {
      // First set up encryption
      await cryptoService.setupE2ee(testPassphrase);

      // Forget key to simulate app restart
      await cryptoService.forgetKey();
      expect(cryptoService.isArmed, false);

      // Unlock with correct passphrase
      final result = await cryptoService.unlock(testPassphrase);
      expect(result, true);
      expect(cryptoService.isArmed, true);
    });

    test('unlock fails with incorrect passphrase', () async {
      // First set up encryption
      await cryptoService.setupE2ee(testPassphrase);

      // Forget key to simulate app restart
      await cryptoService.forgetKey();

      // Try to unlock with wrong passphrase
      final result = await cryptoService.unlock('wrong_passphrase');
      expect(result, false);
      expect(cryptoService.isArmed, false);
    });
  });
}
