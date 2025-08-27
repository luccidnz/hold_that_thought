import 'package:go_router/go_router.dart';
import 'package:hold_that_thought/ui/pages/capture_page.dart';
import 'package:hold_that_thought/ui/pages/create_note_page.dart';
import 'package:hold_that_thought/ui/pages/list_page.dart';
import 'package:hold_that_thought/ui/pages/settings_page.dart';
import 'package:hold_that_thought/ui/pages/view_thought_page.dart';

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
    GoRoute(
      path: '/new',
      builder: (context, state) => const CreateNotePage(),
    ),
    GoRoute(
      path: '/t/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ViewThoughtPage(id: id);
      },
    ),
  ],
);
