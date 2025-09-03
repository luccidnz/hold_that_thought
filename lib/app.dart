import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hold_that_thought/app_root_sync_listener.dart';
import 'pages/capture_page.dart';
import 'pages/list_page.dart';
import 'pages/settings_page.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class HoldThatThoughtApp extends ConsumerWidget {
  const HoldThatThoughtApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const CapturePage(), routes: [
          GoRoute(path: 'list', builder: (_, __) => const ListPage()),
          GoRoute(path: 'settings', builder: (_, __) => const SettingsPage()),
        ]),
      ],
    );

    return MaterialApp.router(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      title: 'Hold That Thought',
      theme: ThemeData(brightness: Brightness.light),
      darkTheme: ThemeData(brightness: Brightness.dark),
      routerConfig: router,
      builder: (context, child) {
        return RootSyncListener(child: child!);
      },
    );
  }
}
