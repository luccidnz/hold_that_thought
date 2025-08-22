import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hold_that_thought/routing/app_router.dart';

abstract class NavigationService {
  void go(String location);
}

class GoRouterNavigationService implements NavigationService {
  final GoRouter _router;

  GoRouterNavigationService(this._router);

  @override
  void go(String location) {
    _router.go(location);
  }
}

final navigationServiceProvider = Provider<NavigationService>((ref) {
  final router = ref.watch(appRouterProvider);
  return GoRouterNavigationService(router);
});
