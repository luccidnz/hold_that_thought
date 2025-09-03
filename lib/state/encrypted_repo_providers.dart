import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/models/thought.dart';
import 'package:hold_that_thought/services/crypto_service.dart' hide cryptoServiceProvider;
import 'package:hold_that_thought/services/feature_flags.dart' hide featureFlagsProvider;
import 'package:hold_that_thought/services/repository/encrypted_thought_repository.dart';
import 'package:hold_that_thought/state/providers.dart';
import 'package:hold_that_thought/state/repository_providers.dart';

/// Provider for the encrypted thought repository
final encryptedThoughtRepositoryProvider = Provider<EncryptedThoughtRepository>((ref) {
  final repository = ref.watch(thoughtRepositoryProvider);
  final cryptoService = ref.watch(cryptoServiceProvider);
  final featureFlags = ref.watch(featureFlagsProvider);

  return EncryptedThoughtRepository(repository, cryptoService, featureFlags);
});

/// Live list of thoughts with decryption applied where needed
final encryptedThoughtsListProvider = FutureProvider<List<Thought>>((ref) async {
  final repo = ref.read(encryptedThoughtRepositoryProvider);
  return repo.getAll();
});

/// Indicator for UI to show if a thought is encrypted
final isThoughtEncryptedProvider = Provider.family<bool, Thought>((ref, thought) {
  return thought.isEncrypted;
});

/// Provides an "encrypted" badge for UI when needed
final encryptionBadgeProvider = Provider.family<String?, Thought>((ref, thought) {
  final isEncrypted = ref.watch(isThoughtEncryptedProvider(thought));
  final cryptoService = ref.watch(cryptoServiceProvider);

  if (isEncrypted) {
    if (cryptoService.isArmed) {
      return "Encrypted (Unlocked)";
    } else {
      return "Encrypted (Locked)";
    }
  }

  return null;
});
