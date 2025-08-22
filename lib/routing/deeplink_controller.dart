import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/routing/deeplink_source.dart';
import 'package:hold_that_thought/routing/navigation_service.dart';

import 'dart:developer';

class DeepLinkController {
  final Ref ref;
  final DeepLinkSource _source;

  StreamSubscription<String?>? _linkSubscription;

  DeepLinkController({required this.ref, required DeepLinkSource source})
      : _source = source {
    _init();
  }

  Future<void> _init() async {
    log('DeepLinkController initialized');
    // Process the initial link on startup
    final initialLink = await _source.getInitialLink();
    _handleLink(initialLink);

    // Subscribe to subsequent links
    _linkSubscription = _source.linkStream.listen(_handleLink);

    // Dispose of the subscription when the controller is disposed
    ref.onDispose(() {
      _linkSubscription?.cancel();
    });
  }

  void _handleLink(String? link) {
    if (link != null && link.isNotEmpty) {
      final uri = Uri.tryParse(link);
      if (uri != null) {
        // The controller should not have to know the GoRouter implementation details.
        // It just needs to know how to navigate. The app router will handle the parsing.
        final path = '/${uri.host}${uri.path}';
        ref.read(navigationServiceProvider).go(path);
      }
    }
  }
}

final deepLinkControllerProvider =
    FutureProvider<DeepLinkController>((ref) async {
  final source = ref.watch(deepLinkSourceProvider);
  final controller = DeepLinkController(ref: ref, source: source);
  // The future completes once the controller is initialized
  return controller;
});
