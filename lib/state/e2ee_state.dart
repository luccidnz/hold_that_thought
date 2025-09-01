import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/services/crypto_service.dart' hide cryptoServiceProvider;
import 'package:hold_that_thought/services/feature_flags.dart' hide featureFlagsProvider;
import 'package:hold_that_thought/services/service_locator.dart';

/// State class for E2EE encryption status
class E2EEState {
  final bool isE2EEEnabled;
  final bool isE2EESetUp;
  final bool isUnlocked;
  final String? error;
  
  const E2EEState({
    this.isE2EEEnabled = false,
    this.isE2EESetUp = false,
    this.isUnlocked = false,
    this.error,
  });
  
  E2EEState copyWith({
    bool? isE2EEEnabled,
    bool? isE2EESetUp,
    bool? isUnlocked,
    String? error,
    bool clearError = false,
  }) {
    return E2EEState(
      isE2EEEnabled: isE2EEEnabled ?? this.isE2EEEnabled,
      isE2EESetUp: isE2EESetUp ?? this.isE2EESetUp,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// StateNotifier for E2EE state management
class E2EEStateNotifier extends StateNotifier<E2EEState> {
  final CryptoService _cryptoService;
  final FeatureFlags _featureFlags;
  
  E2EEStateNotifier(this._cryptoService, this._featureFlags) : super(const E2EEState()) {
    _loadState();
  }
  
  /// Load the initial state
  Future<void> _loadState() async {
    try {
      final isE2EEEnabled = await _featureFlags.getE2eeEnabled();
      final isE2EESetUp = await _cryptoService.isEncryptionSetUp;
      final isUnlocked = _cryptoService.isArmed;
      
      state = state.copyWith(
        isE2EEEnabled: isE2EEEnabled,
        isE2EESetUp: isE2EESetUp,
        isUnlocked: isUnlocked,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load E2EE state: $e',
      );
    }
  }
  
  /// Set up E2EE with a passphrase
  Future<bool> setupE2EE(String passphrase) async {
    try {
      final success = await _cryptoService.setPassphrase(passphrase);
      if (success) {
        await _featureFlags.setE2eeEnabled(true);
        state = state.copyWith(
          isE2EEEnabled: true,
          isE2EESetUp: true,
          isUnlocked: true,
          clearError: true,
        );
        return true;
      } else {
        state = state.copyWith(
          error: 'Failed to set up E2EE',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Error setting up E2EE: $e',
      );
      return false;
    }
  }
  
  /// Change the passphrase
  Future<bool> changePassphrase(String oldPassphrase, String newPassphrase) async {
    try {
      final success = await _cryptoService.changePassphrase(oldPassphrase, newPassphrase);
      if (success) {
        state = state.copyWith(
          clearError: true,
        );
        return true;
      } else {
        state = state.copyWith(
          error: 'Failed to change passphrase',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Error changing passphrase: $e',
      );
      return false;
    }
  }
  
  /// Unlock E2EE with a passphrase
  Future<bool> unlock(String passphrase) async {
    try {
      final success = await _cryptoService.unlock(passphrase);
      if (success) {
        state = state.copyWith(
          isUnlocked: true,
          clearError: true,
        );
        return true;
      } else {
        state = state.copyWith(
          error: 'Invalid passphrase',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Error unlocking E2EE: $e',
      );
      return false;
    }
  }
  
  /// Lock E2EE (forget the key)
  Future<void> lock() async {
    await _cryptoService.forgetKey();
    state = state.copyWith(
      isUnlocked: false,
      clearError: true,
    );
  }
  
  /// Disable E2EE
  Future<bool> disableE2EE() async {
    try {
      // This should decrypt all data
      final success = await _cryptoService.decryptAllData();
      if (success) {
        await _featureFlags.setE2eeEnabled(false);
        state = state.copyWith(
          isE2EEEnabled: false,
          isUnlocked: false,
          clearError: true,
        );
        return true;
      } else {
        state = state.copyWith(
          error: 'Failed to disable E2EE',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Error disabling E2EE: $e',
      );
      return false;
    }
  }
  
  /// Clear any error messages
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider for E2EE state
final e2eeStateProvider = StateNotifierProvider<E2EEStateNotifier, E2EEState>((ref) {
  final cryptoService = ref.watch(cryptoServiceProvider);
  final featureFlags = ref.watch(featureFlagsProvider);
  return E2EEStateNotifier(cryptoService, featureFlags);
});
