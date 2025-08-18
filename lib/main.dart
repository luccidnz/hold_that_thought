import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/routing/app_router.dart';
import 'package:hold_that_thought/theme/app_theme.dart';
import 'package:hold_that_thought/theme/theme_controller.dart';
import 'package:url_strategy/url_strategy.dart';

void main() {
  setPathUrlStrategy();
  runApp(const ProviderScope(child: HoldThatThoughtApp()));
}

class HoldThatThoughtApp extends ConsumerWidget {
  const HoldThatThoughtApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeState = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Hold That Thought',
      theme: AppTheme.getTheme(themeState.accentColor, Brightness.light),
      darkTheme: AppTheme.getTheme(themeState.accentColor, Brightness.dark),
      themeMode: themeState.themeMode,
      routerConfig: router,
    );
  }
}