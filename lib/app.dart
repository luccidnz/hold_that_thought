import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'pages/capture_page.dart';
import 'pages/list_page.dart';
import 'pages/settings_page.dart';

class HoldThatThoughtApp extends StatelessWidget {
  const HoldThatThoughtApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const CapturePage(), routes: [
          GoRoute(path: 'list',     builder: (_, __) => const ListPage()),
          GoRoute(path: 'settings', builder: (_, __) => const SettingsPage()),
        ]),
      ],
    );

    return MaterialApp.router(
      title: 'Hold That Thought',
      theme: ThemeData(brightness: Brightness.light),
      darkTheme: ThemeData(brightness: Brightness.dark),
      routerConfig: router,
    );
  }
}
