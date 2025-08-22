import 'dart:async';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/deeplink/uni_links_source.dart';
import 'package:hold_that_thought/routing/app_router.dart';

import 'deeplink_source.dart';

typedef DeepLinkNavigate = void Function(Uri uri);

class DeepLinkController {
  DeepLinkController({
    required this.source,
    required this.onNavigate,
  });

  final DeepLinkSource source;
  final DeepLinkNavigate onNavigate;

  StreamSubscription<Uri?>? _sub;

  Future<void> init() async {
    final initial = await source.getInitialLink();
    if (initial != null) _handle(initial);
    _sub = source.linkStream.listen((uri) {
      if (uri != null) _handle(uri);
    });
  }

  void _handle(Uri uri) => onNavigate(uri);

  Future<void> dispose() async => _sub?.cancel();
}

final deepLinkSourceProvider = Provider<DeepLinkSource>((ref) {
  return UniLinksSource();
});

final deeplinkControllerProvider = Provider<DeepLinkController>((ref) {
  final source = ref.watch(deepLinkSourceProvider);
  final router = ref.watch(appRouterProvider);

  void onNavigate(Uri uri) {
    if (uri.scheme == 'myapp' &&
        uri.host == 'note' &&
        uri.pathSegments.isNotEmpty) {
      final id = uri.pathSegments.first;
      router.go('/note/$id');
    }
  }

  final controller = DeepLinkController(
    source: source,
    onNavigate: onNavigate,
  );

  // Initialize the controller and dispose it when the provider is disposed.
  controller.init();
  ref.onDispose(controller.dispose);

  return controller;
});
