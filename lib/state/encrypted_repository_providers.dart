import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/services/crypto_service.dart';
import 'package:hold_that_thought/services/feature_flags.dart';
import 'package:hold_that_thought/services/repository/encrypted_thought_repository.dart';
import 'package:hold_that_thought/services/repository/thought_repository.dart';
import 'package:hold_that_thought/state/repository_providers.dart';
import 'package:hold_that_thought/state/security_providers.dart';

/// Provider for the encrypted thought repository
final encryptedThoughtRepositoryProvider = Provider<EncryptedThoughtRepository>((ref) {
  final repository = ref.watch(thoughtRepositoryProvider);
  final cryptoService = ref.watch(cryptoServiceProvider);
  final featureFlags = ref.watch(featureFlagsProvider);
  
  return EncryptedThoughtRepository(repository, cryptoService, featureFlags);
});
