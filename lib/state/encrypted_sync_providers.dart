import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/services/encrypted_sync_service.dart';
import 'package:hold_that_thought/state/encrypted_repo_providers.dart';
import 'package:hold_that_thought/state/providers.dart';
import 'package:hold_that_thought/state/sync_providers.dart';

/// Provider for the encrypted sync service
final encryptedSyncServiceProvider = Provider<EncryptedSyncService>((ref) {
  final syncProv = ref.watch(syncProvider);
  final repo = ref.watch(encryptedThoughtRepositoryProvider);
  final cryptoService = ref.watch(cryptoServiceProvider);
  final featureFlags = ref.watch(featureFlagsProvider);
  
  final service = EncryptedSyncService(
    provider: syncProv,
    repository: repo,
    cryptoService: cryptoService,
    featureFlags: featureFlags,
    ref: ref,
  );
  
  // Initialize the service
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});
