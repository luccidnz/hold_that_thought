import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/services/feature_flags.dart';
import 'package:hold_that_thought/state/auth_state.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({Key? key}) : super(key: key);

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _usePassword = false;
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleAuthAction() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar('Please enter an email address');
      return;
    }

    if (_usePassword) {
      final password = _passwordController.text;
      if (password.isEmpty) {
        _showSnackBar('Please enter a password');
        return;
      }

      if (_isSignUp) {
        await ref.read(authStateProvider.notifier).signUpWithEmailAndPassword(
              email,
              password,
            );
      } else {
        await ref.read(authStateProvider.notifier).signInWithEmailAndPassword(
              email,
              password,
            );
      }
    } else {
      await ref.read(authStateProvider.notifier).signInWithMagicLink(email);
      _showSnackBar('Check your email for a magic link');
    }
  }

  Widget _buildSignedOutContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isSignUp ? 'Create Account' : 'Sign In',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
          ),
          if (_usePassword) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: _usePassword,
                onChanged: (value) => setState(() => _usePassword = value!),
              ),
              const Text('Use password instead of magic link'),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _handleAuthAction,
            child: Text(_isSignUp ? 'Sign Up' : 'Sign In'),
          ),
          TextButton(
            onPressed: () => setState(() => _isSignUp = !_isSignUp),
            child: Text(_isSignUp
                ? 'Already have an account? Sign in'
                : 'Need an account? Sign up'),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Cloud Sync Benefits',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            '• Access thoughts across all your devices\n'
            '• Automatic backup of all your data\n'
            '• Never lose your thoughts if your device is lost\n'
            '• Optional end-to-end encryption for maximum privacy',
          ),
        ],
      ),
    );
  }

  Widget _buildSignedInContent() {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Account',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(user?.email ?? 'No email available'),
                  const SizedBox(height: 8),
                  Text(
                    'User ID',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(user?.id ?? 'Unknown'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Linked Devices',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const ListTile(
                    title: Text('Current Device'),
                    subtitle: Text('Last active: Just now'),
                    leading: Icon(Icons.smartphone),
                  ),
                  // In a real app, we would list all linked devices here
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              final authNotifier = ref.read(authStateProvider.notifier);
              await authNotifier.signOut();
              if (mounted) {
                _showSnackBar('Signed out successfully');
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              // Show confirmation dialog
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Account Data'),
                  content: const Text(
                    'This will delete all account data from this device. '
                    'Your data in the cloud will not be affected, and you can '
                    'access it again by signing in.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await ref.read(authStateProvider.notifier).deleteLocalUserData();
                if (mounted) {
                  _showSnackBar('Local data deleted');
                }
              }
            },
            icon: const Icon(Icons.delete_forever),
            label: const Text('Delete Account Data on this Device'),
          ),
          const SizedBox(height: 16),
          FutureBuilder<bool>(
            future: ref.read(featureFlagsProvider).getE2eeEnabled(),
            builder: (context, snapshot) {
              final e2eeEnabled = snapshot.data ?? false;
              if (!e2eeEnabled) return const SizedBox.shrink();

              return OutlinedButton.icon(
                onPressed: () {
                  // This would open the reset encryption key flow
                  // Will be implemented when we do the E2EE section
                  _showSnackBar('Reset encryption key functionality will be available when E2EE is implemented');
                },
                icon: const Icon(Icons.key),
                label: const Text('Reset Encryption Key'),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isAuthEnabled = ref.watch(authEnabledProvider).value ?? false;

    if (!isAuthEnabled) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account')),
        body: const Center(
          child: Text('Authentication is disabled. Enable it in settings.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: SingleChildScrollView(
        child: authState.isSignedIn
            ? _buildSignedInContent()
            : _buildSignedOutContent(),
      ),
    );
  }
}
