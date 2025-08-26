import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Placeholder pages
class CapturePage extends StatelessWidget {
  const CapturePage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hold That Thought')),
      body: const Center(child: Text('Capture Page')),
    );
  }
}

class ListPage extends StatelessWidget {
  const ListPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thoughts')),
      body: const Center(child: Text('List Page')),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings Page')),
    );
  }
}

void main() {
  runApp(const ProviderScope(child: HoldThatThoughtApp()));
}

class HoldThatThoughtApp extends ConsumerWidget {
  const HoldThatThoughtApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const CapturePage(),
          routes: [
            GoRoute(
              path: 'list',
              builder: (context, state) => const ListPage(),
            ),
            GoRoute(
              path: 'settings',
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
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