import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hold_that_thought/notes/notes_repository.dart';
import 'package:hold_that_thought/routing/app_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:hold_that_thought/sync/sync_service.dart';
import '../test_helpers.dart';
import 'package:hold_that_thought/flavor.dart';
import 'package:hold_that_thought/main.dart';

import 'app_router_test.mocks.dart';

@GenerateMocks([NotesRepository])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AppRouter tests', (WidgetTester tester) async {
    final mockNotesRepository = MockNotesRepository();
    when(mockNotesRepository.exists('123')).thenReturn(true);
    when(mockNotesRepository.exists('zzz')).thenReturn(false);
    when(mockNotesRepository.getDistinctTags()).thenReturn({});
    when(mockNotesRepository.getPinnedNotes()).thenReturn([]);
    when(mockNotesRepository.getUnpinnedNotes(query: anyNamed('query'), tags: anyNamed('tags'))).thenReturn([]);
    when(mockNotesRepository.syncStatus).thenAnswer((_) => Stream.value(SyncStatus.ok));

    final container = ProviderContainer(
      overrides: [
        notesRepositoryProvider.overrideWith((ref) => mockNotesRepository),
        flavorProvider.overrideWithValue(Flavor.dev),
      ],
    );
    final router = container.read(appRouterProvider);

    await tester.pumpWidget(buildTestableRouterWidget(
      container: container,
    ));

    // Test initial route
    expect(find.text('Notes'), findsOneWidget);

    // Test navigation to a valid note
    router.go(AppRoutes.note('123'));
    await tester.pumpAndSettle();
    expect(find.text('Note Detail'), findsOneWidget);

    // Test navigation to an invalid note
    router.go(AppRoutes.note('zzz'));
    await tester.pumpAndSettle();
    expect(find.text('Page Not Found'), findsOneWidget);

    // Test navigation with query parameters
    router.go(AppRoutes.list(tag: 'work'));
    await tester.pumpAndSettle();
    expect(find.text('Thoughts'), findsOneWidget);
  });
}
