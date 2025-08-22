import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/notes/notes_repository.dart';
import 'package:mockito/mockito.dart';

import 'app_router.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hold_that_thought/l10n/app_localizations.dart';

// A mock repository that can be configured for tests.
class MockNotesRepository extends Mock implements NotesRepository {}

class TestApp extends StatelessWidget {
  const TestApp({
    super.key,
    required this.initialLocation,
    this.notesRepository,
  });

  final String initialLocation;
  final NotesRepository? notesRepository;

  @override
  Widget build(BuildContext context) {
    // Use the provided mock repository, or a default one if not provided.
    final mockRepo = notesRepository ?? MockNotesRepository();

    // The router needs to be created with the repository.
    final router = buildAppRouter(mockRepo, initialLocation: initialLocation);

    // We wrap with a ProviderScope to make the notesRepositoryProvider
    // available to the router's redirect guard.
    return ProviderScope(
      overrides: [
        notesRepositoryProvider.overrideWith((ref) => mockRepo),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'), // English
          Locale('mi'), // Maori
        ],
      ),
    );
  }
}
