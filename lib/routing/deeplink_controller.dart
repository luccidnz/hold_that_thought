// TODO: Integrate native deep link config in AndroidManifest.xml and Info.plist
// See docs/deeplinks-native.md for details.

import 'dart:async';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/routing/deeplink_source.dart';
import 'package:hold_that_thought/routing/navigation_service.dart';

class DeepLinkController {
  final Ref ref;
  final DeepLinkSource _source;

  StreamSubscription<Uri?>? _linkSubscription;

  DeepLinkController({required this.ref, required DeepLinkSource source})
      : _source = source {
    _init();
  }

  Future<void> _init() async {
    log('DeepLinkController initialized');
    // Process the initial link on startup
    final initialUri = await _source.getInitialUri();
    _handleLink(initialUri);

    // Subscribe to subsequent links
    _linkSubscription = _source.uriStream.listen(_handleLink);

    // Dispose of the subscription when the controller is disposed
    ref.onDispose(() {
      _linkSubscription?.cancel();
    });
  }

  void _handleLink(Uri? uri) {
    if (uri == null) return;

    // Expects myapp://note/<id>
    if (uri.host != 'note' || uri.pathSegments.isEmpty) return;

    final id = uri.pathSegments.first;
    if (id.trim().isEmpty) return;

    ref.read(navigationServiceProvider).go('/note/$id');
  }
}

final deepLinkControllerProvider =
    FutureProvider<DeepLinkController>((ref) async {
  final source = ref.watch(deepLinkSourceProvider);
  final controller = DeepLinkController(ref: ref, source: source);
  // The future completes once the controller is initialized
  return controller;
});
