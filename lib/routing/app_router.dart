import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hold_that_thought/notes/notes_repository.dart';
import 'package:hold_that_thought/pages/capture_page.dart';
import 'package:hold_that_thought/pages/list_page.dart';
import 'package:hold_that_thought/settings/settings_screen.dart';
import 'package:hold_that_thought/notes/create_note_page.dart';
import 'package:hold_that_thought/notes/note_data.dart';
import 'package:hold_that_thought/notes/note_detail_page.dart';
import 'package:hold_that_thought/pages/not_found_page.dart';
import 'package:hold_that_thought/routing/route_observer.dart';

GoRouter buildAppRouter(NotesRepository notesRepository,
    {String initialLocation = '/'}) {
  return GoRouter(
    initialLocation: initialLocation,
    observers: [if (kDebugMode) AppRouteObserver()],
    errorBuilder: (context, state) {
      if (kDebugMode) {
        log('Routing error: ${state.error}', error: state.error);
      }
      return const NotFoundPage();
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const CapturePage(),
      ),
      GoRoute(
        path: '/list',
        builder: (context, state) {
          final tag = state.uri.queryParameters['tag'];
          return ListPage(tag: tag);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/note/:id',
        redirect: (context, state) {
          final id = state.pathParameters['id']!;
          if (!notesRepository.exists(id)) {
            return AppRoutes.notFound();
          }
          return null;
        },
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return NoteDetailPage(id: id);
        },
      ),
      GoRoute(
        path: '/create',
        builder: (context, state) {
          final data = state.extra as CreateNoteData?;
          return CreateNotePage(prefilledData: data);
        },
      ),
      GoRoute(
        path: '/404',
        builder: (context, state) => const NotFoundPage(),
      ),
    ],
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notesRepository = ref.watch(notesRepositoryProvider);
  return buildAppRouter(notesRepository);
});

class AppRoutes {
  static String home() => '/';
  static String settings() => '/settings';
  static String note(String id) => '/note/$id';
  static String create() => '/create';
  static String notFound() => '/404';
  static String list({String? tag}) {
    if (tag != null) {
      return '/list?tag=$tag';
    }
    return '/list';
  }
}
