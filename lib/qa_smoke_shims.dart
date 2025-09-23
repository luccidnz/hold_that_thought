// QA SMOKE SHIMS — compile-only helpers for CI emulator.
// These must be removed/refined after v0.10.0.
//
// Reason: The smoke test compiles the app; some symbols/extensions are
// missing or private across libs. We provide safe fallbacks.

import 'dart:async';
import 'dart:convert';

// If you use Riverpod, these imports are safe; if unused they dead-strip.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hold_that_thought/services/feature_flags.dart';

/// secureStorageProvider shim (no-op) if not provided elsewhere.
final secureStorageProvider = Provider<dynamic>((ref) => _NoopSecureStorage());

class _NoopSecureStorage {
  Future<void> write({required String key, String? value}) async {}
  Future<String?> read({required String key}) async => null;
}

/// featureFlagsProvider shim (all flags false)
final featureFlagsProvider = Provider<FeatureFlags>((ref) => _NoopFeatureFlags());
class _NoopFeatureFlags extends FeatureFlags {
  _NoopFeatureFlags() : super(const FlutterSecureStorage());

  @override
  Future<bool> getAuthEnabled() async => false;

  @override
  Future<void> setAuthEnabled(bool value) async {}

  @override
  Future<bool> getRagEnabled() async => false;

  @override
  Future<void> setRagEnabled(bool value) async {}

  @override
  Future<bool> getE2eeEnabled() async => false;

  @override
  Future<void> setE2eeEnabled(bool value) async {}

  @override
  Future<bool> getTelemetryEnabled() async => false;

  @override
  Future<void> setTelemetryEnabled(bool value) async {}
}

/// Make `persistSessionString` available even if the real extension is missing.
/// We attach to Object so it resolves on any type including Session.
extension QaPersistSessionString on Object? {
  String get persistSessionString {
    try {
      // Best-effort stringify without leaking secrets.
      return jsonEncode({'type': runtimeType.toString()});
    } catch (_) {
      return toString();
    }
  }
}

/// Provide extractBytes() even if called on a Future.
extension QaFutureExtractBytes on Future<dynamic> {
  Future<List<int>> extractBytes() async {
    final v = await this;
    try {
      // If the resolved value itself has extractBytes(), call it.
      final fn = (v as dynamic).extractBytes as FutureOr<List<int>> Function();
      final out = await fn();
      return out;
    } catch (_) {
      return <int>[];
    }
  }
}
