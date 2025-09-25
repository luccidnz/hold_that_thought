import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/services/crypto_service.dart' hide cryptoServiceProvider;
import 'package:hold_that_thought/services/feature_flags.dart' hide featureFlagsProvider;
import 'package:hold_that_thought/state/providers.dart';

/// A widget that displays privacy settings including End-to-End Encryption options.
/// This is part of the E2EE feature in Phase 10.
class PrivacySection extends ConsumerStatefulWidget {
  const PrivacySection({Key? key}) : super(key: key);

  @override
  _PrivacySectionState createState() => _PrivacySectionState();
}

class _PrivacySectionState extends ConsumerState<PrivacySection> {
  final _passphraseController = TextEditingController();
  final _confirmPassphraseController = TextEditingController();
  bool _obscurePassphrase = true;
  bool _isChangingPassphrase = false;
  String? _passphraseError;

  @override
  void dispose() {
    _passphraseController.dispose();
    _confirmPassphraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e2eeEnabledAsync = ref.watch(e2eeEnabledProvider);
    
    return e2eeEnabledAsync.when(
      data: (e2eeEnabled) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Privacy & Security',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildE2EEToggle(e2eeEnabled),
            if (e2eeEnabled) ...[
              const SizedBox(height: 16),
              _buildEncryptionStatus(),
              const SizedBox(height: 16),
              if (_isChangingPassphrase)
                _buildChangePassphraseForm()
              else
                _buildChangePassphraseButton(),
            ],
            const SizedBox(height: 24),
            _buildPrivacyInfo(e2eeEnabled),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('Error loading privacy settings'),
    );
  }

  Widget _buildE2EEToggle(bool isEnabled) {
    return SwitchListTile(
      title: const Text('End-to-End Encryption'),
      subtitle: const Text(
        'Encrypt your thoughts for maximum privacy. '
        'Note: Requires setting a passphrase.',
      ),
      value: isEnabled,
      onChanged: (value) async {
        if (value) {
          // Enabling E2EE
          _showEnableE2EEDialog();
        } else {
          // Disabling E2EE
          _showDisableE2EEDialog();
        }
      },
    );
  }

  Widget _buildEncryptionStatus() {
    final cryptoService = ref.watch(cryptoServiceProvider);
    final isSetUp = cryptoService.isEncryptionSetUp;
    
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              isSetUp ? Icons.lock : Icons.lock_open,
              color: isSetUp 
                  ? Theme.of(context).colorScheme.primary 
                  : Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSetUp ? 'Encryption is set up' : 'Encryption not set up',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSetUp 
                        ? 'Your data is protected with your passphrase.'
                        : 'Set a passphrase to enable encryption.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangePassphraseButton() {
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _isChangingPassphrase = true;
          _passphraseController.clear();
          _confirmPassphraseController.clear();
          _passphraseError = null;
        });
      },
      child: const Text('Change Passphrase'),
    );
  }

  Widget _buildChangePassphraseForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _passphraseController,
          decoration: InputDecoration(
            labelText: 'New Passphrase',
            errorText: _passphraseError,
            suffixIcon: IconButton(
              icon: Icon(_obscurePassphrase ? Icons.visibility : Icons.visibility_off),
              onPressed: () {
                setState(() {
                  _obscurePassphrase = !_obscurePassphrase;
                });
              },
            ),
          ),
          obscureText: _obscurePassphrase,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPassphraseController,
          decoration: const InputDecoration(
            labelText: 'Confirm Passphrase',
          ),
          obscureText: _obscurePassphrase,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _isChangingPassphrase = false;
                  _passphraseError = null;
                });
              },
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _savePassphrase,
              child: const Text('Save Passphrase'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrivacyInfo(bool e2eeEnabled) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About End-to-End Encryption',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'When enabled, your thoughts are encrypted using AES-GCM-256 before being stored '
              'locally or in the cloud. Only you can decrypt your data with your passphrase.\n\n'
              'Important: If you forget your passphrase, your data cannot be recovered. '
              'There is no "back door" or recovery mechanism.',
            ),
            if (e2eeEnabled) ...[
              const SizedBox(height: 16),
              const Text(
                '✓ Local data is encrypted\n'
                '✓ Cloud backups are encrypted\n'
                '✓ Only you have the key',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEnableE2EEDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Encryption'),
        content: const Text(
          'End-to-End Encryption protects your data with a passphrase only you know. '
          'You will need to set a strong passphrase that you will not forget.\n\n'
          'IMPORTANT: If you forget your passphrase, your data CANNOT be recovered.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isChangingPassphrase = true;
                _passphraseController.clear();
                _confirmPassphraseController.clear();
                _passphraseError = null;
              });
              ref.read(featureFlagsProvider.notifier).setE2EEEnabled(true);
            },
            child: const Text('Set Passphrase'),
          ),
        ],
      ),
    );
  }

  void _showDisableE2EEDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable Encryption'),
        content: const Text(
          'Disabling encryption will decrypt your existing data. '
          'New data will no longer be encrypted.\n\n'
          'This will make your data vulnerable if your device or cloud account is compromised.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.pop(context);
              final cryptoService = ref.read(cryptoServiceProvider);
              
              // Show a passphrase dialog to confirm the user knows the passphrase
              final result = await _promptForCurrentPassphrase();
              if (result == true) {
                // Decrypt all data
                await cryptoService.decryptAllData();
                // Disable E2EE
                ref.read(featureFlagsProvider.notifier).setE2EEEnabled(false);
              }
            },
            child: const Text('Disable Encryption'),
          ),
        ],
      ),
    );
  }

  Future<bool> _promptForCurrentPassphrase() async {
    final passphraseController = TextEditingController();
    bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Passphrase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your current passphrase to decrypt your data:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passphraseController,
              decoration: const InputDecoration(
                labelText: 'Current Passphrase',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final cryptoService = ref.read(cryptoServiceProvider);
              final isValid = await cryptoService.validatePassphrase(passphraseController.text);
              if (isValid) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Incorrect passphrase'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    
    passphraseController.dispose();
    return result ?? false;
  }

  Future<void> _savePassphrase() async {
    final passphrase = _passphraseController.text;
    final confirmPassphrase = _confirmPassphraseController.text;
    
    // Validate passphrase
    if (passphrase.isEmpty) {
      setState(() {
        _passphraseError = 'Passphrase cannot be empty';
      });
      return;
    }
    
    if (passphrase.length < 8) {
      setState(() {
        _passphraseError = 'Passphrase must be at least 8 characters';
      });
      return;
    }
    
    if (passphrase != confirmPassphrase) {
      setState(() {
        _passphraseError = 'Passphrases do not match';
      });
      return;
    }
    
    setState(() {
      _passphraseError = null;
    });
    
    // Save the passphrase and set up encryption
    final cryptoService = ref.read(cryptoServiceProvider);
    final success = await cryptoService.setupEncryption(passphrase);
    
    if (success) {
      setState(() {
        _isChangingPassphrase = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passphrase saved. Your data is now encrypted.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to set up encryption. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
