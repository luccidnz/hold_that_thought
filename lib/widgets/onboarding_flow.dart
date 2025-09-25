import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/services/feature_flags.dart' hide featureFlagsProvider;
import 'package:hold_that_thought/state/providers.dart';

/// A widget that displays an onboarding flow for new features in Phase 10.
/// This includes multi-device sign-in, RAG features, E2EE, and Android foreground service.
class OnboardingFlow extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const OnboardingFlow({
    Key? key,
    required this.onComplete,
  }) : super(key: key);

  @override
  _OnboardingFlowState createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 5; // Welcome + 4 feature pages

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                _buildWelcomePage(theme),
                _buildAuthPage(theme),
                _buildRagPage(theme),
                _buildE2EEPage(theme),
                _buildAndroidServicePage(theme),
              ],
            ),
          ),
          _buildPageIndicator(),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_totalPages, (index) {
          return Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentPage == index
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceVariant,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            TextButton(
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: const Text('Back'),
            )
          else
            const SizedBox(width: 80),
          ElevatedButton(
            onPressed: () {
              if (_currentPage < _totalPages - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                widget.onComplete();
              }
            },
            child: Text(_currentPage < _totalPages - 1 ? 'Next' : 'Get Started'),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.auto_awesome,
            size: 80,
            color: Colors.amber,
          ),
          const SizedBox(height: 32),
          Text(
            'Welcome to Hold That Thought',
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Version 10.0 brings exciting new features to help you capture and recall your thoughts more effectively.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Text(
            'Swipe to learn about the new features',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAuthPage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.devices,
            size: 80,
            color: Colors.blue,
          ),
          const SizedBox(height: 32),
          Text(
            'Multi-Device Sign-In',
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Now you can access your thoughts from all your devices with a simple sign-in.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildFeatureSwitch(
            'Enable Multi-Device Sign-In',
            (value) async {
              final featureFlags = ref.read(featureFlagsProvider);
              await featureFlags.setAuthEnabled(value);
            },
            false, // Default value, will be updated in a real implementation
          ),
        ],
      ),
    );
  }

  Widget _buildRagPage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.psychology,
            size: 80,
            color: Colors.green,
          ),
          const SizedBox(height: 32),
          Text(
            'Smart Recall',
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Get related thought suggestions and daily digests with our new Smart Recall feature.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildFeatureSwitch(
            'Enable Smart Recall',
            (value) async {
              final featureFlags = ref.read(featureFlagsProvider);
              await featureFlags.setRagEnabled(value);
            },
            false, // Default value, will be updated in a real implementation
          ),
        ],
      ),
    );
  }

  Widget _buildE2EEPage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.security,
            size: 80,
            color: Colors.red,
          ),
          const SizedBox(height: 32),
          Text(
            'End-to-End Encryption',
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Protect your private thoughts with optional end-to-end encryption. Only you can access your encrypted data.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Note: You will need to set a passphrase if you enable this feature.',
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildFeatureSwitch(
            'Enable End-to-End Encryption',
            (value) async {
              final featureFlags = ref.read(featureFlagsProvider);
              await featureFlags.setE2eeEnabled(value);
            },
            false, // Default value, will be updated in a real implementation
          ),
        ],
      ),
    );
  }

  Widget _buildAndroidServicePage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.mic,
            size: 80,
            color: Colors.purple,
          ),
          const SizedBox(height: 32),
          Text(
            'Background Recording',
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'On Android, the app now uses a foreground service for reliable background recording, even when the app is minimized.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'This feature is automatically enabled for Android users.',
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureSwitch(String label, Function(bool) onChanged, bool value) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      secondary: const Icon(Icons.check_circle_outline),
    );
  }
}

/// Provider to track whether the onboarding flow has been shown
final onboardingCompletedProvider = StateProvider<bool>((ref) => false);
