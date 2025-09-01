import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/state/e2ee_state.dart';

class E2EESetupPage extends ConsumerStatefulWidget {
  const E2EESetupPage({Key? key}) : super(key: key);

  @override
  ConsumerState<E2EESetupPage> createState() => _E2EESetupPageState();
}

class _E2EESetupPageState extends ConsumerState<E2EESetupPage> {
  final _passphraseController = TextEditingController();
  final _confirmPassphraseController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassphrase = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passphraseController.dispose();
    _confirmPassphraseController.dispose();
    super.dispose();
  }

  Future<void> _setupE2EE() async {
    if (!_formKey.currentState!.validate()) return;

    final passphrase = _passphraseController.text;
    
    setState(() {
      _isLoading = true;
    });
    
    final success = await ref.read(e2eeStateProvider.notifier).setupE2EE(passphrase);
    
    setState(() {
      _isLoading = false;
    });
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End-to-end encryption set up successfully')),
      );
      
      _passphraseController.clear();
      _confirmPassphraseController.clear();
    } else {
      final error = ref.read(e2eeStateProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to set up E2EE: ${error ?? "Unknown error"}')),
      );
    }
  }
  
  Future<void> _unlockE2EE() async {
    if (_passphraseController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your passphrase')),
      );
      return;
    }
    
    final passphrase = _passphraseController.text;
    
    setState(() {
      _isLoading = true;
    });
    
    final success = await ref.read(e2eeStateProvider.notifier).unlock(passphrase);
    
    setState(() {
      _isLoading = false;
    });
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Encryption unlocked successfully')),
      );
      
      _passphraseController.clear();
    } else {
      final error = ref.read(e2eeStateProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unlock: ${error ?? "Invalid passphrase"}')),
      );
    }
  }
  
  Future<void> _disableE2EE() async {
    if (_passphraseController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your passphrase to disable encryption')),
      );
      return;
    }
    
    // First unlock with passphrase to make sure it's valid
    final passphrase = _passphraseController.text;
    
    setState(() {
      _isLoading = true;
    });
    
    final unlocked = await ref.read(e2eeStateProvider.notifier).unlock(passphrase);
    
    if (!unlocked) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid passphrase')),
      );
      return;
    }
    
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable Encryption?'),
        content: const Text(
          'This will decrypt all your data. The data will remain private in your device storage, '
          'but will no longer be protected with your passphrase. '
          'This cannot be undone and may take some time to complete.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Disable'),
          ),
        ],
      ),
    );
    
    if (confirm != true) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    final success = await ref.read(e2eeStateProvider.notifier).disableE2EE();
    
    setState(() {
      _isLoading = false;
    });
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Encryption disabled successfully')),
      );
      
      _passphraseController.clear();
      _confirmPassphraseController.clear();
    } else {
      final error = ref.read(e2eeStateProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to disable E2EE: ${error ?? "Unknown error"}')),
      );
    }
  }
  
  Future<void> _lockE2EE() async {
    await ref.read(e2eeStateProvider.notifier).lock();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Encryption locked')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e2eeState = ref.watch(e2eeStateProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('End-to-End Encryption'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status info
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Encryption Status',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildStatusItem(
                              'E2EE Enabled',
                              e2eeState.isE2EEEnabled ? 'Yes' : 'No',
                              e2eeState.isE2EEEnabled ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(height: 8),
                            _buildStatusItem(
                              'Passphrase Set',
                              e2eeState.isE2EESetUp ? 'Yes' : 'No',
                              e2eeState.isE2EESetUp ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(height: 8),
                            _buildStatusItem(
                              'Encryption Unlocked',
                              e2eeState.isUnlocked ? 'Yes' : 'No',
                              e2eeState.isUnlocked ? Colors.green : Colors.red,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Passphrase input
                    TextFormField(
                      controller: _passphraseController,
                      decoration: InputDecoration(
                        labelText: 'Passphrase',
                        hintText: 'Enter your passphrase',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassphrase ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassphrase = !_obscurePassphrase;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassphrase,
                      validator: (value) {
                        if (!e2eeState.isE2EESetUp && _setupMode) {
                          if (value == null || value.length < 8) {
                            return 'Passphrase must be at least 8 characters';
                          }
                        }
                        return null;
                      },
                    ),
                    
                    if (!e2eeState.isE2EESetUp && _setupMode) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPassphraseController,
                        decoration: const InputDecoration(
                          labelText: 'Confirm Passphrase',
                          hintText: 'Enter your passphrase again',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value != _passphraseController.text) {
                            return 'Passphrases do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Action buttons
                    if (!e2eeState.isE2EESetUp) ...[
                      _buildActionButton(
                        label: 'Set Up End-to-End Encryption',
                        icon: Icons.lock,
                        color: Colors.blue,
                        onPressed: _setupE2EE,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'End-to-end encryption protects your data with a passphrase. '
                        'You will need this passphrase to access your data on this device or other devices. '
                        'If you forget your passphrase, your data cannot be recovered.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    
                    if (e2eeState.isE2EESetUp && !e2eeState.isUnlocked) ...[
                      _buildActionButton(
                        label: 'Unlock Encryption',
                        icon: Icons.lock_open,
                        color: Colors.green,
                        onPressed: _unlockE2EE,
                      ),
                    ],
                    
                    if (e2eeState.isE2EESetUp && e2eeState.isUnlocked) ...[
                      _buildActionButton(
                        label: 'Lock Encryption',
                        icon: Icons.lock_outline,
                        color: Colors.orange,
                        onPressed: _lockE2EE,
                      ),
                      const SizedBox(height: 16),
                      _buildActionButton(
                        label: 'Disable Encryption',
                        icon: Icons.no_encryption,
                        color: Colors.red,
                        onPressed: _disableE2EE,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Disabling encryption will decrypt all your data. '
                        'The data will remain private in your device storage, '
                        'but will no longer be protected with your passphrase.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildStatusItem(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
  
  // Whether we're in setup mode (showing confirm passphrase field)
  bool get _setupMode => true;
}
