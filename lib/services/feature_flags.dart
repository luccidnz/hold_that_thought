import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service to manage feature flags for the app
class FeatureFlags {
  static const String _authEnabledKey = 'feature.authEnabled';
  static const String _ragEnabledKey = 'feature.ragEnabled';
  static const String _e2eeEnabledKey = 'feature.e2eeEnabled';
  static const String _telemetryEnabledKey = 'feature.telemetryEnabled';

  final FlutterSecureStorage _storage;

  FeatureFlags(this._storage);

  Future<bool> getAuthEnabled() async {
    final value = await _storage.read(key: _authEnabledKey);
    return value == 'true';
  }

  Future<void> setAuthEnabled(bool value) async {
    await _storage.write(key: _authEnabledKey, value: value.toString());
  }

  Future<bool> getRagEnabled() async {
    final value = await _storage.read(key: _ragEnabledKey);
    return value == 'true';
  }

  Future<void> setRagEnabled(bool value) async {
    await _storage.write(key: _ragEnabledKey, value: value.toString());
  }

  Future<bool> getE2eeEnabled() async {
    final value = await _storage.read(key: _e2eeEnabledKey);
    return value == 'true';
  }

  Future<void> setE2eeEnabled(bool value) async {
    await _storage.write(key: _e2eeEnabledKey, value: value.toString());
  }

  Future<bool> getTelemetryEnabled() async {
    final value = await _storage.read(key: _telemetryEnabledKey);
    return value == 'true';
  }

  Future<void> setTelemetryEnabled(bool value) async {
    await _storage.write(key: _telemetryEnabledKey, value: value.toString());
  }
}

/// Provider for the FeatureFlags service
final featureFlagsProvider = Provider<FeatureFlags>((ref) {
  return FeatureFlags(const FlutterSecureStorage());
});

/// Feature flag providers that can be consumed across the app
final authEnabledProvider = FutureProvider<bool>((ref) async {
  final featureFlags = ref.watch(featureFlagsProvider);
  return await featureFlags.getAuthEnabled();
});

final ragEnabledProvider = FutureProvider<bool>((ref) async {
  final featureFlags = ref.watch(featureFlagsProvider);
  return await featureFlags.getRagEnabled();
});

final e2eeEnabledProvider = FutureProvider<bool>((ref) async {
  final featureFlags = ref.watch(featureFlagsProvider);
  return await featureFlags.getE2eeEnabled();
});

final telemetryEnabledProvider = FutureProvider<bool>((ref) async {
  final featureFlags = ref.watch(featureFlagsProvider);
  return await featureFlags.getTelemetryEnabled();
});
